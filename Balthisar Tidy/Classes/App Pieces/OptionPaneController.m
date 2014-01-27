/**************************************************************************************************

	OptionPaneController.m

	part of Balthisar Tidy

	The main controller for the multi-use option pane. implemented separately for

		o use on a document window
		o use on the preferences window

	This controller parses optionsInEffect.txt in the application bundle, and compares
	the options listed there with the linked-in TidyLib to determine which options are
	in effect and valid. We use an instance of |JSDTidyDocument| to deal with this.


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
#import "JSDTableColumn.h"


#pragma mark - Non-Public iVars, Properties, and Method declarations

@interface OptionPaneController ()
{
	NSArray *optionsInEffect;		// Array of NSString that holds the options we really want to use.
	NSArray	*optionsExceptions;		// Array of NSString that holds the options we want to treat as STRINGS
}

	@property (nonatomic) IBOutlet NSTableView *theTable;			// Pointer to the table
	@property (nonatomic) IBOutlet NSTextField *theDescription;		// Pointer to the description field.


- (id)tableColumn:(JSDTableColumn *)aTableColumn customDataCellForRow:(NSInteger)row; // [theTable datasource] requirement.


@end


#pragma mark - Implementation

@implementation OptionPaneController


#pragma mark - initializers and deallocs


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init - designated initializer
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
	self = [super init];
	if (self)
	{
		[[NSBundle mainBundle] loadNibNamed:@"OptionPane" owner:self topLevelObjects:nil];

		_tidyDocument = [[JSDTidyDocument alloc] init];

		// Get our options list
		optionsInEffect = [[NSArray arrayWithArray:[JSDTidyDocument loadConfigurationListFromResource:@"optionsInEffect" ofType:@"txt"]] retain];

		// Get our exception list (items to treat as string regardless of tidylib definition)
		optionsExceptions = [[NSArray arrayWithArray:[JSDTidyDocument loadConfigurationListFromResource:@"optionsTypesExceptions" ofType:@"txt"]] retain];

		// Create a custom column for the NSTableView -- the table will retain and control it.
		[[[JSDTableColumn alloc] initReplacingColumn:[_theTable tableColumnWithIdentifier:@"check"]] release];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	[_tidyDocument release];
	[optionsInEffect release];
	[optionsExceptions release];
	[super dealloc];
}


#pragma mark - Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	putViewIntoView:
		Whoever calls me will put my |View| into THIER |dstView|.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)putViewIntoView:(NSView *)dstView
{
	NSEnumerator *enumerator = [[dstView subviews] objectEnumerator];
	NSView *trash;

	while (trash = [enumerator nextObject])
	{
		[trash removeFromSuperview];
	}

	[[_theTable enclosingScrollView] setHasHorizontalScroller:NO];

	[_View setFrame:[dstView frame]];

	//[_View setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

	//[dstView setAutoresizesSubviews:YES];

	[dstView addSubview:_View];
}


#pragma mark - Table Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableViewSelectionDidChange:
		We arrived here by virtue of this controller class being the
		delegate of |theTable|. Whenever the selection changes
		update |theDescription| with the correct, new description
		from Localizable.strings.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// Get the description of the selected row.
	if ([aNotification object] == _theTable)
	{
		[_theDescription setStringValue:NSLocalizedString(optionsInEffect[[_theTable selectedRow]], nil)];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	numberOfRowsInTableView
		We're here because we're the datasource of the |theTable|.
		We need to specify how many items are in the table view.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [optionsInEffect count];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:objectValueForTableColumn:row
		We're here because we're the datasource of |theTable|.
		We need to specify what to show in the row/column.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	// Get the id for the option at this row.
	TidyOptionId optId = [JSDTidyDocument optionIdForName:optionsInEffect[rowIndex]];

	// Handle returning the 'name' of the option.
	if ([[aTableColumn identifier] isEqualToString:@"name"])
	{
		return optionsInEffect[rowIndex];
	}

	// Handle returning the 'value' column of the option.
	if ([[aTableColumn identifier] isEqualToString:@"check"])
	{
		// If we're working on Encoding, then return the INDEX of the
		// value, and not the value itself. The index will be used
		// to set which item in the list is displayed.
		// TODO: this is still a mess. The dictionary doesn't seem to useful.
		// maybe need the dictionary to be sorted by name, and contain it's
		// alphabetical index and character encoding. Or something. The problem
		// is alphabetical position isn't really something the library proper
		// needs to know about. I THINK that since 10.3 we don't have to use
		// the index of item in the usefulPopuCell. We should be able to
		// use the NSStringEncoding, and save ourselves all this trouble, such as NSMenuItem:setTag.
		if ( (optId == TidyCharEncoding) || (optId == TidyInCharEncoding) || (optId == TidyOutCharEncoding) )
		{
			// This is the NSCharacterEncoding value that's important to us.
			NSInteger optionValue = [[_tidyDocument optionValueForId:optId] integerValue]; 

			// This is the localized name for the previous.
			NSString *optionStringValue = [[[_tidyDocument class] allAvailableEncodingsByEncoding] objectForKey:[NSNumber numberWithUnsignedLong:optionValue]];

			// This is the index in the language array, and also the index for the pop-up list that will be used.
			NSInteger optionIndex = [[[_tidyDocument class] allAvailableEncodingLocalizedNames] indexOfObject:optionStringValue];

			return [@(optionIndex) stringValue]; // Return Index as a string. The value of the popup is this index.
		}
		else
		{
			return [_tidyDocument optionValueForId:optId];
		}
	}
	return @"";
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableColumn:customDataCellForRow
		We're here because we're the datasource of |theTable|.
		Here we are providing the popup cell for use by the table.
		Note that Balthisar Tidy *only* uses popups, or uses the
		native in-cell editing.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)tableColumn:(JSDTableColumn *)aTableColumn customDataCellForRow:(NSInteger)row
{
	// Get the id for the option at this row
	TidyOptionId optId = [JSDTidyDocument optionIdForName:optionsInEffect[row]];

	if ([[aTableColumn identifier] isEqualToString:@"check"])
	{
		NSArray *picks = [JSDTidyDocument optionPickListForId:optId];

		// Return a popup only if there IS a picklist and the item is not in the optionsExceptions array
		if ( ([picks count] != 0) && (![optionsExceptions containsObject:optionsInEffect[row]] ) )
		{
			return [aTableColumn usefulPopUpCell:picks];
		}
	}

	return nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:shouldEditTableColumn:row
		We're here because we're the delegate of |theTable|.
		We need to disable for text editing cells with widgets.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] isEqualToString:@"check"])
	{
		if ([[aTableColumn dataCellForRow:rowIndex] class] != [NSTextFieldCell class])
		{
			return NO;
		} 
		else
		{
			return YES;
		}
	}

	return NO;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:setObjectValue:forTableColumn:row
		We're here because we're the datasource of |theTable|.
		Sets the data object for an item in the specified row and column.
		The user change a value in |theTable| and so we will record
		that in our own data structure (i.e., the |_tidyDocument|).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)inColumn row:(int)inRow
{
	TidyOptionId optId = [JSDTidyDocument optionIdForName:optionsInEffect[inRow]];
	if ([[inColumn identifier] isEqualToString:@"check"])
	{
		// if we're working with encoding, we need to get the NSStringEncoding instead of the index of the item.
		if ( (optId == TidyCharEncoding) || (optId == TidyInCharEncoding) || (optId == TidyOutCharEncoding) )
		{
			// we have the alphabetical index. Need to find the matching string, then
			// get the actual NStringEncoding.
			// #TODO this is still an ugly mess. NOTE that since 10.3, we can assign
			// things other than index or value. We should be able to put both the
			// label in the localized language as well as the NSStringEncoding here.

			// First get the string represented by the index.
			NSString *optionStringValue = [[_tidyDocument class] allAvailableEncodingLocalizedNames][[object unsignedLongValue]];

			// Then get the NSStringEncoding value (represented as a string) of that string.
			NSString *stringEncoding = [[[_tidyDocument class] allAvailableEncodingsByLocalizedName][optionStringValue] stringValue];

			[_tidyDocument setOptionValueForId:optId fromObject:stringEncoding];
		}
		else
		{
			// #TODO - it looks like picklists for Tidy take index values from an enum, not text values.
			// Please confirm in debugger. This means using index of the menu item is consistent with this.
			// Also confirm what is object? Is it my tablecell?
			[_tidyDocument setOptionValueForId:optId fromObject:object];
		}

		// signal the update
		[NSApp sendAction:_action to:_target from:self];
	}
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
