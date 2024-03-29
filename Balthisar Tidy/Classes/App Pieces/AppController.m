//
//  AppController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
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

@import JSDTidyFramework;

#import "TidyDocumentService.h"

#ifdef FEATURE_SPARKLE
#  import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface AppController ()


/* Nib stuff we want access to. */
@property (nonatomic, weak) IBOutlet NSMenuItem *menuCheckForUpdates;

@property (nonatomic, weak) IBOutlet NSMenu *menuHelp;
@property (nonatomic, weak) IBOutlet NSMenuItem *menuDownloadApplescripts;
@property (nonatomic, weak) IBOutlet NSView *viewDownloadApplescriptsMenuItem;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicatorDownloadApplescripts;


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


@end


#pragma mark - IMPLEMENTATION


@implementation AppController

@synthesize featureAppleScript = _featureAppleScript;
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

#if defined(TARGET_APP)
    self.featureAppleScript = NO;
    self.featureDualPreview =  NO;
    self.featureExportsConfig =  NO;
    self.featureExportsRTF =  NO;
    self.featureFragariaSchemes =  NO;
#else // TARAGET_PRO, TARGET_WEB
    self.featureAppleScript = YES;
    self.featureDualPreview = YES;
    self.featureExportsConfig = YES;
    self.featureExportsRTF = YES;
    self.featureFragariaSchemes = YES;
#endif
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


#pragma mark - Download Sample AppleScripts DMG


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * <NSURLSessionDelegate>
 *  Respond to progress in the download process.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    double percentCompleted = ((double)totalBytesWritten / (double)totalBytesExpectedToWrite) * 100;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.indicatorDownloadApplescripts.doubleValue = percentCompleted;
    });
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * <NSURLSessionDelegate>
 *  Respond to client-sider errors.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:JSDLocalizedString(@"download-scripts-incomplete-title", nil)];
            [alert setInformativeText:error.localizedDescription];
            [alert addButtonWithTitle:JSDLocalizedString(@"download-scripts-incomplete-cancel", nil)];
            [alert runModal];
        });
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * <NSURLSessionDelegate>
 *  Respond to finishing the download process.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    /* Restore the Help menu items back to normal. */
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSMenuItem *item in self.menuHelp.itemArray)
        {
            item.indentationLevel = item.indentationLevel - 1;
        }
        self.menuDownloadApplescripts.view = nil;
        [self.indicatorDownloadApplescripts stopAnimation:nil];
    });

    NSInteger httpStatus = ((NSHTTPURLResponse *)downloadTask.response).statusCode;

    if ( httpStatus != 200 )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:JSDLocalizedString(@"download-scripts-incomplete-title", nil)];
            [alert setInformativeText:[NSString stringWithFormat:JSDLocalizedString(@"download-scripts-status-code", nil),
                                       httpStatus,
                                       [NSHTTPURLResponse localizedStringForStatusCode:httpStatus]]];
            [alert addButtonWithTitle:JSDLocalizedString(@"download-scripts-incomplete-cancel", nil)];
            [alert runModal];
        });
    }
    else
    {
        NSString *fileName = downloadTask.response.suggestedFilename;
        
        NSFileManager *fm = [NSFileManager defaultManager];

        NSURL *downloadsURL = [fm URLForDirectory:NSDownloadsDirectory
                                         inDomain:NSUserDomainMask
                                appropriateForURL:nil
                                           create:YES
                                            error:nil];
        downloadsURL = [downloadsURL URLByAppendingPathComponent:fileName];

        NSError *fmError = nil;
        if (![fm moveItemAtURL:location toURL:downloadsURL error:&fmError])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:JSDLocalizedString(@"download-scripts-incomplete-title", nil)];
                [alert setInformativeText:fmError.localizedDescription];
                [alert addButtonWithTitle:JSDLocalizedString(@"download-scripts-incomplete-cancel", nil)];
                [alert runModal];
            });
        }
        else
        {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = JSDLocalizedString(@"download-scripts-complete-title", nil);
            notification.informativeText = [NSString stringWithFormat:JSDLocalizedString(@"download-scripts-complete-message", nil), fileName];
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - downloadAppleScriptsDMG:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)downloadAppleScriptsDMG:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"https://www.balthisar.com/files/AppleScriptsforTidy.dmg"];
    
    /*--------------------------------------------------*
     * Although the disk image files is small and we
     * could use an indeterminate progress indicator,
     * who knows who's on dialup. It's also the right
     * thing to do, and teaches me how to do it. Thus
     * we'll do this with delegates instead of simply
     * using a completion handler.
     *--------------------------------------------------*/

    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                             delegate:self
                                                        delegateQueue:nil];
    
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithURL:url];
    
    [downloadTask resume];
        
    /*--------------------------------------------------*
     * We'll just temporarily swap in an NSView with an
     * already activated progress indicator and disabled
     * menu item text, and then remove it when the
     * download completes. This avoids having to make a
     * subclass and track mouse movements and perform
     * menu item highlighting.
     *--------------------------------------------------*/

    for (NSMenuItem *item in self.menuHelp.itemArray)
    {
        item.indentationLevel = item.indentationLevel + 1;
    }
    self.menuDownloadApplescripts.view = self.viewDownloadApplescriptsMenuItem;
    [self.indicatorDownloadApplescripts startAnimation:nil];
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
 * @sharedNuVServer
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (JSDNuVServer *)sharedNuVServer
{
    return [JSDNuVServer sharedNuVServer];
}


#pragma mark - Features Management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @featureAppleScript
 *   We *must* have the plist contain both NSAppleScriptEnabled and
 *   OSAScriptingDefinition if we want the dictionary to be available
 *   to the script editor. Therefore we have to use a fake
 *   NSScriptSuiteRegistery if AppleScript is not supposed to be
 *   available. Because we set this property so early, we will
 *   start with the correct registry.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)featureAppleScript
{
    return _featureAppleScript;
}
- (void)setFeatureAppleScript:(BOOL)featureAppleScript
{
    _featureAppleScript = featureAppleScript;
    
    /*--------------------------------------------------*
     * Simply referencing the suite registry will
     * attempt to automatically load the SDEF's, but
     * the overriding class will prevent this. We will
     * load them manually in the test below.
     *--------------------------------------------------*/

    JSDScriptSuiteRegistry *registry = [JSDScriptSuiteRegistry sharedScriptSuiteRegistry];
    
    if (featureAppleScript)
    {
        [registry loadSuitesFromMainBundle];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:JSDKeyServiceHelperAllowsAppleScript];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:JSDKeyServiceHelperAllowsAppleScript];
    }
}


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


@end
