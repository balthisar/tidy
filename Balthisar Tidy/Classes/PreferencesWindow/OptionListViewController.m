/**************************************************************************************************

	OptionListViewController
	 
	A view controller to manage the preferences' Tidy Options pane.


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

#import "OptionListViewController.h"

#import "JSDTidyModel.h"
#import "OptionPaneController.h"
#import "PreferenceController.h"


#pragma mark - CATEGORY - Non-Public


@interface OptionListViewController ()

@property (weak) IBOutlet NSView    *optionControllerView;   // The empty pane in the nib that we will inhabit.

@property OptionPaneController      *optionController;       // The real option pane loaded into optionPane.

@end


#pragma mark - IMPLEMENTATION


@implementation OptionListViewController


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
    return [super initWithNibName:@"OptionListViewController" bundle:nil];
}



/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
		- Setup the option panel controller.
		- Give the OptionPaneController its optionsInEffect
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{

	/* Create and setup the option controller. */

	self.optionController = [[OptionPaneController alloc] init];

	self.optionController.isInPreferencesView = YES;

	[self.optionControllerView addSubview:self.optionController.view];

	[self.optionController.view setFrame:self.optionControllerView.bounds];

	self.optionController.optionsInEffect = [PreferenceController optionsInEffect];


	/* Set the option values in the optionController from user defaults. */
	
	[[[self optionController] tidyDocument] takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];


	/* 
		NSNotifications from `optionController` indicate that one or more Tidy options changed.
		This is what we will use to capture changes and record them into user defaults.
	 */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyOptionChange:)
												 name:tidyNotifyOptionChanged
											   object:[[self optionController] tidyDocument]];
}


#pragma mark - Events


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleTidyOptionChange:
		We're here because we registered for NSNotification.
		One of the preferences changed in the option pane.
		We're going to record the preference, but we're not
		going to post a notification, because new documents
		will read the preferences themselves.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
	[self.optionController.tidyDocument writeOptionValuesWithDefaults:[NSUserDefaults standardUserDefaults]];
}


#pragma mark - <MASPreferencesViewController> Support


- (BOOL)hasResizableHeight
{
	return YES;
}


- (BOOL)hasResizableWidth
{
	return YES;
}



- (NSString *)identifier
{
    return @"OptionListPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsTidy"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Tidy Options", nil);
}

@end
