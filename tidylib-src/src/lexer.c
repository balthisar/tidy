/* lexer.c -- Lexer for html parser
  
  (c) 1998-2003 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/20 16:39:47 $ 
    $Revision: 1.76 $ 

*/

/*
  Given a file stream fp it returns a sequence of tokens.

     GetToken(fp) gets the next token
     UngetToken(fp) provides one level undo

  The tags include an attribute list:

    - linked list of attribute/value nodes
    - each node has 2 null-terminated strings.
    - entities are replaced in attribute values

  white space is compacted if not in preformatted mode
  If not in preformatted mode then leading white space
  is discarded and subsequent white space sequences
  compacted to single space characters.

  If XmlTags is no then Tag names are folded to upper
  case and attribute names to lower case.

 Not yet done:
    -   Doctype subset and marked sections
*/

#include "tidy-int.h"
#include "lexer.h"
#include "parser.h"
#include "entities.h"
#include "streamio.h"
#include "message.h"
#include "tmbstr.h"
#include "clean.h"
#include "utf8.h"


/* Forward references
*/
/* swallows closing '>' */
AttVal *ParseAttrs( TidyDocImpl* doc, Bool *isempty );

Node *CommentToken( Lexer *lexer);

static tmbstr ParseAttribute( TidyDocImpl* doc, Bool* isempty, 
                             Node **asp, Node **php );

static tmbstr ParseValue( TidyDocImpl* doc, ctmbstr name, Bool foldCase,
                         Bool *isempty, int *pdelim );

static void AddAttrToList( AttVal** list, AttVal* av );

/* used to classify characters for lexical purposes */
#define MAP(c) ((unsigned)c < 128 ? lexmap[(unsigned)c] : 0)
uint lexmap[128];

#define XHTML_NAMESPACE "http://www.w3.org/1999/xhtml"

/* the 3 URIs  for the XHTML 1.0 DTDs */
#define voyager_loose    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
#define voyager_strict   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
#define voyager_frameset "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd"

/* URI for XHTML 1.1 and XHTML Basic 1.0 */
#define voyager_11       "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
#define voyager_basic    "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd"

#define W3C_VERSIONS 10

struct _vers
{
    ctmbstr name;
    ctmbstr voyager_name;
    ctmbstr profile;
    uint    code;
}
const W3C_Version[] =
{
    {"HTML 4.01", "XHTML 1.0 Strict", voyager_strict, VERS_HTML40_STRICT},
    {"HTML 4.01 Transitional", "XHTML 1.0 Transitional", voyager_loose, VERS_HTML40_LOOSE},
    {"HTML 4.01 Frameset", "XHTML 1.0 Frameset", voyager_frameset, VERS_FRAMESET},
    {"HTML 4.0", "XHTML 1.0 Strict", voyager_strict, VERS_HTML40_STRICT},
    {"HTML 4.0 Transitional", "XHTML 1.0 Transitional", voyager_loose, VERS_HTML40_LOOSE},
    {"HTML 4.0 Frameset", "XHTML 1.0 Frameset", voyager_frameset, VERS_FRAMESET},
    {"HTML 3.2", "XHTML 1.0 Transitional", voyager_loose, VERS_HTML32},
    {"HTML 3.2 Final", "XHTML 1.0 Transitional", voyager_loose, VERS_HTML32},
    {"HTML 3.2 Draft", "XHTML 1.0 Transitional", voyager_loose, VERS_HTML32},
    {"HTML 2.0", "XHTML 1.0 Strict", voyager_strict, VERS_HTML20}
};

/* everything is allowed in proprietary version of HTML */
/* this is handled here rather than in the tag/attr dicts */
void ConstrainVersion(TidyDocImpl* doc, uint vers)
{
    doc->lexer->versions &= (vers | VERS_PROPRIETARY);
}

Bool IsWhite(uint c)
{
    uint map = MAP(c);

    return (Bool)(map & white);
}

Bool IsNewline(uint c)
{
    uint map = MAP(c);
    return (Bool)(map & newline);
}

Bool IsDigit(uint c)
{
    uint map;

    map = MAP(c);

    return (Bool)(map & digit);
}

Bool IsLetter(uint c)
{
    uint map;

    map = MAP(c);

    return (Bool)(map & letter);
}

Bool IsNamechar(uint c)
{
    uint map = MAP(c);
    return (Bool)(map & namechar);
}

Bool IsXMLLetter(uint c)
{
    return ((c >= 0x41 && c <= 0x5a) ||
        (c >= 0x61 && c <= 0x7a) ||
        (c >= 0xc0 && c <= 0xd6) ||
        (c >= 0xd8 && c <= 0xf6) ||
        (c >= 0xf8 && c <= 0xff) ||
        (c >= 0x100 && c <= 0x131) ||
        (c >= 0x134 && c <= 0x13e) ||
        (c >= 0x141 && c <= 0x148) ||
        (c >= 0x14a && c <= 0x17e) ||
        (c >= 0x180 && c <= 0x1c3) ||
        (c >= 0x1cd && c <= 0x1f0) ||
        (c >= 0x1f4 && c <= 0x1f5) ||
        (c >= 0x1fa && c <= 0x217) ||
        (c >= 0x250 && c <= 0x2a8) ||
        (c >= 0x2bb && c <= 0x2c1) ||
        c == 0x386 ||
        (c >= 0x388 && c <= 0x38a) ||
        c == 0x38c ||
        (c >= 0x38e && c <= 0x3a1) ||
        (c >= 0x3a3 && c <= 0x3ce) ||
        (c >= 0x3d0 && c <= 0x3d6) ||
        c == 0x3da ||
        c == 0x3dc ||
        c == 0x3de ||
        c == 0x3e0 ||
        (c >= 0x3e2 && c <= 0x3f3) ||
        (c >= 0x401 && c <= 0x40c) ||
        (c >= 0x40e && c <= 0x44f) ||
        (c >= 0x451 && c <= 0x45c) ||
        (c >= 0x45e && c <= 0x481) ||
        (c >= 0x490 && c <= 0x4c4) ||
        (c >= 0x4c7 && c <= 0x4c8) ||
        (c >= 0x4cb && c <= 0x4cc) ||
        (c >= 0x4d0 && c <= 0x4eb) ||
        (c >= 0x4ee && c <= 0x4f5) ||
        (c >= 0x4f8 && c <= 0x4f9) ||
        (c >= 0x531 && c <= 0x556) ||
        c == 0x559 ||
        (c >= 0x561 && c <= 0x586) ||
        (c >= 0x5d0 && c <= 0x5ea) ||
        (c >= 0x5f0 && c <= 0x5f2) ||
        (c >= 0x621 && c <= 0x63a) ||
        (c >= 0x641 && c <= 0x64a) ||
        (c >= 0x671 && c <= 0x6b7) ||
        (c >= 0x6ba && c <= 0x6be) ||
        (c >= 0x6c0 && c <= 0x6ce) ||
        (c >= 0x6d0 && c <= 0x6d3) ||
        c == 0x6d5 ||
        (c >= 0x6e5 && c <= 0x6e6) ||
        (c >= 0x905 && c <= 0x939) ||
        c == 0x93d ||
        (c >= 0x958 && c <= 0x961) ||
        (c >= 0x985 && c <= 0x98c) ||
        (c >= 0x98f && c <= 0x990) ||
        (c >= 0x993 && c <= 0x9a8) ||
        (c >= 0x9aa && c <= 0x9b0) ||
        c == 0x9b2 ||
        (c >= 0x9b6 && c <= 0x9b9) ||
        (c >= 0x9dc && c <= 0x9dd) ||
        (c >= 0x9df && c <= 0x9e1) ||
        (c >= 0x9f0 && c <= 0x9f1) ||
        (c >= 0xa05 && c <= 0xa0a) ||
        (c >= 0xa0f && c <= 0xa10) ||
        (c >= 0xa13 && c <= 0xa28) ||
        (c >= 0xa2a && c <= 0xa30) ||
        (c >= 0xa32 && c <= 0xa33) ||
        (c >= 0xa35 && c <= 0xa36) ||
        (c >= 0xa38 && c <= 0xa39) ||
        (c >= 0xa59 && c <= 0xa5c) ||
        c == 0xa5e ||
        (c >= 0xa72 && c <= 0xa74) ||
        (c >= 0xa85 && c <= 0xa8b) ||
        c == 0xa8d ||
        (c >= 0xa8f && c <= 0xa91) ||
        (c >= 0xa93 && c <= 0xaa8) ||
        (c >= 0xaaa && c <= 0xab0) ||
        (c >= 0xab2 && c <= 0xab3) ||
        (c >= 0xab5 && c <= 0xab9) ||
        c == 0xabd ||
        c == 0xae0 ||
        (c >= 0xb05 && c <= 0xb0c) ||
        (c >= 0xb0f && c <= 0xb10) ||
        (c >= 0xb13 && c <= 0xb28) ||
        (c >= 0xb2a && c <= 0xb30) ||
        (c >= 0xb32 && c <= 0xb33) ||
        (c >= 0xb36 && c <= 0xb39) ||
        c == 0xb3d ||
        (c >= 0xb5c && c <= 0xb5d) ||
        (c >= 0xb5f && c <= 0xb61) ||
        (c >= 0xb85 && c <= 0xb8a) ||
        (c >= 0xb8e && c <= 0xb90) ||
        (c >= 0xb92 && c <= 0xb95) ||
        (c >= 0xb99 && c <= 0xb9a) ||
        c == 0xb9c ||
        (c >= 0xb9e && c <= 0xb9f) ||
        (c >= 0xba3 && c <= 0xba4) ||
        (c >= 0xba8 && c <= 0xbaa) ||
        (c >= 0xbae && c <= 0xbb5) ||
        (c >= 0xbb7 && c <= 0xbb9) ||
        (c >= 0xc05 && c <= 0xc0c) ||
        (c >= 0xc0e && c <= 0xc10) ||
        (c >= 0xc12 && c <= 0xc28) ||
        (c >= 0xc2a && c <= 0xc33) ||
        (c >= 0xc35 && c <= 0xc39) ||
        (c >= 0xc60 && c <= 0xc61) ||
        (c >= 0xc85 && c <= 0xc8c) ||
        (c >= 0xc8e && c <= 0xc90) ||
        (c >= 0xc92 && c <= 0xca8) ||
        (c >= 0xcaa && c <= 0xcb3) ||
        (c >= 0xcb5 && c <= 0xcb9) ||
        c == 0xcde ||
        (c >= 0xce0 && c <= 0xce1) ||
        (c >= 0xd05 && c <= 0xd0c) ||
        (c >= 0xd0e && c <= 0xd10) ||
        (c >= 0xd12 && c <= 0xd28) ||
        (c >= 0xd2a && c <= 0xd39) ||
        (c >= 0xd60 && c <= 0xd61) ||
        (c >= 0xe01 && c <= 0xe2e) ||
        c == 0xe30 ||
        (c >= 0xe32 && c <= 0xe33) ||
        (c >= 0xe40 && c <= 0xe45) ||
        (c >= 0xe81 && c <= 0xe82) ||
        c == 0xe84 ||
        (c >= 0xe87 && c <= 0xe88) ||
        c == 0xe8a ||
        c == 0xe8d ||
        (c >= 0xe94 && c <= 0xe97) ||
        (c >= 0xe99 && c <= 0xe9f) ||
        (c >= 0xea1 && c <= 0xea3) ||
        c == 0xea5 ||
        c == 0xea7 ||
        (c >= 0xeaa && c <= 0xeab) ||
        (c >= 0xead && c <= 0xeae) ||
        c == 0xeb0 ||
        (c >= 0xeb2 && c <= 0xeb3) ||
        c == 0xebd ||
        (c >= 0xec0 && c <= 0xec4) ||
        (c >= 0xf40 && c <= 0xf47) ||
        (c >= 0xf49 && c <= 0xf69) ||
        (c >= 0x10a0 && c <= 0x10c5) ||
        (c >= 0x10d0 && c <= 0x10f6) ||
        c == 0x1100 ||
        (c >= 0x1102 && c <= 0x1103) ||
        (c >= 0x1105 && c <= 0x1107) ||
        c == 0x1109 ||
        (c >= 0x110b && c <= 0x110c) ||
        (c >= 0x110e && c <= 0x1112) ||
        c == 0x113c ||
        c == 0x113e ||
        c == 0x1140 ||
        c == 0x114c ||
        c == 0x114e ||
        c == 0x1150 ||
        (c >= 0x1154 && c <= 0x1155) ||
        c == 0x1159 ||
        (c >= 0x115f && c <= 0x1161) ||
        c == 0x1163 ||
        c == 0x1165 ||
        c == 0x1167 ||
        c == 0x1169 ||
        (c >= 0x116d && c <= 0x116e) ||
        (c >= 0x1172 && c <= 0x1173) ||
        c == 0x1175 ||
        c == 0x119e ||
        c == 0x11a8 ||
        c == 0x11ab ||
        (c >= 0x11ae && c <= 0x11af) ||
        (c >= 0x11b7 && c <= 0x11b8) ||
        c == 0x11ba ||
        (c >= 0x11bc && c <= 0x11c2) ||
        c == 0x11eb ||
        c == 0x11f0 ||
        c == 0x11f9 ||
        (c >= 0x1e00 && c <= 0x1e9b) ||
        (c >= 0x1ea0 && c <= 0x1ef9) ||
        (c >= 0x1f00 && c <= 0x1f15) ||
        (c >= 0x1f18 && c <= 0x1f1d) ||
        (c >= 0x1f20 && c <= 0x1f45) ||
        (c >= 0x1f48 && c <= 0x1f4d) ||
        (c >= 0x1f50 && c <= 0x1f57) ||
        c == 0x1f59 ||
        c == 0x1f5b ||
        c == 0x1f5d ||
        (c >= 0x1f5f && c <= 0x1f7d) ||
        (c >= 0x1f80 && c <= 0x1fb4) ||
        (c >= 0x1fb6 && c <= 0x1fbc) ||
        c == 0x1fbe ||
        (c >= 0x1fc2 && c <= 0x1fc4) ||
        (c >= 0x1fc6 && c <= 0x1fcc) ||
        (c >= 0x1fd0 && c <= 0x1fd3) ||
        (c >= 0x1fd6 && c <= 0x1fdb) ||
        (c >= 0x1fe0 && c <= 0x1fec) ||
        (c >= 0x1ff2 && c <= 0x1ff4) ||
        (c >= 0x1ff6 && c <= 0x1ffc) ||
        c == 0x2126 ||
        (c >= 0x212a && c <= 0x212b) ||
        c == 0x212e ||
        (c >= 0x2180 && c <= 0x2182) ||
        (c >= 0x3041 && c <= 0x3094) ||
        (c >= 0x30a1 && c <= 0x30fa) ||
        (c >= 0x3105 && c <= 0x312c) ||
        (c >= 0xac00 && c <= 0xd7a3) ||
        (c >= 0x4e00 && c <= 0x9fa5) ||
        c == 0x3007 ||
        (c >= 0x3021 && c <= 0x3029) ||
        (c >= 0x4e00 && c <= 0x9fa5) ||
        c == 0x3007 ||
        (c >= 0x3021 && c <= 0x3029));
}

Bool IsXMLNamechar(uint c)
{
    return (IsXMLLetter(c) ||
        c == '.' || c == '_' ||
        c == ':' || c == '-' ||
        (c >= 0x300 && c <= 0x345) ||
        (c >= 0x360 && c <= 0x361) ||
        (c >= 0x483 && c <= 0x486) ||
        (c >= 0x591 && c <= 0x5a1) ||
        (c >= 0x5a3 && c <= 0x5b9) ||
        (c >= 0x5bb && c <= 0x5bd) ||
        c == 0x5bf ||
        (c >= 0x5c1 && c <= 0x5c2) ||
        c == 0x5c4 ||
        (c >= 0x64b && c <= 0x652) ||
        c == 0x670 ||
        (c >= 0x6d6 && c <= 0x6dc) ||
        (c >= 0x6dd && c <= 0x6df) ||
        (c >= 0x6e0 && c <= 0x6e4) ||
        (c >= 0x6e7 && c <= 0x6e8) ||
        (c >= 0x6ea && c <= 0x6ed) ||
        (c >= 0x901 && c <= 0x903) ||
        c == 0x93c ||
        (c >= 0x93e && c <= 0x94c) ||
        c == 0x94d ||
        (c >= 0x951 && c <= 0x954) ||
        (c >= 0x962 && c <= 0x963) ||
        (c >= 0x981 && c <= 0x983) ||
        c == 0x9bc ||
        c == 0x9be ||
        c == 0x9bf ||
        (c >= 0x9c0 && c <= 0x9c4) ||
        (c >= 0x9c7 && c <= 0x9c8) ||
        (c >= 0x9cb && c <= 0x9cd) ||
        c == 0x9d7 ||
        (c >= 0x9e2 && c <= 0x9e3) ||
        c == 0xa02 ||
        c == 0xa3c ||
        c == 0xa3e ||
        c == 0xa3f ||
        (c >= 0xa40 && c <= 0xa42) ||
        (c >= 0xa47 && c <= 0xa48) ||
        (c >= 0xa4b && c <= 0xa4d) ||
        (c >= 0xa70 && c <= 0xa71) ||
        (c >= 0xa81 && c <= 0xa83) ||
        c == 0xabc ||
        (c >= 0xabe && c <= 0xac5) ||
        (c >= 0xac7 && c <= 0xac9) ||
        (c >= 0xacb && c <= 0xacd) ||
        (c >= 0xb01 && c <= 0xb03) ||
        c == 0xb3c ||
        (c >= 0xb3e && c <= 0xb43) ||
        (c >= 0xb47 && c <= 0xb48) ||
        (c >= 0xb4b && c <= 0xb4d) ||
        (c >= 0xb56 && c <= 0xb57) ||
        (c >= 0xb82 && c <= 0xb83) ||
        (c >= 0xbbe && c <= 0xbc2) ||
        (c >= 0xbc6 && c <= 0xbc8) ||
        (c >= 0xbca && c <= 0xbcd) ||
        c == 0xbd7 ||
        (c >= 0xc01 && c <= 0xc03) ||
        (c >= 0xc3e && c <= 0xc44) ||
        (c >= 0xc46 && c <= 0xc48) ||
        (c >= 0xc4a && c <= 0xc4d) ||
        (c >= 0xc55 && c <= 0xc56) ||
        (c >= 0xc82 && c <= 0xc83) ||
        (c >= 0xcbe && c <= 0xcc4) ||
        (c >= 0xcc6 && c <= 0xcc8) ||
        (c >= 0xcca && c <= 0xccd) ||
        (c >= 0xcd5 && c <= 0xcd6) ||
        (c >= 0xd02 && c <= 0xd03) ||
        (c >= 0xd3e && c <= 0xd43) ||
        (c >= 0xd46 && c <= 0xd48) ||
        (c >= 0xd4a && c <= 0xd4d) ||
        c == 0xd57 ||
        c == 0xe31 ||
        (c >= 0xe34 && c <= 0xe3a) ||
        (c >= 0xe47 && c <= 0xe4e) ||
        c == 0xeb1 ||
        (c >= 0xeb4 && c <= 0xeb9) ||
        (c >= 0xebb && c <= 0xebc) ||
        (c >= 0xec8 && c <= 0xecd) ||
        (c >= 0xf18 && c <= 0xf19) ||
        c == 0xf35 ||
        c == 0xf37 ||
        c == 0xf39 ||
        c == 0xf3e ||
        c == 0xf3f ||
        (c >= 0xf71 && c <= 0xf84) ||
        (c >= 0xf86 && c <= 0xf8b) ||
        (c >= 0xf90 && c <= 0xf95) ||
        c == 0xf97 ||
        (c >= 0xf99 && c <= 0xfad) ||
        (c >= 0xfb1 && c <= 0xfb7) ||
        c == 0xfb9 ||
        (c >= 0x20d0 && c <= 0x20dc) ||
        c == 0x20e1 ||
        (c >= 0x302a && c <= 0x302f) ||
        c == 0x3099 ||
        c == 0x309a ||
        (c >= 0x30 && c <= 0x39) ||
        (c >= 0x660 && c <= 0x669) ||
        (c >= 0x6f0 && c <= 0x6f9) ||
        (c >= 0x966 && c <= 0x96f) ||
        (c >= 0x9e6 && c <= 0x9ef) ||
        (c >= 0xa66 && c <= 0xa6f) ||
        (c >= 0xae6 && c <= 0xaef) ||
        (c >= 0xb66 && c <= 0xb6f) ||
        (c >= 0xbe7 && c <= 0xbef) ||
        (c >= 0xc66 && c <= 0xc6f) ||
        (c >= 0xce6 && c <= 0xcef) ||
        (c >= 0xd66 && c <= 0xd6f) ||
        (c >= 0xe50 && c <= 0xe59) ||
        (c >= 0xed0 && c <= 0xed9) ||
        (c >= 0xf20 && c <= 0xf29) ||
        c == 0xb7 ||
        c == 0x2d0 ||
        c == 0x2d1 ||
        c == 0x387 ||
        c == 0x640 ||
        c == 0xe46 ||
        c == 0xec6 ||
        c == 0x3005 ||
        (c >= 0x3031 && c <= 0x3035) ||
        (c >= 0x309d && c <= 0x309e) ||
        (c >= 0x30fc && c <= 0x30fe));
}

Bool IsLower(uint c)
{
    uint map = MAP(c);

    return (Bool)(map & lowercase);
}

Bool IsUpper(uint c)
{
    uint map = MAP(c);

    return (Bool)(map & uppercase);
}

uint ToLower(uint c)
{
    uint map = MAP(c);

    if (map & uppercase)
        c += 'a' - 'A';

    return c;
}

uint ToUpper(uint c)
{
    uint map = MAP(c);

    if (map & lowercase)
        c += (uint) ('A' - 'a' );

    return c;
}

char FoldCase( TidyDocImpl* doc, tmbchar c, Bool tocaps )
{
    if ( !cfgBool(doc, TidyXmlTags) )
    {
        if ( tocaps )
        {
            c = (tmbchar) ToUpper(c);
        }
        else /* force to lower case */
        {
            c = (tmbchar) ToLower(c);
        }
    }
    return c;
}


/*
 return last character in string
 this is useful when trailing quotemark
 is missing on an attribute
*/
static tmbchar LastChar( tmbstr str )
{
    if ( str && *str )
    {
        int n = tmbstrlen(str);
        return str[n-1];
    }
    return 0;
}

/*
   node->type is one of these:

    #define TextNode    1
    #define StartTag    2
    #define EndTag      3
    #define StartEndTag 4
*/

Lexer* NewLexer()
{
    Lexer* lexer = (Lexer*) MemAlloc( sizeof(Lexer) );

    if ( lexer != null )
    {
        ClearMemory( lexer, sizeof(Lexer) );

        lexer->lines = 1;
        lexer->columns = 1;
        lexer->state = LEX_CONTENT;

        lexer->versions = (VERS_ALL|VERS_PROPRIETARY);
        lexer->doctype = VERS_UNKNOWN;
    }
    return lexer;
}

Bool EndOfInput( TidyDocImpl* doc )
{
    assert( doc->docIn != null );
    return ( !doc->docIn->pushed && IsEOF(doc->docIn) );
}

void FreeLexer( TidyDocImpl* doc )
{
    Lexer *lexer = doc->lexer;
    if ( lexer )
    {
        FreeStyles( doc );

        while ( lexer->istacksize > 0 )
            PopInline( doc, null );

        MemFree( lexer->istack );
        MemFree( lexer->lexbuf );
        MemFree( lexer );
        doc->lexer = null;
    }

    FreeNode( doc, doc->root );
    doc->root = null;

    FreeNode( doc, doc->givenDoctype );
    doc->givenDoctype = null;
}

/* Lexer uses bigger memory chunks than pprint as
** it must hold the entire input document. not just
** the last line or three.
*/
void AddByte( Lexer *lexer, tmbchar ch )
{
    if ( lexer->lexsize + 1 >= lexer->lexlength )
    {
        tmbstr buf = null;
        uint allocAmt = lexer->lexlength;
        while ( lexer->lexsize + 1 >= allocAmt )
        {
            if ( allocAmt == 0 )
                allocAmt = 8192;
            else
                allocAmt *= 2;
        }
        buf = (tmbstr) MemRealloc( lexer->lexbuf, allocAmt );
        if ( buf )
        {
          ClearMemory( buf + lexer->lexlength, 
                       allocAmt - lexer->lexlength );
          lexer->lexbuf = buf;
          lexer->lexlength = allocAmt;
        }
    }

    lexer->lexbuf[ lexer->lexsize++ ] = ch;
    lexer->lexbuf[ lexer->lexsize ]   = '\0';  /* debug */
}

static void ChangeChar( Lexer *lexer, tmbchar c )
{
    if ( lexer->lexsize > 0 )
    {
        lexer->lexbuf[ lexer->lexsize-1 ] = c;
    }
}

/* store character c as UTF-8 encoded byte stream */
void AddCharToLexer( Lexer *lexer, uint c )
{
    int i, err, count = 0;
    tmbchar buf[10] = {0};
    
    err = EncodeCharToUTF8Bytes( c, buf, null, &count );
    if (err)
    {
#if 0 && defined(_DEBUG)
        fprintf( stderr, "lexer UTF-8 encoding error for U+%x : ", c );
#endif
        /* replacement character 0xFFFD encoded as UTF-8 */
        buf[0] = (byte) 0xEF;
        buf[1] = (byte) 0xBF;
        buf[2] = (byte) 0xBD;
        count = 3;
    }
    
    for ( i = 0; i < count; ++i )
        AddByte( lexer, buf[i] );
}

static void AddStringToLexer( Lexer *lexer, ctmbstr str )
{
    uint c;

    /*  Many (all?) compilers will sign-extend signed chars (the default) when
    **  converting them to unsigned integer values.  We must cast our char to
    **  unsigned char before assigning it to prevent this from happening.
    */
    while( 0 != (c = (unsigned char) *str++ ))
        AddCharToLexer( lexer, c );
}

/*
  No longer attempts to insert missing ';' for unknown
  enitities unless one was present already, since this
  gives unexpected results.

  For example:   <a href="something.htm?foo&bar&fred">
  was tidied to: <a href="something.htm?foo&amp;bar;&amp;fred;">
  rather than:   <a href="something.htm?foo&amp;bar&amp;fred">

  My thanks for Maurice Buxton for spotting this.

  Also Randy Waki pointed out the following case for the
  04 Aug 00 version (bug #433012):
  
  For example:   <a href="something.htm?id=1&lang=en">
  was tidied to: <a href="something.htm?id=1&lang;=en">
  rather than:   <a href="something.htm?id=1&amp;lang=en">
  
  where "lang" is a known entity (#9001), but browsers would
  misinterpret "&lang;" because it had a value > 256.
  
  So the case of an apparently known entity with a value > 256 and
  missing a semicolon is handled specially.
  
  "ParseEntity" is also a bit of a misnomer - it handles entities and
  numeric character references. Invalid NCR's are now reported.
*/
static void ParseEntity( TidyDocImpl* doc, int mode )
{
    uint start;
    Bool first = yes, semicolon = no;
    int c, ch, startcol;
    Lexer* lexer = doc->lexer;

    start = lexer->lexsize - 1;  /* to start at "&" */
    startcol = doc->docIn->curcol - 1;

    while ( (c = ReadChar(doc->docIn)) != EndOfStream )
    {
        if ( c == ';' )
        {
            semicolon = yes;
            break;
        }

        if (first && c == '#')
        {
#if SUPPORT_ASIAN_ENCODINGS
            if ( !cfgBool(doc, TidyNCR) || 
                 cfg(doc, TidyInCharEncoding) == BIG5 ||
                 cfg(doc, TidyInCharEncoding) == SHIFTJIS )
            {
                UngetChar('#', doc->docIn);
                return;
            }
#endif
            AddCharToLexer( lexer, c );
            first = no;
            continue;
        }

        first = no;

        if ( IsNamechar(c) )
        {
            AddCharToLexer( lexer, c );
            continue;
        }

        /* otherwise put it back */

        UngetChar( c, doc->docIn );
        break;
    }

    /* make sure entity is null terminated */
    lexer->lexbuf[lexer->lexsize] = '\0';

    if ( tmbstrcmp(lexer->lexbuf+start, "&apos") == 0
         && !cfgBool(doc, TidyXmlOut)
         && !lexer->isvoyager
         && !cfgBool(doc, TidyXhtmlOut) )
        ReportEntityError( doc, APOS_UNDEFINED, lexer->lexbuf+start, 39 );

    /* On input, we want to recognize all possible entities.
    */
    ch = EntityCode( lexer->lexbuf+start, VERS_ALL );

    /* deal with unrecognized or invalid entities */
    /* #433012 - fix by Randy Waki 17 Feb 01 */
    /* report invalid NCR's - Terry Teague 01 Sep 01 */
    if ( ch <= 0 || (ch >= 128 && ch <= 159) || (ch >= 256 && c != ';') )
    {
        /* set error position just before offending character */
        lexer->lines = doc->docIn->curline;
        lexer->columns = startcol;

        if (lexer->lexsize > start + 1)
        {
            if (ch >= 128 && ch <= 159)
            {
                /* invalid numeric character reference */
                
                int c1 = 0, replaceMode = DISCARDED_CHAR;
            
                if ( ReplacementCharEncoding == WIN1252 )
                    c1 = DecodeWin1252( ch );
                else if ( ReplacementCharEncoding == MACROMAN )
                    c1 = DecodeMacRoman( ch );

                if ( c1 )
                    replaceMode = REPLACED_CHAR;
                
                if ( c != ';' )  /* issue warning if not terminated by ';' */
                    ReportEntityError( doc, MISSING_SEMICOLON_NCR,
                                       lexer->lexbuf+start, c );
 
                ReportEncodingError( doc, INVALID_NCR | replaceMode, ch );
                
                if ( c1 )
                {
                    /* make the replacement */
                    lexer->lexsize = start;
                    AddCharToLexer( lexer, c1 );
                    semicolon = no;
                }
                else
                {
                    /* discard */
                    lexer->lexsize = start;
                    semicolon = no;
               }
               
            }
            else
                ReportEntityError( doc, UNKNOWN_ENTITY,
                                   lexer->lexbuf+start, ch );

            if (semicolon)
                AddCharToLexer( lexer, ';' );
        }
        else /* naked & */
            ReportEntityError( doc, UNESCAPED_AMPERSAND,
                               lexer->lexbuf+start, ch );
    }
    else
    {
        if ( c != ';' )    /* issue warning if not terminated by ';' */
        {
            /* set error position just before offending chararcter */
            lexer->lines = doc->docIn->curline;
            lexer->columns = startcol;
            ReportEntityError( doc, MISSING_SEMICOLON, lexer->lexbuf+start, c );
        }

        lexer->lexsize = start;
        if ( ch == 160 && (mode & Preformatted) )
            ch = ' ';
        AddCharToLexer( lexer, ch );

        if ( ch == '&' && !cfgBool(doc, TidyQuoteAmpersand) )
            AddStringToLexer( lexer, "amp;" );
    }
}

static tmbchar ParseTagName( TidyDocImpl* doc )
{
    Lexer *lexer = doc->lexer;
    uint c = lexer->lexbuf[ lexer->txtstart ];

    /* fold case of first character in buffer */

    if ( !cfgBool(doc, TidyXmlTags) && IsUpper(c) )
        lexer->lexbuf[lexer->txtstart] = (tmbchar) ToLower(c);

    while ( (c = ReadChar(doc->docIn)) != EndOfStream )
    {
        if (!IsNamechar(c))
            break;

        /* fold case of subsequent characters */

        if ( !cfgBool(doc, TidyXmlTags) && IsUpper(c) )
             c = ToLower(c);

        AddCharToLexer( lexer, c );
    }

    lexer->txtend = lexer->lexsize;
    return (tmbchar) c;
}

/*
  Used for elements and text nodes
  element name is null for text nodes
  start and end are offsets into lexbuf
  which contains the textual content of
  all elements in the parse tree.

  parent and content allow traversal
  of the parse tree in any direction.
  attributes are represented as a linked
  list of AttVal nodes which hold the
  strings for attribute/value pairs.
*/


Node *NewNode(Lexer *lexer)
{
    Node* node = (Node*) MemAlloc( sizeof(Node) );
    ClearMemory( node, sizeof(Node) );
    if ( lexer )
    {
        node->line = lexer->lines;
        node->column = lexer->columns;
    }
    node->type = TextNode;
    return node;
}

/* used to clone heading nodes when split by an <HR> */
Node *CloneNode( TidyDocImpl* doc, Node *element )
{
    Lexer* lexer = doc->lexer;
    Node *node = NewNode( lexer );

    node->start = lexer->lexsize;
    node->end   = lexer->lexsize;

    if ( element )
    {
        node->parent     = element->parent;
        node->type       = element->type;
        node->closed     = element->closed;
        node->implicit   = element->implicit;
        node->tag        = element->tag;
        node->element    = tmbstrdup( element->element );
        node->attributes = DupAttrs( doc, element->attributes );
    }
    return node;
}

/* Does, what CloneNode should do, clones the given node */
/* Maybe CloneNode is just buggy and could be modified   */
Node *CloneNodeEx( TidyDocImpl* doc, Node *element )
{
    Node *node = null;

    if ( element )
    {
        node = NewNode( doc->lexer );

        node->parent     = element->parent;
        node->start      = element->start;
        node->end        = element->end;
        node->type       = element->type;
        node->closed     = element->closed;
        node->implicit   = element->implicit;
        node->tag        = element->tag;
        node->element    = tmbstrdup( element->element );
        node->attributes = DupAttrs( doc, element->attributes );
    }
    return node;
}

/* free node's attributes */
void FreeAttrs( TidyDocImpl* doc, Node *node )
{

    while ( node->attributes )
    {
        AttVal *av = node->attributes;

        if ( av->attribute )
        {
            if ( ( tmbstrcasecmp(av->attribute, "id") == 0 ||
                   tmbstrcasecmp(av->attribute, "name") == 0 )
                 && IsAnchorElement(doc, node) )
            {
                RemoveAnchorByNode( doc, node );
            }
            MemFree( av->attribute );
        }

        MemFree( av->value );
        FreeNode( doc, av->asp );
        FreeNode( doc, av->php );

        node->attributes = av->next;
        MemFree(av);
    }
}

/* doesn't repair attribute list linkage */
void FreeAttribute( AttVal *av )
{
    MemFree( av->attribute );
    MemFree( av->value );
    MemFree( av );
}

/* remove attribute from node then free it
*/
void RemoveAttribute( Node *node, AttVal *attr )
{
    AttVal *av, *prev = null;

    for ( av = node->attributes; av; av = av->next )
    {
        if ( av == attr )
        {
            if ( prev )
                prev->next = attr->next;
            else
                node->attributes = attr->next;
            break;
        }
        prev = av;
    }
    FreeAttribute( attr );
}

/*
  Free document nodes by iterating through peers and recursing
  through children. Set next to null before calling FreeNode()
  to avoid freeing peer nodes. Doesn't patch up prev/next links.
 */
void FreeNode( TidyDocImpl* doc, Node *node )
{
    while ( node )
    {
        Node* next = node->next;

        MemFree( node->element );
        FreeAttrs( doc, node );
        FreeNode( doc, node->content );
        MemFree( node );

        node = next;
    }
}

Node* TextToken( Lexer *lexer )
{
    Node *node = NewNode( lexer );
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

/* used for creating preformatted text from Word2000 */
Node *NewLineNode( Lexer *lexer )
{
    Node *node = NewNode( lexer );
    node->start = lexer->lexsize;
    AddCharToLexer( lexer, (uint)'\n' );
    node->end = lexer->lexsize;
    return node;
}

/* used for adding a &nbsp; for Word2000 */
Node* NewLiteralTextNode( Lexer *lexer, ctmbstr txt )
{
    Node *node = NewNode( lexer );
    node->start = lexer->lexsize;
    AddStringToLexer( lexer, txt );
    node->end = lexer->lexsize;
    return node;
}

static Node* TagToken( TidyDocImpl* doc, uint type )
{
    Lexer* lexer = doc->lexer;
    Node* node = NewNode( lexer );
    node->type = type;
    node->element = tmbstrndup( lexer->lexbuf + lexer->txtstart,
                                lexer->txtend - lexer->txtstart );
    node->start = lexer->txtstart;
    node->end = lexer->txtstart;

    if ( type == StartTag || type == StartEndTag || type == EndTag )
        FindTag(doc, node);

    return node;
}

Node* CommentToken(Lexer *lexer)
{
    Node* node = NewNode( lexer );
    node->type = CommentTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

static Node* DocTypeToken(Lexer *lexer)
{
    Node* node = NewNode( lexer );
    node->type = DocTypeTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

static Node *PIToken(Lexer *lexer)
{
    Node *node = NewNode(lexer);
    node->type = ProcInsTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

static Node *AspToken(Lexer *lexer)
{
    Node* node = NewNode(lexer);
    node->type = AspTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

static Node *JsteToken(Lexer *lexer)
{
    Node* node = NewNode(lexer);
    node->type = JsteTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

/* Added by Baruch Even - handle PHP code too. */
static Node *PhpToken(Lexer *lexer)
{
    Node* node = NewNode(lexer);
    node->type = PhpTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

/* XML Declaration <?xml version='1.0' ... ?> */
static Node *XmlDeclToken(Lexer *lexer)
{
    Node* node = NewNode(lexer);
    node->type = XmlDecl;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

/* Word2000 uses <![if ... ]> and <![endif]> */
static Node *SectionToken(Lexer *lexer)
{
    Node* node = NewNode(lexer);
    node->type = SectionTag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

/* CDATA uses <![CDATA[ ... ]]> */
static Node *CDATAToken(Lexer *lexer)
{
    Node* node = NewNode(lexer);
    node->type = CDATATag;
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    return node;
}

void AddStringLiteral( Lexer* lexer, ctmbstr str )
{
    byte c;
    while( c = *str++ )
        AddCharToLexer( lexer, c );
}

void AddStringLiteralLen( Lexer* lexer, ctmbstr str, int len )
{
    byte c;
    int ix;

    for ( ix=0; ix < len && (c = *str++); ++ix )
        AddCharToLexer(lexer, c);
}

/* find doctype element */
Node *FindDocType( TidyDocImpl* doc )
{
    Node* node;
    for ( node = (doc->root ? doc->root->content : null);
          node && node->type != DocTypeTag; 
          node = node->next )
        /**/;
    return node;
}

/* find parent container element */
Node* FindContainer( Node* node )
{
    for ( node = (node ? node->parent : null);
          node && nodeHasCM(node, CM_INLINE);
          node = node->parent )
        /**/;

    return node;
}


/* find html element */
Node *FindHTML( TidyDocImpl* doc )
{
    Node *node = doc->root;
    for ( node = (node ? node->content : null);
          node && !nodeIsHTML(node); 
          node = node->next )
        /**/;

    return node;
}

Node *FindHEAD( TidyDocImpl* doc )
{
    Node *node = FindHTML( doc );

    if ( node )
    {
        for ( node = node->content;
              node && !nodeIsHEAD(node); 
              node = node->next )
            /**/;
    }

    return node;
}

Node *FindBody( TidyDocImpl* doc )
{
    Node *node = ( doc->root ? doc->root->content : null );

    while ( node && !nodeIsHTML(node) )
        node = node->next;

    if (node == null)
        return null;

    node = node->content;
    while ( node && !nodeIsBODY(node) && !nodeIsFRAMESET(node) )
        node = node->next;

    if ( node && nodeIsFRAMESET(node) )
    {
        node = node->content;
        while ( node && !nodeIsNOFRAMES(node) )
            node = node->next;

        if ( node )
        {
            node = node->content;
            while ( node && !nodeIsBODY(node) )
                node = node->next;
        }
    }

    return node;
}

/* add meta element for Tidy */
Bool AddGenerator( TidyDocImpl* doc )
{
    AttVal *attval;
    Node *node;
    Node *head = FindHEAD( doc );
    tmbchar buf[256];
    
    if (head)
    {
#ifdef PLATFORM_NAME
        sprintf( buf, "HTML Tidy for "PLATFORM_NAME" (vers %s), see www.w3.org",
                 tidyReleaseDate() );
#else
        sprintf( buf, "HTML Tidy (vers %s), see www.w3.org", tidyReleaseDate() );
#endif

        for ( node = head->content; node; node = node->next )
        {
            if ( nodeIsMETA(node) )
            {
                attval = GetAttrByName(node, "name");

                if ( attval && attval->value &&
                     tmbstrcasecmp(attval->value, "generator") == 0 )
                {
                    attval = GetAttrByName(node, "content");

                    if ( attval && attval->value &&
                         tmbstrncasecmp(attval->value, "HTML Tidy", 9) == 0 )
                    {
                        /* update the existing content to reflect the */
                        /* actual version of Tidy currently being used */
                        
                        MemFree(attval->value);
                        attval->value = tmbstrdup(buf);
                        return no;
                    }
                }
            }
        }

        if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
        {
            node = InferredTag( doc, "meta" );
            AddAttribute( doc, node, "content", buf );
            AddAttribute( doc, node, "name", "generator" );
            InsertNodeAtStart( head, node );
            return yes;
        }
    }

    return no;
}

/* examine <!DOCTYPE> to identify version */
int FindGivenVersion( TidyDocImpl* doc, Node* doctype )
{
    Lexer* lexer = doc->lexer;
    tmbstr p, s = lexer->lexbuf+doctype->start;
    ctmbstr nm;
    uint i, j;
    uint len;

    /* if root tag for doctype isn't html give up now */
    if ( tmbstrncasecmp(s, "html ", 5) != 0 )
        return 0;

    s += 5; /* if all is well s -> SYSTEM or PUBLIC */

    if ( !CheckDocTypeKeyWords(lexer, doctype) )
        ReportWarning( doc, doctype, null, DTYPE_NOT_UPPER_CASE );


    /* give up if all we are given is the system id for the doctype */
    if ( tmbstrncasecmp(s, "SYSTEM ", 7) == 0 )
    {
        /* but at least ensure the case is correct */
        if ( tmbstrncmp(s, "SYSTEM", 6) != 0 )
             memcpy( s, "SYSTEM", 6 );  /* No null terminator! */
        return 0;  /* unrecognized */
    }

    if (tmbstrncasecmp(s, "PUBLIC ", 7) == 0)
    {
        if ( tmbstrncmp(s, "PUBLIC", 6) != 0 )
            memcpy( s, "PUBLIC", 6 );   /* No null terminator! */
    }
    else if ( lexer->doctype == VERS_UNKNOWN )
        lexer->bad_doctype = yes;

    for ( i = doctype->start; i < doctype->end; ++i )
    {
        if ( lexer->lexbuf[i] == '"' )
        {
            if ( tmbstrncmp(lexer->lexbuf+i+1, "-//W3C//DTD ", 12) == 0 )
            {
                p = lexer->lexbuf + i + 13;

                /* compute length of identifier e.g. "HTML 4.0 Transitional" */
                for ( j=i+13; j<doctype->end && lexer->lexbuf[j] != '/'; ++j )
                    /**/;
                len = j - i - 13;

                for (j = 0; j < W3C_VERSIONS; ++j)
                {
                    nm = W3C_Version[j].name;
                    if ( len == tmbstrlen(nm) && tmbstrncmp(p, nm, len) == 0 )
                        return W3C_Version[j].code;

                    nm = W3C_Version[j].voyager_name;
                    if ( len == tmbstrlen(nm) && tmbstrncmp(p, nm, len) == 0 )
                        return W3C_Version[j].code;
                }

                /* else unrecognized version */
            }
            else if ( tmbstrncmp(lexer->lexbuf+i+1, "-//IETF//DTD ", 13) == 0 )
            {
                p = lexer->lexbuf + i + 14;

                /* compute length of identifier e.g. "HTML 2.0" */
                for ( j=i+14; j<doctype->end && lexer->lexbuf[j] != '/'; ++j )
                    /**/;
                len = j - i - 14;

                nm = W3C_Version[0].name;
                if ( len == tmbstrlen(nm) && tmbstrncmp(p, nm, len) == 0 )
                    return W3C_Version[0].code;

                /* else unrecognized version */
            }
            break;
        }
    }

    return 0;
}

/* return true if substring s is in p and isn't all in upper case */
/* this is used to check the case of SYSTEM, PUBLIC, DTD and EN */
/* len is how many characters to check in p */

static Bool FindBadSubString( ctmbstr s, ctmbstr p, int len )
{
    int n = tmbstrlen(s);

    while (n < len)
    {
        if (tmbstrncasecmp(s, p, n) == 0)
            return (tmbstrncmp(s, p, n) != 0);

        ++p;
        --len;
    }

    return 0;
}

Bool CheckDocTypeKeyWords(Lexer *lexer, Node *doctype)
{
    ctmbstr s = lexer->lexbuf+doctype->start;
    int len = doctype->end - doctype->start;

    return !(
        FindBadSubString("SYSTEM", s, len) ||
        FindBadSubString("PUBLIC", s, len) ||
        FindBadSubString("//DTD", s, len) ||
        FindBadSubString("//W3C", s, len) ||
        FindBadSubString("//EN", s, len)
        );
}

ctmbstr HTMLVersionName( TidyDocImpl* doc )
{
    uint vers = ApparentVersion( doc );
    return HTMLVersionNameFromCode( vers, doc->lexer->isvoyager );
}

ctmbstr HTMLVersionNameFromCode( uint vers, Bool isXhtml )
{
  int ix;
  for ( ix=0; ix < W3C_VERSIONS; ++ix )
  {
    if ( vers == W3C_Version[ix].code )
    {
        if ( isXhtml )
            return W3C_Version[ix].voyager_name;
        return W3C_Version[ix].name;
    }
  }
  return "HTML Proprietary";
}


static void FixHTMLNameSpace( TidyDocImpl* doc, ctmbstr profile )
{
    Node* node = FindHTML( doc );
    if ( node )
    {
        AttVal *attr = GetAttrByName( node, "xmlns" );
        if ( attr )
        {
            if ( tmbstrcmp(attr->value, profile) != 0 )
            {
                ReportWarning( doc, node, null, INCONSISTENT_NAMESPACE );
                MemFree( attr->value );
                attr->value = tmbstrdup( profile );
            }
        }
        else
        {
            attr = NewAttribute();
            attr->delim = '"';
            attr->attribute = tmbstrdup("xmlns");
            attr->value = tmbstrdup(profile);
            attr->dict = FindAttribute( doc, attr );
            attr->next = node->attributes;
            node->attributes = attr;
        }
    }
}


/* Put DOCTYPE declaration between the
** <?xml version "1.0" ... ?> declaration, if any,
** and the <html> tag.  Should also work for any comments, 
** etc. that may precede the <html> tag.
*/


static Node* NewDocTypeNode( TidyDocImpl* doc )
{
    Node* doctype = null;
    Node* html = FindHTML( doc );
    Node* root = doc->root;
    if ( !html )
        return null;

    doctype = NewNode( null );
    doctype->type = DocTypeTag;
    doctype->next = html;
    doctype->parent = root;

    if ( html == root->content )
    {
        /* No <?xml ... ?> declaration. */
        root->content->prev = doctype;
        root->content = doctype;
        doctype->prev = null;
    }
    else
    {
        /* we have an <?xml ... ?> declaration. */
        doctype->prev = html->prev;
        doctype->prev->next = doctype;
    }
    html->prev = doctype;
    return doctype;
}

Bool SetXHTMLDocType( TidyDocImpl* doc )
{
    Lexer *lexer = doc->lexer;
    ctmbstr fpi = null, sysid = null, dtdsub = null, name_space = XHTML_NAMESPACE;
    int dtdlen = 0;
    Node *doctype = FindDocType( doc );
    uint dtmode = cfg(doc, TidyDoctypeMode);

    FixHTMLNameSpace( doc, name_space );

    if ( dtmode == TidyDoctypeOmit )
    {
        if ( doctype )
            DiscardElement( doc, doctype );
        return yes;
    }

    if ( dtmode == TidyDoctypeAuto )
    {
        /* see what flavor of XHTML this document matches */
        if ( lexer->versions & VERS_HTML40_STRICT )
        {  /* use XHTML strict */
            fpi = "-//W3C//DTD XHTML 1.0 Strict//EN";
            sysid = voyager_strict;
        }
        else if ( lexer->versions & VERS_FRAMESET )
        {   /* use XHTML frames */
            fpi = "-//W3C//DTD XHTML 1.0 Frameset//EN";
            sysid = voyager_frameset;
        }
        else if (lexer->versions & VERS_LOOSE)
        {
            fpi = "-//W3C//DTD XHTML 1.0 Transitional//EN";
            sysid = voyager_loose;
        }
        else /* proprietary */
        {
            fpi = null;
            sysid = "";
        
            if ( doctype )
                DiscardElement( doc, doctype );
        }
    }
    else if ( dtmode == TidyDoctypeStrict )
    {
        fpi = "-//W3C//DTD XHTML 1.0 Strict//EN";
        sysid = voyager_strict;
    }
    else if ( dtmode == TidyDoctypeLoose )
    {
        fpi = "-//W3C//DTD XHTML 1.0 Transitional//EN";
        sysid = voyager_loose;
    }

    if ( dtmode == TidyDoctypeUser && cfgStr(doc, TidyDoctype) )
    {
        fpi = cfgStr( doc, TidyDoctype );
        sysid = "";
    }

    if ( !fpi )
        return no;

    if ( doctype )
    {
      /* Look for internal DTD subset */
      if ( cfgBool(doc, TidyXhtmlOut) || cfgBool(doc, TidyXmlOut) )
      {
        ctmbstr start = lexer->lexbuf + doctype->start;
        int len = doctype->end - doctype->start + 1;
        int dtdbeg = tmbstrnchr( start, len, '[' );
        if ( dtdbeg >= 0 )
        {
          int dtdend = tmbstrnchr( start+dtdbeg, len-dtdbeg, ']' );
          if ( dtdend >= 0 )
          {
            dtdlen = dtdend + 1;
            dtdsub = start + dtdbeg;
          }
        }
      }
    }
    else
    {
        if ( !(doctype = NewDocTypeNode( doc )) )
            return no;
    }

    lexer->txtstart = lexer->txtend = lexer->lexsize;

   /* add public identifier */
    AddStringLiteral(lexer, "html PUBLIC ");

    /* check if the fpi is quoted or not */
    if (fpi[0] == '"')
        AddStringLiteral(lexer, fpi);
    else
    {
        AddStringLiteral(lexer, "\"");
        AddStringLiteral(lexer, fpi);
        AddStringLiteral(lexer, "\"");
    }

    if ( tmbstrlen(sysid) + 6 >= cfg(doc, TidyWrapLen) )
        AddStringLiteral(lexer, "\n\"");
    else
        AddStringLiteral(lexer, "\n    \"");

    /* add system identifier */
    AddStringLiteral(lexer, sysid);
    AddStringLiteral(lexer, "\"");

    if ( dtdlen > 0 && dtdsub )
    {
      AddCharToLexer( lexer, ' ' );
      AddStringLiteralLen( lexer, dtdsub, dtdlen );
    }

    lexer->txtend = lexer->lexsize;

    doctype->start = lexer->txtstart;
    doctype->end = lexer->txtend;

    return no;
}

int ApparentVersion( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    switch (lexer->doctype)
    {
    case VERS_UNKNOWN:
        return HTMLVersion( doc );

    case VERS_HTML20:
        if ( lexer->versions & VERS_HTML20 )
            return VERS_HTML20;
        break;

    case VERS_HTML32:
        if ( lexer->versions & VERS_HTML32 )
            return VERS_HTML32;
        break; /* to replace old version by new */

    case VERS_HTML40_STRICT:
        if ( lexer->versions & VERS_HTML40_STRICT )
            return VERS_HTML40_STRICT;
        break;

    case VERS_HTML40_LOOSE:
        if ( lexer->versions & VERS_HTML40_LOOSE )
            return VERS_HTML40_LOOSE;
        break; /* to replace old version by new */

    case VERS_FRAMESET:
        if ( lexer->versions & VERS_FRAMESET )
            return VERS_FRAMESET;
        break;
    }

    /* 
     kludge to avoid error appearing at end of file
     it would be better to note the actual position
     when first encountering the doctype declaration
    */
    lexer->lines = 1;
    lexer->columns = 1;
    ReportWarning( doc, null, null, INCONSISTENT_VERSION);
    return HTMLVersion( doc );
}


/* fixup doctype if missing */
Bool FixDocType( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    Node* doctype = FindDocType( doc );
    uint i, guessed = VERS_HTML40_STRICT;
    uint dtmode = cfg( doc, TidyDoctypeMode );

    if ( lexer->bad_doctype )
        ReportWarning( doc, doc->root, doctype, MALFORMED_DOCTYPE );

    if ( dtmode == TidyDoctypeOmit )
    {
        if ( doctype )
            DiscardElement( doc, doctype );
        return yes;
    }

    if ( cfgBool(doc, TidyXmlOut) )
        return yes;

    if ( dtmode == TidyDoctypeStrict )
    {
        DiscardElement( doc, doctype );
        doctype = null;
        guessed = VERS_HTML40_STRICT;
    }
    else if ( dtmode == TidyDoctypeLoose )
    {
        DiscardElement( doc, doctype );
        doctype = null;
        guessed = VERS_HTML40_LOOSE;
    }
    else if ( dtmode == TidyDoctypeAuto )
    {
        if ( doctype )
        {
            switch ( lexer->doctype )
            {
            case VERS_UNKNOWN:
                return no;

            case VERS_HTML20:
                if (lexer->versions & VERS_HTML20)
                    return yes;
                break; /* to replace old version by new */

            case VERS_HTML32:
                if (lexer->versions & VERS_HTML32)
                    return yes;
                break; /* to replace old version by new */

            case VERS_HTML40_STRICT:
                if (lexer->versions & VERS_HTML40_STRICT)
                    return yes;
                break; /* to replace old version by new */

            case VERS_HTML40_LOOSE:
                if (lexer->versions & VERS_HTML40_LOOSE)
                    return yes;
                break; /* to replace old version by new */

            case VERS_FRAMESET:
                if (lexer->versions & VERS_FRAMESET)
                    return yes;
                break; /* to replace old version by new */
            }

            /* INCONSISTENT_VERSION warning is now issued by ApparentVersion() */
        }

        /* choose new doctype */
        guessed = HTMLVersion( doc );
    }

    if ( guessed == VERS_UNKNOWN )
        return no;

    /* for XML use the Voyager system identifier */
    if ( !cfgBool(doc, TidyHtmlOut) &&
         ( cfgBool(doc, TidyXmlOut) || cfgBool(doc, TidyXmlTags) ||
           lexer->isvoyager ) )
    {
        if ( doctype )
            DiscardElement( doc, doctype );

        FixHTMLNameSpace( doc, XHTML_NAMESPACE );
    }

    if ( !doctype )
    {
        if ( !(doctype = NewDocTypeNode( doc )) )
            return no;
    }

    lexer->txtstart = lexer->txtend = lexer->lexsize;

   /* use the appropriate public identifier */
    AddStringLiteral(lexer, "html PUBLIC ");

    if ( dtmode == TidyDoctypeUser && cfgStr(doc, TidyDoctype) )
    { 
       AddStringLiteral(lexer, "\"" );
       AddStringLiteral(lexer, cfgStr(doc, TidyDoctype) ); 
       AddStringLiteral(lexer, "\"" );
    }
    else if (guessed == VERS_HTML20)
        AddStringLiteral(lexer, "\"-//IETF//DTD HTML 2.0//EN\"");
    else
    {
        AddStringLiteral(lexer, "\"-//W3C//DTD ");

        for (i = 0; i < W3C_VERSIONS; ++i)
        {
            if (guessed == W3C_Version[i].code)
            {
                AddStringLiteral(lexer, W3C_Version[i].name);
                break;
            }
        }

        AddStringLiteral(lexer, "//EN\"");
    }

    lexer->txtend = lexer->lexsize;

    doctype->start = lexer->txtstart;
    doctype->end = lexer->txtend;

    return yes;
}

/* ensure XML document starts with <?XML version="1.0"?> */
/* add encoding attribute if not using ASCII or UTF-8 output */
Bool FixXmlDecl( TidyDocImpl* doc )
{
    Node* xml;
    AttVal *version, *encoding;
    Lexer*lexer = doc->lexer;
    Node* root = doc->root;

    if ( root->content && root->content->type == XmlDecl )
    {
        xml = root->content;
    }
    else
    {
        xml = NewNode(lexer);
        xml->type = XmlDecl;
        xml->next = root->content;
        
        if ( root->content )
        {
            root->content->prev = xml;
            xml->next = root->content;
        }
        
        root->content = xml;
    }

    version = GetAttrByName(xml, "version");
    encoding = GetAttrByName(xml, "encoding");

    /*
      We need to insert a check if declared encoding 
      and output encoding mismatch and fix the XML
      declaration accordingly!!!
    */

    if ( encoding == null && cfg(doc, TidyOutCharEncoding) != UTF8 )
    {
        ctmbstr enc = null;
        switch ( cfg(doc, TidyOutCharEncoding) )
        {
        case LATIN1:    enc = "iso-8859-1";   break;
        case ISO2022:   enc = "iso-2022";     break;

        /* TODO: Add declarations for other encodings!
        case RAW:       enc = "raw";          break;
        case MACROMAN:  enc = "mac";          break;
        */

#if SUPPORT_UTF16_ENCODINGS
        case UTF16LE:   enc = "UTF-16LE";      break;
        case UTF16BE:   enc = "UTF-16BE";      break;
        case UTF16:     enc = "UTF-16";        break;
#endif
        /* TODO: Add declarations for other encodings!
        case WIN1252:   enc = "win1252";      break;
#if SUPPORT_ASIAN_ENCODINGS
        case BIG5:      enc = "big5";         break;
        case SHIFTJIS:  enc = "shiftjis";     break;
#endif
        */
        }
        if ( enc )
            AddAttribute( doc, xml, "encoding", enc );
    }

    if ( version == null )
        AddAttribute( doc, xml, "version", "1.0" );
    return yes;
}

Node* InferredTag( TidyDocImpl* doc, ctmbstr name )
{
    Lexer *lexer = doc->lexer;
    Node *node = NewNode( lexer );
    node->type = StartTag;
    node->implicit = yes;
    node->element = tmbstrdup(name);
    node->start = lexer->txtstart;
    node->end = lexer->txtend;
    FindTag( doc, node );
    return node;
}

Bool ExpectsContent(Node *node)
{
    if (node->type != StartTag)
        return no;

    /* unknown element? */
    if (node->tag == null)
        return yes;

    if (node->tag->model & CM_EMPTY)
        return no;

    return yes;
}

/*
  create a text node for the contents of
  a CDATA element like style or script
  which ends with </foo> for some foo.
*/
static Bool IsQuote( int c )
{
  return ( c == '\'' || c == '\"' );
}

Node *GetCDATA( TidyDocImpl* doc, Node *container )
{
    Lexer* lexer = doc->lexer;
    uint c, lastc = 0, len, qt = 0, esc = 0;
    int i, start = -1;
    Bool endtag = no;
    Bool begtag = no;

    if ( IsJavaScript(container) )
      esc = '\\';

    lexer->lines = doc->docIn->curline;
    lexer->columns = doc->docIn->curcol;
    lexer->waswhite = no;
    lexer->txtstart = lexer->txtend = lexer->lexsize;


    while ( (c = ReadChar(doc->docIn)) != EndOfStream )
    {
        /* treat \r\n as \n and \r as \n */
        if ( qt > 0 )
        {
            if ( c == qt && (!esc || lastc != esc) )
            {
                qt = 0;
            }
            else if (c == '/' && lastc == '<')
            {
                start = lexer->lexsize + 1;  /* to first letter */
            }
            else if ( c == '>' && start > 0 )
            {
                lexer->lines = doc->docIn->curline;
                lexer->columns = doc->docIn->curcol - 3;

                ReportWarning( doc, null, null, BAD_CDATA_CONTENT );

                /* if javascript insert backslash before / */
                if ( esc )
                {
                    for (i = lexer->lexsize; i > start-1; --i)
                        lexer->lexbuf[i] = lexer->lexbuf[i-1];

                    lexer->lexbuf[start-1] = (byte) esc;
                    lexer->lexsize++;
                }

                start = -1;
            }
        }
        else if ( IsQuote(c) && (!esc || lastc != esc) )
        {
          qt = c;
        }
        else if ( IsXMLLetter(c) && lastc == '<' )
        {
            start = lexer->lexsize;  /* to first letter */
            endtag = no;
            begtag = yes;
        }
        /*
        else if (c == '!' && lastc == '<')  Cancel start tag
        {
            start = -1;
            endtag = no;
            begtag = no;
        }
        */
        else if (c == '/' && lastc == '<')
        {
            start = lexer->lexsize + 1;  /* to first letter */
            endtag = yes;
            begtag = no;
        }
        else if ( c == '>' && start > 0 )  /* End of begin or end tag */
        {
            uint decr = 2;
            if ( endtag && 
                 ( (len = lexer->lexsize - start) == tmbstrlen(container->element) ) &&
                 tmbstrncasecmp(lexer->lexbuf+start, container->element, len) == 0 )
            {
                lexer->txtend = start - decr;
                lexer->lexsize = start - decr; /* #433857 - fix by Huajun Zeng 26 Apr 01 */
                break;
            }

            /* Unquoted markup will end SCRIPT or STYLE elements 
            */
            lexer->lines = doc->docIn->curline;
            lexer->columns = doc->docIn->curcol - 3;

            ReportWarning( doc, null, null, BAD_CDATA_CONTENT );
            if ( begtag )
              decr = 1;
            lexer->txtend = start - decr;
            lexer->lexsize = start - decr;
            break;
        }
        /* #427844 - fix by Markus Hoenicka 21 Oct 00 */
        else if (c == '\r')
        {
            if (begtag || endtag) 
            { 
                continue; /* discard whitespace in endtag */ 
            } 
            else 
            { 
                c = ReadChar(doc->docIn);

                if (c != '\n')
                    UngetChar(c, doc->docIn);

                c = '\n';
            }
        } 
        else if ((c == '\n' || c == '\t' || c == ' ') && (begtag||endtag) )
        { 
            continue; /* discard whitespace in endtag */ 
        }
        
        AddCharToLexer(lexer, (uint)c);
        lexer->txtend = lexer->lexsize;
        lastc = c;
    }

    if (c == EndOfStream)
        ReportWarning( doc, container, null, MISSING_ENDTAG_FOR );

    if (lexer->txtend > lexer->txtstart)
        return lexer->token = TextToken(lexer);

    return null;
}

void UngetToken( TidyDocImpl* doc )
{
    doc->lexer->pushed = yes;
}

/*
  modes for GetToken()

  MixedContent   -- for elements which don't accept PCDATA
  Preformatted   -- white space preserved as is
  IgnoreMarkup   -- for CDATA elements such as script, style
*/

Node* GetToken( TidyDocImpl* doc, uint mode )
{
    Lexer* lexer = doc->lexer;
    int c, lastc, badcomment = 0;
    Bool isempty, inDTDSubset = no;
    AttVal *attributes = null;

    if (lexer->pushed)
    {
        /* duplicate inlines in preference to pushed text nodes when appropriate */
        if (lexer->token->type != TextNode || (!lexer->insert && !lexer->inode))
        {
            lexer->pushed = no;
            return lexer->token;
        }
    }

    /* at start of block elements, unclosed inline
       elements are inserted into the token stream */
     
    if (lexer->insert || lexer->inode)
        return InsertedToken( doc );

    lexer->lines = doc->docIn->curline;
    lexer->columns = doc->docIn->curcol;
    lexer->waswhite = no;

    lexer->txtstart = lexer->txtend = lexer->lexsize;

    while ((c = ReadChar(doc->docIn)) != EndOfStream)
    {
        if (lexer->insertspace && !(mode & IgnoreWhitespace))
        {
            AddCharToLexer(lexer, ' ');
            lexer->waswhite = yes;
            lexer->insertspace = no;
        }

        /* treat \r\n as \n and \r as \n */

        if (c == '\r')
        {
            c = ReadChar(doc->docIn);

            if (c != '\n')
                UngetChar(c, doc->docIn);

            c = '\n';
        }

        AddCharToLexer(lexer, (uint)c);

        switch (lexer->state)
        {
            case LEX_CONTENT:  /* element content */

                /*
                 Discard white space if appropriate. Its cheaper
                 to do this here rather than in parser methods
                 for elements that don't have mixed content.
                */
                if (IsWhite(c) && (mode == IgnoreWhitespace) 
                      && lexer->lexsize == lexer->txtstart + 1)
                {
                    --(lexer->lexsize);
                    lexer->waswhite = no;
                    lexer->lines = doc->docIn->curline;
                    lexer->columns = doc->docIn->curcol;
                    continue;
                }

                if (c == '<')
                {
                    lexer->state = LEX_GT;
                    continue;
                }

                if (IsWhite(c))
                {
                    /* was previous character white? */
                    if (lexer->waswhite)
                    {
                        if (mode != Preformatted && mode != IgnoreMarkup)
                        {
                            --(lexer->lexsize);
                            lexer->lines = doc->docIn->curline;
                            lexer->columns = doc->docIn->curcol;
                        }
                    }
                    else /* prev character wasn't white */
                    {
                        lexer->waswhite = yes;
                        lastc = c;

                        if (mode != Preformatted && mode != IgnoreMarkup && c != ' ')
                            ChangeChar(lexer, ' ');
                    }

                    continue;
                }
                else if (c == '&' && mode != IgnoreMarkup)
                    ParseEntity( doc, mode );

                /* this is needed to avoid trimming trailing whitespace */
                if (mode == IgnoreWhitespace)
                    mode = MixedContent;

                lexer->waswhite = no;
                continue;

            case LEX_GT:  /* < */

                /* check for endtag */
                if (c == '/')
                {
                    if ((c = ReadChar(doc->docIn)) == EndOfStream)
                    {
                        UngetChar(c, doc->docIn);
                        continue;
                    }

                    AddCharToLexer(lexer, c);

                    if (IsLetter(c))
                    {
                        lexer->lexsize -= 3;
                        lexer->txtend = lexer->lexsize;
                        UngetChar(c, doc->docIn);
                        lexer->state = LEX_ENDTAG;
                        lexer->lexbuf[lexer->lexsize] = '\0';  /* debug */
                        doc->docIn->curcol -= 2;

                        /* if some text before the </ return it now */
                        if (lexer->txtend > lexer->txtstart)
                        {
                            /* trim space character before end tag */
                            if (mode == IgnoreWhitespace && lexer->lexbuf[lexer->lexsize - 1] == ' ')
                            {
                                lexer->lexsize -= 1;
                                lexer->txtend = lexer->lexsize;
                            }

                            return lexer->token = TextToken(lexer);
                        }

                        continue;       /* no text so keep going */
                    }

                    /* otherwise treat as CDATA */
                    lexer->waswhite = no;
                    lexer->state = LEX_CONTENT;
                    continue;
                }

                if (mode == IgnoreMarkup)
                {
                    /* otherwise treat as CDATA */
                    lexer->waswhite = no;
                    lexer->state = LEX_CONTENT;
                    continue;
                }

                /*
                   look out for comments, doctype or marked sections
                   this isn't quite right, but its getting there ...
                */
                if (c == '!')
                {
                    c = ReadChar(doc->docIn);

                    if (c == '-')
                    {
                        c = ReadChar(doc->docIn);

                        if (c == '-')
                        {
                            lexer->state = LEX_COMMENT;  /* comment */
                            lexer->lexsize -= 2;
                            lexer->txtend = lexer->lexsize;

                            /* if some text before < return it now */
                            if (lexer->txtend > lexer->txtstart)
                                return lexer->token = TextToken(lexer);

                            lexer->txtstart = lexer->lexsize;
                            continue;
                        }

                        ReportWarning( doc, null, null, MALFORMED_COMMENT );
                    }
                    else if (c == 'd' || c == 'D')
                    {
                        lexer->state = LEX_DOCTYPE; /* doctype */
                        lexer->lexsize -= 2;
                        lexer->txtend = lexer->lexsize;
                        mode = IgnoreWhitespace;

                        /* skip until white space or '>' */

                        for (;;)
                        {
                            c = ReadChar(doc->docIn);

                            if (c == EndOfStream || c == '>')
                            {
                                UngetChar(c, doc->docIn);
                                break;
                            }


                            if (!IsWhite(c))
                                continue;

                            /* and skip to end of whitespace */

                            for (;;)
                            {
                                c = ReadChar(doc->docIn);

                                if (c == EndOfStream || c == '>')
                                {
                                    UngetChar(c, doc->docIn);
                                    break;
                                }


                                if (IsWhite(c))
                                    continue;

                                UngetChar(c, doc->docIn);
                                break;
                            }

                            break;
                        }

                        /* if some text before < return it now */
                        if (lexer->txtend > lexer->txtstart)
                            return lexer->token = TextToken(lexer);

                        lexer->txtstart = lexer->lexsize;
                        continue;
                    }
                    else if (c == '[')
                    {
                        /* Word 2000 embeds <![if ...]> ... <![endif]> sequences */
                        lexer->lexsize -= 2;
                        lexer->state = LEX_SECTION;
                        lexer->txtend = lexer->lexsize;

                        /* if some text before < return it now */
                        if (lexer->txtend > lexer->txtstart)
                            return lexer->token = TextToken(lexer);

                        lexer->txtstart = lexer->lexsize;
                        continue;
                    }



                    /* else swallow characters up to and including next '>' */
                    while ((c = ReadChar(doc->docIn)) != '>')
                    {
                        if (c == EndOfStream)
                        {
                            UngetChar(c, doc->docIn);
                            break;
                        }
                    }

                    lexer->lexsize -= 2;
                    lexer->lexbuf[lexer->lexsize] = '\0';
                    lexer->state = LEX_CONTENT;
                    continue;
                }

                /*
                   processing instructions
                */

                if (c == '?')
                {
                    lexer->lexsize -= 2;
                    lexer->state = LEX_PROCINSTR;
                    lexer->txtend = lexer->lexsize;

                    /* if some text before < return it now */
                    if (lexer->txtend > lexer->txtstart)
                        return lexer->token = TextToken(lexer);

                    lexer->txtstart = lexer->lexsize;
                    continue;
                }

                /* Microsoft ASP's e.g. <% ... server-code ... %> */
                if (c == '%')
                {
                    lexer->lexsize -= 2;
                    lexer->state = LEX_ASP;
                    lexer->txtend = lexer->lexsize;

                    /* if some text before < return it now */
                    if (lexer->txtend > lexer->txtstart)
                        return lexer->token = TextToken(lexer);

                    lexer->txtstart = lexer->lexsize;
                    continue;
                }

                /* Netscapes JSTE e.g. <# ... server-code ... #> */
                if (c == '#')
                {
                    lexer->lexsize -= 2;
                    lexer->state = LEX_JSTE;
                    lexer->txtend = lexer->lexsize;

                    /* if some text before < return it now */
                    if (lexer->txtend > lexer->txtstart)
                        return lexer->token = TextToken(lexer);

                    lexer->txtstart = lexer->lexsize;
                    continue;
                }

                /* check for start tag */
                if (IsLetter(c))
                {
                    UngetChar(c, doc->docIn);     /* push back letter */
                    lexer->lexsize -= 2;      /* discard "<" + letter */
                    lexer->txtend = lexer->lexsize;
                    lexer->state = LEX_STARTTAG;         /* ready to read tag name */

                    /* if some text before < return it now */
                    if (lexer->txtend > lexer->txtstart)
                        return lexer->token = TextToken(lexer);

                    continue;       /* no text so keep going */
                }

                /* otherwise treat as CDATA */
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                continue;

            case LEX_ENDTAG:  /* </letter */
                lexer->txtstart = lexer->lexsize - 1;
                doc->docIn->curcol += 2;
                c = ParseTagName( doc );
                lexer->token = TagToken( doc, EndTag );  /* create endtag token */
                lexer->lexsize = lexer->txtend = lexer->txtstart;

                /* skip to '>' */
                while (c != '>')
                {
                    c = ReadChar(doc->docIn);

                    if (c == EndOfStream)
                        break;
                }

                if (c == EndOfStream)
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token;  /* the endtag token */

            case LEX_STARTTAG: /* first letter of tagname */
                lexer->txtstart = lexer->lexsize - 1; /* set txtstart to first letter */
                c = ParseTagName( doc );
                isempty = no;
                attributes = null;
                lexer->token = TagToken( doc, (isempty ? StartEndTag : StartTag) );

                /* parse attributes, consuming closing ">" */
                if (c != '>')
                {
                    if (c == '/')
                        UngetChar(c, doc->docIn);

                    attributes = ParseAttrs( doc, &isempty );
                }

                if (isempty)
                    lexer->token->type = StartEndTag;

                lexer->token->attributes = attributes;
                lexer->lexsize = lexer->txtend = lexer->txtstart;


                /* swallow newline following start tag */
                /* special check needed for CRLF sequence */
                /* this doesn't apply to empty elements */
                /* nor to preformatted content that needs escaping */

                if ( ( mode != Preformatted || PreContent(doc, lexer->token) ) &&
                     ( ExpectsContent(lexer->token) || 
                       nodeIsBR(lexer->token) )
                   )
                {
                    c = ReadChar(doc->docIn);

                    if (c == '\r')
                    {
                        c = ReadChar(doc->docIn);

                        if (c != '\n')
                            UngetChar(c, doc->docIn);
                    }
                    else if (c != '\n' && c != '\f')
                        UngetChar(c, doc->docIn);

                    lexer->waswhite = yes;  /* to swallow leading whitespace */
                }
                else
                    lexer->waswhite = no;

                lexer->state = LEX_CONTENT;
                if (lexer->token->tag == null)
                    ReportError( doc, null, lexer->token, UNKNOWN_ELEMENT );
                else if ( !cfgBool(doc, TidyXmlTags) )
                {
                    Node* curr = lexer->token;
                    ConstrainVersion( doc, curr->tag->versions );
                    
                    if ( curr->tag->versions & VERS_PROPRIETARY )
                    {
                        if ( !cfgBool(doc, TidyMakeClean) ||
                             ( !nodeIsNOBR(curr) && !nodeIsWBR(curr) ) )
                        {
                            ReportWarning( doc, null, curr, PROPRIETARY_ELEMENT );

                            if ( nodeIsLAYER(curr) )
                                doc->badLayout |= USING_LAYER;
                            else if ( nodeIsSPACER(curr) )
                                doc->badLayout |= USING_SPACER;
                            else if ( nodeIsNOBR(curr) )
                                doc->badLayout |= USING_NOBR;
                        }
                    }

                    if ( curr->tag->chkattrs )
                        curr->tag->chkattrs( doc, curr );
                    else
                        CheckAttributes( doc, curr );

                    /* should this be called before attribute checks? */
                    RepairDuplicateAttributes( doc, curr );
                }
                return lexer->token;  /* return start tag */

            case LEX_COMMENT:  /* seen <!-- so look for --> */

                if (c != '-')
                    continue;

                c = ReadChar(doc->docIn);
                AddCharToLexer(lexer, c);

                if (c != '-')
                    continue;

            end_comment:
                c = ReadChar(doc->docIn);

                if (c == '>')
                {
                    if (badcomment)
                        ReportWarning( doc, null, null, MALFORMED_COMMENT );

                    lexer->txtend = lexer->lexsize;
                    lexer->lexbuf[lexer->lexsize] = '\0';
                    lexer->state = LEX_CONTENT;
                    lexer->waswhite = no;
                    lexer->token = CommentToken(lexer);

                    /* now look for a line break */

                    c = ReadChar(doc->docIn);

                    if (c == '\r')
                    {
                        c = ReadChar(doc->docIn);

                        if (c != '\n')
                            lexer->token->linebreak = yes;
                    }

                    if (c == '\n')
                        lexer->token->linebreak = yes;
                    else
                        UngetChar(c, doc->docIn);

                    return lexer->token;
                }

                /* note position of first such error in the comment */
                if (!badcomment)
                {
                    lexer->lines = doc->docIn->curline;
                    lexer->columns = doc->docIn->curcol - 3;
                }

                badcomment++;

                if ( cfgBool(doc, TidyFixComments) )
                    lexer->lexbuf[lexer->lexsize - 2] = '=';

                AddCharToLexer(lexer, c);

                /* if '-' then look for '>' to end the comment */
                if (c == '-')
                    goto end_comment;

                /* otherwise continue to look for --> */
                lexer->lexbuf[lexer->lexsize - 2] = '=';
                continue; 

            case LEX_DOCTYPE:  /* seen <!d so look for '>' munging whitespace */

                if (IsWhite(c))
                {
                    if (lexer->waswhite)
                        lexer->lexsize -= 1;

                    lexer->waswhite = yes;
                }
                else
                    lexer->waswhite = no;

                if (inDTDSubset) {
                    if (c == ']')
                        inDTDSubset = no;
                }
                else if (c == '[')
                    inDTDSubset = yes;

                if (inDTDSubset || c != '>')
                    continue;

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                lexer->token = DocTypeToken(lexer);
                /* make a note of the version named by the 1st doctype */
                if ( lexer->doctype == VERS_UNKNOWN )
                    lexer->doctype = FindGivenVersion( doc, lexer->token );
                return lexer->token;

            case LEX_PROCINSTR:  /* seen <? so look for '>' */
                /* check for PHP preprocessor instructions <?php ... ?> */

                if  (lexer->lexsize - lexer->txtstart == 3)
                {
                    if (tmbstrncmp(lexer->lexbuf + lexer->txtstart, "php", 3) == 0)
                    {
                        lexer->state = LEX_PHP;
                        continue;
                    }
                }

                if  (lexer->lexsize - lexer->txtstart == 4)
                {
                    if (tmbstrncmp(lexer->lexbuf + lexer->txtstart, "xml", 3) == 0 &&
                        IsWhite(lexer->lexbuf[lexer->txtstart + 3]))
                    {
                        lexer->state = LEX_XMLDECL;
                        attributes = null;
                        continue;
                    }
                }

                if ( cfgBool(doc, TidyXmlPIs) )  /* insist on ?> as terminator */
                {
                    if (c != '?')
                        continue;

                    /* now look for '>' */
                    c = ReadChar(doc->docIn);

                    if (c == EndOfStream)
                    {
                        ReportWarning( doc, null, null, UNEXPECTED_END_OF_FILE );
                        UngetChar(c, doc->docIn);
                        continue;
                    }

                    AddCharToLexer(lexer, c);
                }


                if (c != '>')
                    continue;

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token = PIToken(lexer);

            case LEX_ASP:  /* seen <% so look for "%>" */
                if (c != '%')
                    continue;

                /* now look for '>' */
                c = ReadChar(doc->docIn);


                if (c != '>')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token = AspToken(lexer);

            case LEX_JSTE:  /* seen <# so look for "#>" */
                if (c != '#')
                    continue;

                /* now look for '>' */
                c = ReadChar(doc->docIn);


                if (c != '>')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token = JsteToken(lexer);

            case LEX_PHP: /* seen "<?php" so look for "?>" */
                if (c != '?')
                    continue;

                /* now look for '>' */
                c = ReadChar(doc->docIn);

                if (c != '>')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token = PhpToken(lexer);

            case LEX_XMLDECL: /* seen "<?xml" so look for "?>" */

                if (IsWhite(c) && c != '?')
                    continue;

                /* get pseudo-attribute */
                if (c != '?')
                {
                    tmbstr name;
                    Node *asp, *php;
                    AttVal *av = null;
                    int pdelim = 0;
                    isempty = no;

                    UngetChar(c, doc->docIn);

                    name = ParseAttribute( doc, &isempty, &asp, &php );

                    av = NewAttribute();
                    av->attribute = name;
                    av->value = ParseValue( doc, name, yes, &isempty, &pdelim );
                    av->delim = pdelim;
                    av->dict = FindAttribute( doc, av );

                    AddAttrToList( &attributes, av );
                    /* continue; */
                }

                /* now look for '>' */
                c = ReadChar(doc->docIn);

                if (c != '>')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }
                lexer->lexsize -= 1;
                lexer->txtend = lexer->txtstart;
                lexer->lexbuf[lexer->txtend] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                lexer->token = XmlDeclToken(lexer);
                lexer->token->attributes = attributes;
                return lexer->token;

            case LEX_SECTION: /* seen "<![" so look for "]>" */
                if (c == '[')
                {
                    if (lexer->lexsize == (lexer->txtstart + 6) &&
                        tmbstrncmp(lexer->lexbuf+lexer->txtstart, "CDATA[", 6) == 0)
                    {
                        lexer->state = LEX_CDATA;
                        lexer->lexsize -= 6;
                        continue;
                    }
                }

                if (c != ']')
                    continue;

                /* now look for '>' */
                c = ReadChar(doc->docIn);

                if (c != '>')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token = SectionToken(lexer);

            case LEX_CDATA: /* seen "<![CDATA[" so look for "]]>" */
                if (c != ']')
                    continue;

                /* now look for ']' */
                c = ReadChar(doc->docIn);

                if (c != ']')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                /* now look for '>' */
                c = ReadChar(doc->docIn);

                if (c != '>')
                {
                    UngetChar(c, doc->docIn);
                    continue;
                }

                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
                lexer->lexbuf[lexer->lexsize] = '\0';
                lexer->state = LEX_CONTENT;
                lexer->waswhite = no;
                return lexer->token = CDATAToken(lexer);
        }
    }

    if (lexer->state == LEX_CONTENT)  /* text string */
    {
        lexer->txtend = lexer->lexsize;

        if (lexer->txtend > lexer->txtstart)
        {
            UngetChar(c, doc->docIn);

            if (lexer->lexbuf[lexer->lexsize - 1] == ' ')
            {
                lexer->lexsize -= 1;
                lexer->txtend = lexer->lexsize;
            }

            return lexer->token = TextToken(lexer);
        }
    }
    else if (lexer->state == LEX_COMMENT) /* comment */
    {
        if (c == EndOfStream)
            ReportWarning( doc, null, null, MALFORMED_COMMENT );

        lexer->txtend = lexer->lexsize;
        lexer->lexbuf[lexer->lexsize] = '\0';
        lexer->state = LEX_CONTENT;
        lexer->waswhite = no;
        return lexer->token = CommentToken(lexer);
    }

    return 0;
}

static void MapStr( ctmbstr str, uint code )
{
    while ( *str )
    {
        uint i = (byte) *str++;
        lexmap[i] |= code;
    }
}

void InitMap(void)
{
    MapStr("\r\n\f", newline|white);
    MapStr(" \t", white);
    MapStr("-.:_", namechar);
    MapStr("0123456789", digit|namechar);
    MapStr("abcdefghijklmnopqrstuvwxyz", lowercase|letter|namechar);
    MapStr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", uppercase|letter|namechar);
}

/*
 parser for ASP within start tags

 Some people use ASP for to customize attributes
 Tidy isn't really well suited to dealing with ASP
 This is a workaround for attributes, but won't
 deal with the case where the ASP is used to tailor
 the attribute value. Here is an example of a work
 around for using ASP in attribute values:

  href='<%=rsSchool.Fields("ID").Value%>'

 where the ASP that generates the attribute value
 is masked from Tidy by the quotemarks.

*/

static Node *ParseAsp( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    uint c;
    Node *asp = null;

    lexer->txtstart = lexer->lexsize;

    for (;;)
    {
        if ((c = ReadChar(doc->docIn)) == EndOfStream)
            break;

        AddCharToLexer(lexer, c);


        if (c != '%')
            continue;

        if ((c = ReadChar(doc->docIn)) == EndOfStream)
            break;

        AddCharToLexer(lexer, c);

        if (c == '>')
            break;
    }

    lexer->lexsize -= 2;
    lexer->txtend = lexer->lexsize;

    if (lexer->txtend > lexer->txtstart)
        asp = AspToken(lexer);

    lexer->txtstart = lexer->txtend;
    return asp;
}   
 

/*
 PHP is like ASP but is based upon XML
 processing instructions, e.g. <?php ... ?>
*/
static Node *ParsePhp( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    uint c;
    Node *php = null;

    lexer->txtstart = lexer->lexsize;

    for (;;)
    {
        if ((c = ReadChar(doc->docIn)) == EndOfStream)
            break;

        AddCharToLexer(lexer, c);


        if (c != '?')
            continue;

        if ((c = ReadChar(doc->docIn)) == EndOfStream)
            break;

        AddCharToLexer(lexer, c);

        if (c == '>')
            break;
    }

    lexer->lexsize -= 2;
    lexer->txtend = lexer->lexsize;

    if (lexer->txtend > lexer->txtstart)
        php = PhpToken(lexer);

    lexer->txtstart = lexer->txtend;
    return php;
}   

/* consumes the '>' terminating start tags */
static tmbstr  ParseAttribute( TidyDocImpl* doc, Bool *isempty,
                              Node **asp, Node **php)
{
    Lexer* lexer = doc->lexer;
    int start, len = 0;
    tmbstr attr = null;
    uint c, lastc;

    *asp = null;  /* clear asp pointer */
    *php = null;  /* clear php pointer */

 /* skip white space before the attribute */

    for (;;)
    {
        c = ReadChar( doc->docIn );


        if (c == '/')
        {
            c = ReadChar( doc->docIn );

            if (c == '>')
            {
                *isempty = yes;
                return null;
            }

            UngetChar(c, doc->docIn);
            c = '/';
            break;
        }

        if (c == '>')
            return null;

        if (c =='<')
        {
            c = ReadChar(doc->docIn);

            if (c == '%')
            {
                *asp = ParseAsp( doc );
                return null;
            }
            else if (c == '?')
            {
                *php = ParsePhp( doc );
                return null;
            }

            UngetChar(c, doc->docIn);
            UngetChar('<', doc->docIn);
            ReportAttrError( doc, lexer->token, null, UNEXPECTED_GT );
            return null;
        }

        if (c == '=')
        {
            ReportAttrError( doc, lexer->token, null, UNEXPECTED_EQUALSIGN );
            continue;
        }

        if (c == '"' || c == '\'')
        {
            ReportAttrError( doc, lexer->token, null, UNEXPECTED_QUOTEMARK );
            continue;
        }

        if (c == EndOfStream)
        {
            ReportAttrError( doc, lexer->token, null, UNEXPECTED_END_OF_FILE );
            UngetChar(c, doc->docIn);
            return null;
        }


        if (!IsWhite(c))
           break;
    }

    start = lexer->lexsize;
    lastc = c;

    for (;;)
    {
     /* but push back '=' for parseValue() */
        if (c == '=' || c == '>')
        {
            UngetChar(c, doc->docIn);
            break;
        }

        if (c == '<' || c == EndOfStream)
        {
            UngetChar(c, doc->docIn);
            break;
        }

        if (lastc == '-' && (c == '"' || c == '\''))
        {
            lexer->lexsize--;
            --len;
            UngetChar(c, doc->docIn);
            break;
        }

        if (IsWhite(c))
            break;

        /* what should be done about non-namechar characters? */
        /* currently these are incorporated into the attr name */

        if ( !cfgBool(doc, TidyXmlTags) && IsUpper(c) )
            c = ToLower(c);

        AddCharToLexer( lexer, c );
        lastc = c;
        c = ReadChar(doc->docIn);
    }

    /* handle attribute names with multibyte chars */
    len = lexer->lexsize - start;
    attr = (len > 0 ? tmbstrndup(lexer->lexbuf+start, len) : null);
    lexer->lexsize = start;
    return attr;
}

/*
 invoked when < is seen in place of attribute value
 but terminates on whitespace if not ASP, PHP or Tango
 this routine recognizes ' and " quoted strings
*/
static int ParseServerInstruction( TidyDocImpl* doc )
{
    Lexer* lexer = doc->lexer;
    int c, delim = '"';
    Bool isrule = no;

    c = ReadChar(doc->docIn);
    AddCharToLexer(lexer, c);

    /* check for ASP, PHP or Tango */
    if (c == '%' || c == '?' || c == '@')
        isrule = yes;

    for (;;)
    {
        c = ReadChar(doc->docIn);

        if (c == EndOfStream)
            break;

        if (c == '>')
        {
            if (isrule)
                AddCharToLexer(lexer, c);
            else
                UngetChar(c, doc->docIn);

            break;
        }

        /* if not recognized as ASP, PHP or Tango */
        /* then also finish value on whitespace */
        if (!isrule)
        {
            if (IsWhite(c))
                break;
        }

        AddCharToLexer(lexer, c);

        if (c == '"')
        {
            do
            {
                c = ReadChar(doc->docIn);
                if (c == EndOfStream) /* #427840 - fix by Terry Teague 30 Jun 01 */
                {
                    ReportAttrError( doc, lexer->token, null, UNEXPECTED_END_OF_FILE );
                    UngetChar(c, doc->docIn);
                    return null;
                }
                if (c == '>') /* #427840 - fix by Terry Teague 30 Jun 01 */
                {
                    UngetChar(c, doc->docIn);
                    ReportAttrError( doc, lexer->token, null, UNEXPECTED_GT );
                    return null;
                }
                AddCharToLexer(lexer, c);
            }
            while (c != '"');
            delim = '\'';
            continue;
        }

        if (c == '\'')
        {
            do
            {
                c = ReadChar(doc->docIn);
                if (c == EndOfStream) /* #427840 - fix by Terry Teague 30 Jun 01 */
                {
                    ReportAttrError( doc, lexer->token, null, UNEXPECTED_END_OF_FILE );
                    UngetChar(c, doc->docIn);
                    return null;
                }
                if (c == '>') /* #427840 - fix by Terry Teague 30 Jun 01 */
                {
                    UngetChar(c, doc->docIn);
                    ReportAttrError( doc, lexer->token, null, UNEXPECTED_GT );
                    return null;
                }
                AddCharToLexer(lexer, c);
            }
            while (c != '\'');
        }
    }

    return delim;
}

/* values start with "=" or " = " etc. */
/* doesn't consume the ">" at end of start tag */

static tmbstr ParseValue( TidyDocImpl* doc, ctmbstr name,
                    Bool foldCase, Bool *isempty, int *pdelim)
{
    Lexer* lexer = doc->lexer;
    int len = 0, start;
    Bool seen_gt = no;
    Bool munge = yes;
    uint c, lastc, delim, quotewarning;
    tmbstr value;

    delim = (tmbchar) 0;
    *pdelim = '"';

    /*
     Henry Zrepa reports that some folk are using the
     embed element with script attributes where newlines
     are significant and must be preserved
    */
    if ( cfgBool(doc, TidyLiteralAttribs) )
        munge = no;

 /* skip white space before the '=' */

    for (;;)
    {
        c = ReadChar(doc->docIn);

        if (c == EndOfStream)
        {
            UngetChar(c, doc->docIn);
            break;
        }

        if (!IsWhite(c))
           break;
    }

/*
  c should be '=' if there is a value
  other legal possibilities are white
  space, '/' and '>'
*/

    if (c != '=' && c != '"' && c != '\'')
    {
        UngetChar(c, doc->docIn);
        return null;
    }

 /* skip white space after '=' */

    for (;;)
    {
        c = ReadChar(doc->docIn);

        if (c == EndOfStream)
        {
            UngetChar(c, doc->docIn);
            break;
        }

        if (!IsWhite(c))
           break;
    }

 /* check for quote marks */

    if (c == '"' || c == '\'')
        delim = c;
    else if (c == '<')
    {
        start = lexer->lexsize;
        AddCharToLexer(lexer, c);
        *pdelim = ParseServerInstruction( doc );
        len = lexer->lexsize - start;
        lexer->lexsize = start;
        return (len > 0 ? tmbstrndup(lexer->lexbuf+start, len) : null);
    }
    else
        UngetChar(c, doc->docIn);

 /*
   and read the value string
   check for quote mark if needed
 */

    quotewarning = 0;
    start = lexer->lexsize;
    c = '\0';

    for (;;)
    {
        lastc = c;  /* track last character */
        c = ReadChar(doc->docIn);

        if (c == EndOfStream)
        {
            ReportAttrError( doc, lexer->token, null, UNEXPECTED_END_OF_FILE );
            UngetChar(c, doc->docIn);
            break;
        }

        if (delim == (tmbchar)0)
        {
            if (c == '>')
            {
                UngetChar(c, doc->docIn);
                break;
            }

            if (c == '"' || c == '\'')
            {
                ReportAttrError( doc, lexer->token, null, UNEXPECTED_QUOTEMARK );
                break;
            }

            if (c == '<')
            {
                UngetChar(c, doc->docIn);
                c = '>';
                UngetChar(c, doc->docIn);
                ReportAttrError( doc, lexer->token, null, UNEXPECTED_GT );
                break;
            }

            /*
             For cases like <br clear=all/> need to avoid treating /> as
             part of the attribute value, however care is needed to avoid
             so treating <a href=http://www.acme.com/> in this way, which
             would map the <a> tag to <a href="http://www.acme.com"/>
            */
            if (c == '/')
            {
                /* peek ahead in case of /> */
                c = ReadChar(doc->docIn);

                if ( c == '>' && !IsUrl(doc, name) )
                {
                    *isempty = yes;
                    UngetChar(c, doc->docIn);
                    break;
                }

                /* unget peeked character */
                UngetChar(c, doc->docIn);
                c = '/';
            }
        }
        else  /* delim is '\'' or '"' */
        {
            if (c == delim)
                break;

            /* treat CRLF, CR and LF as single line break */

            if (c == '\r')
            {
                if ((c = ReadChar(doc->docIn)) != '\n')
                    UngetChar(c, doc->docIn);

                c = '\n';
            }

            if (c == '\n' || c == '<' || c == '>')
                ++quotewarning;

            if (c == '>')
                seen_gt = yes;
        }

        if (c == '&')
        {
            /* no entities in ID attributes */
            if (tmbstrcasecmp(name, "id") == 0)
            {
                ReportAttrError( doc, null, null, ENTITY_IN_ID );
                continue;
            }
            else
            {
                AddCharToLexer(lexer, c);
                ParseEntity( doc, null );
                continue;
            }
        }

        /*
         kludge for JavaScript attribute values
         with line continuations in string literals
        */
        if (c == '\\')
        {
            c = ReadChar(doc->docIn);

            if (c != '\n')
            {
                UngetChar(c, doc->docIn);
                c = '\\';
            }
        }

        if (IsWhite(c))
        {
            if ( delim == 0 )
                break;

            if (munge)
            {
                /* discard line breaks in quoted URLs */ 
                /* #438650 - fix by Randy Waki */
                if ( c == '\n' && IsUrl(doc, name) )
                {
                    /* warn that we discard this newline */
                    ReportAttrError( doc, lexer->token, null, NEWLINE_IN_URI);
                    continue;
                }
                
                c = ' ';

                if (lastc == ' ')
                    continue;
            }
        }
        else if (foldCase && IsUpper(c))
            c = ToLower(c);

        AddCharToLexer(lexer, c);
    }

    if (quotewarning > 10 && seen_gt && munge)
    {
        /*
           there is almost certainly a missing trailing quote mark
           as we have see too many newlines, < or > characters.

           an exception is made for Javascript attributes and the
           javascript URL scheme which may legitimately include < and >,
           and for attributes starting with "<xml " as generated by
           Microsoft Office.
        */
        if ( !IsScript(doc, name) &&
             !(IsUrl(doc, name) && tmbstrncmp(lexer->lexbuf+start, "javascript:", 11) == 0) &&
             !(tmbstrncmp(lexer->lexbuf+start, "<xml ", 5) == 0)
           )
            ReportError( doc, null, null, SUSPECTED_MISSING_QUOTE ); 
    }

    len = lexer->lexsize - start;
    lexer->lexsize = start;


    if (len > 0 || delim)
    {
        /* ignore leading and trailing white space for all but title and */
        /* alt attributes unless --literal-attributes is set to yes      */

        if (munge && tmbstrcasecmp(name, "alt") && tmbstrcasecmp(name, "title"))
        {
            while (IsWhite(lexer->lexbuf[start+len-1]))
                --len;

            while (IsWhite(lexer->lexbuf[start]) && start < len)
            {
                ++start;
                --len;
            }
        }

        value = tmbstrndup(lexer->lexbuf + start, len);
    }
    else
        value = null;

    /* note delimiter if given */
    *pdelim = (delim ? delim : '"');

    return value;
}

/* attr must be non-null */
Bool IsValidAttrName( ctmbstr attr )
{
    uint i, c = attr[0];

    /* first character should be a letter */
    if (!IsLetter(c))
        return no;

    /* remaining characters should be namechars */
    for( i = 1; i < tmbstrlen(attr); i++)
    {
        c = attr[i];

        if (IsNamechar(c))
            continue;

        return no;
    }

    return yes;
}


/* create a new attribute */
AttVal *NewAttribute()
{
    AttVal *av = (AttVal*) MemAlloc( sizeof(AttVal) );
    ClearMemory( av, sizeof(AttVal) );
    return av;
}

/* create a new attribute with given name and value */
AttVal* NewAttributeEx( ctmbstr name, ctmbstr value )
{
    AttVal *av = NewAttribute();
    av->attribute = tmbstrdup(name);
    av->value = tmbstrdup(value);
    return av;
}


/* swallows closing '>' */

static void AddAttrToList( AttVal** list, AttVal* av )
{
  if ( *list == null )
    *list = av;
  else
  {
    AttVal* here = *list;
    while ( here->next )
      here = here->next;
    here->next = av;
  }
}

AttVal* ParseAttrs( TidyDocImpl* doc, Bool *isempty )
{
    Lexer* lexer = doc->lexer;
    AttVal *av, *list;
    tmbstr value;
    int delim;
    Node *asp, *php;

    list = null;

    while ( !EndOfInput(doc) )
    {
        tmbstr attribute = ParseAttribute( doc, isempty, &asp, &php );

        if (attribute == null)
        {
            /* check if attributes are created by ASP markup */
            if (asp)
            {
                av = NewAttribute();
                av->asp = asp;
                AddAttrToList( &list, av ); 
                continue;
            }

            /* check if attributes are created by PHP markup */
            if (php)
            {
                av = NewAttribute();
                av->php = php;
                AddAttrToList( &list, av ); 
                continue;
            }

            break;
        }

        value = ParseValue( doc, attribute, no, isempty, &delim );

        if ( attribute && IsValidAttrName(attribute) )
        {
            av = NewAttribute();
            av->delim = delim;
            av->attribute = attribute;
            av->value = value;
            av->dict = FindAttribute( doc, av );
            AddAttrToList( &list, av ); 
        }
        else
        {
            av = NewAttribute();
            av->attribute = attribute;
            av->value = value;
            /* #427664 - fix by Gary Peskin 04 Aug 00; other fixes by Dave Raggett */
            /*
            if (value == null)
                ReportAttrError(lexer, lexer->token, av, MISSING_ATTR_VALUE);
            else
                ReportAttrError(lexer, lexer->token, av, BAD_ATTRIBUTE_VALUE);
            if (value != null)
                ReportAttrError( doc, lexer->token, av, BAD_ATTRIBUTE_VALUE);
            else if (LastChar(attribute) == '"')
                ReportAttrError( doc, lexer->token, av, MISSING_QUOTEMARK);
            else
                ReportAttrError( doc, lexer->token, av, UNKNOWN_ATTRIBUTE);
            */
            if (LastChar(attribute) == '"')
                ReportAttrError( doc, lexer->token, av, MISSING_QUOTEMARK);
            else if (value == null)
                ReportAttrError(doc, lexer->token, av, MISSING_ATTR_VALUE);
            else
                ReportAttrError(doc, lexer->token, av, INVALID_ATTRIBUTE);

            FreeAttribute(av);
        }
    }

    return list;
}
