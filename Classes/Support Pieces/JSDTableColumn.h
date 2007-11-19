/***************************************************************************************
    JSDTableColumn.h

    implement dataCellForRow so that we can use different cells in any row of a table.
    
    FOR SOME REASON, you cannot implement this in IB -- you'll have to swap out the
    type in awakeFromNib in the controller that you use. See these methods to assist:
        initReplacingColumn:
	initReplacingColumnId:
	swapForTableColumn:
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>

@interface JSDTableColumn : NSTableColumn {

}

- (id)initReplacingColumn:(NSTableColumn *)aColumn;	// initializer that replaces an existing column with this one.

- (id)dataCellForRow:(int)row;				// calls the delegate for each column to get the data cell.
- (void)swapForTableColumn:(NSTableColumn *)aColumn;	// swaps this instance of JSDTableColumn for an existing one.

-(NSCell *)usefulCheckCell;
-(NSCell *)usefulRadioCell;
-(NSCell *)usefulPopUpCell:(NSArray *)picks;

@end
