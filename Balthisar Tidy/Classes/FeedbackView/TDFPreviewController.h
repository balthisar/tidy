/**************************************************************************************************

	TDFPreviewController

	Copyright © 2003-2017 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;
@import Foundation;
@import WebKit;


/**
 *  An NSViewController that handles one or two WebViewControllers, depending on the particular
 *  view mode. This controller manages their appearance, the values they display, relative display
 *  orientation, and so on.
 */
@interface TDFPreviewController : NSViewController


#pragma mark - Public Methods
/** @name Public Methods */


/**
 *  Intiates a request to update the webviews with the new strings.
 */
- (void)updateWebViews;


@end
