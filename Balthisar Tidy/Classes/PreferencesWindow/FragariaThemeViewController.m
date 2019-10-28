//
//  FragariaThemeViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "FragariaThemeViewController.h"


@implementation FragariaThemeViewController


#pragma mark - <MASPreferencesViewController> Support


- (id)init
{
    return [super initWithNibName:@"FragariaThemeViewController" bundle:nil];
}


- (NSString *)viewIdentifier
{
    return @"FragariaColorPreferences";
}


- (NSImage *)toolbarItemImage
{
    NSImage *image = [NSImage imageNamed:@"prefsTheme"];
    [image setTemplate:YES];
    return image;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Theme Options", nil);
}

@end
