//
//  MGSHybridUserDefaultsController.h
//  Fragaria
//
//  Created by Jim Derry on 3/24/15.
//
//

#import <Foundation/Foundation.h>
#import "MGSUserDefaultsControllerProtocol.h"


/**
 *  This class masquerades as an MGSUserDefaultsController by adopting its
 *  protocol. It wraps a sharedControllerForGroupID: and a sharedController
 *  so that they can act as one object when bound in the user interface.
 *
 *  All of the properties are read-only, and consist of the union of the
 *  respective properties of the current global sharedController and the
 *  specified groupID.
 *
 *  Delegate and Protocol Adoption
 *  Note that this controller does NOT support a delegate directly. If you
 *  wish to adopt <MGSUserDefaultsDelegate>, then set a delegate directly on
 *  the underlying sharedControllerForGroupID: and/or sharedController.
 **/

@interface MGSHybridUserDefaultsController : NSObject <MGSUserDefaultsController>


/** Provides a hybrid object consisting of the shared controller for `groupID`
 *  and the global group.
 *  @param groupID Indicates the identified for this group
 *      of user defaults. */
+ (instancetype)sharedControllerForGroupID:(NSString *)groupID;


#pragma mark - <MGSUserDefaults> Conformance - Properties


/** The groupID uniquely identifies the preferences that
 *  are managed by instances of this controller. */
@property (nonatomic,strong,readonly) NSString *groupID;


/** Specifies the instances of MGSFragaria whose properties are
 *  managed by an instance of this controller.
 *
 *  @discussion When used with the sharedController (without a groupID)
 *      setting this property will have no effect. It will only contain
 *      a set of MGSFragariaView instances for _all_ user defaults
 *      controllers. */
@property (nonatomic,strong,readonly) NSSet<MGSFragariaView *> *managedInstances;

/** Specifies a set of NSString indicating the name of every property
 *  that is to be managed by this instance of this class. */
@property (nonatomic,strong,readonly) NSSet<NSString *> *managedProperties;


/** Provides KVO-compatible structure for use with NSObjectController.
 *  @discussion Use only KVC setValue:forKey: and valueForKey: with this
 *      object. In general you have no reason to manually manipulate values
 *      with this structure. Simply set MGSFragariaView properties instead. */
@property (nonatomic,strong,readonly) id values;


#pragma mark - Appearance Support


/** Specifies the additional appearance(s) supported by this controllers' group.
 *  @discussion Only applicable when macOS is 10.14+. The default value is
 *      MGSAppearanceNameAqua|MGSAppearanceNameDarkAqua on macOS10.14_,
 *      which will store and retrieve MGSFragariaView properties according to
 *      the effective appearance of one of the managedInstances. Which managed
 *      instance is random, but a well behaved application will be consistent
 *      and they would all have the same appearance.
 */
@property (nonatomic,assign) MGSSupportedAppearance appearanceSubgroups;


@end
