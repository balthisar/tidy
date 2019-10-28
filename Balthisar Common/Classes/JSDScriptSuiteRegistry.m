//
//  JSDScriptSuiteRegistry.h
//
//  Copyright © 2019 Jim Derry. All rights reserved.
//

#import "JSDScriptSuiteRegistry.h"

@implementation JSDScriptSuiteRegistry


+ (instancetype)sharedScriptSuiteRegistry
{
    return (JSDScriptSuiteRegistry*)[super sharedScriptSuiteRegistry];
}


- (void)loadSuitesFromMainBundle
{
    NSLog(@"%@", @"Balthisar Tidy loading AppScript SDEF's.");
    [super loadSuitesFromBundle:[NSBundle mainBundle]];
}

- (void)loadSuitesFromBundle:(NSBundle*)bundle
{
    // noop; we don't want CocoaScripting to load resources.
    NSLog(@"%@", @"Balthisar Tidy skipping loading AppleScript SDEF's.");
}


@end
