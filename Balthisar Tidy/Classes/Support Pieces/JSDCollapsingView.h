//
//  JSDCollapsingView.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  A class providing an NSView that hides itself via constraints, coordinating
 *  view sizes with the host window.
 */
@interface JSDCollapsingView : NSView


/**
 *  Provides a panel number so that users can identify whether this view
 *  should be shown or hidding, like a tag.
 */
@property (nonatomic, assign, readwrite) IBInspectable NSInteger panelNumber;


/**
 *  The constraint priority to set when hiding the view (a high priority).
 */
@property (nonatomic, assign, readwrite) IBInspectable NSInteger priorityHidden;


/**
 *  Shows/Hides the view via its internal constraint.
 */
@property (nonatomic, assign, readwrite, getter=isCollapsed) IBInspectable BOOL collapsed;


/**
 *  Provides the original frame rectangle before the view is collapsed
 */
@property (nonatomic, assign, readonly) NSRect originalFrame;


@end
