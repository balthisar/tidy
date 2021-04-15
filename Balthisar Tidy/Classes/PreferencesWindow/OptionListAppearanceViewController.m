//
//  OptionListAppearanceViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "OptionListAppearanceViewController.h"


@implementation OptionListAppearanceViewController


- (id)init
{
    return [super initWithNibName:@"OptionListAppearanceViewController" bundle:nil];
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
