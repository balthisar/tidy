/**************************************************************************************************
 *
 *  JSDTidyModel+SMLSyntaxError
 *
 *  Copyright © 2018 by Jim Derry. All rights reserved.
 *
 **************************************************************************************************/

@import Cocoa;

@import JSDTidyFramework;
@import Fragaria;

/**
 *  Extends JSDTidyModel so that it can provide an array of <SMLSyntaxError *> objects directly
 *  to a Fragaria view.
 */
@interface JSDTidyModel (SMLSyntaxError)

/**
 *  Makes available tidylib's error report as an @c NSArray of @c<SMLSyntaxError *> of the errors.
 */
@property (nonatomic, strong, readonly) NSArray<SMLSyntaxError *>  *fragariaErrorArray;

@end
