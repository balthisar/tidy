//
//  PrefsUpdatesViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "PrefsUpdatesViewController.h"
#import "CommonHeaders.h"

#import "OptionPaneController.h"

#ifdef FEATURE_SPARKLE
#import <Sparkle/Sparkle.h>
#endif


@implementation PrefsUpdatesViewController


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
    return [super initWithNibName:@"PrefsUpdatesViewController" bundle:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - awakeFromNib
 *  - Setup Sparkle vs No-Sparkle.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
    /* Setup Sparkle versus No-Sparkle versions */
    
#ifdef FEATURE_SPARKLE
    
    /* We'll communicate to Sparkle via user defaults now because its old
     * singleton controller is deprecated, and since Sparkle monitors user
     * defaults, there's no need to instantiate bits and pieces of it.
     */
    NSUserDefaultsController *sharedDefaults = [NSUserDefaultsController sharedUserDefaultsController];
    
    [[self buttonAllowUpdateChecks] bind:@"value" toObject:sharedDefaults withKeyPath:@"values.SUEnableAutomaticChecks" options:nil];
    [[self buttonUpdateInterval] bind:@"enabled" toObject:sharedDefaults withKeyPath:@"values.SUEnableAutomaticChecks" options:nil];
    [[self buttonAllowAutoUpdate] bind:@"enabled" toObject:sharedDefaults withKeyPath:@"values.SUEnableAutomaticChecks" options:nil];
    
    [[self buttonUpdateInterval] bind:@"selectedTag" toObject:sharedDefaults withKeyPath:@"values.SUScheduledCheckInterval" options:nil];
    [[self buttonAllowAutoUpdate] bind:@"value" toObject:sharedDefaults withKeyPath:@"values.SUAutomaticallyUpdate" options:nil];
    
    [[self buttonAllowSystemProfile] bind:@"value" toObject:sharedDefaults withKeyPath:@"values.SUEnableSystemProfiling" options:nil];
    
#endif
}


#pragma mark - <MASPreferencesViewController> Support


- (BOOL)hasResizableHeight
{
    return NO;
}


- (BOOL)hasResizableWidth
{
    return NO;
}


- (NSString *)viewIdentifier
{
    return @"UpdaterOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
    NSImage *image = [NSImage imageNamed:@"prefsUpdate"];
    [image setTemplate:YES];
    return image;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Software Updates", nil);
}

@end
