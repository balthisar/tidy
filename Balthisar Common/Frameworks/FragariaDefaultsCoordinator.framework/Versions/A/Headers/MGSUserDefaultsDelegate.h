//
//  MGSUserDefaultsDelegate.h
//  Fragaria
//
//  Created by Jim Derry on 9/6/18.
//
#include <Cocoa/Cocoa.h>


@protocol MGSUserDefaultsDelegate

@optional
/** Ask the delegate to provide a dictionary of MGSFragariaView properties
 *  to be used for the given appearance. Properties not supplied by this
 *  delegate method will use the built-in defaults, so a complete list is
 *  not required.
 *
 *  Informally, the AppDelegate can adopt this method without setting the
 *  controller's delegate. This can be useful for overriding initial
 *  defaults that are applied during instantiation before a delegate can
 *  be set.
 */
- (NSDictionary *)defaultsForGroupID:(NSString*)groupID AppearanceName:(NSString *)appearanceName;


@end
