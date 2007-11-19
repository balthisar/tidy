/*
  pprint.c -- pretty print parse tree  
  
  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:11 $ 
    $Revision: 1.50 $ 

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pprint.h"
#include "tidy-int.h"
#include "parser.h"
#include "entities.h"
#include "tmbstr.h"
#include "utf8.h"

/*
  Block-level and unknown elements are printed on
  new lines and their contents indented 2 spaces

  Inline elements are printed inline.

  Inline content is wrapped on spaces (except in
  attribute values or preformatted text, after
  start tags and before end tags
*/

static void PPrintAsp( TidyDocImpl* doc, uint indent, Node* node );
static void PPrintJste( TidyDocImpl* doc, uint indent, Node* node );
static void PPrintPhp( TidyDocImpl* doc, uint indent, Node* node );
static int  TextEndsWithNewline( Lexer *lexer, Node *node, uint mode );
static int  TextStartsWithWhitespace( Lexer *lexer, Node *node, uint start, uint mode );
static Bool InsideHead( TidyDocImpl* doc, Node *node );
static Bool ShouldIndent( TidyDocImpl* doc, Node *node );

#if SUPPORT_ASIAN_ENCODINGS
/* #431953 - start RJ Wraplen adjusted for smooth international ride */

uint CWrapLen( TidyDocImpl* doc, uint ind )
{
    ctmbstr lang = cfgStr( doc, TidyLanguage );
    uint wraplen = cfg( doc, TidyWrapLen );

    if ( !tmbstrcasecmp(lang, "zh") )
        /* Chinese characters take two positions on a fixed-width screen */ 
        /* It would be more accurate to keep a parallel linelen and wraphere
           incremented by 2 for Chinese characters and 1 otherwise, but this
           is way simpler.
        */
        return (ind + (( wraplen - ind ) / 2)) ; 
    
    if ( !tmbstrcasecmp(lang, "ja") )
        /* average Japanese text is 30% kanji */
        return (ind + ((( wraplen - ind ) * 7) / 10)) ; 
    
    return wraplen;
}
#endif

static void InitIndent( TidyIndent* ind )
{
    ind->spaces = -1;
    ind->attrValStart = -1;
    ind->attrStringStart = -1;
}

void InitPrintBuf( TidyDocImpl* doc )
{
    ClearMemory( &doc->pprint, sizeof(TidyPrintImpl) );
    InitIndent( &doc->pprint.indent[0] );
    InitIndent( &doc->pprint.indent[1] );
}

void FreePrintBuf( TidyDocImpl* doc )
{
    MemFree( doc->pprint.linebuf );
    InitPrintBuf( doc );
}

static void expand( TidyPrintImpl* pprint, uint len )
{
    uint* ip;
    uint buflen = pprint->lbufsize;

    if ( buflen == 0 )
        buflen = 256;
    while ( len >= buflen )
        buflen *= 2;

    ip = (uint*) MemRealloc( pprint->linebuf, buflen*sizeof(uint) );
    if ( ip )
    {
      ClearMemory( ip+pprint->lbufsize, 
                   (buflen-pprint->lbufsize)*sizeof(uint) );
      pprint->lbufsize = buflen;
      pprint->linebuf = ip;
    }
}

static uint GetSpaces( TidyPrintImpl* pprint )
{
    int spaces = pprint->indent[ 0 ].spaces;
    return ( spaces < 0 ? 0U : (uint) spaces );
}
static int ClearInString( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + pprint->ixInd;
    return ind->attrStringStart = -1;
}
static int ToggleInString( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + pprint->ixInd;
    Bool inString = ( ind->attrStringStart >= 0 );
    return ind->attrStringStart = ( inString ? -1 : (int) pprint->linelen );
}
static Bool IsInString( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + 0; /* Always 1st */
    return ( ind->attrStringStart >= 0 && 
             ind->attrStringStart < (int) pprint->linelen );
}
static Bool IsWrapInString( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + 0; /* Always 1st */
    int wrap = (int) pprint->wraphere;
    return ( ind->attrStringStart == 0 ||
             (ind->attrStringStart > 0 && ind->attrStringStart < wrap) );
}

static void ClearInAttrVal( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + pprint->ixInd;
    ind->attrValStart = -1;
}
static int SetInAttrVal( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + pprint->ixInd;
    return ind->attrValStart = (int) pprint->linelen;
}
static Bool IsWrapInAttrVal( TidyPrintImpl* pprint )
{
    TidyIndent *ind = pprint->indent + 0; /* Always 1st */
    int wrap = (int) pprint->wraphere;
    return ( ind->attrValStart == 0 ||
             (ind->attrValStart > 0 && ind->attrValStart < wrap) );
}

static Bool WantIndent( TidyDocImpl* doc )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool wantIt = GetSpaces(pprint) > 0;
    if ( wantIt )
    {
        Bool indentAttrs = cfgBool( doc, TidyIndentAttributes );
        wantIt = ( ( !IsWrapInAttrVal(pprint) || indentAttrs ) &&
                   !IsWrapInString(pprint) );
    }
    return wantIt;
}


uint  WrapOff( TidyDocImpl* doc )
{
    uint saveWrap = cfg( doc, TidyWrapLen );
    SetOptionInt( doc, TidyWrapLen, 0xFFFFFFFF );  /* very large number */
    return saveWrap;
}
void  WrapOn( TidyDocImpl* doc, uint saveWrap )
{
    SetOptionInt( doc, TidyWrapLen, saveWrap );
}

uint  WrapOffCond( TidyDocImpl* doc, Bool onoff )
{
    if ( onoff )
        return WrapOff( doc );
    return cfg( doc, TidyWrapLen );
}


static void AddC( TidyPrintImpl* pprint, uint c, uint index)
{
    if ( index + 1 >= pprint->lbufsize )
        expand( pprint, index + 1 );
    pprint->linebuf[index] = c;
}

static uint AddChar( TidyPrintImpl* pprint, uint c )
{
    AddC( pprint, c, pprint->linelen );
    return ++pprint->linelen;
}

static uint AddAsciiString( TidyPrintImpl* pprint, ctmbstr str, uint index )
{
    uint ix, len = tmbstrlen( str );
    if ( index + len >= pprint->lbufsize )
        expand( pprint, index + len );

    for ( ix=0; ix<len; ++ix )
        pprint->linebuf[index + ix] = str[ ix ];
    return index + len;
}

static uint AddString( TidyPrintImpl* pprint, ctmbstr str )
{
   return pprint->linelen = AddAsciiString( pprint, str, pprint->linelen );
}

/* Saves current output point as the wrap point,
** but only if indentation would NOT overflow 
** the current line.  Otherwise keep previous wrap point.
*/
static Bool SetWrap( TidyDocImpl* doc, uint indent )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool wrap = ( indent + pprint->linelen < cfg(doc, TidyWrapLen) );
    if ( wrap )
    {
        if ( pprint->indent[0].spaces < 0 )
            pprint->indent[0].spaces = indent;
        pprint->wraphere = pprint->linelen;
    }
    else if ( pprint->ixInd == 0 )
    {
        /* Save indent 1st time we pass the the wrap line */
        pprint->indent[ 1 ].spaces = indent;
        pprint->ixInd = 1;
    }
    return wrap;
}

static void CarryOver( int* valTo, int* valFrom, uint wrapPoint )
{
  if ( *valFrom > (int) wrapPoint )
  {
    *valTo = *valFrom - wrapPoint;
    *valFrom = -1;
  }
}


static Bool SetWrapAttr( TidyDocImpl* doc,
                         uint indent, int attrStart, int strStart )
{
    TidyPrintImpl* pprint = &doc->pprint;
    TidyIndent *ind = pprint->indent + 0;

    Bool wrap = ( indent + pprint->linelen < cfg(doc, TidyWrapLen) );
    if ( wrap )
    {
        if ( ind[0].spaces < 0 )
            ind[0].spaces = indent;
        pprint->wraphere = pprint->linelen;
    }
    else if ( pprint->ixInd == 0 )
    {
        /* Save indent 1st time we pass the the wrap line */
        pprint->indent[ 1 ].spaces = indent;
        pprint->ixInd = 1;

        /* Carry over string state */
        CarryOver( &ind[1].attrStringStart, &ind[0].attrStringStart, pprint->wraphere );
        CarryOver( &ind[1].attrValStart, &ind[0].attrValStart, pprint->wraphere );
    }
    ind += doc->pprint.ixInd;
    ind->attrValStart = attrStart;
    ind->attrStringStart = strStart;
    return wrap;
}


/* Reset indent state after flushing a new line
*/
static void ResetLine( TidyPrintImpl* pprint )
{
    TidyIndent* ind = pprint->indent + 0;
    if ( pprint->ixInd > 0 )
    {
        ind[0] = ind[1];
        InitIndent( &ind[1] );
    }

    if ( pprint->wraphere > 0 )
    {
        int wrap = (int) pprint->wraphere;
        if ( ind[0].attrStringStart > wrap )
            ind[0].attrStringStart -= wrap;
        if ( ind[0].attrValStart > wrap )
            ind[0].attrValStart -= wrap;
    }
    else
    {
        if ( ind[0].attrStringStart > 0 )
            ind[0].attrStringStart = 0;
        if ( ind[0].attrValStart > 0 )
            ind[0].attrValStart = 0;
    }
    pprint->wraphere = pprint->ixInd = 0;
}

/* Shift text after wrap point to
** beginning of next line.
*/
static void ResetLineAfterWrap( TidyPrintImpl* pprint )
{
    TidyIndent* ind = pprint->indent + 0;
    if ( pprint->linelen > pprint->wraphere )
    {
        uint *p = pprint->linebuf;
        uint *q = p + pprint->wraphere;
        uint *end = p + pprint->linelen;

        if ( ! IsWrapInAttrVal(pprint) )
        {
            while ( q < end && *q == ' ' )
                ++q, ++pprint->wraphere;
        }

        while ( q < end )
            *p++ = *q++;

        pprint->linelen -= pprint->wraphere;
    }
    else
    {
        pprint->linelen = 0;
    }

    ResetLine( pprint );
}

/* Goes ahead with writing current line up to
** previously saved wrap point.  Shifts unwritten
** text in output buffer to beginning of next line.
*/
static void WrapLine( TidyDocImpl* doc )
{
    TidyPrintImpl* pprint = &doc->pprint;
    uint i;

    if ( pprint->wraphere == 0 )
        return;

    if ( WantIndent(doc) )
    {
        uint spaces = GetSpaces( pprint );
        for ( i = 0; i < spaces; ++i )
            WriteChar( ' ', doc->docOut );
    }

    for ( i = 0; i < pprint->wraphere; ++i )
        WriteChar( pprint->linebuf[i], doc->docOut );

    if ( IsWrapInString(pprint) )
        WriteChar( '\\', doc->docOut );

    WriteChar( '\n', doc->docOut );
    ResetLineAfterWrap( pprint );
}

/* Checks current output line length along with current indent.
** If combined they overflow output line length, go ahead
** and flush output up to the current wrap point.
*/
static Bool CheckWrapLine( TidyDocImpl* doc )
{
    TidyPrintImpl* pprint = &doc->pprint;
    if ( GetSpaces(pprint) + pprint->linelen >= cfg(doc, TidyWrapLen) )
    {
        WrapLine( doc );
        return yes;
    }
    return no;
}

static Bool CheckWrapIndent( TidyDocImpl* doc, uint indent )
{
    TidyPrintImpl* pprint = &doc->pprint;
    if ( GetSpaces(pprint) + pprint->linelen >= cfg(doc, TidyWrapLen) )
    {
        WrapLine( doc );
        if ( pprint->indent[ 0 ].spaces < 0 )
            pprint->indent[ 0 ].spaces = indent;
        return yes;
    }
    return no;
}

static void WrapAttrVal( TidyDocImpl* doc )
{
    TidyPrintImpl* pprint = &doc->pprint;
    uint i;

    assert( IsWrapInAttrVal(pprint) );
    if ( WantIndent(doc) )
    {
        uint spaces = GetSpaces( pprint );
        for ( i = 0; i < spaces; ++i )
            WriteChar( ' ', doc->docOut );
    }

    for ( i = 0; i < pprint->wraphere; ++i )
        WriteChar( pprint->linebuf[i], doc->docOut );

    if ( IsWrapInString(pprint) )
        WriteChar( '\\', doc->docOut );
    else
        WriteChar( ' ', doc->docOut );

    WriteChar( '\n', doc->docOut );
    ResetLineAfterWrap( pprint );
}

void PFlushLine( TidyDocImpl* doc, uint indent )
{
    TidyPrintImpl* pprint = &doc->pprint;

    if ( pprint->linelen > 0 )
    {
        uint i;
        Bool indentAttrs = cfgBool( doc, TidyIndentAttributes );

        CheckWrapLine( doc );

        if ( WantIndent(doc) )
        {
            uint spaces = GetSpaces( pprint );
            for ( i = 0; i < spaces; ++i )
                WriteChar( ' ', doc->docOut );
        }

        for ( i = 0; i < pprint->linelen; ++i )
            WriteChar( pprint->linebuf[i], doc->docOut );

        if ( IsInString(pprint) )
            WriteChar( '\\', doc->docOut );
        ResetLine( pprint );
        pprint->linelen = 0;
    }

    WriteChar( '\n', doc->docOut );
    pprint->indent[ 0 ].spaces = indent;
}

void PCondFlushLine( TidyDocImpl* doc, uint indent )
{
    TidyPrintImpl* pprint = &doc->pprint;
    if ( pprint->linelen > 0 )
    {
        uint i;
        Bool indentAttrs = cfgBool( doc, TidyIndentAttributes );

        CheckWrapLine( doc );

        if ( WantIndent(doc) )
        {
            uint spaces = GetSpaces( pprint );
            for ( i = 0; i < spaces; ++i )
                WriteChar(' ', doc->docOut);
        }

        for ( i = 0; i < pprint->linelen; ++i )
            WriteChar( pprint->linebuf[i], doc->docOut );

        if ( IsInString(pprint) )
            WriteChar( '\\', doc->docOut );
        ResetLine( pprint );

        WriteChar( '\n', doc->docOut );
        pprint->indent[ 0 ].spaces = indent;
        pprint->linelen = 0;
    }
}

static void PPrintChar( TidyDocImpl* doc, uint c, uint mode )
{
    tmbchar entity[128];
    ctmbstr p;
    Bool breakable = no;
    TidyPrintImpl* pprint  = &doc->pprint;
    uint outenc = cfg( doc, TidyOutCharEncoding );
    Bool qmark = cfgBool( doc, TidyQuoteMarks );

    if ( c == ' ' && !(mode & (PREFORMATTED | COMMENT | ATTRIBVALUE | CDATA)))
    {
        /* coerce a space character to a non-breaking space */
        if (mode & NOWRAP)
        {
            ctmbstr ent = "&nbsp;";
            /* by default XML doesn't define &nbsp; */
            if ( cfgBool(doc, TidyNumEntities) || cfgBool(doc, TidyXmlTags) )
                ent = "&#160;";
            AddString( pprint, ent );
            return;
        }
        else
            pprint->wraphere = pprint->linelen;
    }

    /* comment characters are passed raw */
    if ( mode & (COMMENT | CDATA) )
    {
        AddChar( pprint, c );
        return;
    }

    /* except in CDATA map < to &lt; etc. */
    if ( !(mode & CDATA) )
    {
        if ( c == '<')
        {
            AddString( pprint, "&lt;" );
            return;
        }
            
        if ( c == '>')
        {
            AddString( pprint, "&gt;" );
            return;
        }

        /*
          naked '&' chars can be left alone or
          quoted as &amp; The latter is required
          for XML where naked '&' are illegal.
        */
        if ( c == '&' && cfgBool(doc, TidyQuoteAmpersand) )
        {
            AddString( pprint, "&amp;" );
            return;
        }

        if ( c == '"' && qmark )
        {
            AddString( pprint, "&quot;" );
            return;
        }

        if ( c == '\'' && qmark )
        {
            AddString( pprint, "&#39;" );
            return;
        }

        if ( c == 160 && outenc != RAW )
        {
            if ( cfgBool(doc, TidyMakeBare) )
                AddChar( pprint, ' ' );
            else if ( cfgBool(doc, TidyQuoteNbsp) )
            {
                if ( cfgBool(doc, TidyNumEntities) ||
                     cfgBool(doc, TidyXmlTags) )
                    AddString( pprint, "&#160;" );
                else
                    AddString( pprint, "&nbsp;" );
            }
            else
                AddChar( pprint, c );
            return;
        }
    }

#if SUPPORT_ASIAN_ENCODINGS

    /* #431953 - start RJ */
    /* Handle encoding-specific issues */
    switch ( outenc )
    {
    case UTF8:
    /* Chinese doesn't have spaces, so it needs other kinds of breaks */
    /* This will also help documents using nice Unicode punctuation */
    /* But we leave the ASCII range punctuation untouched */

    /* Break after any punctuation or spaces characters */
    if ( c >= 0x2000 && !(mode & PREFORMATTED) )
    {
        if(((c >= 0x2000) && ( c<= 0x2006 ))
        || ((c >= 0x2008) && ( c<= 0x2010 ))
        || ((c >= 0x2011) && ( c<= 0x2046 ))
        || ((c >= 0x207D) && ( c<= 0x207E )) 
        || ((c >= 0x208D) && ( c<= 0x208E )) 
        || ((c >= 0x2329) && ( c<= 0x232A )) 
        || ((c >= 0x3001) && ( c<= 0x3003 )) 
        || ((c >= 0x3008) && ( c<= 0x3011 )) 
        || ((c >= 0x3014) && ( c<= 0x301F )) 
        || ((c >= 0xFD3E) && ( c<= 0xFD3F )) 
        || ((c >= 0xFE30) && ( c<= 0xFE44 )) 
        || ((c >= 0xFE49) && ( c<= 0xFE52 )) 
        || ((c >= 0xFE54) && ( c<= 0xFE61 )) 
        || ((c >= 0xFE6A) && ( c<= 0xFE6B )) 
        || ((c >= 0xFF01) && ( c<= 0xFF03 )) 
        || ((c >= 0xFF05) && ( c<= 0xFF0A )) 
        || ((c >= 0xFF0C) && ( c<= 0xFF0F )) 
        || ((c >= 0xFF1A) && ( c<= 0xFF1B )) 
        || ((c >= 0xFF1F) && ( c<= 0xFF20 )) 
        || ((c >= 0xFF3B) && ( c<= 0xFF3D )) 
        || ((c >= 0xFF61) && ( c<= 0xFF65 )))
        {
            /* 2, because AddChar is not till later */
            pprint->wraphere = pprint->linelen + 2;
            breakable = yes;
        } 
        else switch (c)
        {
            case 0xFE63:
            case 0xFE68:
            case 0x3030:
            case 0x30FB:
            case 0xFF3F:
            case 0xFF5B:
            case 0xFF5D:
                pprint->wraphere = pprint->linelen + 2;
                breakable = yes;
        }
        /* but break before a left punctuation */
        if (breakable == yes)
        { 
            if (((c >= 0x201A) && (c <= 0x201C)) ||
                ((c >= 0x201E) && (c <= 0x201F)))
            {
                pprint->wraphere--;
            }
            else switch (c)
            {
            case 0x2018:
            case 0x2039:
            case 0x2045:
            case 0x207D:
            case 0x208D:
            case 0x2329:
            case 0x3008:
            case 0x300A:
            case 0x300C:
            case 0x300E:
            case 0x3010:
            case 0x3014:
            case 0x3016:
            case 0x3018:
            case 0x301A:
            case 0x301D:
            case 0xFD3E:
            case 0xFE35:
            case 0xFE37:
            case 0xFE39:
            case 0xFE3B:
            case 0xFE3D:
            case 0xFE3F:
            case 0xFE41:
            case 0xFE43:
            case 0xFE59:
            case 0xFE5B:
            case 0xFE5D:
            case 0xFF08:
            case 0xFF3B:
            case 0xFF5B:
            case 0xFF62:
                pprint->wraphere--; 
            }
        }
    }
    break;

    case BIG5:
        /* Allow linebreak at Chinese punctuation characters */
        /* There are not many spaces in Chinese */
        AddChar( pprint, c );
        if ( (c & 0xFF00) == 0xA100 && !(mode & PREFORMATTED) )
        {
            pprint->wraphere = pprint->linelen;
            /* opening brackets have odd codes: break before them */
            if ( c > 0x5C && c < 0xAD && (c & 1) == 1 ) 
                pprint->wraphere--; 
        }
        return;

    case SHIFTJIS:
    case ISO2022: /* ISO 2022 characters are passed raw */
    case RAW:
        AddChar( pprint, c );
        return;
    }
    /* #431953 - end RJ */

#else

    /* otherwise ISO 2022 characters are passed raw */
    if ( outenc == ISO2022 || outenc == RAW )
    {
        AddChar( pprint, c );
        return;
    }

#endif

    /* if preformatted text, map &nbsp; to space */
    if ( c == 160 && (mode & PREFORMATTED) )
    {
        AddChar( pprint, ' ' ); 
        return;
    }

    /*
     Filters from Word and PowerPoint often use smart
     quotes resulting in character codes between 128
     and 159. Unfortunately, the corresponding HTML 4.0
     entities for these are not widely supported. The
     following converts dashes and quotation marks to
     the nearest ASCII equivalent. My thanks to
     Andrzej Novosiolov for his help with this code.
    */

    if ( (cfgBool(doc, TidyMakeClean) && cfgBool(doc, TidyAsciiChars))
         || cfgBool(doc, TidyMakeBare) )
    {
        if (c >= 0x2013 && c <= 0x201E)
        {
            switch (c) {
              case 0x2013: /* en dash */
              case 0x2014: /* em dash */
                c = '-';
                break;
              case 0x2018: /* left single  quotation mark */
              case 0x2019: /* right single quotation mark */
              case 0x201A: /* single low-9 quotation mark */
                c = '\'';
                break;
              case 0x201C: /* left double  quotation mark */
              case 0x201D: /* right double quotation mark */
              case 0x201E: /* double low-9 quotation mark */
                c = '"';
                break;
              }
        }
    }

    /* don't map latin-1 chars to entities */
    if ( outenc == LATIN1 )
    {
        if (c > 255)  /* multi byte chars */
        {
            uint vers = HTMLVersion( doc );
            if ( !cfgBool(doc, TidyNumEntities) && (p = EntityName(c, vers)) )
                sprintf(entity, "&%s;", p);
            else
                sprintf(entity, "&#%u;", c);

            AddString( pprint, entity );
            return;
        }

        if (c > 126 && c < 160)
        {
            sprintf(entity, "&#%d;", c);
            AddString( pprint, entity );
            return;
        }

        AddChar( pprint, c );
        return;
    }

    /* don't map UTF-8 chars to entities */
    if ( outenc == UTF8 )
    {
        AddChar( pprint, c );
        return;
    }

#if SUPPORT_UTF16_ENCODINGS
    /* don't map UTF-16 chars to entities */
    if ( outenc == UTF16 || outenc == UTF16LE || outenc == UTF16BE )
    {
        AddChar( pprint, c );
        return;
    }
#endif

    /* use numeric entities only  for XML */
    if ( cfgBool(doc, TidyXmlTags) )
    {
        /* if ASCII use numeric entities for chars > 127 */
        if ( c > 127 && outenc == ASCII )
        {
            sprintf(entity, "&#%u;", c);
            AddString( pprint, entity );
            return;
        }

        /* otherwise output char raw */
        AddChar( pprint, c );
        return;
    }

    /* default treatment for ASCII */
    if ( outenc == ASCII && (c > 126 || (c < ' ' && c != '\t')) )
    {
        uint vers = HTMLVersion( doc );
        if (!cfgBool(doc, TidyNumEntities) && (p = EntityName(c, vers)) )
            sprintf(entity, "&%s;", p);
        else
            sprintf(entity, "&#%u;", c);

        AddString( pprint, entity );
        return;
    }

    AddChar( pprint, c );
}

static uint IncrWS( uint start, uint end, uint indent, int ixWS )
{
  if ( ixWS > 0 )
  {
    uint st = start + MIN( (uint)ixWS, indent );
    start = MIN( st, end );
  }
  return start;
}
/* 
  The line buffer is uint not char so we can
  hold Unicode values unencoded. The translation
  to UTF-8 is deferred to the WriteChar() routine called
  to flush the line buffer.
*/
static void PPrintText( TidyDocImpl* doc, uint mode, uint indent,
                        Node* node  )
{
    uint start = node->start;
    uint end = node->end;
    uint ix, c, skipped = 0;
    int  ixNL = TextEndsWithNewline( doc->lexer, node, mode );
    int  ixWS = TextStartsWithWhitespace( doc->lexer, node, start, mode );
    if ( ixNL > 0 )
      end -= ixNL;
    start = IncrWS( start, end, indent, ixWS );

    for ( ix = start; ix < end; ++ix )
    {
        CheckWrapIndent( doc, indent );
        /*
        if ( CheckWrapIndent(doc, indent) )
        {
            ixWS = TextStartsWithWhitespace( doc->lexer, node, ix );
            ix = IncrWS( ix, end, indent, ixWS );
        }
        */
        c = (byte) doc->lexer->lexbuf[ix];

        /* look for UTF-8 multibyte character */
        if ( c > 0x7F )
             ix += GetUTF8( doc->lexer->lexbuf + ix, &c );

        if ( c == '\n' )
        {
            PFlushLine( doc, indent );
            ixWS = TextStartsWithWhitespace( doc->lexer, node, ix+1, mode );
            ix = IncrWS( ix, end, indent, ixWS );
        }
        else
        {
            PPrintChar( doc, c, mode );
        }
    }
}

static void PPrintString( TidyDocImpl* doc, uint indent, ctmbstr str )
{
    while ( *str != '\0' )
        AddChar( &doc->pprint, *str++ );
}


static void PPrintAttrValue( TidyDocImpl* doc, uint indent,
                             tmbstr value, uint delim, Bool wrappable )
{
    TidyPrintImpl* pprint = &doc->pprint;

    int mode = PREFORMATTED | ATTRIBVALUE;
    if ( wrappable )
        mode = NORMAL | ATTRIBVALUE;

    /* look for ASP, Tango or PHP instructions for computed attribute value */
    if ( value && value[0] == '<' )
    {
        if ( value[1] == '%' || value[1] == '@'||
             tmbstrncmp(value, "<?php", 5) == 0 )
            mode |= CDATA;
    }

    if ( delim == 0 )
        delim = '"';

    AddChar( pprint, '=' );

    /* don't wrap after "=" for xml documents */
    if ( !cfgBool(doc, TidyXmlOut) )
    {
        SetWrap( doc, indent );
        CheckWrapIndent( doc, indent );
        /*
        if ( !SetWrap(doc, indent) )
            PCondFlushLine( doc, indent );
        */
    }

    AddChar( pprint, delim );

    if ( value )
    {
        uint wraplen = cfg( doc, TidyWrapLen );
        int attrStart = SetInAttrVal( pprint );
        int strStart = ClearInString( pprint );

        while (*value != '\0')
        {
            uint c = *value;

            if ( wrappable && c == ' ' )
                SetWrapAttr( doc, indent, attrStart, strStart );

            if ( wrappable && pprint->wraphere > 0 &&
                 GetSpaces(pprint) + pprint->linelen >= wraplen )
                WrapAttrVal( doc );

            if ( c == delim )
            {
                ctmbstr entity = (c == '"' ? "&quot;" : "&#39;");
                AddString( pprint, entity );
                ++value;
                continue;
            }
            else if (c == '"')
            {
                if ( cfgBool(doc, TidyQuoteMarks) )
                    AddString( pprint, "&quot;" );
                else
                    AddChar( pprint, c );

                if ( delim == '\'' )
                    strStart = ToggleInString( pprint );

                ++value;
                continue;
            }
            else if ( c == '\'' )
            {
                if ( cfgBool(doc, TidyQuoteMarks) )
                    AddString( pprint, "&#39;" );
                else
                    AddChar( pprint, c );

                if ( delim == '"' )
                    strStart = ToggleInString( pprint );

                ++value;
                continue;
            }

            /* look for UTF-8 multibyte character */
            if ( c > 0x7F )
                 value += GetUTF8( value, &c );
            ++value;

            if ( c == '\n' )
            {
                /* No indent inside Javascript literals */
                PFlushLine( doc, (strStart < 0 ? indent : 0) );
                continue;
            }
            PPrintChar( doc, c, mode );
        }
        ClearInAttrVal( pprint );
        ClearInString( pprint );
    }
    AddChar( pprint, delim );
}

static uint AttrIndent( TidyDocImpl* doc, Node* node, AttVal* attr )
{
  uint spaces = cfg( doc, TidyIndentSpaces );
  uint xtra = 2;  /* 1 for the '<', another for the ' ' */
  if ( node->element == NULL )
    return spaces;

  if ( !nodeHasCM(node, CM_INLINE) ||
       !ShouldIndent(doc, node->parent ? node->parent: node) )
    return xtra + tmbstrlen( node->element );

  if ( node = FindContainer(node) )
    return xtra + tmbstrlen( node->element );
  return spaces;
}

static Bool AttrNoIndentFirst( TidyDocImpl* doc, Node* node, AttVal* attr )
{
  return ( attr==node->attributes );
  
  /*&& 
           ( InsideHead(doc, node) ||
             !nodeHasCM(node, CM_INLINE) ) );
             */
}

static void PPrintAttribute( TidyDocImpl* doc, uint indent,
                             Node *node, AttVal *attr )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool xmlOut    = cfgBool( doc, TidyXmlOut );
    Bool xhtmlOut  = cfgBool( doc, TidyXhtmlOut );
    Bool wrapAttrs = cfgBool( doc, TidyWrapAttVals );
    Bool ucAttrs   = cfgBool( doc, TidyUpperCaseAttrs );
    Bool indAttrs  = cfgBool( doc, TidyIndentAttributes );
    uint xtra      = AttrIndent( doc, node, attr );
    Bool first     = AttrNoIndentFirst( doc, node, attr );
    ctmbstr name   = attr->attribute;
    Bool wrappable = no;

    if ( indAttrs )
    {
        if ( nodeIsElement(node) && !first )
        {
            indent += xtra;
            PCondFlushLine( doc, indent );
        }
        else
          indAttrs = no;
    }

    CheckWrapIndent( doc, indent );

    if ( !xmlOut && !xhtmlOut && attr->dict )
    {
        if ( IsScript(doc, name) )
            wrappable = cfgBool( doc, TidyWrapScriptlets );
        else if ( !attr->dict->nowrap && wrapAttrs )
            wrappable = yes;
    }

    if ( !first && !SetWrap(doc, indent) )
    {
        PFlushLine( doc, indent+xtra );  /* Put it on next line */
    }
    else if ( pprint->linelen > 0 )
    {
        AddChar( pprint, ' ' );
    }

    /* Attribute name */
    while ( *name )
    {
        AddChar( pprint, FoldCase(doc, *name++, ucAttrs) );
    }

    /* If not indenting attributes, bump up indent for 
    ** value after putting out name.
    */
    if ( !indAttrs )
        indent += xtra;

    CheckWrapIndent( doc, indent );
 
    if ( attr->value == null )
    {
        Bool isB = IsBoolAttribute( attr );
        if ( xmlOut )
            PPrintAttrValue( doc, indent, isB ? attr->attribute : "",
                             attr->delim, no );

        else if ( !isB && !IsNewNode(node) )
            PPrintAttrValue( doc, indent, "", attr->delim, yes );

        else 
            SetWrap( doc, indent );
    }
    else
        PPrintAttrValue( doc, indent, attr->value, attr->delim, wrappable );
}

static void PPrintAttrs( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    AttVal* av;

    /* add xml:space attribute to pre and other elements */
    if ( cfgBool(doc, TidyXmlOut) && cfgBool(doc, TidyXmlSpace) &&
         !GetAttrByName(node, "xml:space") &&
         XMLPreserveWhiteSpace(doc, node) )
    {
        AddAttribute( doc, node, "xml:space", "preserve" );
    }

    for ( av = node->attributes; av; av = av->next )
    {
        if ( av->attribute != null )
        {
            const Attribute *dict = av->dict;
            if ( !cfgBool(doc, TidyDropPropAttrs) ||
                 ( dict != null && !(dict->versions & VERS_PROPRIETARY) ) )
                PPrintAttribute( doc, indent, node, av );
        }
        else if ( av->asp != null )
        {
            AddChar( pprint, ' ' );
            PPrintAsp( doc, indent, av->asp );
        }
        else if ( av->php != null )
        {
            AddChar( pprint, ' ' );
            PPrintPhp( doc, indent, av->php );
        }
    }
}

/*
 Line can be wrapped immediately after inline start tag provided
 if follows a text node ending in a space, or it parent is an
 inline element that that rule applies to. This behaviour was
 reverse engineered from Netscape 3.0
*/
static Bool AfterSpace(Lexer *lexer, Node *node)
{
    Node *prev;
    uint c;

    if ( !nodeCMIsInline(node) )
        return yes;

    prev = node->prev;
    if (prev)
    {
        if (prev->type == TextNode && prev->end > prev->start)
        {
            c = lexer->lexbuf[ prev->end - 1 ];

            if ( c == 160 || c == ' ' || c == '\n' )
                return yes;
        }

        return no;
    }

    return AfterSpace(lexer, node->parent);
}

static void PPrintTag( TidyDocImpl* doc,
                       uint mode, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    char c, *p;
    Bool uc = cfgBool( doc, TidyUpperCaseTags );
    Bool xhtmlOut = cfgBool( doc, TidyXhtmlOut );
    Bool xmlOut = cfgBool( doc, TidyXmlOut );

    AddChar( pprint, '<' );

    if ( node->type == EndTag )
        AddChar( pprint, '/' );

    for ( p = node->element; (c = *p); ++p )
        AddChar( pprint, FoldCase(doc, c, uc) );

    PPrintAttrs( doc, indent, node );

    if ( (xmlOut || xhtmlOut) &&
         (node->type == StartEndTag || nodeCMIsEmpty(node)) )
    {
        AddChar( pprint, ' ' );   /* Space is NS compatibility hack <br /> */
        AddChar( pprint, '/' );   /* Required end tag marker */
    }

    AddChar( pprint, '>' );

    if ( (node->type != StartEndTag || xhtmlOut) && !(mode & PREFORMATTED) )
    {
        uint wraplen = cfg( doc, TidyWrapLen );
        CheckWrapIndent( doc, indent );

        if ( indent + pprint->linelen < wraplen )
        {
            /*
             wrap after start tag if is <br/> or if it's not
             inline or it is an empty tag followed by </a>
            */
            if ( AfterSpace(doc->lexer, node) )
            {
                if ( !(mode & NOWRAP) &&
                     ( !nodeCMIsInline(node) ||
                       nodeIsBR(node) ||
                       ( nodeCMIsEmpty(node) && 
                         node->next == null &&
                         nodeIsA(node->parent)
                       )
                     )
                   )
                {
                    pprint->wraphere = pprint->linelen;
                }
            }
        }
        else
            PCondFlushLine( doc, indent );
    }
}

static void PPrintEndTag( TidyDocImpl* doc, uint mode, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool uc = cfgBool( doc, TidyUpperCaseTags );
    ctmbstr p;

   /*
     Netscape ignores SGML standard by not ignoring a
     line break before </A> or </U> etc. To avoid rendering 
     this as an underlined space, I disable line wrapping
     before inline end tags by the #if 0 ... #endif
   */
#if 0
    if ( !(mode & NOWRAP) )
        SetWrap( doc, indent );
#endif

    AddString( pprint, "</" );
    for ( p = node->element; *p; ++p )
        AddChar( pprint, FoldCase(doc, *p, uc) );
    AddChar( pprint, '>' );
}

static void PPrintComment( TidyDocImpl* doc, uint indent, Node* node )
{
    TidyPrintImpl* pprint = &doc->pprint;

    if ( cfgBool(doc, TidyHideComments) )
        return;

    SetWrap( doc, indent );
    AddString( pprint, "<!--" );

#if 0
    SetWrap( doc, indent );
#endif

    PPrintText( doc, COMMENT, indent, node );

#if 0
    SetWrap( doc, indent );
    AddString( pprint, "--" );
#endif

    AddChar( pprint, '>' );
    if ( node->linebreak )
        PFlushLine( doc, indent );
}

static void PPrintDocType( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    uint i, c, mode = 0, xtra = 10;
    Bool q = cfgBool( doc, TidyQuoteMarks );
    SetOptionBool( doc, TidyQuoteMarks, no );

    SetWrap( doc, indent );
    PCondFlushLine( doc, indent );

    AddString( pprint, "<!DOCTYPE " );
    SetWrap( doc, indent );

    for (i = node->start; i < node->end; ++i)
    {
        CheckWrapIndent( doc, indent+xtra );

        c = doc->lexer->lexbuf[i];

        /* inDTDSubset? */
        if ( mode & CDATA ) {
            if ( c == ']' )
                mode &= ~CDATA;
        }
        else if ( c == '[' )
            mode |= CDATA;

        /* look for UTF-8 multibyte character */
        if (c > 0x7F)
             i += GetUTF8( doc->lexer->lexbuf + i, &c );

        if ( c == '\n' )
        {
            PFlushLine( doc, indent );
            continue;
        }

        PPrintChar( doc, c, mode );
    }

    SetWrap( doc, 0 );
    AddChar( pprint, '>' );

    SetOptionBool( doc, TidyQuoteMarks, q );
    PCondFlushLine( doc, indent );
}

static void PPrintPI( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    SetWrap( doc, indent );

    AddString( pprint, "<?" );

    /* set CDATA to pass < and > unescaped */
    PPrintText( doc, CDATA, indent, node );

    if ( node->end <= 0 || doc->lexer->lexbuf[node->end - 1] != '?' )
        AddChar( pprint, '?' );

    AddChar( pprint, '>' );
    PCondFlushLine( doc, indent );
}

static void PPrintXmlDecl( TidyDocImpl* doc, uint indent, Node *node )
{
    AttVal* att;
    uint saveWrap;
    TidyPrintImpl* pprint = &doc->pprint;
    SetWrap( doc, indent );
    saveWrap = WrapOff( doc );

    AddString( pprint, "<?xml" );

    /* Force order of XML declaration attributes */
    /* PPrintAttrs( doc, indent, node ); */
    if ( att = AttrGetById(node, TidyAttr_VERSION) )
      PPrintAttribute( doc, indent, node, att );
    if ( att = AttrGetById(node, TidyAttr_ENCODING) )
      PPrintAttribute( doc, indent, node, att );
    if ( att = GetAttrByName(node, "standalone") )
      PPrintAttribute( doc, indent, node, att );

    if ( node->end <= 0 || doc->lexer->lexbuf[node->end - 1] != '?' )
        AddChar( pprint, '?' );
    AddChar( pprint, '>' );
    WrapOn( doc, saveWrap );
    PFlushLine( doc, indent );
}

/* note ASP and JSTE share <% ... %> syntax */
static void PPrintAsp( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool wrapAsp  = cfgBool( doc, TidyWrapAsp );
    Bool wrapJste = cfgBool( doc, TidyWrapJste );
    uint saveWrap = WrapOffCond( doc, !wrapAsp || !wrapJste );

#if 0
    SetWrap( doc, indent );
#endif
    AddString( pprint, "<%" );
    PPrintText( doc, (wrapAsp ? CDATA : COMMENT), indent, node );
    AddString( pprint, "%>" );

    /* PCondFlushLine( doc, indent ); */
    WrapOn( doc, saveWrap );
}

/* JSTE also supports <# ... #> syntax */
static void PPrintJste( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool wrapAsp = cfgBool( doc, TidyWrapAsp );
    Bool wrapJste = cfgBool( doc, TidyWrapJste );
    uint saveWrap = WrapOffCond( doc, !wrapAsp  );

    AddString( pprint, "<#" );
    PPrintText( doc, (cfgBool(doc, TidyWrapJste) ? CDATA : COMMENT),
                indent, node );
    AddString( pprint, "#>" );

    /* PCondFlushLine( doc, indent ); */
    WrapOn( doc, saveWrap );
}

/* PHP is based on XML processing instructions */
static void PPrintPhp( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool wrapPhp = cfgBool( doc, TidyWrapPhp );
    uint saveWrap = WrapOffCond( doc, !wrapPhp  );
#if 0
    SetWrap( doc, indent );
#endif

    AddString( pprint, "<?" );
    PPrintText( doc, (wrapPhp ? CDATA : COMMENT),
                indent, node );
    AddString( pprint, "?>" );

    /* PCondFlushLine( doc, indent ); */
    WrapOn( doc, saveWrap );
}

static void PPrintCDATA( TidyDocImpl* doc, uint indent, Node *node )
{
    uint saveWrap;
    TidyPrintImpl* pprint = &doc->pprint;
    Bool indentCData = cfgBool( doc, TidyIndentCdata );
    if ( !indentCData )
        indent = 0;

    PCondFlushLine( doc, indent );
    saveWrap = WrapOff( doc );        /* disable wrapping */

    AddString( pprint, "<![CDATA[" );
    PPrintText( doc, COMMENT, indent, node );
    AddString( pprint, "]]>" );

    PCondFlushLine( doc, indent );
    WrapOn( doc, saveWrap );          /* restore wrapping */
}

static void PPrintSection( TidyDocImpl* doc, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Bool wrapSect = cfgBool( doc, TidyWrapSection );
    uint saveWrap = WrapOffCond( doc, !wrapSect  );
#if 0
    SetWrap( doc, indent );
#endif

    AddString( pprint, "<![" );
    PPrintText( doc, (wrapSect ? CDATA : COMMENT),
                indent, node );
    AddString( pprint, "]>" );

    /* PCondFlushLine( doc, indent ); */
    WrapOn( doc, saveWrap );
}


#if 0
/*
** Print script and style elements. For XHTML, wrap the content as follows:
**
**     JavaScript:
**         //<![CDATA[
**             content
**         //]]>
**     VBScript:
**         '<![CDATA[
**             content
**         ']]>
**     CSS:
**         / *<![CDATA[* /     Extra spaces to keep compiler happy
**             content
**         / *]]>* /
**     other:
**         <![CDATA[
**             content
**         ]]>
*/
#endif

static ctmbstr CDATA_START           = "<![CDATA[";
static ctmbstr CDATA_END             = "]]>";
static ctmbstr JS_COMMENT_START      = "//";
static ctmbstr JS_COMMENT_END        = "";
static ctmbstr VB_COMMENT_START      = "\'";
static ctmbstr VB_COMMENT_END        = "";
static ctmbstr CSS_COMMENT_START     = "/*";
static ctmbstr CSS_COMMENT_END       = "*/";
static ctmbstr DEFAULT_COMMENT_START = "";
static ctmbstr DEFAULT_COMMENT_END   = "";

static Bool InsideHead( TidyDocImpl* doc, Node *node )
{
  if ( nodeIsHEAD(node) )
    return yes;

  if ( node->parent != null )
    return InsideHead( doc, node->parent );

  return no;
}

/* Is text node and already ends w/ a newline?
 
   Used to pretty print CDATA/PRE text content.
   If it already ends on a newline, it is not
   necessary to print another before printing end tag.
*/
static int TextEndsWithNewline(Lexer *lexer, Node *node, uint mode )
{
    if ( (mode & CDATA|COMMENT) && node->type == TextNode && node->end > node->start )
    {
        uint ch, ix = node->end - 1;
        /* Skip non-newline whitespace. */
        while ( ix >= node->start && (ch = (lexer->lexbuf[ix] & 0xff))
                && ( ch == ' ' || ch == '\t' || ch == '\r' ) )
            --ix;

        if ( lexer->lexbuf[ ix ] == '\n' )
          return node->end - ix - 1; /* #543262 tidy eats all memory */
    }
    return -1;
}

static int TextStartsWithWhitespace( Lexer *lexer, Node *node, uint start, uint mode )
{
    assert( node != null );
    if ( (mode & (CDATA|COMMENT)) && node->type == TextNode && node->end > node->start && start >= node->start )
    {
        uint ch, ix = start;
        /* Skip whitespace. */
        while ( ix < node->end && (ch = (lexer->lexbuf[ix] & 0xff))
                && ( ch==' ' || ch=='\t' || ch=='\r' ) )
            ++ix;

        if ( ix > start )
          return ix - start;
    }
    return -1;
}

static Bool HasCDATA( Lexer* lexer, Node* node )
{
    /* Scan forward through the textarray. Since the characters we're
    ** looking for are < 0x7f, we don't have to do any UTF-8 decoding.
    */
    ctmbstr start = lexer->lexbuf + node->start;
    int len = node->end - node->start + 1;

    if ( node->type != TextNode )
        return no;

    return ( null != tmbsubstrn( start, len, CDATA_START ));
}


#if 0 
static Bool StartsWithCDATA( Lexer* lexer, Node* node, char* commentStart )
{
    /* Scan forward through the textarray. Since the characters we're
    ** looking for are < 0x7f, we don't have to do any UTF-8 decoding.
    */
    int i = node->start, j, end = node->end;

    if ( node->type != TextNode )
        return no;

    /* Skip whitespace. */
    while ( i < end && lexer->lexbuf[i] <= ' ' )
        ++i;

    /* Check for starting comment delimiter. */
    for ( j = 0; j < mbstrlen(commentStart); ++j )
    {
        if ( i >= end || lexer->lexbuf[i] != commentStart[j] )
            return no;
        ++i;
    }

    /* Skip whitespace. */
    while ( i < end && lexer->lexbuf[i] <= ' ' )
        ++i;

    /* Check for "<![CDATA[". */
    for ( j = 0; j < mbstrlen(CDATA_START); ++j )
    {
        if (i >= end || lexer->lexbuf[i] != CDATA_START[j])
            return no;
        ++i;
    }

    return yes;
}


static Bool EndsWithCDATA( Lexer* lexer, Node* node, 
                           char* commentStart, char* commentEnd )
{
    /* Scan backward through the buff. Since the characters we're
    ** looking for are < 0x7f, we don't have do any UTF-8 decoding. Note
    ** that this is true even though we are scanning backwards because every
    ** byte of a UTF-8 multibyte character is >= 0x80.
    */

    int i = node->end - 1, j, start = node->start;

    if ( node->type != TextNode )
        return no;

    /* Skip whitespace. */
    while ( i >= start && (lexer->lexbuf[i] & 0xff) <= ' ' )
        --i;

    /* Check for ending comment delimiter. */
    for ( j = mbstrlen(commentEnd) - 1; j >= 0; --j )
    {
        if (i < start || lexer->lexbuf[i] != commentEnd[j])
            return no;
        --i;
    }

    /* Skip whitespace. */
    while (i >= start && (lexer->lexbuf[i] & 0xff) <= ' ')
        --i;

    /* Check for "]]>". */
    for (j = mbstrlen(CDATA_END) - 1; j >= 0; j--)
    {
        if (i < start || lexer->lexbuf[i] != CDATA_END[j])
            return no;
        --i;
    }

    /* Skip whitespace. */
    while (i >= start && lexer->lexbuf[i] <= ' ')
        --i;

    /* Check for starting comment delimiter. */
    for ( j = mbstrlen(commentStart) - 1; j >= 0; --j )
    {
        if ( i < start || lexer->lexbuf[i] != commentStart[j] )
            return no;
        --i;
    }

    return yes;
}
#endif /* 0 */

void PPrintScriptStyle( TidyDocImpl* doc, uint mode, uint indent, Node *node )
{
    TidyPrintImpl* pprint = &doc->pprint;
    Node*   content;
    ctmbstr commentStart = DEFAULT_COMMENT_START;
    ctmbstr commentEnd = DEFAULT_COMMENT_END;
    Bool    hasCData = no;
    int     contentIndent = -1;
    Bool    xhtmlOut = cfgBool( doc, TidyXhtmlOut );

    if ( InsideHead(doc, node) )
      PFlushLine( doc, indent );

    PPrintTag( doc, mode, indent, node );
    PFlushLine( doc, indent );

    if ( xhtmlOut && node->content != null )
    {
        AttVal* type = attrGetTYPE( node );
        if ( type != null )
        {
            if ( tmbstrcasecmp(type->value, "text/javascript") == 0 )
            {
                commentStart = JS_COMMENT_START;
                commentEnd = JS_COMMENT_END;
            }
            else if ( tmbstrcasecmp(type->value, "text/css") == 0 )
            {
                commentStart = CSS_COMMENT_START;
                commentEnd = CSS_COMMENT_END;
            }
            else if ( tmbstrcasecmp(type->value, "text/vbscript") == 0 )
            {
                commentStart = VB_COMMENT_START;
                commentEnd = VB_COMMENT_END;
            }
        }

        hasCData = HasCDATA( doc->lexer, node->content );
        if ( ! hasCData )
        {
            uint saveWrap = WrapOff( doc );

            AddString( pprint, commentStart );
            AddString( pprint, CDATA_START );
            AddString( pprint, commentEnd );
            PCondFlushLine( doc, indent );

            WrapOn( doc, saveWrap );
        }
    }

    for ( content = node->content;
          content != null;
          content = content->next )
    {
        PPrintTree( doc, (mode | PREFORMATTED | NOWRAP |CDATA), 
                    indent, content );

        if ( content == node->last )
            contentIndent = TextEndsWithNewline( doc->lexer, content, CDATA );
    }

    if ( contentIndent < 0 )
    {
        PCondFlushLine( doc, indent );
        contentIndent = 0;
    }

    if ( xhtmlOut && node->content != null )
    {
        if ( ! hasCData )
        {
            uint saveWrap = WrapOff( doc );

            AddString( pprint, commentStart );
            AddString( pprint, CDATA_END );
            AddString( pprint, commentEnd );

            WrapOn( doc, saveWrap );
            PCondFlushLine( doc, indent );
        }
    }

    if ( node->content && pprint->indent[ 0 ].spaces != (int)indent )
    {
        pprint->indent[ 0 ].spaces = indent;
    }
    PPrintEndTag( doc, mode, indent, node );
    if ( !cfg(doc, TidyIndentContent) && node->next != null &&
         !( nodeHasCM(node, CM_INLINE) || nodeIsText(node) ) )
        PFlushLine( doc, indent );
}



static Bool ShouldIndent( TidyDocImpl* doc, Node *node )
{
    uint indentContent = cfg( doc, TidyIndentContent );
    if ( indentContent == no )
        return no;

    if ( nodeIsTEXTAREA(node) )
        return no;

    if ( indentContent == TidyAutoState )
    {
        if ( node->content && nodeHasCM(node, CM_NO_INDENT) )
        {
            for ( node = node->content; node; node = node->next )
                if ( nodeHasCM(node, CM_BLOCK) )
                    return yes;
            return no;
        }

        if ( nodeHasCM(node, CM_HEADING) )
            return no;

        if ( nodeIsHTML(node) )
            return no;

        if ( nodeIsP(node) )
            return no;

        if ( nodeIsTITLE(node) )
            return no;
    }

    if ( nodeHasCM(node, CM_FIELD | CM_OBJECT) )
        return yes;

    if ( nodeIsMAP(node) )
        return yes;

    return ( !nodeHasCM( node, CM_INLINE ) && node->content );
}

/*
 Feature request #434940 - fix by Dave Raggett/Ignacio Vazquez-Abrams 21 Jun 01
 print just the content of the body element.
 useful when you want to reuse material from
 other documents.

 -- Sebastiano Vigna <vigna@dsi.unimi.it>
*/
void PrintBody( TidyDocImpl* doc )
{
    Node *node = FindBody( doc );

    if ( node )
    {
        for ( node = node->content; node != null; node = node->next )
            PPrintTree( doc, 0, 0, node );
    }
}

void PPrintTree( TidyDocImpl* doc, uint mode, uint indent, Node *node )
{
    Node *content, *last;
    uint spaces = cfg( doc, TidyIndentSpaces );
    Bool xhtml = cfgBool( doc, TidyXhtmlOut );

    if ( node == null )
        return;

    if ( node->type == TextNode ||
         (node->type == CDATATag && cfgBool(doc, TidyEscapeCdata)) )
    {
        PPrintText( doc, mode, indent, node );
    }
    else if ( node->type == CommentTag )
    {
        PPrintComment( doc, indent, node );
    }
    else if ( node->type == RootNode )
    {
        for ( content = node->content; content; content = content->next )
           PPrintTree( doc, mode, indent, content );
    }
    else if ( node->type == DocTypeTag )
        PPrintDocType( doc, indent, node );
    else if ( node->type == ProcInsTag)
        PPrintPI( doc, indent, node );
    else if ( node->type == XmlDecl)
        PPrintXmlDecl( doc, indent, node );
    else if ( node->type == CDATATag)
        PPrintCDATA( doc, indent, node );
    else if ( node->type == SectionTag)
        PPrintSection( doc, indent, node );
    else if ( node->type == AspTag)
        PPrintAsp( doc, indent, node );
    else if ( node->type == JsteTag)
        PPrintJste( doc, indent, node );
    else if ( node->type == PhpTag)
        PPrintPhp( doc, indent, node );
    else if ( nodeCMIsEmpty(node) ||
              (node->type == StartEndTag && !xhtml) )
    {
        if ( ! nodeHasCM(node, CM_INLINE) )
            PCondFlushLine( doc, indent );

        if ( nodeIsBR(node) && node->prev &&
             !(nodeIsBR(node->prev) || (mode & PREFORMATTED)) &&
             cfgBool(doc, TidyBreakBeforeBR) )
            PFlushLine( doc, indent );

        if ( cfgBool(doc, TidyMakeClean) && nodeIsWBR(node) )
            PPrintString( doc, indent, " " );
        else
            PPrintTag( doc, mode, indent, node );

        if ( node->next )
        {
          if ( nodeIsPARAM(node) || nodeIsAREA(node) )
              PCondFlushLine( doc, indent );
          else if ( (nodeIsBR(node) && !(mode & PREFORMATTED)) || 
                    nodeIsHR(node) )
              PFlushLine( doc, indent );
        }
    }
    else /* some kind of container element */
    {
        if ( node->type == StartEndTag )
            node->type = StartTag;

        if ( node->tag && 
             (node->tag->parser == ParsePre || nodeIsTEXTAREA(node)) )
        {
            uint indprev = indent;
            PCondFlushLine( doc, indent );

            PCondFlushLine( doc, indent );
            PPrintTag( doc, mode, indent, node );

            indent = 0;
            PFlushLine( doc, indent);

            for ( content = node->content; content; content = content->next )
            {
                PPrintTree( doc, (mode | PREFORMATTED | NOWRAP),
                            indent, content );
            }
            indent = indprev;
            PCondFlushLine( doc, indent );
            PPrintEndTag( doc, mode, indent, node );

            if ( !cfg(doc, TidyIndentContent) && node->next != null )
                PFlushLine( doc, indent );
        }
        else if ( nodeIsSTYLE(node) || nodeIsSCRIPT(node) )
        {
            PPrintScriptStyle( doc, (mode | PREFORMATTED | NOWRAP | CDATA),
                               indent, node );
        }
        else if ( nodeCMIsInline(node) )
        {
            if ( cfgBool(doc, TidyMakeClean) )
            {
                /* discards <font> and </font> tags */
                if ( nodeIsFONT(node) )
                {
                    for ( content = node->content;
                          content != null;
                          content = content->next )
                        PPrintTree( doc, mode, indent, content );
                    return;
                }

                /* replace <nobr>...</nobr> by &nbsp; or &#160; etc. */
                if ( nodeIsNOBR(node) )
                {
                    for ( content = node->content;
                          content != null;
                          content = content->next)
                        PPrintTree( doc, mode|NOWRAP, indent, content );
                    return;
                }
            }

            /* otherwise a normal inline element */
            PPrintTag( doc, mode, indent, node );

            /* indent content for SELECT, TEXTAREA, MAP, OBJECT and APPLET */
            if ( ShouldIndent(doc, node) )
            {
                indent += spaces;
                PCondFlushLine( doc, indent );

                for ( content = node->content;
                      content != null;
                      content = content->next )
                    PPrintTree( doc, mode, indent, content );

                indent -= spaces;
                PCondFlushLine( doc, indent );
                /* PCondFlushLine( doc, indent ); */
            }
            else
            {
                for ( content = node->content;
                      content != null;
                      content = content->next )
                    PPrintTree( doc, mode, indent, content );
            }
            PPrintEndTag( doc, mode, indent, node );
        }
        else /* other tags */
        {
            Bool indcont  = ( cfg(doc, TidyIndentContent) > 0 );
            Bool indsmart = ( cfg(doc, TidyIndentContent) == TidyAutoState );
            Bool hideend  = cfgBool( doc, TidyHideEndTags );
            uint contentIndent = indent;

            if ( ShouldIndent(doc, node) )
                contentIndent += spaces;

            PCondFlushLine( doc, indent );
            if ( indsmart && node->prev != null )
                PFlushLine( doc, indent );

            /* do not omit elements with attributes */
            if ( !hideend || !nodeHasCM(node, CM_OMITST) ||
                 node->attributes != null )
            {
                PPrintTag( doc, mode, indent, node );
                if ( ShouldIndent(doc, node) )
                    PCondFlushLine( doc, contentIndent );
                else if ( nodeHasCM(node, CM_HTML) || nodeIsNOFRAMES(node) ||
                          (nodeHasCM(node, CM_HEAD) && !nodeIsTITLE(node)) )
                    PFlushLine( doc, contentIndent );
            }

            last = null;
            for ( content = node->content; content; content = content->next )
            {
                /* kludge for naked text before block level tag */
                if ( last && !indcont && nodeIsText(last) &&
                     content->tag && !nodeHasCM(content, CM_INLINE) )
                {
                    /* PFlushLine(fout, indent); */
                    PFlushLine( doc, contentIndent );
                }

                PPrintTree( doc, mode, contentIndent, content );
                last = content;
            }

            /* don't flush line for td and th */
            if ( ShouldIndent(doc, node) ||
                 ( !hideend &&
                   ( nodeHasCM(node, CM_HTML) || 
                     nodeIsNOFRAMES(node) ||
                     (nodeHasCM(node, CM_HEAD) && !nodeIsTITLE(node))
                   )
                 )
               )
            {
                PCondFlushLine( doc, indent );
                if ( !hideend || !nodeHasCM(node, CM_OPT) )
                {
                    PPrintEndTag( doc, mode, indent, node );
                    /* PFlushLine( doc, indent ); */
                }
            }
            else
            {
                if ( !hideend || !nodeHasCM(node, CM_OPT) )
                    PPrintEndTag( doc, mode, indent, node );
                /* PFlushLine( doc, indent ); */
            }

            /*
            */
            if ( !indcont && !hideend && node->next != null &&
                 nodeHasCM(node, CM_BLOCK|CM_LIST|CM_DEFLIST|CM_TABLE) )
            {
                PFlushLine( doc, indent );
            }
        }
    }
}

void PPrintXMLTree( TidyDocImpl* doc, uint mode, uint indent, Node *node )
{
    Bool xhtmlOut = cfgBool( doc, TidyXhtmlOut );
    if (node == null)
        return;

    if ( node->type == TextNode  ||
         (node->type == CDATATag && cfgBool(doc, TidyEscapeCdata)) )
    {
        PPrintText( doc, mode, indent, node );
    }
    else if ( node->type == CommentTag )
    {
        PCondFlushLine( doc, indent );
        PPrintComment( doc, 0, node);
        /* PCondFlushLine( doc, 0 ); */
    }
    else if ( node->type == RootNode )
    {
        Node *content;
        for ( content = node->content;
              content != null;
              content = content->next )
           PPrintXMLTree( doc, mode, indent, content );
    }
    else if ( node->type == DocTypeTag )
        PPrintDocType( doc, indent, node );
    else if ( node->type == ProcInsTag )
        PPrintPI( doc, indent, node );
    else if ( node->type == XmlDecl )
        PPrintXmlDecl( doc, indent, node );
    else if ( node->type == CDATATag )
        PPrintCDATA( doc, indent, node );
    else if ( node->type == SectionTag )
        PPrintSection( doc, indent, node );
    else if ( node->type == AspTag )
        PPrintAsp( doc, indent, node );
    else if ( node->type == JsteTag)
        PPrintJste( doc, indent, node );
    else if ( node->type == PhpTag)
        PPrintPhp( doc, indent, node );
    else if ( nodeHasCM(node, CM_EMPTY) ||
              (node->type == StartEndTag && !xhtmlOut) )
    {
        PCondFlushLine( doc, indent );
        PPrintTag( doc, mode, indent, node );
        /* PFlushLine( doc, indent ); */
    }
    else /* some kind of container element */
    {
        uint spaces = cfg( doc, TidyIndentSpaces );
        Node *content;
        Bool mixed = no;
        int cindent;

        for ( content = node->content; content; content = content->next )
        {
            if ( nodeIsText(content) )
            {
                mixed = yes;
                break;
            }
        }

        PCondFlushLine( doc, indent );

        if ( XMLPreserveWhiteSpace(doc, node) )
        {
            indent = 0;
            mixed = no;
            cindent = 0;
        }
        else if (mixed)
            cindent = indent;
        else
            cindent = indent + spaces;

        PPrintTag( doc, mode, indent, node );
        if ( !mixed && node->content )
            PFlushLine( doc, cindent );
 
        for ( content = node->content; content; content = content->next )
            PPrintXMLTree( doc, mode, cindent, content );

        if ( !mixed && node->content )
            PCondFlushLine( doc, indent );

        PPrintEndTag( doc, mode, indent, node );
        /* PCondFlushLine( doc, indent ); */
    }
}

