//
//  PreferenceController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "PreferenceController.h"
#import "CommonHeaders.h"

#import "DocumentAppearanceViewController.h"
#import "OptionListAppearanceViewController.h"
#import "OptionListViewController.h"
#import "MiscOptionsViewController.h"
#import "SavingOptionsViewController.h"
#import "ValidatorOptionsViewController.h"
#import "UpdaterOptionsViewController.h"
#import "FragariaEditorViewController.h"
#import "FragariaColorsViewController.h"

#import <Fragaria/Fragaria.h>
#import <FragariaDefaultsCoordinator/FragariaDefaultsCoordinator.h>

@import JSDTidyFramework;


#pragma mark - Category


@interface PreferenceController ()

@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *optionListViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *optionListAppearanceViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *documentAppearanceViewController;
@property (nonatomic, strong) FragariaBaseViewController <MASPreferencesViewController> *fragariaEditorViewController;
@property (nonatomic, strong) FragariaBaseViewController <MASPreferencesViewController> *fragariaColorsViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *savingOptionsViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *validatorOptionsViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *miscOptionsViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *updaterOptionsViewController;
@property (nonatomic, strong) NSViewController <MASPreferencesViewController> *proFeaturesViewController;

@end



#pragma mark - IMPLEMENTATION


@implementation PreferenceController
{
    NSUserDefaults *_mirroredDefaults;
}


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
    if ( (self = [super initWithViewControllers:@[]]) )
    {
        /*--------------------------------------------------*
         * Preferences Panes
         *--------------------------------------------------*/

        self.optionListViewController = [[OptionListViewController alloc] init];
        self.optionListAppearanceViewController = [[OptionListAppearanceViewController alloc] init];
        self.documentAppearanceViewController = [[DocumentAppearanceViewController alloc] init];
        self.fragariaEditorViewController = [[FragariaEditorViewController alloc] initWithController:[[MGSPrefsEditorPropertiesViewController alloc] init]];
        self.fragariaColorsViewController = [[FragariaColorsViewController alloc] initWithController:[[MGSPrefsColourPropertiesViewController alloc] init]];
        self.savingOptionsViewController = [[SavingOptionsViewController alloc] init];
        self.validatorOptionsViewController = [[ValidatorOptionsViewController alloc] init];
        self.miscOptionsViewController = [[MiscOptionsViewController alloc] init];

        [self addViewController:self.optionListViewController];
        [self addViewController:self.optionListAppearanceViewController];
        [self addViewController:self.documentAppearanceViewController];
        [self addViewController:self.fragariaEditorViewController];
        [self addViewController:self.savingOptionsViewController];
        [self addViewController:self.validatorOptionsViewController];
        [self addViewController:self.miscOptionsViewController];

#if defined(FEATURE_SPARKLE)
        self.updaterOptionsViewController = [[UpdaterOptionsViewController alloc] init];
        [self addViewController:self.updaterOptionsViewController];
#endif
        
        /*--------------------------------------------------*
         * Notifications
         *--------------------------------------------------*/
        
        /* Preferences Mirroring */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUserDefaultsChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:[NSUserDefaults standardUserDefaults]];
        
        _mirroredDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];
    }

    return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * + sharedPreferences
 *  Implement this class as a singleton.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (instancetype)sharedPreferences
{
    static PreferenceController *sharedMyPrefController = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{ sharedMyPrefController = [[self alloc] init]; });
    
    return sharedMyPrefController;
}


#pragma mark - MASPreferences Additions


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
* - addViewController:atIndex
*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)addViewController:(NSViewController <MASPreferencesViewController> *)viewController atIndex:(NSUInteger)index
{
    [self.viewControllers insertObject:viewController atIndex:index];
    [self.toolbar insertItemWithItemIdentifier:viewController.viewIdentifier atIndex:index];
    [self.toolbar validateVisibleItems];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
* - removeViewController:
*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)removeViewController:(NSViewController <MASPreferencesViewController> *)viewController
{
    NSUInteger iSelected = self.indexOfSelectedController;
    NSUInteger iRemove = [self.viewControllers indexOfObject:viewController];
    [self.viewControllers removeObject:viewController];
    [self.toolbar removeItemAtIndex:iRemove];
    if (iSelected == iRemove)
    {
        if (iSelected >= self.viewControllers.count-1)
        {
            [self selectControllerAtIndex:self.viewControllers.count - 1];
        }
        else
        {
            [self selectControllerAtIndex:iSelected];
        }
    }
}


#pragma mark - Class Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * + optionsInEffect
 *  Because JSDTidyModel pretty successfully integrates with the
 *  native `libtidy` without having to hardcode everything, it will
 *  use *all* tidy options if we let it. We don't want to use every
 *  tidy option, though, so here we will provide an array of tidy
 *  options via blacklisting the ones we do not support.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray*)optionsInEffect
{
    NSMutableArray *allOptions = [NSMutableArray arrayWithArray:[JSDTidyModel optionsBuiltInOptionList]];
    
    NSArray *blacklist = @[
        @"char-encoding",                // Balthisar Tidy handles this directly
        @"drop-font-tags",               // marked as `obsolete` in libtidy source code.
        @"error-file",                   // Balthisar Tidy handles this directly.
        @"gnu-emacs",                    // Balthisar Tidy handles this directly.
        @"hide-endtags",                 // Is a dupe of `omit-optional-tags`
        @"keep-time",                    // Balthisar Tidy handles this directly.
        @"language",                     // Not currently used; Mac OS X supports localization natively.
        @"markup",                       // Of course we always show markup! We're not a command line tool!
        @"mute",                         // Balthisar Tidy handles message muting directly.
        @"mute-id",                      // Balthisar Tidy handles message muting directly.
        @"output-bom",                   // Balthisar Tidy handles this directly.
        @"output-file",                  // Balthisar Tidy handles this directly.
        @"quiet",                        // Balthisar Tidy handles this directly.
        @"show-errors",                  // Balthisar Tidy handles this directly.
        @"show-filename",                // Balthisar Tidy handles this directly.
        @"show-info",                    // Balthisar Tidy handles this directly.
        @"show-warnings",                // Balthisar Tidy handles this directly.
        @"slide-style",                  // marked as `obsolete` in libtidy source code.
        @"split",                        // marked as `obsolete` in libtidy source code.
        @"write-back",                   // Balthisar Tidy handles this directly.
    ];
    
    [allOptions removeObjectsInArray:blacklist];
    
    return allOptions;
}


#pragma mark - Instance Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - registerUserDefaults
 *  Register all of the user defaults. Implemented as a CLASS
 *  method in order to keep this with the preferences controller.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)registerUserDefaults
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    /* Tidy Options */
    [JSDTidyModel addDefaultsToDictionary:defaultValues];
    
    /* Options List Appearance */
    [defaultValues setObject:@YES forKey:JSDKeyOptionsAlternateRowColors];
    [defaultValues setObject:@YES forKey:JSDKeyOptionsAreGrouped];
    [defaultValues setObject:@YES forKey:JSDKeyOptionsShowDescription];
    [defaultValues setObject:@NO  forKey:JSDKeyOptionsShowHumanReadableNames];
    [defaultValues setObject:@YES forKey:JSDKeyOptionsUseHoverEffect];
    
    /* Document Appearance */
    [defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentMessages];
    [defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentTidyOptions];
    [defaultValues setObject:@NO  forKey:JSDKeyShowNewDocumentSideBySide];
    [defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentSyncInOut];
    [defaultValues setObject:@NO  forKey:JSDKeyShowWrapMarginNot];
    [defaultValues setObject:@YES forKey:JSDKeyShouldOpenUntitledFile];
    
    /* File Saving Options */
    [defaultValues setObject:@(kJSDSaveAsOnly) forKey:JSDKeySavingPrefStyle];
    
    /* Advanced Options */
    [defaultValues setObject:@NO forKey:JSDKeyAllowMacOSTextSubstitutions];
    [defaultValues setObject:@NO forKey:JSDKeyFirstRunComplete];
    [defaultValues setObject:@"3.7.0" forKey:JSDKeyFirstRunCompleteVersion];
    [defaultValues setObject:@NO forKey:JSDKeyIgnoreInputEncodingWhenOpening];
    [defaultValues setObject:@NO forKey:JSDKeyAllowServiceHelperTSR];
    [defaultValues setObject:@NO forKey:JSDKeyAlreadyAskedServiceHelperTSR];
    [defaultValues setObject:@NO forKey:JSDKeyAnimationReduce];
    [defaultValues setObject:@(0.20f) forKey:JSDKeyAnimationStandardTime];
    
    /* Editor Options */
    [self configureEditorDefaults];
    
    /* Updates */
    [defaultValues setObject:@(86400) forKey:JSDSparkleDefaultIntervalKey];
    
    /* Sort Descriptor Defaults */
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"sortKey" ascending:YES];
    
    [defaultValues setObject:[NSArchiver archivedDataWithRootObject:@[descriptor]]
                      forKey:JSDKeyMessagesTableSortDescriptors];
    
    [defaultValues setObject:[NSArchiver archivedDataWithRootObject:@[descriptor]]
                      forKey:JSDKeyValidatorTableSortDescriptors];
    
    /* Web Previewiew Defaults */
    [defaultValues setObject:@(3.5f) forKey:JSDKeyWebPreviewThrottleTime];
    
    /* Document Validation Service Defaults */
    
    /* Make the default the W3C-hosted validator, so that we don't launch
     * our server without user permission the first time the application is
     * run.
     */
    [defaultValues setObject:@(JSDValidatorW3C) forKey:JSDKeyValidatorSelection];
    [defaultValues setObject:@(NO) forKey:JSDKeyValidatorAuto];
    [defaultValues setObject:@(120.0f) forKey:JSDKeyValidatorThrottleTime];
    [defaultValues setObject:@"https://validator.w3.org/nu" forKey:JSDKeyValidatorURL];
    
    [defaultValues setObject:@(YES) forKey:JSDKeyValidatorAutoBuiltIn];
    [defaultValues setObject:@(1.0f) forKey:JSDKeyValidatorThrottleBuiltIn];
    [defaultValues setObject:@(8888) forKey:JSDKeyValidatorBuiltInPort];
    
    [defaultValues setObject:@(NO) forKey:JSDKeyValidatorAutoW3C];
    [defaultValues setObject:@(120.0f) forKey:JSDKeyValidatorThrottleW3C];
    
    [defaultValues setObject:@(NO) forKey:JSDKeyValidatorAutoCustom];
    [defaultValues setObject:@(60.0f) forKey:JSDKeyValidatorThrottleCustom];
    [defaultValues setObject:@"https://checker.html5.org/" forKey:JSDKeyValidatorCustomServer];
    
    /* Other Defaults */
    [defaultValues setObject:@(NO) forKey:@"NSPrintHeaderAndFooter"];
    [defaultValues setObject:@(NO) forKey:JSDKeyServiceHelperAllowsAppleScript];
    
    /* Perform the registration. */
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleUserDefaultsChanged:
 *    Support App Groups so that our Service app and Action extensions
 *    have access to Balthisar Tidy's preferences. The strategy is to
 *    mirror standardUserDefaults to the App Group defaults, uni-
 *    directionally only. The user interface uses several instances
 *    of NSUserDefaultsController which cannot be tied to anything
 *    other than standardUserDefaults. Rather than subclass it and
 *    change all of Balthisar Tidy's source code to use a different
 *    defaults domain, we will use the same defaults as always but
 *    copy them out to the shared domain as needed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleUserDefaultsChanged:(NSNotification*)note
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSDictionary *localDict = [[defs dictionaryRepresentation] objectForKey:JSDKeyTidyTidyOptionsKey];
    [_mirroredDefaults setObject:localDict forKey:JSDKeyTidyTidyOptionsKey];
    [_mirroredDefaults setBool:[defs boolForKey:JSDKeyServiceHelperAllowsAppleScript] forKey:JSDKeyServiceHelperAllowsAppleScript];
    [_mirroredDefaults synchronize];
}


#pragma mark - Properties


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @hasSchemePanel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setHasSchemePanel:(BOOL)hasSchemePanel
{
    BOOL hasPanel = [self.viewControllers containsObject:self.fragariaColorsViewController];

    if (hasSchemePanel && !hasPanel)
    {
        [self addViewController:self.fragariaColorsViewController atIndex:4];
    }

    if (!hasSchemePanel && hasPanel)
    {
        [self removeViewController:self.fragariaColorsViewController];
    }
}
- (BOOL)hasSchemePanel
{
    return [self.viewControllers containsObject:self.fragariaColorsViewController];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @hasProPanel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setHasProPanel:(BOOL)hasProPanel
{
    BOOL hasPanel = [self.viewControllers containsObject:self.proFeaturesViewController];

    if (hasProPanel && !hasPanel)
    {
        [self addViewController:self.proFeaturesViewController];
    }

    if (!hasProPanel && hasPanel)
    {
        [self removeViewController:self.proFeaturesViewController];
    }
}
- (BOOL)hasProPanel
{
    return [self.viewControllers containsObject:self.proFeaturesViewController];
}


#pragma mark - Private


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - configureEditorDefaults
 *  Modern Fragaria has its own defaults coordination system that
 *  we will leverage via three sets of managed groups. The "Global"
 *  group manages user defaults for every FragariaView in the
 *  application. We will also use a sourceGroup and a tidyGroup to
 *  manage those few differences between those two views.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)configureEditorDefaults
{

    /* Fragaria's user defaults are registerd upon first access. */
    MGSUserDefaultsController *groupGlobal = [MGSUserDefaultsController sharedController];
    MGSUserDefaultsController *groupSource = [MGSUserDefaultsController sharedControllerForGroupID:JSDKeyTidyEditorSourceOptions];
    MGSUserDefaultsController *groupTidy = [MGSUserDefaultsController sharedControllerForGroupID:JSDKeyTidyEditorTidyOptions];

    /* The sourceGroup and tidyGroup will handle these items non-globally. */
    NSMutableSet *managedGroup = [[NSMutableSet alloc] initWithArray:@[
        MGSFragariaDefaultsLineWrap,
        MGSFragariaDefaultsLineWrapsAtPageGuide,
        MGSFragariaDefaultsShowsPageGuide,
        MGSFragariaDefaultsPageGuideColumn,
        MGSFragariaDefaultsHighlightsCurrentLine
    ]];

    /* The tidyGroup needs to also avoid sharing the page guide column application-wide. */
    NSMutableSet *managedTidy = [NSMutableSet setWithSet:managedGroup];
    [managedTidy removeObject:MGSFragariaDefaultsPageGuideColumn];

    /* The Global group will handle everything else. */
    NSMutableSet *managedGlobal = [[NSMutableSet alloc] initWithArray:[[MGSFragariaView defaultsDictionary] allKeys]];
    [managedGlobal minusSet:managedGroup];

    /* Let the controllers know which Fragaria properties they handle. */
    groupGlobal.managedProperties = managedGlobal;
    groupSource.managedProperties = managedGroup;
    groupTidy.managedProperties = managedTidy;

    /* And all of these properties should be persistent in user defaults. */
    groupGlobal.persistent = YES;
    groupSource.persistent = YES;
    groupTidy.persistent = YES;

    /* Now let the viewControllers know which groups they are managing.
     * When using MGSHybridUserDefaultsController Global is included.
     */
    if (self.fragariaEditorViewController)
    {
        MGSPrefsEditorPropertiesViewController *controller = (MGSPrefsEditorPropertiesViewController*)self.fragariaEditorViewController.embeddedController;
        controller.userDefaultsController = [MGSHybridUserDefaultsController sharedControllerForGroupID:JSDKeyTidyEditorSourceOptions];
    }

    if (self.fragariaColorsViewController)
    {
        MGSPrefsColourPropertiesViewController *controller = (MGSPrefsColourPropertiesViewController*)self.fragariaColorsViewController.embeddedController;
        controller.userDefaultsController = [MGSHybridUserDefaultsController sharedControllerForGroupID:JSDKeyTidyEditorSourceOptions];
    }
}


@end
