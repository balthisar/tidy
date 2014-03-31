//
//  FirstRunController.m
//  Balthisar Tidy
//
//  Created by Jim Derry on 3/29/14.
//  Copyright (c) 2014 Jim Derry. All rights reserved.
//

#import "FirstRunController.h"

@interface FirstRunController ()

@property (nonatomic, weak) IBOutlet NSPopover *popoverFirstRun;
@property (nonatomic, weak) IBOutlet NSButton *buttonPrevious;
@property (nonatomic, weak) IBOutlet NSButton *buttonCancel;
@property (nonatomic, weak) IBOutlet NSButton *buttonNext;
@property (nonatomic, weak) IBOutlet NSButton *checkboxShowAgain;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldExplanation;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldProgress;

@property (nonatomic, assign) BOOL userHasTouchedCheckbox;

@property (nonatomic, assign) NSInteger currentStep;

- (IBAction)handleButtonPrevious:(NSButton *)sender;
- (IBAction)handleButtonCancel:(NSButton *)sender;
- (IBAction)handleButtonNext:(NSButton *)sender;
- (IBAction)handleCheckboxShowAgain:(NSButton *)sender;

@end



@implementation FirstRunController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init - designated initializer
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
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
	initWithSteps
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithSteps:(NSArray*)steps
{
	self = [self init];
	if (self)
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
	}

}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	showPopoverHavingTag (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)showPopoverHavingTag:(NSInteger)tag
{
	/* 
		Make sure we don't overstep bounds
	 */

	if (tag >= self.steps.count - 1 )
	{
		tag = self.steps.count - 1;
	}
	 
	if (tag < 0)
	{
		tag = 0;
	}

	/*
		Setup general items.
	 */
	self.buttonNext.title = NSLocalizedString(@"firstRun-buttonNext", nil);
	self.checkboxShowAgain.enabled = YES;
	self.buttonCancel.hidden = NO;
	self.buttonPrevious.hidden = NO;

	/*
		Special setup if we're on first item.
	 */
	if (tag == 0)
	{
		self.buttonNext.title = NSLocalizedString(@"firstRun-buttonBegin", nil);
		self.buttonPrevious.hidden = YES;
	}

	/*
		Special setup if we're on last item.
	 */
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
	handleCheckboxShowAgain
		We'll simply remember if the user has ever manually touched
		the checkbox so that we don't change the state at the end
		of the helper sequence.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleCheckboxShowAgain:(NSButton *)sender
{
	self.userHasTouchedCheckbox = YES;
}


#pragma mark - Private Support Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	makeRTFString (private)
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
		// Make into RTF string.
		rawString = [[@"{\\rtf1\\mac\\deff0{\\fonttbl{\\f0 Consolas;}{\\f1 Lucida Grande;}}\\f1\\fs23\\sa100" stringByAppendingString:[rawString substringFromIndex:1]] stringByAppendingString:@"}"];

		NSData *rawData = [rawString dataUsingEncoding:NSMacOSRomanStringEncoding];

		outString = [[NSAttributedString alloc] initWithRTF:rawData documentAttributes:nil];
	}
	else
	{
		// Use the string as-is.
		outString = [[NSAttributedString alloc] initWithString:rawString];
	}
	
	return outString;
}

@end
