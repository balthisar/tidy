//
//  TDFWebViewController.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "TDFWebViewController.h"
#import "CommonHeaders.h"

#import "TidyDocument.h"

@import JSDTidyFramework;


@interface TDFWebViewController ()

/* 
 * UI references. 
 */
@property (nonatomic, assign) IBOutlet NSLayoutConstraint *actionMenuWidthConstraint;
@property (nonatomic, assign) IBOutlet NSMenuItem *menuSetBaseURL;
@property (nonatomic, assign) IBOutlet NSMenuItem *menuClearBaseURL;
@property (nonatomic, assign) IBOutlet WebView *webView;
@property (nonatomic, assign) IBOutlet NSTextField *statusLabel;

/* 
 * These properties are used to perform web preview update throttling, as well as provide
 * bindable properties for displaying load status. 
 */
@property (nonatomic, strong) NSTimer *throttleTimer;
@property (nonatomic, assign) BOOL throttleTimerPassed;
@property (nonatomic, assign) BOOL didRequestLoad;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) double loadingProgress;

/*
 * Used for IB binding to indicate what text should appear in the status areas. 
 */
@property (nonatomic, assign, readonly) NSString *statusLabelText;

/* 
 * A convenience for accessing our represented object's tidyProcess. 
 */
@property (nonatomic, assign, readonly) JSDTidyModel *tidyProcess;

/* 
 * A convenience for knowing the correct keyPath, depending on the value of `showsTidyText`. 
 */
@property (nonatomic, assign, readonly) NSString *keyPath;

/* 
 * Saved scroll position for reload. 
 */
@property (nonatomic, assign) CGPoint savedScrollPosition;

/* 
 * Buffer string to prevent unnecessary reloading. 
 */
@property (nonatomic, strong) NSString *currentStringContents;


@end


@implementation TDFWebViewController

@synthesize showsTidyText   = _showsTidyText;
@synthesize showsActionMenu = _showsActionMenu;

@synthesize baseURL         = _baseURL;


#pragma mark - Intialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
 * Pre-setup.
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ((self = [super init]))
    {
        _showsTidyText = YES;
        _showsActionMenu = YES;
    }
    
    return self;
}

/*———————————————————————————————————————————————————————————————————*
 * Remove all observers.
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    [self.tidyProcess removeObserver:self forKeyPath:self.keyPath];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:JSDKeyWebPreviewThrottleTime];
}



/*———————————————————————————————————————————————————————————————————*
 * Setup all of our required components and register for applicable
 * KVO and notifications.
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
    /*-------------------------------------*
     * Register for KVO and notifications
     * so that we can determine when to
     * update the webview.
     *-------------------------------------*/
    
    /* KVO on the correct property of our tidyProcess. */
    [self.tidyProcess addObserver:self
                       forKeyPath:self.keyPath
                          options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                          context:NULL];
    
    /* KVO on user prefs to look for update frequency changes. */
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:JSDKeyWebPreviewThrottleTime
                                               options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                                               context:NULL];
    
    /* Observe the webviews for start and stop conditions. */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewProgressStarted:)
                                                 name:WebViewProgressStartedNotification
                                               object:self.webView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewProgressFinished:)
                                                 name:WebViewProgressFinishedNotification
                                               object:self.webView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewProgressProgress:)
                                                 name:WebViewProgressEstimateChangedNotification
                                               object:self.webView];
    
    
    /*-------------------------------------*
     * Setup a timer so that we don't spam
     * the webview.
     *-------------------------------------*/
    self.throttleTimerPassed = YES;
    self.didRequestLoad = NO;
    [self activateThrottleTimer];
    
    /*-------------------------------------*
     * Force initial application of our
     * key properties.
     *-------------------------------------*/
    self.showsTidyText = _showsTidyText;
    self.showsActionMenu = _showsActionMenu;
    
    /*-------------------------------------*
     * Link our two menu items to our
     * delegate (our owning controller)
     * instead of to us. The action is
     * already set in Interface Builder.
     *-------------------------------------*/
    self.menuSetBaseURL.target = self.actionMenuDelegate;
    self.menuClearBaseURL.target = self.actionMenuDelegate;
}


#pragma mark - Property Accessors (Public)


/*———————————————————————————————————————————————————————————————————*
 * Setting the baseURL requires resetting the WebView due to a
 * caching bug wherein assets are cached when a previously-used
 * directory is set as base. This means, e.g., that CSS file changes
 * won't be reloaded. To force this to work we will temporarily
 * clear the document entirely before reloading it with the correct
 * base URL.
 *———————————————————————————————————————————————————————————————————*/
- (NSURL *)baseURL
{
    return _baseURL;
}

- (void)setBaseURL:(NSURL *)baseURL
{
    _baseURL = baseURL;
    
    self.throttleTimerPassed = YES;
    self.currentStringContents = nil;
    self.isLoading = NO;
    
    if (baseURL)
    {
        [[self.webView mainFrame] loadHTMLString:@"" baseURL:nil];
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateWebView) userInfo:nil repeats:NO];
    }
    else
    {
        /* If it's nil, it's safe to set without timer games. */
        [self updateWebView];
    }
}


/*———————————————————————————————————————————————————————————————————*
 * When showsTidyText changes, we have to update our bindings.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsTidyText
{
    return _showsTidyText;
}

- (void)setShowsTidyText:(BOOL)showsTidyText
{
    NSString *keyPathOld = self.keyPath;
    NSString *keyPathNew = showsTidyText ? @"tidyText" : @"sourceText";
    
    [self.tidyProcess removeObserver:self forKeyPath:keyPathOld];
    [self.tidyProcess addObserver:self
                       forKeyPath:keyPathNew
                          options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                          context:NULL];
    
    _showsTidyText = showsTidyText;
}


/*———————————————————————————————————————————————————————————————————*
 * Expose the webview's scrollview so that the owning controller can
 * access it.
 *———————————————————————————————————————————————————————————————————*/
- (NSScrollView *)scrollView
{
    return [[[[self.webView mainFrame] frameView] documentView] enclosingScrollView];
}

/*———————————————————————————————————————————————————————————————————*
 * Toggling showsActionMenu shows or hides the action menu.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsActionMenu
{
    return _showsActionMenu;
}

- (void)setShowsActionMenu:(BOOL)showsActionMenu
{
    if (showsActionMenu)
    {
        [self.actionMenuWidthConstraint setConstant:38.0f];
    }
    else
    {
        [self.actionMenuWidthConstraint setConstant:0.0f];
    }
    
    _showsActionMenu = showsActionMenu;
}


#pragma mark - Property Accessors (Category)


/*———————————————————————————————————————————————————————————————————*
 * A convenience for knowing the correct keyPath, depending on the
 * value of `showsTidyText`.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingKeyPath
{
    return [NSSet setWithArray:@[@"showsTidyText"]];
}

- (NSString *)keyPath
{
    return self.showsTidyText ? @"tidyText" : @"sourceText";
}


/*———————————————————————————————————————————————————————————————————*
 * Provides a bindable source for status label text.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingStatusLabelText
{
    return [NSSet setWithArray:@[@"showsTidyText"]];
}

- (NSString *)statusLabelText
{
    return self.showsTidyText ? JSDLocalizedString(@"tidyTextLabel", nil) : JSDLocalizedString(@"sourceTextLabel", nil);
}


/*———————————————————————————————————————————————————————————————————*
 * A convenience accessor for the represented object's tidyProcess.
 *———————————————————————————————————————————————————————————————————*/
- (JSDTidyModel *)tidyProcess
{
    return ((TidyDocument*)self.representedObject).tidyProcess;
}


#pragma mark - Instance Methods (Public)


/*———————————————————————————————————————————————————————————————————*
 * Update the webview. This will only be done if:
 *  - the throttle timer allows us;
 *  - we're not still loading something else; and
 *  - the actual string contents have changed.
 * Otherwise will will flag a reload ASAP via didRequestLoad, which
 * will perform the reload next time the throttleTimer finishes.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateWebView
{
    if (self.throttleTimerPassed && !self.isLoading && ![[self.tidyProcess valueForKey:self.keyPath] isEqualToString:self.currentStringContents] )
    {
        NSScrollView *scrollView = [[[[self.webView mainFrame] frameView] documentView] enclosingScrollView];
        NSRect scrollViewBounds = [[scrollView contentView] bounds];
        self.savedScrollPosition = scrollViewBounds.origin;
        
        self.didRequestLoad = NO;
        self.throttleTimerPassed = NO;
        self.currentStringContents = [[self.tidyProcess valueForKey:self.keyPath] copy];
        [[self.webView mainFrame] loadHTMLString:[self.tidyProcess valueForKey:self.keyPath] baseURL:self.baseURL];
    }
    else
    {
        self.didRequestLoad = YES;
    }
}


#pragma mark - Instance Methods (Private)


/*———————————————————————————————————————————————————————————————————*
 * Setup a reload throttle timer. Although the webview is very fast,
 * large or complex documents (especially with external resources)
 * will take time to load and render. Requests to load the webview
 * will not be honored until this timer is finished.
 *———————————————————————————————————————————————————————————————————*/
- (void)activateThrottleTimer
{
    float throttleTime = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyWebPreviewThrottleTime];
    self.throttleTimer = [NSTimer scheduledTimerWithTimeInterval:throttleTime
                                                          target:self
                                                        selector:@selector(finishThrottleTimer)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)finishThrottleTimer
{
    self.throttleTimerPassed = YES;
    if (self.didRequestLoad)
    {
        [self updateWebView];
    }
}


#pragma mark - KVO and NotificationCenter Handlers


/*———————————————————————————————————————————————————————————————————*
 * Handle KVO for the following:
 *  - Handle changes due to tidyText/sourceText changing. This
 *    generally means updating the webview. However because updating
 *    the webview is a potentially expensive operation, we will only
 *    do so when the view is actually visible.
 *  - Handle updates to the JSDKeyWebPreviewThrottleTime default
 *    setting. This will invalidate current throttle timer and
 *    reactivate it using the current preferences value.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    /* Update the webview with a new string. */
    if ((object == self.tidyProcess) && ([keyPath isEqualToString:self.keyPath]))
    {
        /* Performing this check here instead of in updateWebView allows us to
         * use updateWebView in a forced manner elsewhere, should we want to.
         */
        if (self.view.window && !self.view.hiddenOrHasHiddenAncestor)
        {
            [self updateWebView];
        }
    }
    
    /* Update the throttling timer. */
    if (object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:JSDKeyWebPreviewThrottleTime])
    {
        [self.throttleTimer invalidate];
        [self activateThrottleTimer];
    }
}


/*———————————————————————————————————————————————————————————————————*
 *  The webview has started loading. This value is used to show the
 *  progress indicator via bindings, but also to ensure that we
 *  don't try to reload the view while a current load is in process.
 *———————————————————————————————————————————————————————————————————*/
- (void)webViewProgressStarted:(NSNotification *)notification
{
    self.isLoading = YES;
}


/*———————————————————————————————————————————————————————————————————*
 * The webview has finished loading.
 *  - Set the isLoading property so that progress meter bindings can
 *    get the correct state.
 *  - isLoading will also unlock the ability to updateWebView.
 *  - Update the scroll position to where it was previously. This
 *    is added to the end of current run loop which hopefully ensures
 *    the the webview is done rendering.
 *———————————————————————————————————————————————————————————————————*/
- (void)webViewProgressFinished:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSScrollView *scrollView = [[[[self.webView mainFrame] frameView] documentView] enclosingScrollView];
        [[scrollView documentView] scrollPoint:self.savedScrollPosition];
        self.isLoading = NO;
    });
}


/*———————————————————————————————————————————————————————————————————*
 * The webview reports a progress update. Update the loadingProgress
 * property so that progress meter bindings can get the correct stte.
 *———————————————————————————————————————————————————————————————————*/
- (void)webViewProgressProgress:(NSNotification *)notification
{
    self.loadingProgress = [(WebView*)[notification object] estimatedProgress];
}


#pragma mark - WebView UIDelegate Methods


/*———————————————————————————————————————————————————————————————————*
 * Disable the contextual menu on the WebView.
 *———————————————————————————————————————————————————————————————————*/
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    return nil;
}


@end
