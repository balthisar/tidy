/**************************************************************************************************

	JSDTableView

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDTableView.h"
#import "CommonHeaders.h"


@implementation JSDTableView


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	/* Unregister KVO */
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyOptionsAlternateRowColors];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - awakeFromNib
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
  - observeValueForKeyPath:ofObject:change:context:
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
  - keyDown:
    Calls the delegate's tableViewKeyWasPressed:row:keyCode
    method if it exists.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)keyDown:(NSEvent *)theEvent
{
	if ([[self delegate] respondsToSelector:@selector(tableView:keyWasPressed:row:)])
	{
		BOOL handled = [(id<JSDTableViewDelegate>)[self delegate] tableView:self keyWasPressed:theEvent.keyCode row:self.selectedRow];

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
  - validateProposedFirstResponder:forEvent:
    Allows a control in a table to become first responder
    but first selecting the row. Also allow some controls
    to be first responder that generally aren't ever enabled
    (such as NSStepper).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)validateProposedFirstResponder:(NSResponder *)responder
							  forEvent:(NSEvent *)event
{
	/*
		We want defaults behaviors for everything except
		mouseDown on NSStepper and NSPopupButton.
	 */
	 
	BOOL isMouseDown = ([event type] == NSLeftMouseDown);
	BOOL isSpecial = ([responder class] == [NSStepper class]) || ([responder class] == [NSPopUpButton class]);

	if ( (!isSpecial) | (isSpecial && !isMouseDown) )
	{
		return [super validateProposedFirstResponder:responder forEvent:event];
	}

	NSView *theResponder = (NSView*)responder;

	/* We're already on the currrently selected row. */
	
	if ([self rowForView:theResponder] == [self selectedRow])
	{
		return YES;
	}


	/* Somewhere above is an NSTableRowView. Let's find it. */
	
    NSView *searchView = theResponder.superview;
	
    while ( (![searchView isKindOfClass:[NSTableRowView class]]) && (searchView != nil) )
	{
        if (searchView.superview)
		{
            searchView = searchView.superview;
        }
	}

	if (searchView)
	{
		NSTableRowView *targetedRow = (NSTableRowView*)searchView;
		
		NSInteger rowIndexNew = [self rowForView:targetedRow];
		
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndexNew] byExtendingSelection:NO];

		return YES;
	}

	return NO;
}


@end
