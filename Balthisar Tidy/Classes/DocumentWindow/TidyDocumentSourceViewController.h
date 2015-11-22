/**************************************************************************************************

	TidyDocumentSourceViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import <Fragaria/MGSDragOperationDelegate.h>

@class MGSFragariaView;


/**
 *  The controller for the source panel, which includes the text fields for both untidy and
 *  tidy text. This controller manages interactions and the display orientation.
 */
@interface TidyDocumentSourceViewController : NSViewController <NSTextViewDelegate, MGSDragOperationDelegate>


#pragma mark - Properties
/** @name Properties */


/** Outlet for the current source TextView. */
@property (nonatomic, assign) IBOutlet MGSFragariaView *sourceTextView;

/** Outlet for the current tidy TextView. */
@property (nonatomic, assign) IBOutlet MGSFragariaView *tidyTextView;

/** Outlet for the current splitter. */
@property (nonatomic, assign) IBOutlet NSSplitView *splitterViews;

/** Outlet for the current label above the source TextView. */
@property (nonatomic, assign) IBOutlet NSTextField *sourceLabel;

/** Outlet for the current label above the tidy TextView. */
@property (nonatomic, assign) IBOutlet NSTextField *tidyLabel;


/** A reference to an NSArrayController to monitor for selection changes.
 *  This should be set by a superior controller so that we know which NSArray
 *  controller to monitor.
 */
@property (nonatomic, weak) NSArrayController *messagesArrayController;

/** Specifies whether or not the views are synchronized. @TODO place holder. */
@property (nonatomic, assign) BOOL viewsAreSynced;

/** Specifies whether or not the views are showing DIFFs. @TODO place holder. */
@property (nonatomic, assign) BOOL viewsAreDiffed;


#pragma mark - Other


/**
 *  We will use this to tickle when used externally, since setting the string
 *  directly doesn't trigger notifications. This cheat supports our AppleScript
 *  Document suite, since it's the only use case in which we would set sourceText
 *  directly.
 */
- (void)textDidChange:(NSNotification *)aNotification;


@end
