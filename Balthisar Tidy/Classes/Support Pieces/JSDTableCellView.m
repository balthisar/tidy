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

#import "JSDTableCellView.h"
#import "JSDTableView.h"

#pragma mark - Private Interface Additions

@interface JSDTableCellView ()

@property (nonatomic, strong) NSTrackingArea *trackingArea;

@end


#pragma mark - Implementation


@implementation JSDTableCellView



/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
		Setup some default appearances.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
	[self.popupButtonControl setShowsBorderOnlyWhileMouseInside:self.usesHoverEffect];

	[self.stepperControl setHidden:self.usesHoverEffect];

	[self.textField setBordered:NO];
	[self.textField setDrawsBackground:NO];


}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	observeValueForKeyPath:ofObject:change:context
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"OptionsUseHoverEffect"])
	{
		NSNumber *newNumber = [change objectForKey:NSKeyValueChangeNewKey];
		[self setUsesHoverEffect:[newNumber boolValue]];
    }
}


- (void)setUsesHoverEffect:(BOOL)usesHoverEffect
{
	_usesHoverEffect = usesHoverEffect;
	[self.popupButtonControl setShowsBorderOnlyWhileMouseInside:self.usesHoverEffect];
	[self.stepperControl setHidden:self.usesHoverEffect];
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setObjectValue
		We override this method in order to signal a notfication
		that an object value has changed. We do this because the
		NIB is bound to this class and we have to tell whomever
		is implementing us that data is changed. What we'll do it
		look for tableView:setObjectValue:forTableColumn:row
		and use that.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];

	// Find out which table we belong to.
    NSView *searchView = self.superview;
    while ( (![searchView isKindOfClass:[NSTableView class]]) && (searchView != nil) )
	{
        if (searchView.superview)
		{
            searchView = searchView.superview;
        }
	}

	// We've found our owning table.
	if (searchView)
	{
		NSTableView *tableView = (NSTableView*)searchView;

		if ([tableView.dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
		{
			NSInteger row = [tableView rowForView:self];
			NSInteger columnNumber = [tableView columnForView:self];
			NSTableColumn *column = [tableView tableColumns][columnNumber];

			[(id<NSTableViewDataSource>)[tableView dataSource] tableView:tableView setObjectValue:objectValue forTableColumn:column row:row];
		}
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	mouseEntered:
		Show the NSStepper control (if there is one).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseEntered:(NSEvent *)theEvent
{
	if (self.usesHoverEffect)
	{
		self.stepperControl.hidden = NO;
	}
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	mouseExited:
		Hide the NSStepper control (if there is one).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseExited:(NSEvent *)theEvent
{
	if (self.usesHoverEffect)
	{
		self.stepperControl.hidden = YES;
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	updateTrackingAreas
		Required for mouseEntered and mouseExited to work.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
-(void)updateTrackingAreas
{
	if(self.trackingArea != nil)
	{
		[self removeTrackingArea:self.trackingArea];
	}

	self.trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
													  options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect)
														owner:self
													 userInfo:nil];
	[self addTrackingArea:self.trackingArea];
}

@end
