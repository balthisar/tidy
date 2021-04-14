//
//  FragariaColorsViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "FragariaColorsViewController.h"


@implementation FragariaColorsViewController


#pragma mark - <MASPreferencesViewController> Support


- (id)init
{
    return [super initWithNibName:@"FragariaColorsViewController" bundle:nil];
}


- (NSString *)viewIdentifier
{
    return @"FragariaColorPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsTheme"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Theme Options", nil);
}

@end
