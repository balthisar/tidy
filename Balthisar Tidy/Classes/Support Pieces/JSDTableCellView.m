/**************************************************************************************************

	JSDTableCellView

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDTableCellView.h"
#import "CommonHeaders.h"


@implementation JSDTableCellView
{
@private

	NSTrackingArea *trackingArea;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - init
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
  - awakeFromNib
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
	[self.popupButtonControl setShowsBorderOnlyWhileMouseInside:self.usesHoverEffect];

	[self.stepperControl setHidden:self.usesHoverEffect];

	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:JSDKeyOptionsUseHoverEffect
											   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
											   context:NULL];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	/* Unregister KVO */
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyOptionsUseHoverEffect];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - observeValueForKeyPath:ofObject:change:context:
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
  @property usesHoverEffect
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setUsesHoverEffect:(BOOL)usesHoverEffect
{
	_usesHoverEffect = usesHoverEffect;

	[self.popupButtonControl setShowsBorderOnlyWhileMouseInside:self.usesHoverEffect];

	[self.stepperControl setHidden:self.usesHoverEffect];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - mouseEntered:
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
  - mouseExited:
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
  - updateTrackingAreas
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
