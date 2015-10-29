/**************************************************************************************************

	TidyDocumentWindowController
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

@class EncodingHelperController;
@class FirstRunController;
@class JSDTableViewController;
@class JSDTidyModel;
@class OptionPaneController;
@class TidyMessagesViewController;
@class TidyDocumentSourceViewController;


/**
 *  The main document window controller; manages the view and UI for a TidyDocument window.
 */
@interface TidyDocumentWindowController : NSWindowController


#pragma mark - Split Views
/** @name Split Views */

/** Outlet to the splitter between the options pane and everything else. */
@property (nonatomic, weak) IBOutlet NSSplitView *splitterOptions;

/** Outlet to the splitter between the messages pane and text pane. */
@property (nonatomic, weak) IBOutlet NSSplitView *splitterMessages;


#pragma mark -  Option Controller
/** @name Option Controller */


/** Empty pane in the NIB where optionController's view will live. */
@property (nonatomic, assign) IBOutlet NSView *optionPane;

/** The outer container where the optionPane and other elements exist. */
@property (nonatomic, assign) IBOutlet NSView *optionPaneContainer;

/** The OptionPaneController instance associated with this window controller. */
@property (nonatomic, strong) OptionPaneController *optionController;


#pragma mark - Messages Controller
/** @name Messages Controller */


/** The pane in the NIB where the message pane exists. */
@property (nonatomic, assign) IBOutlet NSView *messagesPane;

/** The JSDTableViewController instance associated with this window controller. */
@property (nonatomic, strong) JSDTableViewController *messagesController;


#pragma mark - Source Controller
/** @name Source Controller */


/** The pane in the NIB where the sourcePane will exist. */
@property (nonatomic, assign) IBOutlet NSView *sourcePane;

/** 
 *  The TidyDocumentSourceViewController instance for this window controller.
 *  It is assigned to either sourceControllerHorizontal or sourceControllerVertical
 *  as appropriate.
 */
@property (nonatomic, weak) TidyDocumentSourceViewController *sourceController;

/** The horizontal TidyDocumentSourceViewController instance for this window controller. */
@property (nonatomic, strong) TidyDocumentSourceViewController *sourceControllerHorizontal;

/** The vertical TidyDocumentSourceViewController instance for this window controller. */
@property (nonatomic, strong) TidyDocumentSourceViewController *sourceControllerVertical;


#pragma mark - Helpers
/** @name Helpers */


/** The first run controller. */
@property (nonatomic, strong) FirstRunController *firstRunHelper;

/** The encoding helper controller. */
@property (nonatomic, strong) EncodingHelperController *encodingHelper;


#pragma mark - React after saving a file
/** @name React after saving a file */


/** */
- (void)documentDidWriteFile;


#pragma mark - Properties that we will bind to for window control
/** @name Properties that we will bind to for window control */


/** Specifies whether or not the options panel is visible. */
@property (nonatomic, assign) BOOL optionsPanelIsVisible;

/** Specifies whether or not the messages panel is visible. */
@property (nonatomic, assign) BOOL messagesPanelIsVisible;

/** Specifies whether or not the source panel is visible. */
@property (nonatomic, assign) BOOL sourcePanelIsVertical;

/** Specifies whether or not the source panel line numbers are visble. */
@property (nonatomic, assign) BOOL sourcePaneLineNumbersAreVisible;


#pragma mark - Actions to support properties from Menus
/** @name Actions to support properties from Menus */

// @TODO: MAKE ALL OF THE STUFF BELOW INTO PROPERTIES.

/** Toggle visibility of the option panel. */
- (IBAction)toggleOptionsPanelIsVisible:(id)sender;

/** Toggle visibility of the messages panel. */
- (IBAction)toggleMessagesPanelIsVisible:(id)sender;

/** Toggle orientation of the source panel. */
- (IBAction)toggleSourcePanelIsVertical:(id)sender;

/** Toggle visibility of the line numbers. */
- (IBAction)toggleSourcePaneShowsLineNumbers:(id)sender;


#pragma mark - Toolbar Actions
/** @name Toolbar Actions */


/** 
 *  Place holder.
 *  Show the web preview of the tidy'd document.
 */
- (IBAction)handleWebPreview:(id)sender;

/**
 *  Place holder.
 *  Show the traditional diff panel.
 */
- (IBAction)handleShowDiffView:(id)sender;

/**
 *  Place holder.
 *  Toggle the display of the diff highlighter.
 *  Yes, this is a typo but will be replaced with a property.
 */
- (IBAction)toggleSyncronizedDiffs:(id)sender;

/**
 *  Place holder.
 *  Toggle synchronized scrolling of the source and tidy'd text.
 */
- (IBAction)toggleSynchronizedScrolling:(id)sender;


@end
