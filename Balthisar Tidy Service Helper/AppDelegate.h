/**************************************************************************************************

	AppDelegate
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

/**
 * Registers the helper application with the services system.
 */
@interface AppDelegate : NSObject <NSApplicationDelegate>

/**
 *  Handle the handleTerminate distributed notification.
 *
 *  Balthisar Tidy launches this helper every time it starts.
 *  This ensures that the system knows the helper is capable of
 *  providing a service. However we don't want it to hang around
 *  open all the time. Because we're sandboxed a lot of other
 *  means to terminate (such as NSTask and NSWorkspace) aren't
 *  effective, but Distributed Notifications still work among
 *  Application Groups.
 */
- (void)handleTerminate:(NSNotification*)aNotification;

@end

