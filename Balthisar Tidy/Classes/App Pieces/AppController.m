//
//  AppController.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

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

#import "TidyDocumentService.h"

#ifdef FEATURE_SPARKLE
#import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface AppController ()


/* We only need to access this menu for Sparkle builds. */
@property (nonatomic, weak) IBOutlet NSMenuItem *menuCheckForUpdates;

#if defined(FEATURE_SPARKLE)
/* And of course, we only need this if this is a Sparkle build. */
@property (nonatomic, strong) SPUStandardUpdaterController *updater;
#endif

@end


#pragma mark - IMPLEMENTATION


@implementation AppController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * + initialize
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)initialize
{
    /*--------------------------------------------------*
     * When the app is initialized pass off registering
     * of the user defaults to `PreferenceController`.
     * This must occur before any documents open.
     *--------------------------------------------------*/
    [[PreferenceController sharedPreferences] registerUserDefaults];
    
    /*--------------------------------------------------*
     * Support Command key on launch to delete all
     * User Defauts.
     *--------------------------------------------------*/

    NSUInteger launchFlag = [NSEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
    
    if (launchFlag & NSEventModifierFlagCommand)
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
        /*--------------------------------------------------*
         * Initialize the value transformers used throughout
         * the application bindings.
         *--------------------------------------------------*/
        
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
 * - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
    if ( (self = [super init]) )
    {
        _userDefaultsController = [MGSUserDefaultsController sharedController];
    }

    return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:JSDKeyValidatorSelection];
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self
                                               forKeyPath:JSDKeyValidatorBuiltInPort];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /*--------------------------------------------------*
     * RECEIPT VALIDATION AND FEATURES CHECKING *STUB*
     *--------------------------------------------------*/
    [[NSNotificationCenter defaultCenter] postNotificationName:JSDNotifyFeatureChange object:self];


    /*--------------------------------------------------*
     * Observe these in order to control NuV server.
     * TODO: Why can't the server be told to monitor its
     * TODO: own user defaults?
     *--------------------------------------------------*/

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
    

    /*--------------------------------------------------*
     * Register our services.
     *--------------------------------------------------*/

    TidyDocumentService *tidyService = [[TidyDocumentService alloc] init];
    
    /* Use NSRegisterServicesProvider instead of NSApp:setServicesProvider
     * So that we can have careful control over the port name.
     */
    NSRegisterServicesProvider(tidyService, @"com.balthisar.app.port");


    /*--------------------------------------------------*
     * Launch and Quit the helper to ensure that it
     * registers itself as a provider of System Services.
     *--------------------------------------------------*/

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


    /*--------------------------------------------------*
     * If this is a Sparkle build, then set it up.
     *--------------------------------------------------*/

#if defined(FEATURE_SPARKLE)
    self.updater = [[SPUStandardUpdaterController alloc] initWithUpdaterDelegate:nil userDriverDelegate:nil];
    [[self menuCheckForUpdates] setTarget:self.updater];
    [[self menuCheckForUpdates] setAction:@selector(checkForUpdates:)];
#endif


    /*--------------------------------------------------*
     * Linked tidy library version check, to ensure
     * compatibility with certain `libtidy` API's.
     * Warn the user if the linker connected us to
     * an old version of `libtidy`.
     *--------------------------------------------------*/

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
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - applicationWillTerminate:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    /*--------------------------------------------------*
     * Clean up the service helper.
     *--------------------------------------------------*/
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAllowServiceHelperTSR])
    {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"balthisarTidyHelperOpenThenQuit" object:@"BalthisarTidy"];
    }
    
    /*--------------------------------------------------*
     * Clean up the NuvServer.
     *--------------------------------------------------*/
    [[self sharedNuVServer] serverStop];
}


#pragma mark - Application Controller


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - applicationShouldOpenUntitledFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyShouldOpenUntitledFile];
}


#pragma mark - KVO for JSDNuVFramework


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - observeValueForKeyPath:ofObject:change:context:
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
    

    /*--------------------------------------------------*
     * Manage the shared controller, including starting
     * and stopping it, and changing the port.
     *--------------------------------------------------*/
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


#pragma mark - About… window


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - showAboutWindow:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showAboutWindow:(id)sender
{
    static DCOAboutWindowController *aboutWindowController = nil;
    
    if (!aboutWindowController)
    {
        aboutWindowController = [[DCOAboutWindowController alloc] init];
        aboutWindowController.delegate = self;
        aboutWindowController.appCredits = [[NSAttributedString alloc] init];
        aboutWindowController.appWebsiteURL = [NSURL URLWithString:@"https://www.balthisar.com/software/tidy/"];
        aboutWindowController.useTextViewForAcknowledgments = YES;
    }
    
    [aboutWindowController showWindow:sender];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - <DCOStringPreprocessingProtocol> preprocessAppAcknowledgments:
 *  Force the strings to use named colors so that dark mode will
 *  show proper colors.
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
 * - <DCOStringPreprocessingProtocol> preproccessAppCredits:
 *  Load the correct file from the bundle, discarding the string
 *  we were provided (we set a junk string on instantiation).
 *  Perform some string substitution, and force the colors to named
 *  colors so that dark mode might work.
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


#pragma mark - Preferences Window


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - showPreferences:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)showPreferences:(id)sender
{
    [[[PreferenceController sharedPreferences] windowController] showWindow:sender];
}


#pragma mark - Singleton Bindings Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @sharedDocumentController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSDocumentController *)sharedDocumentController
{
    return [NSDocumentController sharedDocumentController];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @sharedDocumentController
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (JSDNuVServer *)sharedNuVServer
{
    return [JSDNuVServer sharedNuVServer];
}


#pragma mark - Features Management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureAppleScript
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureAppleScript
{
#ifdef TARGET_PRO
    return YES;
#else
    return NO;
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureDualPreview
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureDualPreview
{
#ifdef TARGET_PRO
    return YES;
#else
    return NO;
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureExportsConfig
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureExportsConfig
{
#ifdef TARGET_PRO
    return YES;
#else
    return NO;
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureExportsRTF
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureExportsRTF
{
#ifdef TARGET_PRO
    return YES;
#else
    return NO;
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureFragariaSchemes
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureFragariaSchemes
{
#ifdef TARGET_PRO
    return YES;
#else
    return NO;
#endif
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureSparkle
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureSparkle
{
    #ifdef FEATURE_SPARKLE
        return YES;
    #else
        return NO;
    #endif
}


@end
