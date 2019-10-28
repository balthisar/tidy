//
//  PrefsTidyOptionsViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "PrefsTidyOptionsViewController.h"


@implementation PrefsTidyOptionsViewController


- (id)init
{
    return [super initWithNibName:@"PrefsTidyOptionsViewController" bundle:nil];
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
    return @"OptionListAppearancePreferences";
}


- (NSImage *)toolbarItemImage
{
    NSImage *image = [NSImage imageNamed:@"prefsTidyListOptions"];
    [image setTemplate:YES];
    return image;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Tidy List Options", nil);
}

@end
