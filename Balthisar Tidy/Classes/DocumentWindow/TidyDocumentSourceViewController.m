/**************************************************************************************************

	TidyDocumentSourceViewController
	 
	The source and tidy text view controller. Manages the two text fields, their interactions,
	and the type of display.
 

	The MIT License (MIT)

	Copyright (c) 2014 James S. Derry <http://www.balthisar.com>

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

#import "TidyDocumentSourceViewController.h"
#import "CommonHeaders.h"

#import "JSDTextView.h"
#import "JSDTidyModel.h"
#import "NSTextView+JSDExtensions.h"
#import "TidyDocument.h"


@implementation TidyDocumentSourceViewController


#pragma mark - Initialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
	initVertical: - designated initializer
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)initVertical:(BOOL)initVertical
{
	NSString *nibName = initVertical ? @"TidyDocumentSourceV" : @"TidyDocumentSourceH";

	if ((self = [super initWithNibName:nibName bundle:nil]))
	{
		_isVertical = initVertical;
		_viewsAreSynced = NO;
		_viewsAreDiffed = NO;
	}

	return self;
}


/*———————————————————————————————————————————————————————————————————*
	init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
	return [self initVertical:NO];
}


/*———————————————————————————————————————————————————————————————————*
	dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifySourceTextRestored object:[[self representedObject] tidyProcess]];

	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyAllowMacOSTextSubstitutions];
}

/*———————————————————————————————————————————————————————————————————*
	awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
	/*
		NSNotifications from the document's sourceText, in case tidyProcess
		changes the sourceText.
	 */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidySourceTextRestored:)
												 name:tidyNotifySourceTextRestored
											   object:[[self representedObject] tidyProcess]];

	/* KVO on user prefs to look for Text Substitution Preference Changes */
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:JSDKeyAllowMacOSTextSubstitutions
											   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
											   context:NULL];
}


#pragma mark - Delegate Methods


/*———————————————————————————————————————————————————————————————————*
	textDidChange:
		We arrived here by virtue of being the delegate of
		`sourcetextView`. Simply update the tidyProcess sourceText,
		and the event chain will eventually update everything
		else.
 *———————————————————————————————————————————————————————————————————*/
- (void)textDidChange:(NSNotification *)aNotification
{
	TidyDocument *localDocument = self.representedObject;

	/* Update the tidyProcess */

	localDocument.tidyProcess.sourceText = self.sourceTextView.string;

	/* Handle document dirty detection. */

	if ( (!localDocument.tidyProcess.isDirty) || (localDocument.tidyProcess.sourceText.length == 0) )
	{
		[localDocument updateChangeCount:NSChangeCleared];
	}
	else
	{
		[localDocument updateChangeCount:NSChangeDone];
	}
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	textView:doCommandBySelector:
		We're here because we're the delegate of `sourceTextView`.
		Allow the tab key to back in and out of this view.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if (aSelector == @selector(insertTab:))
	{
		[aTextView.window selectNextKeyView:nil];
		return YES;
	}

	if (aSelector == @selector(insertBacktab:))
	{
		[aTextView.window selectPreviousKeyView:nil];
		return YES;
	}

	return NO;
}


#pragma mark - KVC and Notification Handling


/*———————————————————————————————————————————————————————————————————*
	observeValueForKeyPath:ofObject:change:context:
		Handle KVC Notifications:
		- the processor's sourceText changed.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	/* Handle changes to the preferences for allowing or disallowing Mac OS X Text Substitutions */
	if ((object == [NSUserDefaults standardUserDefaults]) && ([keyPath isEqualToString:JSDKeyAllowMacOSTextSubstitutions]))
	{
		[self.sourceTextView setAutomaticQuoteSubstitutionEnabled:[[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
		[self.sourceTextView setAutomaticTextReplacementEnabled:[[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
		[self.sourceTextView setAutomaticDashSubstitutionEnabled:[[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
	}
}


/*———————————————————————————————————————————————————————————————————*
	handleTidySourceTextRestored:
		Handle changes to the tidyProcess's sourceText property.
		The tidyProcess changed the sourceText for some reason,
		probably because the user changed input-encoding. Note
		that this event is only received if Tidy itself changes
		the sourceText, not as the result of outside setting.
		The event chain will eventually update everything else.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidySourceTextRestored:(NSNotification *)note
{
	self.sourceTextView.string = ((TidyDocument*)self.representedObject).tidyProcess.sourceText;

	/* At this point, we're done loading the document */
	((TidyDocument*)self.representedObject).documentIsLoading = NO;
}


#pragma mark - Appearance Setup


/*———————————————————————————————————————————————————————————————————*
	setupViewAppearance
 *———————————————————————————————————————————————————————————————————*/
- (void)setupViewAppearance
{
	self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	[self.view setFrame:self.view.superview.bounds];

	[self configureViewSettings:self.sourceTextView];
	[self configureViewSettings:self.tidyTextView];
}


/*———————————————————————————————————————————————————————————————————*
	highlightSourceTextUsingArrayController
		Perform error highlighting on the source text using
		appropriate values from arrayController.
 *———————————————————————————————————————————————————————————————————*/
- (void)highlightSourceTextUsingArrayController:(NSArrayController*)arrayController
{
	self.sourceTextView.showsHighlight = NO;

	NSArray *localObjects = arrayController.arrangedObjects;

	NSInteger errorViewRow = arrayController.selectionIndex;

	if ((errorViewRow >= 0) && (errorViewRow < [localObjects count]))
	{
		NSInteger row = [localObjects[errorViewRow][@"line"] intValue];

		NSInteger col = [localObjects[errorViewRow][@"column"] intValue];

		if (row > 0)
		{
			[self.sourceTextView highlightLine:row Column:col];
		}
	}
}


#pragma mark - Private Methods


/*———————————————————————————————————————————————————————————————————*
	configureViewSettings: (private)
		Configure text view `aView` with uniform settings.
 *———————————————————————————————————————————————————————————————————*/
- (void)configureViewSettings:(NSTextView *)aView
{
	NSUserDefaults *localDefaults = [NSUserDefaults standardUserDefaults];

	[aView setFont:[NSFont fontWithName:@"Menlo" size:[NSFont systemFontSize]]];
	[aView setAutomaticQuoteSubstitutionEnabled:[[localDefaults valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
	[aView setAutomaticTextReplacementEnabled:[[localDefaults valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
	[aView setAutomaticDashSubstitutionEnabled:[[localDefaults valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];

	[aView setWordwrapsText:NO];
}


@end
