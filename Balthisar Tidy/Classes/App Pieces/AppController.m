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
#import "JSDScriptSuiteRegistry.h"

#import "PreferenceController.h"

#import <DCOAboutWindow/DCOAboutWindowController.h>
#import <Fragaria/Fragaria.h>
#import <FragariaDefaultsCoordinator/FragariaDefaultsCoordinator.h>

#import <RMStoreframework/RMStore.h>

@import JSDTidyFramework;

#import "TidyDocumentService.h"

#ifdef FEATURE_SPARKLE
#  import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface AppController ()


/* Nib stuff we want access to. */
@property (nonatomic, weak) IBOutlet NSMenuItem *menuCheckForUpdates;
@property (nonatomic, weak) IBOutlet NSMenuItem *menuPreferencesAlternate;


#if defined(FEATURE_SPARKLE)
/* And of course, we only need this if this is a Sparkle build. */
@property (nonatomic, strong) SPUStandardUpdaterController *updater;
#endif

/* Redeclare this as all readwrite.*/
@property (nonatomic, assign, readwrite) BOOL featureAppleScript;
@property (nonatomic, assign, readwrite) BOOL featureDualPreview;
@property (nonatomic, assign, readwrite) BOOL featureExportsConfig;
@property (nonatomic, assign, readwrite) BOOL featureExportsRTF;
@property (nonatomic, assign, readwrite) BOOL featureFragariaSchemes;
@property (nonatomic, assign, readwrite) BOOL featureSparkle;

#if defined(TARGET_PRO)
@property (nonatomic, assign, readwrite) BOOL purchasedPro;
@property (nonatomic, assign, readwrite) BOOL grandfatheredPro;
#endif


@end


#pragma mark - IMPLEMENTATION


@implementation AppController

@synthesize featureFragariaSchemes = _featureFragariaSchemes;


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * + initialize
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)initialize
{
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
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = (id<NSUserNotificationCenterDelegate>)self;
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
 * - applicationWillFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    /*--------------------------------------------------*
     * When the app is initialized pass off registering
     * of the user defaults to `PreferenceController`.
     * This must occur before any documents open and
     * pretty much before we do anything else with
     * User Defaults.
     *--------------------------------------------------*/

    [[PreferenceController sharedPreferences] registerUserDefaults];


    /*--------------------------------------------------*
     * RECEIPT VALIDATION AND FEATURES CHECKING *STUB*
     *--------------------------------------------------*/

#if defined(TARGET_PRO)
//    [self doStoreStuff];
    self.grandfatheredPro = YES;
#endif

#if defined(TARGET_PRO)
    self.featureAppleScript = self.purchasedPro || self.grandfatheredPro;
    self.featureDualPreview =  self.purchasedPro || self.grandfatheredPro;
    self.featureExportsConfig =  self.purchasedPro || self.grandfatheredPro;
    self.featureExportsRTF =  self.purchasedPro || self.grandfatheredPro;
    self.featureFragariaSchemes =  self.purchasedPro || self.grandfatheredPro;
#else
    self.featureAppleScript = NO;
    self.featureDualPreview = NO;
    self.featureExportsConfig = NO;
    self.featureExportsRTF = NO;
    self.featureFragariaSchemes = NO;
#endif


    /*--------------------------------------------------*
     * We *must* have both NSAppleScriptEnabled and
     * OSAScriptingDefinition if we want the dictionary
     * to be available to the script editor. Therefore
     * we have to use a fake NSScriptSuiteRegistery if
     * AppleScript is not supposed to be available.
     *--------------------------------------------------*/
    if (self.featureAppleScript)
    {
        [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
    }
    else
    {
        [JSDScriptSuiteRegistry sharedScriptSuiteRegistry];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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
     * Target-specific settings.
     *--------------------------------------------------*/

#if defined(FEATURE_SPARKLE)
    self.featureSparkle = YES;
    self.updater = [[SPUStandardUpdaterController alloc] initWithUpdaterDelegate:nil userDriverDelegate:nil];
    [[self menuCheckForUpdates] setTarget:self.updater];
    [[self menuCheckForUpdates] setAction:@selector(checkForUpdates:)];
#endif

#if defined(TARGET_PRO)
    self.menuPreferencesAlternate.alternate = YES;
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
    [[PreferenceController sharedPreferences] showWindow:sender];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - resetHiddenPrefs:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)resetHiddenPrefs:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:JSDKeyProFeaturesHidePreferencePanel];
    [PreferenceController sharedPreferences].hasProPanel = YES;
}


#pragma mark - Download Sample AppleScripts DMG


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - downloadAppleScriptsDMG:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)downloadAppleScriptsDMG:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"https://www.balthisar.com/files/AppleScriptsforTidy.dmg"];
    
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:JSDLocalizedString(@"download-scripts-incomplete-title", nil)];
                [alert setInformativeText:error.localizedDescription];
                [alert addButtonWithTitle:JSDLocalizedString(@"download-scripts-incomplete-cancel", nil)];
                
                NSInteger button = [alert runModal];
                if (button == NSAlertFirstButtonReturn)
                {
                    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
                    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
                }
            });
        }
        else
        {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSURL *downloadsURL = [fm URLForDirectory:NSDownloadsDirectory
                                             inDomain:NSUserDomainMask
                                    appropriateForURL:nil
                                               create:YES
                                                error:nil];
        
            downloadsURL = [downloadsURL URLByAppendingPathComponent:@"AppleScriptsforTidy.dmg"];

            dispatch_async(dispatch_get_main_queue(), ^{
                [data writeToURL:downloadsURL atomically:YES];
            });
            
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = JSDLocalizedString(@"download-scripts-complete-title", nil);
            notification.informativeText = JSDLocalizedString(@"download-scripts-complete-message", nil);
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
    }];
        
    [downloadTask resume];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
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
 * @featureFragariaSchemes
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureFragariaSchemes
{
    return _featureFragariaSchemes;
}
- (void)setFeatureFragariaSchemes:(BOOL)featureFragariaSchemes
{
    _featureFragariaSchemes = featureFragariaSchemes;
    [PreferenceController sharedPreferences].hasSchemePanel = featureFragariaSchemes;
}


#pragma mark - App Store Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - doStoreStuff
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)doStoreStuff
{
    NSArray *_products = @[@"com.balthisar.tidy.iap.pro", @"com.balthisar.tidy.iap.fake"];
    
    [[RMStore defaultStore] requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers)
     {
        NSLog(@"%@", @"Success\n-------");
        for ( SKProduct *product in products )
        {
            NSLog(@"   productIdentifier: %@", product.productIdentifier);
            NSLog(@"      localizedTitle: %@", product.localizedTitle);
            NSLog(@"localizedDescription: %@", product.localizedDescription);
            NSLog(@"      contentVersion: %@", product.contentVersion);
            NSLog(@"               price: %@", product.price);
            NSLog(@"         priceLocale: %@", product.priceLocale.localeIdentifier);
        }
        NSLog(@"%@", @"However, these ID's are invalid:");
        NSLog(@"%@", invalidProductIdentifiers);
    } failure:^(NSError *error) {
        NSLog(@"Error = %@", error);
        }];
}

- (IBAction)doBuySomething:(id)sender
{
    [[RMStore defaultStore] addPayment:@"com.balthisar.tidy.iap.pro" success:^(SKPaymentTransaction *transaction)
    {
        NSLog(@"%@", @"Success with addPayment.");
    } failure:^(SKPaymentTransaction *transaction, NSError *error)
    {
        NSLog(@"%@", @"Payment Transaction Failed");
        NSLog(@"Reason: %@", error.localizedDescription);

    }];
}


@end
