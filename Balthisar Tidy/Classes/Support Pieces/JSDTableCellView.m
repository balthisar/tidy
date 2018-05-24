/**************************************************************************************************

	JSDTableCellView

	Copyright © 2003-2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDTableCellView.h"
#import "CommonHeaders.h"
#import "JSDListEditorController.h"

@import JSDTidyFramework;


@interface JSDTableCellView ()

@property (nonatomic, strong) NSPopover *sharedPopover;
@property (nonatomic, strong) JSDListEditorController *sharedListController;

@end


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


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - setValue:forKeyPath
    Validate the value with an instance of Tidy before applying.
    @note This is a hacky solution; rethink the architecture
    a bit here.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    JSDTidyOption *option = self.objectValue;
    value = [option normalizedOptionValue:value];
    [super setValue:value forKeyPath:keyPath];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - controlTextDidEndEditing
    Update the text label after setting.
    @note This is a hacky solution; rethink the architecture
    a bit here.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    NSTextField *textField = obj.object;
    JSDTidyOption *option = self.objectValue;
    [textField setStringValue:option.optionUIValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - configureListEditor:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)configureListEditor
{
    self.sharedPopover = [[NSPopover alloc] init];
    self.sharedListController = [[JSDListEditorController alloc] init];
    [self.sharedPopover setContentViewController:self.sharedListController];
    [self.sharedPopover setBehavior:NSPopoverBehaviorSemitransient];
    [self.sharedPopover setDelegate:self];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - invokeListEditorForTextField:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)invokeListEditorForTextField
{
    JSDTidyOption *option = self.objectValue;
    [self configureListEditor];
    self.sharedListController.itemsText = option.optionUIValue;
    [self.sharedPopover showRelativeToRect:self.textFieldControl.bounds ofView:self.textFieldControl preferredEdge:NSMaxYEdge];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - popoverDidClose:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)popoverDidClose:(NSNotification *)notification
{
    [self.objectValue setValue:self.sharedListController.itemsText forKey:@"optionUIValue"];
    self.sharedListController = nil;
    self.sharedPopover = nil;
}


@end
