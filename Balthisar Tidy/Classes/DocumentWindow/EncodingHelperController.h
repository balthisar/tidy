/**************************************************************************************************

	EncodingHelperController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import "TidyDocument.h"
#import "AuxilliaryViewDelegate.h"


/**
 *  Implements the encoding helper for Balthisar Tidy documents.
 */
@interface EncodingHelperController : NSViewController <AuxilliaryViewDelegate>


/**
 *  Initializes the helper.
 *  @param note The notification. See JSDTidyFramwork for format.
 *  @param document The tidy document that the notification applies to.
 *  @param view The associated view that the helper view should be bound to.
 */
- (instancetype)initWithNote:(NSNotification*)note fromDocument:(TidyDocument*)document forView:(NSView*)view;

/**
 *  Starts the helper.
 */
- (void)startHelper;

/**
 *  Delegate for instances of this class, per <AuxilliaryViewDelegate>
 */
@property (nonatomic, assign) id delegate;

@end
