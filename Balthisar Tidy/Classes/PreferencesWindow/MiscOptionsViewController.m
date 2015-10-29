/**************************************************************************************************

	MiscOptionsViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

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


- (NSString *)identifier
{
    return @"MiscOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Miscellaneous", nil);
}

@end
