#ifndef __TMBSTR_H__
#define __TMBSTR_H__

/* tmbstr.h - Tidy string utility functions

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:11 $ 
    $Revision: 1.2 $ 

*/

#include "platform.h"

/* like strdup but using MemAlloc */
tmbstr tmbstrdup( ctmbstr str );

/* like strndup but using MemAlloc */
tmbstr tmbstrndup( ctmbstr str, uint len);

/* exactly same as strncpy */
uint tmbstrncpy( tmbstr s1, ctmbstr s2, uint size );

uint tmbstrcpy( tmbstr s1, ctmbstr s2 );

uint tmbstrcat( tmbstr s1, ctmbstr s2 );

/* exactly same as strcmp */
int tmbstrcmp( ctmbstr s1, ctmbstr s2 );

/* returns byte count, not char count */
uint tmbstrlen( ctmbstr str );

/*
  MS C 4.2 doesn't include strcasecmp.
  Note that tolower and toupper won't
  work on chars > 127.

  Neither do Lexer.ToLower() or Lexer.ToUpper()!

  We get away with this because, except for XML tags,
  we are always comparing to ascii element and
  attribute names defined by HTML specs.
*/
int tmbstrcasecmp( ctmbstr s1, ctmbstr s2 );

int tmbstrncmp( ctmbstr s1, ctmbstr s2, uint n );

int tmbstrncasecmp( ctmbstr s1, ctmbstr s2, uint n );

/* return offset of cc from beginning of s1,
** -1 if not found.
*/
int tmbstrnchr( ctmbstr s1, uint len1, tmbchar cc );

ctmbstr tmbsubstrn( ctmbstr s1, uint len1, ctmbstr s2 );
ctmbstr tmbsubstrncase( ctmbstr s1, uint len1, ctmbstr s2 );
ctmbstr tmbsubstr( ctmbstr s1, ctmbstr s2 );

/* transform string to lower case */
tmbstr tmbstrtolower( tmbstr s );

Bool tmbsamefile( ctmbstr filename1, ctmbstr filename2 );

#endif /* __TMBSTR_H__ */
