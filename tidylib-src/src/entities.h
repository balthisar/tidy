#ifndef __ENTITIES_H__
#define __ENTITIES_H__

/* entities.h -- recognize character entities

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: terry_teague $ 
    $Date: 2002/07/08 07:42:13 $ 
    $Revision: 1.1.2.2 $ 

*/

#include "forward.h"

void InitEntities();
void FreeEntities();

/* entity starting with "&" returns zero on error */
uint    EntityCode( ctmbstr name, uint versions );
ctmbstr EntityName( uint charCode, uint versions );

#endif /* __ENTITIES_H__ */
