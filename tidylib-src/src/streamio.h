#ifndef __STREAMIO_H__
#define __STREAMIO_H__

/* streamio.h -- handles character stream I/O

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2002/07/28 18:10:16 $ 
    $Revision: 1.1.2.5 $ 

  Wrapper around Tidy input source and output sink
  that calls appropriate interfaces, and applies 
  necessary char encoding transformations: to/from
  ISO-10646 and/or UTF-8.

*/

#include "forward.h"
#include "tidy.h"
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
    int encoding;
    int state;     /* for ISO 2022 */

    IOType iotype;
    TidyOutputSink sink;
};

StreamOut* FileOutput( FILE* fp, int encoding );
StreamOut* BufferOutput( TidyBuffer* buf, int encoding );
StreamOut* UserOutput( TidyOutputSink* sink, int encoding );

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
#define LATIN1      2
#define UTF8        3
#define ISO2022     4
#define MACROMAN    5
#define WIN1252     6

#if SUPPORT_UTF16_ENCODINGS
#define UTF16LE     7
#define UTF16BE     8
#define UTF16       9
#endif

/* Note that Big5 and SHIFTJIS are not converted to ISO 10646 codepoints
** (i.e., to Unicode) before being recoded into UTF-8. This may be
** confusing: usually UTF-8 implies ISO10646 codepoints.
*/
#if SUPPORT_ASIAN_ENCODINGS
#if SUPPORT_UTF16_ENCODINGS
#define BIG5        10
#define SHIFTJIS    11
#else
#define BIG5        7
#define SHIFTJIS    8
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
extern int ReplacementCharEncoding;

/* Function for conversion from Windows-1252 to Unicode */
uint DecodeWin1252(uint c);

/* Function to convert from MacRoman to Unicode */
uint DecodeMacRoman(uint c);

/* Function to convert from Symbol Font chars to Unicode */
uint DecodeSymbolFont(uint c);


#endif /* __STREAMIO_H__ */
