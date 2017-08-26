/**************************************************************************************************

	TDFPreviewController

	Copyright © 2003-2017 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TDFPreviewController.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"
#import "TidyDocument.h"

#import "TDFWebViewController.h"


/*
 * Preview Controller display modes.
 */
typedef NS_ENUM(NSUInteger, TDFPreviewOptions) {
    TDFShowsTidyText,
    TDFShowsSourceText,
    TDFShowsTidyAndSourceH, // views are horizontal (splitter is vertical)
    TDFShowsTidyAndSourceV  // views are vertical (splitter is horizontal)
};


@interface TDFPreviewController ()

/* 
 * UI references. 
 */
@property (nonatomic, assign) IBOutlet NSSplitView *splitView;
@property (nonatomic, assign) IBOutlet NSView *viewLeft;
@property (nonatomic, assign) IBOutlet NSView *viewRight;

/*
 * Indicates the base URL to be used by the webviews for loading content. 
 */
@property (nonatomic, strong) NSURL *baseURL;

/* 
 * The individual WebViewControllers. 
 */
@property (readwrite, strong) TDFWebViewController *webViewLeftController;
@property (readwrite, strong) TDFWebViewController *webViewRightController;

/*
 * Implement the view mode as a main property, but also expose four separate properties
 * to make it simple to use bindings for control.
 */
@property (nonatomic, assign) TDFPreviewOptions previewMode;
@property (nonatomic, assign) BOOL modeIsTidyText;
@property (nonatomic, assign) BOOL modeIsSourceText;
@property (nonatomic, assign) BOOL modeIsTidyAndSourceH;
@property (nonatomic, assign) BOOL modeIsTidyAndSourceV;

/*
 * Controls whether or not scroll synchronization is in effect in dual-display mode.
 */
@property (nonatomic, assign) BOOL scrollingIsLocked;
@property (nonatomic, assign, readonly) BOOL scrollingIsLockedEnabled;


@end


@implementation TDFPreviewController

@synthesize baseURL           = _baseURL;
@synthesize previewMode       = _previewMode;
@synthesize scrollingIsLocked = _scrollingIsLocked;


#pragma mark - Intialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
 * Create our ViewControllers first so that they exist when we set
 * some of their properties.
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ((self = [super init]))
    {
        self.webViewLeftController = [[TDFWebViewController alloc] init];
        self.webViewRightController = [[TDFWebViewController alloc] init];
    }

    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
    /******************************************************
     Setup the WebViewControllers and their view settings.
     ******************************************************/
    self.webViewLeftController.showsTidyText = NO;

    self.webViewLeftController.showsActionMenu = YES;
    
    self.webViewLeftController.actionMenuDelegate = self;
    
    self.webViewLeftController.representedObject = self.representedObject;
    
    [self.viewLeft addSubview:self.webViewLeftController.view];
    
    self.webViewLeftController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.webViewLeftController.view setFrame:self.viewLeft.bounds];

    
    self.webViewRightController.showsTidyText = YES;

    self.webViewRightController.showsActionMenu = NO;

    self.webViewRightController.actionMenuDelegate = self;

    self.webViewRightController.representedObject = self.representedObject;
    
    [self.viewRight addSubview:self.webViewRightController.view];
    
    self.webViewRightController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.webViewRightController.view setFrame:self.viewLeft.bounds];
    
    self.previewMode = TDFShowsTidyText;
}


#pragma mark - Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * Use our baseURL to trigger the owned views' baseURL.
 *———————————————————————————————————————————————————————————————————*/
- (NSURL *)baseURL
{
    return _baseURL;
}

- (void)setBaseURL:(NSURL *)baseURL
{
    _baseURL = baseURL;
    self.webViewLeftController.baseURL = baseURL;
    self.webViewRightController.baseURL = baseURL;
}


/*———————————————————————————————————————————————————————————————————*
 * Control our webviews' displays with the previewMode property.
 *———————————————————————————————————————————————————————————————————*/
- (TDFPreviewOptions)previewMode
{
    return _previewMode;
}

- (void)setPreviewMode:(TDFPreviewOptions)previewMode
{
    if (previewMode == TDFShowsTidyText || previewMode == TDFShowsSourceText)
    {
        [self.viewRight setHidden:YES];
        self.webViewLeftController.showsActionMenu = YES;
        self.webViewLeftController.showsTidyText = previewMode == TDFShowsTidyText;
    }
    else
    {
        [self.viewRight setHidden:NO];
        [self.splitView setVertical:(previewMode == TDFShowsTidyAndSourceH)];
        self.webViewLeftController.showsTidyText = NO;
        self.webViewLeftController.showsActionMenu = (previewMode == TDFShowsTidyAndSourceH);
        self.webViewRightController.showsTidyText = YES;
        self.webViewRightController.showsActionMenu = (previewMode == TDFShowsTidyAndSourceV);
    }
    
    [self.splitView adjustSubviews];
    [self.splitView setNeedsDisplay:YES];
    _previewMode = previewMode;
}


/*———————————————————————————————————————————————————————————————————*
 * Set and Report preview mode in tidy text mode.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingModeIsTidyText
{
    return [NSSet setWithArray:@[@"previewMode"]];
}

- (BOOL)modeIsTidyText
{
    return self.previewMode == TDFShowsTidyText;
}

- (void)setModeIsTidyText:(BOOL)modeIsTidyText
{
    if (modeIsTidyText)
        self.previewMode = TDFShowsTidyText;
    else
        self.previewMode = TDFShowsSourceText;
}


/*———————————————————————————————————————————————————————————————————*
 * Set and Report preview mode in source text mode.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingModeIsSourceText
{
    return [NSSet setWithArray:@[@"previewMode"]];
}

- (BOOL)modeIsSourceText
{
    return self.previewMode == TDFShowsSourceText;
}

- (void)setModeIsSourceText:(BOOL)modeIsSourceText
{
    if (modeIsSourceText)
        self.previewMode = TDFShowsSourceText;
    else
        self.previewMode = TDFShowsTidyText;
}


/*———————————————————————————————————————————————————————————————————*
 * Set and Report preview mode in horizontal (side by side)
 * orientation.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingModeIsTidyAndSourceH
{
    return [NSSet setWithArray:@[@"previewMode"]];
}

- (BOOL)modeIsTidyAndSourceH
{
    return self.previewMode == TDFShowsTidyAndSourceH;
}

- (void)setModeIsTidyAndSourceH:(BOOL)modeIsTidyAndSourceH
{
    if (modeIsTidyAndSourceH)
        self.previewMode = TDFShowsTidyAndSourceH;
    else
        self.previewMode = TDFShowsTidyAndSourceV;
}


/*———————————————————————————————————————————————————————————————————*
 * Set and Report preview mode in vertical (over under) orientation.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingModeIsTidyAndSourceV
{
    return [NSSet setWithArray:@[@"previewMode"]];
}

- (BOOL)modeIsTidyAndSourceV
{
    return self.previewMode == TDFShowsTidyAndSourceV;
}

- (void)setModeIsTidyAndSourceV:(BOOL)modeIsTidyAndSourceV
{
    if (modeIsTidyAndSourceV)
        self.previewMode = TDFShowsTidyAndSourceV;
    else
        self.previewMode = TDFShowsTidyAndSourceH;
}


/*———————————————————————————————————————————————————————————————————*
 * Control the scroll synchronization mode. The views will be scroll
 * locked if they receive NSViewBoundsDidChangeNotification, which
 * handles the synchronization, so simply toggling the notifications
 * enables and disables this feature.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)scrollingIsLocked
{
    return _scrollingIsLocked;
}

- (void)setScrollingIsLocked:(BOOL)scrollingIsLocked
{
    if (scrollingIsLocked)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronizedViewContentBoundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:self.webViewLeftController.scrollView.contentView];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronizedViewContentBoundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:self.webViewRightController.scrollView.contentView];

        [[NSNotificationCenter defaultCenter] postNotificationName:NSViewBoundsDidChangeNotification
                                                            object:self.webViewLeftController.scrollView.contentView];

    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:self.webViewLeftController.scrollView.contentView];

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:self.webViewRightController.scrollView.contentView];
    }
}


/*———————————————————————————————————————————————————————————————————*
 * Provide a bindable property to enable or disable the scroll lock
 * menu item.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingScrollingIsLockedEnabled
{
    return [NSSet setWithArray:@[@"previewMode"]];
}

- (BOOL)scrollingIsLockedEnabled
{
    return (self.previewMode == TDFShowsTidyAndSourceH) || (self.previewMode == TDFShowsTidyAndSourceV);
}



#pragma mark - NSSplitView Delegate Methods


/*———————————————————————————————————————————————————————————————————*
 * If we're in a single view, then the divider should be hidden.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    return (self.previewMode < TDFShowsTidyAndSourceH);
}


#pragma mark - NSNotificationCenter Notifications


/*———————————————————————————————————————————————————————————————————*
 * Listen for notifications from the webviews' scrollviews and keep
 * the scrollbars synchronized.
 *———————————————————————————————————————————————————————————————————*/
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
    NSClipView *thisView;
    NSClipView *thatView;
    NSScrollView *thatScroller;
    NSClipView *changedContentView = [notification object];

    if (changedContentView == self.webViewLeftController.scrollView.contentView)
    {
        thisView = self.webViewLeftController.scrollView.contentView;
        thatView = self.webViewRightController.scrollView.contentView;
        thatScroller = self.webViewRightController.scrollView;
    }
    else
    {
        thisView = self.webViewRightController.scrollView.contentView;
        thatView = self.webViewLeftController.scrollView.contentView;
        thatScroller = self.webViewLeftController.scrollView;
    }
    
    NSPoint changedBoundsOrigin = [thisView documentVisibleRect].origin;;
    NSPoint curOffset = [thatView bounds].origin;
    NSPoint newOffset = curOffset;
    
    newOffset.y = changedBoundsOrigin.y;
    
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
        [thatView scrollToPoint:newOffset];
        [thatScroller reflectScrolledClipView:thatView];
    }
}


#pragma mark - TDFWebViewController Informal Action Menu Protocol


/*———————————————————————————————————————————————————————————————————*
 * Allow the user to choose a new baseURL.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleSetBaseURL:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setPrompt:JSDLocalizedString(@"openPanelSelect", nil)];
    [openPanel setMessage:JSDLocalizedString(@"openPanelMessage", nil)];
    [openPanel setShowsHiddenFiles:YES];
    [openPanel setExtensionHidden:NO];
    [openPanel setCanSelectHiddenExtension: NO];
    [openPanel setCanChooseFiles: NO];
    [openPanel setCanChooseDirectories: YES];

    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            [openPanel orderOut:self];
            self.baseURL = openPanel.URLs[0];
        }
    }];
}


/*———————————————————————————————————————————————————————————————————*
 * Clears the current baseURL.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleClearBaseURL:(id)sender
{
    self.baseURL = nil;
}


#pragma mark - Instance Methods (Public)


/*———————————————————————————————————————————————————————————————————*
 * Update the webviews.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateWebViews
{
    [self.webViewLeftController updateWebView];
    [self.webViewRightController updateWebView];
}


@end
