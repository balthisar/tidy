//
//  JSDNuValidator+SMLSyntaxError.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;

@import JSDNuVFramework;
@import Fragaria;

/**
 *   Extends JSDTidyModel so that it can provide an array of <MGSSyntaxError> objects directly
 *   to a Fragaria view.
 */
@interface JSDNuValidator (MGSSyntaxError)

/**
 *  Makes available tidylib's error report as an **NSArray** of **MGSSyntaxError** of the errors.
 */
@property (nonatomic, strong, readonly) NSArray<MGSSyntaxError *>  *fragariaErrorArray;

@end
