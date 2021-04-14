//
//  MiscOptionsViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "MiscOptionsViewController.h"


@implementation MiscOptionsViewController


- (id)init
{
    return [super initWithNibName:@"MiscOptionsViewController" bundle:nil];
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
    return @"MiscOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsAdvanced"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", nil);
}

@end
