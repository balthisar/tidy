/**************************************************************************************************

	TidyDocument.m

	part of Balthisar Tidy

	The main document controller.


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

#pragma mark - Notes

/**************************************************************************************************
 
	Event Handling and Interacting with the Tidy Processor
 
		The Tidy processor is loosely couple with the document controller. Most
		interaction with it is handled via NSNotifications.
 
		If user types text we receive a |textDidChange| delegate notification, and we will set
		new text in [tidyProcess sourceText]. The event chain will eventually handle everything
		else.
 
		If |tidyText| changes we will receive NSNotification, and put the new |tidyText|
		into the |tidyView|, and also update |errorView|.
  
		If |optionController| sends an NSNotification, then we will copy the new
		options to |tidyProcess|. The event chain will eventually handle everything else.
 
		If we set |sourceText| via file or data (only happens when opening or reverting)
		we will NOT update |sourceView|. We will wait for |tidyProcess| NSNotification that
		the |sourceText| changed, then set the |sourceView|. HOWEVER this presents a small
		issue to overcome:
 
			- If we set |sourceView| we will get |textDidChange| notification, causing
			  us to update [tidyProcess sourceText] again, resulting in processing the
			  document twice, which we don't want to do.
 
			- To prevent this we will set |documentIsLoading| to YES any time we we set
			  |sourceText| from file or data. In the |textDidChange| handler we will NOT
			  set [tidyProcess sourceText], and we will flip |documentIsLoading| back to NO.
 
 **************************************************************************************************/


#import "TidyDocument.h"
#import "PreferenceController.h"
#import "JSDTidyDocument.h"
#import "NSTextView+JSDExtensions.h"


#pragma mark - CATEGORY - Non-Public


@interface TidyDocument ()


#pragma mark - Properties


// View Outlets
@property (nonatomic, assign) IBOutlet NSTextView *sourceView;
@property (nonatomic, assign) IBOutlet NSTextView *tidyView;
@property (nonatomic, weak) IBOutlet NSTableView *errorView;


// Encoding Helper Popover Outlets
@property (nonatomic, weak) IBOutlet NSPopover *popoverEncoding;
@property (nonatomic, weak) IBOutlet NSButton *buttonEncodingDoNotWarnAgain;
@property (nonatomic, weak) IBOutlet NSButton *buttonEncodingAllowChange;
@property (nonatomic, weak) IBOutlet NSButton *buttonEncodingIgnoreSuggestion;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldEncodingExplanation;


// First Run Helper Popover Outlets
@property (nonatomic, weak) IBOutlet NSPopover *popoverFirstRun;
@property (nonatomic, weak) IBOutlet NSButton *buttonFirstRunNext;
@property (nonatomic, weak) IBOutlet NSButton *buttonFirstRunCancel;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldFirstRunExplanation;


// Window Splitters
@property (nonatomic, weak) IBOutlet NSSplitView *splitLeftRight;		// The left-right (main) split view in the Doc window.
@property (nonatomic, weak) IBOutlet NSSplitView *splitTopDown;			// Top top-to-bottom split view in the Doc window.


// Option Controller
@property (nonatomic, weak) IBOutlet NSView *optionPane;				// Our empty optionPane in the nib.
@property (nonatomic, strong) OptionPaneController *optionController;	// The real option pane we load into optionPane.


// Our Tidy Processor
@property (nonatomic, strong) JSDTidyDocument *tidyProcess;


// Preferences-related flags
@property (nonatomic, assign) BOOL fileWantsProtection;
@property (nonatomic, assign) BOOL ignoreInputEncodingWhenOpening;


// Document Control
@property (nonatomic, strong) NSData *documentOpenedData;				// Hold file we open until nib is awake.
@property (nonatomic, assign) BOOL documentIsLoading;					// Flag to supress certain event updates.


#pragma mark - Methods

// Popover Actions
- (IBAction)popoverHandler:(id)sender;									// Handler for all popover actions.


@end


#pragma mark - IMPLEMENTATION


@implementation TidyDocument


#pragma mark - File I/O Handling


/*———————————————————————————————————————————————————————————————————*
	readFromURL:ofType:error
		Called as part of the responder chain. We already have a
		name and type as a result of
			(1) the file picker, or
			(2) opening a document from Finder. 
		Here, we'll merely load the file contents into an NSData,
		and process it when the nib awakes (since we're	likely to be
		called here before the nib and its controls exist).
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)readFromURL:(NSString *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	// Save the data for use until after the Nib is awake.
	self.documentOpenedData = [NSData dataWithContentsOfFile:absoluteURL];
		
	return YES;
}


/*———————————————————————————————————————————————————————————————————*
	revertToContentsOfURL:ofType:error
		Allow the default reversion to take place, and then put the
		correct value in the editor if it took place. The inherited
		method does |readFromFile|, so put the documentOpenedData
		into our |tidyProcess|.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL didRevert;
	
	if ((didRevert = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]))
	{
		self.documentIsLoading = YES;
		[[self tidyProcess] setSourceTextWithData:[self documentOpenedData]];
	}
	
	return didRevert;
}


/*———————————————————————————————————————————————————————————————————*
	dataOfType:error
		Called as a result of saving files. All we're going to do is
		pass back the NSData taken from the TidyDoc, using the
		encoding specified by `output-encoding`.
 *———————————————————————————————————————————————————————————————————*/
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	return [[self tidyProcess] tidyTextAsData];
}


/*———————————————————————————————————————————————————————————————————*
	writeToUrl:ofType:Error
		Called as a result of saving files, and does the actual
		writing. We're going to override it so that we can update
		the |sourceView| automatically any time the file is saved.
		Setting |sourceView| will kick off the |textDidChange| event
		chain, which will set [tidyProcess sourceText] for us later.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL success = [super writeToURL:absoluteURL ofType:typeName error:outError];
	
	if (success)
	{
		[[self sourceView] setString:[[self tidyProcess] tidyText]];
		self.fileWantsProtection = NO;
	}
	
	return success;
}


/*———————————————————————————————————————————————————————————————————*
	saveDocument
		We're going to override the default save to make sure we
		can comply with the user's preferences. We're going to be
		over-protective because we don't want to get blamed for
		screwing up the user's data if Tidy doesn't process 
		something correctly.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)saveDocument:(id)sender
{
	JSDSaveType saveBehavior = [[NSUserDefaults standardUserDefaults] integerForKey:JSDKeySavingPrefStyle];

	// Warning will only apply if there's a current file and it's NOT been saved yet, and it's not new.
	if ( (saveBehavior == kJSDSaveButWarn) &&
		 ([self fileWantsProtection]) &&
		 ([[[self fileURL] path] length] > 0) )
	{
		NSInteger i = NSRunAlertPanel(NSLocalizedString(@"WarnSaveOverwrite", nil), NSLocalizedString(@"WarnSaveOverwriteExplain", nil),
									  NSLocalizedString(@"continue save", nil), NSLocalizedString(@"do not save", nil) , nil);
		
		if (i == NSAlertAlternateReturn)
		{
			return; // User chose don't save.
		}
	}

	// Save is completely disabled -- tell user to Save As…
	if ( ([self fileWantsProtection]) && (saveBehavior == kJSDSaveAsOnly) )
	{
		NSRunAlertPanel(NSLocalizedString(@"WarnSaveDisabled", nil), NSLocalizedString(@"WarnSaveDisabledExplain", nil),
						NSLocalizedString(@"cancel", nil), nil, nil);
		
		return; // Don't continue the save operation
	}

	return [super saveDocument:sender];
}


#pragma mark - Initialization and Deallocation and Setup


/*———————————————————————————————————————————————————————————————————*
	init
		Our creator -- create the |tidyProcess| and the |processString|.
		Also be registered to receive preference notifications for the
		file-saving preferences.
 *———————————————————————————————————————————————————————————————————*/
- (id)init
{
	if ((self = [super init]))
	{
		self.tidyProcess = [[JSDTidyDocument alloc] init];
		self.documentOpenedData = nil;
	}
	
	return self;
}


/*———————————————————————————————————————————————————————————————————*
	dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifyOptionChanged object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifySourceTextChanged object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifyTidyTextChanged object:nil];
	_sourceView = nil;
	_tidyView = nil;
	_optionController = nil;
}


/*———————————————————————————————————————————————————————————————————*
	configureViewSettings
		Given aView, make it non-wrapping. Also set fonts.
 *———————————————————————————————————————————————————————————————————*/
- (void)configureViewSettings:(NSTextView *)aView
{
	[aView setFont:[NSFont fontWithName:@"Courier" size:12]];
	[aView setRichText:NO];
	[aView setUsesFontPanel:NO];
	[aView setContinuousSpellCheckingEnabled:NO];
	[aView setSelectable:YES];
	[aView setEditable:NO];
	[aView setImportsGraphics:NO];
	[aView setWordwrapsText:NO];					// Provided by category `NSTextView+JSDExtensions`
	[aView setShowsLineNumbers:YES];				// Provided by category `NSTextView+JSDExtensions`
}


/*———————————————————————————————————————————————————————————————————*
	awakeFromNib
		When we wake from the nib file, setup the option controller.
 *———————————————————————————————————————————————————————————————————*/
- (void) awakeFromNib
{
	// Create a OptionPaneController and put it in place of optionPane.
	if (![self optionController])
	{
		self.optionController = [[OptionPaneController alloc] init];
	}
	
	[[self optionController] putViewIntoView:[self optionPane]];
}


/*———————————————————————————————————————————————————————————————————*
	windowControllerDidLoadNib:
		The nib is loaded. If there's a string in processString, it
		will appear in the |sourceView|.
 *———————————————————————————————————————————————————————————————————*/
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	[super windowControllerDidLoadNib:aController];

	
	[self configureViewSettings:[self sourceView]];
	[self configureViewSettings:[self tidyView]];
	[[self sourceView] setEditable:YES];

	
	// Honor the defaults system defaults.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];				// Get the default default system.
	[[[self optionController] tidyDocument] takeOptionValuesFromDefaults:defaults];	// Make the optionController take the values.

	
	// Saving behavior settings
	self.fileWantsProtection = !([self documentOpenedData] == nil);

	
	// Other defaults system items
	self.ignoreInputEncodingWhenOpening = [defaults boolForKey:JSDKeyIgnoreInputEncodingWhenOpening];

	
	// Set the document options.
	[[self tidyProcess] optionCopyFromDocument:[[self optionController] tidyDocument]];

	
	/*
		Delay setting up notifications until now, because otherwise
		all of the earlier options setup is simply going to result
		in a huge cascade of notifications and updates.
	*/

	// NSNotifications from the |optionController| indicate that one or more options changed.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyOptionChange:)
												 name:tidyNotifyOptionChanged
											   object:[[self optionController] tidyDocument]];
	
	// NSNotifications from the tidyProcess indicate that sourceText changed.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidySourceTextChange:)
												 name:tidyNotifySourceTextChanged
											   object:[self tidyProcess]];
	
	// NSNotifications from the tidyProcess indicate that tidyText changed.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyTidyTextChange:)
												 name:tidyNotifyTidyTextChanged
											   object:[self tidyProcess]];
	
	
	if (![defaults boolForKey:JSDKeyFirstRunComplete])
	{
		[self firstRunPopoverSequence];
	}

	if ( ([self documentOpenedData]) && (![defaults boolForKey:JSDKeyIgnoreInputEncodingWhenOpening]) )
	{
		[self inputEncodingSanityCheck];
	}
	
	// Set the tidyProcess data. The event system will set the view later.
	// If we're a new document, then documentOpenData nil is fine.
	self.documentIsLoading = YES;
	[[self tidyProcess] setSourceTextWithData:[self documentOpenedData]];
}


/*———————————————————————————————————————————————————————————————————*
	windowNibName
		Return the name of the Nib associated with this class.
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)windowNibName
{
	return @"TidyDocument";
}


#pragma mark - Tidy-related Event Handling


/*———————————————————————————————————————————————————————————————————*
	handleTidyOptionChange
		One or more options changed in |optionController|. Copy
		those options to our |tidyProcess|. The event chain will
		eventually update everything else because this should
		cause the tidyText to change.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
	[[self tidyProcess] optionCopyFromDocument:[[self optionController] tidyDocument]];
}


/*———————————————————————————————————————————————————————————————————*
	handleTidySourceTextChange
		The tidyProcess changed the sourceText for some reason,
		probably because the user changed input-encoding. Note
		that this event is only received if Tidy itself changes
		the sourceText, not as the result of outside setting.
		The event chain will eventually update everything else.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidySourceTextChange:(NSNotification *)note
{
	[[self sourceView] setString:[[self tidyProcess] sourceText]];
}


/*———————————————————————————————————————————————————————————————————*
	handleTidyTidyTextChange
		|tidyText| changed, so update |tidyView| and |errorView|.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyTidyTextChange:(NSNotification *)note
{
	[[self tidyView] setString:[[self tidyProcess] tidyText]];		// Put the tidy'd text into the |tidyView|.
	[[self errorView] reloadData];									// Reload the error data.
	[[self errorView] deselectAll:self];							// Deselect the selected row.
}


/*———————————————————————————————————————————————————————————————————*
	textDidChange:
		We arrived here by virtue of being the delegate of
		|sourceView|. Simply update the tidyProcess sourceText,
		and the event chain will eventually update everything
		else.
 *———————————————————————————————————————————————————————————————————*/
- (void)textDidChange:(NSNotification *)aNotification
{
	if (![self documentIsLoading])
	{
		[[self tidyProcess] setSourceText:[[self sourceView] string]];
	}
	else
	{
		self.documentIsLoading = NO;
	}
	
	// Handle document dirty detection
	if ( (![[self tidyProcess] isDirty]) || ([[[self tidyProcess] sourceText] length] == 0 ) )
	{
		[self updateChangeCount:NSChangeCleared];
	}
	else
	{
		[self updateChangeCount:NSChangeDone];
	}

}


#pragma mark - Document Opening Encoding Error Support


/*———————————————————————————————————————————————————————————————————*
	inputEncodingSanityCheck
		We're called from windowControllerDidLoadNib.
		As a favor to the user, attempt some basic input-encoding
		sanity checking.
 *———————————————————————————————————————————————————————————————————*/
- (void)inputEncodingSanityCheck
{
	if ([self documentOpenedData])
	{
		NSStringEncoding currentInputEncoding = [[[self tidyProcess] optionValueForId:TidyInCharEncoding] longLongValue];
		NSUInteger dataSize = [[self documentOpenedData] length];
		NSUInteger stringSize = [[[NSString alloc] initWithData:[self documentOpenedData] encoding:currentInputEncoding] length];
		
		if ( (dataSize > 0) && (stringSize < 1) )
		{
			/*
				It's likely that the string wasn't decoded properly, so we will
				prepare and present a friendly NSPopover with an explanation and
				some options.
			*/
	
			/*
				We will try all of the following encodings until we get a hit.
			*/
			
			NSArray *encodingsToTry = @[@(NSUTF8StringEncoding),
										@([NSString defaultCStringEncoding]),
										@(NSMacOSRomanStringEncoding)];
			
			NSStringEncoding suggestedInputEncoding = NSMacOSRomanStringEncoding;
			for(NSNumber *encoding in encodingsToTry)
			{
				if ([[[NSString alloc] initWithData:[self documentOpenedData] encoding:[encoding longLongValue]] length] > 0)
				{
					suggestedInputEncoding = [encoding longLongValue];
					break;
				}
			}
						
			NSString *docName = [[self fileURL] lastPathComponent];
			NSString *encodingCurrent = [NSString localizedNameOfStringEncoding:currentInputEncoding];
			NSString *encodingSuggested = [NSString localizedNameOfStringEncoding:suggestedInputEncoding];

			NSString *newMessage = [NSString stringWithFormat:[[self textFieldEncodingExplanation] stringValue], docName, encodingCurrent, encodingSuggested];

			[[self textFieldEncodingExplanation] setStringValue:newMessage];
			
			[[self buttonEncodingDoNotWarnAgain] setState:[self ignoreInputEncodingWhenOpening]];
			NSLog(@"%ld", (long)self.buttonEncodingIgnoreSuggestion.state);
			
			[[self buttonEncodingAllowChange] setTag:suggestedInputEncoding]; // Cheat. We'll fetch this in the handler. Should be 64-bit.
			
			[[self sourceView] setEditable:NO];
			
			[[self popoverEncoding] showRelativeToRect:[[self sourceView] bounds]
										ofView:[self sourceView]
								 preferredEdge:NSMaxYEdge];
		}
	}
}


/*———————————————————————————————————————————————————————————————————*
	popoverHandler
		Handles all possibles actions from the input-encoding
		helper popover. The only two senders should be
		buttonAllowChange and buttonIgnoreSuggestion.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)popoverHandler:(id)sender
{
	if (sender == [self buttonEncodingAllowChange])
	{
		[[[self optionController] tidyDocument] setOptionValueForId:TidyInCharEncoding fromObject:@([[self buttonEncodingAllowChange] tag])];
		[[[self optionController] theTable] reloadData];
	}
	
	[[NSUserDefaults standardUserDefaults] setBool:[[self buttonEncodingDoNotWarnAgain] state] forKey:JSDKeyIgnoreInputEncodingWhenOpening];
	
	[[self sourceView] setEditable:YES];
	[[self popoverEncoding] performClose:self];
}


#pragma mark - First-Run Support


/*———————————————————————————————————————————————————————————————————*
	firstRunPopoverSequence
		Here we will kick off a short sequence of popovers that
		provide a basic introduction to Tidy's interface.
 *———————————————————————————————————————————————————————————————————*/
- (void)firstRunPopoverSequence
{
	
	[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainWelcome", nil)];
	[[self textFieldFirstRunExplanation] setTag:0];
	[[self popoverFirstRun] showRelativeToRect:[[self sourceView] bounds]
										ofView:[self sourceView]
								 preferredEdge:NSMinXEdge];
}


/*———————————————————————————————————————————————————————————————————*
	popoverFirstRunHandler
		We'll run the whole first-run sequence from here, using
		the textFieldFirstRunExplanation.tag to keep track.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)popoverFirstRunHandler:(id)sender
{
	NSInteger tag = [[self textFieldFirstRunExplanation] tag];
	
	if (tag == 0)
	{
		[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainTidyOptions", nil)];
		[[self textFieldFirstRunExplanation] setTag:1];
		[[self popoverFirstRun] showRelativeToRect:[[self optionPane] bounds]
											ofView:[self optionPane]
									 preferredEdge:NSMinXEdge];
	}

	
	if (tag == 1)
	{
		[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainSourceView", nil)];
		[[self textFieldFirstRunExplanation] setTag:2];
		[[self popoverFirstRun] showRelativeToRect:[[self sourceView] bounds]
											ofView:[self sourceView]
									 preferredEdge:NSMinXEdge];
	}

	if (tag == 2)
	{
		[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainTidyView", nil)];
		[[self textFieldFirstRunExplanation] setTag:3];
		[[self popoverFirstRun] showRelativeToRect:[[self tidyView] bounds]
											ofView:[self tidyView]
									 preferredEdge:NSMinXEdge];
	}

	if (tag == 3)
	{
		[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainErrorView", nil)];
		[[self textFieldFirstRunExplanation] setTag:4];
		[[self popoverFirstRun] showRelativeToRect:[[self errorView] bounds]
											ofView:[self errorView]
									 preferredEdge:NSMinXEdge];
	}

	if (tag == 4)
	{
		[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainPreferences", nil)];
		[[self textFieldFirstRunExplanation] setTag:5];
		[[self popoverFirstRun] showRelativeToRect:[[self optionPane] bounds]
											ofView:[self optionPane]
									 preferredEdge:NSMinXEdge];
	}

	if (tag == 5)
	{
		[[self textFieldFirstRunExplanation] setStringValue:NSLocalizedString(@"popOverExplainStart", nil)];
		[[self buttonFirstRunNext] setTitle:NSLocalizedString(@"popOverButtonDone", nil)];
		[[self textFieldFirstRunExplanation] setTag:6];
		[[self popoverFirstRun] showRelativeToRect:[[self tidyView] bounds]
											ofView:[self tidyView]
									 preferredEdge:NSMinYEdge];
	}

	if (tag == 6)
	{
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:JSDKeyFirstRunComplete];
		[[self popoverFirstRun] performClose:self];

	}
	
}


#pragma mark - Error Table Handling


/*———————————————————————————————————————————————————————————————————*
	numberOfRowsInTableView
		We're here because we're the |datasource| of the errorView.
		We need to specify how many items are in the table.
 *———————————————————————————————————————————————————————————————————*/
- (NSUInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[self tidyProcess] errorArray] count];
}


/*———————————————————————————————————————————————————————————————————*
	tableView:objectValueForTableColumn:row
		We're here because we're the |datasource| of the errorView.
		We need to specify what to show in the row/column. The
		error array consists of dictionaries with entries for
		`level`, `line`, `column`, and `message`.
 *———————————————————————————————————————————————————————————————————*/
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSDictionary *error = [[self tidyProcess] errorArray][rowIndex];

	if ([[aTableColumn identifier] isEqualToString:@"severity"])
	{
		/*
			The severity of the error reported by TidyLib is
			converted to a string label and localized into
			the current language.
		*/
		NSArray *errorTypes = @[@"Info:", @"Warning:", @"Config:", @"Access:", @"Error:", @"Document:", @"Panic:"];
		return NSLocalizedString(errorTypes[[error[@"level"] intValue]], nil);
	}

	if ([[aTableColumn identifier] isEqualToString:@"where"])
	{
		/*
			We can also localize N/A and line and column.
		*/
		if (([error[@"line"] intValue] == 0) || ([error[@"column"] intValue] == 0))
		{
			return NSLocalizedString(@"N/A", nil);
		}
		else
		{
			return [NSString stringWithFormat:@"%@ %@, %@ %@", NSLocalizedString(@"line", nil), error[@"line"], NSLocalizedString(@"column", nil), error[@"column"]];
		}
	}

	if ([[aTableColumn identifier] isEqualToString:@"description"])
	{
		/*
			Unfortunately we can't really localize the message without
			duplicating a lot of TidyLib functionality.
		*/
		return error[@"message"];
	}
	
	return @"";
}


/*———————————————————————————————————————————————————————————————————*
	tableViewSelectionDidChange:
		We arrived here because we're the delegate of the table.
		Whenever the selection changes, highlight the related
		column/row in the |sourceView|.
 *———————————————————————————————————————————————————————————————————*/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger errorViewRow = [[self errorView] selectedRow];
	if (errorViewRow >= 0)
	{
		NSInteger row = [[[self tidyProcess] errorArray][errorViewRow][@"line"] intValue];
		NSInteger col = [[[self tidyProcess] errorArray][errorViewRow][@"column"] intValue];
		
		if (row > 0)
		{
			[[self sourceView] highlightLine:row Column:col];
			return;
		}
	}
	
	[[self sourceView] setShowsHighlight:NO];
}


#pragma mark - Split View Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	splitView:constrainMinCoordinate:ofSubviewAt:
		We're here because we're the delegate of the split views.
		This allows us to set the minimum constraint of the left/top
		item in a splitview. Must coordinate max to ensure others
		have space, too.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition
														 ofSubviewAt:(NSInteger)dividerIndex
{
	// The main splitter
	if (splitView == [self splitLeftRight])
	{
		return 250.0f;
	}
	
	// The text views' first splitter
	if (dividerIndex == 0)
	{
		return 68.0f;
	}
	
	// The text views' second splitter is first plus 68.0f;
    return [[splitView subviews][0] frame].size.height + 68.0f;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	splitView:constrainMaxCoordinate:ofSubviewAt:
		We're here because we're the delegate of the split views.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMinimumPosition
														 ofSubviewAt:(NSInteger)dividerIndex
{
	// The main splitter
	if (splitView == [self splitLeftRight])
	{
		return [splitView frame].size.width - 150.0f;
	}
	
	// The text views' first splitter
	if (dividerIndex == 0)
	{
		return [[splitView subviews][0] frame].size.height +
				[[splitView subviews][1] frame].size.height - 68.0f;
	}
	
	// The text views' second splitter
	return [splitView frame].size.height - 68.0f;	
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	splitView:shouldAdjustSizeOfSubview:
		We're here because we're the delegate of the split views.
		Prevent the left pane from resizing during window resize.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if (splitView == [self splitLeftRight])
	{
		if (subview == [[self splitLeftRight] subviews][0])
		{
			return NO;
		}
	}
	return YES;
}


#pragma mark - Tab key handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	textView:doCommandBySelector:
		We're here because we're the delegate of |sourceView|.
		Allow the tab key to back in and out of this view.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertTab:))
	{
        [[aTextView window] selectNextKeyView:nil];
        return YES;
    }
	
    if (aSelector == @selector(insertBacktab:))
	{
        [[aTextView window] selectPreviousKeyView:nil];
        return YES;
    }
	
    return NO;
}


@end
