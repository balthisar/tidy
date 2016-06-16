/**************************************************************************************************

	TDFTableViewController

	Copyright © 2003-2016 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  A standard NSViewController plus an outlet for an NSArrayController.
 *  Recently expanded to also react to an control message filters.
 */
@interface TDFTableViewController : NSViewController

/**
 *  Determines what is visible in the messages table.
 */
typedef NS_OPTIONS(NSUInteger, TMSGFilterOptions) {
    TMSGNone     = 0,
    TMSGInfo     = 1,
    TMSGWarnings = 2,
    TMSGErrors   = 4,
    TMSGAccess   = 8,
    TMSGOther    = 16
};


/**
 *  An array controller that references the tidy error messages structure.
 */
@property (nonatomic, assign) IBOutlet NSArrayController *arrayController;


/**
 *  A bit mask indicating which combination of items is showing.
 */
@property (nonatomic, assign) TMSGFilterOptions showsMessages;

/**
 *  Indicates/controls whether or not Info messages are displayed.
 */
@property (nonatomic, assign) BOOL showsFilterInfo;

/**
 *  Indicates/controls whether or not Warning messages are displayed.
 */
@property (nonatomic, assign) BOOL showsFilterWarnings;

/**
 *  Indicates/controls whether or not Error messages are displayed.
 */
@property (nonatomic, assign) BOOL showsFilterErrors;

/**
 *  Indicates/controls whether or not Accessibility messages are displayed.
 */
@property (nonatomic, assign) BOOL showsFilterAccess;

/**
 *  Indicates/controls whether or not Other messages are displayed.
 */
@property (nonatomic, assign) BOOL showsFilterOther;


/**
 *  Returns the correct label for the Info button.
 */
@property (nonatomic, readonly, assign) NSString *labelForInfo;

/**
 *  Returns the correct label for the Warnings button.
 */
@property (nonatomic, readonly, assign) NSString *labelForWarnings;

/**
 *  Returns the correct label for the Errors button.
 */
@property (nonatomic, readonly, assign) NSString *labelForErrors;

/**
 *  Returns the correct label for the Access button.
 */
@property (nonatomic, readonly, assign) NSString *labelForAccess;

/**
 *  Returns the correct label for the Other button.
 */
@property (nonatomic, readonly, assign) NSString *labelForOther;

@end
