/**************************************************************************************************

	JSDTableViewController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  A standard NSViewController plus an outlet for an NSArrayController.
 */
@interface JSDTableViewController : NSViewController

@property (nonatomic, assign) IBOutlet NSArrayController *arrayController;

@end
