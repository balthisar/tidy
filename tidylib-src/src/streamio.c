/* streamio.c -- handles character stream I/O

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:11 $ 
    $Revision: 1.2 $ 

  Wrapper around Tidy input source and output sink
  that calls appropriate interfaces, and applies
  necessary char encoding transformations: to/from
  ISO-10646 and/or UTF-8.

*/

#include <stdio.h>
#include <errno.h>

#include "streamio.h"
#include "tidy-int.h"
#include "lexer.h"
#include "message.h"
#include "utf8.h"

/************************
** Forward Declarations
************************/

uint ReadCharFromStream( StreamIn* in );

uint ReadByte( StreamIn* in );
Bool IsEOF( StreamIn* in );
void UngetByte( StreamIn* in, uint byteValue );

void PutByte( uint byteValue, StreamOut* out );

void EncodeWin1252( uint c, StreamOut* out );
void EncodeMacRoman( uint c, StreamOut* out );
void EncodeIbm858( uint c, StreamOut* out );
void EncodeLatin0( uint c, StreamOut* out );

void outcUTF8Bytes( StreamOut *out, byte* buf, int* count );
void outBOM( StreamOut *out );

/******************************
** Static (duration) Globals
******************************/

static StreamOut stderrStreamOut = 
{
    ASCII,
    FSM_ASCII,
    DEFAULT_NL_CONFIG,
    FileIO,
    { 0, filesink_putByte }
};

static StreamOut stdoutStreamOut = 
{
    ASCII,
    FSM_ASCII,
    DEFAULT_NL_CONFIG,
    FileIO,
    { 0, filesink_putByte }
};

StreamOut* StdErrOutput()
{
  if ( stderrStreamOut.sink.sinkData == 0 )
      stderrStreamOut.sink.sinkData = (uint) stderr;
  return &stderrStreamOut;
}

StreamOut* StdOutOutput()
{
  if ( stdoutStreamOut.sink.sinkData == 0 )
      stdoutStreamOut.sink.sinkData = (uint) stdout;
  return &stdoutStreamOut;
}

void  ReleaseStreamOut( StreamOut* out )
{
    if ( out && out != &stderrStreamOut && out != &stdoutStreamOut )
    {
        if ( out->iotype == FileIO )
            fclose( (FILE*) out->sink.sinkData );
        MemFree( out );
    }
}


/************************
** Source
************************/

static StreamIn* initStreamIn( TidyDocImpl* doc, int encoding )
{
    StreamIn *in = (StreamIn*) MemAlloc( sizeof(StreamIn) );

    ClearMemory( in, sizeof(StreamIn) );
    in->curline = 1;
    in->curcol = 1;
    in->encoding = encoding;
    in->state = FSM_ASCII;
    in->lookingForBOM = yes;
    in->doc = doc;
    return in;
}

StreamIn* FileInput( TidyDocImpl* doc, FILE *fp, int encoding )
{
    StreamIn *in = initStreamIn( doc, encoding );
    initFileSource( &in->source, fp );
    in->iotype = FileIO;
    return in;
}

StreamIn* BufferInput( TidyDocImpl* doc, TidyBuffer* buf, int encoding )
{
    StreamIn *in = initStreamIn( doc, encoding );
    initInputBuffer( &in->source, buf );
    in->iotype = BufferIO;
    return in;
}

StreamIn* UserInput( TidyDocImpl* doc, TidyInputSource* source, int encoding )
{
    StreamIn *in = initStreamIn( doc, encoding );
    memcpy( &in->source, source, sizeof(TidyInputSource) );
    in->iotype = UserIO;
    return in;
}

uint ReadChar( StreamIn *in )
{
    uint c = EndOfStream;
    uint tabsize = cfg( in->doc, TidyTabSize );

    if ( in->pushed )
        return PopChar( in );

    in->lastcol = in->curcol;

    if ( in->tabs > 0 )
    {
        in->curcol++;
        in->tabs--;
        return ' ';
    }
    
    for (;;)
    {
        c = ReadCharFromStream(in);

        if ( EndOfStream == c )
            return EndOfStream;

        if (c == '\n')
        {
            in->curcol = 1;
            in->curline++;
            break;
        }

        if (c == '\t')
        {
            in->tabs = tabsize - ((in->curcol - 1) % tabsize) - 1;
            in->curcol++;
            c = ' ';
            break;
        }

        /* #427663 - map '\r' to '\n' - Andy Quick 11 Aug 00 */
        if (c == '\r')
        {
            c = ReadCharFromStream(in);
            if (c != '\n')
            {
                if (c == EndOfStream) /* EOF fix by Terry Teague 12 Aug 01 */
                {
                    /* c = EndOfStream; */ /* debug */
                }
                else
                    UngetChar(c, in);
                c = '\n';
            }
            in->curcol = 1;
            in->curline++;
            break;
        }

        /* strip control characters, except for Esc */

        if (c == '\033')
            break;

        /* Form Feed is allowed in HTML */
        if ( c == '\015' && !cfgBool(in->doc, TidyXmlTags) )
            break;
            
        if ( c < 32 )
            continue; /* discard control char */

        /* watch out for chars that have already been decoded such as */
        /* IS02022, UTF-8 etc, that don't require further decoding */

        if (
            in->encoding == RAW
         || in->encoding == ISO2022
         || in->encoding == UTF8

#if SUPPORT_ASIAN_ENCODINGS
         || in->encoding == SHIFTJIS /* #431953 - RJ */
         || in->encoding == BIG5     /* #431953 - RJ */
#endif
           )
        {
            in->curcol++;
            break;
        }

#if SUPPORT_UTF16_ENCODINGS
        /* handle surrogate pairs */
        if ( in->encoding == UTF16LE ||
             in->encoding == UTF16   ||
             in->encoding == UTF16BE )
        {
            if ( !IsValidUTF16FromUCS4(c) )
            {
                /* invalid UTF-16 value */
                ReportEncodingError(in->doc, INVALID_UTF16 | DISCARDED_CHAR, c);
                c = 0;
            }
            else if ( IsLowSurrogate(c) )
            {
                uint n = c;
                uint m = ReadCharFromStream( in );
                if ( m == EndOfStream )
                   return EndOfStream;

                c = 0;
                if ( IsHighSurrogate(m) )
                {
                    n = CombineSurrogatePair( m, n );
                    if ( IsValidCombinedChar(n) )
                        c = n;
                }
                /* not a valid pair */
                if ( 0 == c )
                    ReportEncodingError( in->doc, INVALID_UTF16 | DISCARDED_CHAR, c );
            }
        }
#endif

        /* Do first: acts on range 128 - 255 */
        switch ( in->encoding )
        {
        case MACROMAN:
            c = DecodeMacRoman( c );
            break;
        case IBM858:
            c = DecodeIbm850( c );
            break;
        case LATIN0:
            c = DecodeLatin0( c );
            break;
        }

        /* produced e.g. as a side-effect of smart quotes in Word */
        /* but can't happen if using MACROMAN encoding */
        if ( 127 < c && c < 160 )
        {
            uint c1 = 0, replMode = DISCARDED_CHAR;
            Bool isVendorChar = ( in->encoding == WIN1252 ||
                                  in->encoding == MACROMAN );
            Bool isWinChar    = ( in->encoding == WIN1252 ||
                                  ReplacementCharEncoding == WIN1252 );
            Bool isMacChar    = ( in->encoding == MACROMAN ||
                                  ReplacementCharEncoding == MACROMAN );
            
            /* set error position just before offending character */
            in->doc->lexer->lines = in->curline;
            in->doc->lexer->columns = in->curcol;
                
            if ( isWinChar )
                c1 = DecodeWin1252( c );
            else if ( isMacChar )
                c1 = DecodeMacRoman( c );
            if ( c1 )
                replMode = REPLACED_CHAR;
                
            if ( c1 == 0 && isVendorChar )
                ReportEncodingError( in->doc, VENDOR_SPECIFIC_CHARS | replMode, c );
            else if ( ! isVendorChar )
                ReportEncodingError( in->doc, INVALID_SGML_CHARS | replMode, c );
                
            c = c1;
        }

        if ( c == 0 )
            continue; /* illegal char is discarded */
        
        in->curcol++;
        break;
    }

    return c;
}

uint PopChar( StreamIn *in )
{
    uint c = EndOfStream;
    if ( in->pushed )
    {
        assert( in->bufpos > 0 );
        c = in->charbuf[ --in->bufpos ];
        if ( in->bufpos == 0 )
            in->pushed = no;

        if ( c == '\n' )
        {
            in->curcol = 1;
            in->curline++;
            return c;
        }
        in->curcol++;
    }
    return c;
}

void UngetChar( uint c, StreamIn *in )
{
    if (c == EndOfStream)
    {
        /* fprintf(stderr, "Attempt to UngetChar EOF\n"); */
        return;
    }
    
    in->pushed = yes;

    if (in->bufpos >= CHARBUF_SIZE)
    {
        memcpy(in->charbuf, in->charbuf + 1, CHARBUF_SIZE - 1);
        (in->bufpos)--;
    }
    in->charbuf[(in->bufpos)++] = c;

    if (c == '\n')
        --(in->curline);

    in->curcol = in->lastcol;
}



/************************
** Sink
************************/

static StreamOut* initStreamOut( int encoding, uint nl )
{
    StreamOut* out = (StreamOut*) MemAlloc( sizeof(StreamOut) );
    ClearMemory( out, sizeof(StreamOut) );
    out->encoding = encoding;
    out->state = FSM_ASCII;
    out->nl = nl;
    return out;
}

StreamOut* FileOutput( FILE* fp, int encoding, uint nl )
{
    StreamOut* out = initStreamOut( encoding, nl );
    initFileSink( &out->sink, fp );
    out->iotype = FileIO;
    return out;
}
StreamOut* BufferOutput( TidyBuffer* buf, int encoding, uint nl )
{
    StreamOut* out = initStreamOut( encoding, nl );
    initOutputBuffer( &out->sink, buf );
    out->iotype = BufferIO;
    return out;
}
StreamOut* UserOutput( TidyOutputSink* sink, int encoding, uint nl )
{
    StreamOut* out = initStreamOut( encoding, nl );
    memcpy( &out->sink, sink, sizeof(TidyOutputSink) );
    out->iotype = UserIO;
    return out;
}

void WriteChar( uint c, StreamOut* out )
{
    /* Translate outgoing newlines */
    if ( LF == c )
    {
      if ( out->nl == TidyCRLF )
          WriteChar( CR, out );
      else if ( out->nl == TidyCR )
          c = CR;
    }

    if (out->encoding == MACROMAN)
    {
        EncodeMacRoman( c, out );
    }
    else if (out->encoding == WIN1252)
    {
        EncodeWin1252( c, out );
    }
    else if (out->encoding == IBM858)
    {
        EncodeIbm858( c, out );
    }
    else if (out->encoding == LATIN0)
    {
        EncodeLatin0( c, out );
    }

    else if (out->encoding == UTF8)
    {
        int count = 0;
        
        EncodeCharToUTF8Bytes( c, null, &out->sink, &count );
        if (count <= 0)
        {
          /* ReportEncodingError(in->lexer, INVALID_UTF8 | REPLACED_CHAR, c); */
            /* replacement char 0xFFFD encoded as UTF-8 */
            PutByte(0xEF, out); PutByte(0xBF, out); PutByte(0xBF, out);
        }
    }
    else if (out->encoding == ISO2022)
    {
        if (c == 0x1b)  /* ESC */
            out->state = FSM_ESC;
        else
        {
            switch (out->state)
            {
            case FSM_ESC:
                if (c == '$')
                    out->state = FSM_ESCD;
                else if (c == '(')
                    out->state = FSM_ESCP;
                else
                    out->state = FSM_ASCII;
                break;

            case FSM_ESCD:
                if (c == '(')
                    out->state = FSM_ESCDP;
                else
                    out->state = FSM_NONASCII;
                break;

            case FSM_ESCDP:
                out->state = FSM_NONASCII;
                break;

            case FSM_ESCP:
                out->state = FSM_ASCII;
                break;

            case FSM_NONASCII:
                c &= 0x7F;
                break;
            }
        }

        PutByte(c, out);
    }

#if SUPPORT_UTF16_ENCODINGS
    else if ( out->encoding == UTF16LE ||
              out->encoding == UTF16BE ||
              out->encoding == UTF16 )
    {
        int i, numChars = 1;
        uint theChars[2];
        
        if ( !IsValidUTF16FromUCS4(c) )
        {
            /* invalid UTF-16 value */
            /* ReportEncodingError(in->lexer, INVALID_UTF16 | DISCARDED_CHAR, c); */
            c = 0;
            numChars = 0;
        }
        else if ( IsCombinedChar(c) )
        {
            /* output both, unless something goes wrong */
            numChars = 2;
            if ( !SplitSurrogatePair(c, &theChars[0], &theChars[1]) )
            {
                /* ReportEncodingError(in->lexer, INVALID_UTF16 | DISCARDED_CHAR, c); */
                c = 0;
                numChars = 0;
            }
        }
        else
        {
            /* just put the char out */
            theChars[0] = c;
        }
        
        for (i = 0; i < numChars; i++)
        {
            c = theChars[i];
            
            if (out->encoding == UTF16LE)
            {
                uint ch = c & 0xFF; PutByte(ch, out); 
                ch = (c >> 8) & 0xFF; PutByte(ch, out); 
            }
    
            else if (out->encoding == UTF16BE || out->encoding == UTF16)
            {
                uint ch = (c >> 8) & 0xFF; PutByte(ch, out); 
                ch = c & 0xFF; PutByte(ch, out); 
            }
        }
    }
#endif

#if SUPPORT_ASIAN_ENCODINGS
    else if (out->encoding == BIG5 || out->encoding == SHIFTJIS)
    {
        if (c < 128)
            PutByte(c, out);
        else
        {
            uint ch = (c >> 8) & 0xFF; PutByte(ch, out); 
            ch = c & 0xFF; PutByte(ch, out); 
        }
    }
#endif

    else
        PutByte( c, out );
}



/****************************
** Miscellaneous / Helpers
****************************/

/* char encoding used when replacing illegal SGML chars,
** regardless of specified encoding.  Set at compile time
** to either Windows or Mac.
*/
const int ReplacementCharEncoding = DFLT_REPL_CHARENC;


/* Mapping for Windows Western character set CP 1252 
** (chars 128-159/U+0080-U+009F) to Unicode.
*/
static const uint Win2Unicode[32] =
{
    0x20AC, 0x0000, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x0000, 0x017D, 0x0000,
    0x0000, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x0000, 0x017E, 0x0178
};

/* Function for conversion from Windows-1252 to Unicode */
uint DecodeWin1252(uint c)
{
    if (127 < c && c < 160)
        c = Win2Unicode[c - 128];
        
    return c;
}

void EncodeWin1252( uint c, StreamOut* out )
{
    if (c < 128 || (c > 159 && c < 256))
        PutByte(c, out);
    else
    {
        int i;

        for (i = 128; i < 160; i++)
            if (Win2Unicode[i - 128] == c)
            {
                PutByte(i, out);
                break;
            }
    }
}

/*
   John Love-Jensen contributed this table for mapping MacRoman
   character set to Unicode
*/

/* modified to only need chars 128-255/U+0080-U+00FF - Terry Teague 19 Aug 01 */
static const uint Mac2Unicode[128] = 
{
    /* x7F = DEL */
    
    0x00C4, 0x00C5, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00E1,
    0x00E0, 0x00E2, 0x00E4, 0x00E3, 0x00E5, 0x00E7, 0x00E9, 0x00E8,

    0x00EA, 0x00EB, 0x00ED, 0x00EC, 0x00EE, 0x00EF, 0x00F1, 0x00F3,
    0x00F2, 0x00F4, 0x00F6, 0x00F5, 0x00FA, 0x00F9, 0x00FB, 0x00FC,

    0x2020, 0x00B0, 0x00A2, 0x00A3, 0x00A7, 0x2022, 0x00B6, 0x00DF,
    0x00AE, 0x00A9, 0x2122, 0x00B4, 0x00A8, 0x2260, 0x00C6, 0x00D8,

    0x221E, 0x00B1, 0x2264, 0x2265, 0x00A5, 0x00B5, 0x2202, 0x2211,
                                            /* =BD U+2126 OHM SIGN */
    0x220F, 0x03C0, 0x222B, 0x00AA, 0x00BA, 0x03A9, 0x00E6, 0x00F8,

    0x00BF, 0x00A1, 0x00AC, 0x221A, 0x0192, 0x2248, 0x2206, 0x00AB,
    0x00BB, 0x2026, 0x00A0, 0x00C0, 0x00C3, 0x00D5, 0x0152, 0x0153,

    0x2013, 0x2014, 0x201C, 0x201D, 0x2018, 0x2019, 0x00F7, 0x25CA,
                            /* =DB U+00A4 CURRENCY SIGN */
    0x00FF, 0x0178, 0x2044, 0x20AC, 0x2039, 0x203A, 0xFB01, 0xFB02,

    0x2021, 0x00B7, 0x201A, 0x201E, 0x2030, 0x00C2, 0x00CA, 0x00C1,
    0x00CB, 0x00C8, 0x00CD, 0x00CE, 0x00CF, 0x00CC, 0x00D3, 0x00D4,
    /* xF0 = Apple Logo */
    /* =F0 U+2665 BLACK HEART SUIT */
    0xF8FF, 0x00D2, 0x00DA, 0x00DB, 0x00D9, 0x0131, 0x02C6, 0x02DC,
    0x00AF, 0x02D8, 0x02D9, 0x02DA, 0x00B8, 0x02DD, 0x02DB, 0x02C7
};

/* Function to convert from MacRoman to Unicode */
uint DecodeMacRoman(uint c)
{
    if (127 < c)
        c = Mac2Unicode[c - 128];
    return c;
}

void EncodeMacRoman( uint c, StreamOut* out )
{
        if (c < 128)
            PutByte(c, out);
        else
        {
            /* For mac users, map Unicode back to MacRoman. */
            int i;
            for (i = 128; i < 256; i++)
            {
                if (Mac2Unicode[i - 128] == c)
                {
                    PutByte(i, out);
                    break;
                }
            }
        }
}

/* Mapping for OS/2 Western character set CP 850
** (chars 128-255) to Unicode.
*/
const uint IBM2Unicode[128] =
{
    0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
    0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
    0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
    0x00FF, 0x00D6, 0x00DC, 0x00F8, 0x00A3, 0x00D8, 0x00D7, 0x0192,
    0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
    0x00BF, 0x00AE, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
    0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x00C1, 0x00C2, 0x00C0,
    0x00A9, 0x2563, 0x2551, 0x2557, 0x255D, 0x00A2, 0x00A5, 0x2510,
    0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x00E3, 0x00C3,
    0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256c, 0x00a4,
    0x00f0, 0x00d0, 0x00ca, 0x00cb, 0x00c8, 0x20AC, 0x00cd, 0x00ce,
    0x00cf, 0x2518, 0x250c, 0x2588, 0x2584, 0x00a6, 0x00cc, 0x2580,
    0x00d3, 0x00df, 0x00d4, 0x00d2, 0x00f5, 0x00d5, 0x00b5, 0x00fe,
    0x00de, 0x00da, 0x00db, 0x00d9, 0x00fd, 0x00dd, 0x00af, 0x00b4,
    0x00ad, 0x00b1, 0x2017, 0x00be, 0x00b6, 0x00a7, 0x00f7, 0x00b8,
    0x00b0, 0x00a8, 0x00b7, 0x00b9, 0x00b3, 0x00b2, 0x25a0, 0x00a0
};

/* Function for conversion from OS/2-850 to Unicode */
uint DecodeIbm850(uint c)
{
    if (127 < c && c < 256)
        c = IBM2Unicode[c - 128];

    return c;
}

/* For OS/2,Java users, map Unicode back to IBM858 (IBM850+Euro). */
void EncodeIbm858( uint c, StreamOut* out )
{
    if (c < 128)
        PutByte(c, out);
    else
    {
        int i;
        for (i = 128; i < 256; i++)
        {
            if (IBM2Unicode[i - 128] == c)
            {
                PutByte(i, out);
                break;
            }
        }
    }
}


/* Convert from Latin0 (aka Latin9, ISO-8859-15) to Unicode */
uint DecodeLatin0(uint c)
{
    if (159 < c && c < 191)
    {
        switch (c)
        {
        case 0xA4: c = 0x20AC; break;
        case 0xA6: c = 0x0160; break;
        case 0xA8: c = 0x0161; break;
        case 0xB4: c = 0x017D; break;
        case 0xB8: c = 0x017E; break;
        case 0xBC: c = 0x0152; break;
        case 0xBD: c = 0x0153; break;
        case 0xBE: c = 0x0178; break;
        }
    }
    return c;
}

/* Map Unicode back to ISO-8859-15. */
void EncodeLatin0( uint c, StreamOut* out )
{
    switch (c)
    {
    case 0x20AC: c = 0xA4; break;
    case 0x0160: c = 0xA6; break;
    case 0x0161: c = 0xA8; break;
    case 0x017D: c = 0xB4; break;
    case 0x017E: c = 0xB8; break;
    case 0x0152: c = 0xBC; break;
    case 0x0153: c = 0xBD; break;
    case 0x0178: c = 0xBE; break;
    }
    PutByte(c, out);
}

/*
   Table to map symbol font characters to Unicode; undefined
   characters are mapped to 0x0000 and characters without any
   Unicode equivalent are mapped to '?'. Is this appropriate?
*/

static const uint Symbol2Unicode[] = 
{
    0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007,
    0x0008, 0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F,
    
    0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017,
    0x0018, 0x0019, 0x001A, 0x001B, 0x001C, 0x001D, 0x001E, 0x001F,
    
    0x0020, 0x0021, 0x2200, 0x0023, 0x2203, 0x0025, 0x0026, 0x220D,
    0x0028, 0x0029, 0x2217, 0x002B, 0x002C, 0x2212, 0x002E, 0x002F,
    
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    
    0x2245, 0x0391, 0x0392, 0x03A7, 0x0394, 0x0395, 0x03A6, 0x0393,
    0x0397, 0x0399, 0x03D1, 0x039A, 0x039B, 0x039C, 0x039D, 0x039F,
    
    0x03A0, 0x0398, 0x03A1, 0x03A3, 0x03A4, 0x03A5, 0x03C2, 0x03A9,
    0x039E, 0x03A8, 0x0396, 0x005B, 0x2234, 0x005D, 0x22A5, 0x005F,
    
    0x00AF, 0x03B1, 0x03B2, 0x03C7, 0x03B4, 0x03B5, 0x03C6, 0x03B3,
    0x03B7, 0x03B9, 0x03D5, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BF,
    
    0x03C0, 0x03B8, 0x03C1, 0x03C3, 0x03C4, 0x03C5, 0x03D6, 0x03C9,
    0x03BE, 0x03C8, 0x03B6, 0x007B, 0x007C, 0x007D, 0x223C, 0x003F,
    
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    
    0x00A0, 0x03D2, 0x2032, 0x2264, 0x2044, 0x221E, 0x0192, 0x2663,
    0x2666, 0x2665, 0x2660, 0x2194, 0x2190, 0x2191, 0x2192, 0x2193,
    
    0x00B0, 0x00B1, 0x2033, 0x2265, 0x00D7, 0x221D, 0x2202, 0x00B7,
    0x00F7, 0x2260, 0x2261, 0x2248, 0x2026, 0x003F, 0x003F, 0x21B5,
    
    0x2135, 0x2111, 0x211C, 0x2118, 0x2297, 0x2295, 0x2205, 0x2229,
    0x222A, 0x2283, 0x2287, 0x2284, 0x2282, 0x2286, 0x2208, 0x2209,
    
    0x2220, 0x2207, 0x00AE, 0x00A9, 0x2122, 0x220F, 0x221A, 0x22C5,
    0x00AC, 0x2227, 0x2228, 0x21D4, 0x21D0, 0x21D1, 0x21D2, 0x21D3,
    
    0x25CA, 0x2329, 0x00AE, 0x00A9, 0x2122, 0x2211, 0x003F, 0x003F,
    0x003F, 0x003F, 0x003F, 0x003F, 0x003F, 0x003F, 0x003F, 0x003F,
    
    0x20AC, 0x232A, 0x222B, 0x2320, 0x003F, 0x2321, 0x003F, 0x003F,
    0x003F, 0x003F, 0x003F, 0x003F, 0x003F, 0x003F, 0x003F, 0x003F
};

/* Function to convert from Symbol Font chars to Unicode */
uint DecodeSymbolFont(uint c)
{
    if (c > 255)
        return c;

    /* todo: add some error message */

    return Symbol2Unicode[c];
}


/* Facilitates user defined source by providing
** an entry point to marshal pointers-to-functions.
** Needed by .NET and possibly other language bindings.
*/
Bool tidyInitSource( TidyInputSource*  source,
                     void*             srcData,
                     TidyGetByteFunc   gbFunc,
                     TidyUngetByteFunc ugbFunc,
                     TidyEOFFunc       endFunc )
{
  Bool ok = ( source && srcData && gbFunc && ugbFunc && endFunc );
  if ( ok )
  {
    source->sourceData = (uint) srcData;
    source->getByte    = gbFunc;
    source->ungetByte  = ugbFunc;
    source->eof        = endFunc;
  }
  return ok;
}

Bool tidyInitSink( TidyOutputSink* sink,
                   void*           snkData,
                   TidyPutByteFunc pbFunc )
{
  Bool ok = ( sink && snkData && pbFunc );
  if ( ok )
  {
    sink->sinkData = (uint) snkData;
    sink->putByte  = pbFunc;
  }
  return ok;
}

/* GetByte must return a byte value in a signed
** integer so that a negative value can signal EOF
** without interfering w/ 0-255 legitimate byte values.
*/
uint  tidyGetByte( TidyInputSource* source )
{
  int bv = source->getByte( source->sourceData );
  return (uint) bv;
}
Bool  tidyIsEOF( TidyInputSource* source )
{
  return source->eof( source->sourceData );
}
void tidyUngetByte( TidyInputSource* source, uint ch )
{
    source->ungetByte( source->sourceData, (byte) ch );
}
void tidyPutByte( TidyOutputSink* sink, uint ch )
{
    sink->putByte( sink->sinkData, (byte) ch );
}

uint ReadByte( StreamIn* in )
{
    return tidyGetByte( &in->source );
}
Bool IsEOF( StreamIn* in )
{
    return tidyIsEOF( &in->source );
}
void UngetByte( StreamIn* in, uint byteValue )
{
    tidyUngetByte( &in->source, byteValue );
}
void PutByte( uint byteValue, StreamOut* out )
{
    tidyPutByte( &out->sink, byteValue );
}

#if 0
static void UngetRawBytesToStream( StreamIn *in, byte* buf, int *count )
{
    int i;
    
    for (i = 0; i < *count; i++)
    {
        /* should never get here; testing for 0xFF, a valid char, is not a good idea */
        if ( in && IsEOF(in) )
        {
            /* fprintf(stderr,"Attempt to unget EOF in UngetRawBytesToStream\n"); */
            *count = -i;
            return;
        }

        in->source.ungetByte( in->source.sourceData, buf[i] );
    }
}

/*
   Read raw bytes from stream, return <= 0 if EOF; or if
   "unget" is true, Unget the bytes to re-synchronize the input stream
   Normally UTF-8 successor bytes are read using this routine.
*/
static void ReadRawBytesFromStream( StreamIn *in, byte* buf, int *count )
{
    int ix;
    for ( ix=0; ix < *count; ++ix )
    {
        if ( in->rawPushed )
        {
            buf[ix] = in->rawBytebuf[ --in->rawBufpos ];
            if ( in->rawBufpos == 0 )
                in->rawPushed = no;
        }
        else
        {
            if ( in->source.eof(in->source.sourceData) )
            {
                *count = -i;
                break;
            }
            buf[ix] = in->source.getByte( in->source.sourceData );
        }
    }
}
#endif /* 0 */

/* read char from stream */
uint ReadCharFromStream( StreamIn* in )
{
    uint c, n;

    if ( IsEOF(in) )
        return EndOfStream;
    
    c = ReadByte( in );
    if ( in->lookingForBOM &&
         (
#if SUPPORT_UTF16_ENCODINGS
           in->encoding == UTF16   ||
           in->encoding == UTF16LE ||
           in->encoding == UTF16BE ||
#endif
           in->encoding == UTF8) )
    {
        /* check for a Byte Order Mark */
        uint c1, bom;
        in->lookingForBOM = no;
        if ( IsEOF(in) )
            return EndOfStream;
        
        c1 = ReadByte( in );
        
#if SUPPORT_UTF16_ENCODINGS
        bom = (c << 8) + c1;
        
        if ( bom == UNICODE_BOM_BE )
        {
            /* big-endian UTF-16 */
            if ( in->encoding != UTF16 && in->encoding != UTF16BE )
            {
                /* fprintf(stderr, "Input is encoded as UTF16BE\n"); */
                ReportEncodingError( in->doc, ENCODING_MISMATCH, UTF16BE ); /* non-fatal error */
            }
            in->encoding = UTF16BE;
            SetOptionInt( in->doc, TidyInCharEncoding, UTF16BE );
            return UNICODE_BOM; /* return decoded BOM */
        }
        else if (bom == UNICODE_BOM_LE)
        {
            /* little-endian UTF-16 */
            if (in->encoding != UTF16 && in->encoding != UTF16LE)
            {
                /* fprintf(stderr, "Input is encoded as UTF16LE\n"); */ /* debug */
                ReportEncodingError( in->doc, ENCODING_MISMATCH, UTF16LE );
            }
            in->encoding = UTF16LE;
            SetOptionInt( in->doc, TidyInCharEncoding, UTF16LE );
            return UNICODE_BOM; /* return decoded BOM */
        }
        else

#endif
        {
            uint c2 = ReadByte( in );
            if ( ((c << 16) + (c1 << 8) + c2) == UNICODE_BOM_UTF8 )
            {
                /* UTF-8 */
                if (in->encoding != UTF8)
                {
                    /* fprintf(stderr, "Input is encoded as UTF8\n"); */ /* debug */
                    ReportEncodingError( in->doc, ENCODING_MISMATCH, UTF8 );
                }
                in->encoding = UTF8;
                SetOptionInt( in->doc, TidyInCharEncoding, UTF8 );
                return UNICODE_BOM; /* return decoded BOM */
            }
            else
            {
                /* the 2nd and/or 3rd bytes weren't what we were */
                /* expecting, so unget the extra 2 bytes */
                UngetByte( in, c2 );
                UngetByte( in, c1 );
               /* drop through to code below, with the original char */
           }
        }
    }
    
    in->lookingForBOM = no;
    
    /*
       A document in ISO-2022 based encoding uses some ESC sequences
       called "designator" to switch character sets. The designators
       defined and used in ISO-2022-JP are:

        "ESC" + "(" + ?     for ISO646 variants

        "ESC" + "$" + ?     and
        "ESC" + "$" + "(" + ?   for multibyte character sets

       Where ? stands for a single character used to indicate the
       character set for multibyte characters.

       Tidy handles this by preserving the escape sequence and
       setting the top bit of each byte for non-ascii chars. This
       bit is then cleared on output. The input stream keeps track
       of the state to determine when to set/clear the bit.
    */

    if (in->encoding == ISO2022)
    {
        if (c == 0x1b)  /* ESC */
        {
            in->state = FSM_ESC;
            return c;
        }

        switch (in->state)
        {
        case FSM_ESC:
            if (c == '$')
                in->state = FSM_ESCD;
            else if (c == '(')
                in->state = FSM_ESCP;
            else
                in->state = FSM_ASCII;
            break;

        case FSM_ESCD:
            if (c == '(')
                in->state = FSM_ESCDP;
            else
                in->state = FSM_NONASCII;
            break;

        case FSM_ESCDP:
            in->state = FSM_NONASCII;
            break;

        case FSM_ESCP:
            in->state = FSM_ASCII;
            break;

        case FSM_NONASCII:
            c |= 0x80;
            break;
        }

        return c;
    }

#if SUPPORT_UTF16_ENCODINGS
    if ( in->encoding == UTF16LE )
    {
        uint c1 = ReadByte( in );
        if ( EndOfStream == c1 )
            return EndOfStream;
        n = (c1 << 8) + c;
        return n;
    }

    if ((in->encoding == UTF16) || (in->encoding == UTF16BE)) /* UTF-16 is big-endian by default */
    {
        uint c1 = ReadByte( in );
        if ( EndOfStream == c1 )
            return EndOfStream;
        n = (c << 8) + c1;
        return n;
    }
#endif

    if ( in->encoding == UTF8 )
    {
        /* deal with UTF-8 encoded char */

        int err, count = 0;
        
        /* first byte "c" is passed in separately */
        err = DecodeUTF8BytesToChar( &n, c, null, &in->source, &count );
        if (!err && (n == (uint)EndOfStream) && (count == 1)) /* EOF */
            return EndOfStream;
        else if (err)
        {
            /* set error position just before offending character */
            in->doc->lexer->lines = in->curline;
            in->doc->lexer->columns = in->curcol;

            ReportEncodingError(in->doc, INVALID_UTF8 | REPLACED_CHAR, n);
            n = 0xFFFD; /* replacement char */
        }
        
        return n;
    }
    
#if SUPPORT_ASIAN_ENCODINGS
    /*
       This section is suitable for any "multibyte" variable-width 
       character encoding in which a one-byte code is less than
       128, and the first byte of a two-byte code is greater or
       equal to 128. Note that Big5 and ShiftJIS fit into this
       kind, even though their second byte may be less than 128
    */
    if ((in->encoding == BIG5) || (in->encoding == SHIFTJIS))
    {
        if (c < 128)
            return c;
        else if ((in->encoding == SHIFTJIS) && (c >= 0xa1 && c <= 0xdf)) /* 461643 - fix suggested by Rick Cameron 14 Sep 01 */
        {
            /*
              Rick Cameron pointed out that for Shift_JIS, the values from
              0xa1 through 0xdf represent singe-byte characters
              (U+FF61 to U+FF9F - half-shift Katakana)
            */
            return c;
        }
        else
        {
            uint c1 = ReadByte( in );
            n = (c << 8) + c1;
            return n;
        }
    }
#endif

    else
        n = c;
        
    return n;
}



/* Output a Byte Order Mark if required */
void outBOM( StreamOut *out )
{
    if ( out->encoding == UTF8
#if SUPPORT_UTF16_ENCODINGS
         || out->encoding == UTF16LE
         || out->encoding == UTF16BE
         || out->encoding == UTF16
#endif
       )
    {
        /* this will take care of encoding the BOM correctly */
        WriteChar( UNICODE_BOM, out );
    }
}
