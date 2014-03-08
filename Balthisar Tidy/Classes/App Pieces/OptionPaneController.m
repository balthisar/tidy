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


#pragma mark - CATEGORY - Non-Public


@interface OptionPaneController ()
{
	NSArray *optionsInEffect;		// Array of NSString that holds the options we really want to use.
	NSArray	*optionsExceptions;		// Array of NSString that holds the options we want to treat as STRINGS
}

	@property (weak, nonatomic) IBOutlet NSView *View;					// Pointer to the NIB's |View|.
	@property (weak, nonatomic) IBOutlet NSTextField *theDescription;	// Pointer to the description field.


- (id)tableColumn:(JSDTableColumn *)aTableColumn customDataCellForRow:(NSInteger)row; // [theTable datasource] requirement.


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

		_tidyDocument = [[JSDTidyDocument alloc] init];

		// Get our options list
		optionsInEffect = [NSArray arrayWithArray:[JSDTidyDocument loadConfigurationListFromResource:@"optionsInEffect" ofType:@"txt"]];

		
		// Get our exception list (items to treat as string regardless of tidylib definition)
		optionsExceptions = [NSArray arrayWithArray:[JSDTidyDocument loadConfigurationListFromResource:@"optionsTypesExceptions" ofType:@"txt"]];

		
		/*
			Create a custom column for the NSTableView -- the table will retain
			and control it. Cast to void because otherwise LVVM thinks we're 
			not using the value.
		*/
		
		(void)[[JSDTableColumn alloc] initReplacingColumn:[_theTable tableColumnWithIdentifier:@"check"]];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	_tidyDocument = nil;
	optionsInEffect = nil;
	optionsExceptions = nil;
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

	[[[self theTable] enclosingScrollView] setHasHorizontalScroller:NO];

	[[self View] setFrame:[dstView bounds]];

	[dstView addSubview:_View];
}


#pragma mark - Table Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableViewSelectionDidChange:
		We arrived here by virtue of this controller class being the
		delegate of |theTable|. This is NOT a notification center
		notification. Whenever the selection changes, update
		|theDescription| with the correct, new description
		from Localizable.strings.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	// Get the description of the selected row.
	if ([aNotification object] == [self theTable])
	{
		[[self theDescription] setStringValue:NSLocalizedString(optionsInEffect[[[self theTable] selectedRow]], nil)];
		
		// #TODO: we want to set auto height. Should remove the splitter and just make it dynamic.
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	numberOfRowsInTableView
		We're here because we're the datasource of the |theTable|.
		We need to specify how many items are in the table view.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [optionsInEffect count];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tableView:objectValueForTableColumn:row
		We're here because we're the datasource of |theTable|.
		We need to specify what to show in the row/column.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
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
		/*
			If we're working on Encoding, then return the INDEX of the
			value, and not the value itself (which is NSStringEncoding).
			The index will be used to set which item in the list is displayed.
		*/
		
		if ( (optId == TidyCharEncoding) || (optId == TidyInCharEncoding) || (optId == TidyOutCharEncoding) )
		{
			return [JSDTidyDocument availableEncodingDictionariesByNSStringEncoding][@([[[self tidyDocument] optionValueForId:optId] integerValue])][@"LocalizedIndex"];
		}
		else
		{
			/*
				All text fields are strings, and so passing a string value is
				appropriate. NSPopupButtonCell requires an integer index of
				the item to select. Tidy PickList items are represented by
				enums (not strings), which are compatible, and so whatever
				we pass to _tidyDocument will be used accordingly.
			*/

			return [[self tidyDocument] optionValueForId:optId];
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
		The user changed a value in |theTable| and so we will record
		that in our own data structure (i.e., the |_tidyDocument|).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)inColumn row:(NSInteger)inRow
{
	TidyOptionId optId = [JSDTidyDocument optionIdForName:optionsInEffect[inRow]];
	
	if ([[inColumn identifier] isEqualToString:@"check"])
	{
		// if we're working with encoding, we need to get the NSStringEncoding instead of the index of the item.
		if ( (optId == TidyCharEncoding) || (optId == TidyInCharEncoding) || (optId == TidyOutCharEncoding) )
		{
			// We have the alphabetical index, but need to find the NSStringEncoding.
			[[self tidyDocument] setOptionValueForId:optId
									fromObject:[JSDTidyDocument availableEncodingDictionariesByLocalizedIndex][@([object unsignedLongValue])][@"NSStringEncoding"]];
		}
		else
		{
			/*
				TidyLib picklist options use an enum for their values, not a string.
				We're really depending on all of TidyLib enums for picklist options
				to range from [0..x], and as long as this holds true it's okay to
				use the enum integer value.
			*/
			[[self tidyDocument] setOptionValueForId:optId fromObject:object];
		}
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
