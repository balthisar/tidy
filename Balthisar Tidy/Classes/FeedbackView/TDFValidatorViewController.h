//
//  TDFValidatorViewController.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;
@import JSDNuVFramework;


/**
 *  A standard NSViewController plus an outlet for an NSArrayController, with
 *  coupling to the represented object to supply validation documents. Also
 *  owns and manages two instances of JSDValidator in order to perform the
 *  required validation.
 */
@interface TDFValidatorViewController : NSViewController <JSDNuValidatorDelegate>


#pragma mark - IB Reference Properties


/**
 *  An array controller to provide data to the table. Will be programmatically
 *  bound to one of the two instances of JSDValidator in order to access the
 *  underlying data.
 */
@property (nonatomic, assign) IBOutlet NSArrayController *arrayController;


/** Exposed source text  validator.
 */
@property (nonatomic, strong) JSDNuValidator *sourceValidator;


/** Exposed Tidy'd text  validator.
 */
@property (nonatomic, strong) JSDNuValidator *tidyValidator;


/** The view with the filter buttons, so that it can be shown/hidden.
 */
@property (nonatomic, assign) IBOutlet NSView *filterView;


/** A reference to the refresh push button.
 */
@property (nonatomic, assign) IBOutlet NSButton *buttonRefresh;


/** A reference to the progress indicator.
 */
@property (nonatomic, assign) IBOutlet NSProgressIndicator *indicatorProgress;


/** A reference to the status label indicating source/tidy.
 */
@property (nonatomic, assign) IBOutlet NSTextField *statusLabel;


#pragma mark - Control Properties


/** Used to indicate whether the table is showing source or Tidy text results.
 */
@property (nonatomic, assign) BOOL modeIsTidyText;


/** Indicates/controls whether or not the filterView is hidden.
 */
@property (nonatomic, assign) BOOL filterViewIsHidden;


/** A bit mask indicating which combination of items is showing.
 */
@property (nonatomic, assign) JSDNuVMessageTypes showsMessages;


/** Indicates/controls whether or not messages of this type are displayed.
 */
@property (nonatomic, assign) BOOL showsFilterInfo;
@property (nonatomic, assign) BOOL showsFilterErrors;
@property (nonatomic, assign) BOOL showsFilterNonDocErrors;


#pragma mark - Content Display Properties


/** Return the correct labels for the filter buttons.
 */
@property (nonatomic, readonly, assign) NSString *labelForInfo;
@property (nonatomic, readonly, assign) NSString *labelForErrors;
@property (nonatomic, readonly, assign) NSString *labelForNonDocErrors;


/** Return the correct items for the network icon.
 */
@property (nonatomic, readonly, assign) NSString *tooltipForNetwork;
@property (nonatomic, readonly, assign) NSImage *imageForNetwork;


/** Returns the correct text for the source/tidy status label.
 */
@property (nonatomic, assign, readonly) NSString *statusLabelText;


/** Indicates that there messages for the document.
 */
@property (nonatomic, assign, readonly) BOOL hasMessageData;


#pragma mark - Status Properties


/** Indicates whether or not any of the validators are in progress.
 */
@property (nonatomic, readonly, assign) BOOL inProgress;


#pragma mark - Actions


/** Manually refresh the table data from the validators.
 */
- (IBAction)handleRefresh:(id)sender;


@end
