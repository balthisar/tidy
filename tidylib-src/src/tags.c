/* tags.c -- recognize HTML tags

  (c) 1998-2003 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: terry_teague $ 
    $Date: 2003/03/02 04:29:12 $ 
    $Revision: 1.22 $ 

  The HTML tags are stored as 8 bit ASCII strings.

*/

#include "tags.h"
#include "tidy-int.h"
#include "message.h"
#include "tmbstr.h"
#include "parser.h"  /* For FixId() */

static const Dict tag_defs[] =
{
  { TidyTag_UNKNOWN,   "unknown!",   0,            0,         null, null},
  { TidyTag_A,         "a",          VERS_ALL,     CM_INLINE, ParseInline, CheckAnchor},
  { TidyTag_ABBR,      "abbr",       VERS_HTML40,  CM_INLINE, ParseInline, null},
  { TidyTag_ACRONYM,   "acronym",    VERS_HTML40,  CM_INLINE, ParseInline, null},
  { TidyTag_ADDRESS,   "address",    VERS_ALL,     CM_BLOCK, ParseBlock, null},
  { TidyTag_ALIGN,     "align",      VERS_NETSCAPE, CM_BLOCK, ParseBlock, null},
  { TidyTag_APPLET,    "applet",     VERS_LOOSE,   (CM_OBJECT|CM_IMG|CM_INLINE|CM_PARAM), ParseBlock, null},
  { TidyTag_AREA,      "area",       (VERS_ALL)&~VERS_BASIC,     (CM_BLOCK|CM_EMPTY), ParseEmpty, CheckAREA},
  { TidyTag_B,         "b",          (VERS_ALL)&~VERS_BASIC,     CM_INLINE, ParseInline, null},
  { TidyTag_BASE,      "base",       VERS_ALL,     (CM_HEAD|CM_EMPTY), ParseEmpty, null},
  { TidyTag_BASEFONT,  "basefont",   VERS_LOOSE,   (CM_INLINE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_BDO,       "bdo",        (VERS_HTML40)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_BGSOUND,   "bgsound",    VERS_MICROSOFT, (CM_HEAD|CM_EMPTY), ParseEmpty, null},
  { TidyTag_BIG,       "big",        (VERS_FROM32)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_BLINK,     "blink",      VERS_PROPRIETARY, CM_INLINE, ParseInline, null},
  { TidyTag_BLOCKQUOTE,"blockquote", VERS_ALL,     CM_BLOCK, ParseBlock, null},
  { TidyTag_BODY,      "body",       VERS_ALL,     (CM_HTML|CM_OPT|CM_OMITST), ParseBody, null},
  { TidyTag_BR,        "br",         VERS_ALL,     (CM_INLINE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_BUTTON,    "button",     (VERS_HTML40)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_CAPTION,   "caption",    VERS_FROM32,  CM_TABLE, ParseInline, CheckCaption},
  { TidyTag_CENTER,    "center",     VERS_LOOSE,   CM_BLOCK, ParseBlock, null},
  { TidyTag_CITE,      "cite",       VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_CODE,      "code",       VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_COL,       "col",        VERS_HTML40,  (CM_TABLE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_COLGROUP,  "colgroup",   VERS_HTML40,  (CM_TABLE|CM_OPT), ParseColGroup, null},
  { TidyTag_COMMENT,   "comment",    VERS_MICROSOFT, CM_INLINE, ParseInline, null},
  { TidyTag_DD,        "dd",         VERS_ALL,     (CM_DEFLIST|CM_OPT|CM_NO_INDENT), ParseBlock, null},
  { TidyTag_DEL,       "del",        (VERS_HTML40)&~VERS_BASIC,  (CM_INLINE|CM_BLOCK|CM_MIXED), ParseInline, null},
  { TidyTag_DFN,       "dfn",        VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_DIR,       "dir",        VERS_LOOSE,   (CM_BLOCK|CM_OBSOLETE), ParseList, null},
  { TidyTag_DIV,       "div",        VERS_FROM32,  CM_BLOCK, ParseBlock, null},
  { TidyTag_DL,        "dl",         VERS_ALL,     CM_BLOCK, ParseDefList, null},
  { TidyTag_DT,        "dt",         VERS_ALL,     (CM_DEFLIST|CM_OPT|CM_NO_INDENT), ParseInline, null},
  { TidyTag_EM,        "em",         VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_EMBED,     "embed",      VERS_NETSCAPE, (CM_INLINE|CM_IMG|CM_EMPTY), ParseEmpty, null},
  { TidyTag_FIELDSET,  "fieldset",   (VERS_HTML40)&~VERS_BASIC,  CM_BLOCK, ParseBlock, null},
  { TidyTag_FONT,      "font",       VERS_LOOSE,   CM_INLINE, ParseInline, null},
  { TidyTag_FORM,      "form",       VERS_ALL,     CM_BLOCK, ParseBlock, CheckFORM},
  { TidyTag_FRAME,     "frame",      VERS_FRAMESET, (CM_FRAMES|CM_EMPTY), ParseEmpty, null},
  { TidyTag_FRAMESET,  "frameset",   VERS_FRAMESET, (CM_HTML|CM_FRAMES), ParseFrameSet, null},
  { TidyTag_H1,        "h1",         VERS_ALL,     (CM_BLOCK|CM_HEADING), ParseInline, null},
  { TidyTag_H2,        "h2",         VERS_ALL,     (CM_BLOCK|CM_HEADING), ParseInline, null},
  { TidyTag_H3,        "h3",         VERS_ALL,     (CM_BLOCK|CM_HEADING), ParseInline, null},
  { TidyTag_H4,        "h4",         VERS_ALL,     (CM_BLOCK|CM_HEADING), ParseInline, null},
  { TidyTag_H5,        "h5",         VERS_ALL,     (CM_BLOCK|CM_HEADING), ParseInline, null},
  { TidyTag_H6,        "h6",         VERS_ALL,     (CM_BLOCK|CM_HEADING), ParseInline, null},
  { TidyTag_HEAD,      "head",       VERS_ALL,     (CM_HTML|CM_OPT|CM_OMITST), ParseHead, null},
  { TidyTag_HR,        "hr",         (VERS_ALL)&~VERS_BASIC,     (CM_BLOCK|CM_EMPTY), ParseEmpty, CheckHR},
  { TidyTag_HTML,      "html",       VERS_ALL,     (CM_HTML|CM_OPT|CM_OMITST),  ParseHTML, CheckHTML},
  { TidyTag_I,         "i",          (VERS_ALL)&~VERS_BASIC,     CM_INLINE, ParseInline, null},
  { TidyTag_IFRAME,    "iframe",     VERS_IFRAME,  CM_INLINE, ParseBlock, null},
  { TidyTag_ILAYER,    "ilayer",     VERS_NETSCAPE, CM_INLINE, ParseInline, null},
  { TidyTag_IMG,       "img",        VERS_ALL,     (CM_INLINE|CM_IMG|CM_EMPTY), ParseEmpty, CheckIMG},
  { TidyTag_INPUT,     "input",      VERS_ALL,     (CM_INLINE|CM_IMG|CM_EMPTY), ParseEmpty, null},
  { TidyTag_INS,       "ins",        (VERS_HTML40)&~VERS_BASIC,  (CM_INLINE|CM_BLOCK|CM_MIXED), ParseInline, null},
  { TidyTag_ISINDEX,   "isindex",    VERS_LOOSE,   (CM_BLOCK|CM_EMPTY), ParseEmpty, null},
  { TidyTag_KBD,       "kbd",        VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_KEYGEN,    "keygen",     VERS_NETSCAPE, (CM_INLINE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_LABEL,     "label",      VERS_HTML40,  CM_INLINE, ParseInline, null},
  { TidyTag_LAYER,     "layer",      VERS_NETSCAPE, CM_BLOCK, ParseBlock, null},
  { TidyTag_LEGEND,    "legend",     (VERS_HTML40)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_LI,        "li",         VERS_ALL,     (CM_LIST|CM_OPT|CM_NO_INDENT), ParseBlock, null},
  { TidyTag_LINK,      "link",       VERS_ALL,     (CM_HEAD|CM_EMPTY), ParseEmpty, CheckLINK},
  { TidyTag_LISTING,   "listing",    VERS_ALL,     (CM_BLOCK|CM_OBSOLETE), ParsePre, null},
  { TidyTag_MAP,       "map",        (VERS_FROM32)&~VERS_BASIC,  CM_INLINE, ParseBlock, CheckMap},
  { TidyTag_MARQUEE,   "marquee",    VERS_MICROSOFT, (CM_INLINE|CM_OPT), ParseInline, null},
  { TidyTag_MENU,      "menu",       VERS_LOOSE,   (CM_BLOCK|CM_OBSOLETE), ParseList, null},
  { TidyTag_META,      "meta",       VERS_ALL,     (CM_HEAD|CM_EMPTY), ParseEmpty, CheckMETA},
  { TidyTag_MULTICOL,  "multicol",   VERS_NETSCAPE,  CM_BLOCK, ParseBlock, null},
  { TidyTag_NOBR,      "nobr",       VERS_PROPRIETARY, CM_INLINE, ParseInline, null},
  { TidyTag_NOEMBED,   "noembed",    VERS_NETSCAPE, CM_INLINE, ParseInline, null},
  { TidyTag_NOFRAMES,  "noframes",   VERS_IFRAME,  (CM_BLOCK|CM_FRAMES), ParseNoFrames,  null},
  { TidyTag_NOLAYER,   "nolayer",    VERS_NETSCAPE, (CM_BLOCK|CM_INLINE|CM_MIXED), ParseBlock, null},
  { TidyTag_NOSAVE,    "nosave",     VERS_NETSCAPE, CM_BLOCK, ParseBlock, null},
  { TidyTag_NOSCRIPT,  "noscript",   (VERS_HTML40)&~VERS_BASIC,  (CM_BLOCK|CM_INLINE|CM_MIXED), ParseBlock, null},
  { TidyTag_OBJECT,    "object",     VERS_HTML40,  (CM_OBJECT|CM_HEAD|CM_IMG|CM_INLINE|CM_PARAM), ParseBlock, null},
  { TidyTag_OL,        "ol",         VERS_ALL,     CM_BLOCK, ParseList, null},
  { TidyTag_OPTGROUP,  "optgroup",   (VERS_HTML40)&~VERS_BASIC,  (CM_FIELD|CM_OPT), ParseOptGroup, null},
  { TidyTag_OPTION,    "option",     VERS_ALL,     (CM_FIELD|CM_OPT), ParseText, null},
  { TidyTag_P,         "p",          VERS_ALL,     (CM_BLOCK|CM_OPT), ParseInline, null},
  { TidyTag_PARAM,     "param",      VERS_FROM32,  (CM_INLINE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_PLAINTEXT, "plaintext",  VERS_ALL,     (CM_BLOCK|CM_OBSOLETE), ParsePre, null},
  { TidyTag_PRE,       "pre",        VERS_ALL,     CM_BLOCK, ParsePre, null},
  { TidyTag_Q,         "q",          VERS_HTML40,  CM_INLINE, ParseInline, null},
  { TidyTag_RB,        "rb",         VERS_XHTML11, CM_INLINE, ParseInline, null},
  { TidyTag_RBC,       "rbc",        VERS_XHTML11, CM_INLINE, ParseInline, null}, 
  { TidyTag_RP,        "rp",         VERS_XHTML11, CM_INLINE, ParseInline, null},
  { TidyTag_RT,        "rt",         VERS_XHTML11, CM_INLINE, ParseInline, null},
  { TidyTag_RTC,       "rtc",        VERS_XHTML11, CM_INLINE, ParseInline, null},
  { TidyTag_RUBY,      "ruby",       VERS_XHTML11, CM_INLINE, ParseInline, null},
  { TidyTag_S,         "s",          VERS_LOOSE,   CM_INLINE, ParseInline, null},
  { TidyTag_SAMP,      "samp",       VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_SCRIPT,    "script",     (VERS_FROM32)&~VERS_BASIC,  (CM_HEAD|CM_MIXED|CM_BLOCK|CM_INLINE), ParseScript, CheckSCRIPT},
  { TidyTag_SELECT,    "select",     VERS_ALL,     (CM_INLINE|CM_FIELD), ParseSelect, null},
  { TidyTag_SERVER,    "server",     VERS_NETSCAPE,  (CM_HEAD|CM_MIXED|CM_BLOCK|CM_INLINE), ParseScript, null},
  { TidyTag_SERVLET,   "servlet",    VERS_SUN,     (CM_OBJECT|CM_IMG|CM_INLINE|CM_PARAM), ParseBlock, null},
  { TidyTag_SMALL,     "small",      (VERS_FROM32)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_SPACER,    "spacer",     VERS_NETSCAPE, (CM_INLINE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_SPAN,      "span",       VERS_FROM32,  CM_INLINE, ParseInline, null},
  { TidyTag_STRIKE,    "strike",     VERS_LOOSE,   CM_INLINE, ParseInline, null},
  { TidyTag_STRONG,    "strong",     VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_STYLE,     "style",      (VERS_FROM32)&~VERS_BASIC,  CM_HEAD, ParseScript, CheckSTYLE},
  { TidyTag_SUB,       "sub",        (VERS_FROM32)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_SUP,       "sup",        (VERS_FROM32)&~VERS_BASIC,  CM_INLINE, ParseInline, null},
  { TidyTag_TABLE,     "table",      VERS_FROM32,  CM_BLOCK, ParseTableTag, CheckTABLE},
  { TidyTag_TBODY,     "tbody",      (VERS_HTML40)&~VERS_BASIC,  (CM_TABLE|CM_ROWGRP|CM_OPT), ParseRowGroup, null},
  { TidyTag_TD,        "td",         VERS_FROM32,  (CM_ROW|CM_OPT|CM_NO_INDENT), ParseBlock, CheckTableCell},
  { TidyTag_TEXTAREA,  "textarea",   VERS_ALL,     (CM_INLINE|CM_FIELD), ParseText, null},
  { TidyTag_TFOOT,     "tfoot",      (VERS_HTML40)&~VERS_BASIC,  (CM_TABLE|CM_ROWGRP|CM_OPT), ParseRowGroup, null},
  { TidyTag_TH,        "th",         VERS_FROM32,  (CM_ROW|CM_OPT|CM_NO_INDENT), ParseBlock, CheckTableCell},
  { TidyTag_THEAD,     "thead",      (VERS_HTML40)&~VERS_BASIC,  (CM_TABLE|CM_ROWGRP|CM_OPT), ParseRowGroup, null},
  { TidyTag_TITLE,     "title",      VERS_ALL,     CM_HEAD, ParseTitle, null},
  { TidyTag_TR,        "tr",         VERS_FROM32,  (CM_TABLE|CM_OPT), ParseRow, null},
  { TidyTag_TT,        "tt",         (VERS_ALL)&~VERS_BASIC,     CM_INLINE, ParseInline, null},
  { TidyTag_U,         "u",          VERS_LOOSE,   CM_INLINE, ParseInline, null},
  { TidyTag_UL,        "ul",         VERS_ALL,     CM_BLOCK, ParseList, null},
  { TidyTag_VAR,       "var",        VERS_ALL,     CM_INLINE, ParseInline, null},
  { TidyTag_WBR,       "wbr",        VERS_PROPRIETARY, (CM_INLINE|CM_EMPTY), ParseEmpty, null},
  { TidyTag_XMP,       "xmp",        VERS_ALL,     (CM_BLOCK|CM_OBSOLETE), ParsePre, null},
  /* this must be the final entry */
    {null,         0,            0,          0,       0}
};

/* choose what version to use for new doctype */
int HTMLVersion( TidyDocImpl* doc )
{
    int dtver = doc->lexer->doctype;
    uint versions = doc->lexer->versions;
    TidyDoctypeModes dtmode = cfg(doc, TidyDoctypeMode);

    Bool wantXhtml = !cfgBool(doc, TidyHtmlOut) &&
                     ( cfgBool(doc, TidyXmlOut) || doc->lexer->isvoyager );

    Bool wantHtml4 = dtmode==TidyDoctypeStrict || dtmode==TidyDoctypeLoose ||
                     dtver==VERS_HTML40_STRICT || dtver==VERS_HTML40_LOOSE;

    /* Prefer HTML 4.x for XHTML */
    if ( !wantXhtml && !wantHtml4 )
    {
        if ( versions & VERS_HTML32 )   /* Prefer 3.2 over 2.0 */
            return VERS_HTML32;

        if ( versions & VERS_HTML20 )
            return VERS_HTML20;
    }

    if ( wantXhtml && (versions & VERS_XHTML11) )
        return VERS_XHTML11;

    if ( versions & VERS_HTML40_STRICT )
        return VERS_HTML40_STRICT;

    if ( versions & VERS_HTML40_LOOSE )
        return VERS_HTML40_LOOSE;

    if ( versions & VERS_FRAMESET )
        return VERS_FRAMESET;

    /* Still here?  Try these again. */
    if ( versions & VERS_HTML32 )   /* Prefer 3.2 over 2.0 */
        return VERS_HTML32;

    if ( versions & VERS_HTML20 )
        return VERS_HTML20;

    return VERS_UNKNOWN;
}

static const Dict* lookup( TidyTagImpl* tags, ctmbstr s )
{
    Dict *np = null;
    if ( s )
    {
        const Dict *np = tag_defs + 1;  /* Skip Unknown */
        for ( /**/; np < tag_defs + N_TIDY_TAGS; ++np )
            if ( tmbstrcmp(s, np->name) == 0 )
                return np;

        for ( np = tags->declared_tag_list; np; np = np->next )
            if ( tmbstrcmp(s, np->name) == 0 )
                return np;
    }
    return null;
}


static void declare( TidyTagImpl* tags,
                     ctmbstr name, uint versions, uint model, 
                     Parser *parser, CheckAttribs *chkattrs )
{
    if ( name )
    {
        Dict* np = (Dict*) lookup( tags, name );
        if ( np == null )
        {
            np = (Dict*) MemAlloc( sizeof(Dict) );
            ClearMemory( np, sizeof(Dict) );

            np->name = tmbstrdup( name );
            np->next = tags->declared_tag_list;
            tags->declared_tag_list = np;
        }

        /* Make sure we are not over-writing predefined tags */
        if ( np->id == TidyTag_UNKNOWN )
        {
          np->versions = versions;
          np->model   |= model;
          np->parser   = parser;
          np->chkattrs = chkattrs;
        }
    }
}

/* public interface for finding tag by name */
Bool FindTag( TidyDocImpl* doc, Node *node )
{
    const Dict *np = null;
    if ( cfgBool(doc, TidyXmlTags) )
    {
        node->tag = doc->tags.xml_tags;
        return yes;
    }

    if ( node->element && (np = lookup(&doc->tags, node->element)) )
    {
        node->tag = np;
        return yes;
    }
    
    return no;
}

const Dict* LookupTagDef( TidyTagId tid )
{
  if ( tid > TidyTag_UNKNOWN && tid < N_TIDY_TAGS )
      return tag_defs + tid;
  return null;
}


Parser* FindParser( TidyDocImpl* doc, Node *node )
{
    const Dict* np = lookup( &doc->tags, node->element );
    if ( np )
        return np->parser;
    return null;
}

void DefineTag( TidyDocImpl* doc, int tagType, ctmbstr name )
{
    Parser* parser = null;
    uint cm = 0;
    uint vers = VERS_PROPRIETARY;

    switch (tagType)
    {
    case tagtype_empty:
        cm = CM_EMPTY|CM_NO_INDENT|CM_NEW;
        parser = ParseBlock;
        break;

    case tagtype_inline:
        cm = CM_INLINE|CM_NO_INDENT|CM_NEW;
        parser = ParseInline;
        break;

    case tagtype_block:
        cm = CM_BLOCK|CM_NO_INDENT|CM_NEW;
        parser = ParseBlock;
        break;

    case tagtype_pre:
        cm = CM_BLOCK|CM_NO_INDENT|CM_NEW;
        parser = ParsePre;
        break;
    }
    if ( cm && parser )
        declare( &doc->tags, name, vers, cm, parser, null );
}

TidyIterator   GetDeclaredTagList( TidyDocImpl* doc )
{
    return (TidyIterator) doc->tags.declared_tag_list;
}

ctmbstr        GetNextDeclaredTag( TidyDocImpl* doc, int tagType,
                                   TidyIterator* iter )
{
    ctmbstr name = null;
    Dict* curr = (Dict*) *iter;
    for ( /**/; name == null && curr != null; curr = curr->next )
    {
        switch ( tagType )
        {
        case tagtype_empty:
            if ( curr->model & CM_EMPTY )
                name = curr->name;
            break;

        case tagtype_inline:
            if ( curr->model & CM_INLINE )
                name = curr->name;
            break;

        case tagtype_block:
            if ( (curr->model & CM_BLOCK) &&
                 curr->parser == ParseBlock )
                name = curr->name;
            break;
    
        case tagtype_pre:
            if ( (curr->model & CM_BLOCK) &&
                 curr->parser == ParsePre )
                name = curr->name;
            break;
        }
    }
    *iter = (TidyIterator) ( curr ? curr : null );
    return name;
}

void InitTags( TidyDocImpl* doc )
{
    Dict* xml;
    TidyTagImpl* tags = &doc->tags;
    ClearMemory( tags, sizeof(TidyTagImpl) );

    /* create dummy entry for all xml tags */
    xml = (Dict*) MemAlloc( sizeof(Dict) );
    ClearMemory( xml, sizeof(Dict) );
    xml->name = null;
    xml->versions = VERS_XML;
    xml->model = CM_BLOCK;
    xml->parser = null;
    xml->chkattrs = null;
    tags->xml_tags = xml;
}

/* By default, zap all of them.  But allow
** an single type to be specified.
*/
void FreeDeclaredTags( TidyDocImpl* doc, int tagType )
{
    TidyTagImpl* tags = &doc->tags;
    Dict *curr, *next = null, *prev = null;

    for ( curr=tags->declared_tag_list; curr; curr = next )
    {
        Bool deleteIt = yes;
        next = curr->next;
        switch ( tagType )
        {
        case tagtype_empty:
            deleteIt = ( curr->model & CM_EMPTY );
            break;

        case tagtype_inline:
            deleteIt = ( curr->model & CM_INLINE );
            break;

        case tagtype_block:
            deleteIt = ( (curr->model & CM_BLOCK) &&
                         curr->parser == ParseBlock );
            break;
    
        case tagtype_pre:
            deleteIt = ( (curr->model & CM_BLOCK) &&
                         curr->parser == ParsePre );
            break;
        }

        if ( deleteIt )
        {
          MemFree( curr->name );
          MemFree( curr );
          if ( prev )
            prev->next = next;
          else
            tags->declared_tag_list = next;
        }
        else
          prev = curr;
    }
}

void FreeTags( TidyDocImpl* doc )
{
    TidyTagImpl* tags = &doc->tags;
    FreeDeclaredTags( doc, 0 );

    MemFree( tags->xml_tags );

    /* get rid of dangling tag references */
    ClearMemory( tags, sizeof(TidyTagImpl) );
}


/* default method for checking an element's attributes */
void CheckAttributes( TidyDocImpl* doc, Node *node )
{
    AttVal *attval;
    for ( attval = node->attributes; attval != null; attval = attval->next )
        CheckAttribute( doc, node, attval );
}

/* methods for checking attributes for specific elements */

void CheckHR( TidyDocImpl* doc, Node *node )
{
    AttVal* av = GetAttrByName( node, "src" );
    CheckAttributes( doc, node );
    if ( av )
        ReportAttrError( doc, node, av, PROPRIETARY_ATTR_VALUE );
}

void CheckIMG( TidyDocImpl* doc, Node *node )
{
    Bool HasAlt = no;
    Bool HasSrc = no;
    Bool HasUseMap = no;
    Bool HasIsMap = no;
    Bool HasDataFld = no;

    AttVal *attval;
    for ( attval = node->attributes; attval != null; attval = attval->next )
    {
        const Attribute* dict = CheckAttribute( doc, node, attval );
        if ( dict )
        {
            TidyAttrId id = dict->id;
            if ( id == TidyAttr_ALT )
                HasAlt = yes;
            else if ( id == TidyAttr_SRC )
                HasSrc = yes;
            else if ( id == TidyAttr_USEMAP )
                HasUseMap = yes;
            else if ( id == TidyAttr_ISMAP )
                HasIsMap = yes;
            else if ( id == TidyAttr_DATAFLD )
                HasDataFld = yes;
            else if ( id == TidyAttr_WIDTH || id == TidyAttr_HEIGHT )
                ConstrainVersion( doc, ~VERS_HTML20 );
        }
    }

    if ( !HasAlt )
    {
        if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
        {
            doc->badAccess |= MISSING_IMAGE_ALT;
            ReportMissingAttr( doc, node, "alt" );
        }
  
        if ( cfgStr(doc, TidyAltText) )
            AddAttribute( doc, node, "alt", cfgStr(doc, TidyAltText) );
    }

    if ( !HasSrc && !HasDataFld )
        ReportMissingAttr( doc, node, "src" );

    if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
    {
        if ( HasIsMap && !HasUseMap )
            ReportMissingAttr( doc, node, "ismap" );
    }
}

void CheckAnchor( TidyDocImpl* doc, Node *node )
{
    CheckAttributes( doc, node );
    FixId( doc, node );
}

void CheckMap( TidyDocImpl* doc, Node *node )
{
    CheckAttributes( doc, node );
    FixId( doc, node );
}

void CheckTableCell( TidyDocImpl* doc, Node *node )
{
    CheckAttributes( doc, node );

    /*
      HTML4 strict doesn't allow mixed content for
      elements with %block; as their content model
    */
    if ( GetAttrByName(node, "width") 
         || GetAttrByName(node, "height") )
        ConstrainVersion( doc, ~VERS_HTML40_STRICT );
}

void CheckCaption( TidyDocImpl* doc, Node *node )
{
    AttVal *attval;
    char *value = null;

    CheckAttributes( doc, node );

    for (attval = node->attributes; attval != null; attval = attval->next)
    {
        if ( tmbstrcasecmp(attval->attribute, "align") == 0 )
        {
            value = attval->value;
            break;
        }
    }

    if (value != null)
    {
        if ( tmbstrcasecmp(value, "left") == 0 ||
             tmbstrcasecmp(value, "right") == 0 )
            ConstrainVersion( doc, VERS_HTML40_LOOSE );
        else if ( tmbstrcasecmp(value, "top") == 0 ||
                  tmbstrcasecmp(value, "bottom") == 0 )
            ConstrainVersion( doc, ~(VERS_HTML20|VERS_HTML32) );
        else
            ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE );
    }
}

void CheckHTML( TidyDocImpl* doc, Node *node )
{
    AttVal *attval;
    AttVal *xmlns;

    xmlns = GetAttrByName(node, "xmlns");

    if ( xmlns != null && tmbstrcmp(xmlns->value, XHTML_NAMESPACE) == 0 )
    {
        Bool htmlOut = cfgBool( doc, TidyHtmlOut );
        doc->lexer->isvoyager = yes;                  /* Unless plain HTML */
        SetOptionBool( doc, TidyXhtmlOut, !htmlOut ); /* is specified, output*/
        SetOptionBool( doc, TidyXmlOut, !htmlOut );   /* will be XHTML. */

        /* adjust other config options, just as in config.c */
        if ( !htmlOut )
        {
            SetOptionBool( doc, TidyUpperCaseTags, no );
            SetOptionBool( doc, TidyUpperCaseAttrs, no );
        }
    }

    for (attval = node->attributes; attval != null; attval = attval->next)
    {
        CheckAttribute( doc, node, attval );
    }
}

void CheckAREA( TidyDocImpl* doc, Node *node )
{
    Bool HasAlt = no;
    Bool HasHref = no;
    AttVal *attval;

    for (attval = node->attributes; attval != null; attval = attval->next)
    {
        const Attribute* dict = CheckAttribute( doc, node, attval );
        if ( dict )
        {
          if ( dict->id == TidyAttr_ALT )
              HasAlt = yes;
          else if ( dict->id == TidyAttr_HREF )
              HasHref = yes;
        }
    }

    if ( !HasAlt )
    {
        if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
        {
            doc->badAccess |= MISSING_LINK_ALT;
            ReportMissingAttr( doc, node, "alt" );
        }
    }

    if ( !HasHref )
        ReportMissingAttr( doc, node, "href" );
}

void CheckTABLE( TidyDocImpl* doc, Node *node )
{
    Bool HasSummary = no;
    AttVal *attval;

    for (attval = node->attributes; attval != null; attval = attval->next)
    {
        const Attribute* dict = CheckAttribute( doc, node, attval );
        if ( dict && dict->id == TidyAttr_SUMMARY )
            HasSummary = yes;
    }

    /* suppress warning for missing summary for HTML 2.0 and HTML 3.2 */
    if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
    {
        Lexer* lexer = doc->lexer;
        if ( !HasSummary 
             && lexer->doctype != VERS_HTML20
             && lexer->doctype != VERS_HTML32 )
        {
            doc->badAccess |= MISSING_SUMMARY;
            ReportMissingAttr( doc, node, "summary");
        }
    }

    /* convert <table border> to <table border="1"> */
    if ( cfgBool(doc, TidyXmlOut) && (attval = GetAttrByName(node, "border")) )
    {
        if (attval->value == null)
            attval->value = tmbstrdup("1");
    }

    /* <table height="..."> is proprietary */
    if ( attval = GetAttrByName(node, "height") )
    {
        ReportAttrError( doc, node, attval, PROPRIETARY_ATTRIBUTE );
        ConstrainVersion( doc, VERS_PROPRIETARY );
    }
}

/* add missing type attribute when appropriate */
void CheckSCRIPT( TidyDocImpl* doc, Node *node )
{
    AttVal *lang, *type;
    char buf[16];

    CheckAttributes( doc, node );

    lang = GetAttrByName( node, "language" );
    type = GetAttrByName( node, "type" );

    if ( !type )
    {
        /*  ReportMissingAttr( doc, node, "type" );  */

        /* check for javascript */
        if ( lang )
        {
            tmbstrncpy( buf, lang->value, sizeof(buf) );
            buf[10] = '\0';

            if ( tmbstrncasecmp(buf, "javascript", 10) == 0 ||
                 tmbstrncasecmp(buf,    "jscript", 7) == 0 )
            {
                AddAttribute( doc, node, "type", "text/javascript" );
            }
            else if ( tmbstrcasecmp(buf, "vbscript") == 0 )
            {
                /* per Randy Waki 8/6/01 */
                AddAttribute( doc, node, "type", "text/vbscript" );
            }
        }
        else
            AddAttribute( doc, node, "type", "text/javascript" );
        type = GetAttrByName( node, "type" );
        ReportAttrError( doc, node, type, INSERTING_ATTRIBUTE );
    }
}


/* add missing type attribute when appropriate */
void CheckSTYLE( TidyDocImpl* doc, Node *node )
{
    AttVal *type = GetAttrByName( node, "type" );

    CheckAttributes( doc, node );

    if ( !type )
    {
        AddAttribute( doc, node, "type", "text/css" );
        type = GetAttrByName( node, "type" );
        ReportAttrError( doc, node, type, INSERTING_ATTRIBUTE );
    }
}

/* add missing type attribute when appropriate */
void CheckLINK( TidyDocImpl* doc, Node *node )
{
    AttVal *rel = GetAttrByName( node, "rel" );

    CheckAttributes( doc, node );

    if ( rel && rel->value &&
         tmbstrcmp(rel->value, "stylesheet") == 0 )
    {
        AttVal *type = GetAttrByName(node, "type");
        if (!type)
        {
            AddAttribute( doc, node, "type", "text/css" );
            type = GetAttrByName( node, "type" );
            ReportAttrError( doc, node, type, INSERTING_ATTRIBUTE );
        }
    }
}

/* reports missing action attribute */
void CheckFORM( TidyDocImpl* doc, Node *node )
{
    AttVal *action = GetAttrByName( node, "action" );
    CheckAttributes( doc, node );
    if (!action)
        ReportMissingAttr( doc, node, "action");
}

/* reports missing content attribute */
void CheckMETA( TidyDocImpl* doc, Node *node )
{
    AttVal *content = GetAttrByName( node, "content" );
    CheckAttributes( doc, node );
    if ( ! content )
        ReportMissingAttr( doc, node, "content" );
    /* name or http-equiv attribute must also be set */
}


Bool nodeIsText( Node* node )
{
  return ( node && node->type == TextNode );
}

Bool nodeHasText( TidyDocImpl* doc, Node* node )
{
  if ( doc && node )
  {
    uint ix;
    Lexer* lexer = doc->lexer;
    for ( ix = node->start; ix < node->end; ++ix )
    {
        /* whitespace */
        if ( !IsWhite( lexer->lexbuf[ix] ) )
            return yes;
    }
  }
  return no;
}

Bool nodeIsElement( Node* node )
{
  return ( node && 
           (node->type == StartTag || node->type == StartEndTag) );
}

/* Compare & result to operand.  If equal, then all bits
** requested are set.
*/
Bool nodeMatchCM( Node* node, uint contentModel )
{
  return ( node && node->tag && 
           (node->tag->model & contentModel) == contentModel );
}

/* True if any of the bits requested are set.
*/
Bool nodeHasCM( Node* node, uint contentModel )
{
  return ( node && node->tag && 
           (node->tag->model & contentModel) != 0 );
}

Bool nodeCMIsBlock( Node* node )
{
  return nodeHasCM( node, CM_BLOCK );
}
Bool nodeCMIsInline( Node* node )
{
  return nodeHasCM( node, CM_INLINE );
}
Bool nodeCMIsEmpty( Node* node )
{
  return nodeHasCM( node, CM_EMPTY );
}

Bool nodeIsHeader( Node* node )
{
    TidyTagId tid = TagId( node  );
    return ( tid && 
             tid == TidyTag_H1 ||
             tid == TidyTag_H2 ||
             tid == TidyTag_H3 ||        
             tid == TidyTag_H4 ||        
             tid == TidyTag_H5 ||
             tid == TidyTag_H6 );
}

uint nodeHeaderLevel( Node* node )
{
    TidyTagId tid = TagId( node  );
    switch ( tid )
    {
    case TidyTag_H1:
        return 1;
    case TidyTag_H2:
        return 2;
    case TidyTag_H3:
        return 3;
    case TidyTag_H4:
        return 4;
    case TidyTag_H5:
        return 5;
    case TidyTag_H6:
        return 6;
    }
    return 0;
}
