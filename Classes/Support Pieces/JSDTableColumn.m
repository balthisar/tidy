/***************************************************************************************
    JSDTableColumn.m

    implement dataCellForRow so that we can use different cells in any row of a table.
    
    FOR SOME REASON, you cannot implement this in IB -- you'll have to swap out the
    type in awakeFromNib in the controller that you use. You can use the method
    swapForTableColumn: for this purpose.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "JSDTableColumn.h"

@implementation JSDTableColumn : NSTableColumn

/********************************************************************
    initReplacingColumn:
    initialize ourself and replace "aColumn" in its table.
*********************************************************************/
- (id)initReplacingColumn:(NSTableColumn *)aColumn {
    if ([super initWithIdentifier:[aColumn identifier]]) {
        [self swapForTableColumn:aColumn];
    }
    return self;
} // initReplacingColumn


/********************************************************************
    dataCellForRow:
    we're going to call the delegate for a cell, if one exists.
*********************************************************************/
- (id)dataCellForRow:(int)row {

    // make sure there's a tableview and a delegate and that the row isn't -1.
    if ( ([self tableView] == nil) || ([[self tableView] delegate] == nil) || (row == -1) )
        return [super dataCellForRow:row];     

    // see if the routine exists
    if ( ! [ [ [self tableView] delegate] respondsToSelector:@selector(tableColumn:customDataCellForRow:)] )
        return [super dataCellForRow:row];
        
    // try getting the cell we want from the delegate routine -- ignore the compiler warning.
    id cell = [[[self tableView] delegate] tableColumn:self customDataCellForRow:row];
    if (cell != nil)
        return cell;				// not nil, so return what we got.

     return [super dataCellForRow:row];		// nothing there, so call the inherited method.
} // dataCellForRow


/********************************************************************
    swapForTableColumn:
    convenience method that allows us to substitute ourself for
    an existing table column.
*********************************************************************/
- (void)swapForTableColumn:(NSTableColumn *)oldTableColumn {
    NSTableView *table = [oldTableColumn tableView];	    // get the tableview the old column is part of
    if (table == nil)				    // do nothing if there's no table
        return;
        
    // copy the old column properties.
    [self setWidth:[oldTableColumn width]];
    [self setMinWidth:[oldTableColumn minWidth]];
    [self setMaxWidth:[oldTableColumn maxWidth]];
    [self setResizable:[oldTableColumn isResizable]];
    [self setEditable:[oldTableColumn isEditable]];
    [self setHeaderCell:[oldTableColumn headerCell]];
    [self setDataCell:[oldTableColumn dataCell]];
    
    // Swap table column
    [table addTableColumn:self];
    // put the new column in the correct spot
    [table moveColumn:[[table tableColumns] indexOfObject:self] toColumn:[[table tableColumns] indexOfObject:oldTableColumn]];
    // remove the old column -- we know it's position was i
    [table removeTableColumn:oldTableColumn];
} // swapForTableColumn


/********************************************************************
    usefulCheckCell:
    return a useful cell type.
*********************************************************************/
-(NSCell *)usefulCheckCell {
    NSButtonCell *myCell = [[[NSButtonCell alloc] initTextCell: @""] autorelease];
    [myCell setEditable: YES];
    [myCell setButtonType:NSSwitchButton];
    [myCell setImagePosition:NSImageOnly];
    [myCell setControlSize:NSSmallControlSize];
    return myCell;
} // usefulCheckCell;


/********************************************************************
    usefulRadioCell:
    return a useful cell type.
*********************************************************************/
-(NSCell *)usefulRadioCell {
    NSButtonCell *myCell =  [[[NSButtonCell alloc] initTextCell: @""] autorelease];
    [myCell setEditable: YES];
    [myCell setButtonType:NSRadioButton];
    [myCell setImagePosition:NSImageOnly];
    [myCell setControlSize:NSSmallControlSize];
    return myCell;
} // usefulRadioCell


/********************************************************************
    usefulPopUpCell:
    return a useful cell type.
*********************************************************************/
-(NSCell *)usefulPopUpCell:(NSArray *)picks {
    NSPopUpButtonCell *myCell =  [[[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO] autorelease];
    [myCell setEditable: YES];
    [myCell setBordered:YES];
    [myCell addItemsWithTitles:picks];
    [myCell setControlSize:NSSmallControlSize];
    [myCell setFont:[NSFont menuFontOfSize:10]];
    return myCell;
} // usefulPopCell

@end