//
//  AppController.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;
@import JSDNuVFramework;

@class MGSUserDefaultsController;

NS_ASSUME_NONNULL_BEGIN


/**
 *  This main application controller handles application startup, Preference, and target conditional
 *  differences such as Sparkle vs. non-sparkle. In more modern terms, we're also the AppDelegate,
 *  having been set as NSApplication's delegate in MainMenu.xib.
 */
@interface AppController : NSObject <NSApplicationDelegate> 


#pragma mark - Preferences Window


/**
 *  Show the Preferences window.
 */
- (IBAction)showPreferences:(id)sender;


/**
 * Reset hiding the Preferences pane.
 */
- (IBAction)resetHiddenPrefs:(id)sender;


#pragma mark - About… Window


/**
 *  Show the About window.
 */
- (IBAction)showAboutWindow:(id)sender;


#pragma mark - Singleton Bindings Accessors


/**
 * Providings binding access to the global Fragaria defaults controller.
 */
@property (nonatomic, assign, readonly) MGSUserDefaultsController *userDefaultsController;


/**
 *  Provide bindings access to the sharedDocumentController. It's best not to bind to its
 *  currentDocument items for anything other than global states because bindings are not
 *  changed when currentDocument changes.
 */
@property (nonatomic, assign, readonly) NSDocumentController *sharedDocumentController;


/**
 *  Provides bindings access to the sharedNuvServer.
 */
@property (nonatomic, assign, readonly) JSDNuVServer *sharedNuVServer;


#pragma mark - Features Management


/** Is AppleScript enabled?
 */
@property (nonatomic, assign, readonly) BOOL featureAppleScript;


/** Is the dual preview feature enabled?
 */
@property (nonatomic, assign, readonly) BOOL featureDualPreview;


/** Is the configuration export feature enabled?
 */
@property (nonatomic, assign, readonly) BOOL featureExportsConfig;


/** Is the RTF export feature enabled?
 */
@property (nonatomic, assign, readonly) BOOL featureExportsRTF;


/** Are Fragaria schemes enabled?
 */
@property (nonatomic, assign, readonly) BOOL featureFragariaSchemes;


/** Is Sparkle a feature?
 */
@property (nonatomic, assign, readonly) BOOL featureSparkle;



@end

NS_ASSUME_NONNULL_END
