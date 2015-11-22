/**************************************************************************************************

	TidyDocumentFeedbackViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TidyDocumentFeedbackViewController.h"

#import "JSDTableViewController.h"


@interface TidyDocumentFeedbackViewController ()

@end

@implementation TidyDocumentFeedbackViewController


#pragma mark - Intialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
 - dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    [self.messagesController.arrayController removeObserver:self forKeyPath:@"selection"];
}




/*———————————————————————————————————————————————————————————————————*
 - awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
    /******************************************************
     Setup the messagesController and its view settings.
     ******************************************************/

    self.messagesController = [[JSDTableViewController alloc] initWithNibName:@"TidyDocumentFeedbackMessagesView" bundle:nil];

    self.messagesController.representedObject = self.representedObject;

    [self.messagesPane addSubview:self.messagesController.view];

    self.messagesController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.messagesController.view setFrame:self.messagesPane.bounds];
    
}

@end
