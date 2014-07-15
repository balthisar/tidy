/**************************************************************************************************

	JSDTableCellView

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
#import "PreferencesDefinitions.h"
//#import "JSDTableView.h"


@implementation JSDTableCellView
{
@private

	NSTrackingArea *trackingArea;
}

@synthesize usesHoverEffect = _usesHoverEffect;

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init
		Setup some default appearances.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
	if ( (self = [super init]) )
	{
		trackingArea = nil;
	}

	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
		Setup some default appearances.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
	[self.popupButtonControl setShowsBorderOnlyWhileMouseInside:self.usesHoverEffect];

	[self.stepperControl setHidden:self.usesHoverEffect];

	//[self.textField setBordered:NO];

	//[self.textField setDrawsBackground:NO];

	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:JSDKeyOptionsUseHoverEffect
											   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
											   context:NULL];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	/* Unregister KVO */
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyOptionsUseHoverEffect];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	observeValueForKeyPath:ofObject:change:context:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:JSDKeyOptionsUseHoverEffect])
	{
		NSNumber *newNumber = [change objectForKey:NSKeyValueChangeNewKey];

		[self setUsesHoverEffect:[newNumber boolValue]];

		[self setNeedsDisplay:YES];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	usesHoverEffect
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)usesHoverEffect
{
	return _usesHoverEffect;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setUsesHoverEffect:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setUsesHoverEffect:(BOOL)usesHoverEffect
{
	_usesHoverEffect = usesHoverEffect;

	[self.popupButtonControl setShowsBorderOnlyWhileMouseInside:self.usesHoverEffect];

	[self.stepperControl setHidden:self.usesHoverEffect];
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
	if (trackingArea != nil)
	{
		[self removeTrackingArea:trackingArea];
	}

	trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
												 options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect)
												   owner:self
												userInfo:nil];
	[self addTrackingArea:trackingArea];
}

@end
