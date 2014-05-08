/**************************************************************************************************

	JSDTableCellView.h

	Simple NSTableCellView subclass that's just generic enough to handle a couple of cases:

		- Default NSTextCell Handling
		- Handle a single NSPopUpButton
		- Handle an NSTextCell with an associated NSStepper
 
	Also takes steps at instantiation to ensure that appearance is consistent with my
	expectations:
 
		- PopUps are only visible when hovered.
		- Steppers are only visible when hovered.
	

	The MIT License (MIT)

	Copyright (c) 2001 to 2013 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import <Cocoa/Cocoa.h>

@class JSDTableView;


/**
	Implements special behavior for a couple of different cell types by adding
	a couple of properties and some behaviours for those properties. Remember
	that as a descdendent of NSTableCell View, that objectValue, textField,
	etc. are all already implemented.
 */
@interface JSDTableCellView : NSTableCellView


@property (nonatomic, assign) BOOL usesHoverEffect;

/** If the view has a stepper, this outlet provides access to it. */
@property (nonatomic, weak) IBOutlet NSStepper *stepperControl;

/** If the view has a popup button, this outlet provides access to it. */
@property (nonatomic, weak) IBOutlet NSPopUpButton *popupButtonControl;

/** Populate this array in order to show options in the popup menus. */
@property (nonatomic, strong) NSArray *popupButtonArray;

@end
