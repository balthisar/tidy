/**************************************************************************************************

	TidyDocumentSourceViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

@class JSDTextView;


/**
 *  The controller for the source panel, which includes the text fields for both untidy and
 *  tidy text. This controller manages interactions and the display orientation.
 */
@interface TidyDocumentSourceViewController : NSViewController <NSTextViewDelegate>

/** Outlet for the source TextView. */
@property (nonatomic, assign) IBOutlet JSDTextView *sourceTextView;

/** Outlet for the tidy TextView. */
@property (nonatomic, assign) IBOutlet NSTextView *tidyTextView;

/** Outlet for the splitter. */
@property (nonatomic, assign) IBOutlet NSSplitView *splitterViews;

/** Outlet for the label above the source TextView. */
@property (nonatomic, assign) IBOutlet NSTextField *sourceLabel;

/** Outlet for the label above the tidy TextView. */
@property (nonatomic, assign) IBOutlet NSTextField *tidyLabel;


/** Indicates that this instance is a vertically oriented view. */
@property (nonatomic, assign, readonly) BOOL isVertical;

/** Specifies whether or not the views are synchronized. @TODO place holder. */
@property (nonatomic, assign) BOOL viewsAreSynced;

/** Specifies whether or not the views are showing DIFFs. @TODO place holder. */
@property (nonatomic, assign) BOOL viewsAreDiffed;


/**
 *  Initializes a new instance, specifying whether or not the view is vertical.
 *  @param initVertical If YES, the view is vertical; if NO, the view is horizontal.
 */
- (instancetype)initVertical:(BOOL)initVertical;

/**
 *  After the Window Controller swaps out the views, it must let thea view controller
 *  know that it is ready and in place by calling this method.
 */
- (void)setupViewAppearance;

/** 
 *  Will highlight message-producing text in the source TextView based on
 *  the current record in the specified array controller.
 *  @param arrayController The array controller with the message data.
 */
- (void)highlightSourceTextUsingArrayController:(NSArrayController*)arrayController;


/**
 *  We will use this to tickle when used externally, since setting the string
 *  directly doesn't trigger notifications. This cheat supports our AppleScript
 *  Document suite, since it's the only use case in which we would set sourceText
 *  directly.
 */
- (void)textDidChange:(NSNotification *)aNotification;


@end
