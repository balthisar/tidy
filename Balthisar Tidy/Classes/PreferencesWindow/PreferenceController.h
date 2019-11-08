//
//  PreferenceController.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import <MASPreferences/MASPreferences.h>


/**
 *  The main preference controller. Here we'll control the following:
 *
 *  - Handles the application preferences.
 *  - Implements class methods to be used before instantiation.
 *
 */
@interface PreferenceController : MASPreferencesWindowController


#pragma mark - Initialization

- (instancetype)init;


#pragma mark - Class Methods


/** Singleton accessor for this class.
 */
+ (instancetype)sharedPreferences;

/** An array of the tidy options that Balthisar Tidy supports.
 */
+ (NSArray*)optionsInEffect;


#pragma mark - Instance Methods


/** Registers Balthisar Tidy's defaults with macOS' defaults system.
 */
- (void)registerUserDefaults;

/** Mirror standardUserDefaults into the application group preferences.
 */
- (void)handleUserDefaultsChanged:(NSNotification*)note;


#pragma mark - Properties


/** Determines whether or not the Color Schemes panel should be available.
 */
@property (nonatomic, assign) BOOL hasSchemePanel;


#pragma mark - AppleScript stuff


/**
 *  Handles AppleScript `documentWindowIsInScreenshotMode` property,
 *  passed off to us from the NSApplication category that handles
 *  AppleScript.
 *
 *  @returns Indicates whether or not document windows are in screenshot
 *  mode or not (i.e., invisible so that popups and sheets can be
 *  captured).
 */
@property (nonatomic, assign) BOOL documentWindowIsInScreenshotMode;


@end
