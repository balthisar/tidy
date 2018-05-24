/**************************************************************************************************

 	HTMLTidy

	The module HTMLTidy is a modularized interface to the HTML Tidy dynamic library.

 	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

FOUNDATION_EXPORT double HTMLTidyModuleVersionNumber;
FOUNDATION_EXPORT const unsigned char HTMLTidyModuleVersionString[];

#import "tidy.h"
#import "tidybuffio.h"
#import "tidyenum.h"
#import "tidyplatform.h"
