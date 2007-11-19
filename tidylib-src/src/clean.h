#ifndef __CLEAN_H__
#define __CLEAN_H__

/* clean.h -- clean up misuse of presentation markup

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info:
    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

*/

void RenameElem( Node* node, TidyTagId tid );

Node* CleanNode( TidyDocImpl* doc, Node* node );

void FreeStyles( TidyDocImpl* doc );

/* Add class="foo" to node
*/
void AddClass( TidyDocImpl* doc, Node* node, ctmbstr classname );

void CleanDocument( TidyDocImpl* doc );

/* simplifies <b><b> ... </b> ...</b> etc. */
void NestedEmphasis( TidyDocImpl* doc, Node* node );

/* replace i by em and b by strong */
void EmFromI( TidyDocImpl* doc, Node* node );

/*
 Some people use dir or ul without an li
 to indent the content. The pattern to
 look for is a list with a single implicit
 li. This is recursively replaced by an
 implicit blockquote.
*/
void List2BQ( TidyDocImpl* doc, Node* node );

/*
 Replace implicit blockquote by div with an indent
 taking care to reduce nested blockquotes to a single
 div with the indent set to match the nesting depth
*/
void BQ2Div( TidyDocImpl* doc, Node* node );


Node *FindEnclosingCell( TidyDocImpl* doc, Node* node );

void DropSections( TidyDocImpl* doc, Node* node );

/* used to hunt for hidden preformatted sections */
Bool NoMargins(Node *node);

/* does element have a single space as its content? */
Bool IsSingleSpace(Lexer *lexer, Node *node);


/*
 This is a major clean up to strip out all the extra stuff you get
 when you save as web page from Word 2000. It doesn't yet know what
 to do with VML tags, but these will appear as errors unless you
 declare them as new tags, such as o:p which needs to be declared
 as inline.
*/
void CleanWord2000( TidyDocImpl* doc, Node *node);

Bool IsWord2000( TidyDocImpl* doc );

/* where appropriate move object elements from head to body */
void BumpObject( TidyDocImpl* doc, Node *html );

void FixBrakes( TidyDocImpl* pDoc, Node *pParent );

void VerifyHTTPEquiv( TidyDocImpl* pDoc, Node *pParent );

Bool  HTMLVersionCompliance( TidyDocImpl* doc );

#endif /* __CLEAN_H__ */
