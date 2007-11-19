/* attrs.c -- recognize HTML attributes

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.54 $ 

*/

#include "tidy-int.h"
#include "attrs.h"
#include "message.h"
#include "tmbstr.h"

#define TEXT        null
#define CHARSET     null
#define TYPE        null
#define CHARACTER   null
#define URLS        null
#define URL         CheckUrl
#define SCRIPT      CheckScript
#define ALIGN       CheckAlign
#define VALIGN      CheckValign
#define COLOR       CheckColor
#define CLEAR       CheckClear
#define BORDER      CheckBool     /* kludge */
#define LANG        CheckLang
#define BOOL        CheckBool
#define COLS        null
#define NUMBER      CheckNumber
#define LENGTH      CheckLength
#define COORDS      null
#define DATE        null
#define TEXTDIR     CheckTextDir
#define IDREFS      null
#define IDREF       null
#define IDDEF       CheckId
#define NAME        CheckName
#define TFRAME      null
#define FBORDER     null
#define MEDIA       null
#define FSUBMIT     CheckFsubmit
#define LINKTYPES   null
#define TRULES      null
#define SCOPE       CheckScope
#define SHAPE       CheckShape
#define SCROLL      CheckScroll
#define TARGET      CheckTarget
#define VTYPE       CheckVType

/*
*/

static const Attribute attribute_defs [] =
{
  {TidyAttr_UNKNOWN,  "unknown!",     VERS_PROPRIETARY,  null},
  {TidyAttr_ABBR,     "abbr",         VERS_HTML40,       TEXT},
  {TidyAttr_ACCEPT,   "accept",       VERS_ALL,          TYPE},
  {TidyAttr_ACCEPT_CHARSET, "accept-charset", VERS_HTML40, CHARSET},
  {TidyAttr_ACCESSKEY, "accesskey",   VERS_HTML40,       CHARACTER},
  {TidyAttr_ACTION,   "action",       VERS_ALL,          URL},
  {TidyAttr_ADD_DATE, "add_date",     VERS_NETSCAPE,     TEXT},     /* A */
  {TidyAttr_ALIGN,    "align",        VERS_ALL,          ALIGN},    /* varies by element */
  {TidyAttr_ALINK,    "alink",        VERS_LOOSE,        COLOR},
  {TidyAttr_ALT,      "alt",          VERS_ALL,          TEXT,  yes }, /* nowrap */
  {TidyAttr_ARCHIVE,  "archive",      VERS_HTML40,       URLS},     /* space or comma separated list */
  {TidyAttr_AXIS,     "axis",         VERS_HTML40,       TEXT},
  {TidyAttr_BACKGROUND, "background", VERS_LOOSE,        URL},
  {TidyAttr_BGCOLOR,  "bgcolor",      VERS_LOOSE,        COLOR},
  {TidyAttr_BGPROPERTIES, "bgproperties", VERS_PROPRIETARY, TEXT},  /* BODY "fixed" fixes background */
  {TidyAttr_BORDER,   "border",       VERS_ALL,          BORDER},   /* like LENGTH + "border" */
  {TidyAttr_BORDERCOLOR, "bordercolor",  VERS_MICROSOFT, COLOR},    /* used on TABLE */
  {TidyAttr_BOTTOMMARGIN, "bottommargin",VERS_MICROSOFT, NUMBER},   /* used on BODY */
  {TidyAttr_CELLPADDING, "cellpadding", VERS_FROM32,     LENGTH},   /* % or pixel values */
  {TidyAttr_CELLSPACING, "cellspacing", VERS_FROM32,     LENGTH},
  {TidyAttr_CHAR,     "char",         VERS_HTML40,       CHARACTER},
  {TidyAttr_CHAROFF,  "charoff",      VERS_HTML40,       LENGTH},
  {TidyAttr_CHARSET,  "charset",      VERS_HTML40,       CHARSET},
  {TidyAttr_CHECKED,  "checked",      VERS_ALL,          BOOL},     /* i.e. "checked" or absent */
  {TidyAttr_CITE,     "cite",         VERS_HTML40,       URL},
  {TidyAttr_CLASS,    "class",        VERS_HTML40,       TEXT},
  {TidyAttr_CLASSID,  "classid",      VERS_HTML40,       URL},
  {TidyAttr_CLEAR,    "clear",        VERS_LOOSE,        CLEAR},    /* BR: left, right, all */
  {TidyAttr_CODE,     "code",         VERS_LOOSE,        TEXT},     /* APPLET */
  {TidyAttr_CODEBASE, "codebase",     VERS_HTML40,       URL},      /* OBJECT */
  {TidyAttr_CODETYPE, "codetype",     VERS_HTML40,       TYPE},     /* OBJECT */
  {TidyAttr_COLOR,    "color",        VERS_LOOSE,        COLOR},    /* BASEFONT, FONT */
  {TidyAttr_COLS,     "cols",         VERS_IFRAME,       COLS},     /* TABLE & FRAMESET */
  {TidyAttr_COLSPAN,  "colspan",      VERS_FROM32,       NUMBER},
  {TidyAttr_COMPACT,  "compact",      VERS_ALL,          BOOL},     /* lists */
  {TidyAttr_CONTENT,  "content",      VERS_ALL,          TEXT, yes},/* META, nowrap */
  {TidyAttr_COORDS,   "coords",       VERS_FROM32,       COORDS},   /* AREA, A */    
  {TidyAttr_DATA,     "data",         VERS_HTML40,       URL},      /* OBJECT */
  {TidyAttr_DATAFLD,  "datafld",      VERS_MICROSOFT,    TEXT},     /* used on DIV, IMG */
  {TidyAttr_DATAFORMATAS, "dataformatas", VERS_MICROSOFT,TEXT},     /* used on DIV, IMG */
  {TidyAttr_DATAPAGESIZE, "datapagesize", VERS_MICROSOFT,NUMBER},   /* used on DIV, IMG */
  {TidyAttr_DATASRC,  "datasrc",      VERS_MICROSOFT,    URL},      /* used on TABLE */
  {TidyAttr_DATETIME, "datetime",     VERS_HTML40,       DATE},     /* INS, DEL */
  {TidyAttr_DECLARE,  "declare",      VERS_HTML40,       BOOL},     /* OBJECT */
  {TidyAttr_DEFER,    "defer",        VERS_HTML40,       BOOL},     /* SCRIPT */
  {TidyAttr_DIR,      "dir",          VERS_HTML40,       TEXTDIR},  /* ltr or rtl */
  {TidyAttr_DISABLED, "disabled",     VERS_HTML40,       BOOL},     /* form fields */
  {TidyAttr_ENCODING, "encoding",     VERS_XML,          TEXT},     /* <?xml?> */
  {TidyAttr_ENCTYPE,  "enctype",      VERS_ALL,          TYPE},     /* FORM */
  {TidyAttr_FACE,     "face",         VERS_LOOSE,        TEXT},     /* BASEFONT, FONT */
  {TidyAttr_FOR,      "for",          VERS_HTML40,       IDREF},    /* LABEL */
  {TidyAttr_FRAME,    "frame",        VERS_HTML40,       TFRAME},   /* TABLE */
  {TidyAttr_FRAMEBORDER, "frameborder", VERS_FRAMESET,   FBORDER},  /* 0 or 1 */
  {TidyAttr_FRAMESPACING, "framespacing", VERS_PROPRIETARY, NUMBER},/* pixel value */
  {TidyAttr_GRIDX,    "gridx",        VERS_PROPRIETARY,  NUMBER},   /* TABLE Adobe golive*/
  {TidyAttr_GRIDY,    "gridy",        VERS_PROPRIETARY,  NUMBER},   /* TABLE Adobe golive */
  {TidyAttr_HEADERS,  "headers",      VERS_HTML40,       IDREFS},   /* table cells */
  {TidyAttr_HEIGHT,   "height",       VERS_ALL,          LENGTH},   /* pixels only for TH/TD */
  {TidyAttr_HREF,     "href",         VERS_ALL,          URL},      /* A, AREA, LINK and BASE */
  {TidyAttr_HREFLANG, "hreflang",     VERS_HTML40,       LANG},     /* A, LINK */
  {TidyAttr_HSPACE,   "hspace",       VERS_ALL,          NUMBER},   /* APPLET, IMG, OBJECT */
  {TidyAttr_HTTP_EQUIV, "http-equiv", VERS_ALL,          TEXT},     /* META */
  {TidyAttr_ID,       "id",           VERS_HTML40,       IDDEF},
  {TidyAttr_ISMAP,    "ismap",        VERS_ALL,          BOOL},     /* IMG */
  {TidyAttr_LABEL,    "label",        VERS_HTML40,       TEXT},     /* OPT, OPTGROUP */
  {TidyAttr_LANG,     "lang",         VERS_HTML40,       LANG},
  {TidyAttr_LANGUAGE, "language",     VERS_LOOSE,        TEXT},     /* SCRIPT */
  {TidyAttr_LAST_MODIFIED, "last_modified", VERS_NETSCAPE, TEXT},   /* A */
  {TidyAttr_LAST_VISIT, "last_visit", VERS_NETSCAPE,     TEXT},     /* A */
  {TidyAttr_LEFTMARGIN, "leftmargin", VERS_MICROSOFT,    NUMBER},   /* used on BODY */
  {TidyAttr_LINK,     "link",         VERS_LOOSE,        COLOR},    /* BODY */
  {TidyAttr_LONGDESC, "longdesc",     VERS_HTML40,       URL},      /* IMG */
  {TidyAttr_LOWSRC,   "lowsrc",       VERS_PROPRIETARY,  URL},      /* IMG */
  {TidyAttr_MARGINHEIGHT, "marginheight", VERS_IFRAME,   NUMBER},   /* FRAME, IFRAME, BODY */
  {TidyAttr_MARGINWIDTH, "marginwidth", VERS_IFRAME,     NUMBER},   /* ditto */
  {TidyAttr_MAXLENGTH, "maxlength",   VERS_ALL,          NUMBER},   /* INPUT */
  {TidyAttr_MEDIA,    "media",        VERS_HTML40,       MEDIA},    /* STYLE, LINK */
  {TidyAttr_METHOD,   "method",       VERS_ALL,          FSUBMIT},  /* FORM: get or post */
  {TidyAttr_MULTIPLE, "multiple",     VERS_ALL,          BOOL},     /* SELECT */
  {TidyAttr_NAME,     "name",         VERS_ALL,          NAME},
  {TidyAttr_NOHREF,   "nohref",       VERS_FROM32,       BOOL},     /* AREA */
  {TidyAttr_NORESIZE, "noresize",     VERS_FRAMESET,     BOOL},     /* FRAME */
  {TidyAttr_NOSHADE,  "noshade",      VERS_LOOSE,        BOOL},     /* HR */
  {TidyAttr_NOWRAP,   "nowrap",       VERS_LOOSE,        BOOL},     /* table cells */
  {TidyAttr_OBJECT,   "object",       VERS_HTML40_LOOSE, TEXT},     /* APPLET */
  {TidyAttr_OnAFTERUPDATE, "onafterupdate", VERS_MICROSOFT, SCRIPT},/* form fields */
  {TidyAttr_OnBEFOREUNLOAD, "onbeforeunload", VERS_MICROSOFT, SCRIPT},/* form fields */
  {TidyAttr_OnBEFOREUPDATE, "onbeforeupdate", VERS_MICROSOFT, SCRIPT},/* form fields */
  {TidyAttr_OnBLUR,   "onblur",       VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnCHANGE, "onchange",     VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnCLICK,  "onclick",      VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnDATAAVAILABLE, "ondataavailable", VERS_MICROSOFT, SCRIPT}, /* object, applet */
  {TidyAttr_OnDATASETCHANGED, "ondatasetchanged", VERS_MICROSOFT, SCRIPT}, /* object, applet */
  {TidyAttr_OnDATASETCOMPLETE, "ondatasetcomplete", VERS_MICROSOFT, SCRIPT},/* object, applet */
  {TidyAttr_OnDBLCLICK, "ondblclick", VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnERRORUPDATE, "onerrorupdate", VERS_MICROSOFT, SCRIPT},   /* form fields */
  {TidyAttr_OnFOCUS,  "onfocus",      VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnKEYDOWN,"onkeydown",    VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnKEYPRESS, "onkeypress", VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnKEYUP,  "onkeyup",      VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnLOAD,   "onload",       VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnMOUSEDOWN, "onmousedown", VERS_EVENTS,     SCRIPT},   /* event */
  {TidyAttr_OnMOUSEMOVE, "onmousemove", VERS_EVENTS,     SCRIPT},   /* event */
  {TidyAttr_OnMOUSEOUT, "onmouseout", VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnMOUSEOVER, "onmouseover", VERS_EVENTS,     SCRIPT},   /* event */
  {TidyAttr_OnMOUSEUP, "onmouseup",   VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnRESET,  "onreset",      VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnROWENTER, "onrowenter", VERS_MICROSOFT,    SCRIPT},   /* form fields */
  {TidyAttr_OnROWEXIT, "onrowexit",   VERS_MICROSOFT,    SCRIPT},   /* form fields */
  {TidyAttr_OnSELECT, "onselect",     VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnSUBMIT, "onsubmit",     VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_OnUNLOAD, "onunload",     VERS_EVENTS,       SCRIPT},   /* event */
  {TidyAttr_PROFILE,  "profile",      VERS_HTML40,       URL},      /* HEAD */
  {TidyAttr_PROMPT,   "prompt",       VERS_LOOSE,        TEXT},     /* ISINDEX */
  {TidyAttr_RBSPAN,   "rbspan",       VERS_XHTML11,      NUMBER},   /* ruby markup */
  {TidyAttr_READONLY, "readonly",     VERS_HTML40,       BOOL},     /* form fields */
  {TidyAttr_REL,      "rel",          VERS_ALL,          LINKTYPES},/* A, LINK */
  {TidyAttr_REV,      "rev",          VERS_ALL,          LINKTYPES},/* A, LINK */
  {TidyAttr_RIGHTMARGIN, "rightmargin", VERS_MICROSOFT,  NUMBER},   /* used on BODY */
  {TidyAttr_ROWS,     "rows",         VERS_ALL,          NUMBER},   /* TEXTAREA */
  {TidyAttr_ROWSPAN,  "rowspan",      VERS_ALL,          NUMBER},   /* table cells */
  {TidyAttr_RULES,    "rules",        VERS_HTML40,       TRULES},   /* TABLE */
  {TidyAttr_SCHEME,   "scheme",       VERS_HTML40,       TEXT},     /* META */
  {TidyAttr_SCOPE,    "scope",        VERS_HTML40,       SCOPE},    /* table cells */
  {TidyAttr_SCROLLING, "scrolling",   VERS_IFRAME,       SCROLL},   /* yes, no or auto */
  {TidyAttr_SELECTED, "selected",     VERS_ALL,          BOOL},     /* OPTION */
  {TidyAttr_SHAPE,    "shape",        VERS_FROM32,       SHAPE},    /* AREA, A */
  {TidyAttr_SHOWGRID, "showgrid",     VERS_PROPRIETARY,  BOOL},     /* TABLE Adobe golive */
  {TidyAttr_SHOWGRIDX,"showgridx",    VERS_PROPRIETARY,  BOOL},     /* TABLE Adobe golive*/
  {TidyAttr_SHOWGRIDY,"showgridy",    VERS_PROPRIETARY,  BOOL},     /* TABLE Adobe golive*/
  {TidyAttr_SIZE,     "size",         VERS_LOOSE,        NUMBER},   /* HR, FONT, BASEFONT, SELECT */
  {TidyAttr_SPAN,     "span",         VERS_HTML40,       NUMBER},   /* COL, COLGROUP */
  {TidyAttr_SRC,      "src",          VERS_ALL,          URL},      /* IMG, FRAME, IFRAME */
  {TidyAttr_STANDBY,  "standby",      VERS_HTML40,       TEXT},     /* OBJECT */
  {TidyAttr_START,    "start",        VERS_ALL,          NUMBER},   /* OL */
  {TidyAttr_STYLE,    "style",        VERS_HTML40,       TEXT},
  {TidyAttr_SUMMARY,  "summary",      VERS_HTML40,       TEXT},     /* TABLE */
  {TidyAttr_TABINDEX, "tabindex",     VERS_HTML40,       NUMBER},   /* fields, OBJECT  and A */
  {TidyAttr_TARGET,   "target",       VERS_HTML40,       TARGET},   /* names a frame/window */
  {TidyAttr_TEXT,     "text",         VERS_LOOSE,        COLOR},    /* BODY */
  {TidyAttr_TITLE,    "title",        VERS_HTML40,       TEXT},     /* text tool tip */
  {TidyAttr_TOPMARGIN,"topmargin",    VERS_MICROSOFT,    NUMBER},   /* used on BODY */
  {TidyAttr_TYPE,     "type",         VERS_FROM32,       TYPE},     /* also used by SPACER */
  {TidyAttr_USEMAP,   "usemap",       VERS_ALL,          BOOL},     /* things with images */
  {TidyAttr_VALIGN,   "valign",       VERS_FROM32,       VALIGN},
  {TidyAttr_VALUE,    "value",        VERS_ALL,          TEXT, yes},/* nowrap, OPTION, PARAM */
  {TidyAttr_VALUETYPE,"valuetype",    VERS_HTML40,       VTYPE},    /* PARAM: data, ref, object */
  {TidyAttr_VERSION,  "version",      VERS_ALL|VERS_XML, TEXT},     /* HTML <?xml?> */
  {TidyAttr_VLINK,    "vlink",        VERS_LOOSE,        COLOR},    /* BODY */
  {TidyAttr_VSPACE,   "vspace",       VERS_LOOSE,        NUMBER},   /* IMG, OBJECT, APPLET */
  {TidyAttr_WIDTH,    "width",        VERS_ALL,          LENGTH},   /* pixels only for TD/TH */
  {TidyAttr_WRAP,     "wrap",         VERS_NETSCAPE,     TEXT},     /* textarea */
  {TidyAttr_XML_LANG, "xml:lang",     VERS_XML,          TEXT},     /* XML language */
  {TidyAttr_XML_SPACE,"xml:space",    VERS_XML,          TEXT},     /* XML language */
  {TidyAttr_XMLNS,    "xmlns",        VERS_ALL,          TEXT},     /* name space */
   
  /* this must be the final entry */
  {N_TIDY_ATTRIBS,    null}
};

/* used by CheckColor() */
struct _colors
{
    ctmbstr name;
    ctmbstr hex;
};

static const struct _colors colors[] =
{
    {"black",   "#000000"},
    {"green",   "#008000"},
    {"silver",  "#C0C0C0"},
    {"lime",    "#00FF00"},
    {"gray",    "#808080"},
    {"olive",   "#808000"},
    {"white",   "#FFFFFF"},
    {"yellow",  "#FFFF00"},
    {"maroon",  "#800000"},
    {"navy",    "#000080"},
    {"red",     "#FF0000"},
    {"blue",    "#0000FF"},
    {"purple",  "#800080"},
    {"teal",    "#008080"},
    {"fuchsia", "#FF00FF"},
    {"aqua",    "#00FFFF"},
    {null,      null}
};

static const struct _colors fancy_colors[] =
{
    { "darkgreen",            "#006400" },
    { "antiquewhite",         "#FAEBD7" },
    { "aqua",                 "#00FFFF" },
    { "aquamarine",           "#7FFFD4" },
    { "azure",                "#F0FFFF" },
    { "beige",                "#F5F5DC" },
    { "bisque",               "#FFE4C4" },
    { "black",                "#000000" },
    { "blanchedalmond",       "#FFEBCD" },
    { "blue",                 "#0000FF" },
    { "blueviolet",           "#8A2BE2" },
    { "brown",                "#A52A2A" },
    { "burlywood",            "#DEB887" },
    { "cadetblue",            "#5F9EA0" },
    { "chartreuse",           "#7FFF00" },
    { "chocolate",            "#D2691E" },
    { "coral",                "#FF7F50" },
    { "cornflowerblue",       "#6495ED" },
    { "cornsilk",             "#FFF8DC" },
    { "crimson",              "#DC143C" },
    { "cyan",                 "#00FFFF" },
    { "darkblue",             "#00008B" },
    { "darkcyan",             "#008B8B" },
    { "darkgoldenrod",        "#B8860B" },
    { "darkgray",             "#A9A9A9" },
    { "darkgreen",            "#006400" },
    { "darkkhaki",            "#BDB76B" },
    { "darkmagenta",          "#8B008B" },
    { "darkolivegreen",       "#556B2F" },
    { "darkorange",           "#FF8C00" },
    { "darkorchid",           "#9932CC" },
    { "darkred",              "#8B0000" },
    { "darksalmon",           "#E9967A" },
    { "darkseagreen",         "#8FBC8F" },
    { "darkslateblue",        "#483D8B" },
    { "darkslategray",        "#2F4F4F" },
    { "darkturquoise",        "#00CED1" },
    { "darkviolet",           "#9400D3" },
    { "deeppink",             "#FF1493" },
    { "deepskyblue",          "#00BFFF" },
    { "dimgray",              "#696969" },
    { "dodgerblue",           "#1E90FF" },
    { "firebrick",            "#B22222" },
    { "floralwhite",          "#FFFAF0" },
    { "forestgreen",          "#228B22" },
    { "fuchsia",              "#FF00FF" },
    { "gainsboro",            "#DCDCDC" },
    { "ghostwhite",           "#F8F8FF" },
    { "gold",                 "#FFD700" },
    { "goldenrod",            "#DAA520" },
    { "gray",                 "#808080" },
    { "green",                "#008000" },
    { "greenyellow",          "#ADFF2F" },
    { "honeydew",             "#F0FFF0" },
    { "hotpink",              "#FF69B4" },
    { "indianred",            "#CD5C5C" },
    { "indigo",               "#4B0082" },
    { "ivory",                "#FFFFF0" },
    { "khaki",                "#F0E68C" },
    { "lavender",             "#E6E6FA" },
    { "lavenderblush",        "#FFF0F5" },
    { "lawngreen",            "#7CFC00" },
    { "lemonchiffon",         "#FFFACD" },
    { "lightblue",            "#ADD8E6" },
    { "lightcoral",           "#F08080" },
    { "lightcyan",            "#E0FFFF" },
    { "lightgoldenrodyellow", "#FAFAD2" },
    { "lightgreen",           "#90EE90" },
    { "lightgrey",            "#D3D3D3" },
    { "lightpink",            "#FFB6C1" },
    { "lightsalmon",          "#FFA07A" },
    { "lightseagreen",        "#20B2AA" },
    { "lightskyblue",         "#87CEFA" },
    { "lightslategray",       "#778899" },
    { "lightsteelblue",       "#B0C4DE" },
    { "lightyellow",          "#FFFFE0" },
    { "lime",                 "#00FF00" },
    { "limegreen",            "#32CD32" },
    { "linen",                "#FAF0E6" },
    { "magenta",              "#FF00FF" },
    { "maroon",               "#800000" },
    { "mediumaquamarine",     "#66CDAA" },
    { "mediumblue",           "#0000CD" },
    { "mediumorchid",         "#BA55D3" },
    { "mediumpurple",         "#9370DB" },
    { "mediumseagreen",       "#3CB371" },
    { "mediumslateblue",      "#7B68EE" },
    { "mediumspringgreen",    "#00FA9A" },
    { "mediumturquoise",      "#48D1CC" },
    { "mediumvioletred",      "#C71585" },
    { "midnightblue",         "#191970" },
    { "mintcream",            "#F5FFFA" },
    { "mistyrose",            "#FFE4E1" },
    { "moccasin",             "#FFE4B5" },
    { "navajowhite",          "#FFDEAD" },
    { "navy",                 "#000080" },
    { "oldlace",              "#FDF5E6" },
    { "olive",                "#808000" },
    { "olivedrab",            "#6B8E23" },
    { "orange",               "#FFA500" },
    { "orangered",            "#FF4500" },
    { "orchid",               "#DA70D6" },
    { "palegoldenrod",        "#EEE8AA" },
    { "palegreen",            "#98FB98" },
    { "paleturquoise",        "#AFEEEE" },
    { "palevioletred",        "#DB7093" },
    { "papayawhip",           "#FFEFD5" },
    { "peachpuff",            "#FFDAB9" },
    { "peru",                 "#CD853F" },
    { "pink",                 "#FFC0CB" },
    { "plum",                 "#DDA0DD" },
    { "powderblue",           "#B0E0E6" },
    { "purple",               "#800080" },
    { "red",                  "#FF0000" },
    { "rosybrown",            "#BC8F8F" },
    { "royalblue",            "#4169E1" },
    { "saddlebrown",          "#8B4513" },
    { "salmon",               "#FA8072" },
    { "sandybrown",           "#F4A460" },
    { "seagreen",             "#2E8B57" },
    { "seashell",             "#FFF5EE" },
    { "sienna",               "#A0522D" },
    { "silver",               "#C0C0C0" },
    { "skyblue",              "#87CEEB" },
    { "slateblue",            "#6A5ACD" },
    { "slategray",            "#708090" },
    { "snow",                 "#FFFAFA" },
    { "springgreen",          "#00FF7F" },
    { "steelblue",            "#4682B4" },
    { "tan",                  "#D2B48C" },
    { "teal",                 "#008080" },
    { "thistle",              "#D8BFD8" },
    { "tomato",               "#FF6347" },
    { "turquoise",            "#40E0D0" },
    { "violet",               "#EE82EE" },
    { "wheat",                "#F5DEB3" },
    { "white",                "#FFFFFF" },
    { "whitesmoke",           "#F5F5F5" },
    { "yellow",               "#FFFF00" },
    { "yellowgreen",          "#9ACD32" },
    { null,      null }
};


static const Attribute* lookup( ctmbstr atnam )
{
    if ( atnam )
    {
        const Attribute *np = attribute_defs;
        for ( /**/; np && np->name; ++np )
            if ( tmbstrcmp(atnam, np->name) == 0 )
                return np;
    }
    return null;
}


/* Locate attributes by type
*/

AttVal* AttrGetById( Node* node, TidyAttrId id )
{
   AttVal* av;
   for ( av = node->attributes; av; av = av->next )
   {
     if ( AttrIsId(av, id) )
         return av;
   }
   return null;
}

/* public method for finding attribute definition by name */
const Attribute* FindAttribute( TidyDocImpl* doc, AttVal *attval )
{
    if ( attval )
       return lookup( attval->attribute );
    return null;
}

AttVal* GetAttrByName( Node *node, ctmbstr name )
{
    AttVal *attr;
    for (attr = node->attributes; attr != null; attr = attr->next)
    {
        if (attr->attribute && tmbstrcmp(attr->attribute, name) == 0)
            break;
    }
    return attr;
}

AttVal* AddAttribute( TidyDocImpl* doc,
                      Node *node, ctmbstr name, ctmbstr value )
{
    AttVal *av = NewAttribute();
    av->delim = '"';
    av->attribute = tmbstrdup( name );
    av->value = tmbstrdup( value );
    av->dict = lookup( name );

    if ( node->attributes == null )
        node->attributes = av;
    else /* append to end of attributes */
    {
        AttVal *here = node->attributes;
        while (here->next)
            here = here->next;
        here->next = av;
    }
    return av;
}

static Bool CheckAttrType( TidyDocImpl* doc,
                           ctmbstr attrname, AttrCheck type )
{
    const Attribute* np = lookup( attrname );
    return (Bool)( np && np->attrchk == type );
}

Bool IsUrl( TidyDocImpl* doc, ctmbstr attrname )
{
    return CheckAttrType( doc, attrname, URL );
}

Bool IsBool( TidyDocImpl* doc, ctmbstr attrname )
{
    return CheckAttrType( doc, attrname, BOOL );
}

Bool IsScript( TidyDocImpl* doc, ctmbstr attrname )
{
    return CheckAttrType( doc, attrname, SCRIPT );
}

Bool IsLiteralAttribute( TidyDocImpl* doc, ctmbstr attrname )
{
    const Attribute* np = lookup( attrname );
    return (Bool)( np && np->literal );
}

/* may id or name serve as anchor? */
Bool IsAnchorElement( TidyDocImpl* doc, Node *node)
{
    TidyTagImpl* tags = &doc->tags;
    TidyTagId tid = TagId( node );
    if ( tid == TidyTag_A      ||
         tid == TidyTag_APPLET ||
         tid == TidyTag_FORM   ||
         tid == TidyTag_FRAME  ||
         tid == TidyTag_IFRAME ||
         tid == TidyTag_IMG    ||
         tid == TidyTag_MAP )
        return yes;

    return no;
}

/*
  In CSS1, selectors can contain only the characters A-Z, 0-9, and Unicode characters 161-255, plus dash (-);
  they cannot start with a dash or a digit; they can also contain escaped characters and any Unicode character
  as a numeric code (see next item).

  The backslash followed by at most four hexadecimal digits (0..9A..F) stands for the Unicode character with that number.

  Any character except a hexadecimal digit can be escaped to remove its special meaning, by putting a backslash in front.

  #508936 - CSS class naming for -clean option
*/
Bool IsCSS1Selector( ctmbstr buf )
{
    Bool valid = yes;
    int esclen = 0;
    byte c;
    int pos;

    for ( pos=0; valid && (c = *buf++); ++pos )
    {
        if ( c == '\\' )
        {
            esclen = 1;  /* ab\555\444 is 4 chars {'a', 'b', \555, \444} */
        }
        else if ( isxdigit( c ) )
        {
            /* Digit not 1st, unless escaped (Max length "\112F") */
            if ( esclen > 0 )
                valid = ( ++esclen < 6 );
            if ( valid )
                valid = ( pos>0 || esclen>0 );
        }
        else
        {
            valid = (
                esclen > 0                       /* Escaped? Anything goes. */
                || ( pos>0 && c == '-' )         /* Dash cannot be 1st char */
                || isalpha(c)                    /* a-z, A-Z anywhere */
                || ( c >= 161 && c <= 255 )      /* Unicode 161-255 anywhere */
            );
            esclen = 0;
        }
    }
    return valid;
}





/* free single anchor */
static void FreeAnchor(Anchor *a)
{
    if ( a )
        MemFree( a->name );
    MemFree( a );
}

/* removes anchor for specific node */
void RemoveAnchorByNode( TidyDocImpl* doc, Node *node )
{
    TidyAttribImpl* attribs = &doc->attribs;
    Anchor *delme = null, *curr, *prev = null;

    for ( curr=attribs->anchor_list; curr!=null; curr=curr->next )
    {
        if ( curr->node == node )
        {
            if ( prev )
                prev->next = curr->next;
            else
                attribs->anchor_list = curr->next;
            delme = curr;
            break;
        }
        prev = curr;
    }
    FreeAnchor( delme );
}

/* initialize new anchor */
static Anchor* NewAnchor( ctmbstr name, Node* node )
{
    Anchor *a = (Anchor*) MemAlloc( sizeof(Anchor) );

    a->name = tmbstrdup( name );
    a->node = node;
    a->next = null;

    return a;
}

/* add new anchor to namespace */
Anchor* AddAnchor( TidyDocImpl* doc, ctmbstr name, Node *node )
{
    TidyAttribImpl* attribs = &doc->attribs;
    Anchor *a = NewAnchor( name, node );

    if ( attribs->anchor_list == null)
         attribs->anchor_list = a;
    else
    {
        Anchor *here =  attribs->anchor_list;
        while (here->next)
            here = here->next;
        here->next = a;
    }

    return attribs->anchor_list;
}

/* return node associated with anchor */
Node* GetNodeByAnchor( TidyDocImpl* doc, ctmbstr name )
{
    TidyAttribImpl* attribs = &doc->attribs;
    Anchor *found;
    for ( found = attribs->anchor_list; found != null; found = found->next )
    {
        if ( tmbstrcasecmp(found->name, name) == 0 )
            break;
    }
    
    if ( found )
        return found->node;
    return null;
}

/* free all anchors */
void FreeAnchors( TidyDocImpl* doc )
{
    TidyAttribImpl* attribs = &doc->attribs;
    Anchor* a;
    while ( a = attribs->anchor_list )
    {
        attribs->anchor_list = a->next;
        MemFree( a->name );
        MemFree( a );
    }
}

/* public method for inititializing attribute dictionary */
void InitAttrs( TidyDocImpl* doc )
{
    ClearMemory( &doc->attribs, sizeof(TidyAttribImpl) );

#ifdef _DEBUG
    {
      ctmbstr prev = null;
      TidyAttrId id;
      for ( id=1; id < N_TIDY_ATTRIBS; ++id )
      {
        const Attribute* dict = &attribute_defs[ id ];
        assert( dict->id == id );
        if ( prev )
            assert( tmbstrcmp( prev, dict->name ) < 0 );
        prev = dict->name;
      }
    }
#endif
}

/*
Henry Zrepa reports that some folk are
using embed with script attributes where
newlines are signficant. These need to be
declared and handled specially!
*/
static void DeclareAttribute( TidyDocImpl* doc, ctmbstr name,
                              uint versions, Bool nowrap, Bool isliteral )
{
    const Attribute *exist = lookup( name );
    if ( exist == null )
    {
        TidyAttribImpl* attribs = &doc->attribs;
        Attribute* dict = (Attribute*) MemAlloc( sizeof(Attribute) );
        ClearMemory( dict, sizeof(Attribute) );

        dict->name     = tmbstrdup( name );
        dict->versions = versions;
        dict->nowrap   = nowrap;
        dict->literal  = isliteral;

        dict->next = attribs->declared_attr_list;
        attribs->declared_attr_list = dict;
    }
}


/* free all declared attributes */
static void FreeDeclaredAttributes( TidyDocImpl* doc )
{
    TidyAttribImpl* attribs = &doc->attribs;
    Attribute* dict;
    while ( dict = attribs->declared_attr_list )
    {
        attribs->declared_attr_list = dict->next;
        MemFree( dict->name );
        MemFree( dict );
    }
}

void DeclareLiteralAttrib( TidyDocImpl* doc, ctmbstr name )
{
    DeclareAttribute( doc, name, VERS_PROPRIETARY, no, yes );
}

void FreeAttrTable( TidyDocImpl* doc )
{
    FreeAnchors( doc );
    FreeDeclaredAttributes( doc );
}

/*
 the same attribute name can't be used
 more than once in each element
*/

void RepairDuplicateAttributes( TidyDocImpl* doc, Node *node)
{
    AttVal *attval;

    for (attval = node->attributes; attval != null;)
    {
        if (attval->asp == null && attval->php == null)
        {
            AttVal *current;
            
            for (current = attval->next; current != null;)
            {
                if (current->asp == null && current->php == null &&
                    tmbstrcasecmp(attval->attribute, current->attribute) == 0)
                {
                    AttVal *temp;

                    if ( tmbstrcasecmp(current->attribute, "class") == 0 
                         && cfgBool(doc, TidyJoinClasses) )
                    {
                        /* concatenate classes */

                        current->value = (tmbstr) MemRealloc(current->value, tmbstrlen(current->value) +
                                                                            tmbstrlen(attval->value)  + 2);
                        tmbstrcat(current->value, " ");
                        tmbstrcat(current->value, attval->value);

                        temp = attval->next;

                        if (temp->next == null)
                            current = null;
                        else
                            current = current->next;

                        ReportAttrError( doc, node, attval, JOINING_ATTRIBUTE);

                        RemoveAttribute(node, attval);
                        attval = temp;
                    }
                    else if ( tmbstrcasecmp(current->attribute, "style") == 0 
                              && cfgBool(doc, TidyJoinStyles) )
                    {
                        /* concatenate styles */

                        /*
                          this doesn't handle CSS comments and
                          leading/trailing white-space very well
                          see http://www.w3.org/TR/css-style-attr
                        */

                        size_t end = strlen(current->value);

                        if (current->value[end] == ';')
                        {
                            /* attribute ends with declaration seperator */

                            current->value = (tmbstr) MemRealloc(current->value,
                                end + tmbstrlen(attval->value) + 2);

                            tmbstrcat(current->value, " ");
                            tmbstrcat(current->value, attval->value);
                        }
                        else if (current->value[end] == '}')
                        {
                            /* attribute ends with rule set */

                            current->value = (tmbstr) MemRealloc(current->value,
                                end + tmbstrlen(attval->value) + 6);

                            tmbstrcat(current->value, " { ");
                            tmbstrcat(current->value, attval->value);
                            tmbstrcat(current->value, " }");
                        }
                        else
                        {
                            /* attribute ends with property value */

                            current->value = (tmbstr) MemRealloc(current->value,
                                end + tmbstrlen(attval->value) + 3);

                            tmbstrcat(current->value, "; ");
                            tmbstrcat(current->value, attval->value);
                        }

                        temp = attval->next;

                        if (temp->next == null)
                            current = null;
                        else
                            current = current->next;

                        ReportAttrError( doc, node, attval, JOINING_ATTRIBUTE);

                        RemoveAttribute(node, attval);
                        attval = temp;

                    }
                    else if ( cfg(doc, TidyDuplicateAttrs) == TidyKeepLast )
                    {
                        temp = current->next;
                        ReportAttrError( doc, node, current, REPEATED_ATTRIBUTE);
                        RemoveAttribute(node, current);
                        current = temp;
                    }
                    else
                    {
                        temp = attval->next;
                        if (attval->next == null)
                            current = null;
                        else
                            current = current->next;

                        ReportAttrError( doc, node, attval, REPEATED_ATTRIBUTE);
                        RemoveAttribute(node, attval);
                        attval = temp;
                    }
                }
                else
                    current = current->next;
            }
            attval = attval->next;
        }
        else
            attval = attval->next;
    }
}


/* ignore unknown attributes for proprietary elements */
const Attribute* CheckAttribute( TidyDocImpl* doc, Node *node, AttVal *attval )
{
    const Attribute* attribute = attval->dict;

    if ( attribute != null )
    {
        /* if attribute looks like <foo/> check XML is ok */
        if ( attribute->versions & VERS_XML )
        {
            if ( !(cfgBool(doc, TidyXmlTags) || cfgBool(doc, TidyXmlOut)) )
                ReportAttrError( doc, node, attval, XML_ATTRIBUTE_VALUE);
        } /* title first appeared in HTML 4.0 except for a/link */
        else if ( attribute->id != TidyAttr_TITLE ||
                  !(nodeIsA(node) || nodeIsLINK(node)) )
        {
            ConstrainVersion( doc, attribute->versions );
        }
        
        if (attribute->attrchk)
            attribute->attrchk( doc, node, attval );
        else if ( attval->dict->versions & VERS_PROPRIETARY )
            ReportAttrError( doc, node, attval, PROPRIETARY_ATTRIBUTE);
    }
    else if ( !cfgBool(doc, TidyXmlTags)
              && attval->asp == null 
              && node->tag != null 
              && !(node->tag->versions & VERS_PROPRIETARY) )
    {
        ReportAttrError( doc, node, attval, UNKNOWN_ATTRIBUTE );
    }

    return attribute;
}

Bool IsBoolAttribute(AttVal *attval)
{
    const Attribute *attribute = ( attval ? attval->dict : null );
    if ( attribute && attribute->attrchk == CheckBool )
        return yes;
    return no;
}

Bool attrIsEvent( AttVal* attval )
{
    TidyAttrId atid = AttrId( attval );
    return ( atid == TidyAttr_OnMOUSEMOVE ||
             atid == TidyAttr_OnMOUSEDOWN ||
             atid == TidyAttr_OnMOUSEUP   ||
             atid == TidyAttr_OnCLICK     ||
             atid == TidyAttr_OnMOUSEOVER ||
             atid == TidyAttr_OnMOUSEOUT  ||
             atid == TidyAttr_OnKEYDOWN   ||
             atid == TidyAttr_OnKEYUP     ||
             atid == TidyAttr_OnKEYPRESS  ||
             atid == TidyAttr_OnFOCUS     ||
             atid == TidyAttr_OnBLUR );
}

static void CheckLowerCaseAttrValue( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr p;
    Bool hasUpper = no;
    
    if (attval == null || attval->value == null)
        return;

    p = attval->value;
    
    while (*p)
    {
        if (IsUpper(*p)) /* #501230 - fix by Terry Teague - 09 Jan 02 */
        {
            hasUpper = yes;
            break;
        }
        p++;
    }

    if (hasUpper)
    {
        Lexer* lexer = doc->lexer;
        if (lexer->isvoyager)
            ReportAttrError( doc, node, attval, ATTR_VALUE_NOT_LCASE);
  
        if ( lexer->isvoyager || cfgBool(doc, TidyLowerLiterals) )
            attval->value = tmbstrtolower(attval->value);
    }
}

/* methods for checking value of a specific attribute */

void CheckUrl( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbchar c; 
    tmbstr dest, p;
    uint escape_count = 0, backslash_count = 0;
    uint i, pos = 0;
    size_t len;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    p = attval->value;
    
    for (i = 0; c = p[i]; ++i)
    {
        if (c == '\\')
        {
            ++backslash_count;
            if ( cfgBool(doc, TidyFixBackslash) )
                p[i] = '/';
        }
        else if ((c > 0x7e) || (c <= 0x20) || (strchr("<>", c)))
            ++escape_count;
    }
    
    if ( cfgBool(doc, TidyFixUri) && escape_count )
    {
        len = tmbstrlen(p) + escape_count * 2 + 1;
        dest = (tmbstr) MemAlloc(len);
        
        for (i = 0; c = p[i]; ++i)
        {
            if ((c > 0x7e) || (c <= 0x20) || (strchr("<>", c)))
                pos += sprintf( dest + pos, "%%%02X", (byte)c );
            else
                dest[pos++] = c;
        }
        dest[pos++] = 0;

        MemFree(attval->value);
        attval->value = dest;
    }
    if ( backslash_count )
    {
        if ( cfgBool(doc, TidyFixBackslash) )
            ReportAttrError( doc, node, attval, FIXED_BACKSLASH );
        else
            ReportAttrError( doc, node, attval, BACKSLASH_IN_URI );
    }
    if ( escape_count )
    {
        if ( cfgBool(doc, TidyFixUri) )
            ReportAttrError( doc, node, attval, ESCAPED_ILLEGAL_URI);
        else
            ReportAttrError( doc, node, attval, ILLEGAL_URI_REFERENCE);

        doc->badChars |= INVALID_URI;
    }
}

void CheckScript( TidyDocImpl* doc, Node *node, AttVal *attval)
{
}

void CheckName( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    Node *old;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    if ( IsAnchorElement(doc, node) )
    {
        ConstrainVersion( doc, ~VERS_XHTML11 );

        if ((old = GetNodeByAnchor(doc, attval->value)) &&  old != node)
        {
            ReportAttrError( doc, node, attval, ANCHOR_NOT_UNIQUE);
        }
        else
            AddAnchor( doc, attval->value, node );
    }
}

void CheckId( TidyDocImpl* doc, Node *node, AttVal *attval )
{
    Lexer* lexer = doc->lexer;
    tmbstr p;
    Node *old;
    uint s;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    p = attval->value;
    s = *p++;

    
    if (!IsLetter(s))
    {
        if (lexer->isvoyager && (IsXMLLetter(s) || s == '_' || s == ':'))
            ReportAttrError( doc, node, attval, XML_ID_SYNTAX);
        else
            ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
    }
    else
    {
        while(s = *p++)         /* #559774 tidy version rejects all id values */
        {
            if (!IsNamechar(s))
            {
                if (lexer->isvoyager && IsXMLNamechar(s))
                    ReportAttrError( doc, node, attval, XML_ID_SYNTAX);
                else
                    ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
                break;
            }
        }
    }

    if ((old = GetNodeByAnchor(doc, attval->value)) &&  old != node)
    {
        ReportAttrError( doc, node, attval, ANCHOR_NOT_UNIQUE);
    }
    else
        AddAnchor( doc, attval->value, node );
}

void CheckBool( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    if (attval == null || attval->value == null)
        return;

    CheckLowerCaseAttrValue( doc, node, attval );
}

void CheckAlign( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;

    /* IMG, OBJECT, APPLET and EMBED use align for vertical position */
    if (node->tag && (node->tag->model & CM_IMG))
    {
        CheckValign( doc, node, attval );
        return;
    }

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval);

    value = attval->value;

    if (! (tmbstrcasecmp(value,    "left") == 0 ||
           tmbstrcasecmp(value,  "center") == 0 ||
           tmbstrcasecmp(value,   "right") == 0 ||
           tmbstrcasecmp(value, "justify") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckValign( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval );

    value = attval->value;

    if (tmbstrcasecmp(value,      "top") == 0 ||
        tmbstrcasecmp(value,   "middle") == 0 ||
        tmbstrcasecmp(value,   "bottom") == 0 ||
        tmbstrcasecmp(value, "baseline") == 0)
    {
            /* all is fine */
    }
    else if (tmbstrcasecmp(value,  "left") == 0 ||
             tmbstrcasecmp(value, "right") == 0)
    {
        if (!(node->tag && (node->tag->model & CM_IMG)))
            ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
    }
    else if (tmbstrcasecmp(value,    "texttop") == 0 ||
             tmbstrcasecmp(value,  "absmiddle") == 0 ||
             tmbstrcasecmp(value,  "absbottom") == 0 ||
             tmbstrcasecmp(value, "textbottom") == 0)
    {
        ConstrainVersion( doc, VERS_PROPRIETARY );
        ReportAttrError( doc, node, attval, PROPRIETARY_ATTR_VALUE);
    }
    else
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckLength( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr p;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    /* don't check for <col width=...> and <colgroup width=...> */
    if ( tmbstrcmp(attval->attribute, "width") == 0 &&
         (nodeIsCOL(node) || nodeIsCOLGROUP(node)) )
        return;

    p = attval->value;
    
    if (!IsDigit(*p++))
    {
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
    }
    else
    {
        while (*p)
        {
            if (!IsDigit(*p) && *p != '%')
            {
                ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
                break;
            }
            ++p;
        }
    }
}

void CheckTarget( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    /* No target attribute in strict HTML versions */
    ConstrainVersion( doc, ~VERS_HTML40_STRICT);

    /*
      target names must begin with A-Za-z or be one of
      _blank, _self, _parent and _top
    */
    
    value = attval->value;

    if (IsLetter(value[0]))
        return;
    
    if (! (tmbstrcasecmp(value,  "_blank") == 0 ||
           tmbstrcasecmp(value,   "_self") == 0 ||
           tmbstrcasecmp(value, "_parent") == 0 ||
           tmbstrcasecmp(value,    "_top") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckFsubmit( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    value = attval->value;

    CheckLowerCaseAttrValue( doc, node, attval);

    if (! (tmbstrcasecmp(value,  "get") == 0 ||
           tmbstrcasecmp(value, "post") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckClear( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        if (attval->value == null)
            attval->value = tmbstrdup( "none" );
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval );
        
    value = attval->value;
    
    if (! (tmbstrcasecmp(value,  "none") == 0 ||
           tmbstrcasecmp(value,  "left") == 0 ||
           tmbstrcasecmp(value, "right") == 0 ||
           tmbstrcasecmp(value,   "all") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckShape( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval );

    value = attval->value;
    
    if (! (tmbstrcasecmp(value,    "rect") == 0 ||
           tmbstrcasecmp(value, "default") == 0 ||
           tmbstrcasecmp(value,  "circle") == 0 ||
           tmbstrcasecmp(value,    "poly") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckScope( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval);

    value = attval->value;
    
    if (! (tmbstrcasecmp(value,      "row") == 0 ||
           tmbstrcasecmp(value, "rowgroup") == 0 ||
           tmbstrcasecmp(value,      "col") == 0 ||
           tmbstrcasecmp(value, "colgroup") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

void CheckNumber( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr p;
    
    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    /* don't check <frameset cols=... rows=...> */
    if ( nodeIsFRAMESET(node) &&
         ( tmbstrcmp(attval->attribute, "cols") == 0 ||
           tmbstrcmp(attval->attribute, "rows") == 0 ) )
     return;

    p  = attval->value;
    
    /* font size may be preceded by + or - */
    if ( nodeIsFONT(node) && (*p == '+' || *p == '-') )
        ++p;

    while (*p)
    {
        if (!IsDigit(*p))
        {
            ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
            break;
        }
        ++p;
    }
}

/* check color syntax and beautify value by option */
void CheckColor( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    /* Bool ReplaceColor = yes; */ /* #477643 - replace hex color attribute values with names */
    Bool HexUppercase = yes;
    Bool invalid = no;
    Bool found = no;
    tmbstr given;
    const struct _colors *color;
    uint i = 0;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    given = attval->value;
    
    for (color = colors; color->name; ++color)
    {
        if (given[0] == '#')
        {
            if (tmbstrlen(given) != 7)
            {
                ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
                invalid = yes;
                break;
            }
            else if (tmbstrcasecmp(given, color->hex) == 0)
            {
                if ( cfgBool(doc, TidyReplaceColor) )
                {
                    MemFree(attval->value);
                    attval->value = tmbstrdup(color->name);
                }
                found = yes;
                break;
            }
        }
        else if (IsLetter(given[0]))
        {
            if (tmbstrcasecmp(given, color->name) == 0)
            {
                if ( cfgBool(doc, TidyReplaceColor) )
                {
                    MemFree(attval->value);
                    attval->value = tmbstrdup(color->name);
                }
                found = yes;
                break;
            }
        }
        else
        {
            ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
            invalid = yes;
            break;
        }
    }
    
    if (!found && !invalid)
    {
        if (given[0] == '#')
        {
            /* check if valid hex digits and letters */
            for (i = 1; i < 7; ++i)
            {
                if (!IsDigit(given[i]) &&
                    !strchr("abcdef", ToLower(given[i])))
                {
                    ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
                    invalid = yes;
                    break;
                }
            }
            
            /* convert hex letters to uppercase */
            if (!invalid && HexUppercase)
            {
                for (i = 1; i < 7; ++i)
                {
                    given[i] = (tmbchar) ToUpper( given[i] );
                }
            }
        }
        else
        {
            /* we could search for more colors and mark the file as HTML
               Proprietary, but I don't thinks it's worth the effort,
               so values not in HTML 4.01 are invalid */

            ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
        }
    }
}

/* check valuetype attribute for element param */
void CheckVType( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval );

    value = attval->value;

    if (! (tmbstrcasecmp(value,   "data") == 0 ||
           tmbstrcasecmp(value, "object") == 0 ||
           tmbstrcasecmp(value,    "ref") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

/* checks scrolling attribute */
void CheckScroll( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval );

    value = attval->value;

    if (! (tmbstrcasecmp(value,   "no") == 0 ||
           tmbstrcasecmp(value, "auto") == 0 ||
           tmbstrcasecmp(value,  "yes") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

/* checks dir attribute */
void CheckTextDir( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    tmbstr value;

    if (attval == null || attval->value == null)
    {
        ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE);
        return;
    }

    CheckLowerCaseAttrValue( doc, node, attval);

    value = attval->value;

    if (! (tmbstrcasecmp(value, "rtl") == 0 ||
           tmbstrcasecmp(value, "ltr") == 0))
        ReportAttrError( doc, node, attval, BAD_ATTRIBUTE_VALUE);
}

/* checks lang and xml:lang attributes */
void CheckLang( TidyDocImpl* doc, Node *node, AttVal *attval)
{
    if ( attval == null || attval->value == null )
    {
        if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
        {
            ReportAttrError( doc, node, attval, MISSING_ATTR_VALUE );
        }
        return;
    }

    if (tmbstrcasecmp(attval->attribute, "lang") == 0)
        ConstrainVersion( doc, ~VERS_XHTML11 );
}



