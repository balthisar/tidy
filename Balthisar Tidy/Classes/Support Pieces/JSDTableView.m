//
//  JSDTableView.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "JSDTableView.h"
#import "CommonHeaders.h"
#import "JSDTableCellView.h"

@import JSDTidyFramework;


@implementation JSDTableView


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
    /* Unregister KVO */
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyOptionsAlternateRowColors];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - awakeFromNib
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
    /* Register with the preferences system to trap JSDKeyOptionsAlternateRowColors */
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:JSDKeyOptionsAlternateRowColors
                                               options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                                               context:NULL];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - observeValueForKeyPath:ofObject:change:context:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:JSDKeyOptionsAlternateRowColors])
    {
        bool usesAlternate = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        self.usesAlternatingRowBackgroundColors = usesAlternate;
        self.gridStyleMask = usesAlternate ? NSTableViewDashedHorizontalGridLineMask : NSTableViewGridNone;
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - keyDown:
 *  Calls the delegate's tableViewKeyWasPressed:row:keyCode
 *  method if it exists.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)keyDown:(NSEvent *)theEvent
{
    
    id localDelegate = (id<JSDTableViewDelegate>)self.delegate;
    
    if ([localDelegate respondsToSelector:@selector(tableView:keyWasPressed:row:)])
    {
        BOOL handled = [localDelegate tableView:self keyWasPressed:theEvent.keyCode row:self.selectedRow];
        
        if (!handled)
        {
            [super keyDown:theEvent];
        }
        else
        {
            [self setNeedsDisplay:YES];
        }
    }
    else
    {
        [super keyDown:theEvent];
    }
    
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - mouseDown:
 *  If there's an NSTextField and the user double-clicks a row,
 *  then we want to activate the NSTextField without making the
 *  user wait. If the NSTextField has a list editor, then we want
 *  to activate that with a triple click.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    
    if (theEvent.clickCount < 2)
    {
        return;
    }
    
    /* Which row was clicked on? */
    NSInteger row = [self rowAtPoint:[self convertPoint:theEvent.locationInWindow fromView:nil]];
    
    if (row < 0)
    {
        return;
    }

    JSDTableCellView *view = [self viewAtColumn:0 row:row makeIfNecessary:NO];

    /* If the textFieldControl is visible, activate it on a double-click,
     * but don't activate it on more than a double-click, so that we can
     * show the list editor instead. We will delay activation by the system's
     * programmed doubleClickInterval, so that we can cancel it if a third
     * click comes in.
     */
    if ( view.textFieldControl.window != nil )
    {
        JSDTidyOption *opt = view.objectValue;

        if ( theEvent.clickCount == 2 )
        {
            [self.window performSelector:@selector(makeFirstResponder:) withObject:view.textFieldControl  afterDelay:[NSEvent doubleClickInterval]];
        } else if (opt.optionIsList) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self.window];
            [view invokeListEditorForTextField];
        }
    }

    /* If the stepperTextFieldControl is visible, activate it when clicked
     * multiple times. We'll use the same delayed activation for consistent
     * behavior.
     */
    if ( view.stepperTextFieldControl.window != nil )
    {
        [self.window performSelector:@selector(makeFirstResponder:) withObject:view.stepperTextFieldControl  afterDelay:[NSEvent doubleClickInterval]];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - validateProposedFirstResponder:forEvent:
 *  Allows a control in a table to become first responder
 *  by first selecting the row. Also allow some controls
 *  to be first responder that generally aren't ever enabled
 *  (such as NSStepper).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)validateProposedFirstResponder:(NSResponder *)responder
                              forEvent:(NSEvent *)event
{
    NSView *theResponder = (NSView*)responder;
    BOOL isMouseDown = ( event.type == NSEventTypeLeftMouseDown);
    BOOL isSpecial = ( responder.class == NSStepper.class) || (responder.class == NSPopUpButton.class );
    
    /* We want default behaviors for everything except
     * mouseDown on NSStepper and NSPopupButton.
     */
    
    if ( !(isSpecial && isMouseDown) )
    {
        return [super validateProposedFirstResponder:responder forEvent:event];
    }
    
    /* We're already on the currrently selected row. */
    
    if ([self rowForView:theResponder] == self.selectedRow)
    {
        return YES;
    }
    
    
    /* Somewhere above is an NSTableRowView. Let's find it. */
    
    NSView *searchView = theResponder.superview;
    
    while ( (![searchView isKindOfClass:NSTableRowView.class] ) && (searchView != nil) )
    {
        if (searchView.superview)
        {
            searchView = searchView.superview;
        }
    }
    
    if ( searchView )
    {
        NSTableRowView *targetedRow = (NSTableRowView*)searchView;
        
        NSInteger rowIndexNew = [self rowForView:targetedRow];
        
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndexNew] byExtendingSelection:NO];
        
        return YES;
    }
    
    return NO;
}


@end
