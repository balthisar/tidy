//
//  JSDScriptSuiteRegistry.h
//
//  Copyright © 2019 Jim Derry. All rights reserved.
//

#import "JSDScriptSuiteRegistry.h"

@implementation JSDScriptSuiteRegistry

- (void)loadSuitesFromBundle:(NSBundle*)bundle
{
    // noop; we don't want CocoaScripting to load resources.
    NSLog(@"%@", @"Balthisar Tidy disabling AppScript, which is a premium feature.");
}

#if defined(PROBABLY_DONT_NEED_THESE)
- (void) _loadSuitesForAlreadyLoadedBundles
{
    // noop; we don't want CocoaScripting to load resources.
    NSLog(@"%@",@"_loadSuitesForAlreadyLoadedBundles");
}

- (void) _loadSuitesFromSDEFData:(NSData*) sdef bundle:(NSBundle*) bundle
{
    // noop; we don't want CocoaScripting to load resources.
    NSLog(@"%@",@"_loadSuitesFromSDEFData:bundle:");
}
#endif

@end
