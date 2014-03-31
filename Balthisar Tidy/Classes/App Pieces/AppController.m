/**************************************************************************************************

	AppController.m

	This main application controller handles the preferences and most of the Sparkle vs.
	non-sparkle builds.


	The MIT License (MIT)

	Copyright (c) 2001 to 2014 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "PreferenceController.h"

#if INCLUDE_SPARKLE == 1
#import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface AppController ()

@property (weak, nonatomic) IBOutlet NSMenuItem *menuCheckForUpdates;

@end


#pragma mark - IMPLEMENTATION


@implementation AppController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	When the app is initialized pass off registering of the user
	defaults to the `PreferenceController`. This must occur before
	any documents open.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)initialize
{
	[PreferenceController registerUserDefaults];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 Things to take care of when the application has launched.
	 - Handle sparkle vs no-sparkle.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
/*
	The `Balthisar Tidy (no sparkle)` target has NOSPARKLE=1 defined.
	Because we're building completely without Sparkle, we have to
	make sure there are no references to it in the MainMenu nib,
	and set its target-action programmatically.
 */
#if INCLUDE_SPARKLE == 0
	[[self menuCheckForUpdates] setHidden:YES];
#else
	[[self menuCheckForUpdates] setTarget:[SUUpdater sharedUpdater]];
	[[self menuCheckForUpdates] setAction:@selector(checkForUpdates:)];
	[[self menuCheckForUpdates] setEnabled:YES];
#endif
}


#pragma mark - Showing preferences and batch windows


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	Show the preferences window.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showPreferences:(id)sender
{
	[[PreferenceController sharedPreferences] showWindow:self];
}


@end
