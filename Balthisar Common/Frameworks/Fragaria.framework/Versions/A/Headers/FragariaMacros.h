//
//  Header.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 28/10/2018.
//

#ifndef FragariaMacros_h
#define FragariaMacros_h


#define FRAGARIA_DEPRECATED __attribute__((deprecated))
#define FRAGARIA_DEPRECATED_MSG(m) __attribute__((deprecated(m)))

#ifndef FRAGARIA_PRIVATE
    #define FRAGARIA_PUB_UNAVAIL __attribute__((deprecated))
    #define FRAGARIA_PUB_UNAVAIL_MSG(m) __attribute__((deprecated(m)))
#else
    #define FRAGARIA_PUB_UNAVAIL
    #define FRAGARIA_PUB_UNAVAIL_MSG(m)
#endif


#endif /* FragariaMacros_h */
