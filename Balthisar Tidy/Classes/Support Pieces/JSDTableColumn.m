/**************************************************************************************************

	JSDTableColumn.m

	implement |dataCellForRow| so that we can use different cells in any row of a table.

	FOR SOME REASON, you cannot implement this in IB -- you'll have to swap out the
	type in |awakeFromNib| in the controller that you use. See these methods to assist:

		initReplacingColumn:
		initReplacingColumnId:
		swapForTableColumn:


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
#import "JSDTableColumn.h"

@implementation JSDTableColumn : NSTableColumn


#pragma mark - initializers and deallocs


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initReplacingColumn:
		Initialize ourself and replace "aColumn" in its table.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initReplacingColumn:(NSTableColumn *)aColumn
{
	self = [super initWithIdentifier:[aColumn identifier]];
	if (self)
	{
		[self swapForTableColumn:aColumn];
	}
	return self;
}


#pragma mark - initializers and deallocs


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	swapForTableColumn:
		Convenience method that allows us to substitute
		ourself for an existing table column.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)swapForTableColumn:(NSTableColumn *)oldTableColumn
{
	// Get the tableview that the old column is part of.
	NSTableView *table = [oldTableColumn tableView];

	// If no table then abort.
	if (table == nil)
	{
		return;
	}

	// Copy the old column properties.
	[self setWidth:[oldTableColumn width]];
	[self setMinWidth:[oldTableColumn minWidth]];
	[self setMaxWidth:[oldTableColumn maxWidth]];
	[self setResizingMask:[oldTableColumn resizingMask]];
	[self setEditable:[oldTableColumn isEditable]];
	[self setHeaderCell:[oldTableColumn headerCell]];
	[self setDataCell:[oldTableColumn dataCell]];

	// Add self to the table.
	[table addTableColumn:self];
	
	// Put self (the new column) in the correct spot of the table.
	[table moveColumn:[[table tableColumns] indexOfObject:self] toColumn:[[table tableColumns] indexOfObject:oldTableColumn]];
	
	// Remove the old column.
	[table removeTableColumn:oldTableColumn];
}


#pragma mark - Dealing with cells


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dataCellForRow:
		Call the delegate of |tableView| (if it exists) for a
		special cell, otherwise use the default cell. This allows
		us to ask the delegate if we should use a special
		cell instead of the default text field.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)dataCellForRow:(int)row
{
	// Ensure there's a tableview and a delegate and that the row isn't -1,
	// otherwise return the standard result.
	if ( ([self tableView] == nil) || ([[self tableView] delegate] == nil) || (row == -1) )
	{
		return [super dataCellForRow:row];
	}

	// See if the selector exists, and if not then return the standard result.
	if ( ! [ [ [self tableView] delegate] respondsToSelector:@selector(tableColumn:customDataCellForRow:)] )
	{
		
		return [super dataCellForRow:row];
	}

	// Try getting the cell we want from the |tableView|'s delegate routine.
	id cell = [(id)[[self tableView] delegate] tableColumn:self customDataCellForRow:row];
	if (cell != nil)
	{
		return cell;
	}

	// Nothing there, so call the inherited method to get a default cell.
	return [super dataCellForRow:row];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	usefulCheckCell:
		Return a useful check box type NSButtonCell. This is
		simply a convenience for users of this class.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSCell *)usefulCheckCell
{
	NSButtonCell *myCell = [[NSButtonCell alloc] initTextCell: @""];
	[myCell setEditable: YES];
	[myCell setButtonType:NSSwitchButton];
	[myCell setImagePosition:NSImageOnly];
	[myCell setControlSize:NSSmallControlSize];
	return myCell;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	usefulRadioCell:
		Return a radio button type NSButtonCell. This is
		simply a convenience for users of this class.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSCell *)usefulRadioCell
{
	NSButtonCell *myCell = [[NSButtonCell alloc] initTextCell: @""];
	[myCell setEditable: YES];
	[myCell setButtonType:NSRadioButton];
	[myCell setImagePosition:NSImageOnly];
	[myCell setControlSize:NSSmallControlSize];
	return myCell;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	usefulPopUpCell:
		Return a popup menu type NSPopupButtonCell. This is
		simply a convenience for users of this class.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSCell *)usefulPopUpCell:(NSArray *)picks
{
	NSPopUpButtonCell *myCell = [[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO];
	[myCell setEditable: YES];
	[myCell setBordered:YES];
	[myCell addItemsWithTitles:picks];
	[myCell setControlSize:NSSmallControlSize];
	[myCell setFont:[NSFont menuFontOfSize:10]];
	return myCell;
}

@end