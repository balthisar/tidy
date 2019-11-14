//
//  JSDScriptSuiteRegistry.h
//
//  Copyright © 2019 Jim Derry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSDScriptSuiteRegistry : NSScriptSuiteRegistry


/**
 * Return our current instance type.
 */
+ (instancetype)sharedScriptSuiteRegistry;


/**
 * Actually do load the suites. Only to be called once you're sure you want
 * to enable AppleScript, because with Cocoa Scripting, there's not any going
 * back until the next application run.
 */
- (void)loadSuitesFromMainBundle;


@end

NS_ASSUME_NONNULL_END
