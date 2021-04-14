//
//  DocumentApperanceViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "DocumentAppearanceViewController.h"


@implementation DocumentAppearanceViewController


- (id)init
{
    return [super initWithNibName:@"DocumentAppearanceViewController" bundle:nil];
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
    return @"DocumentAppearancePreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsDoc"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Document Options", nil);
}

@end
