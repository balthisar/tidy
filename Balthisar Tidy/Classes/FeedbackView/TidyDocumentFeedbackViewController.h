//
//  TidyDocumentFeedbackViewController.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDFTableViewController;
@class TDFPreviewController;
@class TDFValidatorViewController;
@class MMTabBarView;


/**
 *  The controller for the feedback panel, which includes all of the subviews for the tidy messages
 *  table as well as the other feedback views.
 */
@interface TidyDocumentFeedbackViewController : NSViewController;


#pragma mark - Base Properties


/**
 *  The enclosing container for all of the feedback subviews this controller will manage. Each
 *  NSTabViewItem constitutes a particular piece of feedback, and each of these is managed by its
 *  own ViewController. Instead of the default, ugly TabView switcher, we will use MMTabBarView
 *  to control appearance, allow reordering, and simplify implementation of icons and indicators
 *  on the tabs.
 */
@property (nonatomic, assign) IBOutlet NSTabView *tabView;

/**
 *  The tabsBarView references our MMTabBarView instance. This items controls its partner, tabView.
 */
@property (nonatomic, assign) IBOutlet MMTabBarView *tabsBarView;

/**
 *  Exposes the NSTabView's selectedTabViewItem, and makes it read-write. We use this feature
 *  to set the current tab via keyPaths from the first run controller.
 */
@property (nonatomic, assign) NSTabViewItem *selectedTabViewItem;


#pragma mark - Messages Controller


/**
 *  The NSViewController instance associated with this tab. 
 */
@property (nonatomic, strong) TDFTableViewController *messagesController;

/**
 *  The tabViewItem in the NIB where the message pane exists.
 */
@property (nonatomic, assign) IBOutlet NSTabViewItem *messagesTabViewItem;

/**
 The pane in the NIB where the message pane exists.
 */
@property (nonatomic, assign) IBOutlet NSView *messagesPane;


#pragma mark - Web Preview Controller


/**
 *  The NSViewController instance associated with this tab.
 */
@property (nonatomic, strong) TDFPreviewController *previewController;

/**
 *  The tabViewItem in the NIB where the preview pane exists.
 */
@property (nonatomic, assign) IBOutlet NSTabViewItem *previewTabViewItem;

/**
 *  The pane in the NIB where the preview pane exists.
 */
@property (nonatomic, assign) IBOutlet NSView *previewPane;


#pragma mark - Validator Controller


/**
 *  The NSViewController instance associated with this tab.
 */
@property (nonatomic, strong) TDFValidatorViewController *validatorController;

/**
 *  The tabViewItem in the NIB where the table pane exists.
 */
@property (nonatomic, assign) IBOutlet NSTabViewItem *validatorTabViewItem;

/**
 *  The pane in the NIB where the table pane exists.
 */
@property (nonatomic, assign) IBOutlet NSView *validatorPane;



@end
