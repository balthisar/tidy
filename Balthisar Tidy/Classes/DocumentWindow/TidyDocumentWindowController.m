/**************************************************************************************************

	TidyDocumentWindowController
	 
	The main document window controller; manages the view and UI for a TidyDocument window.


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

#pragma mark - Notes

/**************************************************************************************************
 
	Event Handling and Interacting with the Tidy Processor
 
		The Tidy processor is loosely coupled with the document controller. Most
		interaction with it is handled via NSNotifications.
 
		If user types text the SourceViewController receive a `textDidChange` delegate notification,
		and we will set new text in [tidyProcess sourceText]. The event chain will eventually handle
		everything else.
 
		If `tidyText` changes we will receive NSNotification, and put the new `tidyText`
		into the `tidyView`, and also update `messagesViewController`.
  
		If `optionController` sends an NSNotification, then we will copy the new
		options to `tidyProcess`. The event chain will eventually handle everything else.
 
		If we set `sourceText` via file or data (only happens when opening or reverting)
		we will NOT update `sourceView`. We will wait for `tidyProcess` NSNotification that
		the `sourceText` changed, then set the `sourceView`. HOWEVER this presents a small
		issue to overcome:
 
			- If we set `sourceView` we will get `textDidChange` notification, causing
			  us to update [tidyProcess sourceText] again, resulting in processing the
			  document twice, which we don't want to do.
 
			- To prevent this we will set `documentIsLoading` to YES any time we we set
			  `sourceText` from file or data. In the `textDidChange` handler we will NOT
			  set [tidyProcess sourceText], and we will flip `documentIsLoading` back to NO.
 
 **************************************************************************************************/

#import "TidyDocumentWindowController.h"
#import "PreferencesDefinitions.h"
#import "PreferenceController.h"
#import "JSDTidyModel.h"
#import "TidyDocument.h"
#import "OptionPaneController.h"
#import "NSTextView+JSDExtensions.h"
#import "FirstRunController.h"
#import "EncodingHelperController.h"
#import "JSDTableViewController.h"
#import "TidyDocumentSourceViewController.h"


@implementation TidyDocumentWindowController
{
	CGFloat _savedPositionWidth;   // "static" for saving options width.
	CGFloat _savedPositionHeight;  // "static" for saving messages height,
}


@synthesize sourcePaneLineNumbersAreVisible = _sourcePaneLineNumbersAreVisible;

#pragma mark - Initialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
	init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
	self = [super initWithWindowNibName:@"TidyDocumentWindow"];

	if (self)
	{
		// Nothing to see here.
	}

	return self;
}


/*———————————————————————————————————————————————————————————————————*
	dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	TidyDocument *localDocument = self.document;

	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifyOptionChanged object:self.optionController.tidyDocument];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifyPossibleInputEncodingProblem object:localDocument.tidyProcess];

	[self.messagesController.arrayController removeObserver:self forKeyPath:@"selection"];
}


#pragma mark - Setup


/*———————————————————————————————————————————————————————————————————*
	awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
	/******************************************************
		Setup the optionController and its view settings. 
	 ******************************************************/

	self.optionController = [[OptionPaneController alloc] init];

	[self.optionPane addSubview:self.optionController.view];

	self.optionsPanelIsVisible = [[[NSUserDefaults standardUserDefaults] objectForKey:JSDKeyShowNewDocumentTidyOptions] boolValue];

	self.optionController.optionsInEffect = [PreferenceController optionsInEffect];

	/*
		Make the optionController take the default values. This actually
		causes the empty document to go through processTidy one time.
	 */
	[self.optionController.tidyDocument takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];


	/******************************************************
		Setup the messagesController and its view settings.
	 ******************************************************/

	self.messagesController = [[JSDTableViewController alloc] initWithNibName:@"TidyDocumentMessagesView" bundle:nil];

	self.messagesController.representedObject = self.document;

	[self.messagesPane addSubview:self.messagesController.view];

	self.messagesController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	[self.messagesController.view setFrame:self.messagesPane.bounds];

	self.messagesPanelIsVisible = [[[NSUserDefaults standardUserDefaults] objectForKey:JSDKeyShowNewDocumentMessages] boolValue];


	/******************************************************
		Setup the sourceController and its view settings.
	 ******************************************************/

	self.sourcePanelIsVertical  = [[[NSUserDefaults standardUserDefaults] objectForKey:JSDKeyShowNewDocumentSideBySide] boolValue];
	self.sourcePaneLineNumbersAreVisible = [[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyShowNewDocumentLineNumbers] boolValue];

	
	/******************************************************
		Remaining initial document conditions.
	 ******************************************************/

	/*
		Make the local processor take the default values. This causes
		the empty document to go through processTidy a second time.
	 */
	[((TidyDocument*)self.document).tidyProcess takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];


	/*
		Delay setting up notifications until now, because otherwise
		all of the earlier options setup is simply going to result
		in a huge cascade of notifications and updates.
	 */

	/* NSNotifications from the `optionController` indicate that one or more options changed. */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyOptionChange:)
												 name:tidyNotifyOptionChanged
											   object:[[self optionController] tidyDocument]];

	/* NSNotifications from the `tidyProcess` indicate that the input-encoding might be wrong. */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyInputEncodingProblem:)
												 name:tidyNotifyPossibleInputEncodingProblem
											   object:((TidyDocument*)self.document).tidyProcess];

	/*
		KVO on the `arrayController` indicate that a message table row was selected.
		Will use KVO on the array controller instead of a delegate method to capture changes
		because the delegate doesn't catch when the table unselects all rows (meaning that
		highlighted text in the sourceText stays behind). This prevents that.
	 */
	[self.messagesController.arrayController addObserver:self
											  forKeyPath:@"selection"
												 options:(NSKeyValueObservingOptionNew)
												 context:NULL];
	
	
	/* Manually adjust the view sizes. For some reason automatic restoration isn't working. */
	NSRect localRect = NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:@"NSSplitView Subview Frames UIPositionsSplitter01"][0]);
	[self.splitterOptions setPosition:localRect.size.width ofDividerAtIndex:0];

	localRect = NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:@"NSSplitView Subview Frames UIPositionsSplitter02"][0]);
	if (localRect.size.height > 0.0f)
	{
		[self.splitterMessages setPosition:localRect.size.height ofDividerAtIndex:0];
	}
}


/*———————————————————————————————————————————————————————————————————*
	windowDidLoad
		This method handles initialization after the window 
		controller's window has been loaded from its nib file.
 *———————————————————————————————————————————————————————————————————*/
- (void)windowDidLoad
{
	[super windowDidLoad];

	[self.window setInitialFirstResponder:self.optionController.view];

	/*
		We will set the tidyProcess' source text (nil assigment is 
		okay). If we try this in awakeFromNib, we might receive a
		notification before the	nibs are all done loading, so we 
		will do this here.
	 */
	[((TidyDocument*)self.document).tidyProcess setSourceTextWithData:((TidyDocument*)self.document).documentOpenedData];


	/* Run through the new user helper if appropriate */

	if (![[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyFirstRunComplete] boolValue])
	{
		[self kickOffFirstRunSequence:nil];
	}
	
}


#pragma mark - Event and KVO Notification Handling


/*———————————————————————————————————————————————————————————————————*
	handleTidyOptionChange:
		One or more options changed in `optionController`. Copy
		those options to our `tidyProcess`. The event chain will
		eventually update everything else because this should
		cause the tidyText to change.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
	[((TidyDocument*)self.document).tidyProcess optionsCopyValuesFromModel:self.optionController.tidyDocument];
}


/*———————————————————————————————————————————————————————————————————*
	handleTidyInputEncodingProblem:
		We're here as the result of a notification. The value for
		input-encoding might have been wrong for the file
		that tidy is trying to process.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyInputEncodingProblem:(NSNotification*)note
{
	if (![[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyIgnoreInputEncodingWhenOpening] boolValue])
	{
		self.encodingHelper = [[EncodingHelperController alloc] initWithNote:note fromDocument:self.document forView:self.sourceController.sourceTextView];
#ifdef FEATURE_EMPHASIZE_HELPER
		[self.window setAlphaValue:0.0f];
#endif
		[self.encodingHelper startHelper];
	}
}


/*———————————————————————————————————————————————————————————————————*
	documentDidWriteFile
		We're here because the TidyDocument indicated that it
		wrote a file. We have to update the view to reflect the
		new, saved state.
 *———————————————————————————————————————————————————————————————————*/
- (void)documentDidWriteFile
{
	self.sourceController.sourceTextView.string = ((TidyDocument*)self.document).tidyProcess.tidyText;

	/* force the event cycle so errors can be updated. */
	((TidyDocument*)self.document).tidyProcess.sourceText = self.sourceController.sourceTextView.string;
}


/*———————————————————————————————————————————————————————————————————*
	observeValueForKeyPath:ofObject:change:context:
		Handle KVC Notifications:
		- error view selection changed.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	/* Handle changes to the selection of the messages table. */

	if ((object == self.messagesController.arrayController) && ([keyPath isEqualToString:@"selection"]))
	{
		[self.sourceController highlightSourceTextUsingArrayController:self.messagesController.arrayController];
	}
}


#pragma mark - Split View Handling


/*———————————————————————————————————————————————————————————————————*
	splitView:canCollapseSubview
		Supports hiding the tidy options and/or messsages panels.
		Although we're handing this programmatically, this delegate
		method is still required if we want it to work.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	NSView *viewOfInterest;

	if ([splitView isEqual:self.splitterOptions])
	{
		viewOfInterest = [[splitView subviews] objectAtIndex:0];
	}

	if ([splitView isEqual:self.splitterMessages])
	{
		viewOfInterest = [[splitView subviews] objectAtIndex:1];
	}

    return ([subview isEqual:viewOfInterest]);
}


#pragma mark - Menu and State Validation


/*———————————————————————————————————————————————————————————————————*
	validateMenuItem:
		Validates and sets main menu items. We could use instead
		validateUserInterfaceItem:, but we're only worried about
		menus and this ensures everything is a menu item. All of
		the toolbars are validated via bindings.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(kickOffFirstRunSequence:))
	{
		[menuItem setState:self.firstRunHelper.isVisible];
		return !self.firstRunHelper.isVisible;
	}

	if (menuItem.action == @selector(toggleOptionsPanelIsVisible:))
	{
		[menuItem setState:self.optionsPanelIsVisible];
		return !self.firstRunHelper.isVisible;
	}

	if (menuItem.action == @selector(toggleMessagesPanelIsVisible:))
	{
		[menuItem setState:self.messagesPanelIsVisible];
		return !self.firstRunHelper.isVisible;
	}

	if (menuItem.action == @selector(toggleSourcePanelIsVertical:))
	{
		[menuItem setState:self.sourcePanelIsVertical];
		return !self.firstRunHelper.isVisible;
	}

	if (menuItem.action == @selector(toggleSourcePaneShowsLineNumbers:))
	{
		[menuItem setState:self.sourcePaneLineNumbersAreVisible];
		return YES;
	}

	return NO;
}


#pragma mark - Properties


/*———————————————————————————————————————————————————————————————————*
	optionsPaneIsVisible
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet*)keyPathsForValuesAffectingOptionsPanelIsVisible
{
	return [NSSet setWithObject:@"self.optionPaneContainer.hidden"];
}

- (BOOL)optionsPanelIsVisible
{
	NSView *viewOfInterest = [[self.splitterOptions subviews] objectAtIndex:0];

	BOOL isCollapsed = [self.splitterOptions isSubviewCollapsed:viewOfInterest];
	
	return !isCollapsed;
}

- (void)setOptionsPanelIsVisible:(BOOL)optionsPanelIsVisible
{
	/*
		If the savedPosition is zero, this is the first time we've been here. In that
		case let's get the value from the actual pane, which should be either the
		IB default or whatever came in from user defaults.
	 */

	if (_savedPositionWidth == 0.0f)
	{
		_savedPositionWidth = ((NSView*)[[self.splitterOptions subviews] objectAtIndex:0]).frame.size.width;
	}


    if (optionsPanelIsVisible)
	{
		[self.splitterOptions setPosition:_savedPositionWidth ofDividerAtIndex:0];
    }
	else
	{
		_savedPositionWidth = ((NSView*)[[self.splitterOptions subviews] objectAtIndex:0]).frame.size.width;
		[self.splitterOptions setPosition:0.0f ofDividerAtIndex:0];
    }
}


/*———————————————————————————————————————————————————————————————————*
	messagesPanelIsVisible
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet*)keyPathsForValuesAffectingMessagesPanelIsVisible
{
	return [NSSet setWithObject:@"self.messagesPane.hidden"];
}

- (BOOL)messagesPanelIsVisible
{
	NSView *viewOfInterest = [[self.splitterMessages subviews] objectAtIndex:1];

	BOOL isCollapsed = [self.splitterMessages isSubviewCollapsed:viewOfInterest];

	return !isCollapsed;
}

- (void)setMessagesPanelIsVisible:(BOOL)messagesPanelIsVisible
{
	/*
	 If the savedPosition is zero, this is the first time we've been here. In that
	 case let's get the value from the actual pane, which should be either the
	 IB default or whatever came in from user defaults.
	 */

	if (_savedPositionHeight == 0.0f)
	{
		_savedPositionHeight = ((NSView*)[[self.splitterMessages subviews] objectAtIndex:1]).frame.size.height;
	}


    if (messagesPanelIsVisible)
	{
		CGFloat splitterHeight = self.splitterMessages.frame.size.height;
		[self.splitterMessages setPosition:(splitterHeight - _savedPositionHeight) ofDividerAtIndex:0];
    }
	else
	{
		_savedPositionHeight = ((NSView*)[[self.splitterMessages subviews] objectAtIndex:1]).frame.size.height;
		[self.splitterMessages setPosition:self.splitterMessages.frame.size.height ofDividerAtIndex:0];
    }
}


/*———————————————————————————————————————————————————————————————————*
	sourcePanelIsVertical
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)sourcePanelIsVertical
{
	return self.sourceController.isVertical;
}

- (void)setSourcePanelIsVertical:(BOOL)sourcePanelIsVertical
{
	/* Setup (and create if necessary) the appropriate subview controller */

	if (!sourcePanelIsVertical)
	{
		if (!self.sourceControllerHorizontal)
		{
			self.sourceControllerHorizontal = [[TidyDocumentSourceViewController alloc] initVertical:NO];
			self.sourceControllerHorizontal.representedObject = self.document;
		}

		self.sourceController = self.sourceControllerHorizontal;
	}
	else
	{
		if (!self.sourceControllerVertical)
		{
			self.sourceControllerVertical = [[TidyDocumentSourceViewController alloc] initVertical:YES];
			self.sourceControllerVertical.representedObject = self.document;
		}

		self.sourceController = self.sourceControllerVertical;
	}

	[self.sourcePane setSubviews:[NSArray array]];
	[self.sourcePane addSubview:self.sourceController.view];

	[self.sourceController setupViewAppearance];
	self.sourcePaneLineNumbersAreVisible = _sourcePaneLineNumbersAreVisible;

	/* Ensure that the correct text is in the source */

	self.sourceController.sourceTextView.string = ((TidyDocument*)self.document).tidyProcess.sourceText;


	/* In case something is selected in the messages table, highlight it again. */

	[self.sourceController highlightSourceTextUsingArrayController:self.messagesController.arrayController];
}

/*———————————————————————————————————————————————————————————————————*
	lineNumbersAreVisible
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)sourcePaneLineNumbersAreVisible
{
	return _sourcePaneLineNumbersAreVisible;
}

- (void)setSourcePaneLineNumbersAreVisible:(BOOL)sourcePaneLineNumbersAreVisible
{
	self.sourceController.sourceTextView.showsLineNumbers = sourcePaneLineNumbersAreVisible;
	self.sourceController.tidyTextView.showsLineNumbers = sourcePaneLineNumbersAreVisible;
	_sourcePaneLineNumbersAreVisible = sourcePaneLineNumbersAreVisible;
}


#pragma mark - Menu Actions


- (IBAction)toggleOptionsPanelIsVisible:(id)sender
{
	self.optionsPanelIsVisible = !self.optionsPanelIsVisible;
}


- (IBAction)toggleMessagesPanelIsVisible:(id)sender
{
	self.messagesPanelIsVisible = !self.messagesPanelIsVisible;
}


- (IBAction)toggleSourcePanelIsVertical:(id)sender
{
	self.sourcePanelIsVertical = !self.sourcePanelIsVertical;
}

- (IBAction)toggleSourcePaneShowsLineNumbers:(id)sender
{
	self.sourcePaneLineNumbersAreVisible = !self.sourcePaneLineNumbersAreVisible;
}


#pragma mark - Toolbar Actions


/*———————————————————————————————————————————————————————————————————*
	handleWebPreview:
		Show the web preview of the tidy'd document.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleWebPreview:(id)sender
{
	NSLog(@"%@", @"Here is where we will show the web preview.");
}


/*———————————————————————————————————————————————————————————————————*
	handleShowDiffView:
		Show the traditional diff panel.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleShowDiffView:(id)sender
{
	NSLog(@"%@", @"Here is where we will show the traditional diff panel.");
}


/*———————————————————————————————————————————————————————————————————*
	toggleSyncronizedDiffs:
		Toggle the display of the diff highlighter.
		Yes, this is a typo but will be replaced with a property.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleSyncronizedDiffs:(id)sender
{
	NSLog(@"%@", @"Here we will toggle sync'd diffs.");
}


/*———————————————————————————————————————————————————————————————————*
	toggleSynchronizedScrolling:
		Toggle synchronized scrolling of the source and tidy'd text.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleSynchronizedScrolling:(id)sender
{
	NSLog(@"%@", @"Here is where we toggle sync'd scrolling.");
}


#pragma mark - Quick Tutorial Support


/*———————————————————————————————————————————————————————————————————*
	kickOffFirstRunSequence:
		Kicks off the first run sequence. Exposed so we can handle
		requests as the first responder.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)kickOffFirstRunSequence:(id)sender;
{
	NSArray *firstRunSteps = @[
							   @{ @"message": NSLocalizedString(@"popOverExplainWelcome", nil),
								  @"showRelativeToRect": NSStringFromRect(self.sourceController.sourceTextView.bounds),
								  @"ofView": self.sourceController.sourceTextView,
								  @"preferredEdge": @(NSMinXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainTidyOptions", nil),
								  @"showRelativeToRect": NSStringFromRect(self.optionPane.bounds),
								  @"ofView": self.optionPane,
								  @"preferredEdge": @(NSMinXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainSourceView", nil),
								  @"showRelativeToRect": NSStringFromRect(self.sourceController.sourceTextView.bounds),
								  @"ofView": self.sourceController.sourceTextView,
								  @"preferredEdge": @(NSMinXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainTidyView", nil),
								  @"showRelativeToRect": NSStringFromRect(self.sourceController.tidyTextView.bounds),
								  @"ofView": self.sourceController.tidyTextView,
								  @"preferredEdge": @(NSMinXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainErrorView", nil),
								  @"showRelativeToRect": NSStringFromRect(self.messagesPane.bounds),
								  @"ofView": self.messagesPane,
								  @"preferredEdge": @(NSMinXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainPreferences", nil),
								  @"showRelativeToRect": NSStringFromRect(self.optionPane.bounds),
								  @"ofView": self.optionPane,
								  @"preferredEdge": @(NSMinXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainSplitters", nil),
								  @"showRelativeToRect": NSStringFromRect(self.optionPane.bounds),
								  @"ofView": self.optionPane,
								  @"preferredEdge": @(NSMaxXEdge) },

							   @{ @"message": NSLocalizedString(@"popOverExplainStart", nil),
								  @"showRelativeToRect": NSStringFromRect(self.sourceController.tidyTextView.bounds),
								  @"ofView": self.sourceController.tidyTextView,
								  @"preferredEdge": @(NSMinYEdge) },
							   ];

	self.firstRunHelper = [[FirstRunController alloc] initWithSteps:firstRunSteps];

	self.firstRunHelper.preferencesKeyName = JSDKeyFirstRunComplete;

	if (!self.optionsPanelIsVisible)
	{
		self.optionsPanelIsVisible = YES;
	}

	if (!self.messagesPanelIsVisible)
	{
		self.messagesPanelIsVisible = YES;
	}
#ifdef FEATURE_EMPHASIZE_HELPER
		[self.window setAlphaValue:0.0f];
#endif
	
	[self.firstRunHelper beginFirstRunSequence];
}


#pragma mark - Private Methods


@end
