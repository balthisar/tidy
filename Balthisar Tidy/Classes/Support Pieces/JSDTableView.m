/**************************************************************************************************

	JSDTableView

	Simple NSTableView subclass that adds a couple of things:

		- captures keyDown and reports this to the delegate.
		- overrides validateProposedFirstResponder:forEvent in order to allow controls
		  in a table view that would ordinarily never be allowed to be first responder.
		- binds to JSDKeyOptionsAlternateRowColors in preferences to control its own
		  usesAlternatingRowBackgroundColors property.

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

#import "JSDTableView.h"
#import "PreferencesDefinitions.h"


@implementation JSDTableView


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	/* Unregister KVO */
	
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyOptionsAlternateRowColors];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
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
	observeValueForKeyPath:ofObject:change:context:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ([keyPath isEqual:JSDKeyOptionsAlternateRowColors])
	{
		NSNumber *newNumber = [change objectForKey:NSKeyValueChangeNewKey];
		
		self.usesAlternatingRowBackgroundColors = [newNumber boolValue];
		
		return;
    }

	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	keyDown:
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
	validateProposedFirstResponder:forEvent:
		Allows a control in a table to become first responder
		out first selecting the row. Also allow some controls
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
