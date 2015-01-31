/**************************************************************************************************

	FirstRunController

	Implements a first run helper using an array of programmed steps:
		- message as NSString
		- showRelativeToRect as NSRect
		- ofView as NSView
		- preferredEdge as NSRectEdge


	The MIT License (MIT)

	Copyright (c) 2001 to 2014 James S. Derry <http://www.balthisar.com>

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

#import "FirstRunController.h"
#import "PreferenceController.h"


@interface FirstRunController ()

@property (weak) IBOutlet NSPopover   *popoverFirstRun;
@property (weak) IBOutlet NSButton    *buttonPrevious;
@property (weak) IBOutlet NSButton    *buttonCancel;
@property (weak) IBOutlet NSButton    *buttonNext;
@property (weak) IBOutlet NSButton    *checkboxShowAgain;
@property (weak) IBOutlet NSTextField *textFieldExplanation;
@property (weak) IBOutlet NSTextField *textFieldProgress;

@property (assign) BOOL userHasTouchedCheckbox;

@property (assign) NSInteger currentStep;

- (IBAction)handleButtonPrevious:(NSButton *)sender;
- (IBAction)handleButtonCancel:(NSButton *)sender;
- (IBAction)handleButtonNext:(NSButton *)sender;
- (IBAction)handleCheckboxShowAgain:(NSButton *)sender;

@end



@implementation FirstRunController

@synthesize isVisible = _isVisible;

#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init - designated initializer
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
	self = [super init];
	if (self)
	{
		[[NSBundle mainBundle] loadNibNamed:@"FirstRunHelper" owner:self topLevelObjects:nil];
		
		_userHasTouchedCheckbox = NO;
		
		_currentStep = 0;
	}
	return self;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithSteps:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithSteps:(NSArray*)steps
{
	if ((self = [self init]))
	{
		_steps = steps;
	}
	return self;
}


/*———————————————————————————————————————————————————————————————————*
	dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	_steps = nil;
}


#pragma mark - Sequence Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	beginFirstRunSequence
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)beginFirstRunSequence
{
	if (self.steps.count > 0)
	{
		self.currentStep = 0;
		
		[self showPopoverHavingTag:0];

		[self willChangeValueForKey:@"isVisible"];
		_isVisible = YES;
		[self didChangeValueForKey:@"isVisible"];
	}

}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	showPopoverHavingTag: (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)showPopoverHavingTag:(NSInteger)tag
{
	/* Make sure we don't overstep bounds */

	if (tag >= self.steps.count - 1 )
	{
		tag = self.steps.count - 1;
	}
	 
	if (tag < 0)
	{
		tag = 0;
	}


	/* Setup general items. */
	
	self.buttonNext.title = NSLocalizedString(@"firstRun-buttonNext", nil);
	
	self.checkboxShowAgain.enabled = YES;
	
	self.checkboxShowAgain.state = ![[[NSUserDefaults standardUserDefaults] objectForKey:self.preferencesKeyName] boolValue];
	
	self.buttonCancel.hidden = NO;
	
	self.buttonPrevious.hidden = NO;


	/* Special setup if we're on first item. */
	
	if (tag == 0)
	{
		self.buttonNext.title = NSLocalizedString(@"firstRun-buttonBegin", nil);
		
		self.buttonPrevious.hidden = YES;
	}

	/* Special setup if we're on last item. */
	
	if (tag >= self.steps.count - 1)
	{
		self.buttonNext.title = NSLocalizedString(@"firstRun-buttonDone", nil);

		if (!self.userHasTouchedCheckbox)
		{
			self.checkboxShowAgain.state = NO;
		}

		/* No point in allowing user to cancel now. */
		
		self.buttonCancel.hidden = YES;
	}

	/* Display the helper text and position the popover. */
	
	self.textFieldExplanation.attributedStringValue = [self makeRTFStringFromString:self.steps[tag][@"message"]];

	self.currentStep = tag;

	self.textFieldProgress.stringValue = [NSString stringWithFormat:NSLocalizedString(@"firstRun-stepXofY", nil), tag + 1, self.steps.count];

	[self.popoverFirstRun showRelativeToRect:NSRectFromString(self.steps[tag][@"showRelativeToRect"])
									  ofView:self.steps[tag][@"ofView"]
							   preferredEdge:[self.steps[tag][@"preferredEdge"] integerValue]];
}


#pragma mark - Event Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleButtonPrevious:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleButtonPrevious:(NSButton *)sender
{
	[self showPopoverHavingTag:self.currentStep - 1];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleButtonCancel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleButtonCancel:(NSButton *)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:@(!self.checkboxShowAgain.state) forKey:self.preferencesKeyName];

	[self.popoverFirstRun performClose:self];

	[self willChangeValueForKey:@"isVisible"];
	_isVisible = NO;
	[self didChangeValueForKey:@"isVisible"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleButtonNext:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleButtonNext:(NSButton *)sender
{
	if (self.currentStep != self.steps.count -1)
	{
		[self showPopoverHavingTag:self.currentStep + 1];
	}
	else
	{
		[self handleButtonCancel:nil];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleCheckboxShowAgain:
		We'll simply remember if the user has ever manually touched
		the checkbox so that we don't change the state at the end
		of the helper sequence.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleCheckboxShowAgain:(NSButton *)sender
{
	self.userHasTouchedCheckbox = YES;
}


#pragma mark - Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	isVisible
		Indicates whether or not the popup is currently displayed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)isVisible
{
	return _isVisible;
}


#pragma mark - Private Support Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	makeRTFStringFromString: (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSAttributedString*)makeRTFStringFromString:(NSString*)rawString
{
	NSAttributedString *outString;
	
	/*
		RTF can be a little complex due to legacy string encoding issues.
		When strings are internationalized, RTF might not play nicely with
		non-Mac character encodings. Prefixing the strings with an
		asterisk will cause the automatic conversion to and from RTF,
		otherwise the strings will be treated normally (this maintains
		string compatability with `NSLocalizedString`).
	 */
	if ([rawString hasPrefix:@"*"])
	{
		/* Make into RTF string. */
		
		rawString = [[@"{\\rtf1\\mac\\deff0{\\fonttbl{\\f0 Consolas;}{\\f1 Lucida Grande;}}\\f1\\fs23\\sa100" stringByAppendingString:[rawString substringFromIndex:1]] stringByAppendingString:@"}"];

		NSData *rawData = [rawString dataUsingEncoding:NSMacOSRomanStringEncoding];

		outString = [[NSAttributedString alloc] initWithRTF:rawData documentAttributes:nil];
	}
	else
	{
		/* Use the string as-is. */
		
		outString = [[NSAttributedString alloc] initWithString:rawString];
	}
	
	return outString;
}

@end
