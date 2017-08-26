/**************************************************************************************************

	TidyDocumentFeedbackViewController
	 
	Copyright © 2003-2017 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TidyDocumentFeedbackViewController.h"
#import "CommonHeaders.h"

#import "TDFTableViewController.h"
#import "TDFPreviewController.h"

#import "MMTabBarView/MMTabBarView.h"

#import "JSDTidyModel.h"
#import "JSDTidyMessage.h"
#import "TidyDocument.h"


@implementation TidyDocumentFeedbackViewController


#pragma mark - Intialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
 * Create our subordinate controllers here so that they exist when
 * other things are initialized.
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        self.messagesController = [[TDFTableViewController alloc] init];
        
        self.previewController = [[TDFPreviewController alloc] init];
    }

    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * Cleanup KVC
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    [((TidyDocument*)self.representedObject).tidyProcess removeObserver:self forKeyPath:@"errorArray" ];
}


/*———————————————————————————————————————————————————————————————————*
 * Create all of our major controllers and setup the tabsbar
 * appearance and behavior.
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
    /******************************************************
     Setup the messagesController and its view settings.
     ******************************************************/

    self.messagesController.representedObject = self.representedObject;

    [self.messagesPane addSubview:self.messagesController.view];

    self.messagesController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    [self.messagesController.view setFrame:self.messagesPane.bounds];

    
    /******************************************************
     Setup the previewController and its view settings.
     ******************************************************/

    self.previewController.representedObject = self.representedObject;

    [self.previewPane addSubview:self.previewController.view];

    self.previewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    [self.previewController.view setFrame:self.previewPane.bounds];


    /******************************************************
     Setup the tabsBar, including setting the default item
     to match whatever the NSTabView is currently showing.
     ******************************************************/
    
    /* Overall appearance */
    [self.tabsBarView setStyleNamed:@"Yosemite"];
    [self.tabsBarView setDisableTabClose:YES];
    [self.tabsBarView setHideForSingleTab:NO];
    [self.tabsBarView setShowAddTabButton:NO];
    [self.tabsBarView setSizeButtonsToFit:NO];
    [self.tabsBarView setUseOverflowMenu:NO];
    [self.tabsBarView setAlwaysShowActiveTab:YES];
    [self.tabsBarView setResizeTabsToFitTotalWidth:YES];
    
    /* Each tab's identifier will be the instance of the attached button,
       so that we may simply KVC-assign properties without regard to type. */
    for (NSTabViewItem *item in self.tabView.tabViewItems)
    {
        item.identifier = [self.tabsBarView attachedButtonForTabViewItem:item];
    }
    
    /* Individual tabs' appearance */
    [self updateIconImages];

    /* KVO on the represented object so we know how many messages there are. */
    [((TidyDocument*)self.representedObject).tidyProcess addObserver:self
                                                          forKeyPath:@"errorArray"
                                                             options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
                                                             context:NULL];
    
}


#pragma mark - Property Accessors
/*———————————————————————————————————————————————————————————————————*
 * Allows us to set and get the current TabViewItem via KVC.
 *———————————————————————————————————————————————————————————————————*/
- (NSTabViewItem *)selectedTabViewItem
{
    return self.tabView.selectedTabViewItem;
}

- (void)setSelectedTabViewItem:(NSTabViewItem *)selectedTabViewItem
{
    [self.tabView selectTabViewItem:selectedTabViewItem];
}


#pragma mark - KVO and Notifications


/*———————————————————————————————————————————————————————————————————*
 * Handle KVO Notifications:
 *  - the errorArray changed, and we need to update the number of
 *    messages in the tab.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	/* Handle changes from the errorArray in order to display the number of messages in the tab. */
	if ((object == ((TidyDocument*)self.representedObject).tidyProcess) && ([keyPath isEqualToString:@"errorArray"]))
	{
        [self updateMessageCountDisplay];
    }
}


#pragma mark - Delegate Methods


/*———————————————————————————————————————————————————————————————————*
 * - Ensure that the messageCount is only displayed if the messages
 *   tab is not current.
 * - Update the icon images.
 * - Update the preview if switching to preview tab.
 *———————————————————————————————————————————————————————————————————*/
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self updateMessageCountDisplay];
    [self updateIconImages];
    if (tabViewItem == self.previewTabViewItem)
    {
        [self.previewController updateWebViews];
    }
}


#pragma mark - Instance Methods


/*———————————————————————————————————————————————————————————————————*
 * Update the icons. We want light icons on unselected tabs.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateIconImages
{
    NSArray *icons = @[
                       @{ @"panel" : self.messagesTabViewItem, @"selected" : @"messages-messages", @"unselected" : @"messages-messages-light" },
                       @{ @"panel" : self.previewTabViewItem,  @"selected" : @"messages-browser",  @"unselected" : @"messages-browser-light" },
                       ];

    for (NSDictionary *item in icons) {
        NSTabViewItem *tabViewItem = (NSTabViewItem*)item[@"panel"];
        if ( tabViewItem.tabState == NSSelectedTab )
        {
            [[tabViewItem identifier] setValue:[NSImage imageNamed:item[@"selected"]] forKey:@"icon"];
        }
        else
        {
            [[tabViewItem identifier] setValue:[NSImage imageNamed:item[@"unselected"]] forKey:@"icon"];
        }
    }
}


/*———————————————————————————————————————————————————————————————————*
 * Update the message count on the messages tab if it's not the
 * current tab.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateMessageCountDisplay
{
    NSArray *localErrors = ((TidyDocument*)self.representedObject).tidyProcess.errorArray;
    NSUInteger total = localErrors.count;
    
    if (total < 1 || self.messagesTabViewItem.tabState == NSSelectedTab)
    {
        total = 0;
    }

    [[self.messagesTabViewItem identifier] setValue:@(total > 0) forKey:@"showObjectCount"];

    if (total > 0)
    {
        NSUInteger level = [[((TidyDocument*)self.representedObject).tidyProcess.errorArray valueForKeyPath:@"@max.level"] integerValue];
        
        NSColor *countColor;
        switch (level)
        {
            case TidyInfo:
                countColor = [NSColor colorWithCalibratedWhite:0.3 alpha:0.45];
                break;
            case TidyWarning:
            case TidyConfig:
            case TidyAccess:
                countColor =  [NSColor colorWithCalibratedRed:0.977f green:0.773f blue:0.258f alpha:0.75f];
                break;
            default:
                countColor =  [NSColor colorWithCalibratedRed:0.922f green:0.0f blue:0.016f alpha:0.75f];
                break;
        }
        
        [[self.messagesTabViewItem identifier] setValue:@(total) forKey:@"objectCount"];
        [[self.messagesTabViewItem identifier] setValue:countColor forKeyPath:@"objectCountColor"];
    }
}


@end
