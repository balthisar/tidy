/**************************************************************************************************
 
	JSDTidyModel
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.
 
 **************************************************************************************************/

#import "JSDTidyModel.h"

/**
 *  This category adds non-core functionality to JSDTidyModel.
 **/
@interface JSDTidyModel (Developer)


/**
 *  This method dumps all `libtidy` option descriptions to the console. This is probably mostly
 *  useful to developers who want to develop localizations. This is a cheap way to get the descriptions
 *  for Localizable.strings. This will produce a fairly nice, formatted list of strings that you might
 *  use directly. Double-check quotes, etc., before building. There are probably a couple of entities
 *  that are missed.
 */
+ (void)      optionsBuiltInDumpDocsToConsole;


@end
