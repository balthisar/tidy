//
//  AppDelegate.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "AppDelegate.h"

#import "TidyService.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    TidyService *tidyService = [[TidyService alloc] init];

    /* Use NSRegisterServicesProvider instead of NSApp:setServicesProvider
     * so that we can have careful control over the port name.
     */
    NSRegisterServicesProvider(tidyService, @"com.balthisar.service.port");

    /* If started by simply launching Balthisar Tidy, quit immediately.
     * This message will be sent by Balthisar Tidy soon after launching.
     */
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(handleTerminate:)
                                                            name:@"balthisarTidyHelperOpenThenQuit"
                                                          object:@"BalthisarTidy"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleTerminate:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTerminate:(NSNotification*)aNotification
{
    [[NSApplication sharedApplication] terminate:self];
}


@end
