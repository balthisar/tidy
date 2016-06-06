/**************************************************************************************************

	TDFTableViewController

	Copyright © 2003-2016 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  A standard NSViewController plus an outlet for an NSArrayController.
 */
@interface TDFTableViewController : NSViewController

@property (nonatomic, assign) IBOutlet NSArrayController *arrayController;

@end
