/**************************************************************************************************

	JSDTableViewDelegate.h

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  Protocol for JSDTableView providing delegates the opportunity to react to:
 *  - tableView:keyWasPressed:row:
 */
@protocol JSDTableViewDelegate <NSTableViewDelegate>

@optional

/**
 *  This delegate method will be called when a key is pressed in the table view (when a text field
 *  is not receiving input).
 *  @returns Returns YES if the key was handled.
 */
- (BOOL)tableView:(NSTableView *)aTableView keyWasPressed:(NSInteger)keyCode row:(NSInteger)rowIndex;

@end
