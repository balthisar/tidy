//
//  PrefsValidatorViewController.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import <MASPreferences/MASPreferences.h>


/**
 *  A view controller to manage the preferences' miscellaneous options.
 */
@interface PrefsValidatorViewController : NSViewController <MASPreferencesViewController>


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
