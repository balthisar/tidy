//
//  PrefsTidyOptionsViewController.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import <MASPreferences/MASPreferencesViewController.h>


/**
 *  A view controller to manage the preferences' Tidy options list default appearance options.
 */
@interface PrefsTidyOptionsViewController : NSViewController <MASPreferencesViewController>


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
