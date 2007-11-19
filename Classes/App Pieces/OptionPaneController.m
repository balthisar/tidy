/***************************************************************************************
    OptionPaneController.h -- part of Balthisar Tidy

    The main controller for the multi-use option pane. implemented separately for
        o use on a document window
        o use on the preferences window
 ***************************************************************************************/

#import "OptionPaneController.h"
#import "JSDTableColumn.h"

@implementation OptionPaneController


/********************************************************************
    init - designated initializer
    load the bundle so the view can be drawn.
*********************************************************************/
-(id)init {
    if ([super init]) {
        [NSBundle loadNibNamed:@"OptionPane" owner:self];
        tidyProcess = [[JSDTidyDocument alloc] init];
        // get our options list and exception list (items to treat as string regardless of tidylib definition)
        optionsInEffect = [[NSArray arrayWithArray:[JSDTidyDocument loadConfigurationListFromResource:@"optionsInEffect" ofType:@"txt"]] retain];
        optionsExceptions = [[NSArray arrayWithArray:[JSDTidyDocument loadConfigurationListFromResource:@"optionsTypesExceptions" ofType:@"txt"]] retain];
        
        // create a custom column for the NSTableView -- the table will retain and control it.
        [[JSDTableColumn alloc] initReplacingColumn:[theTable tableColumnWithIdentifier:@"check"]];
    } // if
    return self;
} // init

/*********************************************************************
    dealloc
    our destructor -- get rid of stuff
**********************************************************************/
- (void)dealloc
{   
    [tidyProcess release];
    [optionsInEffect release];
    [optionsExceptions release];
    [super dealloc];
}

/********************************************************************
    getView
    return theView so that it can be made a subview in another
    window.
*********************************************************************/
-(NSView *)getView {
    return myView;
} // getView

/********************************************************************
    putViewIntoView
    put the view of this controller into theView
*********************************************************************/
-(void)putViewIntoView:(NSView *)dstView {
    // remove all subviews -- should only be one or zero, but let's be safe.
    NSEnumerator *enumerator = [[dstView subviews] objectEnumerator];
    NSView *trash;
    while (trash = [enumerator nextObject])
        [trash removeFromSuperview];
    // and put in the view
    [dstView addSubview:myView];
    [theTable reloadData];				// this DOES happen automatically, but the scroll bars don't initially appear.
    [theTable selectRow:0 byExtendingSelection:NO]; 	// this SHOULD happen automatically, but doesn't for some reason.
}


/********************************************************************
    tableViewSelectionDidChange:
        we arrived here by virtue of this controller class being the
        delegate of the table. Whenever the selection changes
        we're going to put up a helpful hint of what the selection is.
*********************************************************************/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    // get the description of the selected row.
    if ([aNotification object] == theTable)
        [theDescription setStringValue:NSLocalizedString([optionsInEffect objectAtIndex:[theTable selectedRow]], nil)];
} // tableViewSelectionDidChange

/********************************************************************
    numberOfRowsInTableView
    we're here because we're the datasource of the tableview.
    We need to specify how many items are in the table view.
*********************************************************************/
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [optionsInEffect count];
} // numberOfRowsInTableView


/********************************************************************
    tableView:objectValueForTableColumn:row
    we're here because we're the datasource of the tableview.
    We need to specify what to show in the row/column.
*********************************************************************/
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    // get the id for the option at this row
    TidyOptionId optId = [JSDTidyDocument optionIdForName:[optionsInEffect objectAtIndex:rowIndex]]; 

    // handle returning the name of the option.
    if ([[aTableColumn identifier] isEqualToString:@"name"])
        return [optionsInEffect objectAtIndex:rowIndex];

    // handle the value column of the option
    if ([[aTableColumn identifier] isEqualToString:@"check"])
        // if we're working on Encoding, then return the INDEX in allAvailableStringEncodings of the value.
        if ( (optId == TidyCharEncoding) || (optId == TidyInCharEncoding) || (optId == TidyOutCharEncoding) ) {
            int i = [[tidyProcess optionValueForId:optId] intValue];							// value of option
            uint j = [[[tidyProcess class] allAvailableStringEncodings] indexOfObject:[NSNumber numberWithInt:i]];	// index of option
            return [[NSNumber numberWithInt:j] stringValue];								// return it as a string
        } else
            return [tidyProcess optionValueForId:optId];
    return @"";
} //tableView:objectValueForTableColumn:row



/********************************************************************
    tableColumn:customDataCellForRow
    we're here because we're the datasource of the tableview.
    We need to specify which cell to use for this particular row.
*********************************************************************/
-(id)tableColumn:(JSDTableColumn *)aTableColumn customDataCellForRow:(int)row {
    // get the id for the option at this row
    TidyOptionId optId = [JSDTidyDocument optionIdForName:[optionsInEffect objectAtIndex:row]]; 

    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
           NSArray *picks = [JSDTidyDocument optionPickListForId:optId];
           // only return a popup if there IS a picklist OR the item is in the optionsExceptions array.
           if ( ([picks count] != 0) && (![optionsExceptions containsObject:[optionsInEffect objectAtIndex:row]] ) )
                return [aTableColumn usefulPopUpCell:picks];     
    } // if
    return nil;
} // tableColumn:customDataCellForRow

/********************************************************************
    tableView:shouldEditTableColumn:row
    we're here because we're the delegate of the tableview.
    We need to disable for text editing cells with widgets.
*********************************************************************/
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"check"]) {
        if ([[aTableColumn dataCellForRow:rowIndex] class] != [NSTextFieldCell class])
            return NO;
        else
            return YES;
    } // if
    return NO;
} // tableView:shouldEditTableColumn:row


/********************************************************************
    tableView:setObjectValue:forTableColumn:row
    user changed a value -- let's record it!
*********************************************************************/
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)inColumn row:(int)inRow { 
    TidyOptionId optId = [JSDTidyDocument optionIdForName:[optionsInEffect objectAtIndex:inRow]]; 
    if ([[inColumn identifier] isEqualToString:@"check"]) {
        // if we're working with encoding, we need to get the NSStringEncoding instead of the index of the item.
        if ( (optId == TidyCharEncoding) || (optId == TidyInCharEncoding) || (optId == TidyOutCharEncoding) ) {
            id myNumber = [[[tidyProcess class] allAvailableStringEncodings] objectAtIndex:[object unsignedLongValue]];
            [tidyProcess setOptionValueForId:optId fromObject:myNumber];
        } else
            [tidyProcess setOptionValueForId:optId fromObject:object];
    } // if
} // tableView:setObjectValue:forTableColumn:row

/********************************************************************
    tidyDocument
    get method to expose the tidy document.
*********************************************************************/
-(void)tidyDocument:(JSDTidyDocument *)theDoc {
    [theDoc retain];
    [tidyProcess release];
    tidyProcess = theDoc;
} // tidyDocument


/********************************************************************
    tidyDocument
    set method to expose the tidy document.
*********************************************************************/
-(JSDTidyDocument *)tidyDocument {
    return tidyProcess;
} // tidyDocument

//===================================================================================================
//   TARGETING AND ACTIONING -- we want to behave like a Cocoa component, so support that idea.
//===================================================================================================

/********************************************************************
    optionChanged:
    One of the options changed! See if there's something assigned
    to _action, and if so, call it! We're here as a result of being
    the Action of the tableview.
*********************************************************************/
- (IBAction)optionChanged:(id)sender {
    [NSApp sendAction:_action to:_target from:self];
}

/********************************************************************
    action
    return the assigned action.
*********************************************************************/
-(SEL)action {
    return _action;
} // action

/********************************************************************
    SetAction
    assign an action to this controller.
*********************************************************************/
-(void)setAction:(SEL)theAction {
    _action = theAction;
} // setAction;

/********************************************************************
    target
    return the target of this controller.
*********************************************************************/
-(id)target {
    return _target;
} // target

/********************************************************************
    SetTarget
    assign a target to this controller. Remember that actions work
    on the target-action paradigm, but that nil-targeted actions are
    supported. This means if _target isn't used, the action is
    sent all the way up the responder chain. If there's a target, it
    only goes to the target.
*********************************************************************/
-(void)setTarget:(id)theTarget {
    _target = theTarget;
} // setTarger

@end
