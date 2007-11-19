#ifndef __ATTRS_H__
#define __ATTRS_H__

/* attrs.h -- recognize HTML attributes

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

*/

#include "forward.h"

/* declaration for methods that check attribute values */
typedef void (AttrCheck)(TidyDocImpl* doc, Node *node, AttVal *attval);

struct _Attribute
{
    TidyAttrId  id;
    tmbstr      name;
    unsigned    versions;
    AttrCheck*  attrchk;
    Bool        nowrap;
    Bool        literal;

    struct _Attribute* next;
};


/*
 Anchor/Node linked list
*/

struct _Anchor
{
    struct _Anchor *next;
    Node *node;
    char *name;
};

typedef struct _Anchor Anchor;



#define ATTRIB_HASHSIZE 357

struct _TidyAttribImpl
{
    /* anchor/node lookup */
    Anchor*    anchor_list;

    /* Declared literal attributes */
    Attribute* declared_attr_list;
};

typedef struct _TidyAttribImpl TidyAttribImpl;

#define XHTML_NAMESPACE "http://www.w3.org/1999/xhtml"


/*
 Bind attribute types to procedures to check values.
 You can add new procedures for better validation
 and each procedure has access to the node in which
 the attribute occurred as well as the attribute name
 and its value.

 By default, attributes are checked without regard
 to the element they are found on. You have the choice
 of making the procedure test which element is involved
 or in writing methods for each element which controls
 exactly how the attributes of that element are checked.
 This latter approach is best for detecting the absence
 of required attributes.
*/

AttrCheck CheckUrl;
AttrCheck CheckScript;
AttrCheck CheckName;
AttrCheck CheckId;
AttrCheck CheckAlign;
AttrCheck CheckValign;
AttrCheck CheckBool;
AttrCheck CheckLength;
AttrCheck CheckTarget;
AttrCheck CheckFsubmit;
AttrCheck CheckClear;
AttrCheck CheckShape;
AttrCheck CheckNumber;
AttrCheck CheckScope;
AttrCheck CheckColor;
AttrCheck CheckVType;
AttrCheck CheckScroll;
AttrCheck CheckTextDir;
AttrCheck CheckLang;

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


/* public method for finding attribute definition by name */
const Attribute* CheckAttribute( TidyDocImpl* doc, Node *node, AttVal *attval );

const Attribute* FindAttribute( TidyDocImpl* doc, AttVal *attval );

AttVal* GetAttrByName( Node *node, ctmbstr name );

AttVal* AddAttribute( TidyDocImpl* doc,
                      Node *node, ctmbstr name, ctmbstr value );

Bool IsUrl( TidyDocImpl* doc, ctmbstr attrname );

Bool IsBool( TidyDocImpl* doc, ctmbstr attrname );

Bool IsScript( TidyDocImpl* doc, ctmbstr attrname );

Bool IsLiteralAttribute( TidyDocImpl* doc, ctmbstr attrname );

/* may id or name serve as anchor? */
Bool IsAnchorElement( TidyDocImpl* doc, Node* node );

/*
  In CSS1, selectors can contain only the characters A-Z, 0-9, and
  Unicode characters 161-255, plus dash (-); they cannot start with
  a dash or a digit; they can also contain escaped characters and any
  Unicode character as a numeric code (see next item).

  The backslash followed by at most four hexadecimal digits (0..9A..F)
  stands for the Unicode character with that number.

  Any character except a hexadecimal digit can be escaped to remove its
  special meaning, by putting a backslash in front.

  #508936 - CSS class naming for -clean option
*/
Bool IsCSS1Selector( ctmbstr buf );


/* removes anchor for specific node */
void RemoveAnchorByNode( TidyDocImpl* doc, Node *node );

/* add new anchor to namespace */
Anchor* AddAnchor( TidyDocImpl* doc, ctmbstr name, Node *node );

/* return node associated with anchor */
Node* GetNodeByAnchor( TidyDocImpl* doc, ctmbstr name );

/* free all anchors */
void FreeAnchors( TidyDocImpl* doc );


/* public methods for inititializing/freeing attribute dictionary */
void InitAttrs( TidyDocImpl* doc );
void FreeAttrTable( TidyDocImpl* doc );

/*
Henry Zrepa reports that some folk are
using embed with script attributes where
newlines are signficant. These need to be
declared and handled specially!
*/
void DeclareLiteralAttrib( TidyDocImpl* doc, ctmbstr name );

/*
 the same attribute name can't be used
 more than once in each element
*/
void RepairDuplicateAttributes( TidyDocImpl* doc, Node* node );

Bool IsBoolAttribute( AttVal* attval );
Bool attrIsEvent( AttVal* attval );

AttVal* AttrGetById( Node* node, TidyAttrId id );

/* 0 == TidyAttr_UNKNOWN */
#define AttrId(av) ((av) && (av)->dict ? (av)->dict->id : TidyAttr_UNKNOWN)
#define AttrIsId(av, atid) ((av) && (av)->dict && ((av)->dict->id == atid))

#define AttrHasValue(attr)      ((attr) && (attr)->value)
#define AttrMatches(attr, val)  (AttrHasValue(attr) && \
                                 tmbstrcasecmp((attr)->value, val) == 0)
#define AttrContains(attr, val) (AttrHasValue(attr) && \
                                 tmbsubstr((attr)->value, val) != null)
#define AttrVersions(attr)      ((attr) && (attr)->dict ? (attr)->dict->versions : VERS_PROPRIETARY)


#define attrIsABBR(av)              AttrIsId( av, TidyAttr_ABBR )
#define attrIsACCEPT(av)            AttrIsId( av, TidyAttr_ACCEPT )
#define attrIsACCEPT_CHARSET(av)    AttrIsId( av, TidyAttr_ACCEPT_CHARSET )
#define attrIsACCESSKEY(av)         AttrIsId( av, TidyAttr_ACCESSKEY )
#define attrIsACTION(av)            AttrIsId( av, TidyAttr_ACTION )
#define attrIsADD_DATE(av)          AttrIsId( av, TidyAttr_ADD_DATE )
#define attrIsALIGN(av)             AttrIsId( av, TidyAttr_ALIGN )
#define attrIsALINK(av)             AttrIsId( av, TidyAttr_ALINK )
#define attrIsALT(av)               AttrIsId( av, TidyAttr_ALT )
#define attrIsARCHIVE(av)           AttrIsId( av, TidyAttr_ARCHIVE )
#define attrIsAXIS(av)              AttrIsId( av, TidyAttr_AXIS )
#define attrIsBACKGROUND(av)        AttrIsId( av, TidyAttr_BACKGROUND )
#define attrIsBGCOLOR(av)           AttrIsId( av, TidyAttr_BGCOLOR )
#define attrIsBGPROPERTIES(av)      AttrIsId( av, TidyAttr_BGPROPERTIES )
#define attrIsBORDER(av)            AttrIsId( av, TidyAttr_BORDER )
#define attrIsBORDERCOLOR(av)       AttrIsId( av, TidyAttr_BORDERCOLOR )
#define attrIsBOTTOMMARGIN(av)      AttrIsId( av, TidyAttr_BOTTOMMARGIN )
#define attrIsCELLPADDING(av)       AttrIsId( av, TidyAttr_CELLPADDING )
#define attrIsCELLSPACING(av)       AttrIsId( av, TidyAttr_CELLSPACING )
#define attrIsCHAR(av)              AttrIsId( av, TidyAttr_CHAR )
#define attrIsCHAROFF(av)           AttrIsId( av, TidyAttr_CHAROFF )
#define attrIsCHARSET(av)           AttrIsId( av, TidyAttr_CHARSET )
#define attrIsCHECKED(av)           AttrIsId( av, TidyAttr_CHECKED )
#define attrIsCITE(av)              AttrIsId( av, TidyAttr_CITE )
#define attrIsCLASS(av)             AttrIsId( av, TidyAttr_CLASS )
#define attrIsCLASSID(av)           AttrIsId( av, TidyAttr_CLASSID )
#define attrIsCLEAR(av)             AttrIsId( av, TidyAttr_CLEAR )
#define attrIsCODE(av)              AttrIsId( av, TidyAttr_CODE )
#define attrIsCODEBASE(av)          AttrIsId( av, TidyAttr_CODEBASE )
#define attrIsCODETYPE(av)          AttrIsId( av, TidyAttr_CODETYPE )
#define attrIsCOLOR(av)             AttrIsId( av, TidyAttr_COLOR )
#define attrIsCOLS(av)              AttrIsId( av, TidyAttr_COLS )
#define attrIsCOLSPAN(av)           AttrIsId( av, TidyAttr_COLSPAN )
#define attrIsCOMPACT(av)           AttrIsId( av, TidyAttr_COMPACT )
#define attrIsCONTENT(av)           AttrIsId( av, TidyAttr_CONTENT )
#define attrIsCOORDS(av)            AttrIsId( av, TidyAttr_COORDS )
#define attrIsDATA(av)              AttrIsId( av, TidyAttr_DATA )
#define attrIsDATAFLD(av)           AttrIsId( av, TidyAttr_DATAFLD )
#define attrIsDATAFORMATAS(av)      AttrIsId( av, TidyAttr_DATAFORMATAS )
#define attrIsDATAPAGESIZE(av)      AttrIsId( av, TidyAttr_DATAPAGESIZE )
#define attrIsDATASRC(av)           AttrIsId( av, TidyAttr_DATASRC )
#define attrIsDATETIME(av)          AttrIsId( av, TidyAttr_DATETIME )
#define attrIsDECLARE(av)           AttrIsId( av, TidyAttr_DECLARE )
#define attrIsDEFER(av)             AttrIsId( av, TidyAttr_DEFER )
#define attrIsDIR(av)               AttrIsId( av, TidyAttr_DIR )
#define attrIsDISABLED(av)          AttrIsId( av, TidyAttr_DISABLED )
#define attrIsENCODING(av)          AttrIsId( av, TidyAttr_ENCODING )
#define attrIsENCTYPE(av)           AttrIsId( av, TidyAttr_ENCTYPE )
#define attrIsFACE(av)              AttrIsId( av, TidyAttr_FACE )
#define attrIsFOR(av)               AttrIsId( av, TidyAttr_FOR )
#define attrIsFRAME(av)             AttrIsId( av, TidyAttr_FRAME )
#define attrIsFRAMEBORDER(av)       AttrIsId( av, TidyAttr_FRAMEBORDER )
#define attrIsFRAMESPACING(av)      AttrIsId( av, TidyAttr_FRAMESPACING )
#define attrIsGRIDX(av)             AttrIsId( av, TidyAttr_GRIDX )
#define attrIsGRIDY(av)             AttrIsId( av, TidyAttr_GRIDY )
#define attrIsHEADERS(av)           AttrIsId( av, TidyAttr_HEADERS )
#define attrIsHEIGHT(av)            AttrIsId( av, TidyAttr_HEIGHT )
#define attrIsHREF(av)              AttrIsId( av, TidyAttr_HREF )
#define attrIsHREFLANG(av)          AttrIsId( av, TidyAttr_HREFLANG )
#define attrIsHSPACE(av)            AttrIsId( av, TidyAttr_HSPACE )
#define attrIsHTTP_EQUIV(av)        AttrIsId( av, TidyAttr_HTTP_EQUIV )
#define attrIsID(av)                AttrIsId( av, TidyAttr_ID )
#define attrIsISMAP(av)             AttrIsId( av, TidyAttr_ISMAP )
#define attrIsLABEL(av)             AttrIsId( av, TidyAttr_LABEL )
#define attrIsLANG(av)              AttrIsId( av, TidyAttr_LANG )
#define attrIsLANGUAGE(av)          AttrIsId( av, TidyAttr_LANGUAGE )
#define attrIsLAST_MODIFIED(av)     AttrIsId( av, TidyAttr_LAST_MODIFIED )
#define attrIsLAST_VISIT(av)        AttrIsId( av, TidyAttr_LAST_VISIT )
#define attrIsLEFTMARGIN(av)        AttrIsId( av, TidyAttr_LEFTMARGIN )
#define attrIsLINK(av)              AttrIsId( av, TidyAttr_LINK )
#define attrIsLONGDESC(av)          AttrIsId( av, TidyAttr_LONGDESC )
#define attrIsLOWSRC(av)            AttrIsId( av, TidyAttr_LOWSRC )
#define attrIsMARGINHEIGHT(av)      AttrIsId( av, TidyAttr_MARGINHEIGHT )
#define attrIsMARGINWIDTH(av)       AttrIsId( av, TidyAttr_MARGINWIDTH )
#define attrIsMAXLENGTH(av)         AttrIsId( av, TidyAttr_MAXLENGTH )
#define attrIsMEDIA(av)             AttrIsId( av, TidyAttr_MEDIA )
#define attrIsMETHOD(av)            AttrIsId( av, TidyAttr_METHOD )
#define attrIsMULTIPLE(av)          AttrIsId( av, TidyAttr_MULTIPLE )
#define attrIsNAME(av)              AttrIsId( av, TidyAttr_NAME )
#define attrIsNOHREF(av)            AttrIsId( av, TidyAttr_NOHREF )
#define attrIsNORESIZE(av)          AttrIsId( av, TidyAttr_NORESIZE )
#define attrIsNOSHADE(av)           AttrIsId( av, TidyAttr_NOSHADE )
#define attrIsNOWRAP(av)            AttrIsId( av, TidyAttr_NOWRAP )
#define attrIsOBJECT(av)            AttrIsId( av, TidyAttr_OBJECT )
#define attrIsOnAFTERUPDATE(av)     AttrIsId( av, TidyAttr_OnAFTERUPDATE )
#define attrIsOnBEFOREUNLOAD(av)    AttrIsId( av, TidyAttr_OnBEFOREUNLOAD )
#define attrIsOnBEFOREUPDATE(av)    AttrIsId( av, TidyAttr_OnBEFOREUPDATE )
#define attrIsOnBLUR(av)            AttrIsId( av, TidyAttr_OnBLUR )
#define attrIsOnCHANGE(av)          AttrIsId( av, TidyAttr_OnCHANGE )
#define attrIsOnCLICK(av)           AttrIsId( av, TidyAttr_OnCLICK )
#define attrIsOnDATAAVAILABLE(av)   AttrIsId( av, TidyAttr_OnDATAAVAILABLE )
#define attrIsOnDATASETCHANGED(av)  AttrIsId( av, TidyAttr_OnDATASETCHANGED )
#define attrIsOnDATASETCOMPLETE(av) AttrIsId( av, TidyAttr_OnDATASETCOMPLETE )
#define attrIsOnDBLCLICK(av)        AttrIsId( av, TidyAttr_OnDBLCLICK )
#define attrIsOnERRORUPDATE(av)     AttrIsId( av, TidyAttr_OnERRORUPDATE )
#define attrIsOnFOCUS(av)           AttrIsId( av, TidyAttr_OnFOCUS )
#define attrIsOnKEYDOWN(av)         AttrIsId( av, TidyAttr_OnKEYDOWN )
#define attrIsOnKEYPRESS(av)        AttrIsId( av, TidyAttr_OnKEYPRESS )
#define attrIsOnKEYUP(av)           AttrIsId( av, TidyAttr_OnKEYUP )
#define attrIsOnLOAD(av)            AttrIsId( av, TidyAttr_OnLOAD )
#define attrIsOnMOUSEDOWN(av)       AttrIsId( av, TidyAttr_OnMOUSEDOWN )
#define attrIsOnMOUSEMOVE(av)       AttrIsId( av, TidyAttr_OnMOUSEMOVE )
#define attrIsOnMOUSEOUT(av)        AttrIsId( av, TidyAttr_OnMOUSEOUT )
#define attrIsOnMOUSEOVER(av)       AttrIsId( av, TidyAttr_OnMOUSEOVER )
#define attrIsOnMOUSEUP(av)         AttrIsId( av, TidyAttr_OnMOUSEUP )
#define attrIsOnRESET(av)           AttrIsId( av, TidyAttr_OnRESET )
#define attrIsOnROWENTER(av)        AttrIsId( av, TidyAttr_OnROWENTER )
#define attrIsOnROWEXIT(av)         AttrIsId( av, TidyAttr_OnROWEXIT )
#define attrIsOnSELECT(av)          AttrIsId( av, TidyAttr_OnSELECT )
#define attrIsOnSUBMIT(av)          AttrIsId( av, TidyAttr_OnSUBMIT )
#define attrIsOnUNLOAD(av)          AttrIsId( av, TidyAttr_OnUNLOAD )
#define attrIsPROFILE(av)           AttrIsId( av, TidyAttr_PROFILE )
#define attrIsPROMPT(av)            AttrIsId( av, TidyAttr_PROMPT )
#define attrIsRBSPAN(av)            AttrIsId( av, TidyAttr_RBSPAN )
#define attrIsREADONLY(av)          AttrIsId( av, TidyAttr_READONLY )
#define attrIsREL(av)               AttrIsId( av, TidyAttr_REL )
#define attrIsREV(av)               AttrIsId( av, TidyAttr_REV )
#define attrIsRIGHTMARGIN(av)       AttrIsId( av, TidyAttr_RIGHTMARGIN )
#define attrIsROWS(av)              AttrIsId( av, TidyAttr_ROWS )
#define attrIsROWSPAN(av)           AttrIsId( av, TidyAttr_ROWSPAN )
#define attrIsRULES(av)             AttrIsId( av, TidyAttr_RULES )
#define attrIsSCHEME(av)            AttrIsId( av, TidyAttr_SCHEME )
#define attrIsSCOPE(av)             AttrIsId( av, TidyAttr_SCOPE )
#define attrIsSCROLLING(av)         AttrIsId( av, TidyAttr_SCROLLING )
#define attrIsSELECTED(av)          AttrIsId( av, TidyAttr_SELECTED )
#define attrIsSHAPE(av)             AttrIsId( av, TidyAttr_SHAPE )
#define attrIsSHOWGRID(av)          AttrIsId( av, TidyAttr_SHOWGRID )
#define attrIsSHOWGRIDX(av)         AttrIsId( av, TidyAttr_SHOWGRIDX )
#define attrIsSHOWGRIDY(av)         AttrIsId( av, TidyAttr_SHOWGRIDY )
#define attrIsSIZE(av)              AttrIsId( av, TidyAttr_SIZE )
#define attrIsSPAN(av)              AttrIsId( av, TidyAttr_SPAN )
#define attrIsSRC(av)               AttrIsId( av, TidyAttr_SRC )
#define attrIsSTANDBY(av)           AttrIsId( av, TidyAttr_STANDBY )
#define attrIsSTART(av)             AttrIsId( av, TidyAttr_START )
#define attrIsSTYLE(av)             AttrIsId( av, TidyAttr_STYLE )
#define attrIsSUMMARY(av)           AttrIsId( av, TidyAttr_SUMMARY )
#define attrIsTABINDEX(av)          AttrIsId( av, TidyAttr_TABINDEX )
#define attrIsTARGET(av)            AttrIsId( av, TidyAttr_TARGET )
#define attrIsTEXT(av)              AttrIsId( av, TidyAttr_TEXT )
#define attrIsTITLE(av)             AttrIsId( av, TidyAttr_TITLE )
#define attrIsTOPMARGIN(av)         AttrIsId( av, TidyAttr_TOPMARGIN )
#define attrIsTYPE(av)              AttrIsId( av, TidyAttr_TYPE )
#define attrIsUSEMAP(av)            AttrIsId( av, TidyAttr_USEMAP )
#define attrIsVALIGN(av)            AttrIsId( av, TidyAttr_VALIGN )
#define attrIsVALUE(av)             AttrIsId( av, TidyAttr_VALUE )
#define attrIsVALUETYPE(av)         AttrIsId( av, TidyAttr_VALUETYPE )
#define attrIsVERSION(av)           AttrIsId( av, TidyAttr_VERSION )
#define attrIsVLINK(av)             AttrIsId( av, TidyAttr_VLINK )
#define attrIsVSPACE(av)            AttrIsId( av, TidyAttr_VSPACE )
#define attrIsWIDTH(av)             AttrIsId( av, TidyAttr_WIDTH )
#define attrIsWRAP(av)              AttrIsId( av, TidyAttr_WRAP )
#define attrIsXMLNS(av)             AttrIsId( av, TidyAttr_XMLNS )
#define attrIsXML_LANG(av)          AttrIsId( av, TidyAttr_XML_LANG )
#define attrIsXML_SPACE(av)         AttrIsId( av, TidyAttr_XML_SPACE )


/* Attribute Retrieval macros
*/
#define attrGetHREF( nod )        AttrGetById( nod, TidyAttr_HREF )
#define attrGetSRC( nod )         AttrGetById( nod, TidyAttr_SRC )
#define attrGetID( nod )          AttrGetById( nod, TidyAttr_ID )
#define attrGetNAME( nod )        AttrGetById( nod, TidyAttr_NAME )
#define attrGetSUMMARY( nod )     AttrGetById( nod, TidyAttr_SUMMARY )
#define attrGetALT( nod )         AttrGetById( nod, TidyAttr_ALT )
#define attrGetLONGDESC( nod )    AttrGetById( nod, TidyAttr_LONGDESC )
#define attrGetUSEMAP( nod )      AttrGetById( nod, TidyAttr_USEMAP )
#define attrGetISMAP( nod )       AttrGetById( nod, TidyAttr_ISMAP )
#define attrGetLANGUAGE( nod )    AttrGetById( nod, TidyAttr_LANGUAGE )
#define attrGetTYPE( nod )        AttrGetById( nod, TidyAttr_TYPE )
#define attrGetVALUE( nod )       AttrGetById( nod, TidyAttr_VALUE )
#define attrGetCONTENT( nod )     AttrGetById( nod, TidyAttr_CONTENT )
#define attrGetTITLE( nod )       AttrGetById( nod, TidyAttr_TITLE )
#define attrGetXMLNS( nod )       AttrGetById( nod, TidyAttr_XMLNS )
#define attrGetDATAFLD( nod )     AttrGetById( nod, TidyAttr_DATAFLD )
#define attrGetWIDTH( nod )       AttrGetById( nod, TidyAttr_WIDTH )
#define attrGetHEIGHT( nod )      AttrGetById( nod, TidyAttr_HEIGHT )
#define attrGetFOR( nod )         AttrGetById( nod, TidyAttr_FOR )
#define attrGetSELECTED( nod )    AttrGetById( nod, TidyAttr_SELECTED )
#define attrGetCHECKED( nod )     AttrGetById( nod, TidyAttr_CHECKED )
#define attrGetLANG( nod )        AttrGetById( nod, TidyAttr_LANG )
#define attrGetTARGET( nod )      AttrGetById( nod, TidyAttr_TARGET )
#define attrGetHTTP_EQUIV( nod )  AttrGetById( nod, TidyAttr_HTTP_EQUIV )
#define attrGetREL( nod )         AttrGetById( nod, TidyAttr_REL )

#define attrGetOnMOUSEMOVE( nod ) AttrGetById( nod, TidyAttr_OnMOUSEMOVE )
#define attrGetOnMOUSEDOWN( nod ) AttrGetById( nod, TidyAttr_OnMOUSEDOWN )
#define attrGetOnMOUSEUP( nod )   AttrGetById( nod, TidyAttr_OnMOUSEUP )
#define attrGetOnCLICK( nod )     AttrGetById( nod, TidyAttr_OnCLICK )
#define attrGetOnMOUSEOVER( nod ) AttrGetById( nod, TidyAttr_OnMOUSEOVER )
#define attrGetOnMOUSEOUT( nod )  AttrGetById( nod, TidyAttr_OnMOUSEOUT )
#define attrGetOnKEYDOWN( nod )   AttrGetById( nod, TidyAttr_OnKEYDOWN )
#define attrGetOnKEYUP( nod )     AttrGetById( nod, TidyAttr_OnKEYUP )
#define attrGetOnKEYPRESS( nod )  AttrGetById( nod, TidyAttr_OnKEYPRESS )
#define attrGetOnFOCUS( nod )     AttrGetById( nod, TidyAttr_OnFOCUS )
#define attrGetOnBLUR( nod )      AttrGetById( nod, TidyAttr_OnBLUR )

#define attrGetBGCOLOR( nod )     AttrGetById( nod, TidyAttr_BGCOLOR )

#define attrGetLINK( nod )        AttrGetById( nod, TidyAttr_LINK )
#define attrGetALINK( nod )       AttrGetById( nod, TidyAttr_ALINK )
#define attrGetVLINK( nod )       AttrGetById( nod, TidyAttr_VLINK )

#define attrGetTEXT( nod )        AttrGetById( nod, TidyAttr_TEXT )
#define attrGetSTYLE( nod )       AttrGetById( nod, TidyAttr_STYLE )
#define attrGetABBR( nod )        AttrGetById( nod, TidyAttr_ABBR )
#define attrGetCOLSPAN( nod )     AttrGetById( nod, TidyAttr_COLSPAN )
#define attrGetFONT( nod )        AttrGetById( nod, TidyAttr_FONT )
#define attrGetBASEFONT( nod )    AttrGetById( nod, TidyAttr_BASEFONT )
#define attrGetROWSPAN( nod )     AttrGetById( nod, TidyAttr_ROWSPAN )

#endif /* __ATTRS_H__ */
