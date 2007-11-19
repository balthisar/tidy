/* tmbstr.c -- Tidy string utility functions

  (c) 1998-2002 (W3C) MIT, INRIA, Keio University
  See tidy.h for the copyright notice.

  CVS Info :

    $Author: creitzel $ 
    $Date: 2003/02/16 19:33:11 $ 
    $Revision: 1.2 $ 

*/

#include "tmbstr.h"

/* like strdup but using MemAlloc */
tmbstr tmbstrdup( ctmbstr str )
{
    tmbstr s = null;
    if ( str )
    {
        uint len = tmbstrlen( str );
        tmbstr cp = s = (tmbstr) MemAlloc( 1+len );
        while ( *cp++ = *str++ )
            /**/;
    }
    return s;
}

/* like strndup but using MemAlloc */
tmbstr tmbstrndup( ctmbstr str, uint len )
{
    tmbstr s = null;
    if ( str && len > 0 )
    {
        tmbstr cp = s = (tmbstr) MemAlloc( 1+len );
        while ( len-- > 0 &&  (*cp++ = *str++) )
          /**/;
        *cp = 0;
    }
    return s;
}

/* exactly same as strncpy */
uint tmbstrncpy( tmbstr s1, ctmbstr s2, uint size )
{
    if ( s1 != null && s2 != null )
    {
        tmbstr cp = s1;
        while ( *s2 && --size )  /* Predecrement: reserve byte */
            *cp++ = *s2++;       /* for null terminator. */
        *cp = 0;
    }
    return size;
}

/* Allows expressions like:  cp += tmbstrcpy( cp, "joebob" );
*/
uint tmbstrcpy( tmbstr s1, ctmbstr s2 )
{
    uint ncpy = 0;
    while ( *s1++ = *s2++ )
        ++ncpy;
    return ncpy;
}

/* Allows expressions like:  cp += tmbstrcat( cp, "joebob" );
*/
uint tmbstrcat( tmbstr s1, ctmbstr s2 )
{
    uint ncpy = 0;
    while ( *s1 )
        ++s1;

    while ( *s1++ = *s2++ )
        ++ncpy;
    return ncpy;
}

/* exactly same as strcmp */
int tmbstrcmp( ctmbstr s1, ctmbstr s2 )
{
    int c;
    while ((c = *s1) == *s2)
    {
        if (c == '\0')
            return 0;

        ++s1;
        ++s2;
    }

    return (*s1 > *s2 ? 1 : -1);
}

/* returns byte count, not char count */
uint tmbstrlen( ctmbstr str )
{
    uint len = 0;
    while ( *str++ )
        ++len;
    return len;
}

/*
 MS C 4.2 doesn't include strcasecmp.
 Note that tolower and toupper won't
 work on chars > 127.

 Neither does ToLower()!
*/
uint ToLower( uint c );

int tmbstrcasecmp( ctmbstr s1, ctmbstr s2 )
{
    uint c;

    while (c = (uint)(*s1), ToLower(c) == ToLower((uint)(*s2)))
    {
        if (c == '\0')
            return 0;

        ++s1;
        ++s2;
    }

    return (*s1 > *s2 ? 1 : -1);
}

int tmbstrncmp( ctmbstr s1, ctmbstr s2, uint n )
{
    uint c;

    while ((c = (byte)*s1) == (byte)*s2)
    {
        if (c == '\0')
            return 0;

        if (n == 0)
            return 0;

        ++s1;
        ++s2;
        --n;
    }

    if (n == 0)
        return 0;

    return (*s1 > *s2 ? 1 : -1);
}

int tmbstrncasecmp( ctmbstr s1, ctmbstr s2, uint n )
{
    uint c;

    while ( (c = tolower(*s1)) == (uint) tolower(*s2) )
    {
        if (c == '\0')
            return 0;

        if (n == 0)
            return 0;

        ++s1;
        ++s2;
        --n;
    }

    if (n == 0)
        return 0;

    return (*s1 > *s2 ? 1 : -1);
}

/* return offset of cc from beginning of s1,
** -1 if not found.
*/
int tmbstrnchr( ctmbstr s1, uint maxlen, tmbchar cc )
{
    int i;
    ctmbstr cp = s1;

    for ( i = 0; (uint)i < maxlen; ++i, ++cp )
    {
        if ( *cp == cc )
            return i;
    }

    return -1;
}

ctmbstr tmbsubstrn( ctmbstr s1, uint len1, ctmbstr s2 )
{
    uint len2 = tmbstrlen(s2);
    int ix, diff = len1 - len2;

    for ( ix = 0; ix <= diff; ++ix )
    {
        if ( tmbstrncmp(s1+ix, s2, len2) == 0 )
            return (ctmbstr) s1+ix;
    }
    return null;
}

ctmbstr tmbsubstrncase( ctmbstr s1, uint len1, ctmbstr s2 )
{
    uint len2 = tmbstrlen(s2);
    int ix, diff = len1 - len2;

    for ( ix = 0; ix <= diff; ++ix )
    {
        if ( tmbstrncasecmp(s1+ix, s2, len2) == 0 )
            return (ctmbstr) s1+ix;
    }
    return null;
}

ctmbstr tmbsubstr( ctmbstr s1, ctmbstr s2 )
{
    uint len1 = tmbstrlen(s1), len2 = tmbstrlen(s2);
    int ix, diff = len1 - len2;

    for ( ix = 0; ix <= diff; ++ix )
    {
        if ( tmbstrncasecmp(s1+ix, s2, len2) == 0 )
            return (ctmbstr) s1+ix;
    }
    return null;
}

/* Transform ASCII chars in string to lower case.
*/
tmbstr tmbstrtolower( tmbstr s )
{
    tmbstr cp;
    for ( cp=s; *cp; ++cp )
        *cp = (tmbchar) ToLower( *cp );
    return s;
}


Bool tmbsamefile( ctmbstr filename1, ctmbstr filename2 )
{
#if FILENAMES_CASE_SENSITIVE
    return ( tmbstrcmp( filename1, filename2 ) == 0 );
#else
    return ( tmbstrcasecmp( filename1, filename2 ) == 0 );
#endif
}
