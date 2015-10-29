/**************************************************************************************************

	TidyService

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

/**
	This class provides the functions for allowing Balthisar Tidy to provide a service.
	It operates as a faceless app only and thus only provides the faceless services.
    Balthisar Tidy proper will provide other services.
 */
@interface TidyService : NSObject

/**
 *  Handle the "Tidy with Balthisar Tidy" system service.
 *
 *  Returns a Tidy'd version of the pasteboard text with a tidy'd
 *  version using the preferences defaults. We will try with
 *  force-output if no response.
 */
- (void)tidySelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

/**
 *  Handle the "Tidy with Balthisar Tidy (body only)" system service.
 *
 *  Returns a Tidy'd version of the pasteboard text with a tidy'd
 *  version using the preferences defaults. We will try with
 *  force-output if no response.
 */
- (void)tidySelectionBodyOnly:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

@end
