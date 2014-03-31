/**************************************************************************************************
 
 JSDTextField.m
 
 - fixes the intrinsicContentSize when using auto layout and multiline, wrapping labels.
 - can be clicked like a button
 - can show alternate text when hovered
 - can show alternate color when hovered
 
 
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


#import "JSDTextField.h"

@interface JSDTextField ()

@property (nonatomic, strong) NSString *holdingText;
@property (nonatomic, strong) NSTrackingArea *trackingArea;

@end

@implementation JSDTextField


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 drawRect:
		 Forces redraw using the new instrinsicContentSize.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)drawRect:(NSRect)dirtyRect
{
	[self invalidateIntrinsicContentSize];
	[super drawRect:dirtyRect];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 intrinsicContentSize
		Properly calculates the intrinsicContentSize taking into
		consideration the actual size the text will occupy.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
-(NSSize)intrinsicContentSize
{
    if ( ![self.cell wraps] )
	{
        return [super intrinsicContentSize];
    }

	NSRect frame;
	CGFloat width;
	CGFloat height;

	if (!self.isHiddenOrHasHiddenAncestor)
	{
		frame = [self frame];
		width = frame.size.width;

		frame.size.height = CGFLOAT_MAX;

		height = [self.cell cellSizeForBounds: frame].height;
	}
	else
	{
		width = 0;
		height = 0;
	}

    return NSMakeSize(width, height);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 mouseDown:
		We will toggle the label text and highlight it while the
		mouse is down AND we're still over the label.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseDown:(NSEvent *)theEvent
{
	//NSLog(@"%@",@"Mouse was down");
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 mouseUp:
		Determine if this event qualifies as a click, and if so
		fire off the action.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseUp:(NSEvent *)theEvent
{
	// Convert theEvent window coordinates to TextField coordinates.
	NSPoint localPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];

	// Ensure that mouseUp occurred within the TextField.
	BOOL eventIsClick = CGRectContainsPoint(self.bounds, localPoint);

	if (eventIsClick)
	{
		[self sendAction:self.action to:self.target];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 mouseEntered:
		Update string values.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseEntered:(NSEvent *)theEvent
{
	// Only do this if there is a hoverStringValue.
	if (self.hoverStringValue)
	{
		self.holdingText = self.stringValue;
		self.stringValue = self.hoverStringValue;
	}
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 mouseExited:
		Update string values.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)mouseExited:(NSEvent *)theEvent
{
	// Only do this if there is a hoverStringValue.
	if (self.hoverStringValue)
	{
		self.stringValue = self.holdingText;
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 updateTrackingAreas
		Required for mouseEntered and mouseExited to work.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
-(void)updateTrackingAreas
{
	// Only do this if there is a hoverStringValue.
	if (self.hoverStringValue)
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
}
@end
