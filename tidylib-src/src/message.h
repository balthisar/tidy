#ifndef __MESSAGE_H__
#define __MESSAGE_H__

/* message.h -- general message writing routines

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

*/

#include "forward.h"
#include "tidy.h"  /* For TidyReportLevel */

/* General message writing routines.
** Each message is a single warning, error, etc.
**
** This routine will keep track of counts and,
** if the caller has set a filter, it will be
** called.  The new preferred way of handling
** Tidy diagnostics output is either a) define
** a new output sink or b) install a message
** filter routine.
**
** Keeps track of ShowWarnings, ShowErrors, etc.
*/

ctmbstr ReleaseDate();

/* Reports error at current Lexer line/column. */ 
void message( TidyDocImpl* doc, TidyReportLevel level, ctmbstr msg, ... );

/* Reports error at node line/column. */ 
void messageNode( TidyDocImpl* doc, TidyReportLevel level,
                  Node* node, ctmbstr msg, ... );

/* Reports error at given line/column. */ 
void messageLexer( TidyDocImpl* doc, TidyReportLevel level, 
                   ctmbstr msg, ... );

/* For general reporting.  Emits nothing if --quiet yes */
void tidy_out( TidyDocImpl* doc, ctmbstr msg, ... );


void ShowVersion( TidyDocImpl* doc );
void ReportUnknownOption( TidyDocImpl* doc, ctmbstr option );
void ReportBadArgument( TidyDocImpl* doc, ctmbstr option );
void NeedsAuthorIntervention( TidyDocImpl* doc );
void MissingBody( TidyDocImpl* doc );
void ReportNumberOfSlides( TidyDocImpl* doc, int count );

void HelloMessage( TidyDocImpl* doc, ctmbstr date, ctmbstr filename );
void ReportMarkupVersion( TidyDocImpl* doc );
void ReportNumWarnings( TidyDocImpl* doc );

void HelpText( TidyDocImpl* doc, ctmbstr prog );
void GeneralInfo( TidyDocImpl* doc );
void UnknownOption( TidyDocImpl* doc, char c );
void UnknownFile( TidyDocImpl* doc, ctmbstr program, ctmbstr file );
void FileError( TidyDocImpl* doc, ctmbstr file );

void ErrorSummary( TidyDocImpl* doc );
void ReportEncodingError( TidyDocImpl* doc, uint code, uint c );
void ReportEntityError( TidyDocImpl* doc, uint code, ctmbstr entity, int c );
void ReportAttrError( TidyDocImpl* doc, Node* node, AttVal* av, uint code );
void ReportMissingAttr( TidyDocImpl* doc, Node* node, ctmbstr name );
void ReportWarning( TidyDocImpl* doc, Node* element, Node* node, uint code );
void ReportError( TidyDocImpl* doc, Node* element, Node* node, uint code );

void ReportNonCompliantAttr( TidyDocImpl* doc, Node* node, AttVal* attr, uint versWanted );
void ReportNonCompliantNode( TidyDocImpl* doc, Node* node, uint code, uint versWanted );

/* error codes for entities/numeric character references */

#define MISSING_SEMICOLON       1
#define MISSING_SEMICOLON_NCR   2
#define UNKNOWN_ENTITY          3
#define UNESCAPED_AMPERSAND     4
#define APOS_UNDEFINED          5

/* error codes for element messages */

#define MISSING_ENDTAG_FOR      1
#define MISSING_ENDTAG_BEFORE   2
#define DISCARDING_UNEXPECTED   3
#define NESTED_EMPHASIS         4
#define NON_MATCHING_ENDTAG     5
#define TAG_NOT_ALLOWED_IN      6
#define MISSING_STARTTAG        7
#define UNEXPECTED_ENDTAG       8
#define USING_BR_INPLACE_OF     9
#define INSERTING_TAG           10
#define SUSPECTED_MISSING_QUOTE 11
#define MISSING_TITLE_ELEMENT   12
#define DUPLICATE_FRAMESET      13
#define CANT_BE_NESTED          14
#define OBSOLETE_ELEMENT        15
#define PROPRIETARY_ELEMENT     16
#define UNKNOWN_ELEMENT         17
#define TRIM_EMPTY_ELEMENT      18
#define COERCE_TO_ENDTAG        19
#define ILLEGAL_NESTING         20
#define NOFRAMES_CONTENT        21
#define CONTENT_AFTER_BODY      22
#define INCONSISTENT_VERSION    23
#define MALFORMED_COMMENT       24
#define BAD_COMMENT_CHARS       25
#define BAD_XML_COMMENT         26
#define BAD_CDATA_CONTENT       27
#define INCONSISTENT_NAMESPACE  28
#define DOCTYPE_AFTER_TAGS      29
#define MALFORMED_DOCTYPE       30
#define UNEXPECTED_END_OF_FILE  31
#define DTYPE_NOT_UPPER_CASE    32
#define TOO_MANY_ELEMENTS       33
#define UNESCAPED_ELEMENT       34
#define NESTED_QUOTATION        35
#define ELEMENT_NOT_EMPTY       36
#define ENCODING_IO_CONFLICT    37
#define MIXED_CONTENT_IN_BLOCK  38

/* error codes used for attribute messages */

#define UNKNOWN_ATTRIBUTE       1
#define INSERTING_ATTRIBUTE     2
#define MISSING_ATTR_VALUE      3
#define BAD_ATTRIBUTE_VALUE     4
#define UNEXPECTED_GT           5
#define PROPRIETARY_ATTRIBUTE   6
#define PROPRIETARY_ATTR_VALUE  7
#define REPEATED_ATTRIBUTE      8
#define MISSING_IMAGEMAP        9
#define XML_ATTRIBUTE_VALUE     10
#define UNEXPECTED_QUOTEMARK    11
#define MISSING_QUOTEMARK       12
#define ID_NAME_MISMATCH        13

#define BACKSLASH_IN_URI        14
#define FIXED_BACKSLASH         15
#define ILLEGAL_URI_REFERENCE   16
#define ESCAPED_ILLEGAL_URI     17

#define NEWLINE_IN_URI          18
#define ANCHOR_NOT_UNIQUE       19
#define ENTITY_IN_ID            20
#define JOINING_ATTRIBUTE       21
#define UNEXPECTED_EQUALSIGN    22
#define ATTR_VALUE_NOT_LCASE    23
#define XML_ID_SYNTAX           24

#define INVALID_ATTRIBUTE       25

/* page transition effects */

#define EFFECT_BLEND               -1
#define EFFECT_BOX_IN               0
#define EFFECT_BOX_OUT              1
#define EFFECT_CIRCLE_IN            2
#define EFFECT_CIRCLE_OUT           3
#define EFFECT_WIPE_UP              4
#define EFFECT_WIPE_DOWN            5
#define EFFECT_WIPE_RIGHT           6
#define EFFECT_WIPE_LEFT            7
#define EFFECT_VERT_BLINDS          8
#define EFFECT_HORZ_BLINDS          9
#define EFFECT_CHK_ACROSS          10
#define EFFECT_CHK_DOWN            11
#define EFFECT_RND_DISSOLVE        12
#define EFFECT_SPLIT_VIRT_IN       13
#define EFFECT_SPLIT_VIRT_OUT      14
#define EFFECT_SPLIT_HORZ_IN       15
#define EFFECT_SPLIT_HORZ_OUT      16
#define EFFECT_STRIPS_LEFT_DOWN    17
#define EFFECT_STRIPS_LEFT_UP      18
#define EFFECT_STRIPS_RIGHT_DOWN   19
#define EFFECT_STRIPS_RIGHT_UP     20
#define EFFECT_RND_BARS_HORZ       21
#define EFFECT_RND_BARS_VERT       22
#define EFFECT_RANDOM              23

/* accessibility flaws */

#define MISSING_IMAGE_ALT       1
#define MISSING_LINK_ALT        2
#define MISSING_SUMMARY         4
#define MISSING_IMAGE_MAP       8
#define USING_FRAMES            16
#define USING_NOFRAMES          32

/* presentation flaws */

#define USING_SPACER            1
#define USING_LAYER             2
#define USING_NOBR              4
#define USING_FONT              8
#define USING_BODY              16

/* character encoding errors */
/* "or" DISCARDED_CHAR with the other errors if discarding char;
** otherwise default is replacing
*/
#define REPLACED_CHAR           0
#define DISCARDED_CHAR          1

#define VENDOR_SPECIFIC_CHARS   2
#define INVALID_SGML_CHARS      4
#define INVALID_UTF8            8
#define INVALID_UTF16           16
#define ENCODING_MISMATCH       32 /* fatal error */
#define INVALID_URI             64
#define INVALID_NCR             128

#endif /* __MESSAGE_H__ */
