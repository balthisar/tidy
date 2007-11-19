/* fileio.c -- does standard I/O

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

  Default implementations of Tidy input sources
  and output sinks based on standard C FILE*.

*/

#include <stdio.h>

#include "fileio.h"
#include "tidy.h"


typedef struct _fp_input_source
{
    FILE*        fp;
    TidyBuffer   unget;
} FileSource;

int filesrc_getByte( uint sourceData )
{
  FileSource* fin = (FileSource*) sourceData;
  int bv;
  if ( fin->unget.size > 0 )
    bv = tidyBufPopByte( &fin->unget );
  else
    bv = fgetc( fin->fp );
  return bv;
}
Bool filesrc_eof( uint sourceData )
{
  FileSource* fin = (FileSource*) sourceData;
  Bool isEOF = ( fin->unget.size == 0 );
  if ( isEOF )
    isEOF = feof( fin->fp );
  return isEOF;
}
void filesrc_ungetByte( uint sourceData, byte bv )
{
  FileSource* fin = (FileSource*) sourceData;
  tidyBufPutByte( &fin->unget, bv );
}

void initFileSource( TidyInputSource* inp, FILE* fp )
{
  FileSource* fin = null;

  inp->getByte    = filesrc_getByte;
  inp->eof        = filesrc_eof;
  inp->ungetByte  = filesrc_ungetByte;

  fin = (FileSource*) MemAlloc( sizeof(FileSource) );
  ClearMemory( fin, sizeof(FileSource) );
  fin->fp = fp;
  inp->sourceData = (uint) fin;
}

void freeFileSource( TidyInputSource* inp, Bool closeIt )
{
    FileSource* fin = (FileSource*) inp->sourceData;
    if ( closeIt && fin && fin->fp )
      fclose( fin->fp );
    tidyBufFree( &fin->unget );
    MemFree( fin );
}

void filesink_putByte( uint sinkData, byte bv )
{
  FILE* fout = (FILE*) sinkData;
  fputc( bv, fout );
}

void  initFileSink( TidyOutputSink* outp, FILE* fp )
{
  outp->putByte  = filesink_putByte;
  outp->sinkData = (uint) fp;
}

