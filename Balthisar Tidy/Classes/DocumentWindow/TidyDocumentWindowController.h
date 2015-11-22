/**************************************************************************************************

	TidyDocumentWindowController
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

@class EncodingHelperController;
@class FirstRunController;
@class JSDTableViewController;
@class OptionPaneController;
@class TidyDocumentSourceViewController;
@class TidyDocumentFeedbackViewController;


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


#pragma mark - Feedback Controller
/** @name Feedback Controller */


/** The pane in the BIN where the feedback pane exists. */
@property (nonatomic, assign) IBOutlet NSView *feedbackPane;

/** The TidyDocumentFeedbackViewController 
 *  instance associated wit this window controller. */
@property (nonatomic, strong) TidyDocumentFeedbackViewController *feedbackController;


#pragma mark - Source Controller
/** @name Source Controller */


/** The pane in the NIB where the sourcePane will exist. */
@property (nonatomic, assign) IBOutlet NSView *sourcePane;

/** 
 *  The TidyDocumentSourceViewController instance for this window controller.
 */
@property (nonatomic, strong) TidyDocumentSourceViewController *sourceController;


#pragma mark - Helpers
/** @name Helpers */


/** The first run controller. */
@property (nonatomic, strong) FirstRunController *firstRunHelper;

/** The encoding helper controller. */
@property (nonatomic, strong) EncodingHelperController *encodingHelper;


#pragma mark - React after saving a file
/** @name React after saving a file */


/** This is called when the TidyDocument indicates that it wrong a file. */
- (void)documentDidWriteFile;


#pragma mark - Properties that we will bind to for window control
/** @name Properties that we will bind to for window control */


/** Specifies whether or not the options panel is visible. */
@property (nonatomic, assign) BOOL optionsPanelIsVisible;

/** Specifies whether or not the feedback panel is visible. */
@property (nonatomic, assign) BOOL feedbackPanelIsVisible;


#pragma mark - Actions to support properties from Menus
/** @name Actions to support properties from Menus */


/**
 *  Toggle visibility of the messages panel.
 *  Provided so that menu actions can invoke the first responder.
 */
- (IBAction)toggleFeedbackPanelIsVisible:(id)sender;

/**
 *  Toggle visibility of the option panel.
 *  Provided so that menu actions can invoke the first responder.
 */
- (IBAction)toggleOptionsPanelIsVisible:(id)sender;

/**
 *  Toggle aspect of the source panel.
 *  Provided so that menu actions can invoke the first responder.
 */
- (IBAction)toggleSourcePanelIsVertical:(id)sender;


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
