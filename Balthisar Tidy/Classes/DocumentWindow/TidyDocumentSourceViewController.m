/**************************************************************************************************

	TidyDocumentSourceViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TidyDocumentSourceViewController.h"
#import "CommonHeaders.h"

#import <Fragaria/Fragaria.h>

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"
#import "TidyDocument.h"


@implementation TidyDocumentSourceViewController


#pragma mark - Initialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
  - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    NSString *nibName = @"TidyDocumentSourceView";

    if ((self = [super initWithNibName:nibName bundle:nil]))
    {
        _viewsAreSynced = NO;
        _viewsAreDiffed = NO;
    }
    
    return self;
}


/*———————————————————————————————————————————————————————————————————*
  - dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifySourceTextRestored object:[self.representedObject tidyProcess]];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:tidyNotifyOptionChanged object:[self.representedObject tidyProcess]];

	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyAllowMacOSTextSubstitutions];

    self.messagesArrayController = nil; // removes observer if one is present.
}

/*———————————————————————————————————————————————————————————————————*
  - awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
	
	/********************************************************
	 * Fragaria Groups
	 ********************************************************/
	
	MGSUserDefaultsController *sourceGroup = [MGSUserDefaultsController sharedControllerForGroupID:JSDKeyTidyEditorSourceOptions];
	MGSUserDefaultsController *tidyGroup = [MGSUserDefaultsController sharedControllerForGroupID:JSDKeyTidyEditorTidyOptions];

	[sourceGroup addFragariaToManagedSet:self.sourceTextView];
	[tidyGroup addFragariaToManagedSet:self.tidyTextView];

	/********************************************************
	 * Notifications, etc.
	 ********************************************************/
	
	/* NSNotifications from the document's sourceText, in case tidyProcess
	 * changes the sourceText.
	 */
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidySourceTextRestored:)
												 name:tidyNotifySourceTextRestored
											   object:[[self representedObject] tidyProcess]];

    /* NSNotifications from the `optionController` indicate that one or more options changed. 
     * We will use this to manage the page guide position.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTidyOptionChange:)
                                                 name:tidyNotifyOptionChanged
                                               object:[self.representedObject tidyProcess]];

	/* KVO on user prefs to look for Text Substitution Preference Changes */
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:JSDKeyAllowMacOSTextSubstitutions
											   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
											   context:NULL];
	
    /* KVO on user prefs to look for Wrap Margin Indicator Preference Changes */
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:JSDKeyShowWrapMarginNot
                                               options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                                               context:NULL];

    /* KVO on the errorArray so we can display inline errors. */
	[((TidyDocument*)self.representedObject).tidyProcess addObserver:self
														  forKeyPath:@"errorArray"
															 options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
															 context:NULL];
	
	/* Interface Builder doesn't allow us to define custom bindings, so we have to bind the tidyTextView manually. */
	[self.tidyTextView bind:@"string" toObject:self.representedObject withKeyPath:@"tidyProcess.tidyText" options:nil];


    self.splitterViews.vertical = [[[NSUserDefaults standardUserDefaults] objectForKey:JSDKeyShowNewDocumentSideBySide] boolValue];
    [self  setupViewAppearance];
}


#pragma mark - Delegate Methods


/*———————————————————————————————————————————————————————————————————*
  - textDidChange:
	We arrived here by virtue of being the delegate of
	`sourcetextView`. Simply update the tidyProcess sourceText,
	and the event chain will eventually update everything else.
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
  - textView:doCommandBySelector:
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


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - concludeDragOperation:
   We're here because we're the concludeDragOperationDelegte
   of `sourceTextView`.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pasteBoard = [sender draggingPasteboard];
	
	/**************************************************
	 The pasteboard contains a list of file names
	 **************************************************/
	if ( [[pasteBoard types] containsObject:NSFilenamesPboardType] )
	{
		NSArray *fileNames = [pasteBoard propertyListForType:@"NSFilenamesPboardType"];
		
		for (NSString *path in fileNames)
		{
			NSString *contents;
			
            NSData *rawData;
            if ((rawData = [NSData dataWithContentsOfFile:path]))
            {
                [NSString stringEncodingForData:rawData encodingOptions:nil convertedString:&contents usedLossyConversion:nil];
            }

			if (contents)
			{
				[self.sourceTextView.textView insertText:contents];
			}
			
		}
	}
}


#pragma mark - KVC and Notification Handling


/*———————————————————————————————————————————————————————————————————*
 - observeValueForKeyPath:ofObject:change:context:
   Handle KVO Notifications:
   - certain preferences changed.
   - the errorArray changed.
   - the messages table selection changed.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	/* Handle changes to the preferences for allowing or disallowing Mac OS X Text Substitutions */
	if ((object == [NSUserDefaults standardUserDefaults]) && ([keyPath isEqualToString:JSDKeyAllowMacOSTextSubstitutions]))
	{
		[self.sourceTextView.textView setAutomaticQuoteSubstitutionEnabled:[[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
		[self.sourceTextView.textView setAutomaticTextReplacementEnabled:[[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
		[self.sourceTextView.textView setAutomaticDashSubstitutionEnabled:[[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
	}

    /* Handle changes to the preferences for the `wrap` option margin indictor. */
    if ((object == [NSUserDefaults standardUserDefaults]) && ([keyPath isEqualToString:JSDKeyShowWrapMarginNot]))
    {
        self.tidyTextView.showsPageGuide = ![[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyShowWrapMarginNot] boolValue];
    }

	/* Handle changes from the errorArray so that we can setup our errors in the gutter. */
	if ((object == ((TidyDocument*)self.representedObject).tidyProcess) && ([keyPath isEqualToString:@"errorArray"]))
	{
		NSArray *localErrors = ((TidyDocument*)self.representedObject).tidyProcess.errorArray;
		NSMutableArray *highlightErrors = [[NSMutableArray alloc] init];
		
		for (NSDictionary *localError in localErrors)
		{
			SMLSyntaxError *newError = [SMLSyntaxError new];
			newError.errorDescription = localError[@"message"];
			newError.line = [localError[@"line"] intValue];
			newError.character = [localError[@"column"] intValue];
			newError.length = 1;
			newError.hidden = NO;
			newError.warningImage = localError[@"levelImage"];
			[highlightErrors addObject:newError];
		}
		
		self.sourceTextView.syntaxErrors = highlightErrors;
	}

    /* Handle changes to the selection of the messages table; go to line selected. */
    if ((object == self.messagesArrayController) && ([keyPath isEqualToString:@"selection"]))
    {
        NSArray *localObjects = self.messagesArrayController.arrangedObjects;

        NSUInteger errorViewRow = self.messagesArrayController.selectionIndex;

        if (errorViewRow < [localObjects count])
        {
            NSInteger row = [localObjects[errorViewRow][@"line"] intValue];

            if (row > 0)
            {
                [self.sourceTextView goToLine:row centered:NO highlight:NO];
            }
        }
    }

}


/*———————————————————————————————————————————————————————————————————*
  - handleTidySourceTextRestored:
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


/*———————————————————————————————————————————————————————————————————*
  - handleTidyOptionChange:
	One or more options changed in `optionController`.
    We're interested in the value of `wrap` so we can adjust our
    margin indicator. Note that we hit this at startup, too, because
    the window controller sets options after we are created.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
    if (note)
    {
        NSString *wrapValue = [note.userInfo valueForKey:@"wrap"];
        if (wrapValue)
        {
            int pageGuidePosition = [wrapValue intValue];
            self.tidyTextView.pageGuideColumn = pageGuidePosition;
            self.tidyTextView.showsPageGuide = (pageGuidePosition > 0) && (![[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyShowWrapMarginNot] boolValue]);
        }
    }
}


#pragma mark - Properties


/*———————————————————————————————————————————————————————————————————*
  @property messagesArrayController
 *———————————————————————————————————————————————————————————————————*/
- (void)setMessagesArrayController:(NSArrayController *)messagesArrayController
{
    if (_messagesArrayController)
    {
        [_messagesArrayController removeObserver:self forKeyPath:@"selection"];
    }

    if (messagesArrayController)
    {
        /* KVO on the `messagesArrayController` indicate that a message table row was selected.
         * Will use KVO on the array controller instead of a delegate method to capture changes
         * because the delegate doesn't catch when the table unselects all rows.
         */
        [messagesArrayController addObserver:self
                                  forKeyPath:@"selection"
                                     options:(NSKeyValueObservingOptionNew)
                                     context:NULL];
    }

    _messagesArrayController = messagesArrayController;
}


#pragma mark - Private Methods


/*———————————————————————————————————————————————————————————————————*
 - setupViewAppearance
 *———————————————————————————————————————————————————————————————————*/
- (void)setupViewAppearance
{
    /* This closure acts as a subroutine to avoid being repetitive. */

    void (^configureCommonViewSettings)(MGSFragariaView *) = ^(MGSFragariaView *aView) {

        NSUserDefaults *localDefaults = [NSUserDefaults standardUserDefaults];

        aView.syntaxDefinitionName = @"html";

        [aView.textView setAutomaticQuoteSubstitutionEnabled:[[localDefaults valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
        [aView.textView setAutomaticTextReplacementEnabled:[[localDefaults valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
        [aView.textView setAutomaticDashSubstitutionEnabled:[[localDefaults valueForKey:JSDKeyAllowMacOSTextSubstitutions] boolValue]];
        [aView.textView setImportsGraphics:NO];
        [aView.textView setAllowsImageEditing:NO];
        [aView.textView setUsesFontPanel:NO];
        [aView.textView setUsesInspectorBar:NO];
        [aView.textView setUsesFindBar:NO];
        [aView.textView setUsesFindPanel:NO];
    };

    configureCommonViewSettings(self.sourceTextView);
    configureCommonViewSettings(self.tidyTextView);


    /* tidyTextView special settings. */

    [self.tidyTextView.textView setAllowsUndo:NO];
    [self.tidyTextView.textView setEditable:NO];
    [self.tidyTextView.textView setRichText:NO];
    [self.tidyTextView.textView setSelectable:YES];
    [self.tidyTextView.textView setLineWrap:NO];

    /* sourceTextView shouldn't accept every drop type */
    [self.sourceTextView.textView registerForDraggedTypes:@[NSFilenamesPboardType]];
}


@end
