#ifndef __STREAMIO_H__
#define __STREAMIO_H__

/* streamio.h -- handles character stream I/O

  (c) 1998-2003 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: lpassey $ 
    $Date: 2003/02/25 21:12:03 $ 
    $Revision: 1.3 $ 

  Wrapper around Tidy input source and output sink
  that calls appropriate interfaces, and applies 
  necessary char encoding transformations: to/from
  ISO-10646 and/or UTF-8.

*/

#include "forward.h"
#include "buffio.h"
#include "fileio.h"

typedef enum
{
  FileIO,
  BufferIO,
  UserIO
} IOType;

/************************
** Source
************************/

#define CHARBUF_SIZE 5

/* non-raw input is cleaned up*/
struct _StreamIn
{
    int  state;     /* FSM for ISO2022 */
    Bool lookingForBOM;
    Bool pushed;
    uint charbuf[ CHARBUF_SIZE ];
    int  bufpos;
    int  tabs;
    int  lastcol;
    int  curcol;
    int  curline;

    int  encoding;
    IOType iotype;
    TidyInputSource source;

    /* Pointer back to document for error reporting */
    TidyDocImpl* doc;
};

StreamIn* FileInput( TidyDocImpl* doc, FILE* fp, int encoding );
StreamIn* BufferInput( TidyDocImpl* doc, TidyBuffer* content, int encoding );
StreamIn* UserInput( TidyDocImpl* doc, TidyInputSource* source, int encoding );

uint      ReadChar( StreamIn* in );
void      UngetChar( uint c, StreamIn* in );
uint      PopChar( StreamIn *in );
Bool      IsEOF( StreamIn* in );


/************************
** Sink
************************/

struct _StreamOut
{
    int   encoding;
    int   state;     /* for ISO 2022 */
    uint  nl;

    IOType iotype;
    TidyOutputSink sink;
};

StreamOut* FileOutput( FILE* fp, int encoding, uint newln );
StreamOut* BufferOutput( TidyBuffer* buf, int encoding, uint newln );
StreamOut* UserOutput( TidyOutputSink* sink, int encoding, uint newln );

StreamOut* StdErrOutput();
StreamOut* StdOutOutput();
void       ReleaseStreamOut( StreamOut* out );

void WriteChar( uint c, StreamOut* out );
void outBOM( StreamOut *out );

/************************
** Misc
************************/

/* character encodings
*/
#define RAW         0
#define ASCII       1
#define LATIN0      2
#define LATIN1      3
#define UTF8        4
#define ISO2022     5
#define MACROMAN    6
#define WIN1252     7
#define IBM858      8

#if SUPPORT_UTF16_ENCODINGS
#define UTF16LE     9
#define UTF16BE     10
#define UTF16       11
#endif

/* Note that Big5 and SHIFTJIS are not converted to ISO 10646 codepoints
** (i.e., to Unicode) before being recoded into UTF-8. This may be
** confusing: usually UTF-8 implies ISO10646 codepoints.
*/
#if SUPPORT_ASIAN_ENCODINGS
#if SUPPORT_UTF16_ENCODINGS
#define BIG5        12
#define SHIFTJIS    13
#else
#define BIG5        9
#define SHIFTJIS    10
#endif
#endif


/* states for ISO 2022

 A document in ISO-2022 based encoding uses some ESC sequences called
 "designator" to switch character sets. The designators defined and
 used in ISO-2022-JP are:

    "ESC" + "(" + ?     for ISO646 variants

    "ESC" + "$" + ?     and
    "ESC" + "$" + "(" + ?   for multibyte character sets
*/
#define FSM_ASCII    0
#define FSM_ESC      1
#define FSM_ESCD     2
#define FSM_ESCDP    3
#define FSM_ESCP     4
#define FSM_NONASCII 5


/* char encoding used when replacing illegal SGML chars,
** regardless of specified encoding.  Set at compile time
** to either Windows or Mac.
*/
extern const int ReplacementCharEncoding;

/* Function for conversion from Windows-1252 to Unicode */
uint DecodeWin1252(uint c);

/* Function to convert from MacRoman to Unicode */
uint DecodeMacRoman(uint c);

/* Function for conversion from OS/2-850 to Unicode */
uint DecodeIbm850(uint c);

/* Function for conversion from Latin0 to Unicode */
uint DecodeLatin0(uint c);

/* Function to convert from Symbol Font chars to Unicode */
uint DecodeSymbolFont(uint c);


/* Use numeric constants as opposed to escape chars (\r, \n)
** to avoid conflict Mac compilers that may re-define these.
*/
#define CR    0xD
#define LF    0xA

#if   defined(MAC_OS_CLASSIC)
#define DEFAULT_NL_CONFIG TidyCR
#elif defined(_WIN32) || defined(OS2_OS)
#define DEFAULT_NL_CONFIG TidyCRLF
#else
#define DEFAULT_NL_CONFIG TidyLF
#endif


#endif /* __STREAMIO_H__ */
