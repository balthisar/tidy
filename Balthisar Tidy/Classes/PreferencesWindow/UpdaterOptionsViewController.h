//
//  UpdaterOptionsViewController.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import <MASPreferences/MASPreferencesViewController.h>


/**
 *  A view controller to manage the preferences' updater options.
 */
@interface UpdaterOptionsViewController : NSViewController <MASPreferencesViewController>


#pragma mark - Software Updater Pane Outlets

@property (weak) IBOutlet NSButton      *buttonAllowUpdateChecks;
@property (weak) IBOutlet NSButton      *buttonAllowSystemProfile;
@property (weak) IBOutlet NSPopUpButton *buttonUpdateInterval;
@property (weak) IBOutlet NSButton      *buttonAllowAutoUpdate;


#pragma mark - <MASPreferencesViewController>


/**
 * Indicates to the window controller whether this view can be widened.
 * This is complying with <MASPreferencesViewController>.
 */
@property (nonatomic, readonly) BOOL hasResizableWidth;

/**
 * Indicates to the window controller whether this view can be heightened.
 * This is complying with <MASPreferencesViewController>.
 */
@property (nonatomic, readonly) BOOL hasResizableHeight;


@end
