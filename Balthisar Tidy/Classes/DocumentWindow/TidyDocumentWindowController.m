//
//  TidyDocumentWindowController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#pragma mark - Notes

/*
 * Event Handling and Interacting with the Tidy Processor
 *
 * The Tidy processor is loosely coupled with the document controller. Most
 * interaction with it is handled via NSNotifications and/or bindings.
 *
 * If user types text, then the `sourceViewController` receives the delegate
 * `textDidChange` notification, and will set new text in
 * `tidyProcess.sourceText`. The event chain will eventually handle everything
 * else. Notably setting this text directly does not invoke this notification.
 *
 * The Tidy process' `tidyText` is bound directly to the text of the `tidyView`
 * in the `sourceViewController`. If Tidy's error text changes, the Tidy
 * process sends a `tidyNotifyTidyErrorsChanged` which is sent to the views
 * depending on which feedback pane is showing, and whether or not the feedback
 * pane is showing source or Tidy'd information.
 *
 * If `optionController` sends an NSNotification, then we will copy the new
 * options to `tidyProcess`. The event chain will eventually handle everything
 * else.
 *
 * If we set `sourceText` via file or data (only happens when opening or
 * reverting) we will NOT update `sourceView`. We will wait for `tidyProcess`
 * NSNotification that the `sourceText` changed, then set the `sourceView`.
 * HOWEVER this presents a small issue to overcome:
 *
 *   - If we set `sourceView` we will get `textDidChange` notification, causing
 *     us to update [tidyProcess sourceText] again, resulting in processing the
 *     document twice, which we don't want to do.
 *
 *   - To prevent this we will set `documentIsLoading` to YES any time we we set
 *     `sourceText` from file or data. In the `textDidChange` handler we will
 *     NOT set [tidyProcess sourceText], and we will flip `documentIsLoading`
 *     back to NO.
 */

#import "TidyDocumentWindowController.h"
#import "CommonHeaders.h"

#import "AppController.h"
#import "PreferenceController.h"

#import "OptionPaneController.h"
#import "TidyDocumentSourceViewController.h"
#import "TidyDocumentFeedbackViewController.h"

#import "TDFTableViewController.h"
#import "TDFValidatorViewController.h"

#import "EncodingHelperController.h"
#import "FirstRunController.h"

#import "JSDTidyModel+MGSSyntaxError.h"
#import "JSDNuValidator+MGSSyntaxError.h"

#import <Fragaria/Fragaria.h>
#import <FragariaDefaultsCoordinator/FragariaDefaultsCoordinator.h>

#import "SWFSemanticVersion.h"

@import MMTabBarView;


@import JSDTidyFramework;

@interface TidyDocumentWindowController ()

/* A managed version of NSUserDefaultsController. */
@property (nonatomic, assign, readonly) MGSUserDefaultsController *userDefaultsController;

/* Convenience properties. */
@property (nonatomic, assign, readonly) JSDTidyModel *tidyProcess;
@property (nonatomic, assign, readonly) NSArray <MGSSyntaxError *> *sourceValidatorErrors;
@property (nonatomic, assign, readonly) NSArray <MGSSyntaxError *> *tidyValidatorErrors;

@end


@implementation TidyDocumentWindowController
{
    CGFloat _savedPositionWidth;   // For saving options width.
    CGFloat _savedPositionHeight;  // For saving messages height,
}


#pragma mark - Initialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
 * - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ( ( self = [super initWithWindowNibName:@"TidyDocumentWindow"] ) )
    {
        _userDefaultsController = [MGSUserDefaultsController sharedController];
    }
    
    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * - dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:tidyNotifyOptionChanged
                                                  object:self.optionController.tidyDocument];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:tidyNotifyPossibleInputEncodingProblem
                                                  object:self.tidyProcess];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:tidyNotifyTidyErrorsChanged
                                                  object:nil];
}


#pragma mark - Setup


/*———————————————————————————————————————————————————————————————————*
 * - awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
    /* Setup the optionController and its view settings.
     */
    self.optionController = [[OptionPaneController alloc] init];
    
    [self.optionPane addSubview:self.optionController.view];
    
    [self.optionController.view setFrame:self.optionPane.bounds];
    
    self.optionController.optionsInEffect = [PreferenceController optionsInEffect];
    
    /* Make the optionController take the default values. This actually
     * causes the empty document to go through processTidy one time.
     */
    [self.optionController.tidyDocument takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];
    
    
    /* Setup the feedbackController and its view settings.
     */
    self.feedbackController = [[TidyDocumentFeedbackViewController alloc] init];
    
    self.feedbackController.representedObject = self.document;
    
    [self.feedbackPane addSubview:self.feedbackController.view];
    
    self.feedbackController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.feedbackController.view setFrame:self.feedbackPane.bounds];
    
    
    /* Setup the sourceViewController and its view settings.
     */
    self.sourceViewController = [[TidyDocumentSourceViewController alloc] init];
    
    self.sourceViewController.representedObject = self.document;
    
    [self.sourcePane addSubview:self.sourceViewController.view];
    
    self.sourceViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.sourceViewController.view setFrame:self.sourcePane.bounds];
    
    self.sourceViewController.sourceTextView.string = self.tidyProcess.sourceText;
    
    self.sourceViewController.messagesArrayController = self.feedbackController.messagesController.arrayController;
    
    
    /*-------------------------------------*
     * Get the correct tidy options.
     *-------------------------------------*/

    /* Make the local processor take the default values. This causes
     * the empty document to go through processTidy a second time.
     */
    [self.tidyProcess takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];
    
    
    /*-------------------------------------*
     * Notifications, etc.
     *-------------------------------------*/

    /* Delay setting up notifications until now, because otherwise
     * all of the earlier options setup is simply going to result
     * in a huge cascade of notifications and updates.
     */
    
    /* NSNotifications from the `optionController` indicate that one or more options changed. */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTidyOptionChange:)
                                                 name:tidyNotifyOptionChanged
                                               object:[[self optionController] tidyDocument]];
    
    /* NSNotifications from the `tidyProcess` indicate that the input-encoding might be wrong. */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTidyInputEncodingProblem:)
                                                 name:tidyNotifyPossibleInputEncodingProblem
                                               object:self.tidyProcess];
    
    /* NSNotifications from the `tidyProcess` indicate that one or more errors changed. */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTidyErrorsChange:)
                                                 name:tidyNotifyTidyErrorsChanged
                                               object:nil];
    
    
    /*-------------------------------------*
     * Remaining manual view adjustments.
     *-------------------------------------*/
    
    NSRect localRect = NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:@"NSSplitView Subview Frames UIPositionsSplitter01"][0]);
    [self.splitterOptions setPosition:localRect.size.width ofDividerAtIndex:0];
    
    localRect = NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:@"NSSplitView Subview Frames UIPositionsSplitter02"][0]);
    if (localRect.size.height > 0.0f)
    {
        [self.splitterMessages setPosition:localRect.size.height ofDividerAtIndex:0];
    }
    
    self.splitterMessages.superview.wantsLayer = YES;
    self.splitterOptions.superview.wantsLayer = YES;
    self.sourceViewController.view.wantsLayer = YES;
    
    [self handleTidyErrorsChange:nil];
}


/*———————————————————————————————————————————————————————————————————*
 * - windowDidLoad
 *  This method handles initialization after the window
 *  controller's window has been loaded from its nib file.
 *———————————————————————————————————————————————————————————————————*/
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.optionsPanelIsVisible = [[defaults objectForKey:JSDKeyShowNewDocumentTidyOptions] boolValue];
    self.feedbackPanelIsVisible = [[defaults objectForKey:JSDKeyShowNewDocumentMessages] boolValue];
    
    
    [self.window setInitialFirstResponder:self.optionController.view];
    
    /* We will set the tidyProcess' source text (nil assigment is
     * okay). If we try this in awakeFromNib, we might receive a
     * notification before the nibs are all done loading, so we
     * will do this here.
     */
    TidyDocument *tidyDoc = self.document;
    NSData *docOpenedData = tidyDoc.documentOpenedData;
    [self.tidyProcess setSourceTextWithData:docOpenedData];
    
    
    /* If we have docOpenedData but no output, then suggest that the user
     * try `force-output`.
     */
    JSDTidyOption *opt = self.tidyProcess.tidyOptions[@"force-output"];
    BOOL force = [opt.optionValue isEqualToString:@"yes"];
    if ( docOpenedData && [tidyDoc.tidyText isEqualToString:@""] && !force )
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:JSDLocalizedString(@"WarnTryForceOutput", nil)];
        [alert setInformativeText:JSDLocalizedString(@"WarnTryForceOutputExplain", nil)];
        [alert addButtonWithTitle:JSDLocalizedString(@"WarnTryForceOutputButton", nil)];
        [alert runModal];
    }
    
    
    /* Force the validator to refresh, now that we have a document.
     */
    [self.feedbackController.validatorController handleRefresh:nil];
    
    
    /* Run through the new user helper if appropriate.
     */

    SWFSemanticVersion *current = [SWFSemanticVersion semanticVersionWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"]];
    SWFSemanticVersion *previous = [SWFSemanticVersion semanticVersionWithString:[defaults stringForKey:JSDKeyFirstRunCompleteVersion]];
    
    BOOL upgraded = ([previous compare:current] == NSOrderedAscending);
    BOOL incomplete = ![defaults boolForKey:JSDKeyFirstRunComplete];
    
    if ( incomplete || upgraded )
    {
        [self kickOffFirstRunSequence:nil];
    }
}


#pragma mark - Event and KVO Notification Handling


/*———————————————————————————————————————————————————————————————————*
 * - handleTidyOptionChange:
 *  One or more options changed in `optionController`. Copy
 *  those options to our `tidyProcess`. The event chain will
 *  eventually update everything else because this will cause
 *  the tidyText to change.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
    [self.tidyProcess optionsCopyValuesFromModel:self.optionController.tidyDocument];
}


/*———————————————————————————————————————————————————————————————————*
 * - handleTidyInputEncodingProblem:
 *  We're here as the result of a notification. The value for
 *  input-encoding might have been wrong for the file
 *  that tidy is trying to process. We only want to peform this
 *  if documentIsLoading.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyInputEncodingProblem:(NSNotification*)note
{
    if (((TidyDocument*)self.document).documentIsLoading && ![[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyIgnoreInputEncodingWhenOpening] boolValue])
    {
        self.encodingHelper = [[EncodingHelperController alloc] initWithNote:note fromDocument:self.document forView:self.sourceViewController.sourceTextView];
        self.encodingHelper.delegate = self;
        
        if ([[PreferenceController sharedPreferences] documentWindowIsInScreenshotMode])
        {
            [self.window setAlphaValue:0.0f];
        }
        [self.encodingHelper startHelper];
    }
}


/*———————————————————————————————————————————————————————————————————*
 * - handleTidyErrorsChange:
 *  We received tidyNotifyTidyErrorsChanged, which can be sent by
 *  a tidyProcess, or by the TidyDocumentFeedbackViewController when
 *  a tab switches. We will update which errors are shown in the
 *  source views.
 *———————————————————————————————————————————————————————————————————*/
- (void)handleTidyErrorsChange:(NSNotification *)note
{
    if ( self.feedbackPanelIsVisible
        && self.feedbackController.selectedTabViewItem == self.feedbackController.messagesTabViewItem )
    {
        self.sourceViewController.sourceTextView.syntaxErrors = self.tidyErrors;
        self.sourceViewController.tidyTextView.syntaxErrors = nil;
        self.sourceViewController.messagesArrayController = self.feedbackController.messagesController.arrayController;
        self.sourceViewController.jumpTarget = self.sourceViewController.sourceTextView;
    }
    else if (self.feedbackPanelIsVisible
             && self.feedbackController.selectedTabViewItem == self.feedbackController.validatorTabViewItem )
    {
        self.sourceViewController.sourceTextView.syntaxErrors = self.sourceValidatorErrors;
        self.sourceViewController.tidyTextView.syntaxErrors = self.tidyValidatorErrors;
        self.sourceViewController.messagesArrayController = self.feedbackController.validatorController.arrayController;
        if (self.feedbackController.validatorController.modeIsTidyText)
        {
            self.sourceViewController.jumpTarget = self.sourceViewController.tidyTextView;
        }
        else
        {
            self.sourceViewController.jumpTarget = self.sourceViewController.sourceTextView;
        }
    }
    else
    {
        self.sourceViewController.sourceTextView.syntaxErrors = nil;
        self.sourceViewController.tidyTextView.syntaxErrors = nil;
        self.sourceViewController.messagesArrayController = nil;
        self.sourceViewController.jumpTarget = nil;
    }
}


/*———————————————————————————————————————————————————————————————————*
 * - documentDidWriteFile
 *  We're here either because:
 *    - TidyDocument indicated that it wrote a file, or
 *    - The user wants to transpose the Tidy HTML to the Source HTML.
 *  We have to update the view to reflect either condition.
 *———————————————————————————————————————————————————————————————————*/
- (void)documentDidWriteFile
{
    self.sourceViewController.sourceTextView.string = self.tidyProcess.tidyText;
    
    /* Force the event cycle so errors can be updated. */
    self.tidyProcess.sourceText = self.sourceViewController.sourceTextView.string;
}


/*———————————————————————————————————————————————————————————————————*
 * - auxilliaryViewWillClose:
 *  We're here because we're the delegate of the encoding helper
 *  and the first run controller, and they are about to close.
 *———————————————————————————————————————————————————————————————————*/
- (void)auxilliaryViewWillClose:(id)sender
{
    if (sender == self.firstRunHelper)
    {
        if (![[PreferenceController sharedPreferences] documentWindowIsInScreenshotMode])
        {
            [self.window setAlphaValue:1.0f];
        }
    }
    
    if (sender == self.encodingHelper)
    {
        if (![[PreferenceController sharedPreferences] documentWindowIsInScreenshotMode])
        {
            [self.window setAlphaValue:1.0f];
        }
    }
}


#pragma mark - Split View Handling


/*———————————————————————————————————————————————————————————————————*
 * - splitView:canCollapseSubview
 *  Supports hiding the tidy options and/or messsages panels.
 *  Although we're handing this programmatically, this delegate
 *  method is still required if we want it to work.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    NSView *viewOfInterest;
    
    if ([splitView isEqual:self.splitterOptions])
    {
        viewOfInterest = [[splitView subviews] objectAtIndex:0];
    }
    
    if ([splitView isEqual:self.splitterMessages])
    {
        viewOfInterest = [[splitView subviews] objectAtIndex:1];
    }
    
    return ([subview isEqual:viewOfInterest]);
}


#pragma mark - Menu and State Validation


/*———————————————————————————————————————————————————————————————————*
 * - validateMenuItem:
 *  Validates and sets main menu items. We could use instead
 *  validateUserInterfaceItem:, but we're only worried about
 *  menus and this ensures everything is a menu item. All of
 *  the toolbars are validated via bindings.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(kickOffFirstRunSequence:))
    {
        [menuItem setState:self.firstRunHelper.visible];
        return !self.firstRunHelper.visible; // don't allow when helper open.
    }
    
    if (menuItem.action == @selector(toggleFeedbackPanelIsVisible:))
    {
        [menuItem setState:self.feedbackPanelIsVisible];
        return !self.firstRunHelper.visible; // don't allow when helper open.
    }
    
    if (menuItem.action == @selector(toggleOptionsPanelIsVisible:))
    {
        [menuItem setState:self.optionsPanelIsVisible];
        return !self.firstRunHelper.visible; // don't allow when helper open.
    }
    
    if (menuItem.action == @selector(toggleSourcePanelIsVertical:))
    {
        [menuItem setState:self.sourceViewController.splitterViews.vertical];
        return !self.firstRunHelper.visible; // don't allow when helper open.
    }
    
    if (menuItem.action == @selector(handleTransposeTidyText:))
    {
        // don't allow when there's no Tidy HTML.
        return ![self.sourceViewController.tidyTextView.string isEqualToString:@""];
    }
    
    return NO;
}


#pragma mark - Properties


/*———————————————————————————————————————————————————————————————————*
 * @property optionsPaneIsVisible
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet*)keyPathsForValuesAffectingOptionsPanelIsVisible
{
    return [NSSet setWithArray:@[@"self.optionPaneContainer.hidden"]];
}

- (BOOL)optionsPanelIsVisible
{
    NSView *viewOfInterest = [[self.splitterOptions subviews] objectAtIndex:0];
    
    BOOL isCollapsed = [self.splitterOptions isSubviewCollapsed:viewOfInterest];
    
    return !isCollapsed;
}

- (void)setOptionsPanelIsVisible:(BOOL)optionsPanelIsVisible
{
    /* If the savedPosition is zero, this is the first time we've been here. In that
     * case let's get the value from the actual pane, which should be either the
     * IB default or whatever came in from user defaults.
     */
    
    if (_savedPositionWidth == 0.0f)
    {
        _savedPositionWidth = ((NSView*)[[self.splitterOptions subviews] objectAtIndex:0]).frame.size.width;
    }
    
    
    [self.splitterOptions.superview layoutSubtreeIfNeeded];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
        context.allowsImplicitAnimation = YES;
        
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAnimationReduce] )
        {
            context.duration = 0.0f;
        }
        else
        {
            context.duration = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyAnimationStandardTime];
        }
        
        if (optionsPanelIsVisible)
        {
            [self.splitterOptions setPosition:self->_savedPositionWidth ofDividerAtIndex:0];
        }
        else
        {
            self->_savedPositionWidth = ((NSView*)[[self.splitterOptions subviews] objectAtIndex:0]).frame.size.width;
            [self.splitterOptions setPosition:0.0f ofDividerAtIndex:0];
        }
        
        [self.splitterOptions.superview layoutSubtreeIfNeeded];
    }
                        completionHandler:nil];
}


/*———————————————————————————————————————————————————————————————————*
 * @property feedbackPanelIsVisible
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet*)keyPathsForValuesAffectingFeedbackPanelIsVisible
{
    return [NSSet setWithObject:@"self.feedbackPane.hidden"];
}

- (BOOL)feedbackPanelIsVisible
{
    NSView *viewOfInterest = [[self.splitterMessages subviews] objectAtIndex:1];
    
    BOOL isCollapsed = [self.splitterMessages isSubviewCollapsed:viewOfInterest];
    
    return !isCollapsed;
}

- (void)setFeedbackPanelIsVisible:(BOOL)feedbackPanelIsVisible
{
    /* If the savedPosition is zero, this is the first time we've been here. In that
     * case let's get the value from the actual pane, which should be either the
     * IB default or whatever came in from user defaults.
     */
    
    if (_savedPositionHeight == 0.0f)
    {
        _savedPositionHeight = ((NSView*)[[self.splitterMessages subviews] objectAtIndex:1]).frame.size.height;
    }
    
    [self.splitterMessages.superview layoutSubtreeIfNeeded];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
        context.allowsImplicitAnimation = YES;
        
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAnimationReduce] )
        {
            context.duration = 0.0f;
        }
        else
        {
            context.duration = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyAnimationStandardTime];
        }
        
        if (feedbackPanelIsVisible)
        {
            CGFloat splitterHeight = self.splitterMessages.frame.size.height;
            [self.splitterMessages setPosition:(splitterHeight - self->_savedPositionHeight) ofDividerAtIndex:0];
        }
        else
        {
            self->_savedPositionHeight = ((NSView*)[[self.splitterMessages subviews] objectAtIndex:1]).frame.size.height;
            [self.splitterMessages setPosition:self.splitterMessages.frame.size.height ofDividerAtIndex:0];
        }
        
        [self.splitterMessages.superview layoutSubtreeIfNeeded];
    }
                        completionHandler:nil];
    
    [self handleTidyErrorsChange:nil];
}


/*———————————————————————————————————————————————————————————————————*
 * @property sourceViewIsVertical
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingSourceViewIsVertical
{
    return [NSSet setWithArray:@[ @"self.sourceViewController.splitterViews.vertical" ]];
}

- (BOOL)sourceViewIsVertical
{
    return self.sourceViewController.splitterViews.vertical;
}

- (void)setSourceViewIsVertical:(BOOL)sourceViewIsVertical
{
    static float _savedPosition = 0.0f;
    static float _newPosition = 0.0f;
    
    NSSplitView *splitter = self.sourceViewController.splitterViews;
    
    _newPosition = _savedPosition;
    
    if ( splitter.vertical )
    {
        _savedPosition = [splitter.subviews objectAtIndex:0].frame.size.width;
    }
    else
    {
        _savedPosition = [splitter.subviews objectAtIndex:0].frame.size.height;
    }
    
    [self.sourceViewController.view layoutSubtreeIfNeeded];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
        context.allowsImplicitAnimation = YES;
        
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAnimationReduce] )
        {
            context.duration = 0.0f;
        }
        else
        {
            context.duration = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyAnimationStandardTime];
        }
        
        self.sourceViewController.splitterViews.vertical = !self.sourceViewController.splitterViews.vertical;
        
        if ( _newPosition != 0.0f )
        {
            [splitter setPosition:_newPosition ofDividerAtIndex:0];
        }
        
        [self.sourceViewController.view layoutSubtreeIfNeeded];
    } completionHandler:nil];
    
}


#pragma mark - Menu Actions


/*———————————————————————————————————————————————————————————————————*
 * - toggleFeedbackPanelIsVisible:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleFeedbackPanelIsVisible:(id)sender
{
    self.feedbackPanelIsVisible = !self.feedbackPanelIsVisible;
}


/*———————————————————————————————————————————————————————————————————*
 * - toggleOptionsPanelIsVisible:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleOptionsPanelIsVisible:(id)sender
{
    self.optionsPanelIsVisible = !self.optionsPanelIsVisible;
}


/*———————————————————————————————————————————————————————————————————*
 * - toggleSourcePanelIsVertical:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleSourcePanelIsVertical:(id)sender
{
    self.sourceViewIsVertical = ! self.sourceViewIsVertical;
}


/*———————————————————————————————————————————————————————————————————*
 * - handleTransposeTidyText:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleTransposeTidyText:(id)sender
{
    NSTextView *textView = self.sourceViewController.sourceTextView.textView;
    NSInteger ip = [[[textView selectedRanges] objectAtIndex:0] rangeValue].location;
    
    [self documentDidWriteFile];
    
    [textView setSelectedRange: NSMakeRange(ip, 0)];
}


#pragma mark - Toolbar Actions


/*———————————————————————————————————————————————————————————————————*
 * - handleShowDiffView:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleShowDiffView:(id)sender
{
    NSLog(@"%@", @"Here is where we will show the traditional diff panel.");
}


/*———————————————————————————————————————————————————————————————————*
 * - toggleSyncronizedDiffs:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleSyncronizedDiffs:(id)sender
{
    NSLog(@"%@", @"Here we will toggle sync'd diffs.");
}


/*———————————————————————————————————————————————————————————————————*
 * - toggleSynchronizedScrolling:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)toggleSynchronizedScrolling:(id)sender
{
    NSLog(@"%@", @"Here is where we toggle sync'd scrolling.");
}

#pragma mark - Quick Tutorial Support


/*———————————————————————————————————————————————————————————————————*
 * - kickOffFirstRunSequence:
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)kickOffFirstRunSequence:(id)sender;
{
    AppController *appController = [[NSApplication sharedApplication] delegate];
    
    NSArray *firstRunSteps = @[
        @{ @"message": @"tidyFirstRun00a",
           @"showRelativeToRect": NSStringFromRect(self.sourceViewController.sourceTextView.bounds),
           @"ofView": self.sourceViewController.sourceTextView,
           @"preferredEdge": @(NSMinXEdge),
        },
        
        @{ @"message": @"tidyFirstRun00b",
           @"showRelativeToRect": NSStringFromRect(self.sourceViewController.sourceTextView.bounds),
           @"ofView": self.sourceViewController.sourceTextView,
           @"preferredEdge": @(NSMinXEdge),
        },
        
        @{ @"message": @"tidyFirstRun10",
           @"showRelativeToRect": NSStringFromRect(self.optionPane.bounds),
           @"ofView": self.optionPane,
           @"preferredEdge": @(NSMinXEdge),
        },
        
        @{ @"message": @"tidyFirstRun20",
           @"showRelativeToRect": NSStringFromRect(self.sourceViewController.sourceTextView.bounds),
           @"ofView": self.sourceViewController.sourceTextView,
           @"preferredEdge": @(NSMinXEdge),
        },
        
        @{ @"message": @"tidyFirstRun30",
           @"showRelativeToRect": NSStringFromRect(self.sourceViewController.tidyTextView.bounds),
           @"ofView": self.sourceViewController.tidyTextView,
           @"preferredEdge": @(NSMinXEdge),
        },
        
        @{ @"message": @"tidyFirstRun40",
           @"showRelativeToRect": NSStringFromRect(self.feedbackController.tabsBarView.bounds),
           @"ofView": self.feedbackController.tabsBarView,
           @"preferredEdge": @(NSMinXEdge),
           @"keyPath": @"feedbackController.selectedTabViewItem",
           @"keyPathValue": self.feedbackController.messagesTabViewItem,
        },

        @{ @"message": appController.featureDualPreview ? @"tidyFirstRun50a" : @"tidyFirstRun50b",
           @"showRelativeToRect": NSStringFromRect(self.feedbackController.tabsBarView.bounds),
           @"ofView": self.feedbackController.tabsBarView,
           @"preferredEdge": @(NSMaxYEdge),
           @"keyPath": @"feedbackController.selectedTabViewItem",
           @"keyPathValue": self.feedbackController.previewTabViewItem,
        },
        @{ @"message": @"tidyFirstRun60",
           @"showRelativeToRect": NSStringFromRect(self.feedbackController.tabsBarView.bounds),
           @"ofView": self.feedbackController.tabsBarView,
           @"preferredEdge": @(NSMaxXEdge),
           @"keyPath": @"feedbackController.selectedTabViewItem",
           @"keyPathValue": self.feedbackController.validatorTabViewItem,
           @"newInVersion": @"4.0.0",
        },
        
        @{ @"message": @"tidyFirstRun70",
           @"showRelativeToRect": NSStringFromRect(self.optionPane.bounds),
           @"ofView": self.optionPane,
           @"preferredEdge": @(NSMinXEdge)
        },
        
        @{ @"message": @"tidyFirstRun80",
           @"showRelativeToRect": NSStringFromRect(self.sourceViewController.splitterViews.bounds),
           @"ofView": self.sourceViewController.splitterViews,
           @"preferredEdge": @(NSMinXEdge),
        },
        
        @{ @"message": @"tidyFirstRun85",
           @"showRelativeToRect": NSStringFromRect(NSZeroRect),
           @"ofView": self.sourceViewController.sourceTextView,
           @"preferredEdge": @(NSMinYEdge),
           @"newInVersion": @"4.1.0",
        },
        
        @{ @"message": @"tidyFirstRun90",
           @"showRelativeToRect": NSStringFromRect(self.sourceViewController.sourceTextView.bounds),
           @"ofView": self.sourceViewController.sourceTextView,
           @"preferredEdge": @(NSMinXEdge),
        },
    ];
    
    self.firstRunHelper = [[FirstRunController alloc] initWithSteps:firstRunSteps];
    
    self.firstRunHelper.preferencesKeyNameComplete = JSDKeyFirstRunComplete;
    self.firstRunHelper.preferencesKeyNameCompleteVersion = JSDKeyFirstRunCompleteVersion;
    
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAnimationReduce] )
    {
        self.firstRunHelper.animationSpeed = 0.0f;
    }
    else
    {
        self.firstRunHelper.animationSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyAnimationStandardTime];
    }
    
    self.firstRunHelper.delegate = self;
    
    if (!self.optionsPanelIsVisible)
    {
        self.optionsPanelIsVisible = YES;
    }
    
    if (!self.feedbackPanelIsVisible)
    {
        self.feedbackPanelIsVisible = YES;
    }
    
    if ([[PreferenceController sharedPreferences] documentWindowIsInScreenshotMode])
    {
        [self.window setAlphaValue:0.0f];
    }
    
    [self.firstRunHelper beginFirstRunSequence:sender];
}


#pragma mark - Category Properies


/*———————————————————————————————————————————————————————————————————*
 * @property tidyProcess
 *———————————————————————————————————————————————————————————————————*/
- (JSDTidyModel *)tidyProcess
{
    return ((TidyDocument*)self.document).tidyProcess;
}


/*———————————————————————————————————————————————————————————————————*
 * @property tidyErrors
 *———————————————————————————————————————————————————————————————————*/
- (NSArray <MGSSyntaxError *> *)tidyErrors
{
    return self.tidyProcess.fragariaErrorArray;
}


/*———————————————————————————————————————————————————————————————————*
 * @property sourceValidatorErrors
 *———————————————————————————————————————————————————————————————————*/
- (NSArray <MGSSyntaxError *> *)sourceValidatorErrors
{
    return self.feedbackController.validatorController.sourceValidator.fragariaErrorArray;
}


/*———————————————————————————————————————————————————————————————————*
 * @property tidyValidatorErrors
 *———————————————————————————————————————————————————————————————————*/
- (NSArray <MGSSyntaxError *> *)tidyValidatorErrors
{
    return self.feedbackController.validatorController.tidyValidator.fragariaErrorArray;
}


@end
