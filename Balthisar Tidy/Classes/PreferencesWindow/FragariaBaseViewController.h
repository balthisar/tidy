/**************************************************************************************************

	FragariaBaseViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import "MASPreferencesViewController.h"


/**
 *  A view controller for Preference panes that uses an embedded subview
 *  and its own controller.
 */
@interface FragariaBaseViewController : NSViewController <MASPreferencesViewController>


#pragma mark - MASPreferences Properties
/** @name MASPreferences Properties */


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


#pragma mark - Embedded Controller Properties
/** @name Embedded Controller Properties */


/**
 *  Initializes the view controller with an embedded controller.
 */
- (instancetype) initWithController:(NSViewController*)embeddedController;

/**
 *  Indicates the NSViewController that should be embedded into this
 *  controller's view.
 */
@property (nonatomic, strong) NSViewController *embeddedController;

/**
 *  Indicates the NSView to fill with the embeddedController's view.
 */
@property (nonatomic, assign) IBOutlet NSView *embeddedContainer;

/**
 *  Indicates the top-level item of the embedded view.
 */
@property (nonatomic, assign) IBOutlet NSView *embeddedView;


@end
