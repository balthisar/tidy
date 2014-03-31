/**************************************************************************************************

	OptionPaneController.m

	The main controller for the Tidy Options pane. Used separately by

	- document windows
	- the preferences window

	This controller parses `optionsInEffect.txt` in the application bundle, and compares
	the options listed there with the linked-in TidyLib to determine which options are
	in effect and valid. We use an instance of `JSDTidyModel` to deal with this.


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

#import "OptionPaneController.h"
#import "JSDTextField.h"

#pragma mark - CATEGORY - Non-Public


@interface OptionPaneController ()

@property (weak, nonatomic) IBOutlet NSView *View;					// Pointer to the NIB's |View|.

@property (weak) IBOutlet JSDTextField *theHidingLabel;				// Pointer to the label that hides the description.

@property (weak, nonatomic) IBOutlet NSTextField *theDescription;	// Pointer to the description field.

@property (assign, nonatomic) BOOL theDescriptionIsHidden;					// Indicates whether or not theDescription is hidden.
@property (strong, nonatomic) NSLayoutConstraint *theDescriptionConstraint;	// The layout constraint we will apply to theDescription.


- (IBAction)labelHideClicked:(NSTextField *)sender;

@end


#pragma mark - IMPLEMENTATION


@implementation OptionPaneController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init - designated initializer
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
	self = [super init];
	if (self)
	{
		[[NSBundle mainBundle] loadNibNamed:@"OptionPane" owner:self topLevelObjects:nil];

		_tidyDocument = [[JSDTidyModel alloc] init];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	_tidyDocument = nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void) awakeFromNib
{
	// Clean up the table's row-height.
	[self.theTable setRowHeight:20.0f];

	// Setup some changing labels.
	self.theHidingLabel.stringValue = @"";
	self.theHidingLabel.hoverStringValue = NSLocalizedString(@"description-Hide", nil);
	self.theDescriptionIsHidden = NO;
	self.theDescriptionConstraint = [NSLayoutConstraint constraintWithItem:self.theDescription
																 attribute:NSLayoutAttributeHeight
																 relatedBy:NSLayoutRelationEqual
																	toItem:nil
																 attribute:NSLayoutAttributeNotAnAttribute
																multiplier:1.0
																  constant:0.0];
}

#pragma mark - Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	putViewIntoView:
		Whoever calls me will put my `View` into THIER `dstView`.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)putViewIntoView:(NSView *)dstView
{
	for (NSView *trash in [dstView subviews])
	{
		[trash removeFromSuperview];
	}
	
	[[[self theTable] enclosingScrollView] setHasHorizontalScroller:NO];

	[[self View] setFrame:[dstView bounds]];

	[dstView addSubview:_View];
}


#pragma mark - Options Related


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	> optionsInEffect
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionsInEffect:(NSArray *)optionsInEffect
{
	_optionsInEffect = optionsInEffect;
	self.tidyDocument.optionsInEffect = optionsInEffect;
}


#pragma mark - Table Handling - Datasource Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	numberOfRowsInTableView
		We're here because we're the datasource of the `theTable`.
		We need to specify how many items are in the table view.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self.optionsInEffect count];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:objectValueForTableColumn:row
		We're here because we're the datasource of `theTable`.
		We need to specify what to show in the row/column.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	JSDTidyOption *optionRef = [[self tidyDocument] tidyOptions][self.optionsInEffect[rowIndex]];

	// Handle returning the 'name' of the option.
	if ([[aTableColumn identifier] isEqualToString:@"name"])
	{
		BOOL test = [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyOptionsShowHumanReadableNames];
		if ( test )
		{
			return optionRef.localizedHumanReadableName;
		}
		else
		{
			return self.optionsInEffect[rowIndex];
		}
	}

	// Handle returning the 'value' column of the option.
	if ([[aTableColumn identifier] isEqualToString:@"check"])
	{
		return optionRef.optionUIValue;
	}
	
	return @"";
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:setObjectValue:forTableColumn:row
		We're here because we're the datasource of `theTable`.
		Sets the data object for an item in the specified row and column.
		The user changed a value in `theTable` and so we will record
		that in our own data structure.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)inColumn row:(NSInteger)inRow
{
	if ([[inColumn identifier] isEqualToString:@"check"])
	{
		JSDTidyOption *optionRef = [[self tidyDocument] tidyOptions][self.optionsInEffect[inRow]];
				
		if ([object isKindOfClass:[NSString class]])
		{
			optionRef.optionUIValue = [NSString stringWithString:object];
		}
		else
		{
			optionRef.optionUIValue = [object stringValue];
		}
	}
}


#pragma mark - Table Handling - Delegate Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableViewSelectionDidChange:
		We're here because we're the delegate of the `theTable`.
		delegate of `theTable`. This is NOT a notification center
		notification. Whenever the selection changes, update
		`theDescription` with the correct, new description
		from Localizable.strings.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == [self theTable])
	{
		NSString *selectedOptionName = self.optionsInEffect[[[self theTable] selectedRow]];
		
		JSDTidyOption *optionRef = [[self tidyDocument] tidyOptions][selectedOptionName];
		
		[[self theDescription] setAttributedStringValue:optionRef.localizedHumanReadableDescription];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:dataCellForTableColumn:row:
		We're here because we're the delegate of `theTable`.
		Here we are providing the popup cell for use by the table.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([[tableColumn identifier] isEqualToString:@"check"])
	{
		JSDTidyOption *optionRef = [[self tidyDocument] tidyOptions][self.optionsInEffect[row]];
		
		NSArray *picks = optionRef.possibleOptionValues;

		// Return a popup only if there's a picklist.
		if ([picks count] != 0)
		{
			NSPopUpButtonCell *myCell = [[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO];
			[myCell setEditable: YES];
			[myCell setBordered:YES];
			[myCell addItemsWithTitles:picks];
			[myCell setControlSize:NSSmallControlSize];
			[myCell setFont:[NSFont menuFontOfSize:10]];
			return myCell;
		}
	}

	return nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:shouldEditTableColumn:row
		We're here because we're the delegate of `theTable`.
		We need to disable for text editing cells with widgets.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[aTableColumn identifier] isEqualToString:@"check"])
	{
		return ([[aTableColumn dataCellForRow:rowIndex] class] == [NSTextFieldCell class]);
	}
	
	return NO;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableViewKeyWasPressed
		Respond to table view keypresses.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)tableViewKeyWasPressed:(NSTableView *)aTableView row:(NSInteger)rowIndex keyCode:(NSInteger)keyCode;
{

	if ((rowIndex >= 0) && (( keyCode == 123) || (keyCode == 124)))
	{
		NSString *selectedOptionName = self.optionsInEffect[[[self theTable] selectedRow]];

		JSDTidyOption *optionRef = [[self tidyDocument] tidyOptions][selectedOptionName];

		if (keyCode == 123)
		{
			[optionRef optionUIValueDecrement];
		}
		else
		{
			[optionRef optionUIValueIncrement];
		}
		
		return YES;
	}

	return NO;
}


#pragma mark - Description Field Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	labelHideClicked
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)labelHideClicked:(NSTextField *)sender
{
	if (self.theDescriptionIsHidden)
	{
		[self.theDescription removeConstraint:self.theDescriptionConstraint];
		self.theDescriptionIsHidden = NO;
		self.theHidingLabel.hoverStringValue = NSLocalizedString(@"description-Hide", nil);
	}
	else
	{
		[self.theDescription addConstraint:self.theDescriptionConstraint];
		self.theDescriptionIsHidden = YES;
		self.theHidingLabel.hoverStringValue = NSLocalizedString(@"description-Show", nil);
	}

	self.theHidingLabel.stringValue = @"";
}


#pragma mark - Split View Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	splitView:constrainMinCoordinate:ofSubviewAt:
		We're here because we're the delegate of the split view.
		This will impose a minimum limit on the UPPER pane of the
		split.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 68.0f;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	splitView:constrainMaxCoordinate:ofSubviewAt:
		We're here because we're the delegate of the split view.
		In order to guarantee a minimum size for the LOWER pane,
		we have to setup a dyanmic maximum size for the UPPER.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return [splitView frame].size.height - 40.0f;
}

@end
