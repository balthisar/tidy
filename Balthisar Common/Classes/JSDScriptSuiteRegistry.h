//
//  JSDScriptSuiteRegistry.h
//
//  Copyright © 2019 Jim Derry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - class JSDScriptSuiteRegistry

/**
 *  Override the NSScriptSuiteRegistry so that we can take manual control over the loading of
 *  scripting suites. This allows Balthisar Tidy to selectively support loading suites or
 *  not, thus giving a single application the ability to support or not support AppleScript.
 */
@interface JSDScriptSuiteRegistry : NSScriptSuiteRegistry


/**
 * Return our current instance type.
 */
+ (instancetype)sharedScriptSuiteRegistry;


/**
 * Overridden method that Cocoa calls automatically when an application is started. This
 * would normally load the SDEF's for us automatically if SDEF's are present in the bundle,
 * but we don't want this to happen if AppleScript support is an add-on feature.
 */
- (void)loadSuitesFromBundle:(NSBundle*)bundle;

/**
 * Actually do load the suites. Only to be called once you're sure you want
 * to enable AppleScript, because with Cocoa Scripting, there's not any going
 * back until the next application run.
 */
- (void)loadSuitesFromMainBundle;


@end

NS_ASSUME_NONNULL_END
