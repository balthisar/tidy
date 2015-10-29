/**************************************************************************************************

	AppController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "AppController.h"
#import "CommonHeaders.h"

#import "JSDAllCapsValueTransformer.h"
#import "JSDIntegerValueTransformer.h"
#import "JSDBoolToStringValueTransformer.h"

#import "DCOAboutWindowController.h"
#import "PreferenceController.h"
#import "TidyDocument.h"

#ifdef FEATURE_SUPPORTS_SERVICE
	#import "TidyDocumentService.h"
#endif

#ifdef FEATURE_SPARKLE
	#import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface AppController ()


/* Window controller for About... */
@property (nonatomic, strong) DCOAboutWindowController *aboutWindowController;

/* We need to hide this for App Store builds. */
@property (nonatomic, weak) IBOutlet NSMenuItem *menuCheckForUpdates;

/* Retrieves the current, correct name for the Quit menu item. */
@property (nonatomic, weak, readonly) NSString *menuQuitTitle;

/* Exposes conditional define FEATURE_EXPORTS_CONFIG for binding. */
@property (nonatomic, assign, readonly) BOOL featureExportsConfig;

/* Exposes conditional define FEATURE_SUPPORTS_SXS_DIFFS for binding. */
@property (nonatomic, assign, readonly) BOOL featureSyncedDiffs;

@end


#pragma mark - IMPLEMENTATION


@implementation AppController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + initialize
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)initialize
{
	/* When the app is initialized pass off registering of the user
	   defaults to the `PreferenceController`. This must occur before
	   any documents open.
	 */
	
	[[PreferenceController sharedPreferences] registerUserDefaults];

	/* Initialize the value transformers used throughout the
	   application bindings.
	 */

	NSValueTransformer *localTransformer;

	localTransformer = [[JSDIntegerValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:localTransformer forName:@"JSDIntegerValueTransformer"];

	localTransformer = [[JSDAllCapsValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:localTransformer forName:@"JSDAllCapsValueTransformer"];

	localTransformer = [[JSDBoolToStringValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:localTransformer forName:@"JSDBoolToStringValueTransformer"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#ifdef FEATURE_SUPPORTS_SERVICE
	
	/* Register our services.
	 */
	TidyDocumentService *tidyService = [[TidyDocumentService alloc] init];
	
	/*
	   Use NSRegisterServicesProvider instead of NSApp:setServicesProvider
	   So that we can have careful control over the port name.
	 */
	NSRegisterServicesProvider(tidyService, @"com.balthisar.app.port");
	

	/* Launch and Quit the helper to ensure that it registers
	   itself as a provider of System Services. 
	   @NOTE: Only on 10.9 and above.
	 */
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_9)
	{
		dispatch_queue_t launchQueue = dispatch_queue_create("launchHelper", NULL);
		dispatch_async(launchQueue, ^{
			NSString *helper = [NSString stringWithFormat:@"%@/Contents/PlugIns/Balthisar Tidy Service Helper.app", [[NSBundle mainBundle] bundlePath]];
			NSTask *task = [[NSTask alloc] init];
			[task setLaunchPath:@"/usr/bin/open"];
			[task setArguments:@[helper]];
			[task launch];
			if (![[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAllowServiceHelperTSR])
			{
				sleep(3);
				dispatch_async(dispatch_get_main_queue(), ^{
					[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"balthisarTidyHelperOpenThenQuit" object:@"BalthisarTidy"];
				});
			}
		});
	}
#endif

	/*	The `Balthisar Tidy (no sparkle)` target has NOSPARKLE=1 defined.
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


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - applicationWillTerminate:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAllowServiceHelperTSR])
	{
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"balthisarTidyHelperOpenThenQuit" object:@"BalthisarTidy"];
	}
}


#pragma mark - Showing Preferences and such


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property aboutWindowController
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
  - showAboutWindow:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showAboutWindow:(id)sender {
    
    /* Configure the controller to override defaults. */

    self.aboutWindowController.appWebsiteURL = [NSURL URLWithString:@"http://www.balthisar.com/software/tidy/"];

	self.aboutWindowController.useTextViewForAcknowledgments = YES;
    
    [self.aboutWindowController showWindow:nil];
    
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - showPreferences:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showPreferences:(id)sender
{
	[[PreferenceController sharedPreferences] showWindow:self];
}


#pragma mark - Other Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property menuQuitTitle
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)menuQuitTitle
{
#ifdef TARGET_PRO
	return NSLocalizedString(@"Quit Balthisar Tidy for Work", nil);
#else
	return NSLocalizedString(@"Quit Balthisar Tidy", nil);
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property featureExportsConfig
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
