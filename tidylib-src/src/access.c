/* access.c -- carry out accessibility checks

  Copyright University of Toronto
  Portions (c) 1998-2003 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:09 $ 
    $Revision: 1.4 $ 

*/

/*********************************************************************
* AccessibilityChecks
*
* Carries out processes for all accessibility checks.  Traverses
* through all the content within the tree and evaluates the tags for
* accessibility.
*
* To perform the following checks, 'AccessibilityChecks' must be
* called AFTER the tree structure has been formed.
*
* If, in the command prompt, there is no specification of which
* accessibility priorities to check, no accessibility checks will be 
* performed.  (ie. '1' for priority 1, '2' for priorities 1 and 2, 
*                  and '3') for priorities 1, 2 and 3.)
*
* Copyright University of Toronto
* Programmed by: Mike Lam and Chris Ridpath
* Modifications by : Terry Teague (TRT)
*
*********************************************************************/

#include "tidy-int.h"

#if SUPPORT_ACCESSIBILITY_CHECKS

#include "access.h"
#include "message.h"
#include "tags.h"
#include "attrs.h"
#include "tmbstr.h"


/* 
    The accessibility checks to perform depending on user's desire.

    1. priority 1
    2. priority 1 & 2
    3. priority 1, 2, & 3
*/

/* List of possible image types */
static const ctmbstr imageExtensions[] =
{".jpg", ".gif", ".tif", ".pct", ".pic", ".iff", ".dib",
 ".tga", ".pcx", ".png", ".jpeg", ".tiff", ".bmp"};

#define N_IMAGE_EXTS (sizeof(imageExtensions)/sizeof(ctmbstr))

/* List of possible sound file types */
static const ctmbstr soundExtensions[] =
{".wav", ".au", ".aiff", ".snd", ".ra", ".rm"};

static const int soundExtErrCodes[] = 
{
    AUDIO_MISSING_TEXT_WAV,
    AUDIO_MISSING_TEXT_AU,
    AUDIO_MISSING_TEXT_AIFF,
    AUDIO_MISSING_TEXT_SND,
    AUDIO_MISSING_TEXT_RA,
    AUDIO_MISSING_TEXT_RM
};

#define N_AUDIO_EXTS (sizeof(soundExtensions)/sizeof(ctmbstr))

/* List of possible media extensions */
static const ctmbstr mediaExtensions[] = 
{".mpg", ".mov", ".asx", ".avi", ".ivf", ".m1v", ".mmm", ".mp2v",
 ".mpa", ".mpe", ".mpeg", ".ram", ".smi", ".smil", ".swf",
 ".wm", ".wma", ".wmv"};

#define N_MEDIA_EXTS (sizeof(mediaExtensions)/sizeof(ctmbstr))

/* List of possible frame sources */
static const ctmbstr frameExtensions[] =
{".htm", ".html", ".shtm", ".shtml", ".cfm", ".cfml",
".asp", ".cgi", ".pl", ".smil"};

#define N_FRAME_EXTS (sizeof(frameExtensions)/sizeof(ctmbstr))

/* List of possible colour values */
static const int colorValues[][3] =
{
  {  0,  0,  0},
  {128,128,128},
  {192,192,192},
  {255,255,255},
  {192,  0,  0},
  {255,  0,  0},
  {128,  0,128},
  {255,  0,255},
  {  0,128,  0},
  {  0,255,  0},
  {128,128,  0},
  {255,255,  0},  
  {  0,  0,128},
  {  0,  0,255},
  {  0,128,128},
  {  0,255,255}
};

#define N_COLOR_VALS (sizeof(colorValues)/(sizeof(int[3]))

/* These arrays are used to convert color names to their RGB values */
static const ctmbstr colorNames[] =
{
  "black",
  "silver",
  "grey",
  "white",
  "maroon",
  "red",
  "purple",
  "fuchsia",
  "green",
  "lime",
  "olive",
  "yellow", 
  "navy",
  "blue",
  "teal",
  "aqua"
};

#define N_COLOR_NAMES (sizeof(colorNames)/sizeof(ctmbstr))
#define N_COLORS N_COLOR_NAMES


/* 
    List of error/warning messages.  The error code corresponds to
    the check that is listed in the AERT (HTML specifications).
*/
static const ctmbstr errorMsgs[] =  
{
    "[1.1.1.1]: <img> missing 'alt' text.",
    "[1.1.1.2]: suspicious 'alt' text (filename).",
    "[1.1.1.3]: suspicious 'alt' text (file size).",
    "[1.1.1.4]: suspicious 'alt' text (placeholder).",
    "[1.1.1.10]: suspicious 'alt' text (too long).",
    "[1.1.1.11]: <img> missing 'alt' text (bullet).",
    "[1.1.1.12]: <img> missing 'alt' text (horizontal rule).",
    "[1.1.2.1]: <img> missing 'longdesc' and d-link.",
    "[1.1.2.2]: <img> missing d-link.",
    "[1.1.2.3]: <img> missing 'longdesc'.",
    "[1.1.2.5]: 'longdesc' not required.",
    "[1.1.3.1]: <img> (button) missing 'alt' text.", 
    "[1.1.4.1]: <applet> missing alternate content.",
    "[1.1.5.1]: <object> missing alternate content.",
    "[1.1.6.1]: audio missing text transcript (wav).",
    "[1.1.6.2]: audio missing text transcript (au).",
    "[1.1.6.3]: audio missing text transcript (aiff).",
    "[1.1.6.4]: audio missing text transcript (snd).",
    "[1.1.6.5]: audio missing text transcript (ra).",
    "[1.1.6.6]: audio missing text transcript (rm).",
    "[1.1.8.1]: <frame> may require 'longdesc'.",
    "[1.1.9.1]: <area> missing 'alt' text.",
    "[1.1.10.1]: <script> missing <noscript> section.",
    "[1.1.12.1]: ascii art requires description.",
    "[1.2.1.1]: image map (server-side) requires text links.",
    "[1.4.1.1]: multimedia requires synchronized text equivalents.", 
    "[1.5.1.1]: image map (client-side) missing text links.",
    "[2.1.1.1]: ensure information not conveyed through color alone (image).",
    "[2.1.1.2]: ensure information not conveyed through color alone (applet).",
    "[2.1.1.3]: ensure information not conveyed through color alone (object).",
    "[2.1.1.4]: ensure information not conveyed through color alone (script).",
    "[2.1.1.5]: ensure information not conveyed through color alone (input).",
    "[2.2.1.1]: poor color contrast (text).",
    "[2.2.1.2]: poor color contrast (link).",
    "[2.2.1.3]: poor color contrast (active link).",
    "[2.2.1.4]: poor color contrast (visited link).",
    "[3.2.1.1]: <doctype> missing.",
    "[3.3.1.1]: use style sheets to control presentation.",
    "[3.5.1.1]: headers improperly nested.",
    "[3.5.2.1]: potential header (bold).",
    "[3.5.2.2]: potential header (italics).",
    "[3.5.2.3]: potential header (underline).",
    "[3.5.3.1]: header used to format text.",
    "[3.6.1.1]: list usage invalid <ul>.",
    "[3.6.1.2]: list usage invalid <ol>.",
    "[3.6.1.4]: list usage invalid <li>.",
    "[4.1.1.1]: indicate changes in language.",
    "[4.3.1.1]: language not identified.",
    "[4.3.1.2]: language attribute invalid.",
    "[5.1.2.1]: data <table> missing row/column headers (all).",
    "[5.1.2.2]: data <table> missing row/column headers (1 col).",
    "[5.1.2.3]: data <table> missing row/column headers (1 row).",
    "[5.2.1.1]: data <table> may require markup (column headers).",
    "[5.2.1.2]: data <table> may require markup (row headers).",
    "[5.3.1.1]: verify layout tables linearize properly.",
    "[5.4.1.1]: invalid markup used in layout <table>.",
    "[5.5.1.1]: <table> missing summary.",
    "[5.5.1.2]: <table> summary invalid (null).",
    "[5.5.1.3]: <table> summary invalid (spaces).",
    "[5.5.1.6]: <table> summary invalid (placeholder text).",
    "[5.5.2.1]: <table> missing <caption>.",
    "[5.6.1.1]: <table> may require header abbreviations.",
    "[5.6.1.2]: <table> header abbreviations invalid (null).",
    "[5.6.1.3]: <table> header abbreviations invalid (spaces).",
    "[6.1.1.1]: style sheets require testing (link).",
    "[6.1.1.2]: style sheets require testing (style element).",
    "[6.1.1.3]: style sheets require testing (style attribute).",
    "[6.2.1.1]: <frame> source invalid.",
    "[6.2.2.1]: text equivalents require updating (applet).",
    "[6.2.2.2]: text equivalents require updating (script).",
    "[6.2.2.3]: text equivalents require updating (object).",
    "[6.3.1.1]: programmatic objects require testing (script).",
    "[6.3.1.2]: programmatic objects require testing (object).",
    "[6.3.1.3]: programmatic objects require testing (embed).",
    "[6.3.1.4]: programmatic objects require testing (applet).",
    "[6.5.1.1]: <frameset> missing <noframes> section.", 
    "[6.5.1.2]: <noframes> section invalid (no value).",
    "[6.5.1.3]: <noframes> section invalid (content).",
    "[6.5.1.4]: <noframes> section invalid (link).",
    "[7.1.1.1]: remove flicker (script).",
    "[7.1.1.2]: remove flicker (object).",
    "[7.1.1.3]: remove flicker (embed).",
    "[7.1.1.4]: remove flicker (applet).",
    "[7.1.1.5]: remove flicker (animated gif).",
    "[7.2.1.1]: remove blink/marquee.",
    "[7.4.1.1]: remove auto-refresh.",
    "[7.5.1.1]: remove auto-redirect.",
    "[8.1.1.1]: ensure programmatic objects are accessible (script).",
    "[8.1.1.2]: ensure programmatic objects are accessible (object).",
    "[8.1.1.3]: ensure programmatic objects are accessible (applet).",
    "[8.1.1.4]: ensure programmatic objects are accessible (embed).",
    "[9.1.1.1]: image map (server-side) requires conversion.",
    "[9.3.1.1]: <script> not keyboard accessible (onMouseDown).",
    "[9.3.1.2]: <script> not keyboard accessible (onMouseUp).",
    "[9.3.1.3]: <script> not keyboard accessible (onClick).",
    "[9.3.1.4]: <script> not keyboard accessible (onMouseOver).",
    "[9.3.1.5]: <script> not keyboard accessible (onMouseOut).",
    "[9.3.1.6]: <script> not keyboard accessible (onMouseMove).",
    "[10.1.1.1]: new windows require warning (_new).",
    "[10.1.1.2]: new windows require warning (_blank).",
    "[10.2.1.1]: <label> needs repositioning (<label> before <input>).",
    "[10.2.1.2]: <label> needs repositioning (<label> after <input>).",
    "[10.4.1.1]: form control requires default text.",
    "[10.4.1.2]: form control default text invalid (null).",
    "[10.4.1.3]: form control default text invalid (spaces).",
    "[11.2.1.1]: replace deprecated html <applet>.",
    "[11.2.1.2]: replace deprecated html <basefont>.",
    "[11.2.1.3]: replace deprecated html <center>.",
    "[11.2.1.4]: replace deprecated html <dir>.",
    "[11.2.1.5]: replace deprecated html <font>.",
    "[11.2.1.6]: replace deprecated html <isindex>.",
    "[11.2.1.7]: replace deprecated html <menu>.",
    "[11.2.1.8]: replace deprecated html <s>.",
    "[11.2.1.9]: replace deprecated html <strike>.",
    "[11.2.1.10]: replace deprecated html <u>.",
    "[12.1.1.1]: <frame> missing title.",
    "[12.1.1.2]: <frame> title invalid (null).",
    "[12.1.1.3]: <frame> title invalid (spaces).",
    "[12.4.1.1]: associate labels explicitly with form controls.",
    "[12.4.1.2]: associate labels explicitly with form controls (for).",
    "[12.4.1.3]: associate labels explicitly with form controls (id).",
    "[13.1.1.1]: link text not meaningful.",
    "[13.1.1.2]: link text missing.",
    "[13.1.1.3]: link text too long.",
    "[13.1.1.4]: link text not meaningful (click here).",
    "[13.1.1.5]: link text not meaningful (more).",
    "[13.1.1.6]: link text not meaningful (follow this).",
    "[13.2.1.1]: Metadata missing.",
    "[13.2.1.2]: Metadata missing (link element).",
    "[13.2.1.3]: Metadata missing (redirect/auto-refresh).",
    "[13.10.1.1]: skip over ascii art.",
    
    "Unknown error.",    /* must be last */
};

#define N_ERROR_MSGS (sizeof(errorMsgs)/sizeof(ctmbstr))

/* function prototypes */
void InitAccessibilityChecks( TidyDocImpl* doc, int level123 );
void FreeAccessibilityChecks( TidyDocImpl* doc );

static Bool GetRgb( ctmbstr color, int rgb[3] );
static Bool CompareColors( int rgbBG[3], int rgbFG[3] );
static int  ctox( tmbchar ch );

static void DisplayHTMLTableAlgorithm( TidyDocImpl* doc);
/*
static void CheckMapAccess( TidyDocImpl* doc, Node* node, Node* front);
static void GetMapLinks( TidyDocImpl* doc, Node* node, Node* front);
static void CompareAnchorLinks( TidyDocImpl* doc, Node* front, int counter);
static void FindMissingLinks( TidyDocImpl* doc, Node* node, int counter);
*/
static void CheckFormControls( TidyDocImpl* doc, Node* node );
static void MetaDataPresent( TidyDocImpl* doc, Node* node );
static void CheckEmbed( TidyDocImpl* doc, Node* node );
static void CheckListUsage( TidyDocImpl* doc, Node* node );

/*
    GetFileExtension takes a path and returns the extension
    portion of the path (if any).
*/

static void GetFileExtension( ctmbstr path, tmbchar *ext, uint maxExt )
{
    int i = tmbstrlen(path) - 1;
    
    ext[0] = '\0';
    
    do {
        if ( path[i] == '/' || path[i] == '\\' )
            break;
        else if ( path[i] == '.' )
        {
            tmbstrncpy( ext, path+i, maxExt );
            break;
        }
    } while ( --i > 0 );
}

/*************************************************************************
* AccessReport
*
* Reports and displays errors/warnings.
*************************************************************************/

static void AccessReport( TidyDocImpl* doc, Node* node,
                          TidyReportLevel level, uint errorCode )
{
    ctmbstr error = "";
    if ( errorCode >= N_ERROR_MSGS )
        errorCode = LAST_ACCESS_ERR;
    error = errorMsgs[ errorCode ];
    doc->badAccess = yes;
    messageNode( doc, level, node, error );
}


/************************************************************************
* IsImage
*
* Checks if the given filename is an image file.
* Returns 'yes' if it is, 'no' if it's not.
************************************************************************/

static Bool IsImage( ctmbstr iType )
{
    int i;

    /* Get the file extension */
    tmbchar ext[20];
    GetFileExtension( iType, ext, sizeof(ext) );

    /* Compare it to the array of known image file extensions */
    for (i = 0; i < N_IMAGE_EXTS; i++)
    {
        if ( tmbstrcasecmp(ext, imageExtensions[i]) == 0 )
            return yes;
    }
    
    return no;
}


/***********************************************************************
* IsSoundFile
*
* Checks if the given filename is a sound file.
* Returns 'yes' if it is, 'no' if it's not.
***********************************************************************/

static int IsSoundFile( ctmbstr sType )
{
    int i;
    tmbchar ext[ 20 ];
    GetFileExtension( sType, ext, sizeof(ext) );

    for (i = 0; i < N_AUDIO_EXTS; i++)
    {
        if ( tmbstrcasecmp(ext, soundExtensions[i]) == 0 )
            return soundExtErrCodes[i];
    }
    return 0;
}


/***********************************************************************
* IsValidSrcExtension
*
* Checks if the 'SRC' value within the FRAME element is valid
* The 'SRC' extension must end in ".htm", ".html", ".shtm", ".shtml", 
* ".cfm", ".cfml", ".asp", ".cgi", ".pl", or ".smil"
*
* Returns yes if it is, returns no otherwise.
***********************************************************************/

static Bool IsValidSrcExtension( ctmbstr sType )
{
    int i;
    tmbchar ext[20];
    GetFileExtension( sType, ext, sizeof(ext) );

    for (i = 0; i < N_FRAME_EXTS; i++)
    {
        if ( tmbstrcasecmp(ext, frameExtensions[i]) == 0 )
            return yes;
    }
    return no;
}


/*********************************************************************
* IsValidMediaExtension
*
* Checks to warn the user that syncronized text equivalents are 
* required if multimedia is used.
*********************************************************************/

static Bool IsValidMediaExtension( ctmbstr sType )
{
    int i;
    tmbchar ext[20];
    GetFileExtension( sType, ext, sizeof(ext) );

    for (i = 0; i < N_MEDIA_EXTS; i++)
    {
        if ( tmbstrcasecmp(ext, mediaExtensions[i]) == 0 )
            return yes;
    }
    return no;
}


/************************************************************************
* IsWhitespace
*
* Checks if the given string is all whitespace.
* Returns 'yes' if it is, 'no' if it's not.
************************************************************************/

static Bool IsWhitespace( ctmbstr pString )
{
    Bool isWht = yes;
    ctmbstr cp;

    for ( cp = pString; isWht && cp && *cp; ++cp )
    {
        isWht = IsWhite( *cp );
    }
    return isWht;
}

static Bool hasValue( AttVal* av )
{
  return ( av && ! IsWhitespace(av->value) );
}

/***********************************************************************
* IsPlaceholderAlt
*  
* Checks to see if there is an image and photo place holder contained
* in the ALT text.
*
* Returns 'yes' if there is, 'no' if not.
***********************************************************************/

static Bool IsPlaceholderAlt( ctmbstr txt )
{
    return ( strstr(txt, "image") != NULL || 
             strstr(txt, "photo") != NULL );
}


/***********************************************************************
* IsPlaceholderTitle
*  
* Checks to see if there is an TITLE place holder contained
* in the 'ALT' text.
*
* Returns 'yes' if there is, 'no' if not.

static Bool IsPlaceHolderTitle( ctmbstr txt )
{
    return ( strstr(txt, "title") != NULL );
}
***********************************************************************/


/***********************************************************************
* IsPlaceHolderObject
*  
* Checks to see if there is an OBJECT place holder contained
* in the 'ALT' text.
*
* Returns 'yes' if there is, 'no' if not.
***********************************************************************/

static Bool IsPlaceHolderObject( ctmbstr txt )
{
    return ( strstr(txt, "object") != NULL );
}


/**********************************************************
* EndsWithBytes
*
* Checks to see if the ALT text ends with 'bytes'
* Returns 'yes', if true, 'no' otherwise.
**********************************************************/

static Bool EndsWithBytes( ctmbstr txt )
{
    uint len = tmbstrlen( txt );
    return ( len >= 5 && strcmp(txt+len-5, "bytes") == 0 );
}


/*******************************************************
* textFromOneNode
*
* Returns a list of characters contained within one
* text node.
*******************************************************/

static tmbstr textFromOneNode( TidyDocImpl* doc, Node* node )
{
    uint i;
    int x = 0;
    tmbstr txt = doc->access.text;
    
    if ( node )
    {
        /* Copy contents of a text node */
        for (i = node->start; i < node->end; ++i, ++x )
        {
            txt[x] = doc->lexer->lexbuf[i];

            /* Check buffer overflow */
            if ( x >= sizeof(doc->access.text)-1 )
                break;
        }
    }

    txt[x] = 0;
    return txt;
}


/*********************************************************
* getTextNode
*
* Locates text nodes within a container element.
* Retrieves text that are found contained within 
* text nodes, and concatenates the text.
*********************************************************/
    
static void getTextNode( TidyDocImpl* doc, Node* node )
{
    tmbstr txtnod = doc->access.textNode;       
    
    /* 
       Continues to traverse through container element until it no
       longer contains any more contents 
    */

    /* If the tag of the node is NULL, then grab the text within the node */
    if ( node && node->type == TextNode )
    {
        uint i;

        /* Retrieves each character found within the text node */
        for (i = node->start; i < node->end; i++)
        {
            /* The text must not exceed buffer */
            if ( doc->access.counter >= TEXTBUF_SIZE-1 )
                return;

            txtnod[ doc->access.counter++ ] = doc->lexer->lexbuf[i];
        }

        /* Traverses through the contents within a container element */
        for ( node = node->content; node != NULL; node = node->next )
            getTextNode( doc, node );
    }   
}


/**********************************************************
* getTextNodeClear
*
* Clears the current 'textNode' and reloads it with new
* text.  The textNode must be cleared before use.
**********************************************************/

static tmbstr getTextNodeClear( TidyDocImpl* doc, Node* node )
{
    /* Clears list */
    ClearMemory( doc->access.textNode, TEXTBUF_SIZE );
    doc->access.counter = 0;

    getTextNode( doc, node );
    return doc->access.textNode;
}
    

/********************************************************
* CheckColorAvailable
*
* Verify that information conveyed with color is 
* available without color.
********************************************************/

static void CheckColorAvailable( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if ( nodeIsIMG(node) )
            AccessReport( doc, node, TidyWarning,
                          INFORMATION_NOT_CONVEYED_IMAGE );

        else if ( nodeIsAPPLET(node) )
            AccessReport( doc, node, TidyWarning,
                          INFORMATION_NOT_CONVEYED_APPLET );

        else if ( nodeIsOBJECT(node) )
            AccessReport( doc, node, TidyWarning,
                          INFORMATION_NOT_CONVEYED_OBJECT );

        else if ( nodeIsSCRIPT(node) )
            AccessReport( doc, node, TidyWarning,
                          INFORMATION_NOT_CONVEYED_SCRIPT );

        else if ( nodeIsINPUT(node) )
            AccessReport( doc, node, TidyWarning,
                          INFORMATION_NOT_CONVEYED_INPUT );
    }
}

/*********************************************************************
* CheckColorContrast
*
* Checks elements for color contrast.  Must have valid contrast for
* valid visibility.
*
* This logic is extremely fragile as it does not recognize
* the fact that color is inherited by many components and
* that BG and FG colors are often set separately.  E.g. the
* background color may be set by for the body or a table 
* or a cell.  The foreground color may be set by any text
* element (p, h1, h2, input, textarea), either explicitly
* or by style.  Ergo, this test will not handle most real
* world cases.  It's a start, however.
*********************************************************************/

static void CheckColorContrast( TidyDocImpl* doc, Node* node )
{
    int rgbBG[3] = {255,255,255};   /* Black text on white BG */

    if ( doc->access.PRIORITYCHK == 3 )
    {
        Bool gotBG = yes;
        AttVal* av;

        /* Check for 'BGCOLOR' first to compare with other color attributes */
        for ( av = node->attributes; av; av = av->next )
        {            
            if ( attrIsBGCOLOR(av) )
            {
                if ( hasValue(av) )
                    gotBG = GetRgb( av->value, rgbBG );
            }
        }
        
        /* 
           Search for COLOR attributes to compare with background color
           Must have valid colour contrast
        */
        for ( av = node->attributes; gotBG && av != NULL; av = av->next )
        {
            uint errcode = 0;
            if ( attrIsTEXT(av) )
                errcode = COLOR_CONTRAST_TEXT;
            else if ( attrIsLINK(av) )
                errcode = COLOR_CONTRAST_LINK;
            else if ( attrIsALINK(av) )
                errcode = COLOR_CONTRAST_ACTIVE_LINK;
            else if ( attrIsVLINK(av) )
                errcode = COLOR_CONTRAST_VISITED_LINK;

            if ( errcode && hasValue(av) )
            {
                int rgbFG[3] = {0, 0, 0};  /* Black text */

                if ( GetRgb(av->value, rgbFG) &&
                     !CompareColors(rgbBG, rgbFG) )
                {
                    AccessReport( doc, node, TidyWarning, errcode );
                }
            }
        }
    }
}


/**************************************************************
* CompareColors
*
* Compares two RGB colors for good contrast.
**************************************************************/
static int minmax( int i1, int i2 )
{
   return MAX(i1, i2) - MIN(i1,i2);
}
static int brightness( int rgb[3] )
{
   return ((rgb[0]*299) + (rgb[1]*587) + (rgb[2]*114)) / 1000;
}

static Bool CompareColors( int rgbBG[3], int rgbFG[3] )
{
    int brightBG = brightness( rgbBG );
    int brightFG = brightness( rgbFG );

    int diffBright = minmax( brightBG, brightFG );

    int diffColor = minmax( rgbBG[0], rgbFG[0] )
                  + minmax( rgbBG[1], rgbFG[1] )
                  + minmax( rgbBG[2], rgbFG[2] );

    return ( diffBright > 180 &&
             diffColor > 500 );
}


/*********************************************************************
* GetRgb
*
* Gets the red, green and blue values for this attribute for the 
* background.
*
* Example: If attribute is BGCOLOR="#121005" then red = 18, green = 16,
* blue = 5.
*********************************************************************/

static Bool GetRgb( ctmbstr color, int rgb[] )
{
    int x;

    /* Check if we have a color name */
    for (x = 0; x < N_COLORS; x++)
    {
        if ( strstr(colorNames[x], color) != NULL )
        {
            rgb[0] = colorValues[x][0];
            rgb[1] = colorValues[x][1];
            rgb[2] = colorValues[x][2];
            return yes;
        }
    }

    /*
       No color name so must be hex values 
       Is this a number in hexadecimal format?
    */
    
    /* Must be 7 characters in the RGB value (including '#') */
    if ( tmbstrlen(color) == 7 && color[0] == '#' )
    {
        rgb[0] = (ctox(color[1]) * 16) + ctox(color[2]);
        rgb[1] = (ctox(color[3]) * 16) + ctox(color[4]);
        rgb[2] = (ctox(color[5]) * 16) + ctox(color[6]);
        return yes;
    }
    return no;
} 



/*******************************************************************
* ctox
*
* Converts a character to a number.
* Example: if given character is 'A' then returns 10.
*
* Returns the number that the character represents. Returns -1 if not a
* valid number.
*******************************************************************/

static int ctox( tmbchar ch )
{
    if ( ch >= '0' && ch <= '9' )
    {
         return ch - '0';
    }
    else if ( ch >= 'a' && ch <= 'f' )
    {
        return ch - 'a' + 10;
    }
    else if ( ch >= 'A' && ch <= 'F' )
    {
        return ch - 'A' + 10;
    }
    return -1;
}


/***********************************************************
* CheckImage
*
* Checks all image attributes for specific elements to
* check for validity of the values contained within
* the attributes.  An appropriate warning message is displayed
* to indicate the error.  
***********************************************************/

static void CheckImage( TidyDocImpl* doc, Node* node )
{
    Bool HasAlt = no;
    Bool HasIsMap = no;
    Bool HasDataFld = no;
    Bool HasLongDesc = no;
    Bool HasDLINK = no;
    Bool HasValidHeight = no;
    Bool HasValidWidthBullet = no;
    Bool HasValidWidthHR = no; 
    Bool HasTriggeredMissingAlt = no;
    Bool HasTriggeredMissingLongDesc = no;

    AttVal* av;
    Node* current = node;
    tmbstr word;
                
    if ((doc->access.PRIORITYCHK == 1)||
        (doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* Checks all image attributes for invalid values within attributes */
        for (av = node->attributes; av != NULL; av = av->next)
        {
            /* 
               Checks for valid ALT attribute.
               The length of the alt text must be less than 150 characters 
               long.
            */
            if ( attrIsALT(av) )
            {
                if (av->value != NULL) 
                {
                    if ((strlen(av->value) < 150) &&
                        (IsPlaceholderAlt (av->value) == no) &&
                        (IsPlaceHolderObject (av->value) == no) &&
                        (EndsWithBytes (av->value) == no) &&
                        (IsImage (av->value) == no))
                    {
                        HasAlt = yes;
                    }

                    else if (strlen (av->value) > 150)
                    {
                        HasAlt = yes;
                        AccessReport( doc, node, TidyWarning,
                                      IMG_ALT_SUSPICIOUS_TOO_LONG );
                    }

                    else if (IsImage (av->value) == yes)
                    {
                        HasAlt = yes;
                        AccessReport( doc, node, TidyWarning,
                                      IMG_ALT_SUSPICIOUS_FILENAME);
                    }
            
                    else if (IsPlaceholderAlt (av->value) == yes)
                    {
                        HasAlt = yes;
                        AccessReport( doc, node, TidyWarning,
                                      IMG_ALT_SUSPICIOUS_PLACEHOLDER);
                    }

                    else if (EndsWithBytes (av->value) == yes)
                    {
                        HasAlt = yes;
                        AccessReport( doc, node, TidyWarning,
                                      IMG_ALT_SUSPICIOUS_FILE_SIZE);
                    }
                }
            }

            /* 
               Checks for width values of 'bullets' and 'horizontal
               rules' for validity.

               Valid pixel width for 'bullets' must be < 30, and > 150 for
               horizontal rules.
            */
            else if ( attrIsWIDTH(av) )
            {
                /* Longdesc attribute needed if width attribute is not present. */
                if ( hasValue(av) )
                {
                    int width = atoi( av->value );
                    if ( width < 30 )
                        HasValidWidthBullet = yes;

                    if ( width > 150 )
                        HasValidWidthHR = yes;
                }
            }

            /* 
               Checks for height values of 'bullets' and horizontal
               rules for validity.

               Valid pixel height for 'bullets' and horizontal rules 
               mustt be < 30.
            */
            else if ( attrIsHEIGHT(av) )
            {
                /* Longdesc attribute needed if height attribute not present. */
                if ( hasValue(av) && atoi(av->value) < 30 )
                    HasValidHeight = yes;
            }

            /* 
               Checks for longdesc and determines validity.  
               The length of the 'longdesc' must be > 1
            */
            else if ( attrIsLONGDESC(av) )
            {
                if ( hasValue(av) && strlen(av->value) > 1 )
                    HasLongDesc = yes;
              }

            /* 
               Checks for 'USEMAP' attribute.  Ensures that
               text links are provided for client-side image maps
            */
            else if ( attrIsUSEMAP(av) )
            {
                if ( hasValue(av) )
                    doc->access.HasUseMap = yes;
            }    

            else if ( attrIsISMAP(av) )
            {
                HasIsMap = yes;
            }
        }    
        
        
        /* 
            Check to see if a dLINK is present.  The ANCHOR element must
            be present following the IMG element.  The text found between 
            the ANCHOR tags must be < 6 characters long, and must contain
            the letter 'd'.
        */
        if ( nodeIsA(node->next) )
        {
            node = node->next;
            
            /* 
                Node following the anchor must be a text node
                for dLINK to exist 
            */

            if(node->content != NULL && (node->content)->tag == NULL)
            {
                /* Number of characters found within the text node */
                word = textFromOneNode( doc, node->content);
                    
                if ((strcmp(word,"d") == 0)||
                    (strcmp(word,"D") == 0))
                {
                    HasDLINK = yes;
                }
            }
        }
                    
        /*
            Special case check for dLINK.  This will occur if there is 
            whitespace between the <img> and <a> elements.  Ignores 
            whitespace and continues check for dLINK.
        */
        
        if ( node->next && !node->next->tag )
        {
            node = node->next;

            if ( nodeIsA(node->next) )
            {
                node = node->next;

                /* 
                    Node following the ANCHOR must be a text node
                    for dLINK to exist 
                */
                if(node->content != NULL && node->content->tag == NULL)
                {
                    /* Number of characters found within the text node */
                    word = textFromOneNode( doc, node->content );

                    if ((strcmp(word, "d") == 0)||
                        (strcmp(word, "D") == 0))
                    {
                        HasDLINK = yes;
                    }
                }
            }    
        }

        if ((HasAlt == no)&&
            (HasValidWidthBullet == yes)&&
            (HasValidHeight == yes))
        {
            AccessReport( doc, node, TidyError, IMG_MISSING_ALT_BULLET);
            HasTriggeredMissingAlt = yes;
        }

        if ((HasAlt == no)&&
            (HasValidWidthHR == yes)&&
            (HasValidHeight == yes))
        {
            AccessReport( doc, node, TidyError, IMG_MISSING_ALT_H_RULE);
            HasTriggeredMissingAlt = yes;
        }
        
        if (HasTriggeredMissingAlt == no)
        {
            if (HasAlt == no)
            {
                AccessReport( doc, node, TidyError, IMG_MISSING_ALT);
            }
        }

        if ((HasLongDesc == no)&&
            (HasValidHeight ==yes)&&
            (HasValidWidthHR == yes)||
            (HasValidWidthBullet == yes))
        {
            HasTriggeredMissingLongDesc = yes;
            AccessReport( doc, node, TidyWarning, LONGDESC_NOT_REQUIRED);
        }

        if (HasTriggeredMissingLongDesc == no)
        {
            if ((HasDLINK == yes)&&
                (HasLongDesc == no))
            {
                AccessReport( doc, node, TidyWarning, IMG_MISSING_LONGDESC);
            }

            if ((HasLongDesc == yes)&&
                (HasDLINK == no))
            {
                AccessReport( doc, node, TidyWarning, IMG_MISSING_DLINK);
            }
            
            if ((HasLongDesc == no)&&
                (HasDLINK == no))
            {
                AccessReport( doc, node, TidyWarning, IMG_MISSING_LONGDESC_DLINK);
            }
        }
        
        if (HasIsMap == yes)
        {
            AccessReport( doc, node, TidyError, IMAGE_MAP_SERVER_SIDE_REQUIRES_CONVERSION);

            AccessReport( doc, node, TidyWarning, IMG_MAP_SERVER_REQUIRES_TEXT_LINKS);
        }
    }
}


/***********************************************************
* CheckApplet
*
* Checks APPLET element to check for validity pertaining 
* the 'ALT' attribute.  An appropriate warning message is 
* displayed  to indicate the error. An appropriate warning 
* message is displayed to indicate the error.  If no 'ALT'
* text is present, then there must be alternate content
* within the APPLET element.
***********************************************************/

static void CheckApplet( TidyDocImpl* doc, Node* node )
{
    Bool HasAlt = no;
    Bool HasDescription = no;

    AttVal* av;
    tmbstr word = null;
        
    if ((doc->access.PRIORITYCHK == 1)||
        (doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* Checks for attributes within the APPLET element */
        for (av = node->attributes; av != NULL; av = av->next)
        {
            /*
               Checks for valid ALT attribute.
               The length of the alt text must be > 4 characters in length
               but must be < 150 characters long.
            */

            if ( attrIsALT(av) )
            {
                if (av->value != NULL)
                {
                    HasAlt = yes;
                }
            }
        }

        if (HasAlt == no)
        {
            /* Must have alternate text representation for that element */
            if (node->content != NULL) 
            {
                if ( node->content->tag == NULL )
                    word = textFromOneNode( doc, node->content);

                if ( node->content->content != NULL &&
                     node->content->content->tag == NULL )
                {
                    word = textFromOneNode( doc, node->content->content);
                }
                
                if ( word != NULL && !IsWhitespace(word) )
                    HasDescription = yes;
            }
        }

        if ( !HasDescription && !HasAlt )
        {
            AccessReport( doc, node, TidyError, APPLET_MISSING_ALT );
        }
    }
}


/*******************************************************************
* CheckObject
*
* Checks to verify whether the OBJECT element contains
* 'ALT' text, and to see that the sound file selected is 
* of a valid sound file type.  OBJECT must have an alternate text 
* representation.
*******************************************************************/

static void CheckObject( TidyDocImpl* doc, Node* node )
{
    tmbstr word = null;
    Node* tnode = null;

    Bool HasAlt = no;
    Bool HasDescription = no;

    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if ( node->content != NULL)
        {
            if ( node->content->type != TextNode )
            {
                Node* tnode = node->content;
                AttVal* av;

                for ( av=tnode->attributes; av; av = av->next )
                {
                    if ( attrIsALT(av) )
                    {
                        HasAlt = yes;
                        break;
                    }
                }
            }

            /* Must have alternate text representation for that element */
            if ( !HasAlt )
            {
                if ( node->content->type == TextNode )
                    word = textFromOneNode( doc, node->content );

                if ( word == NULL && 
                     node->content->content != NULL &&
                     node->content->content->type == TextNode )
                {
                    word = textFromOneNode( doc, node->content->content );
                }
                    
                if ( word != NULL && !IsWhitespace(word) )
                    HasDescription = yes;
            }
        }

        if ( !HasAlt && !HasDescription )
        {
            AccessReport( doc, node, TidyError, OBJECT_MISSING_ALT );
        }
    }
}


/***************************************************************
* CheckMissingStyleSheets
*
* Ensures that stylesheets are used to control the presentation.
***************************************************************/

static Bool CheckMissingStyleSheets( TidyDocImpl* doc, Node* node )
{
    AttVal* av;
    Node* content;
    Bool sspresent = no;

    for ( content = node->content;
          !sspresent && content != NULL;
          content = content->next )
    {
        sspresent = ( nodeIsLINK(content)  ||
                      nodeIsSTYLE(content) ||
                      nodeIsFONT(content)  ||
                      nodeIsBASEFONT(content) );

        for ( av = content->attributes;
              !sspresent && av != NULL;
              av = av->next )
        {
            sspresent = ( attrIsSTYLE(av) || attrIsTEXT(av)  ||
                          attrIsVLINK(av) || attrIsALINK(av) ||
                          attrIsLINK(av) );

            if ( !sspresent && attrIsREL(av) )
            {
                sspresent = ( av->value != NULL &&
                              strcmp(av->value, "stylesheet") == 0 );
            }
        }

        if ( ! sspresent )
            sspresent = CheckMissingStyleSheets( doc, content );
    }
    return sspresent;
}


/*******************************************************************
* CheckFrame
*
* Checks if the URL is valid and to check if a 'LONGDESC' is needed
* within the FRAME element.  If a 'LONGDESC' is needed, the value must 
* be valid. The URL must end with the file extension, htm, or html. 
* Also, checks to ensure that the 'SRC' and 'TITLE' values are valid. 
*******************************************************************/

static void CheckFrame( TidyDocImpl* doc, Node* node )
{
    Bool HasTitle = no;
    AttVal* av;

    doc->access.numFrames++;

    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Checks for attributes within the FRAME element */
        for (av = node->attributes; av != null; av = av->next)
        {
            /* Checks if 'LONGDESC' value is valid only if present */
            if ( attrIsLONGDESC(av) )
            {
                if ( hasValue(av) && strlen(av->value) > 1 )
                {
                    doc->access.HasCheckedLongDesc++;
                }
            }

            /* Checks for valid 'SRC' value within the frame element */
            else if ( attrIsSRC(av) )
            {
                if ( hasValue(av) && !IsValidSrcExtension(av->value) )
                {
                    AccessReport( doc, node, TidyError, FRAME_SRC_INVALID );
                }
            }

            /* Checks for valid 'TITLE' value within frame element */
            else if ( attrIsTITLE(av) )
            {
                if ( hasValue(av) )
                    HasTitle = yes;

                if ( !HasTitle )
                {
                    if ( av->value == NULL || strlen(av->value) == 0 )
                    {
                        HasTitle = yes;
                        AccessReport( doc, node, TidyError, FRAME_TITLE_INVALID_NULL);
                    }
                    else
                    {
                        if ( IsWhitespace(av->value) && strlen(av->value) > 0 )
                        {
                            HasTitle = yes;
                            AccessReport( doc, node, TidyError, FRAME_TITLE_INVALID_SPACES );
                        }
                    }
                }
            }
        }

        if ( !HasTitle )
        {
            AccessReport( doc, node, TidyError, FRAME_MISSING_TITLE);
        }

        if ( doc->access.numFrames==3 && doc->access.HasCheckedLongDesc<3 )
        {
            doc->access.numFrames = 0;
            AccessReport( doc, node, TidyWarning, FRAME_MISSING_LONGDESC );
        }
    }
}


/****************************************************************
* CheckIFrame
*
* Checks if 'SRC' value is valid.  Must end in appropriate
* file extension.
****************************************************************/

static void CheckIFrame( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Checks for valid 'SRC' value within the IFRAME element */
        AttVal* av = attrGetSRC( node );
        if ( hasValue(av) )
        {
            if ( !IsValidSrcExtension(av->value) )
                AccessReport( doc, node, TidyError, FRAME_SRC_INVALID );
        }
    }
}


/**********************************************************************
* CheckAnchorAccess
*
* Checks that the sound file is valid, and to ensure that
* text transcript is present describing the 'HREF' within the 
* ANCHOR element.  Also checks to see ensure that the 'TARGET' attribute
* (if it exists) is not null and does not contain '_new' or '_blank'.
**********************************************************************/

static void CheckAnchorAccess( TidyDocImpl* doc, Node* node )
{
    AttVal* av;
    tmbstr word = null;
    int checked = 0;
    Bool HasDescription = no;
    Bool HasTriggeredLink = no;

    /* Checks for attributes within the ANCHOR element */
    for ( av = node->attributes; av != NULL; av = av->next )
    {
        if ( doc->access.PRIORITYCHK == 1 ||
             doc->access.PRIORITYCHK == 2 ||
             doc->access.PRIORITYCHK == 3 )
        {
            /* Must be of valid sound file type */
            if ( attrIsHREF(av) )
            {
                if ( hasValue(av) )
                {
                    tmbchar ext[ 20 ];
                    GetFileExtension (av->value, ext, sizeof(ext) );

                    /* Checks to see if multimedia is used */
                    if ( IsValidMediaExtension(av->value) )
                    {
                        AccessReport( doc, node, TidyError, MULTIMEDIA_REQUIRES_TEXT );
                    }
            
                    /* 
                        Checks for validity of sound file, and checks to see if 
                        the file is described within the document, or by a link
                        that is present which gives the description.
                    */
                    if ( strlen(ext) < 6 && strlen(ext) > 0 )
                    {
                        int errcode = IsSoundFile( av->value );
                        if ( errcode )
                        {
                            if (node->next != NULL)
                            {
                                if (node->next->tag == NULL)
                                {
                                    word = textFromOneNode( doc, node->next);
                                
                                    /* Must contain at least one letter in the text */
                                    if (IsWhitespace (word) == no)
                                    {
                                        HasDescription = yes;
                                    }
                                }
                            }

                            /* Must contain text description of sound file */
                            if ( !HasDescription )
                            {
                                AccessReport( doc, node, TidyError, errcode );
                            }
                        }
                    }
                }
            }
        }

        if ( doc->access.PRIORITYCHK == 2 ||
             doc->access.PRIORITYCHK == 3 )
        {
            /* Checks 'TARGET' attribute for validity if it exists */
            if ( attrIsTARGET(av) )
            {
                checked = 1;

                if ( hasValue(av) )
                {
                    if (strcmp (av->value, "_new") == 0)
                    {
                        AccessReport( doc, node, TidyWarning, NEW_WINDOWS_REQUIRE_WARNING_NEW);
                    }
                    
                    if (strcmp (av->value, "_blank") == 0)
                    {
                        AccessReport( doc, node, TidyWarning, NEW_WINDOWS_REQUIRE_WARNING_BLANK);
                    }
                }
            }
        }
    }
    
    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if ((node->content != NULL)&&
            (node->content->tag == NULL))
        {
            word = textFromOneNode( doc, node->content);

            if ((word != NULL)&&
                (IsWhitespace (word) == no))
            {
                if (strcmp (word, "more") == 0)
                {
                    HasTriggeredLink = yes;
                    AccessReport( doc, node, TidyWarning, LINK_TEXT_NOT_MEANINGFUL_MORE);
                }

                if (strcmp (word, "follow this") == 0)
                {
                    AccessReport( doc, node, TidyWarning, LINK_TEXT_NOT_MEANINGFUL_FOLLOW_THIS);
                }

                if (strcmp (word, "click here") == 0)
                {
                    AccessReport( doc, node, TidyWarning, LINK_TEXT_NOT_MEANINGFUL_CLICK_HERE);
                }

                if (HasTriggeredLink == no)
                {
                    if (strlen (word) < 6)
                    {
                        AccessReport( doc, node, TidyWarning, LINK_TEXT_NOT_MEANINGFUL);
                    }
                }

                if (strlen (word) > 60)
                {
                    AccessReport( doc, node, TidyWarning, LINK_TEXT_TOO_LONG);
                }

            }
        }
        
        if (node->content == NULL)
        {
            AccessReport( doc, node, TidyWarning, LINK_TEXT_MISSING);
        }
    }
}


/************************************************************
* CheckArea
*
* Checks attributes within the AREA element to 
* determine if the 'ALT' text and 'HREF' values are valid.
* Also checks to see ensure that the 'TARGET' attribute
* (if it exists) is not null and does not contain '_new' 
* or '_blank'.
************************************************************/

static void CheckArea( TidyDocImpl* doc, Node* node )
{
    Bool HasAlt = no;
    int checked = 0;
    AttVal* av;

    /* Checks all attributes within the AREA element */
    for (av = node->attributes; av != null; av = av->next)
    {
        if ((doc->access.PRIORITYCHK == 1)||
            (doc->access.PRIORITYCHK == 2)||
            (doc->access.PRIORITYCHK == 3))
        {
            /*
              Checks for valid ALT attribute.
              The length of the alt text must be > 4 characters long
              but must be less than 150 characters long.
            */
                
            if ( attrIsALT(av) )
            {
                /* The check for validity */
                if (av->value != NULL) 
                {
                    HasAlt = yes;
                }
            }
        }

        if ((doc->access.PRIORITYCHK == 2)||
            (doc->access.PRIORITYCHK == 3))
        {
            if ( attrIsTARGET(av) )
            {
                if ((av->value != NULL)&&
                    (IsWhitespace (av->value) == no))
                {
                    if (strcmp (av->value, "_new") == 0)
                    {
                        AccessReport( doc, node, TidyWarning, NEW_WINDOWS_REQUIRE_WARNING_NEW);
                    }
                        
                    if (strcmp (av->value, "_blank") == 0)
                    {
                        AccessReport( doc, node, TidyWarning, NEW_WINDOWS_REQUIRE_WARNING_BLANK);
                    }
                }
            }
        }
    }

    if ((doc->access.PRIORITYCHK == 1)||
        (doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* AREA must contain alt text */
        if (HasAlt == no)
        {
            AccessReport( doc, node, TidyError, AREA_MISSING_ALT);
        }    
    }
}


/***************************************************
* CheckScript
*
* Checks the SCRIPT element to ensure that a
* NOSCRIPT section follows the SCRIPT.  
***************************************************/

static void CheckScriptAcc( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* NOSCRIPT element must appear immediately following SCRIPT element */
        if ( node->next == NULL || !nodeIsNOSCRIPT(node->next) )
        {
            AccessReport( doc, node, TidyError, SCRIPT_MISSING_NOSCRIPT);
        }
    }
}


/**********************************************************
* CheckRows
*
* Check to see that each table has a row of headers if
* a column of columns doesn't exist. 
**********************************************************/

static void CheckRows( TidyDocImpl* doc, Node* node )
{
    int numTR = 0;
    int numValidTH = 0;
    tmbstr word;
    
    doc->access.CheckedHeaders++;

    for(;;)
    {
        if (node == NULL)
        {
            break;
        }

        else 
        {
            numTR++;

            if ( nodeIsTH(node) )
            {
                doc->access.HasTH = yes;
            
                if ( node->content && nodeIsText(node->content->content) )
                {
                    word = textFromOneNode( doc, node->content->content);
                    if ( !IsWhitespace(word) )
                        numValidTH++;
                }
            }
        }
        
        node = node->next;
    }

    if (numTR == numValidTH)
    {
        doc->access.HasValidRowHeaders = yes;
    }

    if ( numTR >= 2 &&
         numTR > numValidTH &&
         numValidTH >= 2 &&
         doc->access.HasTH == yes )
    {
        doc->access.HasInvalidRowHeader = yes;
    }
}


/**********************************************************
* CheckColumns
*
* Check to see that each table has a column of headers if
* a row of columns doesn't exist.  
**********************************************************/

static void CheckColumns( TidyDocImpl* doc, Node* node )
{
    Node* tnode;
    tmbstr word;
    int numTH = 0;
    Bool isMissingHeader = no;

    doc->access.CheckedHeaders++;

    /* Table must have row of headers if headers for columns don't exist */
    if ( nodeIsTH(node->content) )
    {
        doc->access.HasTH = yes;

        for ( tnode = node->content; tnode; tnode = tnode->next )
        {
            if ( nodeIsTH(tnode) )
            {
                if ( nodeIsText(tnode->content) )
                {
                    word = textFromOneNode( doc, tnode->content);
                    if ( !IsWhitespace(word) )
                        numTH++;
                }
            }
            else
            {
                isMissingHeader = yes;
            }
        }
    }

    if ( !isMissingHeader && numTH > 0 )
        doc->access.HasValidColumnHeaders = yes;

    if ( isMissingHeader && numTH >= 2 )
        doc->access.HasInvalidColumnHeader = yes;
}


/*****************************************************
* CheckTH
*
* Checks to see if the header provided for a table
* requires an abbreviation. (only required if the 
* length of the header is greater than 15 characters)
*****************************************************/

static void CheckTH( TidyDocImpl* doc, Node* node )
{
    Bool HasAbbr = no;
    tmbstr word = null;
    AttVal* av;

    if (doc->access.PRIORITYCHK == 3)
    {
        /* Checks TH element for 'ABBR' attribute */
        for (av = node->attributes; av != NULL; av = av->next)
        {
            if ( attrIsABBR(av) )
            {
                /* Value must not be null and must be less than 15 characters */
                if ((av->value != NULL)&&
                    (IsWhitespace (av->value) == no))
                {
                    HasAbbr = yes;
                }

                if ((av->value == NULL)||
                    (strlen (av->value) == 0))
                {
                    HasAbbr = yes;
                    AccessReport( doc, node, TidyWarning, TABLE_MAY_REQUIRE_HEADER_ABBR_NULL);
                }
                
                if ((IsWhitespace (av->value) == yes)&&
                    (strlen (av->value) > 0))
                {
                    HasAbbr = yes;
                    AccessReport( doc, node, TidyWarning, TABLE_MAY_REQUIRE_HEADER_ABBR_SPACES);
                }
            }
        }

        /* If the header is greater than 15 characters, an abbreviation is needed */
        word = textFromOneNode( doc, node->content);

        if ((word != NULL)&&
            (IsWhitespace (word) == no))
        {
            /* Must have 'ABBR' attribute if header is > 15 characters */
            if ((strlen (word) > 15)&&
                (HasAbbr == no))
            {
                AccessReport( doc, node, TidyWarning, TABLE_MAY_REQUIRE_HEADER_ABBR);
            }
        }
    }
}


/*****************************************************************
* CheckMultiHeaders
*
* Layout tables should make sense when linearized.
* TABLE must contain at least one TH element.
* This technique applies only to tables used for layout purposes, 
* not to data tables. Checks for column of multiple headers.
*****************************************************************/

static void CheckMultiHeaders( TidyDocImpl* doc, Node* node )
{
    Node* TNode;
    Node* temp;
    
    Bool validColSpanRows = yes;
    Bool validColSpanColumns = yes;

    int flag = 0;

    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if (node->content != NULL)
        {
            TNode = node->content;

            /* 
               Checks for column of multiple headers found 
               within a data table. 
            */
            while (TNode != NULL)
            {
                if ( nodeIsTR(TNode) )
                {
                    if (TNode->content != NULL)
                    {
                        temp = TNode->content;

                        if ( nodeIsTH(temp) )
                        {
                            AttVal* av;
                            for (av = temp->attributes; av != null; av = av->next)
                            {
                                if ( attrIsROWSPAN(av) )
                                {
                                    if (atoi(av->value) > 1)
                                    {
                                        validColSpanRows = no;
                                    }
                                }
                            }
                        }

                        /* The number of TH elements found within TR element */
                        if (flag == 0)
                        {
                            while (temp != NULL)
                            {
                                /* 
                                   Must contain at least one TH element 
                                   within in the TR element 
                                */
                                if ( nodeIsTH(temp) )
                                {
                                    AttVal* av;
                                    for (av = temp->attributes; av != null; av = av->next)
                                    {
                                        if ( attrIsCOLSPAN(av) )
                                        {
                                            if (atoi(av->value) > 1)
                                            {
                                                validColSpanColumns = no;
                                            }
                                        }
                                    }
                                }

                                temp = temp->next;
                            }    

                            flag = 1;
                        }
                    }
                }
            
                TNode = TNode->next;
            }

            /* Displays HTML 4 Table Algorithm when multiple column of headers used */
            if (validColSpanRows == no)
            {
                AccessReport( doc, node, TidyWarning, DATA_TABLE_REQUIRE_MARKUP_ROW_HEADERS );
                DisplayHTMLTableAlgorithm( doc );
            }

            if (validColSpanColumns == no)
            {
                AccessReport( doc, node, TidyWarning, DATA_TABLE_REQUIRE_MARKUP_COLUMN_HEADERS );
                DisplayHTMLTableAlgorithm( doc );
            }
        }
    }
}


/****************************************************
* CheckTable
*
* Checks the TABLE element to ensure that the
* table is not missing any headers.  Must have either
* a row or column of headers.  
****************************************************/

static void CheckTable( TidyDocImpl* doc, Node* node )
{
    Node* TNode;
    Node* temp;

    tmbstr word = null;
    tmbstr value = null;

    int numTR = 0;

    Bool HasSummary = no;
    Bool HasCaption = no;

    if (doc->access.PRIORITYCHK == 3)
    {
        AttVal* av;
        /* Table must have a 'SUMMARY' describing the purpose of the table */
        for (av = node->attributes; av != null; av = av->next)
        {
            if ( attrIsSUMMARY(av) )
            {
                if ( hasValue(av) )
                {
                    if ( strstr(av->value, "summary") == NULL &&
                         strstr(av->value, "table") == NULL )
                    {
                        HasSummary = yes;
                    }

                    if ( strstr(av->value, "summary") != NULL ||
                         strstr(av->value, "table") != NULL )
                    {
                        HasSummary = yes;
                        AccessReport( doc, node, TidyError, TABLE_SUMMARY_INVALID_PLACEHOLDER );
                    }
                }

                if ( av->value == NULL || strlen(av->value) == 0 )
                {
                    HasSummary = yes;
                    AccessReport( doc, node, TidyError, TABLE_SUMMARY_INVALID_NULL );
                }
                else if ( IsWhitespace(av->value) && strlen(av->value) > 0 )
                {
                    HasSummary = yes;
                    AccessReport( doc, node, TidyError, TABLE_SUMMARY_INVALID_SPACES );
                }
            }
        }

        /* TABLE must have content. */
        if (node->content == NULL)
        {
            AccessReport( doc, node, TidyError, DATA_TABLE_MISSING_HEADERS);
        
            return;
        }
    }

    if ((doc->access.PRIORITYCHK == 1)||
        (doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* Checks for multiple headers */
        CheckMultiHeaders( doc, node );
    }
    
    if ((doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* Table must have a CAPTION describing the purpose of the table */
        if ( nodeIsCAPTION(node->content) )
        {
            TNode = node->content;

            if (TNode->content->tag == NULL)
            {
                word = getTextNodeClear( doc, TNode);
            }

            if ( !IsWhitespace(word) )
            {
                HasCaption = yes;
            }
        }

        if (HasCaption == no)
        {
            AccessReport( doc, node, TidyError, TABLE_MISSING_CAPTION);
        }
    }

    
    if (node->content != NULL)
    {
        if ( nodeIsCAPTION(node->content) && nodeIsTR(node->content->next) )
        {
            CheckColumns( doc, node->content->next );
        }
        else if ( nodeIsTR(node->content) )
        {
            CheckColumns( doc, node->content );
        }
    }
    
    if ( ! doc->access.HasValidColumnHeaders )
    {
        if (node->content != NULL)
        {
            if ( nodeIsCAPTION(node->content) && nodeIsTR(node->content->next) )
            {
                CheckRows( doc, node->content->next);
            }
            else if ( nodeIsTR(node->content) )
            {
                CheckRows( doc, node->content);
            }
        }
    }
    
    
    if ( doc->access.PRIORITYCHK == 3 )
    {
        /* Suppress warning for missing 'SUMMARY for HTML 2.0 and HTML 3.2 */
        if (HasSummary == no)
        {
            AccessReport( doc, node, TidyError, TABLE_MISSING_SUMMARY);
        }
    }

    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if (node->content != NULL)
        {
            temp = node->content;

            while (temp != NULL)
            {
                if ( nodeIsTR(temp) )
                {
                    numTR++;
                }

                temp = temp->next;
            }

            if (numTR == 1)
            {
                AccessReport( doc, node, TidyWarning, LAYOUT_TABLES_LINEARIZE_PROPERLY);
            }
        }
    
        if ( doc->access.HasTH )
        {
            AccessReport( doc, node, TidyWarning, LAYOUT_TABLE_INVALID_MARKUP);
        }
    }

    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if ( doc->access.CheckedHeaders == 2 )
        {
            if ( !doc->access.HasValidRowHeaders &&
                 !doc->access.HasValidColumnHeaders &&
                 !doc->access.HasInvalidRowHeader &&
                 !doc->access.HasInvalidColumnHeader  )
            {
                AccessReport( doc, node, TidyError, DATA_TABLE_MISSING_HEADERS);
            }

            if ( !doc->access.HasValidRowHeaders && 
                 doc->access.HasInvalidRowHeader )
            {
                AccessReport( doc, node, TidyError, DATA_TABLE_MISSING_HEADERS_ROW);
            }

            if ( !doc->access.HasValidColumnHeaders &&
                 doc->access.HasInvalidColumnHeader )
            {
                AccessReport( doc, node, TidyError, DATA_TABLE_MISSING_HEADERS_COLUMN);
            }
        }
    }
}


/*********************************************************
* DisplayHTMLTableAlgorithm()
*
* If the table does contain 2 or more logical levels of 
* row or column headers, the HTML 4 table algorithm 
* to show the author how the headers are currently associated 
* with the cells.
*********************************************************/
 
static void DisplayHTMLTableAlgorithm( TidyDocImpl* doc )
{
    tidy_out(doc, " \n");
    tidy_out(doc, "      - First, search left from the cell's position to find row header cells.\n");
    tidy_out(doc, "      - Then search upwards to find column header cells.\n");
    tidy_out(doc, "      - The search in a given direction stops when the edge of the table is\n");
    tidy_out(doc, "        reached or when a data cell is found after a header cell.\n"); 
    tidy_out(doc, "      - Row headers are inserted into the list in the order they appear in\n");
    tidy_out(doc, "        the table. \n");
    tidy_out(doc, "      - For left-to-right tables, headers are inserted from left to right.\n");
    tidy_out(doc, "      - Column headers are inserted after row headers, in \n");
    tidy_out(doc, "        the order they appear in the table, from top to bottom. \n");
    tidy_out(doc, "      - If a header cell has the headers attribute set, then the headers \n");
    tidy_out(doc, "        referenced by this attribute are inserted into the list and the \n");
    tidy_out(doc, "        search stops for the current direction.\n");
    tidy_out(doc, "        TD cells that set the axis attribute are also treated as header cells.\n");
    tidy_out(doc, " \n");
}


/***************************************************
* CheckASCII
* 
* Checks for valid text equivalents for XMP and PRE
* elements for ASCII art.  Ensures that there is
* a skip over link to skip multi-lined ASCII art.
***************************************************/

static void CheckASCII( TidyDocImpl* doc, Node* node )
{
    Node* temp1;
    Node* temp2;

    tmbstr skipOver = null;
    Bool IsAscii = no;
    int HasSkipOverLink = 0;
        
    uint i, x;
    int newLines = -1;
    tmbchar compareLetter;
    int matchingCount = 0;
    AttVal* av;
    
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* 
           Checks the text within the PRE and XMP tags to see if ascii 
           art is present 
        */
        for (i = node->content->start + 1; i < node->content->end; i++)
        {
            matchingCount = 0;

            /* Counts the number of lines of text */
            if (doc->lexer->lexbuf[i] == '\n')
            {
                newLines++;
            }
            
            compareLetter = doc->lexer->lexbuf[i];

            /* Counts consecutive character matches */
            for (x = i; x < i + 5; x++)
            {
                if (doc->lexer->lexbuf[x] == compareLetter)
                {
                    matchingCount++;
                }

                else
                {
                    break;
                }
            }

            /* Must have at least 5 consecutive character matches */
            if (matchingCount >= 5)
            {
                break;
            }
        }

        /* 
           Must have more than 6 lines of text OR 5 or more consecutive 
           letters that are the same for there to be ascii art 
        */
        if (newLines >= 6 || matchingCount >= 5)
        {
            IsAscii = yes;
        }

        /* Checks for skip over link if ASCII art is present */
        if (IsAscii == yes)
        {
            if (node->prev != NULL && node->prev->prev != NULL)
            {
                temp1 = node->prev->prev;

                /* Checks for 'HREF' attribute */
                for (av = temp1->attributes; av != null; av = av->next)
                {
                    if ( attrIsHREF(av) && hasValue(av) )
                    {
                        skipOver = av->value;
                        HasSkipOverLink++;
                    }
                }
            }
        }
    }

    if ((doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* 
           Checks for A element following PRE to ensure proper skipover link
           only if there is an A element preceding PRE.
        */
        if (HasSkipOverLink == 1)
        {
            if ( nodeIsA(node->next) )
            {
                temp2 = node->next;
                
                /* Checks for 'NAME' attribute */
                for (av = temp2->attributes; av != null; av = av->next)
                {
                    if ( attrIsNAME(av) && hasValue(av) )
                    {
                        /* 
                           Value within the 'HREF' attribute must be the same
                           as the value within the 'NAME' attribute for valid
                           skipover.
                        */
                        if ( strstr(skipOver, av->value) != NULL )
                        {
                            HasSkipOverLink++;
                        }
                    }
                }
            }
        }

        if (IsAscii == yes)
        {
            AccessReport( doc, node, TidyError, ASCII_REQUIRES_DESCRIPTION);
        }

        if (HasSkipOverLink < 2)
        {
            if (IsAscii == yes)
            {
                AccessReport( doc, node, TidyError, SKIPOVER_ASCII_ART);
            }
        }
    }
}


/***********************************************************
* CheckFormControls
*
* <form> must have valid 'FOR' attribute, and <label> must
* have valid 'ID' attribute for valid form control.
***********************************************************/

static void CheckFormControls( TidyDocImpl* doc, Node* node )
{
    if ( !doc->access.HasValidFor &&
         doc->access.HasValidId )
    {
        AccessReport( doc, node, TidyError, ASSOCIATE_LABELS_EXPLICITLY_FOR);
    }    

    if ( !doc->access.HasValidId &&
         doc->access.HasValidFor )
    {
        AccessReport( doc, node, TidyError, ASSOCIATE_LABELS_EXPLICITLY_ID);
    }

    if ( !doc->access.HasValidId &&
         !doc->access.HasValidFor )
    {
        AccessReport( doc, node, TidyError, ASSOCIATE_LABELS_EXPLICITLY);
    }
}


/************************************************************
* CheckLabel
*
* Check for valid 'FOR' attribute within the LABEL element
************************************************************/

static void CheckLabel( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {    
        /* Checks for valid 'FOR' attribute */
        AttVal* av = attrGetFOR( node );
        if ( hasValue(av) )
            doc->access.HasValidFor = yes;

        if ( ++doc->access.ForID == 2 )
        {
            doc->access.ForID = 0;
            CheckFormControls( doc, node );
        }
    }
}


/************************************************************
* CheckInputLabel
* 
* Checks for valid 'ID' attribute within the INPUT element.
* Checks to see if there is a LABEL directly before
* or after the INPUT element determined by the 'TYPE'.  
* Each INPUT element must have a LABEL describing the form.
************************************************************/

static void CheckInputLabel( TidyDocImpl* doc, Node* node )
{
    int flag = 0;

    tmbstr word = null;
    tmbstr text = null;

    AttVal* av;

    Bool HasLabelBefore = no;
    Bool HasLabelAfter = no;
    Bool HasValidLabel = no;

    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {

        /* Checks attributes within the INPUT element */
        for (av = node->attributes; av != NULL; av = av->next)
        {
            /* Must have valid 'ID' value */
            if ( attrIsID(av) && hasValue(av) )
                doc->access.HasValidId = yes;
    
            /* 
               Determines where the LABEL should be located determined by 
               the 'TYPE' of form the INPUT is.
            */
            else if ( attrIsTYPE(av) && hasValue(av) )
            {
                if ( strstr(av->value, "checkbox") != NULL ||
                     strstr(av->value, "radio") != NULL    ||
                     strstr(av->value, "text") != NULL     ||
                     strstr(av->value, "password") != NULL ||
                     strstr(av->value, "file") != NULL )
                {
                    if ( node->prev != NULL &&
                         node->prev->prev != NULL )
                    {
                        Node* temp = node->prev->prev;
                        if ( nodeIsLABEL(temp) )
                        {
                            flag = 1;
                            if ( nodeIsText(temp->content) )
                            {
                                word = textFromOneNode( doc, temp->content );
                                if ( !IsWhitespace(word) )
                                    HasLabelBefore = yes;
                            }
                        }
                        
                        if ( HasLabelBefore && nodeIsText(node->prev) )
                        {
                            text = textFromOneNode( doc, node->prev );
                            if ( IsWhitespace(text) )
                                HasValidLabel = yes;
                        }
                    }

                    if ( flag == 0 )
                    {
                        if ( node->next != NULL &&
                             node->next->next != NULL )
                        {
                            Node* temp = node->next->next;
                            if ( nodeIsLABEL(temp) &&
                                 nodeIsText(temp->content) )
                            {
                                word = textFromOneNode( doc, temp->content);
                                if ( !IsWhitespace(word) )
                                    HasLabelAfter = yes;
                            }

                            if ( HasLabelAfter && nodeIsText(node->next) )
                            {
                                text = textFromOneNode( doc, node->next);
                                if ( IsWhitespace(text) )
                                    HasValidLabel = yes;
                            }
                        }
                    }
                }

                /* The following 'TYPES' do not require a LABEL */
                if ( strcmp(av->value, "image") == 0  ||
                     strcmp(av->value, "hidden") == 0 ||
                     strcmp(av->value, "submit") == 0 ||
                     strcmp(av->value, "reset") == 0  ||
                     strcmp(av->value, "button") == 0 )
                {
                    HasValidLabel = yes;
                }
            }
        }

        if ( !HasValidLabel )
        {
            if ( HasLabelBefore )
              AccessReport( doc, node, TidyError,
                            LABEL_NEEDS_REPOSITIONING_BEFORE_INPUT );
       
            if ( HasLabelAfter )
              AccessReport( doc, node, TidyError,
                            LABEL_NEEDS_REPOSITIONING_AFTER_INPUT );
        }
        
        if ( ++doc->access.ForID == 2 )
        {
            doc->access.ForID = 0;
            CheckFormControls( doc, node );
        }
    }
}


/***************************************************************
* CheckInputAttributes 
*
* INPUT element must have a valid 'ALT' attribute if the
* 'VALUE' attribute is present.
***************************************************************/

static void CheckInputAttributes( TidyDocImpl* doc, Node* node )
{
    Bool HasValue = no;
    Bool HasAlt = no;
    Bool MustHaveAlt = no;
    Bool MustHaveValue = no;
    AttVal* av;

    /* Checks attributes within the INPUT element */
    for (av = node->attributes; av != NULL; av = av->next)
    {
        /* 'VALUE' must be found if the 'TYPE' is 'text' or 'checkbox' */
        if ( attrIsTYPE(av) && hasValue(av) )
        {
            if ( doc->access.PRIORITYCHK == 1 ||
                 doc->access.PRIORITYCHK == 2 ||
                 doc->access.PRIORITYCHK == 3 )
            {
                if ( strcmp(av->value, "image") == 0 )
                {
                    MustHaveAlt = yes;
                }
            }

            if ( doc->access.PRIORITYCHK == 3 )
            {
                if ( strcmp(av->value, "text") == 0 ||
                     strcmp(av->value, "checkbox") == 0 )
                {    
                    MustHaveValue = yes;
                }
            }
        }
        
        if ( attrIsALT(av) && hasValue(av) )
        {
            HasAlt = yes;
        }

        if ( attrIsVALUE(av) )
        {
            if ( hasValue(av) )
            {
                HasValue = yes;
            }
            else if ( av->value == NULL || strlen(av->value) == 0 )
            {
                HasValue = yes;
                AccessReport( doc, node, TidyError,
                              FORM_CONTROL_DEFAULT_TEXT_INVALID_NULL );
            }
            else if ( IsWhitespace(av->value) && strlen(av->value) > 0 )
            {
                HasValue = yes;
                AccessReport( doc, node, TidyError,
                              FORM_CONTROL_DEFAULT_TEXT_INVALID_SPACES );
            }
        }
    }

    if ( MustHaveAlt && !HasAlt )
    {
        AccessReport( doc, node, TidyError, IMG_BUTTON_MISSING_ALT );
    }

    if ( MustHaveValue && !HasValue )
    {
        AccessReport( doc, node, TidyError, FORM_CONTROL_REQUIRES_DEFAULT_TEXT );
    }
}


/***************************************************************
* CheckFrameSet
*
* Frameset must have valid NOFRAME section.  Must contain some 
* text but must not contain information telling user to update 
* browsers, 
***************************************************************/

static void CheckFrameSet( TidyDocImpl* doc, Node* node )
{
    Node* temp;
    tmbstr word;
    
    Bool HasNoFrames = no;

    if ((doc->access.PRIORITYCHK == 1)||
        (doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        if (node->content != NULL)
        {
            temp = node->content;

            while (temp != NULL)
            {
                if ( nodeIsA(temp) )
                {
                    AccessReport( doc, temp, TidyError, NOFRAMES_INVALID_LINK);
                }
                else if ( nodeIsNOFRAMES(temp) )
                {
                    HasNoFrames = yes;

                    if ( temp->content && nodeIsP(temp->content->content) )
                    {
                        Node* para = temp->content->content;
                        if ( nodeIsText(para->content) )
                        {
                            word = textFromOneNode( doc, para->content );
                            if ( word && strstr(word, "browser") != NULL )
                            {
                                AccessReport( doc, para, TidyError, NOFRAMES_INVALID_CONTENT );
                            }
                        }
                    }
                    else if (temp->content == NULL)
                    {
                        AccessReport( doc, temp, TidyError, NOFRAMES_INVALID_NO_VALUE);
                    }
                    else if ( temp->content &&
                              IsWhitespace(textFromOneNode(doc, temp->content)) )
                    {
                        AccessReport( doc, temp, TidyError, NOFRAMES_INVALID_NO_VALUE);
                    }
                }

                temp = temp->next;
            }
        }

        if (HasNoFrames == no)
        {
            AccessReport( doc, node, TidyError, FRAME_MISSING_NOFRAMES);
        }
    }
}


/***********************************************************
* CheckHeaderNesting
*
* Checks for heading increases and decreases.  Headings must
* not increase by more than one header level, but may
* decrease at from any level to any level.  Text within 
* headers must not be more than 20 words in length.  
***********************************************************/

static void CheckHeaderNesting( TidyDocImpl* doc, Node* node )
{
    Node* temp;
    tmbstr word;
    uint i;
    int numWords = 1;

    Bool IsValidIncrease = no;
    Bool NeedsDescription = no;

    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* 
           Text within header element cannot contain more than 20 words without
           a separate description
        */
        if (node->content->tag == NULL)
        {
            word = textFromOneNode( doc, node->content);

            for(i = 0; i < strlen (word); i++)
            {
                if (word[i] == ' ')
                {
                    numWords++;
                }
            }

            if (numWords > 20)
            {
                NeedsDescription = yes;
            }
        }

        /* Header following must be same level or same plus 1 for
        ** valid heading increase size.  E.g. H1 -> H1, H2.  H3 -> H3, H4
        */
        if ( nodeIsHeader(node) )
        {
            uint level = nodeHeaderLevel( node );
            IsValidIncrease = yes;

            for ( temp = node->next; temp != NULL; temp = temp->next )
            {
                uint nested = nodeHeaderLevel( temp );
                if ( nested >= level )
                {
                    IsValidIncrease = ( nested <= level + 1 );
                    break;
                }
            }
        }

        if ( !IsValidIncrease )
            AccessReport( doc, node, TidyWarning, HEADERS_IMPROPERLY_NESTED );
    
        if ( NeedsDescription )
            AccessReport( doc, node, TidyWarning, HEADER_USED_FORMAT_TEXT );    
    }
}


/*************************************************************
* CheckParagraphHeader
*
* Checks to ensure that P elements are not headings.  Must be
* greater than 10 words in length, and they must not be in bold,
* or italics, or underlined, etc.
*************************************************************/

static void CheckParagraphHeader( TidyDocImpl* doc, Node* node )
{
    Bool IsHeading = yes;
    Bool IsNotHeader = no;
    Node* temp;

    if ((doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* Cannot contain text formatting elements */
        if (node->content != NULL)   
        {                     
            if (node->content->tag != NULL)
            {
                temp = node->content;

                while (temp != NULL)
                {
                    if (temp->tag == NULL)
                    {
                        IsNotHeader = yes;
                        break;
                    }
                        
                    temp = temp->next;
                }
            }

            if ( !IsNotHeader )
            {
                if ( nodeIsSTRONG(node->content) )
                {
                    AccessReport( doc, node, TidyWarning, POTENTIAL_HEADER_BOLD);
                }

                if ( nodeIsU(node->content) )
                {
                    AccessReport( doc, node, TidyWarning, POTENTIAL_HEADER_UNDERLINE);
                }

                if ( nodeIsEM(node->content) )
                {
                    AccessReport( doc, node, TidyWarning, POTENTIAL_HEADER_ITALICS);
                }
            }
        }
    }
}


/*********************************************************
* CheckSelect
*
* Checks to see if a LABEL follows the SELECT element.
*********************************************************/

static void CheckSelect( TidyDocImpl* doc, Node* node )
{
    Node* temp;
    tmbstr label;
    int flag = 0;

    Bool HasLabelBefore = no;
    Bool HasLabelAfter = no;

    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Check to see if there is a LABEL preceding SELECT */
        if ( node->prev != NULL && node->prev->prev != NULL )
        {
            if ( nodeIsLABEL(node->prev->prev) )
            {
                temp = node->prev->prev;
                
                if ( nodeIsText(temp->content) )
                {
                    label = textFromOneNode( doc, temp->content );
                    if ( !IsWhitespace(label) )
                    {
                        flag = 1;
                        HasLabelBefore = yes;
                    }
                }
            }

            /* Check to see if there is a LABEL following SELECT */
            if (flag == 0)
            {
                if ( nodeIsLABEL(node) )
                {
                    temp = node->next->next;
                    
                    if ( nodeIsText(temp->content) )
                    {
                        label = textFromOneNode( doc, temp->content );
                        if ( !IsWhitespace(label) )
                        {
                            flag = 1;
                            HasLabelAfter = yes;
                        }
                    }
                }
            }

            if ( !HasLabelAfter )
                AccessReport( doc, node, TidyError, LABEL_NEEDS_REPOSITIONING_AFTER_INPUT);

            if (HasLabelBefore == no)
                AccessReport( doc, node, TidyError, LABEL_NEEDS_REPOSITIONING_BEFORE_INPUT);
        }
    }
}


/************************************************************
* CheckTextArea
*
* TEXTAREA must contain a label description either before 
* or after the TEXTAREA element. Text must exist within 
* TEXTAREA.
************************************************************/

static void CheckTextArea( TidyDocImpl* doc, Node* node )
{
    int flag = 0;
    
    Bool HasLabelAfter = no;
    Bool HasLabelBefore = no;

    tmbstr label;
    Node* temp;

    if ((doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        /* Check to see if there is a LABEL before or after TEXTAREA */
        if (node->prev != NULL && node->prev->prev != NULL)
        {
            if ( nodeIsLABEL(node->prev->prev) )
            {
                temp = node->prev->prev;
                
                if ( nodeIsText(temp->content) )
                {
                    label = textFromOneNode( doc, temp->content );
                    if ( !IsWhitespace(label) )
                    {
                        flag = 1;
                        HasLabelBefore = yes;
                    }
                }
            }

            if (flag == 0)
            {
                if ( nodeIsLABEL(node->next->next) )
                {
                    temp = node->next->next;
                    
                    if ( nodeIsText(temp->content) )
                    {
                        label = textFromOneNode( doc, temp->content);
                        if ( !IsWhitespace(label) )
                        {
                            flag = 1;
                            HasLabelAfter = yes;
                        }
                    }
                }
            }
        
            if ( !HasLabelAfter )
                AccessReport( doc, node, TidyError, LABEL_NEEDS_REPOSITIONING_AFTER_INPUT);

            if ( !HasLabelBefore )
                AccessReport( doc, node, TidyError, LABEL_NEEDS_REPOSITIONING_BEFORE_INPUT);
        }
    }
}


/****************************************************************
* CheckEmbed
*
* Checks to see if 'SRC' is a multimedia type.  Must have 
* syncronized captions if used.
****************************************************************/

static void CheckEmbed( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        AttVal* av = attrGetSRC( node );
        if ( hasValue(av) && IsValidMediaExtension(av->value) )
        {
             AccessReport( doc, node, TidyError, MULTIMEDIA_REQUIRES_TEXT );
        }
    }
}


/*********************************************************************
* CheckHTMLAccess
*
* Checks HTML element for valid 'LANG' attribute.  Must be a valid
* language.  ie. 'fr' or 'en'
********************************************************************/

static void CheckHTMLAccess( TidyDocImpl* doc, Node* node )
{
    Bool ValidLang = no;

    if ( doc->access.PRIORITYCHK == 3 )
    {
        AttVal* av = attrGetLANG( node );
        if ( av )
        {
            ValidLang = yes;
            if ( !hasValue(av) )
                AccessReport( doc, node, TidyError, LANGUAGE_INVALID );
        }
        if ( !ValidLang )
            AccessReport( doc, node, TidyError, LANGUAGE_NOT_IDENTIFIED );
    }
}


/********************************************************
* CheckBlink
*
* Document must not contain the BLINK element.  
* It is invalid HTML/XHTML.
*********************************************************/

static void CheckBlink( TidyDocImpl* doc, Node* node )
{
    
    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Checks to see if text is found within the BLINK element. */
        if ( nodeIsText(node->content) )
        {
            tmbstr word = textFromOneNode( doc, node->content );
            if ( !IsWhitespace(word) )
            {
                AccessReport( doc, node, TidyError, REMOVE_BLINK_MARQUEE );
            }
        }
    }
}


/********************************************************
* CheckMarquee
*
* Document must not contain the MARQUEE element.
* It is invalid HTML/XHTML.
********************************************************/


static void CheckMarquee( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Checks to see if there is text in between the MARQUEE element */
        if ( nodeIsText(node) )
        {
            tmbstr word = textFromOneNode( doc, node->content);
            if ( !IsWhitespace(word) )
            {
                AccessReport( doc, node, TidyError, REMOVE_BLINK_MARQUEE );
            }
        }
    }
}


/**********************************************************
* CheckLink
*
* 'REL' attribute within the LINK element must not contain
* 'stylesheet'.  HTML/XHTML document is unreadable when
* style sheets are applied.  -- CPR huh?
**********************************************************/

static void CheckLink( TidyDocImpl* doc, Node* node )
{
    Bool HasRel = no;
    Bool HasType = no;

    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        AttVal* av;
        /* Check for valid 'REL' and 'TYPE' attribute */
        for (av = node->attributes; av != null; av = av->next)
        {
            if ( attrIsREL(av) && hasValue(av) )
            {
                if ( strstr(av->value, "stylesheet") != NULL )
                    HasRel = yes;
            }

            if ( attrIsTYPE(av) && hasValue(av) )
            {
                HasType = yes;
            }
        }

        AccessReport( doc, node, TidyWarning,
                      STYLESHEETS_REQUIRE_TESTING_LINK );
    }
}


/*******************************************************
* CheckStyle
*
* Document must not contain STYLE element.  HTML/XHTML 
* document is unreadable when style sheets are applied.
*******************************************************/

static void CheckStyle( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        AccessReport( doc, node, TidyWarning,
                      STYLESHEETS_REQUIRE_TESTING_STYLE_ELEMENT );
    }
}


/*************************************************************
* DynamicContent
*
* Verify that equivalents of dynamic content are updated and 
* available as often as the dynamic content.
*************************************************************/


static void DynamicContent( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        uint msgcode = 0;
        if ( nodeIsAPPLET(node) )
            msgcode = TEXT_EQUIVALENTS_REQUIRE_UPDATING_APPLET;
        else if ( nodeIsSCRIPT(node) )
            msgcode = TEXT_EQUIVALENTS_REQUIRE_UPDATING_SCRIPT;
        else if ( nodeIsOBJECT(node) )
            msgcode = TEXT_EQUIVALENTS_REQUIRE_UPDATING_OBJECT;

        if ( msgcode )
            AccessReport( doc, node, TidyWarning, msgcode );
    }
}


/*************************************************************
* ProgrammaticObjects
*
* Verify that the page is usable when programmatic objects 
* are disabled.
*************************************************************/

static void ProgrammaticObjects( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        int msgcode = 0;
        if ( nodeIsSCRIPT(node) )
            msgcode = PROGRAMMATIC_OBJECTS_REQUIRE_TESTING_SCRIPT;
        else if ( nodeIsOBJECT(node) )
            msgcode = PROGRAMMATIC_OBJECTS_REQUIRE_TESTING_OBJECT;
        else if ( nodeIsEMBED(node) )
            msgcode = PROGRAMMATIC_OBJECTS_REQUIRE_TESTING_EMBED;
        else if ( nodeIsAPPLET(node) )
            msgcode = PROGRAMMATIC_OBJECTS_REQUIRE_TESTING_APPLET;

        if ( msgcode )
            AccessReport( doc, node, TidyWarning, msgcode );
    }
}


/*************************************************************
* AccessibleCompatible
*
* Verify that programmatic objects are directly accessible.
*************************************************************/

static void AccessibleCompatible( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        int msgcode = 0;
        if ( nodeIsSCRIPT(node) )
            msgcode = ENSURE_PROGRAMMATIC_OBJECTS_ACCESSIBLE_SCRIPT;
        else if ( nodeIsOBJECT(node) )
            msgcode = ENSURE_PROGRAMMATIC_OBJECTS_ACCESSIBLE_OBJECT;
        else if ( nodeIsEMBED(node) )
            msgcode = ENSURE_PROGRAMMATIC_OBJECTS_ACCESSIBLE_EMBED;
        else if ( nodeIsAPPLET(node) )
            msgcode = ENSURE_PROGRAMMATIC_OBJECTS_ACCESSIBLE_APPLET;

        if ( msgcode )
            AccessReport( doc, node, TidyWarning, msgcode );
    }
}


/********************************************************
* WordCount
*
* Counts the number of words in the document.  Must have
* more than 3 words to verify changes in natural
* language of document.
*
* CPR - Not sure what intent is here, but this 
* routine has nothing to do with changes in language.
* It seems like a bad idea to emit this message for
* every document with _more_ than 3 words!
********************************************************/

static int WordCount( TidyDocImpl* doc, Node* node )
{
    int wc = 0;

    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Count the number of words found within a text node */
        if ( nodeIsText( node ) )
        {
            tmbchar ch;
            tmbstr word = textFromOneNode( doc, node );
            if ( !IsWhitespace(word) )
            {
                ++wc;
                while ( (ch = *word++) && wc < 5 )
                {
                    if ( ch == ' ')
                        ++wc;
                }
            }
        }

        for ( node = node->content; wc < 5 && node; node = node->next )
        {
            wc += WordCount( doc, node );
        }
    }
    return wc;
}


/**************************************************
* CheckFlicker
*
* Verify that the page does not cause flicker.
**************************************************/

static void CheckFlicker( TidyDocImpl* doc, Node* node )
{
    if ((doc->access.PRIORITYCHK == 1)||
        (doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        int msgcode = 0;
        if ( nodeIsSCRIPT(node) )
            msgcode = REMOVE_FLICKER_SCRIPT;
        else if ( nodeIsOBJECT(node) )
            msgcode = REMOVE_FLICKER_OBJECT;
        else if ( nodeIsEMBED(node) )
            msgcode = REMOVE_FLICKER_EMBED;
        else if ( nodeIsAPPLET(node) )
            msgcode = REMOVE_FLICKER_APPLET;

        /* Checks for animated gif within the <img> tag. */
        else if ( nodeIsIMG(node) )
        {
            AttVal* av = attrGetSRC( node );
            if ( hasValue(av) )
            {
                tmbchar ext[20];
                GetFileExtension( av->value, ext, sizeof(ext) );
                if ( tmbstrcasecmp(ext, ".gif") == 0 )
                    msgcode = REMOVE_FLICKER_ANIMATED_GIF;
            }
        }            

        if ( msgcode )
            AccessReport( doc, node, TidyWarning, msgcode );
    }
}


/**********************************************************
* CheckDeprecated
*
* APPLET, BASEFONT, CENTER, FONT, ISINDEX, 
* S, STRIKE, and U should not be used.  Becomes deprecated
* HTML if any of the above are used.
**********************************************************/

static void CheckDeprecated( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        int msgcode = 0;
        if ( nodeIsAPPLET(node) )
            msgcode = REPLACE_DEPRECATED_HTML_APPLET;
        else if ( nodeIsBASEFONT(node) )
            msgcode = REPLACE_DEPRECATED_HTML_BASEFONT;
        else if ( nodeIsCENTER(node) )
            msgcode = REPLACE_DEPRECATED_HTML_CENTER;
        else if ( nodeIsDIR(node) )
            msgcode = REPLACE_DEPRECATED_HTML_DIR;
        else if ( nodeIsFONT(node) )
            msgcode = REPLACE_DEPRECATED_HTML_FONT;
        else if ( nodeIsISINDEX(node) )
            msgcode = REPLACE_DEPRECATED_HTML_ISINDEX;
        else if ( nodeIsMENU(node) )
            msgcode = REPLACE_DEPRECATED_HTML_MENU;
        else if ( nodeIsS(node) )
            msgcode = REPLACE_DEPRECATED_HTML_S;
        else if ( nodeIsSTRIKE(node) )
            msgcode = REPLACE_DEPRECATED_HTML_STRIKE;
        else if ( nodeIsU(node) )
            msgcode = REPLACE_DEPRECATED_HTML_U;

        if ( msgcode )
            AccessReport( doc, node, TidyError, msgcode );
    }
}


/************************************************************
* CheckScriptKeyboardAccessible
*
* Elements must have a device independent event handler if 
* they have any of the following device dependent event 
* handlers. 
************************************************************/

static void CheckScriptKeyboardAccessible( TidyDocImpl* doc, Node* node )
{
    int HasOnMouseDown = 0;
    int HasOnMouseUp = 0;
    int HasOnClick = 0;
    int HasOnMouseOut = 0;
    int HasOnMouseOver = 0;
    int HasOnMouseMove = 0;

    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        AttVal* av;
        /* Checks all elements for their attributes */
        for (av = node->attributes; av != null; av = av->next)
        {
            /* Must also have 'ONKEYDOWN' attribute with 'ONMOUSEDOWN' */
            if ( attrIsOnMOUSEDOWN(av) )
                HasOnMouseDown++;

            /* Must also have 'ONKEYUP' attribute with 'ONMOUSEUP' */
            if ( attrIsOnMOUSEUP(av) )
                HasOnMouseUp++;

            /* Must also have 'ONKEYPRESS' attribute with 'ONCLICK' */
            if ( attrIsOnCLICK(av) )
                HasOnClick++;

            /* Must also have 'ONBLUR' attribute with 'ONMOUSEOUT' */
            if ( attrIsOnMOUSEOUT(av) )
                HasOnMouseOut++;

            if ( attrIsOnMOUSEOVER(av) )
                HasOnMouseOver++;

            if ( attrIsOnMOUSEMOVE(av) )
                HasOnMouseMove++;

            if ( attrIsOnKEYDOWN(av) )
                HasOnMouseDown++;

            if ( attrIsOnKEYUP(av) )
                HasOnMouseUp++;

            if ( attrIsOnKEYPRESS(av) )
                HasOnClick++;

            if ( attrIsOnBLUR(av) )
                HasOnMouseOut++;
        }

        if ( HasOnMouseDown == 1 )
        {
            AccessReport( doc, node, TidyError, SCRIPT_NOT_KEYBOARD_ACCESSIBLE_ON_MOUSE_DOWN);
        }

        if ( HasOnMouseUp == 1 )
        {
            AccessReport( doc, node, TidyError, SCRIPT_NOT_KEYBOARD_ACCESSIBLE_ON_MOUSE_UP);
        }
        
        if ( HasOnClick == 1 )
        {
            AccessReport( doc, node, TidyError, SCRIPT_NOT_KEYBOARD_ACCESSIBLE_ON_CLICK);
        }
            
        if ( HasOnMouseOut == 1 )
        {
            AccessReport( doc, node, TidyError, SCRIPT_NOT_KEYBOARD_ACCESSIBLE_ON_MOUSE_OUT);
        }
        
        if ( HasOnMouseOver == 1 )
        {
            AccessReport( doc, node, TidyError, SCRIPT_NOT_KEYBOARD_ACCESSIBLE_ON_MOUSE_OVER);
        }

        if ( HasOnMouseMove == 1 )
        {
            AccessReport( doc, node, TidyError, SCRIPT_NOT_KEYBOARD_ACCESSIBLE_ON_MOUSE_MOVE);
        }
    }
}


/**********************************************************
* CheckMetaData
*
* Must have at least one of these elements in the document.
* META, LINK, TITLE or ADDRESS.  <meta> must contain 
* a "content" attribute that doesn't contain a URL, and
* an "http-Equiv" attribute that doesn't contain 'refresh'.
**********************************************************/


static Bool CheckMetaData( TidyDocImpl* doc, Node* node )
{
    Bool HasHttpEquiv = no;
    Bool HasContent = no;
    Bool HasRel = no;
    Bool ContainsAttr = no;
    Bool HasMetaData = no;

    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        if ( nodeIsMETA(node) )
        {
            AttVal* av;
            for (av = node->attributes; av != null; av = av->next)
            {
                if ( attrIsHTTP_EQUIV(av) && hasValue(av) )
                {
                    ContainsAttr = yes;

                    /* Must not have an auto-refresh */
                    if ( strcmp(av->value, "refresh") == 0 )
                    {
                        HasHttpEquiv = yes;
                        AccessReport( doc, node, TidyError, REMOVE_AUTO_REFRESH );
                    }
                }

                if ( attrIsCONTENT(av) && hasValue(av) )
                {
                    ContainsAttr = yes;

                    /* If the value is not an integer, then it must not be a URL */
                    if ( tmbstrncmp(av->value, "http:", 5) == 0)
                    {
                        HasContent = yes;
                        AccessReport( doc, node, TidyError, REMOVE_AUTO_REDIRECT);
                    }
                }
            }
        
            if ( HasContent || HasHttpEquiv )
            {
                HasMetaData = yes;
                AccessReport( doc, node, TidyError, METADATA_MISSING_REDIRECT_AUTOREFRESH);
            }
            else
            {
                if ( ContainsAttr && !HasContent && !HasHttpEquiv )
                    HasMetaData = yes;                    
            }
        }

        if ( !HasMetaData && 
             nodeIsADDRESS(node) &&
             nodeIsA(node->content) )
        {
            HasMetaData = yes;
        }
            
        if ( !HasMetaData &&
             nodeIsTITLE(node) &&
             nodeIsText(node->content) )
        {
            tmbstr word = textFromOneNode( doc, node->content );
            if ( !IsWhitespace(word) )
                HasMetaData = yes;
        }

        if ( !HasMetaData &&
             nodeIsLINK(node) )
        {
            AttVal* av = attrGetREL(node);
            HasMetaData = yes;

            if ( hasValue(av) &&
                 strstr(av->value, "stylesheet") != NULL )
            {
                HasRel = yes;
                AccessReport( doc, node, TidyError, METADATA_MISSING_LINK );
            }
        }
            
        /* Check for MetaData */
        for ( node = node->content; !HasMetaData && node; node = node->next )
        {
            HasMetaData = CheckMetaData( doc, node);
        }
    }
    return HasMetaData;
}


/*******************************************************
* MetaDataPresent
*
* Determines if MetaData is present in document
*******************************************************/

static void MetaDataPresent( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        AccessReport( doc, node, TidyError, METADATA_MISSING );
    }
}


/*****************************************************
* CheckDocType
*
* Checks that every HTML/XHTML document contains a 
* '!DOCTYPE' before the root node. ie.  <HTML>
*****************************************************/

static void CheckDocType( TidyDocImpl* doc, Node* node )
{
    tmbstr word;
    Bool HasDocType = no;

    if ((doc->access.PRIORITYCHK == 2)||
        (doc->access.PRIORITYCHK == 3))
    {
        if (node->tag == NULL)
        {
            word = textFromOneNode( doc, node->content);
                
            if ((strstr (word, "HTML PUBLIC") == NULL) &&
                (strstr (word, "html PUBLIC") == NULL))
            {
                AccessReport( doc, node, TidyError, DOCTYPE_MISSING);
            }
        }
    }
}



/********************************************************
* CheckMapLinks
*
* Checks to see if an HREF for A element matches HREF
* for AREA element.  There must be an HREF attribute 
* of an A element for every HREF of an AREA element. 
********************************************************/

static Bool urlMatch( ctmbstr url1, ctmbstr url2 )
{
  /* TODO: Make host part case-insensitive and
  ** remainder case-sensitive.
  */
  return ( tmbstrcmp( url1, url2 ) == 0 );
}

static Bool FindLinkA( TidyDocImpl* doc, Node* node, ctmbstr url )
{
  Bool found = no;
  for ( node = node->content; !found && node; node = node->next )
  {
    if ( nodeIsA(node) )
    {
      AttVal* href = attrGetHREF( node );
      found = ( hasValue(href) && urlMatch(url, href->value) );
    }
    else
        found = FindLinkA( doc, node, url );
  }
  return found;
}

static void CheckMapLinks( TidyDocImpl* doc, Node* node )
{
    Node* child = node->content;

    /* Stores the 'HREF' link of an AREA element within a MAP element */
    for ( child = node->content; child != NULL; child = child->next )
    {
        if ( nodeIsAREA(child) )
        {
            /* Checks for 'HREF' attribute */                
            AttVal* href = attrGetHREF( child );
            if ( hasValue(href) &&
                 !FindLinkA( doc, doc->root, href->value ) )
            {
                AccessReport( doc, node, TidyError,
                              IMG_MAP_CLIENT_MISSING_TEXT_LINKS );
            }
        }
    }
}


/****************************************************
* CheckForStyleAttribute
*
* Checks all elements within the document to check 
* for the use of 'STYLE' attribute.
****************************************************/

static void CheckForStyleAttribute( TidyDocImpl* doc, Node* node )
{
    if ( doc->access.PRIORITYCHK == 1 ||
         doc->access.PRIORITYCHK == 2 ||
         doc->access.PRIORITYCHK == 3 )
    {
        /* Must not contain 'STYLE' attribute */
        AttVal* style = attrGetSTYLE( node );
        if ( hasValue(style) )
        {
            AccessReport( doc, node, TidyWarning,
                          STYLESHEETS_REQUIRE_TESTING_STYLE_ATTR );
        }
    }
}


/*****************************************************
* CheckForListElements
*
* Checks document for list elements (<ol>, <ul>, <li>)
*****************************************************/

static void CheckForListElements( TidyDocImpl* doc, Node* node )
{
    if ( nodeIsLI(node) )
    {
        doc->access.ListElements++;
    }
    else if ( nodeIsOL(node) || nodeIsUL(node) )
    {
        doc->access.OtherListElements++;
    }

    for ( node = node->content; node != null; node = node->next )
    {
        CheckForListElements( doc, node );
    }
}


/******************************************************
* CheckListUsage
*
* Ensures that lists are properly used.  <ol> and <ul>
* must contain <li> within itself, and <li> must not be
* by itself.
******************************************************/

static void CheckListUsage( TidyDocImpl* doc, Node* node )
{
    int msgcode = 0;
    if ( nodeIsOL(node) )
        msgcode = LIST_USAGE_INVALID_OL;
    else if ( nodeIsUL(node) )
        msgcode = LIST_USAGE_INVALID_UL;

    if ( msgcode )
    {
        if ( !nodeIsLI(node->content) )
            AccessReport( doc, node, TidyWarning, msgcode );
    }
    else if ( nodeIsLI(node) )
    {
        /* Check that LI parent 
        ** a) exists,
        ** b) is either OL or UL
        */
        if ( node->parent == NULL ||
             ( !nodeIsOL(node->parent) && !nodeIsUL(node->parent) ) )
        {
            AccessReport( doc, node, TidyWarning, LIST_USAGE_INVALID_LI );
        }
    }
}

/************************************************************
* InitAccessibilityChecks
*
* Initializes the AccessibilityChecks variables as necessary
************************************************************/

void InitAccessibilityChecks( TidyDocImpl* doc, int level123 )
{
    ClearMemory( &doc->access, sizeof(doc->access) );
    doc->access.PRIORITYCHK = level123;
}

/************************************************************
* CleanupAccessibilityChecks
*
* Cleans up the AccessibilityChecks variables as necessary
************************************************************/


void FreeAccessibilityChecks( TidyDocImpl* doc )
{
    /* free any memory allocated for the lists

    Linked List of Links not used.  Just search document as 
    AREA tags are encountered.  Same algorithm, but no
    data structures necessary.

    current = start;
    while (current)
    {
        void    *templink = (void *)current;
        
        current = current->next;
        MemFree(templink);
    }
    start = NULL;
    */
}

/************************************************************
* AccessibilityChecks
*
* Traverses through the individual nodes of the tree
* and checks attributes and elements for accessibility.
* after the tree structure has been formed.
************************************************************/

static void AccessibilityCheckNode( TidyDocImpl* doc, Node* node )
{
    Node* content;
    
    /* Check BODY for color contrast */
    if ( nodeIsBODY(node) )
    {
        CheckColorContrast( doc, node );
    }

    /* Checks document for MetaData */
    else if ( nodeIsHEAD(node) )
    {
        if ( !CheckMetaData( doc, node ) )
          MetaDataPresent( doc, node );
    }
    
    /* Check the ANCHOR tag */
    else if ( nodeIsA(node) )
    {
        CheckAnchorAccess( doc, node );
    }

    /* Check the IMAGE tag */
    else if ( nodeIsIMG(node) )
    {
        CheckFlicker( doc, node );
        CheckColorAvailable( doc, node );
        CheckImage( doc, node );
    }

        /* Checks MAP for client-side text links */
    else if ( nodeIsMAP(node) )
    {
        CheckMapLinks( doc, node );
    }

    /* Check the AREA tag */
    else if ( nodeIsAREA(node) )
    {
        CheckArea( doc, node );
    }

    /* Check the APPLET tag */
    else if ( nodeIsAPPLET(node) )
    {
        CheckDeprecated( doc, node );
        ProgrammaticObjects( doc, node );
        DynamicContent( doc, node );
        AccessibleCompatible( doc, node );
        CheckFlicker( doc, node );
        CheckColorAvailable( doc, node );
        CheckApplet(doc, node );
    }
    
    /* Check the OBJECT tag */
    else if ( nodeIsOBJECT(node) )
    {
        ProgrammaticObjects( doc, node );
        DynamicContent( doc, node );
        AccessibleCompatible( doc, node );
        CheckFlicker( doc, node );
        CheckColorAvailable( doc, node );
        CheckObject( doc, node );
    }
    
    /* Check the FRAME tag */
    else if ( nodeIsFRAME(node) )
    {
        CheckFrame( doc, node );
    }
    
    /* Check the IFRAME tag */
    else if ( nodeIsIFRAME(node) )
    {
        CheckIFrame( doc, node );
    }
    
    /* Check the SCRIPT tag */
    else if ( nodeIsSCRIPT(node) )
    {
        DynamicContent( doc, node );
        ProgrammaticObjects( doc, node );
        AccessibleCompatible( doc, node );
        CheckFlicker( doc, node );
        CheckColorAvailable( doc, node );
        CheckScriptAcc( doc, node );
    }

    /* Check the TABLE tag */
    else if ( nodeIsTABLE(node) )
    {
        CheckColorContrast( doc, node );
        CheckTable( doc, node );
    }

    /* Check the PRE for ASCII art */
    else if ( nodeIsPRE(node) || nodeIsXMP(node) )
    {
        CheckASCII( doc, node );
    }

    /* Check the LABEL tag */
    else if ( nodeIsLABEL(node) )
    {
        CheckLabel( doc, node );
    }

    /* Check INPUT tag for validity */
    else if ( nodeIsINPUT(node) )
    {
        CheckColorAvailable( doc, node );
        CheckInputLabel( doc, node );
        CheckInputAttributes( doc, node );
    }

    /* Checks FRAMESET element for NOFRAME section */
    else if ( nodeIsFRAMESET(node) )
    {
        CheckFrameSet( doc, node );
    }
    
    /* Checks for header elements for valid header increase */
    else if ( nodeIsHeader(node) )
    {
        CheckHeaderNesting( doc, node );
    }

    /* Checks P element to ensure that it is not a header */
    else if ( nodeIsP(node) )
    {
        CheckParagraphHeader( doc, node );
    }

    /* Checks SELECT element for LABEL */
    else if ( nodeIsSELECT(node) )
    {
        CheckSelect( doc, node );
    }

    /* Checks TEXTAREA element for LABEL */
    else if ( nodeIsTEXTAREA(node) )
    {
        CheckTextArea( doc, node );
    }

    /* Checks HTML elemnt for valid 'LANG' */
    else if ( nodeIsHTML(node) )
    {
        CheckHTMLAccess( doc, node );
    }

    /* Checks BLINK for any blinking text */
    else if ( nodeIsBLINK(node) )
    {
        CheckBlink( doc, node );
    }

    /* Checks MARQUEE for any MARQUEE text */
    else if ( nodeIsMARQUEE(node) )
    {
        CheckMarquee( doc, node );
    }

    /* Checks LINK for 'REL' attribute */
    else if ( nodeIsLINK(node) )
    {
        CheckLink( doc, node );
    }

    /* Checks to see if STYLE is used */
    else if ( nodeIsSTYLE(node) )
    {
        CheckColorContrast( doc, node );
        CheckStyle( doc, node );
    }

    /* Checks to see if EMBED is used */
    else if ( nodeIsEMBED(node) )
    {
        CheckEmbed( doc, node );
        ProgrammaticObjects( doc, node );
        AccessibleCompatible( doc, node );
        CheckFlicker( doc, node );
    }

    /* Deprecated HTML if the following tags are found in the document */
    else if ( nodeIsBASEFONT(node) ||
              nodeIsCENTER(node)   ||
              nodeIsISINDEX(node)  ||
              nodeIsU(node)        ||
              nodeIsFONT(node)     ||
              nodeIsDIR(node)      ||
              nodeIsS(node)        ||
              nodeIsSTRIKE(node)   ||
              nodeIsMENU(node) )
    {
        CheckDeprecated( doc, node );
    }

    /* Checks for 'ABBR' attribute if needed */
    else if ( nodeIsTH(node) )
    {
        CheckTH( doc, node );
    }

    /* Ensures that lists are properly used */
    else if ( nodeIsLI(node) || nodeIsOL(node) || nodeIsUL(node) )
    {
        CheckListUsage( doc, node );
    }

    /* Recursively check all child nodes.
    */
    for ( content = node->content; content != null; content = content->next )
    {
        AccessibilityCheckNode( doc, content );
    }
}


void AccessibilityChecks( TidyDocImpl* doc )
{
    /* Initialize */
    InitAccessibilityChecks( doc, cfg(doc, TidyAccessibilityCheckLevel) );

    /* Hello there, ladies and gentlemen... */
    tidy_out( doc, "\n" );
    tidy_out( doc, "Accessibility Checks: Version 0.1\n" );
    tidy_out( doc, "\n" );

    /* Checks all elements for script accessibility */
    CheckScriptKeyboardAccessible( doc, doc->root );

    /* Checks entire document for the use of 'STYLE' attribute */
    CheckForStyleAttribute( doc, doc->root );

    /* Checks for '!DOCTYPE' */
    CheckDocType( doc, doc->root );

    
    /* Checks to see if stylesheets are used to control the layout */
    if ( ! CheckMissingStyleSheets( doc, doc->root ) )
    {
        AccessReport( doc, doc->root, TidyWarning,
                      STYLE_SHEET_CONTROL_PRESENTATION );
    }

    /* Check to see if any list elements are found within the document */
    CheckForListElements( doc, doc->root );

    /* Checks for natural language change */
    /* Must contain more than 3 words of text in the document
    **
    ** CPR - Not sure what intent is here, but this 
    ** routine has nothing to do with changes in language.
    ** It seems like a bad idea to emit this message for
    ** every document with _more_ than 3 words!

    if ( WordCount(doc, doc->root) > 3 )
    {
        AccessReport( doc, node, TidyWarning, INDICATE_CHANGES_IN_LANGUAGE);
    }
    */


    /* Recursively apply all remaining checks to 
    ** each node in document.
    */
    AccessibilityCheckNode( doc, doc->root );

    /* Cleanup */
    FreeAccessibilityChecks( doc );
}

#endif
