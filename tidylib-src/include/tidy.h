#ifndef __TIDY_H__
#define __TIDY_H__

/* tidy.h -- Defines HTML Tidy API implemented by tidy library.

  Public interface is const-correct and doesn't explicitly depend
  on any globals.  Thus, thread-safety may be introduced w/out
  changing the interface.

  Looking ahead to a C++ wrapper, C functions always pass 
  this-equivalent as 1st arg.


  Copyright (c) 1998-2002 World Wide Web Consortium
  (Massachusetts Institute of Technology, Institut National de
  Recherche en Informatique et en Automatique, Keio University).
  All Rights Reserved.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2002/10/15 19:46:52 $ 
    $Revision: 1.1.2.10 $ 

  Contributing Author(s):

     Dave Raggett <dsr@w3.org>

  The contributing author(s) would like to thank all those who
  helped with testing, bug fixes and suggestions for improvements. 
  This wouldn't have been possible without your help.

  COPYRIGHT NOTICE:
 
  This software and documentation is provided "as is," and
  the copyright holders and contributing author(s) make no
  representations or warranties, express or implied, including
  but not limited to, warranties of merchantability or fitness
  for any particular purpose or that the use of the software or
  documentation will not infringe any third party patents,
  copyrights, trademarks or other rights. 

  The copyright holders and contributing author(s) will not be held
  liable for any direct, indirect, special or consequential damages
  arising out of any use of the software or documentation, even if
  advised of the possibility of such damage.

  Permission is hereby granted to use, copy, modify, and distribute
  this source code, or portions hereof, documentation and executables,
  for any purpose, without fee, subject to the following restrictions:

  1. The origin of this source code must not be misrepresented.
  2. Altered versions must be plainly marked as such and must
     not be misrepresented as being the original source.
  3. This Copyright notice may not be removed or altered from any
     source or altered source distribution.
 
  The copyright holders and contributing author(s) specifically
  permit, without fee, and encourage the use of this source code
  as a component for supporting the Hypertext Markup Language in
  commercial products. If you use this source code in a product,
  acknowledgment is not required but would be appreciated.


  Created 2001-05-20 by Charles Reitzel
  Updated 2002-07-01 by Charles Reitzel - 1st Implementation

*/

#include "platform.h"
#include "tidyenum.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque data structures.
*  Cast to implementation types within lib.
*  Reduces inter-dependencies/conflicts w/ application code.
*/
opaque( TidyDoc );
opaque( TidyOption );
opaque( TidyNode );
opaque( TidyAttr );

TIDY_STRUCT struct _TidyBuffer;
typedef struct _TidyBuffer TidyBuffer;

/* Tidy public interface
**
** Most functions return an integer:
**
** 0    -> SUCCESS
** >0   -> WARNING
** <0   -> ERROR
** 
*/

TIDY_EXPORT TidyDoc     tidyCreate();
TIDY_EXPORT void        tidyRelease( TidyDoc tdoc );

/* Let application store a chunk of data w/ each Tidy instance.
** Useful for callbacks.
*/
TIDY_EXPORT void        tidySetAppData( TidyDoc tdoc, uint appData );
TIDY_EXPORT uint        tidyGetAppData( TidyDoc tdoc );

TIDY_EXPORT ctmbstr     tidyReleaseDate();

/* Diagnostics and Repair */
TIDY_EXPORT int         tidyStatus( TidyDoc tdoc );
TIDY_EXPORT int         tidyDetectedHtmlVersion( TidyDoc tdoc ); /* 0, 2, 3 or 4 */
TIDY_EXPORT Bool        tidyDetectedXhtml( TidyDoc tdoc );
TIDY_EXPORT Bool        tidyDetectedGenericXml( TidyDoc tdoc );

TIDY_EXPORT uint        tidyErrorCount( TidyDoc tdoc );
TIDY_EXPORT uint        tidyWarningCount( TidyDoc tdoc );
TIDY_EXPORT uint        tidyAccessWarningCount( TidyDoc tdoc );
TIDY_EXPORT uint        tidyConfigErrorCount( TidyDoc tdoc );

/* Get/Set configuration options
*/
TIDY_EXPORT int         tidyLoadConfig( TidyDoc tdoc, ctmbstr configFile );
TIDY_EXPORT int         tidyLoadConfigEnc( TidyDoc tdoc,
                               ctmbstr configFile, ctmbstr charenc );

TIDY_EXPORT int         tidySetCharEncoding( TidyDoc tdoc, ctmbstr encnam );

/* Enumerate configuration options
*/

TIDY_EXPORT TidyOptionId  tidyOptGetIdForName( ctmbstr optnam );

TIDY_EXPORT TidyIterator  tidyGetOptionList( TidyDoc tdoc );
TIDY_EXPORT TidyOption    tidyGetNextOption( TidyDoc tdoc, TidyIterator* pos );

TIDY_EXPORT TidyOption    tidyGetOption( TidyDoc tdoc, TidyOptionId optId );
TIDY_EXPORT TidyOption    tidyGetOptionByName( TidyDoc tdoc, ctmbstr optnam );

TIDY_EXPORT TidyOptionId  tidyOptGetId( TidyOption opt );
TIDY_EXPORT ctmbstr       tidyOptGetName( TidyOption opt );
TIDY_EXPORT TidyOptionType tidyOptGetType( TidyOption opt );
TIDY_EXPORT Bool          tidyOptIsReadOnly( TidyOption opt );
TIDY_EXPORT TidyConfigCategory tidyOptGetCategory( TidyOption opt );
TIDY_EXPORT ctmbstr       tidyOptGetDefault( TidyOption opt );
TIDY_EXPORT uint          tidyOptGetDefaultInt( TidyOption opt );
TIDY_EXPORT Bool          tidyOptGetDefaultBool( TidyOption opt );

TIDY_EXPORT TidyIterator  tidyOptGetPickList( TidyOption opt );
TIDY_EXPORT ctmbstr       tidyOptGetNextPick( TidyOption opt, TidyIterator* pos );

TIDY_EXPORT ctmbstr       tidyOptGetValue( TidyDoc tdoc, TidyOptionId optId );
TIDY_EXPORT Bool          tidyOptSetValue( TidyDoc tdoc, TidyOptionId optId, ctmbstr val );
TIDY_EXPORT Bool          tidyOptParseValue( TidyDoc tdoc, ctmbstr optnam, ctmbstr val );

TIDY_EXPORT uint          tidyOptGetInt( TidyDoc tdoc, TidyOptionId optId );
TIDY_EXPORT Bool          tidyOptSetInt( TidyDoc tdoc, TidyOptionId optId, uint val );

TIDY_EXPORT Bool          tidyOptGetBool( TidyDoc tdoc, TidyOptionId optId );
TIDY_EXPORT Bool          tidyOptSetBool( TidyDoc tdoc, TidyOptionId optId, Bool val );

TIDY_EXPORT Bool          tidyOptResetToDefault( TidyDoc tdoc, TidyOptionId opt );
TIDY_EXPORT Bool          tidyOptResetAllToDefault( TidyDoc tdoc );

/* reset to config (after document processing) */
TIDY_EXPORT Bool          tidyOptSnapshot( TidyDoc tdoc );
TIDY_EXPORT Bool          tidyOptResetToSnapshot( TidyDoc tdoc );

TIDY_EXPORT Bool          tidyOptDiffThanDefault( TidyDoc tdoc );
TIDY_EXPORT Bool          tidyOptDiffThanSnapshot( TidyDoc tdoc );

TIDY_EXPORT Bool          tidyOptCopyConfig( TidyDoc tdocTo, TidyDoc tdocFrom );

TIDY_EXPORT ctmbstr       tidyOptGetEncName( TidyDoc tdoc, TidyOptionId optId );
TIDY_EXPORT ctmbstr       tidyOptGetCurrPick( TidyDoc tdoc, TidyOptionId optId);

TIDY_EXPORT TidyIterator  tidyOptGetDeclTagList( TidyDoc tdoc );
TIDY_EXPORT ctmbstr       tidyOptGetNextDeclTag( TidyDoc tdoc, 
                                                 TidyOptionId optId,
                                                 TidyIterator* iter );

/* I/O and Message handling interface
**
** By default, Tidy will define, create and use 
** instances of input and output handlers for 
** standard C buffered I/O (i.e. FILE* stdin,
** FILE* stdout and FILE* stderr for content
** input, content output and diagnostic output,
** respectively.  A FILE* cfgFile input handler
** will be used for config files.  Command line
** options will just be set directly.
*/

/*****************
   Input Source
*****************/
typedef int  (*TidyGetByteFunc)( uint sourceData );
typedef void (*TidyUngetByteFunc)( uint sourceData, byte bt );
typedef Bool (*TidyEOFFunc)( uint sourceData );

#define EndOfStream (~0u)

TIDY_STRUCT
typedef struct _TidyInputSource
{
  /* Instance data */
  uint                sourceData;

  /* Methods */
  TidyGetByteFunc     getByte;
  TidyUngetByteFunc   ungetByte;
  TidyEOFFunc         eof;
} TidyInputSource;

/* Facilitates user defined source by providing
** an entry point to marshal pointers-to-functions.
** Needed by .NET and possibly other language bindings.
*/
TIDY_EXPORT Bool tidyInitSource( TidyInputSource*  source,
                                 void*             srcData,
                                 TidyGetByteFunc   gbFunc,
                                 TidyUngetByteFunc ugbFunc,
                                 TidyEOFFunc       endFunc );

TIDY_EXPORT uint tidyGetByte( TidyInputSource* source );
TIDY_EXPORT void tidyUngetByte( TidyInputSource* source, uint byteValue );
TIDY_EXPORT Bool tidyIsEOF( TidyInputSource* source );


/****************
   Output Sink
****************/
typedef void (*TidyPutByteFunc)( uint sinkData, byte bt );

TIDY_STRUCT
typedef struct _TidyOutputSink
{
  /* Instance data */
  uint                sinkData; 

  /* Methods */
  TidyPutByteFunc     putByte;
} TidyOutputSink;

/* Facilitates user defined sinks by providing
** an entry point to marshal pointers-to-functions.
** Needed by .NET and possibly other language bindings.
*/
TIDY_EXPORT Bool tidyInitSink( TidyOutputSink* sink, 
                               void*           snkData,
                               TidyPutByteFunc pbFunc );
TIDY_EXPORT void tidyPutByte( TidyOutputSink* sink, uint byteValue );


/* Use TidyReportFilter to filter messages by diagnostic level:
** info, warning, etc.  Just set diagnostic output 
** handler to redirect all diagnostics output.  Return true
** to proceed with output, false to cancel.
*/
typedef Bool (*TidyReportFilter)( TidyDoc tdoc,
                                  TidyReportLevel lvl, uint line, uint col, ctmbstr mssg );

TIDY_EXPORT Bool    tidySetReportFilter( TidyDoc tdoc,
                                         TidyReportFilter filtCallback );


TIDY_EXPORT FILE*   tidySetErrorFile( TidyDoc tdoc, ctmbstr errfilnam );
TIDY_EXPORT int     tidySetErrorBuffer( TidyDoc tdoc, TidyBuffer* errbuf );
TIDY_EXPORT int     tidySetErrorSink( TidyDoc tdoc, TidyOutputSink* sink );


/* By default, Tidy will use its own wrappers
** around standard C malloc/free calls. 
** These wrappers will abort upon any failures.
** If any are set, all must be set.
** Pass NULL to clear previous setting.
**
** May be used to set environment-specific allocators
** such as used by web server plugins, etc.
*/
typedef void* (*TidyMalloc)( size_t len );
typedef void* (*TidyRealloc)( void* buf, size_t len );
typedef void  (*TidyFree)( void* buf );
typedef void  (*TidyPanic)( ctmbstr mssg );

TIDY_EXPORT Bool        tidySetMallocCall( TidyMalloc fmalloc );
TIDY_EXPORT Bool        tidySetReallocCall( TidyRealloc frealloc );
TIDY_EXPORT Bool        tidySetFreeCall( TidyFree ffree );
TIDY_EXPORT Bool        tidySetPanicCall( TidyPanic fpanic );

/* TODO: Catalog all messages for easy translation
TIDY_EXPORT ctmbstr     tidyLookupMessage( int errorNo );
*/



/* Parse/load Functions
**
** HTML/XHTML version determined from input.
*/

TIDY_EXPORT int         tidyParseFile( TidyDoc tdoc, ctmbstr filename );
TIDY_EXPORT int         tidyParseStdin( TidyDoc tdoc );
TIDY_EXPORT int         tidyParseString( TidyDoc tdoc, ctmbstr content );
TIDY_EXPORT int         tidyParseBuffer( TidyDoc tdoc, TidyBuffer* buf );
TIDY_EXPORT int         tidyParseSource( TidyDoc tdoc, TidyInputSource* source );

/* Diagnostics and Repair */
TIDY_EXPORT int         tidyCleanAndRepair( TidyDoc tdoc );
TIDY_EXPORT int         tidyRunDiagnostics( TidyDoc tdoc );

/* Document save Functions
**
** If buffer is not big enough, ENOMEM will be returned and
** the necessary buffer size will be placed in *buflen.
*/
TIDY_EXPORT int         tidySaveFile( TidyDoc tdoc, ctmbstr filename );
TIDY_EXPORT int         tidySaveStdout( TidyDoc tdoc );
TIDY_EXPORT int         tidySaveBuffer( TidyDoc tdoc, TidyBuffer* buf );
TIDY_EXPORT int         tidySaveString( TidyDoc tdoc, tmbstr buffer, uint* buflen );
TIDY_EXPORT int         tidySaveSink( TidyDoc tdoc, TidyOutputSink* sink );

/* Save Config
*/
TIDY_EXPORT int         tidyOptSaveFile( TidyDoc tdoc, ctmbstr cfgfil );
TIDY_EXPORT int         tidyOptSaveSink( TidyDoc tdoc, TidyOutputSink* sink );

/* Error reporting functions 
*/
TIDY_EXPORT void        tidyErrorSummary( TidyDoc tdoc );
TIDY_EXPORT void        tidyGeneralInfo( TidyDoc tdoc );


/* Document tree traversal functions
*/

TIDY_EXPORT TidyNode    tidyGetRoot( TidyDoc tdoc );
TIDY_EXPORT TidyNode    tidyGetHtml( TidyDoc tdoc );
TIDY_EXPORT TidyNode    tidyGetHead( TidyDoc tdoc );
TIDY_EXPORT TidyNode    tidyGetBody( TidyDoc tdoc );

/* parent / child */
TIDY_EXPORT TidyNode    tidyGetParent( TidyNode tnod );
TIDY_EXPORT TidyNode    tidyGetChild( TidyNode tnod );

/* siblings */
TIDY_EXPORT TidyNode    tidyGetNext( TidyNode tnod );
TIDY_EXPORT TidyNode    tidyGetPrev( TidyNode tnod );

/* Node info */
TIDY_EXPORT TidyNodeType tidyNodeGetType( TidyNode tnod );
TIDY_EXPORT ctmbstr     tidyNodeGetName( TidyNode tnod );

/* Null for non-element nodes and all pure HTML
TIDY_EXPORT ctmbstr     tidyNodeNsLocal( TidyNode tnod );
TIDY_EXPORT ctmbstr     tidyNodeNsPrefix( TidyNode tnod );
TIDY_EXPORT ctmbstr     tidyNodeNsUri( TidyNode tnod );
*/

/* Iterate over attribute values */
TIDY_EXPORT TidyAttr    tidyAttrFirst( TidyNode tnod );
TIDY_EXPORT TidyAttr    tidyAttrNext( TidyAttr tattr );

TIDY_EXPORT ctmbstr     tidyAttrName( TidyAttr tattr );
TIDY_EXPORT ctmbstr     tidyAttrValue( TidyAttr tattr );

/* Null for pure HTML
TIDY_EXPORT ctmbstr     tidyAttrNsLocal( TidyAttr tattr );
TIDY_EXPORT ctmbstr     tidyAttrNsPrefix( TidyAttr tattr );
TIDY_EXPORT ctmbstr     tidyAttrNsUri( TidyAttr tattr );
*/



/* Node interrogation 
*/

TIDY_EXPORT Bool tidyNodeIsText( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsProp( TidyDoc tdoc, TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsHeader( TidyNode tnod ); /* h1, h2, ... */

TIDY_EXPORT Bool tidyNodeHasText( TidyDoc tdoc, TidyNode tnod );
TIDY_EXPORT Bool tidyNodeGetText( TidyDoc tdoc, TidyNode tnod, TidyBuffer* buf );

TIDY_EXPORT TidyTagId tidyNodeGetId( TidyNode tnod );

TIDY_EXPORT Bool tidyNodeIsHTML( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsHEAD( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsTITLE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBASE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsMETA( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBODY( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsFRAMESET( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsFRAME( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsIFRAME( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsNOFRAMES( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsHR( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsH1( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsH2( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsPRE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsLISTING( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsP( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsUL( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsOL( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsDL( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsDIR( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsLI( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsDT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsDD( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsTABLE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsCAPTION( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsTD( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsTH( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsTR( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsCOL( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsCOLGROUP( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBR( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsA( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsLINK( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsB( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsI( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSTRONG( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsEM( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBIG( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSMALL( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsPARAM( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsOPTION( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsOPTGROUP( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsIMG( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsMAP( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsAREA( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsNOBR( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsWBR( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsFONT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsLAYER( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSPACER( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsCENTER( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSTYLE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSCRIPT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsNOSCRIPT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsFORM( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsTEXTAREA( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBLOCKQUOTE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsAPPLET( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsOBJECT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsDIV( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSPAN( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsINPUT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsQ( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsLABEL( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsH3( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsH4( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsH5( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsH6( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsADDRESS( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsXMP( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSELECT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBLINK( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsMARQUEE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsEMBED( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsBASEFONT( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsISINDEX( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsS( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsSTRIKE( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsU( TidyNode tnod );
TIDY_EXPORT Bool tidyNodeIsMENU( TidyNode tnod );


/* Attribute interrogation
*/

TIDY_EXPORT TidyAttrId tidyAttrGetId( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsEvent( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsProp( TidyAttr tattr );

TIDY_EXPORT Bool tidyAttrIsHREF( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsSRC( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsID( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsNAME( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsSUMMARY( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsALT( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsLONGDESC( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsUSEMAP( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsISMAP( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsLANGUAGE( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsTYPE( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsVALUE( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsCONTENT( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsTITLE( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsXMLNS( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsDATAFLD( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsWIDTH( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsHEIGHT( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsFOR( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsSELECTED( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsCHECKED( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsLANG( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsTARGET( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsHTTP_EQUIV( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsREL( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnMOUSEMOVE( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnMOUSEDOWN( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnMOUSEUP( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnCLICK( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnMOUSEOVER( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnMOUSEOUT( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnKEYDOWN( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnKEYUP( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnKEYPRESS( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnFOCUS( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsOnBLUR( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsBGCOLOR( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsLINK( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsALINK( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsVLINK( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsTEXT( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsSTYLE( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsABBR( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsCOLSPAN( TidyAttr tattr );
TIDY_EXPORT Bool tidyAttrIsROWSPAN( TidyAttr tattr );

/* Attribute retrieval
*/

TIDY_EXPORT TidyAttr tidyAttrGetHREF( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetSRC( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetID( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetNAME( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetSUMMARY( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetALT( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetLONGDESC( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetUSEMAP( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetISMAP( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetLANGUAGE( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetTYPE( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetVALUE( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetCONTENT( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetTITLE( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetXMLNS( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetDATAFLD( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetWIDTH( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetHEIGHT( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetFOR( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetSELECTED( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetCHECKED( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetLANG( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetTARGET( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetHTTP_EQUIV( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetREL( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnMOUSEMOVE( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnMOUSEDOWN( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnMOUSEUP( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnCLICK( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnMOUSEOVER( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnMOUSEOUT( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnKEYDOWN( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnKEYUP( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnKEYPRESS( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnFOCUS( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetOnBLUR( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetBGCOLOR( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetLINK( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetALINK( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetVLINK( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetTEXT( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetSTYLE( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetABBR( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetCOLSPAN( TidyNode tnod );
TIDY_EXPORT TidyAttr tidyAttrGetROWSPAN( TidyNode tnod );

#ifdef __cplusplus
}  /* extern "C" */
#endif
#endif /* __TIDY_H__ */
