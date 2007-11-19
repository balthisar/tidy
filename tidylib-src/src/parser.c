/* parser.c -- HTML Parser

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.56 $ 

*/

#include "tidy-int.h"
#include "lexer.h"
#include "parser.h"
#include "message.h"
#include "clean.h"
#include "tags.h"
#include "tmbstr.h"

Bool CheckNodeIntegrity(Node *node)
{
    if (node->prev)
    {
        if (node->prev->next != node)
            return no;
    }

    if (node->next)
    {
        if (node->next->prev != node)
            return no;
    }

    if (node->parent)
    {
        Node *child = null;
        if (node->prev == null && node->parent->content != node)
            return no;

        if (node->next == null && node->parent->last != node)
            return no;

        for (child = node->parent->content; child; child = child->next)
        {
            if (child == node)
                break;
        }
        if ( node != child )
            return no;
    }

    for (node = node->content; node; node = node->next)
        if ( !CheckNodeIntegrity(node) )
            return no;

    return yes;
}

/*
 used to determine how attributes
 without values should be printed
 this was introduced to deal with
 user defined tags e.g. Cold Fusion
*/
Bool IsNewNode(Node *node)
{
    if (node && node->tag)
    {
        return (node->tag->model & CM_NEW);
    }
    return yes;
}

void CoerceNode( TidyDocImpl* doc, Node *node, TidyTagId tid )
{
    const Dict* tag = LookupTagDef( tid );
    Node* tmp = InferredTag( doc, tag->name );
    ReportWarning( doc, node, tmp, OBSOLETE_ELEMENT );
    MemFree( tmp->element );
    MemFree( tmp );

    node->was = node->tag;
    node->tag = tag;
    node->type = StartTag;
    node->implicit = yes;
    MemFree( node->element );
    node->element = tmbstrdup( tag->name );
}

/* extract a node and its children from a markup tree */
Node *RemoveNode(Node *node)
{
    if (node->prev)
        node->prev->next = node->next;

    if (node->next)
        node->next->prev = node->prev;

    if (node->parent)
    {
        if (node->parent->content == node)
            node->parent->content = node->next;

        if (node->parent->last == node)
            node->parent->last = node->prev;
    }

    node->parent = node->prev = node->next = null;
    return node;
}

/* remove node from markup tree and discard it */
Node *DiscardElement( TidyDocImpl* doc, Node *element )
{
    Node *next = null;

    if (element)
    {
        next = element->next;
        RemoveNode(element);
        FreeNode( doc, element);
    }

    return next;
}

/* insert node into markup tree */
void InsertNodeAtStart(Node *element, Node *node)
{
    node->parent = element;

    if (element->content == null)
        element->last = node;
    else
        element->content->prev = node;
    
    node->next = element->content;
    node->prev = null;
    element->content = node;
}

/* insert node into markup tree */
void InsertNodeAtEnd(Node *element, Node *node)
{
    node->parent = element;
    node->prev = element->last;

    if (element->last != null)
        element->last->next = node;
    else
        element->content = node;

    element->last = node;
}

/*
 insert node into markup tree in place of element
 which is moved to become the child of the node
*/
static void InsertNodeAsParent(Node *element, Node *node)
{
    node->content = element;
    node->last = element;
    node->parent = element->parent;
    element->parent = node;
    
    if (node->parent->content == element)
        node->parent->content = node;

    if (node->parent->last == element)
        node->parent->last = node;

    node->prev = element->prev;
    element->prev = null;

    if (node->prev)
        node->prev->next = node;

    node->next = element->next;
    element->next = null;

    if (node->next)
        node->next->prev = node;
}

/* insert node into markup tree before element */
void InsertNodeBeforeElement(Node *element, Node *node)
{
    Node *parent;

    parent = element->parent;
    node->parent = parent;
    node->next = element;
    node->prev = element->prev;
    element->prev = node;

    if (node->prev)
        node->prev->next = node;

    if (parent->content == element)
        parent->content = node;
}

/* insert node into markup tree after element */
void InsertNodeAfterElement(Node *element, Node *node)
{
    Node *parent;

    parent = element->parent;
    node->parent = parent;

    /* AQ - 13 Jan 2000 fix for parent == null */
    if (parent != null && parent->last == element)
        parent->last = node;
    else
    {
        node->next = element->next;
        /* AQ - 13 Jan 2000 fix for node->next == null */
        if (node->next != null)
            node->next->prev = node;
    }

    element->next = node;
    node->prev = element;
}

static Bool CanPrune( TidyDocImpl* doc, Node *element )
{
    if (element->type == TextNode)
        return yes;

    if (element->content)
        return no;

    if ( element->tag->model & CM_BLOCK && element->attributes != null )
        return no;

    if ( nodeIsA(element) && element->attributes != null )
        return no;

    if ( nodeIsP(element) && !cfgBool(doc, TidyDropEmptyParas) )
        return no;

    if ( element->tag == null )
        return no;

    if ( element->tag->model & CM_ROW )
        return no;

    if ( element->tag->model & CM_EMPTY )
        return no;

    if ( nodeIsAPPLET(element) )
        return no;

    if ( nodeIsOBJECT(element) )
        return no;

    if ( nodeIsSCRIPT(element) && attrGetSRC(element) )
        return no;

    if ( nodeIsTITLE(element) )
        return no;

    /* #433359 - fix by Randy Waki 12 Mar 01 */
    if ( nodeIsIFRAME(element) )
        return no;

    if ( attrGetID(element) || attrGetNAME(element) )
        return no;

    return yes;
}

Node *TrimEmptyElement( TidyDocImpl* doc, Node *element )
{
    if ( CanPrune(doc, element) )
    {
       if ( element->type != TextNode )
            ReportWarning( doc, element, null, TRIM_EMPTY_ELEMENT);
        return DiscardElement(doc, element);
    }
    else if ( nodeIsP(element) && element->content == null )
    {
        /* Put a non-breaking space into empty paragraphs.
        ** Contrary to intent, replacing empty paragraphs
        ** with two <br><br> does not preserve formatting.
        */
        char onesixty[2] = { '\240', 0 };
        InsertNodeAtStart( element, NewLiteralTextNode(doc->lexer, onesixty) );
    }
    return element;
}

/* 
  errors in positioning of form start or end tags
  generally require human intervention to fix
*/
static void BadForm( TidyDocImpl* doc )
{
    doc->badForm = yes;
    /* doc->errors++; */
}

/*
  This maps 
       <em>hello </em><strong>world</strong>
  to
       <em>hello</em> <strong>world</strong>

  If last child of element is a text node
  then trim trailing white space character
  moving it to after element's end tag.
*/
static void TrimTrailingSpace( TidyDocImpl* doc, Node *element, Node *last )
{
    Lexer* lexer = doc->lexer;
    byte c;

    if (last != null && last->type == TextNode)
    {
        if (last->end > last->start)
        {
            c = (byte) lexer->lexbuf[ last->end - 1 ];

            if (   c == ' '
#ifdef COMMENT_NBSP_FIX
                || c == 160
#endif
               )
            {
#ifdef COMMENT_NBSP_FIX
                /* take care with <td>&nbsp;</td> */
                if ( c == 160 && 
                     ( element->tag == doc->tags.tag_td || 
                       element->tag == doc->tags.tag_th )
                   )
                {
                    if (last->end > last->start + 1)
                        last->end -= 1;
                }
                else
#endif
                {
                    last->end -= 1;
                    if ( (element->tag->model & CM_INLINE) &&
                         !(element->tag->model & CM_FIELD) )
                        lexer->insertspace = yes;
                }
            }
        }
        /* if empty string then delete from parse tree */
        if ( last->start == last->end
#ifdef COMMENT_NBSP_FIX
             && tag != doc->tags.tag_td 
             && tag != doc->tags.tag_th
#endif
            )
            TrimEmptyElement( doc, last );
    }
}

static Node *EscapeTag(Lexer *lexer, Node *element)
{
    Node *node = NewNode(lexer);

    node->start = lexer->lexsize;
    AddByte(lexer, '<');

    if (element->type == EndTag)
        AddByte(lexer, '/');

    if (element->element)
    {
        char *p;
        for (p = element->element; *p != '\0'; ++p)
            AddByte(lexer, *p);
    }
    else if (element->type == DocTypeTag)
    {
        uint i;
        AddStringLiteral( lexer, "!DOCTYPE " );
        for (i = element->start; i < element->end; ++i)
            AddByte(lexer, lexer->lexbuf[i]);
    }

    if (element->type == StartEndTag)
        AddByte(lexer, '/');

    AddByte(lexer, '>');
    node->end = lexer->lexsize;

    return node;
}

/* Only true for text nodes. */
Bool IsBlank(Lexer *lexer, Node *node)
{
    Bool isBlank = ( node->type == TextNode );
    if ( isBlank )
        isBlank = ( node->end == node->start ||       /* Zero length */
                    ( node->end == node->start+1      /* or one blank. */
                      && lexer->lexbuf[node->start] == ' ' ) );
    return isBlank;
}

/*
  This maps 
       <p>hello<em> world</em>
  to
       <p>hello <em>world</em>

  Trims initial space, by moving it before the
  start tag, or if this element is the first in
  parent's content, then by discarding the space
*/
static void TrimInitialSpace( TidyDocImpl* doc, Node *element, Node *text )
{
    Lexer* lexer = doc->lexer;
    Node *prev, *node;

    if ( text->type == TextNode && 
         lexer->lexbuf[text->start] == ' ' && 
         text->start < text->end )
    {
        if ( (element->tag->model & CM_INLINE) &&
             !(element->tag->model & CM_FIELD) &&
             element->parent->content != element )
        {
            prev = element->prev;

            if (prev && prev->type == TextNode)
            {
                if (lexer->lexbuf[prev->end - 1] != ' ')
                    lexer->lexbuf[(prev->end)++] = ' ';

                ++(element->start);
            }
            else /* create new node */
            {
                node = NewNode(lexer);
                node->start = (element->start)++;
                node->end = element->start;
                lexer->lexbuf[node->start] = ' ';
                node->prev = prev;

                if (prev)
                    prev->next = node;

                node->next = element;
                element->prev = node;
                node->parent = element->parent;
            }
        }

        /* discard the space in current node */
        ++(text->start);
    }
}

/* 
  Move initial and trailing space out.
  This routine maps:

       hello<em> world</em>
  to
       hello <em>world</em>
  and
       <em>hello </em><strong>world</strong>
  to
       <em>hello</em> <strong>world</strong>
*/
static void TrimSpaces( TidyDocImpl* doc, Node *element)
{
    Node* text = element->content;
    if ( nodeIsText(text) && !nodeIsPRE(element) )
        TrimInitialSpace( doc, element, text );

    text = element->last;
    if ( nodeIsText(text) )
        TrimTrailingSpace( doc, element, text );
}

Bool DescendantOf( Node *element, TidyTagId tid )
{
    Node *parent;
    for ( parent = element->parent;
          parent != null;
          parent = parent->parent )
    {
        if ( TagIsId(parent, tid) )
            return yes;
    }
    return no;
}

static Bool InsertMisc(Node *element, Node *node)
{
    if (node->type == CommentTag ||
        node->type == ProcInsTag ||
        node->type == CDATATag ||
        node->type == SectionTag ||
        node->type == AspTag ||
        node->type == JsteTag ||
        node->type == PhpTag )
    {
        InsertNodeAtEnd(element, node);
        return yes;
    }

    if ( node->type == XmlDecl )
    {
        Node* root = element;
        while ( root && root->parent )
            root = root->parent;
        if ( root )
        {
          InsertNodeAtStart( root, node );
          return yes;
        }
    }

    /* Declared empty tags seem to be slipping through
    ** the cracks.  This is an experiment to figure out
    ** a decent place to pick them up.
    */
    if ( node->tag &&
         (node->type == StartTag || node->type == StartEndTag) &&
         nodeCMIsEmpty(node) && TagId(node) == TidyTag_UNKNOWN &&
         (node->tag->versions & VERS_PROPRIETARY) != 0 )
    {
        InsertNodeAtEnd(element, node);
        return yes;
    }

    return no;
}


static void ParseTag( TidyDocImpl* doc, Node *node, uint mode )
{
    Lexer* lexer = doc->lexer;
    /*
       Fix by GLP 2000-12-21.  Need to reset insertspace if this 
       is both a non-inline and empty tag (base, link, meta, isindex, hr, area).
    */
    if (node->tag->model & CM_EMPTY)
    {
        lexer->waswhite = no;
        if (node->tag->parser == null)
            return;
    }
    else if (!(node->tag->model & CM_INLINE))
        lexer->insertspace = no;

    if (node->tag->parser == null)
        return;

    if (node->type == StartEndTag)
    {
        TrimEmptyElement( doc, node );
        return;
    }

    (*node->tag->parser)( doc, node, mode );
}

/*
 the doctype has been found after other tags,
 and needs moving to before the html element
*/
static void InsertDocType( TidyDocImpl* doc, Node *element, Node *doctype )
{
    Node* existing = FindDocType( doc );
    if ( existing )
    {
        ReportWarning( doc, element, doctype, DISCARDING_UNEXPECTED );
        FreeNode( doc, doctype );
    }
    else
    {
        ReportWarning( doc, element, doctype, DOCTYPE_AFTER_TAGS );
        while ( !nodeIsHTML(element) )
            element = element->parent;
        InsertNodeBeforeElement( element, doctype );
    }
}

/*
 duplicate name attribute as an id
 and check if id and name match
*/
void FixId( TidyDocImpl* doc, Node *node )
{
    AttVal *name = GetAttrByName(node, "name");
    AttVal *id = GetAttrByName(node, "id");

    if (name)
    {
        if (id)
        {
            if ( name->value != null && id->value != null &&
                 tmbstrcmp(id->value, name->value) != 0 )
                ReportAttrError( doc, node, name, ID_NAME_MISMATCH );
        }
        else if ( cfgBool(doc, TidyXmlOut) )
            AddAttribute( doc, node, "id", name->value );
    }
}

/*
 move node to the head, where element is used as starting
 point in hunt for head. normally called during parsing
*/
static void MoveToHead( TidyDocImpl* doc, Node *element, Node *node )
{
    Node *head;

    RemoveNode( node );  /* make sure that node is isolated */

    if ( node->type == StartTag || node->type == StartEndTag )
    {
        ReportWarning( doc, element, node, TAG_NOT_ALLOWED_IN );

        while ( !nodeIsHTML(element) )
            element = element->parent;

        for (head = element->content; head; head = head->next)
        {
            if ( nodeIsHEAD(head) )
            {
                InsertNodeAtEnd(head, node);
                break;
            }
        }

        if ( node->tag->parser )
            ParseTag( doc, node, IgnoreWhitespace );
    }
    else
    {
        ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node );
    }
}

/* moves given node to end of body element */
static void MoveNodeToBody( TidyDocImpl* doc, Node* node )
{
    Node* body = FindBody( doc );
    RemoveNode( node );
    InsertNodeAtEnd( body, node );
}

/*
   element is node created by the lexer
   upon seeing the start tag, or by the
   parser when the start tag is inferred
*/
void ParseBlock( TidyDocImpl* doc, Node *element, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node, *parent;
    Bool checkstack = yes;
    uint istackbase = 0;

    if ( element->tag->model & CM_EMPTY )
        return;

    if ( nodeIsFORM(element) && 
         DescendantOf(element, TidyTag_FORM) )
        ReportWarning( doc, element, null, ILLEGAL_NESTING );

    /*
     InlineDup() asks the lexer to insert inline emphasis tags
     currently pushed on the istack, but take care to avoid
     propagating inline emphasis inside OBJECT or APPLET.
     For these elements a fresh inline stack context is created
     and disposed of upon reaching the end of the element.
     They thus behave like table cells in this respect.
    */
    if (element->tag->model & CM_OBJECT)
    {
        istackbase = lexer->istackbase;
        lexer->istackbase = lexer->istacksize;
    }

    if (!(element->tag->model & CM_MIXED))
        InlineDup( doc, null );

    mode = IgnoreWhitespace;

    while ((node = GetToken(doc, mode /*MixedContent*/)) != null)
    {
        /* end tag for this element */
        if (node->type == EndTag && node->tag &&
            (node->tag == element->tag || element->was == node->tag))
        {
            FreeNode( doc, node );

            if (element->tag->model & CM_OBJECT)
            {
                /* pop inline stack */
                while (lexer->istacksize > lexer->istackbase)
                    PopInline( doc, null );
                lexer->istackbase = istackbase;
            }

            element->closed = yes;
            TrimSpaces( doc, element );
            TrimEmptyElement( doc, element );
            return;
        }

        if ( nodeIsHTML(node) || nodeIsHEAD(node) || nodeIsBODY(node) )
        {
            if ( node->type == StartTag || node->type == StartEndTag )
                ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
            FreeNode( doc, node );
            continue;
        }


        if (node->type == EndTag)
        {
            if (node->tag == null)
            {
                ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
                FreeNode( doc, node );
                continue;
            }
            else if ( nodeIsBR(node) )
                node->type = StartTag;
            else if ( nodeIsP(node) )
            {
                CoerceNode( doc, node, TidyTag_BR );
                FreeAttrs( doc, node ); /* discard align attribute etc. */
                InsertNodeAtEnd( element, node );
                node = InferredTag( doc, "br" );
            }
            else
            {
                /* 
                  if this is the end tag for an ancestor element
                  then infer end tag for this element
                */
                for ( parent = element->parent;
                      parent != null; 
                      parent = parent->parent )
                {
                    if (node->tag == parent->tag)
                    {
                        if (!(element->tag->model & CM_OPT))
                            ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE );

                        UngetToken( doc );

                        if (element->tag->model & CM_OBJECT)
                        {
                            /* pop inline stack */
                            while (lexer->istacksize > lexer->istackbase)
                                PopInline( doc, null );
                            lexer->istackbase = istackbase;
                        }

                        TrimSpaces( doc, element );
                        TrimEmptyElement( doc, element );
                        return;
                    }
                }

                /* special case </tr> etc. for stuff moved in front of table */
                if ( lexer->exiled
                     && node->tag->model
                     && (node->tag->model & CM_TABLE) )
                {
                    UngetToken( doc );
                    TrimSpaces( doc, element );
                    TrimEmptyElement( doc, element );
                    return;
                }
            }
        }

        /* mixed content model permits text */
        if (node->type == TextNode)
        {
            Bool iswhitenode = ( node->type == TextNode &&
                                 node->end <= node->start + 1 &&
                                 lexer->lexbuf[node->start] == ' ' );

            if ( cfgBool(doc, TidyEncloseBlockText) && !iswhitenode )
            {
                UngetToken( doc );
                node = InferredTag( doc, "p" );
                InsertNodeAtEnd( element, node );
                ParseTag( doc, node, MixedContent );
                continue;
            }

            if ( checkstack )
            {
                checkstack = no;
                if (!(element->tag->model & CM_MIXED))
                {
                    if ( InlineDup(doc, node) > 0 )
                        continue;
                }
            }

            InsertNodeAtEnd(element, node);
            mode = MixedContent;

            /*
              HTML4 strict doesn't allow mixed content for
              elements with %block; as their content model
            */
            /*
              But only body, map, blockquote, form and
              noscript have content model %block;
            */
            if ( nodeIsBODY(element)       ||
                 nodeIsMAP(element)        ||
                 nodeIsBLOCKQUOTE(element) ||
                 nodeIsFORM(element)       ||
                 nodeIsNOSCRIPT(element) )
                ConstrainVersion( doc, ~VERS_HTML40_STRICT );
            continue;
        }

        if ( InsertMisc(element, node) )
            continue;

        /* allow PARAM elements? */
        if ( nodeIsPARAM(node) )
        {
            if ( nodeHasCM(element, CM_PARAM) &&
                 (node->type == StartEndTag || node->type == StartTag) )
            {
                InsertNodeAtEnd(element, node);
                continue;
            }

            /* otherwise discard it */
            ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
            FreeNode( doc, node );
            continue;
        }

        /* allow AREA elements? */
        if ( nodeIsAREA(node) )
        {
            if ( nodeIsMAP(element) &&
                 (node->type == StartTag || node->type == StartEndTag) )
            {
                InsertNodeAtEnd(element, node);
                continue;
            }

            /* otherwise discard it */
            ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
            FreeNode( doc, node );
            continue;
        }

        /* ignore unknown start/end tags */
        if ( node->tag == null )
        {
            ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
            FreeNode( doc, node );
            continue;
        }

        /*
          Allow CM_INLINE elements here.

          Allow CM_BLOCK elements here unless
          lexer->excludeBlocks is yes.

          LI and DD are special cased.

          Otherwise infer end tag for this element.
        */

        if ( !nodeHasCM(node, CM_INLINE) )
        {
            if (node->type != StartTag && node->type != StartEndTag)
            {
                if ( nodeIsFORM(node) )
                    BadForm( doc );

                ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
                FreeNode( doc, node );
                continue;
            }

            /* #427671 - Fix by Randy Waki - 10 Aug 00 */
            /*
             If an LI contains an illegal FRAME, FRAMESET, OPTGROUP, or OPTION
             start tag, discard the start tag and let the subsequent content get
             parsed as content of the enclosing LI.  This seems to mimic IE and
             Netscape, and avoids an infinite loop: without this check,
             ParseBlock (which is parsing the LI's content) and ParseList (which
             is parsing the LI's parent's content) repeatedly defer to each
             other to parse the illegal start tag, each time inferring a missing
             </li> or <li> respectively.

             NOTE: This check is a bit fragile.  It specifically checks for the
             four tags that happen to weave their way through the current series
             of tests performed by ParseBlock and ParseList to trigger the
             infinite loop.
            */
            if ( nodeIsLI(element) )
            {
                if ( nodeIsFRAME(node)    ||
                     nodeIsFRAMESET(node) ||
                     nodeIsOPTGROUP(node) ||
                     nodeIsOPTION(node) )
                {
                    ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
                    FreeNode( doc, node );  /* DSR - 27Apr02 avoid memory leak */
                    continue;
                }
            }

            if ( nodeIsTD(element) || nodeIsTH(element) )
            {
                /* if parent is a table cell, avoid inferring the end of the cell */

                if ( nodeHasCM(node, CM_HEAD) )
                {
                    MoveToHead( doc, element, node );
                    continue;
                }

                if ( nodeHasCM(node, CM_LIST) )
                {
                    UngetToken( doc );
                    node = InferredTag( doc, "ul" );
                    AddClass( doc, node, "noindent" );
                    lexer->excludeBlocks = yes;
                }
                else if ( nodeHasCM(node, CM_DEFLIST) )
                {
                    UngetToken( doc );
                    node = InferredTag( doc, "dl" );
                    lexer->excludeBlocks = yes;
                }

                /* infer end of current table cell */
                if ( !nodeHasCM(node, CM_BLOCK) )
                {
                    UngetToken( doc );
                    TrimSpaces( doc, element );
                    TrimEmptyElement( doc, element );
                    return;
                }
            }
            else if ( nodeHasCM(node, CM_BLOCK) )
            {
                if ( lexer->excludeBlocks )
                {
                    if ( !nodeHasCM(element, CM_OPT) )
                        ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE );

                    UngetToken( doc );

                    if ( nodeHasCM(element, CM_OBJECT) )
                        lexer->istackbase = istackbase;

                    TrimSpaces( doc, element );
                    TrimEmptyElement( doc, element );
                    return;
                }
            }
            else /* things like list items */
            {
                if (node->tag->model & CM_HEAD)
                {
                    MoveToHead( doc, element, node );
                    continue;
                }

                /*
                 special case where a form start tag
                 occurs in a tr and is followed by td or th
                */

                if ( nodeIsFORM(element) &&
                     nodeIsTD(element->parent) &&
                     element->parent->implicit )
                {
                    if ( nodeIsTD(node) )
                    {
                        ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
                        FreeNode( doc, node );
                        continue;
                    }

                    if ( nodeIsTH(node) )
                    {
                        ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
                        FreeNode( doc, node );
                        node = element->parent;
                        MemFree(node->element);
                        node->element = tmbstrdup("th");
                        node->tag = LookupTagDef( TidyTag_TH );
                        continue;
                    }
                }

                if ( !nodeHasCM(element, CM_OPT) && !element->implicit )
                    ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE );

                UngetToken( doc );

                if ( nodeHasCM(node, CM_LIST) )
                {
                    if ( element->parent && element->parent->tag &&
                         element->parent->tag->parser == ParseList )
                    {
                        TrimSpaces( doc, element );
                        TrimEmptyElement( doc, element );
                        return;
                    }

                    node = InferredTag( doc, "ul" );
                    AddClass( doc, node, "noindent" );
                }
                else if ( nodeHasCM(node, CM_DEFLIST) )
                {
                    if ( nodeIsDL(element->parent) )
                    {
                        TrimSpaces( doc, element );
                        TrimEmptyElement( doc, element );
                        return;
                    }

                    node = InferredTag( doc, "dl" );
                }
                else if ( nodeHasCM(node, CM_TABLE) || nodeHasCM(node, CM_ROW) )
                {
                    node = InferredTag( doc, "table" );
                }
                else if ( nodeHasCM(element, CM_OBJECT) )
                {
                    /* pop inline stack */
                    while ( lexer->istacksize > lexer->istackbase )
                        PopInline( doc, null );
                    lexer->istackbase = istackbase;
                    TrimSpaces( doc, element );
                    TrimEmptyElement( doc, element );
                    return;

                }
                else
                {
                    TrimSpaces( doc, element );
                    TrimEmptyElement( doc, element );
                    return;
                }
            }
        }

        /* parse known element */
        if (node->type == StartTag || node->type == StartEndTag)
        {
            if (node->tag->model & CM_INLINE)
            {
                /* DSR - 27Apr02 ensure we wrap anchors and other inline content */
                if ( cfgBool(doc, TidyEncloseBlockText) )
                {
                    UngetToken( doc );
                    node = InferredTag( doc, "p" );
                    InsertNodeAtEnd( element, node );
                    ParseTag( doc, node, MixedContent );
                    continue;
                }

                if (checkstack && !node->implicit)
                {
                    checkstack = no;

                    if (!(element->tag->model & CM_MIXED)) /* #431731 - fix by Randy Waki 25 Dec 00 */
                    {
                        if ( InlineDup(doc, node) > 0 )
                            continue;
                    }
                }

                mode = MixedContent;
            }
            else
            {
                checkstack = yes;
                mode = IgnoreWhitespace;
            }

            /* trim white space before <br> */
            if ( nodeIsBR(node) )
                TrimSpaces( doc, element );

            InsertNodeAtEnd(element, node);
            
            if (node->implicit)
                ReportWarning( doc, element, node, INSERTING_TAG );

            ParseTag( doc, node, IgnoreWhitespace /*MixedContent*/ );
            continue;
        }

        /* discard unexpected tags */
        if (node->type == EndTag)
            PopInline( doc, node );  /* if inline end tag */

        ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
        FreeNode( doc, node );
        continue;
    }

    if (!(element->tag->model & CM_OPT))
        ReportWarning( doc, element, node, MISSING_ENDTAG_FOR);

    if (element->tag->model & CM_OBJECT)
    {
        /* pop inline stack */
        while ( lexer->istacksize > lexer->istackbase )
            PopInline( doc, null );
        lexer->istackbase = istackbase;
    }

    TrimSpaces( doc, element );
    TrimEmptyElement( doc, element );
}

void ParseInline( TidyDocImpl* doc, Node *element, uint mode )
{
    Lexer* lexer = doc->lexer;
    Node *node, *parent;

    if (element->tag->model & CM_EMPTY)
        return;

    /*
     ParseInline is used for some block level elements like H1 to H6
     For such elements we need to insert inline emphasis tags currently
     on the inline stack. For Inline elements, we normally push them
     onto the inline stack provided they aren't implicit or OBJECT/APPLET.
     This test is carried out in PushInline and PopInline, see istack.c
     We don't push SPAN to replicate current browser behavior
    */
    if ( nodeHasCM(element, CM_BLOCK) || nodeIsDT(element) )
        InlineDup( doc, null );
    else if ( nodeHasCM(element, CM_INLINE) )
        PushInline( doc, element );

    if ( nodeIsNOBR(element) )
        doc->badLayout |= USING_NOBR;
    else if ( nodeIsFONT(element) )
        doc->badLayout |= USING_FONT;

    /* Inline elements may or may not be within a preformatted element */
    if (mode != Preformatted)
        mode = MixedContent;

    while ((node = GetToken(doc, mode)) != null)
    {
        /* end tag for current element */
        if (node->tag == element->tag && node->type == EndTag)
        {
            if (element->tag->model & CM_INLINE)
                PopInline( doc, node );

            FreeNode( doc, node );

            if (!(mode & Preformatted))
                TrimSpaces(doc, element);

            /*
             if a font element wraps an anchor and nothing else
             then move the font element inside the anchor since
             otherwise it won't alter the anchor text color
            */
            if ( nodeIsFONT(element) && 
                 element->content && element->content == element->last )
            {
                Node *child = element->content;

                if ( nodeIsA(child) )
                {
                    child->parent = element->parent;
                    child->next = element->next;
                    child->prev = element->prev;

                    if (child->prev)
                        child->prev->next = child;
                    else
                        child->parent->content = child;

                    if (child->next)
                        child->next->prev = child;
                    else
                        child->parent->last = child;

                    element->next = null;
                    element->prev = null;
                    element->parent = child;
                    element->content = child->content;
                    element->last = child->last;
                    child->content = child->last = element;

                    for (child = element->content; child; child = child->next)
                        child->parent = element;
                }
            }

            element->closed = yes;
            TrimSpaces( doc, element );
            TrimEmptyElement( doc, element );
            return;
        }

        /* <u>...<u>  map 2nd <u> to </u> if 1st is explicit */
        /* otherwise emphasis nesting is probably unintentional */
        /* big and small have cumulative effect to leave them alone */
        if ( node->type == StartTag
             && node->tag == element->tag
             && IsPushed( doc, node )
             && !node->implicit
             && !element->implicit
             && node->tag && (node->tag->model & CM_INLINE)
             && !nodeIsA(node)
             && !nodeIsFONT(node)
             && !nodeIsBIG(node)
             && !nodeIsSMALL(node)
             && !nodeIsQ(node)
           )
        {
            if ( element->content != null && node->attributes == null )
            {
                ReportWarning( doc, element, node, COERCE_TO_ENDTAG );
                node->type = EndTag;
                UngetToken( doc );
                continue;
            }

            ReportWarning( doc, element, node, NESTED_EMPHASIS );
        }
        else if ( IsPushed(doc, node) && node->type == StartTag && 
                  nodeIsQ(node) )
        {
            ReportWarning( doc, element, node, NESTED_QUOTATION );
        }

        if ( node->type == TextNode )
        {
            /* only called for 1st child */
            if ( element->content == null && !(mode & Preformatted) )
                TrimSpaces( doc, element );

            if ( node->start >= node->end )
            {
                FreeNode( doc, node );
                continue;
            }

            InsertNodeAtEnd(element, node);
            continue;
        }

        /* mixed content model so allow text */
        if (InsertMisc(element, node))
            continue;

        /* deal with HTML tags */
        if ( nodeIsHTML(node) )
        {
            if ( node->type == StartTag || node->type == StartEndTag )
            {
                ReportWarning( doc, element, node, DISCARDING_UNEXPECTED );
                FreeNode( doc, node );
                continue;
            }

            /* otherwise infer end of inline element */
            UngetToken( doc );

            if (!(mode & Preformatted))
                TrimSpaces(doc, element);

            TrimEmptyElement(doc, element);
            return;
        }

        /* within <dt> or <pre> map <p> to <br> */
        if ( nodeIsP(node) &&
             node->type == StartTag &&
             ( (mode & Preformatted) ||
               nodeIsDT(element) || 
               DescendantOf(element, TidyTag_DT )
             )
           )
        {
            node->tag = LookupTagDef( TidyTag_BR );
            MemFree(node->element);
            node->element = tmbstrdup("br");
            TrimSpaces(doc, element);
            InsertNodeAtEnd(element, node);
            continue;
        }

        /* ignore unknown and PARAM tags */
        if ( node->tag == null || nodeIsPARAM(node) )
        {
            ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node );
            continue;
        }

        if ( nodeIsBR(node) && node->type == EndTag )
            node->type = StartTag;

        if ( node->type == EndTag )
        {
           /* coerce </br> to <br> */
           if ( nodeIsBR(node) )
                node->type = StartTag;
           else if ( nodeIsP(node) )
           {
               /* coerce unmatched </p> to <br><br> */
                if ( !DescendantOf(element, TidyTag_P) )
                {
                    CoerceNode( doc, node, TidyTag_BR );
                    TrimSpaces( doc, element );
                    InsertNodeAtEnd( element, node );
                    node = InferredTag(doc, "br");
                    continue;
                }
           }
           else if ( nodeHasCM(node, CM_INLINE)
                     && !nodeIsA(node)
                     && !nodeHasCM(node, CM_OBJECT)
                     && nodeHasCM(element, CM_INLINE) )
            {
                /* allow any inline end tag to end current element */
                PopInline( doc, element );

                if ( !nodeIsA(element) )
                {
                    if ( nodeIsA(node) && node->tag != element->tag )
                    {
                       ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE );
                       UngetToken( doc );
                    }
                    else
                    {
                        ReportWarning( doc, element, node, NON_MATCHING_ENDTAG);
                        FreeNode( doc, node);
                    }

                    if (!(mode & Preformatted))
                        TrimSpaces(doc, element);

                    TrimEmptyElement(doc, element);
                    return;
                }

                /* if parent is <a> then discard unexpected inline end tag */
                ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }  /* special case </tr> etc. for stuff moved in front of table */
            else if ( lexer->exiled
                      && node->tag->model
                      && (node->tag->model & CM_TABLE) )
            {
                UngetToken( doc );
                TrimSpaces(doc, element);
                TrimEmptyElement(doc, element);
                return;
            }
        }

        /* allow any header tag to end current header */
        if ( nodeHasCM(node, CM_HEADING) && nodeHasCM(element, CM_HEADING) )
        {

            if ( node->tag == element->tag )
            {
                ReportWarning( doc, element, node, NON_MATCHING_ENDTAG );
                FreeNode( doc, node);
            }
            else
            {
                ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE );
                UngetToken( doc );
            }

            if (!(mode & Preformatted))
                TrimSpaces(doc, element);

            TrimEmptyElement(doc, element);
            return;
        }

        /*
           an <A> tag to ends any open <A> element
           but <A href=...> is mapped to </A><A href=...>
        */
        /* #427827 - fix by Randy Waki and Bjoern Hoehrmann 23 Aug 00 */
        /* if (node->tag == doc->tags.tag_a && !node->implicit && IsPushed(doc, node)) */
        if ( nodeIsA(node) && !node->implicit && 
             (nodeIsA(element) || DescendantOf(element, TidyTag_A)) )
        {
            /* coerce <a> to </a> unless it has some attributes */
            /* #427827 - fix by Randy Waki and Bjoern Hoehrmann 23 Aug 00 */
            /* other fixes by Dave Raggett */
            /* if (node->attributes == null) */
            if (node->type != EndTag && node->attributes == null)
            {
                node->type = EndTag;
                ReportWarning( doc, element, node, COERCE_TO_ENDTAG);
                /* PopInline( doc, node ); */
                UngetToken( doc );
                continue;
            }

            UngetToken( doc );
            ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE);
            /* PopInline( doc, element ); */

            if (!(mode & Preformatted))
                TrimSpaces(doc, element);

            TrimEmptyElement(doc, element);
            return;
        }

        if (element->tag->model & CM_HEADING)
        {
            if ( nodeIsCENTER(node) || nodeIsDIV(node) )
            {
                if (node->type != StartTag && node->type != StartEndTag)
                {
                    ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
                    FreeNode( doc, node);
                    continue;
                }

                ReportWarning( doc, element, node, TAG_NOT_ALLOWED_IN);

                /* insert center as parent if heading is empty */
                if (element->content == null)
                {
                    InsertNodeAsParent(element, node);
                    continue;
                }

                /* split heading and make center parent of 2nd part */
                InsertNodeAfterElement(element, node);

                if (!(mode & Preformatted))
                    TrimSpaces(doc, element);

                element = CloneNode( doc, element );
                InsertNodeAtEnd(node, element);
                continue;
            }

            if ( nodeIsHR(node) )
            {
                if ( node->type != StartTag && node->type != StartEndTag )
                {
                    ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
                    FreeNode( doc, node);
                    continue;
                }

                ReportWarning( doc, element, node, TAG_NOT_ALLOWED_IN);

                /* insert hr before heading if heading is empty */
                if (element->content == null)
                {
                    InsertNodeBeforeElement(element, node);
                    continue;
                }

                /* split heading and insert hr before 2nd part */
                InsertNodeAfterElement(element, node);

                if (!(mode & Preformatted))
                    TrimSpaces(doc, element);

                element = CloneNode( doc, element );
                InsertNodeAfterElement(node, element);
                continue;
            }
        }

        if ( nodeIsDT(element) )
        {
            if ( nodeIsHR(node) )
            {
                Node *dd;
                if (node->type != StartTag && node->type != StartEndTag)
                {
                    ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
                    FreeNode( doc, node);
                    continue;
                }

                ReportWarning( doc, element, node, TAG_NOT_ALLOWED_IN);
                dd = InferredTag(doc, "dd");

                /* insert hr within dd before dt if dt is empty */
                if (element->content == null)
                {
                    InsertNodeBeforeElement(element, dd);
                    InsertNodeAtEnd(dd, node);
                    continue;
                }

                /* split dt and insert hr within dd before 2nd part */
                InsertNodeAfterElement(element, dd);
                InsertNodeAtEnd(dd, node);

                if (!(mode & Preformatted))
                    TrimSpaces(doc, element);

                element = CloneNode( doc, element );
                InsertNodeAfterElement(dd, element);
                continue;
            }
        }


        /* 
          if this is the end tag for an ancestor element
          then infer end tag for this element
        */
        if (node->type == EndTag)
        {
            for (parent = element->parent;
                    parent != null; parent = parent->parent)
            {
                if (node->tag == parent->tag)
                {
                    if (!(element->tag->model & CM_OPT) && !element->implicit)
                        ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE);

                    PopInline( doc, element );
                    UngetToken( doc );

                    if (!(mode & Preformatted))
                        TrimSpaces(doc, element);

                    TrimEmptyElement(doc, element);
                    return;
                }
            }
        }

        /* block level tags end this element */
        if (!(node->tag->model & CM_INLINE))
        {
            if (node->type != StartTag)
            {
                ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            if (!(element->tag->model & CM_OPT))
                ReportWarning( doc, element, node, MISSING_ENDTAG_BEFORE);

            if (node->tag->model & CM_HEAD && !(node->tag->model & CM_BLOCK))
            {
                MoveToHead(doc, element, node);
                continue;
            }

            /*
               prevent anchors from propagating into block tags
               except for headings h1 to h6
            */
            if ( nodeIsA(element) )
            {
                if (node->tag && !(node->tag->model & CM_HEADING))
                    PopInline( doc, element );
                else if (!(element->content))
                {
                    DiscardElement( doc, element );
                    UngetToken( doc );
                    return;
                }
            }

            UngetToken( doc );

            if (!(mode & Preformatted))
                TrimSpaces(doc, element);

            TrimEmptyElement(doc, element);
            return;
        }

        /* parse inline element */
        if (node->type == StartTag || node->type == StartEndTag)
        {
            if (node->implicit)
                ReportWarning( doc, element, node, INSERTING_TAG);

            /* trim white space before <br> */
            if ( nodeIsBR(node) )
                TrimSpaces(doc, element);
            
            InsertNodeAtEnd(element, node);
            ParseTag(doc, node, mode);
            continue;
        }

        /* discard unexpected tags */
        ReportWarning( doc, element, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
        continue;
    }

    if (!(element->tag->model & CM_OPT))
        ReportWarning( doc, element, node, MISSING_ENDTAG_FOR);

    TrimEmptyElement(doc, element);
}

void ParseEmpty(TidyDocImpl* doc, Node *element, uint mode)
{
    Lexer* lexer = doc->lexer;
    if ( lexer->isvoyager )
    {
        Node *node = GetToken( doc, mode);
        if (!(node->type == EndTag && node->tag == element->tag))
        {
            ReportWarning( doc, element, node, ELEMENT_NOT_EMPTY);
            UngetToken( doc );
        }
    }
}

void ParseDefList(TidyDocImpl* doc, Node *list, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node, *parent;

    if (list->tag->model & CM_EMPTY)
        return;

    lexer->insert = null;  /* defer implicit inline start tags */

    while ((node = GetToken( doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == list->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            list->closed = yes;
            TrimEmptyElement( doc, list);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(list, node))
            continue;

        if (node->type == TextNode)
        {
            UngetToken( doc );
            node = InferredTag( doc, "dt");
            ReportWarning( doc, list, node, MISSING_STARTTAG);
        }

        if (node->tag == null)
        {
            ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* 
          if this is the end tag for an ancestor element
          then infer end tag for this element
        */
        if (node->type == EndTag)
        {
            if ( nodeIsFORM(node) )
            {
                BadForm( doc );
                ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
                continue;
            }

            for (parent = list->parent;
                    parent != null; parent = parent->parent)
            {
                if (node->tag == parent->tag)
                {
                    ReportWarning( doc, list, node, MISSING_ENDTAG_BEFORE);

                    UngetToken( doc );
                    TrimEmptyElement( doc, list);
                    return;
                }
            }
        }

        /* center in a dt or a dl breaks the dl list in two */
        if ( nodeIsCENTER(node) )
        {
            if (list->content)
                InsertNodeAfterElement(list, node);
            else /* trim empty dl list */
            {
                InsertNodeBeforeElement(list, node);

/* #540296 tidy dumps with empty definition list */
#if 0
                DiscardElement(list);
#endif
            }

            /* #426885 - fix by Glenn Carroll 19 Apr 00, and
                         Gary Dechaines 11 Aug 00 */
            /* ParseTag can destroy node, if it finds that
             * this <center> is followed immediately by </center>.
             * It's awkward but necessary to determine if this
             * has happened.
             */
            parent = node->parent;

            /* and parse contents of center */
            lexer->excludeBlocks = no;
            ParseTag( doc, node, mode);
            lexer->excludeBlocks = yes;

            /* now create a new dl element,
             * unless node has been blown away because the
             * center was empty, as above.
             */
            if (parent->last == node)
            {
                list = InferredTag( doc, "dl");
                InsertNodeAfterElement(node, list);
            }
            continue;
        }

        if ( !(nodeIsDT(node) || nodeIsDD(node)) )
        {
            UngetToken( doc );

            if (!(node->tag->model & (CM_BLOCK | CM_INLINE)))
            {
                ReportWarning( doc, list, node, TAG_NOT_ALLOWED_IN);
                TrimEmptyElement( doc, list);
                return;
            }

            /* if DD appeared directly in BODY then exclude blocks */
            if (!(node->tag->model & CM_INLINE) && lexer->excludeBlocks)
            {
                TrimEmptyElement( doc, list);
                return;
            }

            node = InferredTag( doc, "dd");
            ReportWarning( doc, list, node, MISSING_STARTTAG);
        }

        if (node->type == EndTag)
        {
            ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }
        
        /* node should be <DT> or <DD>*/
        InsertNodeAtEnd(list, node);
        ParseTag( doc, node, IgnoreWhitespace);
    }

    ReportWarning( doc, list, node, MISSING_ENDTAG_FOR);
    TrimEmptyElement( doc, list);
}

void ParseList(TidyDocImpl* doc, Node *list, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node, *parent;

    if (list->tag->model & CM_EMPTY)
        return;

    lexer->insert = null;  /* defer implicit inline start tags */

    while ((node = GetToken( doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == list->tag && node->type == EndTag)
        {
            FreeNode( doc, node);

            if (list->tag->model & CM_OBSOLETE)
                CoerceNode( doc, list, TidyTag_UL );

            list->closed = yes;
            TrimEmptyElement( doc, list);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(list, node))
            continue;

        if (node->type != TextNode && node->tag == null)
        {
            ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* 
          if this is the end tag for an ancestor element
          then infer end tag for this element
        */
        if (node->type == EndTag)
        {
            if ( nodeIsFORM(node) )
            {
                BadForm( doc );
                ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
                continue;
            }

            if (node->tag && node->tag->model & CM_INLINE)
            {
                ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
                PopInline( doc, node );
                FreeNode( doc, node);
                continue;
            }

            for (parent = list->parent;
                    parent != null; parent = parent->parent)
            {
                if (node->tag == parent->tag)
                {
                    ReportWarning( doc, list, node, MISSING_ENDTAG_BEFORE);
                    UngetToken( doc );

                    if (list->tag->model & CM_OBSOLETE)
                        CoerceNode( doc, list, TidyTag_UL );

                    TrimEmptyElement( doc, list);
                    return;
                }
            }

            ReportWarning( doc, list, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        if ( !nodeIsLI(node) )
        {
            UngetToken( doc );

            if (node->tag && (node->tag->model & CM_BLOCK) && lexer->excludeBlocks)
            {
                ReportWarning( doc, list, node, MISSING_ENDTAG_BEFORE);
                TrimEmptyElement( doc, list);
                return;
            }

            node = InferredTag( doc, "li" );
            AddAttribute( doc, node, "style", "list-style: none" );
            ReportWarning( doc, list, node, MISSING_STARTTAG );
        }

        /* node should be <LI> */
        InsertNodeAtEnd(list,node);
        ParseTag( doc, node, IgnoreWhitespace);
    }

    if (list->tag->model & CM_OBSOLETE)
        CoerceNode( doc, list, TidyTag_UL );

    ReportWarning( doc, list, node, MISSING_ENDTAG_FOR);
    TrimEmptyElement( doc, list);
}

/*
 unexpected content in table row is moved to just before
 the table in accordance with Netscape and IE. This code
 assumes that node hasn't been inserted into the row.
*/
static void MoveBeforeTable( TidyDocImpl* doc, Node *row, Node *node )
{
    Node *table;

    /* first find the table element */
    for (table = row->parent; table; table = table->parent)
    {
        if ( nodeIsTABLE(table) )
        {
            if (table->parent->content == table)
                table->parent->content = node;

            node->prev = table->prev;
            node->next = table;
            table->prev = node;
            node->parent = table->parent;
        
            if (node->prev)
                node->prev->next = node;

            break;
        }
    }
}

/*
 if a table row is empty then insert an empty cell
 this practice is consistent with browser behavior
 and avoids potential problems with row spanning cells
*/
static void FixEmptyRow(TidyDocImpl* doc, Node *row)
{
    Node *cell;

    if (row->content == null)
    {
        cell = InferredTag( doc, "td");
        InsertNodeAtEnd(row, cell);
        ReportWarning( doc, row, cell, MISSING_STARTTAG);
    }
}

void ParseRow(TidyDocImpl* doc, Node *row, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;
    Bool exclude_state;

    if (row->tag->model & CM_EMPTY)
        return;

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == row->tag)
        {
            if (node->type == EndTag)
            {
                FreeNode( doc, node);
                row->closed = yes;
                FixEmptyRow( doc, row);
                return;
            }

            /* New row start implies end of current row */
            UngetToken( doc );
            FixEmptyRow( doc, row);
            return;
        }

        /* 
          if this is the end tag for an ancestor element
          then infer end tag for this element
        */
        if ( node->type == EndTag )
        {
            if ( DescendantOf(row, TagId(node)) )
            {
                UngetToken( doc );
                TrimEmptyElement( doc, row);
                return;
            }

            if ( nodeIsFORM(node) || nodeHasCM(node, CM_BLOCK|CM_INLINE) )
            {
                if ( nodeIsFORM(node) )
                    BadForm( doc );

                ReportWarning( doc, row, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            if ( nodeIsTD(node) || nodeIsTH(node) )
            {
                ReportWarning( doc, row, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }
        }

        /* deal with comments etc. */
        if (InsertMisc(row, node))
            continue;

        /* discard unknown tags */
        if (node->tag == null && node->type != TextNode)
        {
            ReportWarning( doc, row, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* discard unexpected <table> element */
        if ( nodeIsTABLE(node) )
        {
            ReportWarning( doc, row, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* THEAD, TFOOT or TBODY */
        if ( nodeHasCM(node, CM_ROWGRP) )
        {
            UngetToken( doc );
            TrimEmptyElement( doc, row);
            return;
        }

        if (node->type == EndTag)
        {
            ReportWarning( doc, row, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /*
          if text or inline or block move before table
          if head content move to head
        */

        if (node->type != EndTag)
        {
            if ( nodeIsFORM(node) )
            {
                UngetToken( doc );
                node = InferredTag( doc, "td");
                ReportWarning( doc, row, node, MISSING_STARTTAG);
            }
            else if ( nodeIsText(node)
                      || nodeHasCM(node, CM_BLOCK | CM_INLINE) )
            {
                MoveBeforeTable( doc, row, node );
                ReportWarning( doc, row, node, TAG_NOT_ALLOWED_IN);
                lexer->exiled = yes;

                if (node->type != TextNode)
                    ParseTag( doc, node, IgnoreWhitespace);

                lexer->exiled = no;
                continue;
            }
            else if (node->tag->model & CM_HEAD)
            {
                ReportWarning( doc, row, node, TAG_NOT_ALLOWED_IN);
                MoveToHead( doc, row, node);
                continue;
            }
        }

        if ( !(nodeIsTD(node) || nodeIsTH(node)) )
        {
            ReportWarning( doc, row, node, TAG_NOT_ALLOWED_IN);
            FreeNode( doc, node);
            continue;
        }
        
        /* node should be <TD> or <TH> */
        InsertNodeAtEnd(row, node);
        exclude_state = lexer->excludeBlocks;
        lexer->excludeBlocks = no;
        ParseTag( doc, node, IgnoreWhitespace);
        lexer->excludeBlocks = exclude_state;

        /* pop inline stack */

        while ( lexer->istacksize > lexer->istackbase )
            PopInline( doc, null );
    }

    TrimEmptyElement( doc, row);
}

void ParseRowGroup(TidyDocImpl* doc, Node *rowgroup, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node, *parent;

    if (rowgroup->tag->model & CM_EMPTY)
        return;

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == rowgroup->tag)
        {
            if (node->type == EndTag)
            {
                rowgroup->closed = yes;
                TrimEmptyElement(doc, rowgroup);
                FreeNode( doc, node);
                return;
            }

            UngetToken( doc );
            return;
        }

        /* if </table> infer end tag */
        if ( nodeIsTABLE(node) && node->type == EndTag )
        {
            UngetToken( doc );
            TrimEmptyElement(doc, rowgroup);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(rowgroup, node))
            continue;

        /* discard unknown tags */
        if (node->tag == null && node->type != TextNode)
        {
            ReportWarning( doc, rowgroup, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /*
          if TD or TH then infer <TR>
          if text or inline or block move before table
          if head content move to head
        */

        if (node->type != EndTag)
        {
            if ( nodeIsTD(node) || nodeIsTH(node) )
            {
                UngetToken( doc );
                node = InferredTag(doc, "tr");
                ReportWarning( doc, rowgroup, node, MISSING_STARTTAG);
            }
            else if ( nodeIsText(node)
                      || nodeHasCM(node, CM_BLOCK|CM_INLINE) )
            {
                MoveBeforeTable( doc, rowgroup, node );
                ReportWarning( doc, rowgroup, node, TAG_NOT_ALLOWED_IN);
                lexer->exiled = yes;

                if (node->type != TextNode)
                    ParseTag(doc, node, IgnoreWhitespace);

                lexer->exiled = no;
                continue;
            }
            else if (node->tag->model & CM_HEAD)
            {
                ReportWarning( doc, rowgroup, node, TAG_NOT_ALLOWED_IN);
                MoveToHead(doc, rowgroup, node);
                continue;
            }
        }

        /* 
          if this is the end tag for ancestor element
          then infer end tag for this element
        */
        if (node->type == EndTag)
        {
            if ( nodeIsFORM(node) || nodeHasCM(node, CM_BLOCK|CM_INLINE) )
            {
                if ( nodeIsFORM(node) )
                    BadForm( doc );

                ReportWarning( doc, rowgroup, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            if ( nodeIsTR(node) || nodeIsTD(node) || nodeIsTH(node) )
            {
                ReportWarning( doc, rowgroup, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            for ( parent = rowgroup->parent;
                  parent != null;
                  parent = parent->parent )
            {
                if (node->tag == parent->tag)
                {
                    UngetToken( doc );
                    TrimEmptyElement(doc, rowgroup);
                    return;
                }
            }
        }

        /*
          if THEAD, TFOOT or TBODY then implied end tag

        */
        if (node->tag->model & CM_ROWGRP)
        {
            if (node->type != EndTag)
                UngetToken( doc );

            TrimEmptyElement(doc, rowgroup);
            return;
        }

        if (node->type == EndTag)
        {
            ReportWarning( doc, rowgroup, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }
        
        if ( !nodeIsTR(node) )
        {
            node = InferredTag(doc, "tr");
            ReportWarning( doc, rowgroup, node, MISSING_STARTTAG);
            UngetToken( doc );
        }

       /* node should be <TR> */
        InsertNodeAtEnd(rowgroup, node);
        ParseTag(doc, node, IgnoreWhitespace);
    }

    TrimEmptyElement(doc, rowgroup);
}

void ParseColGroup(TidyDocImpl* doc, Node *colgroup, uint mode)
{
    Node *node, *parent;

    if (colgroup->tag->model & CM_EMPTY)
        return;

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == colgroup->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            colgroup->closed = yes;
            return;
        }

        /* 
          if this is the end tag for an ancestor element
          then infer end tag for this element
        */
        if (node->type == EndTag)
        {
            if ( nodeIsFORM(node) )
            {
                BadForm( doc );
                ReportWarning( doc, colgroup, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            for ( parent = colgroup->parent;
                  parent != null;
                  parent = parent->parent )
            {
                if (node->tag == parent->tag)
                {
                    UngetToken( doc );
                    return;
                }
            }
        }

        if (node->type == TextNode)
        {
            UngetToken( doc );
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(colgroup, node))
            continue;

        /* discard unknown tags */
        if (node->tag == null)
        {
            ReportWarning( doc, colgroup, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        if ( !nodeIsCOL(node) )
        {
            UngetToken( doc );
            return;
        }

        if (node->type == EndTag)
        {
            ReportWarning( doc, colgroup, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }
        
        /* node should be <COL> */
        InsertNodeAtEnd(colgroup, node);
        ParseTag(doc, node, IgnoreWhitespace);
    }
}

void ParseTableTag(TidyDocImpl* doc, Node *table, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node, *parent;
    uint istackbase;

    DeferDup( doc );
    istackbase = lexer->istackbase;
    lexer->istackbase = lexer->istacksize;
    
    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == table->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            lexer->istackbase = istackbase;
            table->closed = yes;
            TrimEmptyElement(doc, table);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(table, node))
            continue;

        /* discard unknown tags */
        if (node->tag == null && node->type != TextNode)
        {
            ReportWarning( doc, table, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* if TD or TH or text or inline or block then infer <TR> */

        if (node->type != EndTag)
        {
            if ( nodeIsTD(node) || nodeIsTH(node) || nodeIsTABLE(node) )
            {
                UngetToken( doc );
                node = InferredTag(doc, "tr");
                ReportWarning( doc, table, node, MISSING_STARTTAG);
            }
            else if ( nodeIsText(node) ||nodeHasCM(node,CM_BLOCK|CM_INLINE) )
            {
                InsertNodeBeforeElement(table, node);
                ReportWarning( doc, table, node, TAG_NOT_ALLOWED_IN);
                lexer->exiled = yes;

                if (node->type != TextNode) 
                    ParseTag(doc, node, IgnoreWhitespace);

                lexer->exiled = no;
                continue;
            }
            else if (node->tag->model & CM_HEAD)
            {
                MoveToHead(doc, table, node);
                continue;
            }
        }

        /* 
          if this is the end tag for an ancestor element
          then infer end tag for this element
        */
        if (node->type == EndTag)
        {
            if ( nodeIsFORM(node) )
            {
                BadForm( doc );
                ReportWarning( doc, table, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            /* best to discard unexpected block/inline end tags */
            if ( nodeHasCM(node, CM_TABLE|CM_ROW) ||
                 nodeHasCM(node, CM_BLOCK|CM_INLINE) )
            {
                ReportWarning( doc, table, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            for ( parent = table->parent;
                  parent != null;
                  parent = parent->parent )
            {
                if (node->tag == parent->tag)
                {
                    ReportWarning( doc, table, node, MISSING_ENDTAG_BEFORE );
                    UngetToken( doc );
                    lexer->istackbase = istackbase;
                    TrimEmptyElement(doc, table);
                    return;
                }
            }
        }

        if (!(node->tag->model & CM_TABLE))
        {
            UngetToken( doc );
            ReportWarning( doc, table, node, TAG_NOT_ALLOWED_IN);
            lexer->istackbase = istackbase;
            TrimEmptyElement(doc, table);
            return;
        }

        if (node->type == StartTag || node->type == StartEndTag)
        {
            InsertNodeAtEnd(table, node);
            ParseTag(doc, node, IgnoreWhitespace);
            continue;
        }

        /* discard unexpected text nodes and end tags */
        ReportWarning( doc, table, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }

    ReportWarning( doc, table, node, MISSING_ENDTAG_FOR);
    TrimEmptyElement(doc, table);
    lexer->istackbase = istackbase;
}

/* acceptable content for pre elements */
Bool PreContent( TidyDocImpl* doc, Node* node )
{
    /* p is coerced to br's, Text OK too */
    if ( nodeIsP(node) || nodeIsText(node) )
        return yes;

    if ( node->tag == null ||
         nodeIsPARAM(node) ||
         !nodeHasCM(node, CM_INLINE|CM_NEW) )
        return no;

    return yes;
}

void ParsePre( TidyDocImpl* doc, Node *pre, uint mode )
{
    Lexer* lexer = doc->lexer;
    Node *node;

    if (pre->tag->model & CM_EMPTY)
        return;

    if (pre->tag->model & CM_OBSOLETE)
        CoerceNode( doc, pre, TidyTag_PRE );

    InlineDup( doc, null ); /* tell lexer to insert inlines if needed */

    while ((node = GetToken(doc, Preformatted)) != null)
    {
        if ( node->type == EndTag && 
             (node->tag == pre->tag || DescendantOf(pre, TagId(node))) )
        {
            if ( node->tag == pre->tag )
              FreeNode( doc, node);
            else
            {
              ReportWarning( doc, pre, node, MISSING_ENDTAG_BEFORE );
              UngetToken( doc );
            }
            TrimSpaces(doc, pre);
            pre->closed = yes;
            TrimEmptyElement(doc, pre);
            return;
        }

        if (node->type == TextNode)
        {
            /* if first check for inital newline */
            if (pre->content == null)
            {
                if ( lexer->lexbuf[node->start] == '\n' )
                    ++(node->start);

                if (node->start >= node->end)
                {
                    FreeNode( doc, node);
                    continue;
                }
            }

            InsertNodeAtEnd(pre, node);
            continue;
        }

        /* deal with comments etc. */
        if (InsertMisc(pre, node))
            continue;

        /* strip unexpected tags */
        if ( !PreContent(doc, node) )
        {
            Node *newnode;
            ReportWarning( doc, pre, node, UNESCAPED_ELEMENT );
            newnode = EscapeTag( lexer, node );
            FreeNode( doc, node );
            InsertNodeAtEnd(pre, newnode);
            continue;
        }

        if ( nodeIsP(node) )
        {
            if (node->type == StartTag)
            {
                ReportWarning( doc, pre, node, USING_BR_INPLACE_OF);

                /* trim white space before <p> in <pre>*/
                TrimSpaces(doc, pre);
            
                /* coerce both <p> and </p> to <br> */
                CoerceNode( doc, node, TidyTag_BR );
                FreeAttrs( doc, node ); /* discard align attribute etc. */
                InsertNodeAtEnd( pre, node );
            }
            else
            {
                ReportWarning( doc, pre, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
            }
            continue;
        }

        if ( node->type == StartTag || node->type == StartEndTag )
        {
            /* trim white space before <br> */
            if ( nodeIsBR(node) )
                TrimSpaces(doc, pre);
            
            InsertNodeAtEnd(pre, node);
            ParseTag(doc, node, Preformatted);
            continue;
        }

        /* discard unexpected tags */
        ReportWarning( doc, pre, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }

    ReportWarning( doc, pre, node, MISSING_ENDTAG_FOR);
    TrimEmptyElement(doc, pre);
}

void ParseOptGroup(TidyDocImpl* doc, Node *field, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;

    lexer->insert = null;  /* defer implicit inline start tags */

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == field->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            field->closed = yes;
            TrimSpaces(doc, field);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(field, node))
            continue;

        if ( node->type == StartTag && 
             (nodeIsOPTION(node) || nodeIsOPTGROUP(node)) )
        {
            if ( nodeIsOPTGROUP(node) )
                ReportWarning( doc, field, node, CANT_BE_NESTED);

            InsertNodeAtEnd(field, node);
            ParseTag(doc, node, MixedContent);
            continue;
        }

        /* discard unexpected tags */
        ReportWarning( doc, field, node, DISCARDING_UNEXPECTED );
        FreeNode( doc, node);
    }
}


void ParseSelect(TidyDocImpl* doc, Node *field, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;

    lexer->insert = null;  /* defer implicit inline start tags */

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == field->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            field->closed = yes;
            TrimSpaces(doc, field);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(field, node))
            continue;

        if ( node->type == StartTag && 
             ( nodeIsOPTION(node)   ||
               nodeIsOPTGROUP(node) ||
               nodeIsSCRIPT(node)) 
           )
        {
            InsertNodeAtEnd(field, node);
            ParseTag(doc, node, IgnoreWhitespace);
            continue;
        }

        /* discard unexpected tags */
        ReportWarning( doc, field, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }

    ReportWarning( doc, field, node, MISSING_ENDTAG_FOR);
}

void ParseText(TidyDocImpl* doc, Node *field, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;

    lexer->insert = null;  /* defer implicit inline start tags */

    if ( nodeIsTEXTAREA(field) )
        mode = Preformatted;
    else
        mode = MixedContent;  /* kludge for font tags */

    while ((node = GetToken(doc, mode)) != null)
    {
        if (node->tag == field->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            field->closed = yes;
            TrimSpaces(doc, field);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(field, node))
            continue;

        if (node->type == TextNode)
        {
            /* only called for 1st child */
            if (field->content == null && !(mode & Preformatted))
                TrimSpaces(doc, field);

            if (node->start >= node->end)
            {
                FreeNode( doc, node);
                continue;
            }

            InsertNodeAtEnd(field, node);
            continue;
        }

        /* for textarea should all cases of < and & be escaped? */

        /* discard inline tags e.g. font */
        if (   node->tag 
            && node->tag->model & CM_INLINE
            && !(node->tag->model & CM_FIELD)) /* #487283 - fix by Lee Passey 25 Jan 02 */
        {
            ReportWarning( doc, field, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* terminate element on other tags */
        if (!(field->tag->model & CM_OPT))
            ReportWarning( doc, field, node, MISSING_ENDTAG_BEFORE);

        UngetToken( doc );
        TrimSpaces(doc, field);
        return;
    }

    if (!(field->tag->model & CM_OPT))
        ReportWarning( doc, field, node, MISSING_ENDTAG_FOR);
}


void ParseTitle(TidyDocImpl* doc, Node *title, uint mode)
{
    Node *node;
    while ((node = GetToken(doc, MixedContent)) != null)
    {
        if (node->tag == title->tag && node->type == StartTag)
        {
            ReportWarning( doc, title, node, COERCE_TO_ENDTAG);
            node->type = EndTag;
            UngetToken( doc );
            continue;
        }
        else if (node->tag == title->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            title->closed = yes;
            TrimSpaces(doc, title);
            return;
        }

        if (node->type == TextNode)
        {
            /* only called for 1st child */
            if (title->content == null)
                TrimInitialSpace(doc, title, node);

            if (node->start >= node->end)
            {
                FreeNode( doc, node);
                continue;
            }

            InsertNodeAtEnd(title, node);
            continue;
        }

        /* deal with comments etc. */
        if (InsertMisc(title, node))
            continue;

        /* discard unknown tags */
        if (node->tag == null)
        {
            ReportWarning( doc, title, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* pushback unexpected tokens */
        ReportWarning( doc, title, node, MISSING_ENDTAG_BEFORE);
        UngetToken( doc );
        TrimSpaces(doc, title);
        return;
    }

    ReportWarning( doc, title, node, MISSING_ENDTAG_FOR);
}

/*
  This isn't quite right for CDATA content as it recognises
  tags within the content and parses them accordingly.
  This will unfortunately screw up scripts which include
  < + letter,  < + !, < + ?  or  < + / + letter
*/

void ParseScript(TidyDocImpl* doc, Node *script, uint mode)
{
    Node *node = GetCDATA(doc, script);
    if ( node )
        InsertNodeAtEnd(script, node);
}

Bool IsJavaScript(Node *node)
{
    Bool result = no;
    AttVal *attr;

    if (node->attributes == null)
        return yes;

    for (attr = node->attributes; attr; attr = attr->next)
    {
        if ( (tmbstrcasecmp(attr->attribute, "language") == 0
                || tmbstrcasecmp(attr->attribute, "type") == 0)
                && tmbsubstr(attr->value, "javascript"))
            result = yes;
    }

    return result;
}

void ParseHead(TidyDocImpl* doc, Node *head, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;
    int HasTitle = 0;
    int HasBase = 0;

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == head->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            head->closed = yes;
            break;
        }

        if (node->type == TextNode)
        {
            ReportWarning( doc, head, node, TAG_NOT_ALLOWED_IN);
            UngetToken( doc );
            break;
        }

        /* deal with comments etc. */
        if (InsertMisc(head, node))
            continue;

        if (node->type == DocTypeTag)
        {
            InsertDocType(doc, head, node);
            continue;
        }

        /* discard unknown tags */
        if (node->tag == null)
        {
            ReportWarning( doc, head, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }
        
        /*
         if it doesn't belong in the head then
         treat as implicit head of head and deal
         with as part of the body
        */
        if (!(node->tag->model & CM_HEAD))
        {
            /* #545067 Implicit closing of head broken - warn only for XHTML input */
            if ( lexer->isvoyager )
                ReportWarning( doc, head, node, TAG_NOT_ALLOWED_IN );
            UngetToken( doc );
            break;
        }

        if (node->type == StartTag || node->type == StartEndTag)
        {
            if ( nodeIsTITLE(node) )
            {
                ++HasTitle;

                if (HasTitle > 1)
                    ReportWarning( doc, head, node, TOO_MANY_ELEMENTS);
            }
            else if ( nodeIsBASE(node) )
            {
                ++HasBase;

                if (HasBase > 1)
                    ReportWarning( doc, head, node, TOO_MANY_ELEMENTS);
            }
            else if ( nodeIsNOSCRIPT(node) )
                ReportWarning( doc, head, node, TAG_NOT_ALLOWED_IN);

            InsertNodeAtEnd(head, node);
            ParseTag(doc, node, IgnoreWhitespace);
            continue;
        }

        /* discard unexpected text nodes and end tags */
        ReportWarning( doc, head, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }
  
    if ( HasTitle == 0 )
    {
        if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
        {
            if ( !cfgBool(doc, TidyBodyOnly) )
                ReportWarning( doc, head, null, MISSING_TITLE_ELEMENT);
 
            InsertNodeAtEnd(head, InferredTag(doc, "title"));
        }
    }
}

void ParseBody(TidyDocImpl* doc, Node *body, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;
    Bool checkstack, iswhitenode;

    mode = IgnoreWhitespace;
    checkstack = yes;

    BumpObject( doc, body->parent );

    while ((node = GetToken(doc, mode)) != null)
    {
        /* #538536 Extra endtags not detected */
        if ( nodeIsHTML(node) )
        {
            if (node->type == StartTag || node->type == StartEndTag || lexer->seenEndHtml) 
                ReportWarning( doc, body, node, DISCARDING_UNEXPECTED);
            else
                lexer->seenEndHtml = 1;

            FreeNode( doc, node);
            continue;
        }

        if ( lexer->seenEndBody && 
             ( node->type == StartTag ||
               node->type == EndTag   ||
               node->type == StartEndTag ) )
        {
            ReportWarning( doc, body, node, CONTENT_AFTER_BODY );
        }

        if ( node->tag == body->tag && node->type == EndTag )
        {
            body->closed = yes;
            TrimSpaces(doc, body);
            FreeNode( doc, node);
            lexer->seenEndBody = 1;
            mode = IgnoreWhitespace;

            if ( nodeIsNOFRAMES(body->parent) )
                break;

            continue;
        }

        if ( nodeIsNOFRAMES(node) )
        {
            if (node->type == StartTag)
            {
                InsertNodeAtEnd(body, node);
                ParseBlock(doc, node, mode);
                continue;
            }

            if (node->type == EndTag && nodeIsNOFRAMES(body->parent) )
            {
                TrimSpaces(doc, body);
                UngetToken( doc );
                break;
            }
        }

        if ( (nodeIsFRAME(node) || nodeIsFRAMESET(node))
             && nodeIsNOFRAMES(body->parent) )
        {
            TrimSpaces(doc, body);
            UngetToken( doc );
            break;
        }
        
        iswhitenode = no;

        if ( node->type == TextNode &&
             node->end <= node->start + 1 &&
             lexer->lexbuf[node->start] == ' ' )
            iswhitenode = yes;

        /* deal with comments etc. */
        if (InsertMisc(body, node))
            continue;

        /* #538536 Extra endtags not detected */
#if 0
        if ( lexer->seenEndBody == 1 && !iswhitenode )
        {
            ++lexer->seenEndBody;
            ReportWarning( doc, body, node, CONTENT_AFTER_BODY);
        }
#endif

        /* mixed content model permits text */
        if (node->type == TextNode)
        {
            if (iswhitenode && mode == IgnoreWhitespace)
            {
                FreeNode( doc, node);
                continue;
            }

            if ( cfgBool(doc, TidyEncloseBodyText) && !iswhitenode )
            {
                Node *para;
                
                UngetToken( doc );
                para = InferredTag(doc, "p");
                InsertNodeAtEnd(body, para);
                ParseTag(doc, para, mode);
                mode = MixedContent;
                continue;
            }
            else /* HTML 2 and HTML4 strict don't allow text here */
                ConstrainVersion(doc, ~(VERS_HTML40_STRICT | VERS_HTML20));


            if (checkstack)
            {
                checkstack = no;

                if ( InlineDup(doc, node) > 0 )
                    continue;
            }

            InsertNodeAtEnd(body, node);
            mode = MixedContent;
            continue;
        }

        if (node->type == DocTypeTag)
        {
            InsertDocType(doc, body, node);
            continue;
        }
        /* discard unknown  and PARAM tags */
        if ( node->tag == null || nodeIsPARAM(node) )
        {
            ReportWarning( doc, body, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /*
          Netscape allows LI and DD directly in BODY
          We infer UL or DL respectively and use this
          Bool to exclude block-level elements so as
          to match Netscape's observed behaviour.
        */
        lexer->excludeBlocks = no;
        
        if ( nodeIsINPUT(node) ||
             (!nodeHasCM(node, CM_BLOCK) && !nodeHasCM(node, CM_INLINE))
           )
        {
            /* avoid this error message being issued twice */
            if (!(node->tag->model & CM_HEAD))
                ReportWarning( doc, body, node, TAG_NOT_ALLOWED_IN);

            if (node->tag->model & CM_HTML)
            {
                /* copy body attributes if current body was inferred */
                if ( nodeIsBODY(node) && body->implicit 
                     && body->attributes == null )
                {
                    body->attributes = node->attributes;
                    node->attributes = null;
                }

                FreeNode( doc, node);
                continue;
            }

            if (node->tag->model & CM_HEAD)
            {
                MoveToHead(doc, body, node);
                continue;
            }

            if (node->tag->model & CM_LIST)
            {
                UngetToken( doc );
                node = InferredTag(doc, "ul");
                AddClass( doc, node, "noindent" );
                lexer->excludeBlocks = yes;
            }
            else if (node->tag->model & CM_DEFLIST)
            {
                UngetToken( doc );
                node = InferredTag(doc, "dl");
                lexer->excludeBlocks = yes;
            }
            else if (node->tag->model & (CM_TABLE | CM_ROWGRP | CM_ROW))
            {
                UngetToken( doc );
                node = InferredTag(doc, "table");
                lexer->excludeBlocks = yes;
            }
            else if ( nodeIsINPUT(node) )
            {
                UngetToken( doc );
                node = InferredTag(doc, "form");
                lexer->excludeBlocks = yes;
            }
            else
            {
                if (!(node->tag->model & (CM_ROW | CM_FIELD)))
                {
                    UngetToken( doc );
                    return;
                }

                /* ignore </td> </th> <option> etc. */
                continue;
            }
        }

        if (node->type == EndTag)
        {
            if ( nodeIsBR(node) )
                node->type = StartTag;
            else if ( nodeIsP(node) )
            {
                CoerceNode( doc, node, TidyTag_BR );
                FreeAttrs( doc, node ); /* discard align attribute etc. */
                InsertNodeAtEnd(body, node);
                node = InferredTag(doc, "br");
            }
            else if (node->tag->model & CM_INLINE)
                PopInline( doc, node );
        }

        if (node->type == StartTag || node->type == StartEndTag)
        {
            if ((node->tag->model & CM_INLINE) && !(node->tag->model & CM_MIXED))
            {
                /* HTML4 strict doesn't allow inline content here */
                /* but HTML2 does allow img elements as children of body */
                if ( nodeIsIMG(node) )
                    ConstrainVersion(doc, ~VERS_HTML40_STRICT);
                else
                    ConstrainVersion(doc, ~(VERS_HTML40_STRICT|VERS_HTML20));

                if (checkstack && !node->implicit)
                {
                    checkstack = no;

                    if ( InlineDup(doc, node) > 0 )
                        continue;
                }

                mode = MixedContent;
            }
            else
            {
                checkstack = yes;
                mode = IgnoreWhitespace;
            }

            if (node->implicit)
                ReportWarning( doc, body, node, INSERTING_TAG);

            InsertNodeAtEnd(body, node);
            ParseTag(doc, node, mode);
            continue;
        }

        /* discard unexpected tags */
        ReportWarning( doc, body, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }
}

void ParseNoFrames(TidyDocImpl* doc, Node *noframes, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;
    Bool checkstack;

    if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
    {
        doc->badAccess |=  USING_NOFRAMES;
    }
    mode = IgnoreWhitespace;
    checkstack = yes;

    while ( (node = GetToken(doc, mode)) != null )
    {
        if ( node->tag == noframes->tag && node->type == EndTag )
        {
            FreeNode( doc, node);
            noframes->closed = yes;
            TrimSpaces(doc, noframes);
            return;
        }

        if ( nodeIsFRAME(node) || nodeIsFRAMESET(node) )
        {
            TrimSpaces(doc, noframes);
            if (node->type == EndTag)
            {
                ReportWarning( doc, noframes, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);       /* Throw it away */
            }
            else
            {
                ReportWarning( doc, noframes, node, MISSING_ENDTAG_BEFORE);
                UngetToken( doc );
            }
            return;
        }

        if ( nodeIsHTML(node) )
        {
            if (node->type == StartTag || node->type == StartEndTag)
                ReportWarning( doc, noframes, node, DISCARDING_UNEXPECTED);

            FreeNode( doc, node);
            continue;
        }

        /* deal with comments etc. */
        if (InsertMisc(noframes, node))
            continue;

        if ( nodeIsBODY(node) && node->type == StartTag )
        {
            Bool seen_body = lexer->seenEndBody;
            InsertNodeAtEnd(noframes, node);
            ParseTag(doc, node, IgnoreWhitespace /*MixedContent*/);

            if (seen_body)
            {
                CoerceNode(doc, node, TidyTag_DIV );
                MoveNodeToBody(doc, node);
            }
            continue;
        }

        /* implicit body element inferred */
        if (node->type == TextNode || (node->tag && node->type != EndTag))
        {
            if ( lexer->seenEndBody )
            {
                Node *body = FindBody( doc );
                if ( node->type == TextNode )
                {
                    UngetToken( doc );
                    node = InferredTag( doc, "p" );
                    ReportWarning( doc, noframes, node, CONTENT_AFTER_BODY );
                }
                InsertNodeAtEnd( body, node );
            }
            else
            {
                UngetToken( doc );
                node = InferredTag( doc, "body" );
                if ( cfgBool(doc, TidyXmlOut) )
                    ReportWarning( doc, noframes, node, INSERTING_TAG);
                InsertNodeAtEnd( noframes, node );
            }

            ParseTag( doc, node, IgnoreWhitespace /*MixedContent*/ );
            continue;
        }

        /* discard unexpected end tags */
        ReportWarning( doc, noframes, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }

    ReportWarning( doc, noframes, node, MISSING_ENDTAG_FOR);
}

void ParseFrameSet(TidyDocImpl* doc, Node *frameset, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;

    if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
    {
        doc->badAccess |=  USING_FRAMES;
    }
    
    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        if (node->tag == frameset->tag && node->type == EndTag)
        {
            FreeNode( doc, node);
            frameset->closed = yes;
            TrimSpaces(doc, frameset);
            return;
        }

        /* deal with comments etc. */
        if (InsertMisc(frameset, node))
            continue;

        if (node->tag == null)
        {
            ReportWarning( doc, frameset, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue; 
        }

        if (node->type == StartTag || node->type == StartEndTag)
        {
            if (node->tag && node->tag->model & CM_HEAD)
            {
                MoveToHead(doc, frameset, node);
                continue;
            }
        }

        if ( nodeIsBODY(node) )
        {
            UngetToken( doc );
            node = InferredTag(doc, "noframes");
            ReportWarning( doc, frameset, node, INSERTING_TAG);
        }

        if (node->type == StartTag && (node->tag->model & CM_FRAMES))
        {
            InsertNodeAtEnd(frameset, node);
            lexer->excludeBlocks = no;
            ParseTag(doc, node, MixedContent);
            continue;
        }
        else if (node->type == StartEndTag && (node->tag->model & CM_FRAMES))
        {
            InsertNodeAtEnd(frameset, node);
            continue;
        }

        /* discard unexpected tags */
        ReportWarning( doc, frameset, node, DISCARDING_UNEXPECTED);
        FreeNode( doc, node);
    }

    ReportWarning( doc, frameset, node, MISSING_ENDTAG_FOR);
}

void ParseHTML(TidyDocImpl* doc, Node *html, uint mode)
{
    Node *node, *head;
    Node *frameset = null;
    Node *noframes = null;

    SetOptionBool( doc, TidyXmlTags, no );

    for (;;)
    {
        node = GetToken(doc, IgnoreWhitespace);

        if (node == null)
        {
            node = InferredTag(doc, "head");
            break;
        }

        if ( nodeIsHEAD(node) )
            break;

        if (node->tag == html->tag && node->type == EndTag)
        {
            ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        /* deal with comments etc. */
        if (InsertMisc(html, node))
            continue;

        UngetToken( doc );
        node = InferredTag(doc, "head");
        break;
    }

    head = node;
    InsertNodeAtEnd(html, head);
    ParseHead(doc, head, mode);

    for (;;)
    {
        node = GetToken(doc, IgnoreWhitespace);

        if (node == null)
        {
            if (frameset == null) /* implied body */
            {
                node = InferredTag(doc, "body");
                InsertNodeAtEnd(html, node);
                ParseBody(doc, node, mode);
            }

            return;
        }

        /* robustly handle html tags */
        if (node->tag == html->tag)
        {
            if (node->type != StartTag && frameset == null)
                ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);

            FreeNode( doc, node);
            continue;
        }

        /* deal with comments etc. */
        if (InsertMisc(html, node))
            continue;

        /* if frameset document coerce <body> to <noframes> */
        if ( nodeIsBODY(node) )
        {
            if (node->type != StartTag)
            {
                ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            if ( cfg(doc, TidyAccessibilityCheckLevel) == 0 )
            {
                if (frameset != null)
                {
                    UngetToken( doc );

                    if (noframes == null)
                    {
                        noframes = InferredTag(doc, "noframes");
                        InsertNodeAtEnd(frameset, noframes);
                        ReportWarning( doc, html, noframes, INSERTING_TAG);
                    }

                    ParseTag(doc, noframes, mode);
                    continue;
                }
            }

            ConstrainVersion(doc, ~VERS_FRAMESET);
            break;  /* to parse body */
        }

        /* flag an error if we see more than one frameset */
        if ( nodeIsFRAMESET(node) )
        {
            if (node->type != StartTag)
            {
                ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            if (frameset != null)
                ReportError(doc, html, node, DUPLICATE_FRAMESET);
            else
                frameset = node;

            InsertNodeAtEnd(html, node);
            ParseTag(doc, node, mode);

            /*
              see if it includes a noframes element so
              that we can merge subsequent noframes elements
            */

            for (node = frameset->content; node; node = node->next)
            {
                if ( nodeIsNOFRAMES(node) )
                    noframes = node;
            }
            continue;
        }

        /* if not a frameset document coerce <noframes> to <body> */
        if ( nodeIsNOFRAMES(node) )
        {
            if (node->type != StartTag)
            {
                ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                continue;
            }

            if (frameset == null)
            {
                ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
                node = InferredTag(doc, "body");
                break;
            }

            if (noframes == null)
            {
                noframes = node;
                InsertNodeAtEnd(frameset, noframes);
            }
            else
                FreeNode( doc, node);

            ParseTag(doc, noframes, mode);
            continue;
        }

        if (node->type == StartTag || node->type == StartEndTag)
        {
            if (node->tag && node->tag->model & CM_HEAD)
            {
                MoveToHead(doc, html, node);
                continue;
            }

            /* discard illegal frame element following a frameset */
            if ( frameset != null && nodeIsFRAME(node) )
            {
                ReportWarning( doc, html, node, DISCARDING_UNEXPECTED);
                continue;
            }
        }

        UngetToken( doc );

        /* insert other content into noframes element */

        if (frameset)
        {
            if (noframes == null)
            {
                noframes = InferredTag(doc, "noframes");
                InsertNodeAtEnd(frameset, noframes);
            }
            else
                ReportWarning( doc, html, node, NOFRAMES_CONTENT);

            ConstrainVersion(doc, VERS_FRAMESET);
            ParseTag(doc, noframes, mode);
            continue;
        }

        node = InferredTag(doc, "body");
        ConstrainVersion(doc, ~VERS_FRAMESET);
        break;
    }

    /* node must be body */

    InsertNodeAtEnd(html, node);
    ParseTag(doc, node, mode);
}

/*
  HTML is the top level element
*/
Node *ParseDocument(TidyDocImpl* doc)
{
    Node *node, *document, *html, *doctype = null;

    document = NewNode(doc->lexer);
    document->type = RootNode;
    doc->root = doc->lexer->root = document;

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        /* deal with comments etc. */
        if (InsertMisc(document, node))
            continue;

        if (node->type == DocTypeTag)
        {
            if (doctype == null)
            {
                InsertNodeAtEnd(document, node);
                doctype = node;
            }
            else
            {
                ReportWarning( doc, RootNode, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
            }
            continue;
        }

        if (node->type == EndTag)
        {
            ReportWarning( doc, RootNode, node, DISCARDING_UNEXPECTED);
            FreeNode( doc, node);
            continue;
        }

        if ( node->type != StartTag || !nodeIsHTML(node) )
        {
            UngetToken( doc );
            html = InferredTag(doc, "html");
        }
        else
            html = node;

        InsertNodeAtEnd(document, html);
        ParseHTML( doc, html, no );
        break;
    }

    return document;
}

Bool XMLPreserveWhiteSpace( TidyDocImpl* doc, Node *element)
{
    AttVal *attribute;

    /* search attributes for xml:space */
    for (attribute = element->attributes; attribute; attribute = attribute->next)
    {
        if ( tmbstrcmp(attribute->attribute, "xml:space") == 0 )
        {
            if ( tmbstrcmp(attribute->value, "preserve") == 0 )
                return yes;

            return no;
        }
    }

    if (element->element == null)
        return no;
        
    /* kludge for html docs without explicit xml:space attribute */
    if ( tmbstrcasecmp(element->element, "pre") == 0
         || tmbstrcasecmp(element->element, "script") == 0
         || tmbstrcasecmp(element->element, "style") == 0
         || FindParser(doc, element) == ParsePre )
        return yes;

    /* kludge for XSL docs */
    if ( tmbstrcasecmp(element->element, "xsl:text") == 0 )
        return yes;

    return no;
}

/*
  XML documents
*/
static void ParseXMLElement(TidyDocImpl* doc, Node *element, uint mode)
{
    Lexer* lexer = doc->lexer;
    Node *node;

    /* if node is pre or has xml:space="preserve" then do so */

    if ( XMLPreserveWhiteSpace(doc, element) )
        mode = Preformatted;

    while ((node = GetToken(doc, mode)) != null)
    {
        if (node->type == EndTag && tmbstrcmp(node->element, element->element) == 0)
        {
            FreeNode( doc, node);
            element->closed = yes;
            break;
        }

        /* discard unexpected end tags */
        if (node->type == EndTag)
        {
            ReportError( doc, element, node, UNEXPECTED_ENDTAG );
            FreeNode( doc, node);
            continue;
        }

        /* parse content on seeing start tag */
        if (node->type == StartTag)
            ParseXMLElement( doc, node, mode );

        InsertNodeAtEnd(element, node);
    }

    /*
     if first child is text then trim initial space and
     delete text node if it is empty.
    */

    node = element->content;

    if (node && node->type == TextNode && mode != Preformatted)
    {
        if ( lexer->lexbuf[node->start] == ' ' )
        {
            node->start++;

            if (node->start >= node->end)
                DiscardElement( doc, node );
        }
    }

    /*
     if last child is text then trim final space and
     delete the text node if it is empty
    */

    node = element->last;

    if (node && node->type == TextNode && mode != Preformatted)
    {
        if ( lexer->lexbuf[node->end - 1] == ' ' )
        {
            node->end--;

            if (node->start >= node->end)
                DiscardElement( doc, node );
        }
    }
}

Node *ParseXMLDocument(TidyDocImpl* doc)
{
    Lexer* lexer = doc->lexer;
    Node *node, *document, *doctype = null;

    doc->root = lexer->token = document = NewNode( lexer );
    document->type = RootNode;
    SetOptionBool( doc, TidyXmlTags, yes );

    while ((node = GetToken(doc, IgnoreWhitespace)) != null)
    {
        /* discard unexpected end tags */
        if (node->type == EndTag)
        {
            ReportWarning( doc, null, node, UNEXPECTED_ENDTAG);
            FreeNode( doc, node);
            continue;
        }

         /* deal with comments etc. */
        if (InsertMisc(document, node))
            continue;

        if (node->type == DocTypeTag)
        {
            if (doctype == null)
            {
                InsertNodeAtEnd(document, node);
                doctype = node;
            }
            else
            {
                ReportWarning( doc, RootNode, node, DISCARDING_UNEXPECTED);
                FreeNode( doc, node);
            }
            continue;
        }

        if (node->type == StartEndTag)
        {
            InsertNodeAtEnd(document, node);
            continue;
        }

       /* if start tag then parse element's content */
        if (node->type == StartTag)
        {
            InsertNodeAtEnd( document, node );
            ParseXMLElement( doc, node, IgnoreWhitespace );
        }

    }

    if ( doctype && !CheckDocTypeKeyWords(lexer, doctype) )
        ReportWarning( doc, doctype, null, DTYPE_NOT_UPPER_CASE );

    /* ensure presence of initial <?XML version="1.0"?> */
    if ( cfgBool(doc, TidyXmlDecl) )
        FixXmlDecl( doc );

    return document;
}

