//
//  ProFeaturesViewController.m
//
//  Copyright © 2019 by Jim Derry. All rights reserved.
//

#import "ProFeaturesViewController.h"


@implementation ProFeaturesViewController


- (id)init
{
    return [super initWithNibName:@"ProFeaturesViewController" bundle:nil];
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
    return @"ProFeaturesPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsPro"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Pro", nil);
}


- (IBAction)appStoreNewPurchase:(id)sender
{
    NSLog(@"%@", @"Buy Stuff");
}

- (IBAction)appStoreRestorePurchase:(id)sender
{
    NSLog(@"%@", @"Restore Stuff");
}


@end
