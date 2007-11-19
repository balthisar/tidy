/* localize.c -- text strings and routines to handle errors and general messages

  (c) 1998-2003 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  You should only need to edit this file and tidy.c
  to localize HTML tidy. *** This needs checking ***
  
  CVS Info :

    $Author: terry_teague $ 
    $Date: 2003/03/02 04:30:09 $ 
    $Revision: 1.68 $ 

*/

#include "tidy-int.h"
#include "lexer.h"
#include "streamio.h"
#include "message.h"
#include "tmbstr.h"
#include "utf8.h"

/* used to point to Web Accessibility Guidelines */
#define ACCESS_URL  "http://www.w3.org/WAI/GL"

/* points to the Adaptive Technology Resource Centre at the
** University of Toronto
*/
#define ATRC_ACCESS_URL  "http://www.aprompt.ca/Tidy/accessibilitychecks.html"

const static char *release_date = "1st March 2003";

ctmbstr ReleaseDate()
{
  return release_date;
}


static char* LevelPrefix( TidyReportLevel level, char* buf )
{
  *buf = 0;
  switch ( level )
  {
  case TidyInfo:
    tmbstrcpy( buf, "Info: " );
    break;
  case TidyWarning:
    tmbstrcpy( buf, "Warning: " );
    break;
  case TidyConfig:
    tmbstrcpy( buf, "Config: " );
    break;
  case TidyAccess:
    tmbstrcpy( buf, "Access: " );
    break;
  case TidyError:
    tmbstrcpy( buf, "Error: " );
    break;
  case TidyBadDocument:
    tmbstrcpy( buf, "Document: " );
    break;
  case TidyFatal:
    tmbstrcpy( buf, "panic: " );
    break;
  }
  return buf + tmbstrlen( buf );
}

/* Updates document message counts and
** compares counts to options to see if message
** display should go forward.
*/
static Bool UpdateCount( TidyDocImpl* doc, TidyReportLevel level )
{
  /* keep quiet after <ShowErrors> errors */
  Bool go = ( doc->errors < cfg(doc, TidyShowErrors) );

  switch ( level )
  {
  case TidyInfo:
    doc->infoMessages++;
    break;
  case TidyWarning:
    doc->warnings++;
    go = go && cfgBool( doc, TidyShowWarnings );
    break;
  case TidyConfig:
    doc->optionErrors++;
    break;
  case TidyAccess:
    doc->accessErrors++;
    break;
  case TidyError:
    doc->errors++;
    break;
  case TidyBadDocument:
    doc->docErrors++;
    break;
  case TidyFatal:
    /* Ack! */;
    break;
  }

  return go;
}

static char* ReportPosition( TidyDocImpl* doc, int line, int col, char* buf )
{
    *buf = 0;

    /* Change formatting to be parsable by GNU Emacs */
    if ( cfgBool(doc, TidyEmacs) && cfgStr(doc, TidyEmacsFile) )
        sprintf( buf, "%s:%d:%d: ", 
                 cfgStr(doc, TidyEmacsFile), line, col );
    else /* traditional format */
        sprintf( buf, "line %d column %d - ", line, col );
    return buf + tmbstrlen( buf );
}

/* General message writing routine.
** Each message is a single warning, error, etc.
** 
** This routine will keep track of counts and,
** if the caller has set a filter, it will be 
** called.  The new preferred way of handling
** Tidy diagnostics output is either a) define
** a new output sink or b) install a message
** filter routine.
*/

static void messagePos( TidyDocImpl* doc, TidyReportLevel level,
                        int line, int col, ctmbstr msg, va_list args )
{
    char message[ 2048 ];
    Bool go = UpdateCount( doc, level );

    if ( go )
    {
        vsprintf( message, msg, args );
        if ( doc->mssgFilt )
        {
            TidyDoc tdoc = tidyImplToDoc( doc );
            go = doc->mssgFilt( tdoc, level, line, col, message );
        }
    }

    if ( go )
    {
        char buf[ 64 ], *cp;
        if ( line > 0 && col > 0 )
        {
            ReportPosition( doc, line, col, buf );
            for ( cp = buf; *cp; ++cp )
                WriteChar( *cp, doc->errout );
        }

        LevelPrefix( level, buf );
        for ( cp = buf; *cp; ++cp )
            WriteChar( *cp, doc->errout );

        for ( cp = message; *cp; ++cp )
            WriteChar( *cp, doc->errout );
        WriteChar( '\n', doc->errout );
    }
}

void message( TidyDocImpl* doc, TidyReportLevel level, ctmbstr msg, ... )
{
    va_list args;
    va_start( args, msg );
    messagePos( doc, level, 0, 0, msg, args );
    va_end( args );
}


void messageLexer( TidyDocImpl* doc, TidyReportLevel level, ctmbstr msg, ... )
{
    int line = ( doc->lexer ? doc->lexer->lines : 0 );
    int col  = ( doc->lexer ? doc->lexer->columns : 0 );

    va_list args;
    va_start( args, msg );
    messagePos( doc, level, line, col, msg, args );
    va_end( args );
}

void messageNode( TidyDocImpl* doc, TidyReportLevel level, Node* node,
                  ctmbstr msg, ... )
{
    int line = ( node ? node->line :
                 ( doc->lexer ? doc->lexer->lines : 0 ) );
    int col  = ( node ? node->column :
                 ( doc->lexer ? doc->lexer->columns : 0 ) );

    va_list args;
    va_start( args, msg );
    messagePos( doc, level, line, col, msg, args );
    va_end( args );
}

void tidy_out( TidyDocImpl* doc, ctmbstr msg, ... )
{
    if ( !cfgBool(doc, TidyQuiet) )
    {
        ctmbstr cp;
        char buf[ 2048 ];

        va_list args;
        va_start( args, msg );
        vsprintf( buf, msg, args );
        va_end( args );

        for ( cp=buf; *cp; ++cp )
          WriteChar( *cp, doc->errout );
    }
}

void ShowVersion( TidyDocImpl* doc )
{
    ctmbstr platform = "", helper = "";

#ifdef PLATFORM_NAME
    platform = PLATFORM_NAME;
    helper = " for ";
#endif

    tidy_out( doc, "\nHTML Tidy%s%s (release date: %s; built on %s, at %s)\n"
                   "See http://tidy.sourceforge.net/ for details.\n",
              helper, platform, release_date, __DATE__, __TIME__ );
}

void FileError( TidyDocImpl* doc, ctmbstr file )
{
    message( doc, TidyError, "Can't open \"%s\"\n", file );
}

static char* TagToString( Node* tag, char* buf )
{
    *buf = 0;
    if ( tag )
    {
      if ( tag->type == StartTag || tag->type == StartEndTag )
          sprintf( buf, "<%s>", tag->element );
      else if ( tag->type == EndTag )
          sprintf( buf, "</%s>", tag->element );
      else if ( tag->type == DocTypeTag )
          strcpy( buf, "<!DOCTYPE>" );
      else if ( tag->type == TextNode )
          strcpy( buf, "plain text" );
      else if ( tag->element )
        strcpy( buf, tag->element );
    }
    return buf + tmbstrlen( buf );
}

/* lexer is not defined when this is called */
void ReportUnknownOption( TidyDocImpl* doc, ctmbstr option )
{
    assert( option != null );
    message( doc, TidyConfig, "unknown option: %s", option );
}

/* lexer is not defined when this is called */
void ReportBadArgument( TidyDocImpl* doc, ctmbstr option )
{
    assert( option != null );
    message( doc, TidyConfig,
             "missing or malformed argument for option: %s", option );
}

static void NtoS(int n, tmbstr str)
{
    tmbchar buf[40];
    int i;

    for (i = 0;; ++i)
    {
        buf[i] = (tmbchar)( (n % 10) + '0' );

        n = n / 10;

        if (n == 0)
            break;
    }

    n = i;

    while (i >= 0)
    {
        str[n-i] = buf[i];
        --i;
    }

    str[n+1] = '\0';
}


void ReportEncodingError( TidyDocImpl* doc, uint code, uint c )
{
    Lexer* lexer = doc->lexer;
    char buf[ 32 ];

    uint reason = code & ~DISCARDED_CHAR;
    ctmbstr action = code & DISCARDED_CHAR ? "discarding" : "replacing";
    ctmbstr fmt = null;

    doc->warnings++;

    /* An encoding mismatch is currently treated as a non-fatal error */
    switch ( reason )
    {
    case ENCODING_MISMATCH:
        /* actual encoding passed in "c" */
        messageLexer( doc, TidyWarning,
                      "specified input encoding (%s) does "
                      "not match actual input encoding (%s)",
                       CharEncodingName( doc->docIn->encoding ),
                       CharEncodingName(c) );
        break;

    case VENDOR_SPECIFIC_CHARS:
        NtoS(c, buf);
        fmt = "Warning: %s invalid character code %s";
        break;

    case INVALID_SGML_CHARS:
        NtoS(c, buf);
        fmt = "Warning: %s invalid character code %s";
        break;

    case INVALID_UTF8:
        sprintf( buf, "U+%04X", c );
        fmt = "Warning: %s invalid UTF-8 bytes (char. code %s)";
        break;

#if SUPPORT_UTF16_ENCODINGS
    case INVALID_UTF16:
        sprintf( buf, "U+%04X", c );
        fmt = "Warning: %s invalid UTF-16 surrogate pair (char. code %s)";
        break;
#endif

#if SUPPORT_ASIAN_ENCODINGS
    case INVALID_NCR:
        NtoS(c, buf);
        fmt = "Warning: %s invalid numeric character reference %s";
        break;
#endif
    default:
        reason = 0;
        break;
    }

    if ( fmt )
        messageLexer( doc, TidyWarning, fmt, action, buf );
    if ( reason )
      doc->badChars |= reason;
}

void ReportEntityError( TidyDocImpl* doc, uint code, ctmbstr entity, int c )
{
    ctmbstr entityname = ( entity ? entity : "NULL" );
    ctmbstr fmt = null;

    switch ( code )
    {
    case MISSING_SEMICOLON:
        fmt = "entity \"%s\" doesn't end in ';'";
        break;
    case MISSING_SEMICOLON_NCR:
        fmt = "numeric character reference \"%s\" doesn't end in ';'";
        break;
    case UNKNOWN_ENTITY:
        fmt = "unescaped & or unknown entity \"%s\"";
        break;
    case UNESCAPED_AMPERSAND:
        fmt = "unescaped & which should be written as &amp;";
        break;
    case APOS_UNDEFINED:
        fmt = "named entity &apos; only defined in XML/XHTML";
        break;
    }

    if ( fmt )
        messageLexer( doc, TidyWarning, fmt, entityname );
}

void ReportAttrError( TidyDocImpl* doc, Node *node, AttVal *av, uint code)
{
    char *name = "NULL", *value = "NULL", tagdesc[ 64 ];

    TagToString( node, tagdesc );
    if ( av )
    {
        if ( av->attribute )
            name = av->attribute;
        if ( av->value )
            value = av->value;
    }

    switch ( code )
    {
    case UNKNOWN_ATTRIBUTE:
        messageNode( doc, TidyWarning, node,
                     "unknown attribute \"%s\"", name );
        break;

    case INSERTING_ATTRIBUTE:
        messageNode( doc, TidyWarning, node,
                     "inserting \"%s\" attribute for %s element", name, tagdesc );
        break;

    case MISSING_ATTR_VALUE:
        messageNode( doc, TidyWarning, node,
                     "%s attribute \"%s\" lacks value", tagdesc, name );
        break;

    case MISSING_IMAGEMAP:  /* this is not used anywhere */
        messageNode( doc, TidyWarning, node,
                     "%s should use client-side image map", tagdesc );
        doc->badAccess |= MISSING_IMAGE_MAP;
        break;

    case BAD_ATTRIBUTE_VALUE:
        messageNode( doc, TidyWarning, node,
                     "%s attribute \"%s\" has invalid value \"%s\"",
                     tagdesc, name, value );
        break;

    case INVALID_ATTRIBUTE:
        messageNode( doc, TidyWarning, node,
                     "%s attribute name \"%s\" (value=\"%s\") is invalid",
                     tagdesc, name, value );
        break;
    case XML_ID_SYNTAX:
        messageNode( doc, TidyWarning, node,
                     "%s ID \"%s\" uses XML ID syntax", tagdesc, value );
        break;

    case XML_ATTRIBUTE_VALUE:
        messageNode( doc, TidyWarning, node,
                     "%s has XML attribute \"%s\"", tagdesc, name );
        break;

    case UNEXPECTED_QUOTEMARK:
        messageNode( doc, TidyWarning, node,
                     "%s unexpected or duplicate quote mark", tagdesc );
        break;

    case MISSING_QUOTEMARK:
        messageNode( doc, TidyWarning, node,
                     "%s attribute with missing trailing quote mark",
                     tagdesc );
        break;

    case REPEATED_ATTRIBUTE:
        messageNode( doc, TidyWarning, node,
                     "%s dropping value \"%s\" for repeated attribute \"%s\"",
                     tagdesc, value, name );
        break;

    case PROPRIETARY_ATTR_VALUE:
        messageNode( doc, TidyWarning, node,
                     "%s proprietary attribute value \"%s\"", tagdesc, value );
        break;

    case PROPRIETARY_ATTRIBUTE:
        messageNode( doc, TidyWarning, node,
                     "%s proprietary attribute \"%s\"", tagdesc, name );
        break;

    case UNEXPECTED_END_OF_FILE:
        /* on end of file adjust reported position to end of input */
        doc->lexer->lines   = doc->docIn->curline;
        doc->lexer->columns = doc->docIn->curcol;
        messageLexer( doc, TidyWarning,
                      "end of file while parsing attributes" );
        break;

    case ID_NAME_MISMATCH:
        messageNode( doc, TidyWarning, node,
                     "%s id and name attribute value mismatch", tagdesc );
        break;

    case BACKSLASH_IN_URI:
        messageNode( doc, TidyWarning, node,
                     "%s URI reference contains backslash. Typo?", tagdesc );
        break;

    case FIXED_BACKSLASH:
        messageNode( doc, TidyWarning, node,
                     "%s converting backslash in URI to slash", tagdesc );
        break;

    case ILLEGAL_URI_REFERENCE:
        messageNode( doc, TidyWarning, node,
                     "%s improperly escaped URI reference", tagdesc );
        break;

    case ESCAPED_ILLEGAL_URI:
        messageNode( doc, TidyWarning, node,
                     "%s escaping malformed URI reference", tagdesc );
        break;

    case NEWLINE_IN_URI:
        messageNode( doc, TidyWarning, node,
                     "%s discarding newline in URI reference", tagdesc );
        break;

    case ANCHOR_NOT_UNIQUE:
        messageNode( doc, TidyWarning, node,
                     "%s Anchor \"%s\" already defined", tagdesc, value);
        break;

    case ENTITY_IN_ID:
        messageNode( doc, TidyWarning, node,
                     "No entities allowed in id attribute, discarding \"&\"" );
        break;

    case JOINING_ATTRIBUTE:
        messageNode( doc, TidyWarning, node,
                     "%s joining values of repeated attribute \"%s\"",
                 tagdesc, name );
        break;

    case UNEXPECTED_EQUALSIGN:
        messageNode( doc, TidyWarning, node,
                     "%s unexpected '=', expected attribute name", tagdesc );
        break;

    case ATTR_VALUE_NOT_LCASE:
        messageNode( doc, TidyWarning, node,
                     "%s attribute value \"%s\" must be lower case for XHTML",
                     tagdesc, value );
        break;

    case UNEXPECTED_GT:
        messageNode( doc, TidyWarning, node,
                     "%s missing '>' for end of tag", tagdesc );
        break;
    }
}


void ReportNonCompliantAttr( TidyDocImpl* doc, Node* node, AttVal* attr, uint versWanted )
{
    ctmbstr attrnam = ( attr && attr->attribute ? attr->attribute : "Unknown" );
    ctmbstr htmlVer = HTMLVersionNameFromCode( versWanted, doc->lexer->isvoyager );
    messageNode( doc, TidyWarning, node,
                 "Attribute \"%s\" not supported in %s", attrnam, htmlVer );
}

void ReportNonCompliantNode( TidyDocImpl* doc, Node* node, uint code, uint versWanted )
{
    char desc[ 256 ] = {0};
    ctmbstr htmlVer = HTMLVersionNameFromCode( versWanted, doc->lexer->isvoyager );
    TagToString( node, desc );

    switch ( code )
    {
    case MIXED_CONTENT_IN_BLOCK:
        messageNode( doc, TidyWarning, node,
                     "Text node in %s in %s", desc, htmlVer );
        break;

    case OBSOLETE_ELEMENT:
        messageNode( doc, TidyWarning, node,
                     "Element %s not supported in %s", desc, htmlVer );
        break;
    }
}

void ReportMissingAttr( TidyDocImpl* doc, Node* node, ctmbstr name )
{
    /* ReportAttrError( doc, node, null, MISSING_ATTRIBUTE ); */
    char tagdesc[ 64 ];
    TagToString( node, tagdesc );
    messageNode( doc, TidyWarning, node,
                 "%s lacks \"%s\" attribute", tagdesc, name );
}

void ReportWarning( TidyDocImpl* doc, Node *element, Node *node, uint code )
{
    char nodedesc[ 256 ] = {0};
    char elemdesc[ 256 ] = {0};
    Node* rpt = ( element ? element : node );
    TagToString( node, nodedesc );

    switch ( code )
    {
    case MISSING_ENDTAG_FOR:
        messageNode( doc, TidyWarning, rpt,
                     "missing </%s>", element->element );
        break;

    case MISSING_ENDTAG_BEFORE:
        messageNode( doc, TidyWarning, rpt,
                     "missing </%s> before %s",
                     element->element, nodedesc );
        break;

    case DISCARDING_UNEXPECTED:
        /* Force error if in a bad form */
        messageNode( doc, doc->badForm ? TidyError : TidyWarning, node,
                     "discarding unexpected %s", nodedesc );
        break;

    case NESTED_EMPHASIS:
        messageNode( doc, TidyWarning, rpt,
                     "nested emphasis %s", nodedesc );
        break;

    case COERCE_TO_ENDTAG:
        messageNode( doc, TidyWarning, rpt,
                     "<%s> is probably intended as </%s>",
                     node->element, node->element );
        break;

    case NON_MATCHING_ENDTAG:
        messageNode( doc, TidyWarning, rpt,
                     "replacing unexpected %s by </%s>",
                     node->element, node->element );
        break;

    case TAG_NOT_ALLOWED_IN:
        messageNode( doc, TidyWarning, rpt,
                     "%s isn't allowed in <%s> elements",
                     nodedesc, element->element );
        break;

    case DOCTYPE_AFTER_TAGS:
        messageNode( doc, TidyWarning, rpt,
                     "<!DOCTYPE> isn't allowed after elements" );
        break;

    case MISSING_STARTTAG:
        messageNode( doc, TidyWarning, node,
                     "missing <%s>", node->element );
        break;

    case UNEXPECTED_ENDTAG:
        if ( element )
            messageNode( doc, TidyWarning, node,
                         "unexpected </%s> in <%s>",
                         node->element, element->element );
        else
            messageNode( doc, TidyWarning, node,
                         "unexpected </%s>", node->element );
        break;

    case TOO_MANY_ELEMENTS:
        if ( element )
            messageNode( doc, TidyWarning, node,
                         "too many %s elements in <%s>",
                         node->element, element->element );
        else
            messageNode( doc, TidyWarning, node,
                         "too many %s elements",
                         node->element );
        break;

    case USING_BR_INPLACE_OF:
        messageNode( doc, TidyWarning, node,
                     "using <br> in place of %s", nodedesc );
        break;

    case INSERTING_TAG:
        messageNode( doc, TidyWarning, node,
                     "inserting implicit <%s>", node->element );
        break;

    case CANT_BE_NESTED:
        messageNode( doc, TidyWarning, node,
                     "%s can't be nested", nodedesc );
        break;

    case PROPRIETARY_ELEMENT:
        messageNode( doc, TidyWarning, node,
                     "%s is not approved by W3C", nodedesc );
        break;

    case OBSOLETE_ELEMENT:
        {
          ctmbstr obsolete = "";
          if ( element->tag && (element->tag->model & CM_OBSOLETE) )
              obsolete = " obsolete";

          TagToString( element, elemdesc );
          messageNode( doc, TidyWarning, rpt,
                       "replacing %s element %s by %s",
                       obsolete, elemdesc, nodedesc );
        }
        break;

    case UNESCAPED_ELEMENT:
        messageNode( doc, TidyWarning, node,
                     "unescaped %s in pre content", nodedesc );
        break;

    case TRIM_EMPTY_ELEMENT:
        TagToString( element, elemdesc );
        messageNode( doc, TidyWarning, element,
                     "trimming empty %s", elemdesc );
        break;

    case MISSING_TITLE_ELEMENT:
        messageNode( doc, TidyWarning, rpt,
                     "inserting missing 'title' element" );
        break;

    case ILLEGAL_NESTING:
        TagToString( element, elemdesc );
        messageNode( doc, TidyWarning, element,
                     "%s shouldn't be nested", elemdesc );
        break;

    case NOFRAMES_CONTENT:
        messageNode( doc, TidyWarning, node,
                     "%s not inside 'noframes' element", nodedesc );
        break;

    case INCONSISTENT_VERSION:
        messageNode( doc, TidyWarning, rpt,
                     "HTML DOCTYPE doesn't match content" );
        break;

    case MALFORMED_DOCTYPE:
        messageNode( doc, TidyWarning, rpt,
                     "expected \"html PUBLIC\" or \"html SYSTEM\"" );
        break;

    case CONTENT_AFTER_BODY:
        messageNode( doc, TidyWarning, rpt,
                     "content occurs after end of body" );
        break;

    case MALFORMED_COMMENT:
        messageNode( doc, TidyWarning, rpt,
                     "adjacent hyphens within comment" );
        break;

    case BAD_COMMENT_CHARS:
        messageNode( doc, TidyWarning, rpt,
                     "expecting -- or >" );
        break;

    case BAD_XML_COMMENT:
        messageNode( doc, TidyWarning, rpt,
                     "XML comments can't contain --" );
        break;

    case BAD_CDATA_CONTENT:
        messageNode( doc, TidyWarning, rpt,
                     "'<' + '/' + letter not allowed here" );
        break;

    case INCONSISTENT_NAMESPACE:
        messageNode( doc, TidyWarning, rpt,
                     "HTML namespace doesn't match content" );
        break;

    case DTYPE_NOT_UPPER_CASE:
        messageNode( doc, TidyWarning, rpt,
                     "SYSTEM, PUBLIC, W3C, DTD, EN must be upper case" );
        break;

    case UNEXPECTED_END_OF_FILE:
        /* on end of file report position at end of input */
        TagToString( element, elemdesc );
        messageNode( doc, TidyWarning, element,
                     "unexpected end of file %s", elemdesc );
        break;

    case NESTED_QUOTATION:
        messageNode( doc, TidyWarning, rpt,
                     "nested q elements, possible typo." );
        break;

    case ELEMENT_NOT_EMPTY:
        TagToString( element, elemdesc );
        messageNode( doc, TidyWarning, element,
                     "%s element not empty or not closed", elemdesc );
        break;

    case ENCODING_IO_CONFLICT:
        messageNode( doc, TidyWarning, node,
           "Output encoding does not work with standard output" );
        break;
    }
}

void ReportError( TidyDocImpl* doc, Node *element, Node *node, uint code)
{
    char nodedesc[ 256 ] = {0};
    Node* rpt = ( element ? element : node );

    switch ( code )
    {
    case SUSPECTED_MISSING_QUOTE:
        messageNode( doc, TidyError, rpt, 
                     "missing quote mark for attribute value" );
        break;

    case DUPLICATE_FRAMESET:
        messageNode( doc, TidyError, rpt, "repeated FRAMESET element" );
        break;

    case UNKNOWN_ELEMENT:
        TagToString( node, nodedesc );
        messageNode( doc, TidyError, node, "%s is not recognized!", nodedesc );
        break;

    case UNEXPECTED_ENDTAG:  /* generated by XML docs */
        if (element)
            messageNode( doc, TidyError, node, "unexpected </%s> in <%s>",
                         node->element, element->element );
#if defined(__arm)
        if (!element)
#else
	    else
#endif
            messageNode( doc, TidyError, node, "unexpected </%s>",
                         node->element );
        break;
    }
}

void ErrorSummary( TidyDocImpl* doc )
{
    /* adjust badAccess to that its null if frames are ok */
    ctmbstr encnam = "specified";
    int charenc = cfg( doc, TidyCharEncoding ); 
    if ( charenc == WIN1252 ) 
        encnam = "Windows-1252";
    else if ( charenc == MACROMAN )
        encnam = "MacRoman";
    else if ( charenc == IBM858 )
        encnam = "ibm858";
    else if ( charenc == LATIN0 )
        encnam = "latin0";

    if ( doc->badAccess & (USING_FRAMES | USING_NOFRAMES) )
    {
        if (!((doc->badAccess & USING_FRAMES) && !(doc->badAccess & USING_NOFRAMES)))
            doc->badAccess &= ~(USING_FRAMES | USING_NOFRAMES);
    }

    if (doc->badChars)
    {
#if 0
        if ( doc->badChars & WINDOWS_CHARS )
        {
            tidy_out(doc, "Characters codes for the Microsoft Windows fonts in the range\n");
            tidy_out(doc, "128 - 159 may not be recognized on other platforms. You are\n");
            tidy_out(doc, "instead recommended to use named entities, e.g. &trade; rather\n");
            tidy_out(doc, "than Windows character code 153 (0x2122 in Unicode). Note that\n");
            tidy_out(doc, "as of February 1998 few browsers support the new entities.\n\n");
        }
#endif
        if (doc->badChars & VENDOR_SPECIFIC_CHARS)
        {

            tidy_out(doc, "It is unlikely that vendor-specific, system-dependent encodings\n");
            tidy_out(doc, "work widely enough on the World Wide Web; you should avoid using the \n");
            tidy_out(doc, encnam );
            tidy_out(doc, " character encoding, instead you are recommended to\n" );
            tidy_out(doc, "use named entities, e.g. &trade;.\n\n");
        }
        if ((doc->badChars & INVALID_SGML_CHARS) || (doc->badChars & INVALID_NCR))
        {
            tidy_out(doc, "Character codes 128 to 159 (U+0080 to U+009F) are not allowed in HTML;\n");
            tidy_out(doc, "even if they were, they would likely be unprintable control characters.\n");
            tidy_out(doc, "Tidy assumed you wanted to refer to a character with the same byte value in the \n");
            tidy_out(doc, encnam );
            tidy_out(doc, " encoding and replaced that reference with the Unicode equivalent.\n\n" );
        }
        if (doc->badChars & INVALID_UTF8)
        {
            tidy_out(doc, "Character codes for UTF-8 must be in the range: U+0000 to U+10FFFF.\n");
            tidy_out(doc, "The definition of UTF-8 in Annex D of ISO/IEC 10646-1:2000 also\n");
            tidy_out(doc, "allows for the use of five- and six-byte sequences to encode\n");
            tidy_out(doc, "characters that are outside the range of the Unicode character set;\n");
            tidy_out(doc, "those five- and six-byte sequences are illegal for the use of\n");
            tidy_out(doc, "UTF-8 as a transformation of Unicode characters. ISO/IEC 10646\n");
            tidy_out(doc, "does not allow mapping of unpaired surrogates, nor U+FFFE and U+FFFF\n");
            tidy_out(doc, "(but it does allow other noncharacters). For more information please refer to\n");
            tidy_out(doc, "http://www.unicode.org/unicode and http://www.cl.cam.ac.uk/~mgk25/unicode.html\n\n");
        }

#if SUPPORT_UTF16_ENCODINGS

      if (doc->badChars & INVALID_UTF16)
      {
        tidy_out(doc, "Character codes for UTF-16 must be in the range: U+0000 to U+10FFFF.\n");
        tidy_out(doc, "The definition of UTF-16 in Annex C of ISO/IEC 10646-1:2000 does not allow the\n");
        tidy_out(doc, "mapping of unpaired surrogates. For more information please refer to\n");
        tidy_out(doc, "http://www.unicode.org/unicode and http://www.cl.cam.ac.uk/~mgk25/unicode.html\n\n");
      }

#endif

      if (doc->badChars & INVALID_URI)
      {
        tidy_out(doc, "URIs must be properly escaped, they must not contain unescaped\n");
        tidy_out(doc, "characters below U+0021 including the space character and not\n");
        tidy_out(doc, "above U+007E. Tidy escapes the URI for you as recommended by\n");
        tidy_out(doc, "HTML 4.01 section B.2.1 and XML 1.0 section 4.2.2. Some user agents\n");
        tidy_out(doc, "use another algorithm to escape such URIs and some server-sided\n");
        tidy_out(doc, "scripts depend on that. If you want to depend on that, you must\n");
        tidy_out(doc, "escape the URI by your own. For more information please refer to\n");
        tidy_out(doc, "http://www.w3.org/International/O-URL-and-ident.html\n\n");
      }
    }

    if (doc->badForm)
    {
        tidy_out(doc, "You may need to move one or both of the <form> and </form>\n");
        tidy_out(doc, "tags. HTML elements should be properly nested and form elements\n");
        tidy_out(doc, "are no exception. For instance you should not place the <form>\n");
        tidy_out(doc, "in one table cell and the </form> in another. If the <form> is\n");
        tidy_out(doc, "placed before a table, the </form> cannot be placed inside the\n");
        tidy_out(doc, "table! Note that one form can't be nested inside another!\n\n");
    }
    
    if (doc->badAccess)
    {
      if ( cfg(doc, TidyAccessibilityCheckLevel) > 0 )
      {
        tidy_out(doc, "For further advice on how to make your pages accessible, see\n");
        tidy_out(doc, ACCESS_URL );
        tidy_out(doc, "and\n" );
        tidy_out(doc, ATRC_ACCESS_URL );
        tidy_out(doc, ".\n" );
        tidy_out(doc, "You may also want to try \"http://www.cast.org/bobby/\" which is a free Web-based\n");
        tidy_out(doc, "service for checking URLs for accessibility.\n\n");
      }
      else
      {
        if (doc->badAccess & MISSING_SUMMARY)
        {
          tidy_out(doc, "The table summary attribute should be used to describe\n");
          tidy_out(doc, "the table structure. It is very helpful for people using\n");
          tidy_out(doc, "non-visual browsers. The scope and headers attributes for\n");
          tidy_out(doc, "table cells are useful for specifying which headers apply\n");
          tidy_out(doc, "to each table cell, enabling non-visual browsers to provide\n");
          tidy_out(doc, "a meaningful context for each cell.\n\n");
        }

        if (doc->badAccess & MISSING_IMAGE_ALT)
        {
          tidy_out(doc, "The alt attribute should be used to give a short description\n");
          tidy_out(doc, "of an image; longer descriptions should be given with the\n");
          tidy_out(doc, "longdesc attribute which takes a URL linked to the description.\n");
          tidy_out(doc, "These measures are needed for people using non-graphical browsers.\n\n");
        }

        if (doc->badAccess & MISSING_IMAGE_MAP)
        {
          tidy_out(doc, "Use client-side image maps in preference to server-side image\n");
          tidy_out(doc, "maps as the latter are inaccessible to people using non-\n");
          tidy_out(doc, "graphical browsers. In addition, client-side maps are easier\n");
          tidy_out(doc, "to set up and provide immediate feedback to users.\n\n");
        }

        if (doc->badAccess & MISSING_LINK_ALT)
        {
          tidy_out(doc, "For hypertext links defined using a client-side image map, you\n");
          tidy_out(doc, "need to use the alt attribute to provide a textual description\n");
          tidy_out(doc, "of the link for people using non-graphical browsers.\n\n");
        }

        if ((doc->badAccess & USING_FRAMES) && !(doc->badAccess & USING_NOFRAMES))
        {
          tidy_out(doc, "Pages designed using frames presents problems for\n");
          tidy_out(doc, "people who are either blind or using a browser that\n");
          tidy_out(doc, "doesn't support frames. A frames-based page should always\n");
          tidy_out(doc, "include an alternative layout inside a NOFRAMES element.\n\n");
        }

        tidy_out(doc, "For further advice on how to make your pages accessible\n");
        tidy_out(doc, "see " );
        tidy_out(doc, ACCESS_URL );
        tidy_out(doc, ". You may also want to try\n" );
        tidy_out(doc, "\"http://www.cast.org/bobby/\" which is a free Web-based\n");
        tidy_out(doc, "service for checking URLs for accessibility.\n\n");
      }
    }

    if (doc->badLayout)
    {
        if (doc->badLayout & USING_LAYER)
        {
            tidy_out(doc, "The Cascading Style Sheets (CSS) Positioning mechanism\n");
            tidy_out(doc, "is recommended in preference to the proprietary <LAYER>\n");
            tidy_out(doc, "element due to limited vendor support for LAYER.\n\n");
        }

        if (doc->badLayout & USING_SPACER)
        {
            tidy_out(doc, "You are recommended to use CSS for controlling white\n");
            tidy_out(doc, "space (e.g. for indentation, margins and line spacing).\n");
            tidy_out(doc, "The proprietary <SPACER> element has limited vendor support.\n\n");
        }

        if (doc->badLayout & USING_FONT)
        {
            tidy_out(doc, "You are recommended to use CSS to specify the font and\n");
            tidy_out(doc, "properties such as its size and color. This will reduce\n");
            tidy_out(doc, "the size of HTML files and make them easier to maintain\n");
            tidy_out(doc, "compared with using <FONT> elements.\n\n");
        }

        if (doc->badLayout & USING_NOBR)
        {
            tidy_out(doc, "You are recommended to use CSS to control line wrapping.\n");
            tidy_out(doc, "Use \"white-space: nowrap\" to inhibit wrapping in place\n");
            tidy_out(doc, "of inserting <NOBR>...</NOBR> into the markup.\n\n");
        }

        if (doc->badLayout & USING_BODY)
        {
            tidy_out(doc, "You are recommended to use CSS to specify page and link colors\n");
        }
    }
}

void UnknownOption( TidyDocImpl* doc, char c )
{
    message( doc, TidyConfig,
             "unrecognized option -%c use -help to list options\n", c );
}

void UnknownFile( TidyDocImpl* doc, ctmbstr program, ctmbstr file )
{
    message( doc, TidyConfig, 
             "%s: can't open file \"%s\"\n", program, file );
}

void NeedsAuthorIntervention( TidyDocImpl* doc )
{
    tidy_out(doc, "This document has errors that must be fixed before\n");
    tidy_out(doc, "using HTML Tidy to generate a tidied up version.\n\n");
}

void MissingBody( TidyDocImpl* doc )
{
    tidy_out( doc, "Can't create slides - document is missing a body element.\n" );
}

void ReportNumberOfSlides( TidyDocImpl* doc, int count)
{
    tidy_out( doc, "%d Slides found", count );
}

void GeneralInfo( TidyDocImpl* doc )
{
    tidy_out(doc, "To learn more about HTML Tidy see http://tidy.sourceforge.net\n");
    tidy_out(doc, "Please send bug reports to html-tidy@w3.org\n");
    tidy_out(doc, "HTML and CSS specifications are available from http://www.w3.org/\n");
    tidy_out(doc, "Lobby your company to join W3C, see http://www.w3.org/Consortium\n");
}


void HelloMessage( TidyDocImpl* doc, ctmbstr date, ctmbstr filename )
{
    tmbchar buf[ 2048 ];
    ctmbstr platform = "", helper = "";
    ctmbstr msgfmt = "\nHTML Tidy for %s (vers %s; built on %s, at %s)\n"
                  "Parsing \"%s\"\n";

#ifdef PLATFORM_NAME
    platform = PLATFORM_NAME;
    helper = " for ";
#endif
    
    if ( tmbstrcmp(filename, "stdin") == 0 )
    {
        /* Filename will be ignored at end of varargs */
        msgfmt = "\nHTML Tidy for %s (vers %s; built on %s, at %s)\n"
                 "Parsing console input (stdin)\n";
    }
    
    sprintf( buf, msgfmt, helper, platform, 
             date, __DATE__, __TIME__, filename );
    tidy_out( doc, buf );
}

void ReportMarkupVersion( TidyDocImpl* doc )
{
    Node* doctype = doc->givenDoctype;

    if ( doctype )
    {
        Lexer* lexer = doc->lexer;
        uint ix;
        int quoteCount = 0;
        tmbchar buf[ 2048 ] = {0};
        tmbstr cp = buf;

        for ( ix = doctype->start; ix < doctype->end; ++ix )
        {
            uint c = (byte) lexer->lexbuf[ix];

            /* look for UTF-8 multibyte character */
            if ( c > 0x7F )
                ix += GetUTF8( lexer->lexbuf + ix, &c );

            if ( c == '"' )
                ++quoteCount;
            else if ( quoteCount == 1 )
                *cp++ = (tmbchar) c;
        }

        *cp = 0;
        message( doc, TidyInfo, "Doctype given is \"%s\"", buf );
    }

    if ( ! cfgBool(doc, TidyXmlTags) )
    {
        uint apparentVers = HTMLVersion( doc );
        Bool isXhtml = doc->lexer->isvoyager;
        ctmbstr vers = HTMLVersionNameFromCode( apparentVers, isXhtml );
        message( doc, TidyInfo, "Document content looks like %s", vers );
    }
}

void ReportNumWarnings( TidyDocImpl* doc )
{
    if ( doc->warnings > 0 || doc->errors > 0 )
    {
        tidy_out( doc, "%d %s, %d %s were found!",
                  doc->warnings, doc->warnings == 1 ? "warning" : "warnings",
                  doc->errors, doc->errors == 1 ? "error" : "errors" );

        if ( doc->errors > cfg(doc, TidyShowErrors) ||
             !cfgBool(doc, TidyShowWarnings) )
            tidy_out( doc, " Not all warnings/errors were shown.\n\n" );
        else
            tidy_out( doc, "\n\n" );
    }
    else
        tidy_out( doc, "No warnings or errors were found.\n\n" );
}

void HelpText( TidyDocImpl* doc, ctmbstr prog )
{
    tidy_out(doc, "%s [option...] [file...] [option...] [file...]\n", prog );
    tidy_out(doc, "Utility to clean up and pretty print HTML/XHTML/XML\n");
    tidy_out(doc, "see http://tidy.sourgeforge.net/\n");
    tidy_out(doc, "\n");

#ifdef PLATFORM_NAME
    tidy_out(doc, "Options for HTML Tidy for %s released on %s:\n",
             PLATFORM_NAME, release_date);
#else
    tidy_out(doc, "Options for HTML Tidy released on %s:\n", release_date);
#endif
    tidy_out(doc, "\n");

    tidy_out(doc, "File manipulation\n");
    tidy_out(doc, "-----------------\n");
    tidy_out(doc, "  -o <file>         to write output markup to specified <file>\n");
    tidy_out(doc, "  -config <file>    to set configuration options from the specified <file>\n");
    tidy_out(doc, "  -f <file>         to write errors to the specified <file>\n");
    tidy_out(doc, "  -modify or -m     to modify the original input files\n");
    tidy_out(doc, "\n");

    tidy_out(doc, "Processing directives\n");
    tidy_out(doc, "---------------------\n");
    tidy_out(doc, "  -asxhtml          to convert HTML to well formed XHTML\n");
    tidy_out(doc, "  -ashtml           to force XHTML to (non-XML) HTML\n");
    tidy_out(doc, "  -xml              to specify the input is XML\n");
    tidy_out(doc, "  -asxml            to convert input to well formed XML\n");
    tidy_out(doc, "  -indent  or -i    to indent element content\n");
    tidy_out(doc, "  -wrap <column>    to wrap text at the specified <column> (default is 68)\n");
    tidy_out(doc, "  -upper   or -u    to force tags to upper case (default is lower case)\n");
    tidy_out(doc, "  -clean   or -c    to replace FONT, NOBR and CENTER tags by CSS\n");
    tidy_out(doc, "  -bare    or -b    to strip out smart quotes and em dashes, etc.\n");
    tidy_out(doc, "  -numeric or -n    to output numeric rather than named entities\n");
    tidy_out(doc, "  -errors  or -e    to only show errors\n");
    tidy_out(doc, "  -quiet   or -q    to suppress nonessential output\n");
    tidy_out(doc, "  -omit             to omit optional end tags\n");

/* TRT */
#if SUPPORT_ACCESSIBILITY_CHECKS
    tidy_out(doc, "  -access <level>   to do additional accessibility checks (<level> = 1, 2, 3)\n");
#endif

    tidy_out(doc, "\n");

    tidy_out(doc, "Character encodings\n");
    tidy_out(doc, "-------------------\n");
    tidy_out(doc, "  -raw              to output values above 127 without conversion to entities\n");
    tidy_out(doc, "  -ascii            to use US-ASCII for output, ISO-8859-1 for input\n");
    tidy_out(doc, "  -latin0           to use ISO-8859-15 for input and US-ASCII for output\n");
    tidy_out(doc, "  -latin1           to use ISO-8859-1 for both input and output\n");
    tidy_out(doc, "  -iso2022          to use ISO-2022 for both input and output\n");
    tidy_out(doc, "  -utf8             to use UTF-8 for both input and output\n");
    tidy_out(doc, "  -mac              to use MacRoman for input, US-ASCII for output\n");
    tidy_out(doc, "  -win1252          to use Windows-1252 for input, US-ASCII for output\n");
    tidy_out(doc, "  -ibm858           to use IBM-858 (CP850+Euro) for input, US-ASCII for output\n");

#if SUPPORT_UTF16_ENCODINGS
    tidy_out(doc, "  -utf16le          to use UTF-16LE for both input and output\n");
    tidy_out(doc, "  -utf16be          to use UTF-16BE for both input and output\n");
    tidy_out(doc, "  -utf16            to use UTF-16 for both input and output\n");
#endif

#if SUPPORT_ASIAN_ENCODINGS
    tidy_out(doc, "  -big5             to use Big5 for both input and output\n"); /* #431953 - RJ */
    tidy_out(doc, "  -shiftjis         to use Shift_JIS for both input and output\n"); /* #431953 - RJ */
    tidy_out(doc, "  -language <lang>  to set the two-letter language code <lang> (for future use)\n"); /* #431953 - RJ */
#endif
    tidy_out(doc, "\n");

    tidy_out(doc, "Miscellaneous\n");
    tidy_out(doc, "-------------\n");
    tidy_out(doc, "  -version  or -v   to show the version of Tidy\n");
    tidy_out(doc, "  -help, -h or -?   to list the command line options\n");
    tidy_out(doc, "  -help-config      to list all configuration options\n");
    tidy_out(doc, "  -show-config      to list the current configuration settings\n");
    tidy_out(doc, "\n");
    tidy_out(doc, "Use --blah blarg for any configuration option \"blah\" with argument \"blarg\"\n");
    tidy_out(doc, "\n");

    tidy_out(doc, "Input/Output default to stdin/stdout respectively\n");
    tidy_out(doc, "Single letter options apart from -f may be combined\n");
    tidy_out(doc, "as in:  tidy -f errs.txt -imu foo.html\n");
    tidy_out(doc, "For further info on HTML see http://www.w3.org/MarkUp\n");
    tidy_out(doc, "\n");
}
