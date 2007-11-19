#ifndef __PARSER_H__
#define __PARSER_H__

/* parser.h -- HTML Parser

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.
  
  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:11 $ 
    $Revision: 1.2 $ 

*/

#include "forward.h"

Bool CheckNodeIntegrity(Node *node);

/*
 used to determine how attributes
 without values should be printed
 this was introduced to deal with
 user defined tags e.g. Cold Fusion
*/
Bool IsNewNode(Node *node);

void CoerceNode( TidyDocImpl* doc, Node *node, TidyTagId tid );

/* extract a node and its children from a markup tree */
Node *RemoveNode(Node *node);

/* remove node from markup tree and discard it */
Node *DiscardElement( TidyDocImpl* doc, Node *element);

/* insert node into markup tree */
void InsertNodeAtStart(Node *element, Node *node);

/* insert node into markup tree */
void InsertNodeAtEnd(Node *element, Node *node);

/* insert node into markup tree before element */
void InsertNodeBeforeElement(Node *element, Node *node);

/* insert node into markup tree after element */
void InsertNodeAfterElement(Node *element, Node *node);

Node *TrimEmptyElement( TidyDocImpl* doc, Node *element );



/* assumes node is a text node */
Bool IsBlank(Lexer *lexer, Node *node);


/*
 duplicate name attribute as an id
 and check if id and name match
*/
void FixId( TidyDocImpl* doc, Node *node );

/* acceptable content for pre elements */
Bool PreContent( TidyDocImpl* doc, Node *node );

Bool IsJavaScript(Node *node);

/*
  HTML is the top level element
*/
Node *ParseDocument( TidyDocImpl* doc );



/*
  XML documents
*/
Bool XMLPreserveWhiteSpace( TidyDocImpl* doc, Node *element );

Node* ParseXMLDocument( TidyDocImpl* doc );

#endif /* __PARSER_H__ */
