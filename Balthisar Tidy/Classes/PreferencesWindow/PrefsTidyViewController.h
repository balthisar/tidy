//
//  PrefsTidyViewController.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import <MASPreferences/MASPreferencesViewController.h>


/**
 *  A view controller to manage the preferences' Tidy Options pane.
 */
@interface PrefsTidyViewController : NSViewController <MASPreferencesViewController>


/**
 * Indicates to the window controller whether this view can be widened.
 * This is complying with <MASPreferencesViewController>.
 */
@property (nonatomic, assign, readonly) BOOL hasResizableWidth;

/**
 * Indicates to the window controller whether this view can be heightened.
 * This is complying with <MASPreferencesViewController>.
 */
@property (nonatomic, assign, readonly) BOOL hasResizableHeight;

@end
