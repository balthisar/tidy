#ifndef __TIDYENUM_H__
#define __TIDYENUM_H__

/* tidyenum.h -- Split public enums into separate header

  Simplifies enum re-use in various wrappers.  E.g. SWIG
  generated wrappers and COM IDL files.

  Copyright (c) 1998-2002 World Wide Web Consortium
  (Massachusetts Institute of Technology, Institut National de
  Recherche en Informatique et en Automatique, Keio University).
  All Rights Reserved.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2002/10/15 19:46:52 $ 
    $Revision: 1.1.2.1 $ 

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

#ifdef __cplusplus
extern "C" {
#endif

/* Enumerate configuration options
*/

typedef enum
{
  TidyMarkup,
  TidyDiagnostics,
  TidyPrettyPrint,
  TidyEncoding,
  TidyMiscellaneous
} TidyConfigCategory;


/* Option IDs
**
** Used to get/set option values.
*/

typedef enum
{
  TidyUnknownOption,   /* Unknown! */
  TidyIndentSpaces,    /* indentation n spaces */
  TidyWrapLen,         /* wrap margin */
  TidyTabSize,         /* expand tabs to n spaces */

  TidyCharEncoding,    /* in/out character encoding */
  TidyInCharEncoding,  /* input character encoding (if different) */
  TidyOutCharEncoding, /* output character encoding (if different) */    

  TidyDoctypeMode,     /* see doctype property */
  TidyDoctype,         /* user specified doctype */

  TidyDuplicateAttrs,  /* Keep first or last duplicate attribute */
  TidyAltText,         /* default text for alt attribute */
  TidySlideStyle,      /* style sheet for slides: not used for anything yet */
  TidyErrFile,         /* file name to write errors to */
  TidyWriteBack,       /* if true then output tidied markup */
  TidyShowMarkup,      /* if false, normal output is suppressed */
  TidyShowWarnings,    /* however errors are always shown */
  TidyQuiet,           /* no 'Parsing X', guessed DTD or summary */
  TidyIndentContent,   /* indent content of appropriate tags */
                       /* "auto" does text/block level content indentation */
  TidyHideEndTags,     /* suppress optional end tags */
  TidyXmlTags,         /* treat input as XML */
  TidyXmlOut,          /* create output as XML */
  TidyXhtmlOut,        /* output extensible HTML */
  TidyHtmlOut,         /* output plain HTML, even for XHTML input.
                          Yes means set explicitly. */
  TidyXmlDecl,         /* add <?xml?> for XML docs */
  TidyUpperCaseTags,   /* output tags in upper not lower case */
  TidyUpperCaseAttrs,  /* output attributes in upper not lower case */
  TidyMakeBare,        /* Make bare HTML: remove Microsoft cruft */
  TidyMakeClean,       /* replace presentational clutter by style rules */
  TidyLogicalEmphasis, /* replace i by em and b by strong */
  TidyDropPropAttrs,   /* discard proprietary attributes */
  TidyDropFontTags,    /* discard presentation tags */
  TidyDropEmptyParas,  /* discard empty p elements */
  TidyFixComments,     /* fix comments with adjacent hyphens */
  TidyBreakBeforeBR,   /* o/p newline before <br> or not? */
  TidyBurstSlides,     /* create slides on each h2 element */
  TidyNumEntities,     /* use numeric entities */
  TidyQuoteMarks,      /* output " marks as &quot; */
  TidyQuoteNbsp,       /* output non-breaking space as entity */
  TidyQuoteAmpersand,  /* output naked ampersand as &amp; */
  TidyWrapAttVals,     /* wrap within attribute values */
  TidyWrapScriptlets,  /* wrap within JavaScript string literals */
  TidyWrapSection,     /* wrap within <![ ... ]> section tags */
  TidyWrapAsp,         /* wrap within ASP pseudo elements */
  TidyWrapJste,        /* wrap within JSTE pseudo elements */
  TidyWrapPhp,         /* wrap within PHP pseudo elements */
  TidyFixBackslash,    /* fix URLs by replacing \ with / */
  TidyIndentAttributes,/* newline+indent before each attribute */
  TidyXmlPIs,          /* if set to yes PIs must end with ?> */
  TidyXmlSpace,        /* if set to yes adds xml:space attr as needed */
  TidyEncloseBodyText, /* if yes text at body is wrapped in <p>'s */
  TidyEncloseBlockText,/* if yes text in blocks is wrapped in <p>'s */
  TidyKeepFileTimes,   /* if yes last modied time is preserved */
  TidyWord2000,        /* draconian cleaning for Word2000 */
  TidyMark,            /* add meta element indicating tidied doc */
  TidyEmacs,           /* if true format error output for GNU Emacs */
  TidyEmacsFile,       /* Name of current Emacs file */
  TidyLiteralAttribs,  /* if true attributes may use newlines */
  TidyBodyOnly,        /* output BODY content only */
  TidyFixUri,          /* applies URI encoding if necessary */
  TidyLowerLiterals,   /* folds known attribute values to lower case */
  TidyHideComments,    /* hides all (real) comments in output */
  TidyIndentCdata,     /* indent <!CDATA[ ... ]]> section */
  TidyForceOutput,     /* output document even if errors were found */
  TidyShowErrors,      /* number of errors to put out */
  TidyAsciiChars,      /* convert quotes and dashes to nearest ASCII char */
  TidyJoinClasses,     /* join multiple class attributes */
  TidyJoinStyles,      /* join multiple style attributes */
  TidyEscapeCdata,     /* replace <![CDATA[]]> sections with escaped text */

#if SUPPORT_ASIAN_ENCODINGS
  TidyLanguage,        /* language property: not used for anything yet */
  TidyNCR,             /* allow numeric character references */
#endif
#if SUPPORT_UTF16_ENCODINGS
  TidyOutputBOM,       /* output a Byte Order Mark (BOM) for UTF-16 encodings */
                       /* auto: if input stream has BOM, we output a BOM */
#endif

  TidyReplaceColor,    /* replace hex color attribute values with names */
  TidyCSSPrefix,       /* CSS class naming for -clean option */

  TidyInlineTags,      /* Declared inline tags */
  TidyBlockTags,       /* Declared block tags */
  TidyEmptyTags,       /* Declared empty tags */
  TidyPreTags,         /* Declared pre tags */

  TidyAccessibilityCheckLevel, /* Accessibility check level 
                                  0 (old style), or 1, 2, 3 */

  N_TIDY_OPTIONS       /* Must be last */
} TidyOptionId;


typedef enum
{
  TidyString,
  TidyInteger,
  TidyBoolean
} TidyOptionType;


/* used by ParseBool, ParseTriState, ParseIndent, ParseBOM */
typedef enum
{
   TidyNoState,      /* maps to 'no' */
   TidyYesState,    /* maps to 'yes' */
   TidyAutoState
} TidyTriState;


/* mode controlling treatment of doctype */
typedef enum
{
    TidyDoctypeOmit,
    TidyDoctypeAuto,
    TidyDoctypeStrict,
    TidyDoctypeLoose,
    TidyDoctypeUser
} TidyDoctypeModes;

/* mode controlling treatment of duplicate Attributes */

typedef enum
{
    TidyKeepFirst,
    TidyKeepLast
} TidyDupAttrModes;


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

typedef enum 
{
  TidyInfo,
  TidyWarning,
  TidyConfig,
  TidyAccess,
  TidyError,
  TidyBadDocument,
  TidyFatal
} TidyReportLevel;

typedef enum
{
  TidyContentInput,
  TidyConfigInput
} TidyInputType;

typedef enum
{
  TidyContentOutput,
  TidyDiagnosticOutput
} TidyOutputType;
  

/* Document tree traversal functions
*/

typedef enum 
{
  TidyNode_Root,
  TidyNode_DocType,
  TidyNode_Comment,
  TidyNode_ProcIns,
  TidyNode_Text,
  TidyNode_Start,
  TidyNode_End,
  TidyNode_StartEnd,
  TidyNode_CDATA,
  TidyNode_Section,
  TidyNode_Asp,
  TidyNode_Jste,
  TidyNode_Php,
  TidyNode_XmlDecl
} TidyNodeType;

/* Node interrogation 
*/

typedef enum
{
  TidyTag_UNKNOWN,
  TidyTag_A,
  TidyTag_ABBR,
  TidyTag_ACRONYM,
  TidyTag_ADDRESS,
  TidyTag_ALIGN,
  TidyTag_APPLET,
  TidyTag_AREA,
  TidyTag_B,
  TidyTag_BASE,
  TidyTag_BASEFONT,
  TidyTag_BDO,
  TidyTag_BGSOUND,
  TidyTag_BIG,
  TidyTag_BLINK,
  TidyTag_BLOCKQUOTE,
  TidyTag_BODY,
  TidyTag_BR,
  TidyTag_BUTTON,
  TidyTag_CAPTION,
  TidyTag_CENTER,
  TidyTag_CITE,
  TidyTag_CODE,
  TidyTag_COL,
  TidyTag_COLGROUP,
  TidyTag_COMMENT,
  TidyTag_DD,
  TidyTag_DEL,
  TidyTag_DFN,
  TidyTag_DIR,
  TidyTag_DIV,
  TidyTag_DL,
  TidyTag_DT,
  TidyTag_EM,
  TidyTag_EMBED,
  TidyTag_FIELDSET,
  TidyTag_FONT,
  TidyTag_FORM,
  TidyTag_FRAME,
  TidyTag_FRAMESET,
  TidyTag_H1,
  TidyTag_H2,
  TidyTag_H3,
  TidyTag_H4,
  TidyTag_H5,
  TidyTag_H6,
  TidyTag_HEAD,
  TidyTag_HR,
  TidyTag_HTML,
  TidyTag_I,
  TidyTag_IFRAME,
  TidyTag_ILAYER,
  TidyTag_IMG,
  TidyTag_INPUT,
  TidyTag_INS,
  TidyTag_ISINDEX,
  TidyTag_KBD,
  TidyTag_KEYGEN,
  TidyTag_LABEL,
  TidyTag_LAYER,
  TidyTag_LEGEND,
  TidyTag_LI,
  TidyTag_LINK,
  TidyTag_LISTING,
  TidyTag_MAP,
  TidyTag_MARQUEE,
  TidyTag_MENU,
  TidyTag_META,
  TidyTag_MULTICOL,
  TidyTag_NOBR,
  TidyTag_NOEMBED,
  TidyTag_NOFRAMES,
  TidyTag_NOLAYER,
  TidyTag_NOSAVE,
  TidyTag_NOSCRIPT,
  TidyTag_OBJECT,
  TidyTag_OL,
  TidyTag_OPTGROUP,
  TidyTag_OPTION,
  TidyTag_P,
  TidyTag_PARAM,
  TidyTag_PLAINTEXT,
  TidyTag_PRE,
  TidyTag_Q,
  TidyTag_RB,
  TidyTag_RBC,
  TidyTag_RP,
  TidyTag_RT,
  TidyTag_RTC,
  TidyTag_RUBY,
  TidyTag_S,
  TidyTag_SAMP,
  TidyTag_SCRIPT,
  TidyTag_SELECT,
  TidyTag_SERVER,
  TidyTag_SERVLET,
  TidyTag_SMALL,
  TidyTag_SPACER,
  TidyTag_SPAN,
  TidyTag_STRIKE,
  TidyTag_STRONG,
  TidyTag_STYLE,
  TidyTag_SUB,
  TidyTag_SUP,
  TidyTag_TABLE,
  TidyTag_TBODY,
  TidyTag_TD,
  TidyTag_TEXTAREA,
  TidyTag_TFOOT,
  TidyTag_TH,
  TidyTag_THEAD,
  TidyTag_TITLE,
  TidyTag_TR,
  TidyTag_TT,
  TidyTag_U,
  TidyTag_UL,
  TidyTag_VAR,
  TidyTag_WBR,
  TidyTag_XMP,
  N_TIDY_TAGS   /* Must be last */
} TidyTagId;

/* Attribute interrogation
*/

typedef enum
{
    TidyAttr_UNKNOWN,
    TidyAttr_ABBR,
    TidyAttr_ACCEPT,
    TidyAttr_ACCEPT_CHARSET,
    TidyAttr_ACCESSKEY,
    TidyAttr_ACTION,
    TidyAttr_ADD_DATE,
    TidyAttr_ALIGN,
    TidyAttr_ALINK,
    TidyAttr_ALT,
    TidyAttr_ARCHIVE,
    TidyAttr_AXIS,
    TidyAttr_BACKGROUND,
    TidyAttr_BGCOLOR,
    TidyAttr_BGPROPERTIES,
    TidyAttr_BORDER,
    TidyAttr_BORDERCOLOR,
    TidyAttr_BOTTOMMARGIN,
    TidyAttr_CELLPADDING,
    TidyAttr_CELLSPACING,
    TidyAttr_CHAR,
    TidyAttr_CHAROFF,
    TidyAttr_CHARSET,
    TidyAttr_CHECKED,
    TidyAttr_CITE,
    TidyAttr_CLASS,
    TidyAttr_CLASSID,
    TidyAttr_CLEAR,
    TidyAttr_CODE,
    TidyAttr_CODEBASE,
    TidyAttr_CODETYPE,
    TidyAttr_COLOR,
    TidyAttr_COLS,
    TidyAttr_COLSPAN,
    TidyAttr_COMPACT,
    TidyAttr_CONTENT,
    TidyAttr_COORDS,
    TidyAttr_DATA,
    TidyAttr_DATAFLD,
    TidyAttr_DATAFORMATAS,
    TidyAttr_DATAPAGESIZE,
    TidyAttr_DATASRC,
    TidyAttr_DATETIME,
    TidyAttr_DECLARE,
    TidyAttr_DEFER,
    TidyAttr_DIR,
    TidyAttr_DISABLED,
    TidyAttr_ENCODING,
    TidyAttr_ENCTYPE,
    TidyAttr_FACE,
    TidyAttr_FOR,
    TidyAttr_FRAME,
    TidyAttr_FRAMEBORDER,
    TidyAttr_FRAMESPACING,
    TidyAttr_GRIDX,
    TidyAttr_GRIDY,
    TidyAttr_HEADERS,
    TidyAttr_HEIGHT,
    TidyAttr_HREF,
    TidyAttr_HREFLANG,
    TidyAttr_HSPACE,
    TidyAttr_HTTP_EQUIV,
    TidyAttr_ID,
    TidyAttr_ISMAP,
    TidyAttr_LABEL,
    TidyAttr_LANG,
    TidyAttr_LANGUAGE,
    TidyAttr_LAST_MODIFIED,
    TidyAttr_LAST_VISIT,
    TidyAttr_LEFTMARGIN,
    TidyAttr_LINK,
    TidyAttr_LONGDESC,
    TidyAttr_LOWSRC,
    TidyAttr_MARGINHEIGHT,
    TidyAttr_MARGINWIDTH,
    TidyAttr_MAXLENGTH,
    TidyAttr_MEDIA,
    TidyAttr_METHOD,
    TidyAttr_MULTIPLE,
    TidyAttr_NAME,
    TidyAttr_NOHREF,
    TidyAttr_NORESIZE,
    TidyAttr_NOSHADE,
    TidyAttr_NOWRAP,
    TidyAttr_OBJECT,
    TidyAttr_OnAFTERUPDATE,
    TidyAttr_OnBEFOREUNLOAD,
    TidyAttr_OnBEFOREUPDATE,
    TidyAttr_OnBLUR,
    TidyAttr_OnCHANGE,
    TidyAttr_OnCLICK,
    TidyAttr_OnDATAAVAILABLE,
    TidyAttr_OnDATASETCHANGED,
    TidyAttr_OnDATASETCOMPLETE,
    TidyAttr_OnDBLCLICK,
    TidyAttr_OnERRORUPDATE,
    TidyAttr_OnFOCUS,
    TidyAttr_OnKEYDOWN,
    TidyAttr_OnKEYPRESS,
    TidyAttr_OnKEYUP,
    TidyAttr_OnLOAD,
    TidyAttr_OnMOUSEDOWN,
    TidyAttr_OnMOUSEMOVE,
    TidyAttr_OnMOUSEOUT,
    TidyAttr_OnMOUSEOVER,
    TidyAttr_OnMOUSEUP,
    TidyAttr_OnRESET,
    TidyAttr_OnROWENTER,
    TidyAttr_OnROWEXIT,
    TidyAttr_OnSELECT,
    TidyAttr_OnSUBMIT,
    TidyAttr_OnUNLOAD,
    TidyAttr_PROFILE,
    TidyAttr_PROMPT,
    TidyAttr_RBSPAN,
    TidyAttr_READONLY,
    TidyAttr_REL,
    TidyAttr_REV,
    TidyAttr_RIGHTMARGIN,
    TidyAttr_ROWS,
    TidyAttr_ROWSPAN,
    TidyAttr_RULES,
    TidyAttr_SCHEME,
    TidyAttr_SCOPE,
    TidyAttr_SCROLLING,
    TidyAttr_SELECTED,
    TidyAttr_SHAPE,
    TidyAttr_SHOWGRID,
    TidyAttr_SHOWGRIDX,
    TidyAttr_SHOWGRIDY,
    TidyAttr_SIZE,
    TidyAttr_SPAN,
    TidyAttr_SRC,
    TidyAttr_STANDBY,
    TidyAttr_START,
    TidyAttr_STYLE,
    TidyAttr_SUMMARY,
    TidyAttr_TABINDEX,
    TidyAttr_TARGET,
    TidyAttr_TEXT,
    TidyAttr_TITLE,
    TidyAttr_TOPMARGIN,
    TidyAttr_TYPE,
    TidyAttr_USEMAP,
    TidyAttr_VALIGN,
    TidyAttr_VALUE,
    TidyAttr_VALUETYPE,
    TidyAttr_VERSION,
    TidyAttr_VLINK,
    TidyAttr_VSPACE,
    TidyAttr_WIDTH,
    TidyAttr_WRAP,
    TidyAttr_XML_LANG,
    TidyAttr_XML_SPACE,
    TidyAttr_XMLNS,
    N_TIDY_ATTRIBS      /* Must be last */
} TidyAttrId;

#ifdef __cplusplus
}  /* extern "C" */
#endif
#endif /* __TIDYENUM_H__ */
