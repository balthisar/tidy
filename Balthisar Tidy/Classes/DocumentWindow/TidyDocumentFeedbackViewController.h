/**************************************************************************************************

	TidyDocumentFeedbackViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import <Cocoa/Cocoa.h>

@class JSDTableViewController;


/**
 *  The controller for the feedback panel, which includes all of the subviews for the tidy messages
 *  table as well as future, upcoming feedback views.
 */
@interface TidyDocumentFeedbackViewController : NSViewController


#pragma mark - Base Properties
/** @name Base Properties */


/** The enclosing container for all of the feedback subviews this controller will manage. */
@property (nonatomic, assign) IBOutlet NSTabView *tabView;


#pragma mark - Messages Controller
/** @name Messages Controller */


/** The pane in the NIB where the message pane exists. */
@property (nonatomic, assign) IBOutlet NSView *messagesPane;

/** The JSDTableViewController instance associated with this window controller. */
@property (nonatomic, strong) JSDTableViewController *messagesController;



@end
