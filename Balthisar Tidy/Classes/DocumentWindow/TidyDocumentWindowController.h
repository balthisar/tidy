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

#import <Cocoa/Cocoa.h>

@class OptionPaneController;
@class EncodingHelperController;
@class FirstRunController;
@class JSDTidyModel;
@class TidyMessagesViewController;
@class TidyDocumentSourceViewController;
@class JSDTableViewController;


@interface TidyDocumentWindowController : NSWindowController

/* Split Views */

@property (weak) IBOutlet NSSplitView *splitterOptions;

@property (weak) IBOutlet NSSplitView *splitterMessages;


/* Option Controller */

@property (assign) IBOutlet NSView *optionPane;     // Empty pane in NIB where optionController's view will live.

@property (assign) IBOutlet NSView *optionPaneContainer; 

@property OptionPaneController *optionController;


/* Messages Controller */

@property (assign) IBOutlet NSView *messagesPane;

@property JSDTableViewController *messagesController;


/* Source Controller */

@property (assign) IBOutlet NSView *sourcePane;

@property TidyDocumentSourceViewController *sourceController;

@property TidyDocumentSourceViewController *sourceControllerHorizontal;

@property TidyDocumentSourceViewController *sourceControllerVertical;


/* Helpers */

@property FirstRunController *firstRunHelper;

@property EncodingHelperController *encodingHelper;


/* React after saving a file */

- (void)documentDidWriteFile;


/* Properties that we will bind to for window control */

@property BOOL optionsPanelIsVisible;

@property BOOL messagesPanelIsVisible;

@property BOOL sourcePanelIsVertical;

@property BOOL sourcePaneLineNumbersAreVisible;


/* Actions to support properties from Menus */
- (IBAction)toggleOptionsPanelIsVisible:(id)sender;
- (IBAction)toggleMessagesPanelIsVisible:(id)sender;
- (IBAction)toggleSourcePanelIsVertical:(id)sender;
- (IBAction)toggleSourcePaneShowsLineNumbers:(id)sender;



/* Toolbar Actions */

- (IBAction)handleWebPreview:(id)sender;

- (IBAction)handleShowDiffView:(id)sender;

- (IBAction)toggleSyncronizedDiffs:(id)sender;

- (IBAction)toggleSynchronizedScrolling:(id)sender;


@end
