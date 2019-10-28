//
//  AppDelegate.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "AppDelegate.h"

#import "TidyService.h"
#import "CommonHeaders.h"
#import "JSDScriptSuiteRegistry.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize sharedUserDefaults = _sharedUserDefaults;


#pragma mark - Application Delegate Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - applicationDidFinishLaunching:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [JSDScriptSuiteRegistry sharedScriptSuiteRegistry];

    [self.sharedUserDefaults addObserver:self
                              forKeyPath:JSDKeyServiceHelperAllowsAppleScript
                                 options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                                 context:nil];
}


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


#pragma mark - Notification Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleTerminate:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTerminate:(NSNotification*)aNotification
{
    [[NSApplication sharedApplication] terminate:self];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - observeValueForKeyPath:ofObject:change:context:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:JSDKeyServiceHelperAllowsAppleScript] && [change valueForKey:NSKeyValueChangeNewKey])
    {
        if ([[change valueForKey:NSKeyValueChangeNewKey] boolValue])
        {
            [[JSDScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromMainBundle];
        }
    }
}


#pragma mark - Convenience Properties


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @sharedUserDefaults
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSUserDefaults *)sharedUserDefaults
{
    if (!_sharedUserDefaults)
    {
        _sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];
    }

    return _sharedUserDefaults;
}


@end
