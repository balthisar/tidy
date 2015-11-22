/**************************************************************************************************

	PreferenceController
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "PreferenceController.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"

#import "DocumentAppearanceViewController.h"
#import "OptionListAppearanceViewController.h"
#import "OptionListViewController.h"
#import "MiscOptionsViewController.h"
#import "SavingOptionsViewController.h"
#import "UpdaterOptionsViewController.h"
#import "FragariaEditorViewController.h"
#import "FragariaColorsViewController.h"

#import <Fragaria/Fragaria.h>


#pragma mark - Category


@interface PreferenceController ()

@property (nonatomic, strong) NSViewController *optionListViewController;
@property (nonatomic, strong) NSViewController *optionListAppearanceViewController;
@property (nonatomic, strong) NSViewController *documentAppearanceViewController;
@property (nonatomic, strong) FragariaBaseViewController *fragariaEditorViewController;
@property (nonatomic, strong) FragariaBaseViewController *fragariaColorsViewController;
@property (nonatomic, strong) NSViewController *savingOptionsViewController;
@property (nonatomic, strong) NSViewController *miscOptionsViewController;
@property (nonatomic, strong) NSViewController *updaterOptionsViewController;

@end



#pragma mark - IMPLEMENTATION


@implementation PreferenceController
{
	NSUserDefaults *_mirroredDefaults;
}


#pragma mark - Class Methods


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
	self.optionListViewController = [[OptionListViewController alloc] init];
	self.optionListAppearanceViewController = [[OptionListAppearanceViewController alloc] init];
	self.documentAppearanceViewController = [[DocumentAppearanceViewController alloc] init];
	self.fragariaEditorViewController = [[FragariaEditorViewController alloc] initWithController:[[MGSPrefsEditorPropertiesViewController alloc] init]];
	self.savingOptionsViewController = [[SavingOptionsViewController alloc] init];
	self.miscOptionsViewController = [[MiscOptionsViewController alloc] init];
	
#if defined(FEATURE_SPARKLE) || defined(FEATURE_FAKE_SPARKLE)
	self.updaterOptionsViewController = [[UpdaterOptionsViewController alloc] init];
#endif
	
#if defined(FEATURE_SUPPORTS_THEMES)
	self.fragariaColorsViewController = [[FragariaColorsViewController alloc] initWithController:[[MGSPrefsColourPropertiesViewController alloc] init]];
#endif
	
	NSArray *controllers = @[self.optionListViewController,
							 self.optionListAppearanceViewController,
							 self.documentAppearanceViewController,
							 self.fragariaEditorViewController];
	
#if defined(FEATURE_SUPPORTS_THEMES)
	controllers = [controllers arrayByAddingObjectsFromArray:@[self.fragariaColorsViewController]];
#endif
	
	controllers = [controllers arrayByAddingObjectsFromArray:@[self.savingOptionsViewController,
															   self.miscOptionsViewController]];
	
	
#if defined(FEATURE_SPARKLE) || defined(FEATURE_FAKE_SPARKLE)
	controllers = [controllers arrayByAddingObjectsFromArray:@[self.updaterOptionsViewController]];
#endif
	
	
    self = [super initWithViewControllers:controllers];

    /* Handle Preferences Mirroring -- @NOTE: only on OS X 10.9 and above. */
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_9)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUserDefaultsChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:[NSUserDefaults standardUserDefaults]];
        
        _mirroredDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];
    }


	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + sharedPreferences
    Implement this class as a singleton.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (id)sharedPreferences
{
    static PreferenceController *sharedMyPrefController = nil;
	
    static dispatch_once_t onceToken;
	
    dispatch_once(&onceToken, ^{ sharedMyPrefController = [[self alloc] init]; });
	
    return sharedMyPrefController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + optionsInEffect
    Because JSDTidyModel pretty successfully integrates with the
    native `libtidy` without having to hardcode everything, it
    will use *all* tidy options if we let it. We don't want
    to use every tidy option, though, so here we will provide
    an array of tidy options that we will support.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray*)optionsInEffect
{
	/*
		To better support new libtidy versions, we're going to
		start blacklist options instead of the previous approach
		of whitelisting.
	 */
	
	NSMutableArray *allOptions = [NSMutableArray arrayWithArray:[JSDTidyModel optionsBuiltInOptionList]];
	
	NSArray *blacklist = @[
						   @"char-encoding",                // Balthisar Tidy handles this directly
						   @"doctype-mode",                 // Read-only; should use `doctype`.
						   @"drop-font-tags",               // marked as `obsolete` in libtidy source code.
						   @"error-file",                   // Balthisar Tidy handles this directly.
						   @"gnu-emacs",                    // Balthisar Tidy handles this directly.
						   @"gnu-emacs-file",               // Balthisar Tidy handles this directly.
						   @"hide-endtags",                 // Is a dupe of `omit-optional-tags`
						   @"keep-time",                    // Balthisar Tidy handles this directly.
						   @"language",                     // Not currently used; Mac OS X supports localization natively.
						   @"output-bom",                   // Balthisar Tidy handles this directly.
						   @"output-file",                  // Balthisar Tidy handles this directly.
						   @"quiet",                        // Balthisar Tidy handles this directly.
						   @"show-errors",                  // Balthisar Tidy handles this directly.
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
  - registerUserDefaults
    Register all of the user defaults. Implemented as a CLASS
    method in order to keep this with the preferences controller.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)registerUserDefaults
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	/* Tidy Options */
	[JSDTidyModel addDefaultsToDictionary:defaultValues];

	/** Options List Appearance */
	[defaultValues setObject:@YES forKey:JSDKeyOptionsAlternateRowColors];
	[defaultValues setObject:@YES forKey:JSDKeyOptionsAreGrouped];
	[defaultValues setObject:@YES forKey:JSDKeyOptionsShowDescription];
	[defaultValues setObject:@NO  forKey:JSDKeyOptionsShowHumanReadableNames];
	[defaultValues setObject:@YES forKey:JSDKeyOptionsUseHoverEffect];

	/** Document Appearance */
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentMessages];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentTidyOptions];
	[defaultValues setObject:@NO  forKey:JSDKeyShowNewDocumentSideBySide];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentSyncInOut];
    [defaultValues setObject:@NO forKey:JSDKeyShowWrapMarginNot];

	/* File Saving Options */
	[defaultValues setObject:@(kJSDSaveAsOnly) forKey:JSDKeySavingPrefStyle];

	/* Advanced Options */
	[defaultValues setObject:@NO forKey:JSDKeyAllowMacOSTextSubstitutions];
	[defaultValues setObject:@NO forKey:JSDKeyFirstRunComplete];
	[defaultValues setObject:@NO forKey:JSDKeyIgnoreInputEncodingWhenOpening];
	[defaultValues setObject:@NO forKey:JSDKeyAllowServiceHelperTSR];
	[defaultValues setObject:@NO forKey:JSDKeyAlreadyAskedServiceHelperTSR];

	/* Editor Options */
	[self configureEditorDefaults];

	/* Updates */
	// none - handled by Sparkle

	/* Sort Descriptor Defaults */
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"locationString" ascending:YES];
	[defaultValues setObject:[NSArchiver archivedDataWithRootObject:@[descriptor]]
					  forKey:JSDKeyMessagesTableSortDescriptors];

	/* Other Defaults */
	[defaultValues setObject:@NO  forKey:@"NSPrintHeaderAndFooter"];

	/* Perform the registration. */
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - configureEditorDefaults
    Modern Fragaria has its own defaults coordination system that
    we will leverage via three sets of managed groups. The "Global"
    group manages user defaults for every FragariaView in the
    application. We will also use a sourceGroup and a tidyGroup to
    manage those few differences between those two views.
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

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - handleUserDefaultsChanged:
    Support App Groups so that our Service app and Action extensions
    have access to Balthisar Tidy's preferences. The strategy is to
    mirror standardUserDefaults to the App Group defaults, uni-
    directionally only. The user interface uses several instances
    of NSUserDefaultsController which cannot be tied to anything
    other than standardUserDefaults. Rather than subclass it and
    change all of Balthisar Tidy's source code to use a different
    defaults domain, we will use the same defaults as always but
    copy them out to the shared domain as needed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleUserDefaultsChanged:(NSNotification*)note
{
	NSDictionary *localDict = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:JSDKeyTidyTidyOptionsKey];
	[_mirroredDefaults setObject:localDict forKey:JSDKeyTidyTidyOptionsKey];
	[_mirroredDefaults synchronize];
}

@end
