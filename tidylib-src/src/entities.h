#ifndef __ENTITIES_H__
#define __ENTITIES_H__

/* entities.h -- recognize character entities

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:10 $ 
    $Revision: 1.2 $ 

*/

#include "forward.h"

void InitEntities();
void FreeEntities();

/* entity starting with "&" returns zero on error */
uint    EntityCode( ctmbstr name, uint versions );
ctmbstr EntityName( uint charCode, uint versions );

#endif /* __ENTITIES_H__ */
