/**************************************************************************************************

	TDFWebViewController

	Copyright © 2003-2017 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;
@import Foundation;
@import WebKit;

#import "TDFPreviewController.h"


/** 
 *  An NSViewController that handles a single WebView and associated display items, such as
 *  progress indicators, menus, and status text. It is tightly coupled with:
 *   - its owning instance of TDFPreviewController via the actionMenuDelegate property. 
 *   - Its Additionally it is tightly coupled to its represented object of type TidyDocument.
 */
@interface TDFWebViewController : NSViewController


#pragma mark - Main Properties
/** @name Main Properties */


/**
 * Indicates the base URL to be used by the webview for loading content. The webview uses this
 * as the base directory for loading relative assets.
 */
@property (readwrite, strong) NSURL *baseURL;

/**
 *  Indicates whether or not this item should display the action menu.
 */
@property (nonatomic, assign) BOOL showsActionMenu;

/**
 *  Indicates whether this item should display `tidyText` (the default) or not. If not, then
 *  `sourceText` will be displayed instead.
 */
@property (nonatomic, assign) BOOL showsTidyText;

/**
 *  Expose the webview's scrollview so that the owning controller can access it.
 */
@property (nonatomic, assign, readonly) NSScrollView *scrollView;

/**
 *  Not truly a delegate anymore, but a weak reference to the owning controller. It's used in
 *  interface bindings and elsewhere to bubble key data back up to the PreviewController.
 */
@property (nonatomic, assign) IBOutlet TDFPreviewController *actionMenuDelegate;


#pragma mark - Public Methods
/** @name Public Methods */


/** 
 * This method requests an update to the webview. Updates are not guaranteed to be instant and
 * are dependent on the application-level throttle setting.
 */
- (void)updateWebView;


@end
