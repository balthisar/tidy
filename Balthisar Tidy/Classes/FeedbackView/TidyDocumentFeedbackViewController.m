/**************************************************************************************************

	TidyDocumentFeedbackViewController
	 
	Copyright © 2003-2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TidyDocumentFeedbackViewController.h"
#import "CommonHeaders.h"

#import "TDFTableViewController.h"
#import "TDFPreviewController.h"
#import "TDFValidatorViewController.h"

#import "MMTabBarView/MMTabBarView.h"
#import "NSImage+Tinted.h"

#import "TidyDocument.h"

@import JSDTidyFramework;
@import JSDNuVFramework;


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

        self.validatorController = [[TDFValidatorViewController alloc] init];
    }

    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * Cleanup KVC
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    [((TidyDocument*)self.representedObject).tidyProcess removeObserver:self forKeyPath:@"errorArray" ];
	[self.validatorController.arrayController removeObserver:self forKeyPath:@"arrangedObjects"];
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
     Setup the validatorController and its view settings.
     ******************************************************/

    self.validatorController.representedObject = self.representedObject;

    [self.validatorPane addSubview:self.validatorController.view];

    self.validatorController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    [self.validatorController.view setFrame:self.validatorPane.bounds];


    /******************************************************
     Setup the tabsBar, including setting the default item
     to match whatever the NSTabView is currently showing.
     ******************************************************/
    
    /* Overall appearance */
    [self.tabsBarView setStyleNamed:@"Mojave"];
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

	/* KVO on the validator controller so that we know how many validator messages there are. */
	[self.validatorController.arrayController addObserver:self
											   forKeyPath:@"arrangedObjects"
												  options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)
												  context:NULL];

	/* We need to observe the window active state, otherwise MMTabBarView doesn't
	   work on views with CALayer backing. */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeInactiveState) name:NSWindowDidBecomeMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeInactiveState) name:NSWindowDidResignMainNotification object:nil];

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
	[self.tabsBarView setNeedsDisplay:YES];
	/* Handle changes from the errorArray in order to display the number of messages in the tab. */
	if ((object == ((TidyDocument*)self.representedObject).tidyProcess) && ([keyPath isEqualToString:@"errorArray"]))
	{
        [self updateMessageCountDisplay];
    }

	if (object == self.validatorController.arrayController && [keyPath isEqualToString:@"arrangedObjects"])
	{
		[self updateValidatorCountDisplay];
	}
}


/*———————————————————————————————————————————————————————————————————*
 * React to window active/inactive to update the tabs' display.
 *———————————————————————————————————————————————————————————————————*/
- (void)changeInactiveState
{
	[self.tabsBarView setNeedsUpdate:YES];
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
	[self updateValidatorCountDisplay];
    [self updateIconImages];
    if (tabViewItem == self.previewTabViewItem)
    {
        [self.previewController updateWebViews];
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyErrorsChanged object:self];
}


#pragma mark - Instance Methods


/*———————————————————————————————————————————————————————————————————*
 * Update the icons. We want light icons on unselected tabs.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateIconImages
{
	NSArray *icons = @[
					   @{ @"panel" : self.messagesTabViewItem,  @"img" : @"messages-messages"  },
					   @{ @"panel" : self.previewTabViewItem,   @"img" : @"messages-browser"   },
					   @{ @"panel" : self.validatorTabViewItem, @"img" : @"messages-validator" },
					   ];

    for (NSDictionary *item in icons)
	{
		NSTabViewItem *tabViewItem = (NSTabViewItem*)item[@"panel"];
		NSColor *tint;

		if ( tabViewItem.tabState == NSSelectedTab )
		{
			tint = [NSColor selectedKnobColor];
		}
		else
		{
			tint = [NSColor knobColor];
		}

		NSImage *img = [[NSImage imageNamed:item[@"img"]] tintedWithColor:tint];

		[tabViewItem.identifier setValue:img forKey:@"icon"];
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


/*———————————————————————————————————————————————————————————————————*
 * Update the message count on the validator tab if it's not the
 * current tab.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateValidatorCountDisplay
{
	NSArray *localErrors = self.validatorController.arrayController.arrangedObjects;
	NSUInteger total = localErrors.count;

	if (total < 1 || self.validatorTabViewItem.tabState == NSSelectedTab)
	{
		total = 0;
	}

	[[self.validatorTabViewItem identifier] setValue:@(total > 0) forKey:@"showObjectCount"];

	if (total > 0)
	{
		NSUInteger level = [[localErrors valueForKeyPath:@"@max.typeID"] integerValue];

		NSColor *countColor;
		switch (level)
		{
			case JSDNuVInfo:
				countColor = [NSColor colorWithCalibratedRed:0.977f green:0.773f blue:0.258f alpha:0.75f];
				break;
			case JSDNuVError:
				countColor = [NSColor colorWithCalibratedRed:0.922f green:0.0f blue:0.016f alpha:0.75f];;
				break;
			default:
				countColor = [NSColor colorWithCalibratedWhite:0.3 alpha:0.45];
				break;
		}

		[[self.validatorTabViewItem identifier] setValue:@(total) forKey:@"objectCount"];
		[[self.validatorTabViewItem identifier] setValue:countColor forKeyPath:@"objectCountColor"];
	}
}


@end
