/**************************************************************************************************

	FragariaColorsViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "FragariaColorsViewController.h"


@implementation FragariaColorsViewController


#pragma mark - <MASPreferencesViewController> Support


- (id)init
{
    return [super initWithNibName:@"FragariaColorsViewController" bundle:nil];
}


- (NSString *)identifier
{
    return @"FragariaColorPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsColor"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Theme Options", nil);
}

@end
