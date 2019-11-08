//
//  ProFeaturesViewController.h
//
//  Copyright © 2019 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import <MASPreferences/MASPreferencesViewController.h>


/**
 *  A view controller to manage the preferences' file saving behavior options.
 */
@interface ProFeaturesViewController : NSViewController <MASPreferencesViewController>


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
