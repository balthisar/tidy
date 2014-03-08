/**************************************************************************************************

	JSDTableColumn.h

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


#pragma mark - JSDTableColumn Class


@interface JSDTableColumn : NSTableColumn

- (id)initReplacingColumn:(NSTableColumn *)aColumn;		// Initializer that replaces an existing column with this one.

- (id)dataCellForRow:(int)row;							// Calls the delegate for each column to get the data cell.

- (void)swapForTableColumn:(NSTableColumn *)aColumn;	// Swaps this instance of JSDTableColumn for an existing one.

- (NSCell *)usefulCheckCell;							// Returns an instance of a NSButtonCell as a check box.
- (NSCell *)usefulRadioCell;							// Returns an instance of a NSButtonCell as a radio button.
- (NSCell *)usefulPopUpCell:(NSArray *)picks;			// Returns an instance of a NSPopupButtonCell as a pop-up list.

@end


#pragma mark - JSDTableColumn Protocol


@protocol JSDTableColumnProtocol <NSObject>

@required

- (id)tableColumn:(JSDTableColumn *)aTableColumn customDataCellForRow:(NSInteger)row;

@end

