/**************************************************************************************************

	AppController

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

#import "AppController.h"
#import "PreferenceController.h"
#import "PreferencesDefinitions.h"
#import "JSDIntegerValueTransformer.h"
#import "JSDAllCapsValueTransformer.h"
#import "JSDBoolToStringValueTransformer.h"
#import "TidyDocument.h"
#import "DCOAboutWindowController.h"

#ifdef FEATURE_SPARKLE
	#import <Sparkle/Sparkle.h>
#endif



#pragma mark - CATEGORY - Non-Public


@interface AppController ()


@property (weak) IBOutlet NSMenuItem *menuCheckForUpdates;               // We need to hide this for App Store builds.

@property (nonatomic) DCOAboutWindowController *aboutWindowController;   // Window controller for About...


/* Feature Properties for binding to conditionally-compiled features. */

@property (readonly) BOOL featureExportsConfig; // exposes conditional define FEATURE_EXPORTS_CONFIG for binding.


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


	/* Initialize the value transformers used throughout the application bindings */

	NSValueTransformer *localTransformer;

	localTransformer = [[JSDIntegerValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:localTransformer forName:@"JSDIntegerValueTransformer"];

	localTransformer = [[JSDAllCapsValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:localTransformer forName:@"JSDAllCapsValueTransformer"];

	localTransformer = [[JSDBoolToStringValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:localTransformer forName:@"JSDBoolToStringValueTransformer"];
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
	#ifdef FEATURE_SPARKLE
		[[self menuCheckForUpdates] setTarget:[SUUpdater sharedUpdater]];
		[[self menuCheckForUpdates] setAction:@selector(checkForUpdates:)];
		[[self menuCheckForUpdates] setEnabled:YES];
	#else
		[[self menuCheckForUpdates] setHidden:YES];
	#endif
}


#pragma mark - Showing preferences and such


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	aboutWindowController
		Implemented as a property in order to allow lazy-loading.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (DCOAboutWindowController *)aboutWindowController
{
    if (!_aboutWindowController)
	{
        _aboutWindowController = [[DCOAboutWindowController alloc] init];
    }
    return _aboutWindowController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	showAboutWindow:
		Show the about window.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showAboutWindow:(id)sender {
    
    /* Configure the controller to override defaults. */

    self.aboutWindowController.appWebsiteURL = [NSURL URLWithString:@"http://www.balthisar.com/software/tidy/"];

	self.aboutWindowController.acknowledgmentsUseEditor = NO;
    
    [self.aboutWindowController showWindow:nil];
    
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	showPreferences:
		Show the preferences window.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showPreferences:(id)sender
{
	[[PreferenceController sharedPreferences] showWindow:self];
}


#pragma mark - App Name Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	menuQuitTitle
		Hard-compiled determiner.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)menuQuitTitle
{
#ifdef TARGET_PRO
	return NSLocalizedString(@"Quit Balthisar Tidy for Work", nil);
#else
	return NSLocalizedString(@"Quit Balthisar Tidy", nil);
#endif
}



#pragma mark - Feature Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	featureExportsConfig
		Hard-compiled feature determiner.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureExportsConfig
{
#ifdef FEATURE_EXPORTS_CONFIG
	return YES;
#else
	return NO;
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	featureSyncedDiffs
		Hard-compiled feature determiner.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureSyncedDiffs
{
#ifdef FEATURE_SUPPORTS_SXS_DIFFS
	return NO;
#else
	return NO;
#endif
}



@end
