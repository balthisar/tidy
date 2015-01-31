/**************************************************************************************************

	AppDelegate
 
	Registers the helper application with the services system.


	The MIT License (MIT)

	Copyright (c) 2001 to 2014 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
		Balthisar Tidy launches this helper every time it starts.
		This ensures that the system knows the helper is capable of
		providing a service. However we don't want it to hang around
		open all the time. Because we're sandboxed a lot of other
		means to terminate (such as NSTask and NSWorkspace) aren't
		effective, but Distributed Notifications still work among
        Application Groups.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTerminate:(NSNotification*)aNotification
{
	[[NSApplication sharedApplication] terminate:self];
}


@end
