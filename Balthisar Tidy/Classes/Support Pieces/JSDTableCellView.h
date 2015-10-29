/**************************************************************************************************

	JSDTableCellView

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  Simple NSTableCellView subclass that's just generic enough to handle a couple of cases:
 *
 *  - Default NSTextCell Handling
 *  - Handle a single NSPopUpButton
 *  - Handle an NSTextCell with an associated NSStepper
 *
 *  Also takes steps at instantiation to ensure that appearance is consistent with my
 *  expectations:
 *
 *  - PopUps are only visible when hovered.
 *  - Steppers are only visible when hovered.
 *
 *  Finally it observes NSUserDefaults in order to change its hover effect.
 */
@interface JSDTableCellView : NSTableCellView


/**
 *  Specifies whether or not controls in the cell are always drawn, or if
 *  they're only drawn when the mouse cursor hovers over them.
 */
@property (nonatomic, assign) BOOL usesHoverEffect;

/**
 *  An outlet to the cell's NSStepper.
 */
@property (nonatomic, weak) IBOutlet NSStepper *stepperControl;

/**
 *  An outlet to the cell's NSPopUpButton.
 */
@property (nonatomic, weak) IBOutlet NSPopUpButton *popupButtonControl;


@end
