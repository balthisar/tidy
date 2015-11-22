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
#import "JSDTidyModel.h"

#import "TidyDocumentWindowController.h"

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

/* Exposes conditional define FEATURE_EXPORTS_RTF for binding. */
@property (nonatomic, assign, readonly) BOOL featureExportsRTF;

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
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		
		/* When the app is initialized pass off registering of the user
		 * defaults to the `PreferenceController`. This must occur before
		 * any documents open.
		 */
		
		[[PreferenceController sharedPreferences] registerUserDefaults];
		
		/* Initialize the value transformers used throughout the
		 * application bindings.
		 */
		
		NSValueTransformer *localTransformer;
		
		localTransformer = [[JSDIntegerValueTransformer alloc] init];
		[NSValueTransformer setValueTransformer:localTransformer forName:@"JSDIntegerValueTransformer"];
		
		localTransformer = [[JSDAllCapsValueTransformer alloc] init];
		[NSValueTransformer setValueTransformer:localTransformer forName:@"JSDAllCapsValueTransformer"];
		
		localTransformer = [[JSDBoolToStringValueTransformer alloc] init];
		[NSValueTransformer setValueTransformer:localTransformer forName:@"JSDBoolToStringValueTransformer"];
	});
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

	/* The `Balthisar Tidy (no sparkle)` target has NOSPARKLE=1 defined.
	 * Because we're building completely without Sparkle, we have to
	 * make sure there are no references to it in the MainMenu nib,
	 * and set its target-action programmatically.
	 */
#if defined(FEATURE_SPARKLE)
	[[self menuCheckForUpdates] setTarget:[SUUpdater sharedUpdater]];
	[[self menuCheckForUpdates] setAction:@selector(checkForUpdates:)];
	[[self menuCheckForUpdates] setEnabled:YES];
#elif defined(FEATURE_FAKE_SPARKLE)
	[[self menuCheckForUpdates] setTarget:self];
	[[self menuCheckForUpdates] setAction:@selector(showPreferences:)];
	[[self menuCheckForUpdates] setEnabled:YES];
#else
	[[self menuCheckForUpdates] setHidden:YES];
#endif

	/* Linked tidy library version check. To ensure compatibility with
	 * certain API matters in `libtidy` warn the user if the linker
	 * connected us to an old version of `libtidy`.
	 * - require 5.1.24 so that `indent-with-tabs` works properly.
	 */
	JSDTidyModel *localModel = [[JSDTidyModel alloc] init];
	NSString *versionWant = LIBTIDY_V_WANT;
	NSString *versionHave = localModel.tidyLibraryVersion;
	
	if (![localModel tidyLibraryVersionAtLeast:versionWant])
	{
		NSString *message = [NSString stringWithFormat:JSDLocalizedString(@"libTidy-compatability-inform", nil), versionHave, versionWant];
		NSLog(@"%@", message);
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:JSDLocalizedString(@"libTidy-compatability-message", nil)];
		[alert setInformativeText:message];
		[alert addButtonWithTitle:@"OK"];
		[alert runModal];
	}
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

#if defined(TARGET_WEB)
        NSString *creditsFile = @"Credits";
#elif defined(TARGET_APP)
        NSString *creditsFile = @"Credits (app)";
#elif defined(TARGET_PRO)
        NSString *creditsFile = @"Credits (pro)";
#else
        NSString *creditsFile = @"Credits";
#endif

		JSDTidyModel *localModel = [[JSDTidyModel alloc] init];
		NSString *version = localModel.tidyLibraryVersion;

		NSString *creditsPath = [[NSBundle mainBundle] pathForResource:creditsFile ofType:@"rtf"];
		NSMutableAttributedString *creditsText = [[NSMutableAttributedString alloc] initWithPath:creditsPath documentAttributes:nil];
        [creditsText.mutableString replaceOccurrencesOfString:@"%@"
                                                   withString:version
                                                      options:NSLiteralSearch
                                                        range:NSMakeRange(0, [creditsText.mutableString length])];

        _aboutWindowController.appCredits = creditsText;
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
  @property sharedDocumentController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSDocumentController *)sharedDocumentController
{
	return [NSDocumentController sharedDocumentController];
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property menuQuitTitle
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)menuQuitTitle
{
#ifdef USE_STANDARD_QUIT_MENU_NAME
    return NSLocalizedString(@"Quit Balthisar Tidy", nil);
#else
    return NSLocalizedString(@"Quit Balthisar Tidy for Work", nil);
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
  @property featureExportsRTF
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureExportsRTF
{
#ifdef FEATURE_EXPORTS_RTF
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
