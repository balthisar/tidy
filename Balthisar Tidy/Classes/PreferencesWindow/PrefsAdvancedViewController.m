//
//  PrefsAdvancedViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "PrefsAdvancedViewController.h"


@implementation PrefsAdvancedViewController


- (id)init
{
    return [super initWithNibName:@"PrefsAdvancedViewController" bundle:nil];
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
    NSImage *image = [NSImage imageNamed:@"prefsAdvanced"];
    [image setTemplate:YES];
    return image;
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", nil);
}

@end
