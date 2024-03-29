//
//  PrefsTidyViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "PrefsTidyViewController.h"

#import "OptionPaneController.h"
#import "PreferenceController.h"

@import JSDTidyFramework;


#pragma mark - CATEGORY - Non-Public


@interface PrefsTidyViewController ()

@property (weak) IBOutlet NSView    *optionControllerView;   // The empty pane in the nib that we will inhabit.

@property OptionPaneController      *optionController;       // The real option pane loaded into optionPane.

@end


#pragma mark - IMPLEMENTATION


@implementation PrefsTidyViewController


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
    return [super initWithNibName:@"PrefsTidyViewController" bundle:nil];
}



/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - awakeFromNib
 *  - Setup the option panel controller.
 *  - Give the OptionPaneController its optionsInEffect.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
    
    /* Create and setup the option controller. */
    
    self.optionController = [[OptionPaneController alloc] init];
    
    self.optionController.isInPreferencesView = YES;
    
    [self.optionControllerView addSubview:self.optionController.view];
    
    [self.optionController.view setFrame:self.optionControllerView.bounds];
    
    self.optionController.optionsInEffect = [PreferenceController optionsInEffect];
    
    
    /* Set the option values in the optionController from user defaults. */
    
    [[[self optionController] tidyDocument] takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];
    
    
    /* NSNotifications from `optionController` indicate that one or more
     * Tidy options changed. This is what we will use to capture changes and
     * record them into user defaults.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTidyOptionChange:)
                                                 name:tidyNotifyOptionChanged
                                               object:[[self optionController] tidyDocument]];
}


#pragma mark - Events


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleTidyOptionChange:
 *  We're here because we registered for NSNotification.
 *  One of the preferences changed in the option pane.
 *  We're going to record the preference, but we're not
 *  going to post a notification, because new documents
 *  will read the preferences themselves.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
    [self.optionController.tidyDocument writeOptionValuesWithDefaults:[NSUserDefaults standardUserDefaults]];
}


#pragma mark - <MASPreferencesViewController> Support


- (BOOL)hasResizableHeight
{
    return YES;
}


- (BOOL)hasResizableWidth
{
    return YES;
}


- (NSString *)viewIdentifier
{
    return @"OptionListPreferences";
}


- (NSImage *)toolbarItemImage
{
    NSImage *image = [NSImage imageNamed:@"prefsTidy"];
    [image setTemplate:YES];
    return image;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Tidy Options", nil);
}

@end
