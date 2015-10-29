/**************************************************************************************************

	AppController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  This main application controller handles application startup, Preference, and target conditional
 *  differences such as Sparkle vs. non-sparkle.
 */
@interface AppController : NSObject <NSApplicationDelegate>


/**
 *  Show the Preferences window.
 */
- (IBAction)showPreferences:(id)sender;


/**
 *  Show the About window.
 */
- (IBAction)showAboutWindow:(id)sender;


@end

