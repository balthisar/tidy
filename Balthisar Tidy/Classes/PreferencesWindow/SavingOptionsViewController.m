/**************************************************************************************************

	SavingOptionsViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "SavingOptionsViewController.h"


@implementation SavingOptionsViewController


- (id)init
{
    return [super initWithNibName:@"SavingOptionsViewController" bundle:nil];
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
    return @"SavingOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsSave"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"File Saving", nil);
}

@end
