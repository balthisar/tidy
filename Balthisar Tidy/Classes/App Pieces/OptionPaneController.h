/**************************************************************************************************

	OptionPaneController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import "JSDTableViewDelegate.h"

@class JSDTidyModel;


/**
 *  The OptionPaneController is the main controller for all instances of the Tidy Option pane,
 *  which is used separately in document windows and also in Preferences.
 */

@interface OptionPaneController : NSViewController <NSTableViewDataSource, JSDTableViewDelegate>


/**
 *  Specifies the Tidy options that will be managed by instances of the class. Each
 *  element is an NSString containing the name of a Tidy option.
 */
@property (nonatomic, strong) NSArray *optionsInEffect;


/**
 *  Exposes the tidyDocument so that its tidyOptions and values can be accessed.
 */
@property (nonatomic, strong, readonly) JSDTidyModel *tidyDocument;

/**
 *  Specifies whether or not the view should reflect its use in Preferences versus
 *  its use in document windows, as there are item availability differences.
 */
@property (nonatomic, assign) BOOL isInPreferencesView;

/**
 *  Specifies whether or not the Tidy option description is visible or not.
 */
@property (nonatomic, assign) BOOL descriptionIsVisible;


@end
