#ifndef __TIDY_INT_H__
#define __TIDY_INT_H__

/* tidy-int.h -- internal library declarations

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:11 $ 
    $Revision: 1.2 $ 

*/

#include "tidy.h"
#include "config.h"
#include "tags.h"
#include "attrs.h"
#include "lexer.h"
#include "pprint.h"
#include "access.h"

#ifndef MAX
#define MAX(a,b) (((a) > (b))?(a):(b))
#endif
#ifndef MIN
#define MIN(a,b) (((a) < (b))?(a):(b))
#endif

struct _TidyDocImpl
{
    /* Config + Markup Declarations */
    TidyConfigImpl      config;
    TidyTagImpl         tags;
    TidyAttribImpl      attribs;

#if SUPPORT_ACCESSIBILITY_CHECKS
    /* Accessibility Checks state */
    TidyAccessImpl      access;
#endif

    /* The Pretty Print buffer */
    TidyPrintImpl       pprint;

    /* The Document Tree (and backing store buffer) */
    Node*               root;
    Lexer*              lexer;

    /* I/O */
    StreamIn*           docIn;
    StreamOut*          docOut;
    StreamOut*          errout;
    TidyReportFilter    mssgFilt;
    TidyOptCallback     pOptCallback;

    /* Parse + Repair Results */
    uint                optionErrors;
    uint                errors;
    uint                warnings;
    uint                accessErrors;
    uint                infoMessages;
    uint                docErrors;
    int                 parseStatus;

    uint                badAccess;   /* for accessibility errors */
    uint                badLayout;   /* for bad style errors */
    uint                badChars;    /* for bad char encodings */
    uint                badForm;     /* for badly placed form tags */

    /* Miscellaneous */
    uint                appData;
    uint                nClassId;
    Bool                inputHadBOM;

#if PRESERVE_FILE_TIMES
    struct utimbuf      filetimes;
#endif
    Node*               givenDoctype;
};


/* Twizzle internal/external types */
#ifdef NEVER
TidyDocImpl* tidyDocToImpl( TidyDoc tdoc );
TidyDoc      tidyImplToDoc( TidyDocImpl* impl );

Node*        tidyNodeToImpl( TidyNode tnod );
TidyNode     tidyImplToNode( Node* node );

AttVal*      tidyAttrToImpl( TidyAttr tattr );
TidyAttr     tidyImplToAttr( AttVal* attval );

const TidyOptionImpl* tidyOptionToImpl( TidyOption topt );
TidyOption   tidyImplToOption( const TidyOptionImpl* option );
#else

#define tidyDocToImpl( tdoc )       ((TidyDocImpl*)(tdoc))
#define tidyImplToDoc( doc )        ((TidyDoc)(doc))

#define tidyNodeToImpl( tnod )      ((Node*)(tnod))
#define tidyImplToNode( node )      ((TidyNode)(node))

#define tidyAttrToImpl( tattr )     ((AttVal*)(tattr))
#define tidyImplToAttr( attval )    ((TidyAttr)(attval))

#define tidyOptionToImpl( topt )    ((const TidyOptionImpl*)(topt))
#define tidyImplToOption( option )  ((TidyOption)(option))

#endif

/* Create/Destroy a Tidy "document" object */
TidyDocImpl* tidyDocCreate();
void         tidyDocRelease( TidyDocImpl* impl );

int          tidyDocStatus( TidyDocImpl* impl );

/* Parse Markup */
int          tidyDocParseFile( TidyDocImpl* impl, ctmbstr htmlfil );
int          tidyDocParseStdin( TidyDocImpl* impl );
int          tidyDocParseString( TidyDocImpl* impl, ctmbstr content );
int          tidyDocParseBuffer( TidyDocImpl* impl, TidyBuffer* inbuf );
int          tidyDocParseSource( TidyDocImpl* impl, TidyInputSource* docIn );
int          tidyDocParseStream( TidyDocImpl* impl, StreamIn* in );


/* Execute post-parse diagnostics and cleanup.
** Note, the order is important.  You will get different
** results from the diagnostics depending on if they are run
** pre-or-post repair.
*/
int          tidyDocRunDiagnostics( TidyDocImpl* doc );
int          tidyDocCleanAndRepair( TidyDocImpl* doc );


/* Save cleaned up file to file/buffer/sink */
int          tidyDocSaveFile( TidyDocImpl* impl, ctmbstr htmlfil );
int          tidyDocSaveStdout( TidyDocImpl* impl );
int          tidyDocSaveString( TidyDocImpl* impl, tmbstr buffer, uint* buflen );
int          tidyDocSaveBuffer( TidyDocImpl* impl, TidyBuffer* outbuf );
int          tidyDocSaveSink( TidyDocImpl* impl, TidyOutputSink* docOut );
int          tidyDocSaveStream( TidyDocImpl* impl, StreamOut* out );

#endif /* __TIDY_INT_H__ */
