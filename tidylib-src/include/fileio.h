#ifndef __FILEIO_H__
#define __FILEIO_H__

/* fileio.h -- does standard I/O

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2002/07/28 18:10:16 $ 
    $Revision: 1.1.2.1 $ 

  Implementation of a FILE* based TidyInputSource and 
  TidyOutputSink.
  
*/

#include "buffio.h"
#ifdef __cplusplus
extern "C" {
#endif

void initFileSource( TidyInputSource* source, FILE* fp );
void freeFileSource( TidyInputSource* source, Bool closeIt );

void initFileSink( TidyOutputSink* sink, FILE* fp );

void filesink_putByte( uint sinkData, byte bv );

#ifdef __cplusplus
}
#endif
#endif /* __FILEIO_H__ */
