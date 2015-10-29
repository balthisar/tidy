/**************************************************************************************************

	AppDelegate
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "AppDelegate.h"

#import "TidyService.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_9)
	{
		TidyService *tidyService = [[TidyService alloc] init];

		/*
		  Use NSRegisterServicesProvider instead of NSApp:setServicesProvider
		  So that we can have careful control over the port name.
		 */
		NSRegisterServicesProvider(tidyService, @"com.balthisar.service.port");
	}
	else
	{
		NSLog(@"%@", @"TidyServiceHelper can only work on Mac OS X 10.9 and above.");
	}
	
	/* 
	  If started by simply launching Balthisar Tidy_ quit immediately.
	  This message will be sent by Balthisar Tidy soon after launching.
	 */
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTerminate:) name:@"balthisarTidyHelperOpenThenQuit" object:@"BalthisarTidy"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleTerminate:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTerminate:(NSNotification*)aNotification
{
	[[NSApplication sharedApplication] terminate:self];
}


@end
