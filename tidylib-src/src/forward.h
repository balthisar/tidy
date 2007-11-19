#ifndef __FORWARD_H__
#define __FORWARD_H__

/* forward.h -- Forward declarations for major Tidy structures

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

  Avoids many include file circular dependencies.

  Try to keep this file down to the minimum to avoid
  cross-talk between modules.

  Header files include this file.  C files include tidy-int.h.

*/

#include "platform.h"
#include "tidy.h"

struct _StreamIn;
typedef struct _StreamIn StreamIn;

struct _StreamOut;
typedef struct _StreamOut StreamOut;

struct _TidyDocImpl;
typedef struct _TidyDocImpl TidyDocImpl;


struct _Dict;
typedef struct _Dict Dict;

struct _Attribute;
typedef struct _Attribute Attribute;

struct _AttVal;
typedef struct _AttVal AttVal;

struct _Node;
typedef struct _Node Node;

struct _IStack;
typedef struct _IStack IStack;

struct _Lexer;
typedef struct _Lexer Lexer;



#endif /* __FORWARD_H__ */
