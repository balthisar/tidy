//
//  FragariaEditorViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "FragariaEditorViewController.h"


@implementation FragariaEditorViewController


#pragma mark - <MASPreferencesViewController> Support


- (id)init
{
    return [super initWithNibName:@"FragariaEditorViewController" bundle:nil];
}


- (NSString *)viewIdentifier
{
    return @"FragariaEditorPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsEditing"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Editing Options", nil);
}

@end
