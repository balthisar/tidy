#ifndef __BUFFIO_H__
#define __BUFFIO_H__

/* buffio.h -- Treat buffer as an I/O stream.

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2002/10/15 19:46:52 $ 
    $Revision: 1.1.2.3 $ 

  Requires buffer to automatically grow as bytes are added.
  Must keep track of current read and write points.

*/

#include "platform.h"
#include "tidy.h"

#ifdef __cplusplus
extern "C" {
#endif

TIDY_STRUCT
struct _TidyBuffer 
{
    byte* bp;
    uint  size;
    uint  allocated;
    uint  next;
};

TIDY_EXPORT void tidyBufInit( TidyBuffer* buf );
TIDY_EXPORT void tidyBufAlloc( TidyBuffer* buf, uint allocSize );
TIDY_EXPORT void tidyBufCheckAlloc( TidyBuffer* buf,
                                    uint allocSize, uint chunkSize );
TIDY_EXPORT void tidyBufFree( TidyBuffer* buf );

TIDY_EXPORT void tidyBufClear( TidyBuffer* buf );
TIDY_EXPORT void tidyBufAttach( TidyBuffer* buf, void* bp, uint size );
TIDY_EXPORT void tidyBufDetach( TidyBuffer* buf );

TIDY_EXPORT void tidyBufAppend( TidyBuffer* buf, void* vp, uint size );
TIDY_EXPORT void tidyBufPutByte( TidyBuffer* buf, byte bv );
TIDY_EXPORT int  tidyBufPopByte( TidyBuffer* buf );

TIDY_EXPORT int  tidyBufGetByte( TidyBuffer* buf );
TIDY_EXPORT Bool tidyBufEndOfInput( TidyBuffer* buf );
TIDY_EXPORT void tidyBufUngetByte( TidyBuffer* buf, byte bv );


/**************
   TIDY
**************/

/* Forward declarations
*/

TIDY_EXPORT void initInputBuffer( TidyInputSource* inp, TidyBuffer* buf );
TIDY_EXPORT void initOutputBuffer( TidyOutputSink* outp, TidyBuffer* buf );

#ifdef __cplusplus
}
#endif
#endif /* __BUFFIO_H__ */
