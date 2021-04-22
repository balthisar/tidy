//
//  PrefsSavingViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "PrefsSavingViewController.h"


@implementation PrefsSavingViewController


- (id)init
{
    return [super initWithNibName:@"PrefsSavingViewController" bundle:nil];
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
    NSImage *image = [NSImage imageNamed:@"prefsSaving"];
    [image setTemplate:YES];
    return image;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"File Saving", nil);
}

@end
