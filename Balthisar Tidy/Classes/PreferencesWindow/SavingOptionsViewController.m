//
//  SavingOptionsViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "SavingOptionsViewController.h"


@implementation SavingOptionsViewController


- (id)init
{
    return [super initWithNibName:@"SavingOptionsViewController" bundle:nil];
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
    return @"SavingOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsSaving"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"File Saving", nil);
}

@end
