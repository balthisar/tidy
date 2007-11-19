/* buffio.c -- Treat buffer as an I/O stream.

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

  Requires buffer to automatically grow as bytes are added.
  Must keep track of current read and write points.

*/

#include <tidy.h>
#include <buffio.h>


/**************
   TIDY
**************/

static int insrc_getByte( uint appData )
{
  TidyBuffer* buf = (TidyBuffer*) appData;
  return tidyBufGetByte( buf );
}
static Bool insrc_eof( uint appData )
{
  TidyBuffer* buf = (TidyBuffer*) appData;
  return tidyBufEndOfInput( buf );
}
static void insrc_ungetByte( uint appData, byte bv )
{
  TidyBuffer* buf = (TidyBuffer*) appData;
  tidyBufUngetByte( buf, bv );
}

void  initInputBuffer( TidyInputSource* inp, TidyBuffer* buf )
{
  inp->getByte    = insrc_getByte;
  inp->eof        = insrc_eof;
  inp->ungetByte  = insrc_ungetByte;
  inp->sourceData = (uint) buf;
}

static void outsink_putByte( uint appData, byte bv )
{
  TidyBuffer* buf = (TidyBuffer*) appData;
  tidyBufPutByte( buf, bv );
}

void  initOutputBuffer( TidyOutputSink* outp, TidyBuffer* buf )
{
  outp->putByte  = outsink_putByte;
  outp->sinkData = (uint) buf;
}


void      tidyBufInit( TidyBuffer* buf )
{
    assert( buf != null );
    ClearMemory( buf, sizeof(TidyBuffer) );
}

void      tidyBufAlloc( TidyBuffer* buf, uint allocSize )
{
    tidyBufInit( buf );
    tidyBufCheckAlloc( buf, allocSize, 0 );
    buf->next = 0;
}
void      tidyBufFree( TidyBuffer* buf )
{
    assert( buf != null );
    MemFree( buf->bp );
    tidyBufInit( buf );
}

void      tidyBufClear( TidyBuffer* buf )
{
    assert( buf != null );
    if ( buf->bp )
    {
        ClearMemory( buf->bp, buf->allocated );
        buf->size = 0;
    }
    buf->next = 0;
}

/* Avoid thrashing memory by doubling buffer size
** until larger than requested size.
*/
void tidyBufCheckAlloc( TidyBuffer* buf, uint allocSize, uint chunkSize )
{
    assert( buf != null );
    if ( 0 == chunkSize )
        chunkSize = 256;
    if ( allocSize > buf->allocated )
    {
        byte* bp;
        uint allocAmt = chunkSize;
        if ( buf->allocated > 0 )
            allocAmt = buf->allocated;
        while ( allocAmt < allocSize )
            allocAmt *= 2;

        bp = MemRealloc( buf->bp, allocAmt );
        if ( bp != null )
        {
            ClearMemory( bp + buf->allocated, allocAmt - buf->allocated );
            buf->bp = bp;
            buf->allocated = allocAmt;
        }
    }
}

/* Attach buffer to a chunk O' memory w/out allocation */
void      tidyBufAttach( TidyBuffer* buf, void* bp, uint size )
{
    assert( buf != null );
    buf->bp = bp;
    buf->size = buf->allocated = size;
    buf->next = 0;
}

/* Clear pointer to memory w/out deallocation */
void      tidyBufDetach( TidyBuffer* buf )
{
    tidyBufInit( buf );
}


/**************
   OUTPUT
**************/

void      tidyBufAppend( TidyBuffer* buf, void* vp, uint size )
{
    assert( buf != null );
    if ( vp != null && size > 0 )
    {
        tidyBufCheckAlloc( buf, buf->size + size, 0 );
        memcpy( buf->bp + buf->size, vp, size );
        buf->size += size;
    }
}

void      tidyBufPutByte( TidyBuffer* buf, byte bv )
{
    assert( buf != null );
    tidyBufCheckAlloc( buf, buf->size + 1, 0 );
    buf->bp[ buf->size++ ] = bv;
}


int      tidyBufPopByte( TidyBuffer* buf )
{
    int bv = EOF;
    assert( buf != null );
    if ( buf->size > 0 )
      bv = buf->bp[ --buf->size ];
    return bv;
}

/**************
   INPUT
**************/

int       tidyBufGetByte( TidyBuffer* buf )
{
    int bv = EOF;
    if ( ! tidyBufEndOfInput(buf) )
      bv = buf->bp[ buf->next++ ];
    return bv;
}

Bool      tidyBufEndOfInput( TidyBuffer* buf )
{
    return ( buf->next >= buf->size );
}

void      tidyBufUngetByte( TidyBuffer* buf, byte bv )
{
    if ( buf->next > 0 )
    {
        --buf->next;
        assert( bv == buf->bp[ buf->next ] );
    }
}

