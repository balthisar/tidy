/**************************************************************************************************

	UpdaterOptionsViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "UpdaterOptionsViewController.h"
#import "CommonHeaders.h"

#import "OptionPaneController.h"

#ifdef FEATURE_SPARKLE
	#import <Sparkle/Sparkle.h>
#endif


@implementation UpdaterOptionsViewController


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
    return [super initWithNibName:@"UpdaterOptionsViewController" bundle:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - awakeFromNib
    - Setup Sparkle vs No-Sparkle.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
	/* Setup Sparkle versus No-Sparkle versions */

#ifdef FEATURE_SPARKLE

	SUUpdater *sharedUpdater = [SUUpdater sharedUpdater];

	[[self buttonAllowUpdateChecks] bind:@"value" toObject:sharedUpdater withKeyPath:@"automaticallyChecksForUpdates" options:nil];

	[[self buttonUpdateInterval] bind:@"enabled" toObject:sharedUpdater withKeyPath:@"automaticallyChecksForUpdates" options:nil];

	[[self buttonUpdateInterval] bind:@"selectedTag" toObject:sharedUpdater withKeyPath:@"updateCheckInterval" options:nil];

	[[self buttonAllowSystemProfile] bind:@"value" toObject:sharedUpdater withKeyPath:@"sendsSystemProfile" options:nil];

#endif
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
    return @"UpdaterOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"prefsUpdate"];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Software Updates", nil);
}

@end
