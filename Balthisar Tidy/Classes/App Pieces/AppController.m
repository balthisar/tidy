/**************************************************************************************************

	AppController

	Copyright © 2003-2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "AppController.h"
#import "CommonHeaders.h"

#import "JSDAllCapsValueTransformer.h"
#import "JSDIntegerValueTransformer.h"
#import "JSDBoolToStringValueTransformer.h"

#import "PreferenceController.h"

#import <DCOAboutWindow/DCOAboutWindowController.h>
#import <Fragaria/Fragaria.h>
#import <FragariaDefaultsCoordinator/FragariaDefaultsCoordinator.h>


@import JSDTidyFramework;


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

/* A managed version of NSUserDefaultsController for Global Fragaria Properties. */
@property (nonatomic, assign, readonly) MGSUserDefaultsController *userDefaultsController;


/* Instance of Sparkle to keep around. */
#if defined(FEATURE_SPARKLE)
@property (nonatomic, strong, readonly) SPUStandardUpdaterController *updater;
#endif

@end


#pragma mark - IMPLEMENTATION


@implementation AppController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + initialize
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)initialize
{
	/* Support Cmd-Shift launch deletes all user defaults. */
    NSUInteger launchFlag = [NSEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
	
    if (launchFlag & (NSEventModifierFlagShift | NSEventModifierFlagCommand))
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:JSDLocalizedString(@"defaults-delete-message", nil)];
		[alert addButtonWithTitle:JSDLocalizedString(@"defaults-delete-button-delete", nil)];
		[alert addButtonWithTitle:JSDLocalizedString(@"defaults-delete-button-cancel", nil)];
		
		NSInteger button = [alert runModal];
		if (button == NSAlertFirstButtonReturn)
		{
			NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
			[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
		}
	}

	
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
  - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
    if ( (self = [super init]) )
    {
#if defined(FEATURE_SPARKLE)
        _updater = [[SPUStandardUpdaterController alloc] initWithUpdaterDelegate:nil userDriverDelegate:nil];
#endif
    }
	
	_userDefaultsController = [MGSUserDefaultsController sharedController];

    return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self
											   forKeyPath:JSDKeyValidatorSelection];

	[[NSUserDefaults standardUserDefaults] removeObserver:self
											   forKeyPath:JSDKeyValidatorBuiltInPort];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	/* Observe these in order to control the built-in NuV server */

	static int jim1 = 123;
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:JSDKeyValidatorSelection
											   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
											   context:&jim1];

	static int jim2 = 321;
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:JSDKeyValidatorBuiltInPort
											   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
											   context:&jim2];

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
    [[self menuCheckForUpdates] setTarget:self.updater];
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
	 * - require 5.1.29 so that tidy.cfg files work with css-prefix.
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
		[alert addButtonWithTitle:JSDLocalizedString(@"libTidy-compatability-button", nil)];
		[alert runModal];
	}

#ifdef USE_STANDARD_MENU_NAME
	NSMenu *menu = [[[NSApp mainMenu] itemAtIndex:0] submenu];
	[menu setTitle:@"Balthisar Tidy\x1b"];
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

	[[self sharedNuVServer] serverStop];
}


#pragma mark - Application Controller


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - applicationShouldOpenUntitledFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyShouldOpenUntitledFile];
}


#pragma mark - About... window


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property aboutWindowController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (DCOAboutWindowController *)aboutWindowController
{
    if (!_aboutWindowController)
	{
        _aboutWindowController = [[DCOAboutWindowController alloc] init];
		_aboutWindowController.delegate = self;
        _aboutWindowController.appCredits = [[NSAttributedString alloc] init]; // empty, not nil!
    }
	
    return _aboutWindowController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  <DCOStringPreprocessingProtocol> preprocessAppAcknowledgments:
    Force the strings to use named colors so that dark mode will
    show proper colors.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSAttributedString *)preprocessAppAcknowledgments:(NSAttributedString *)appAcknowledgments
{
	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithAttributedString:appAcknowledgments];
	
	[result addAttribute:NSForegroundColorAttributeName
				   value:[NSColor textColor]
				   range:NSMakeRange(0,result.length)];
	
	[result addAttribute:NSBackgroundColorAttributeName
				   value:[NSColor textBackgroundColor]
				   range:NSMakeRange(0,result.length)];

	return result;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  <DCOStringPreprocessingProtocol> preproccessAppCredits:
    Load the correct file from the bundle, discarding the string
    we were provided (we set a junk string on instantiation).
    Perform some string substitution, and force the colors to named
    colors so that dark mode might work.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSAttributedString *)preprocessAppCredits:(NSAttributedString *)preproccessAppCredits
{
#if defined(TARGET_WEB)
	NSString *creditsFile = @"Credits (web)";
#elif defined(TARGET_APP)
	NSString *creditsFile = @"Credits (app)";
#elif defined(TARGET_PRO)
	NSString *creditsFile = @"Credits (pro)";
#else
	NSString *creditsFile = @"Credits (pro)";
#endif
	
    NSURL *creditsURL = [[NSBundle mainBundle] URLForResource:creditsFile withExtension:@"rtf"];
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc]
                                         initWithURL:creditsURL
                                         options:@{}
                                         documentAttributes:nil
                                         error:nil];
    
	JSDTidyModel *localModel = [[JSDTidyModel alloc] init];
	
	[result.mutableString replaceOccurrencesOfString:@"${TIDY_VERSION}"
											   withString:localModel.tidyLibraryVersion
												  options:NSLiteralSearch
													range:NSMakeRange(0, result.mutableString.length)];
	
	[result.mutableString replaceOccurrencesOfString:@"${NUV_VERSION}"
											   withString:[JSDNuVServer serverVersion]
												  options:NSLiteralSearch
													range:NSMakeRange(0, result.mutableString.length)];
	
	[result.mutableString replaceOccurrencesOfString:@"${JRE_VERSION}"
										  withString:[[JSDNuVServer JREVersion] capitalizedString]
											 options:NSLiteralSearch
											   range:NSMakeRange(0, result.mutableString.length)];
	
	[result addAttribute:NSForegroundColorAttributeName
						value:[NSColor textColor]
						range:NSMakeRange(0,result.length)];
	
	[result addAttribute:NSBackgroundColorAttributeName
						value:[NSColor textBackgroundColor]
						range:NSMakeRange(0,result.length)];

	return result;
}


#pragma mark - Showing Preferences


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
 @property sharedDocumentController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (JSDNuVServer *)sharedNuVServer
{
	return [JSDNuVServer sharedNuVServer];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property menuQuitTitle
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)menuQuitTitle
{
#ifdef USE_STANDARD_MENU_NAME
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
  @property featureDualPreview
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureDualPreview
{
#ifdef FEATURE_SUPPORTS_DUAL_PREVIEW
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


#pragma mark - KVO


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - observeValueForKeyPath:ofObject:change:context:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	/* There's a bug in recent macOS that can result in duplicate KVO notifications for user
	   default changes! Because we should never receive the same change twice in a row, let's
	   filter out this condition.
	 */
	static NSDictionary *prevDict;
	if ( prevDict && [change isEqualToDictionary:prevDict] )
	{
		prevDict = change;
		return;
	}
	prevDict = change;

	/* Manage the shared controller, including starting and stopping it, and
	 changing the port. */

	if ( [keyPath isEqualToString:JSDKeyValidatorSelection] || [keyPath isEqualToString:JSDKeyValidatorBuiltInPort] )
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		JSDValidatorSelectionType selection = [defaults integerForKey:JSDKeyValidatorSelection];
		NSString *port = [defaults stringForKey:JSDKeyValidatorBuiltInPort];
		JSDNuVServer *server = [JSDNuVServer sharedNuVServer];

		switch ( selection )
		{
			case JSDValidatorBuiltIn:
				server.port = port;
				[server serverLaunch];
				break;

			default:
				if ( server.serverTask.running )
				{
					[server serverStop];
				}
				break;
		}
	}
}


@end
