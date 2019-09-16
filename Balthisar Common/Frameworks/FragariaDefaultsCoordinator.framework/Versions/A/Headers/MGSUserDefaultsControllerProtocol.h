//
//  MGSUserDefaultsControllerProtocol.h
//  Fragaria
//
//  Created by Jim Derry on 3/24/15.
//
//
#include <Cocoa/Cocoa.h>
#include "MGSUserDefaultsDelegate.h"


@class MGSFragariaView;


/**
 *  A bit field indicating which appearances a user defaults controller
 *  provides automatic support for. Although these are available to
 *  choose on macOS < 10.14, setting anything other than
 *  MGSAppearanceNameAqua will have no effect on such systems.
 */
typedef NS_OPTIONS(NSInteger, MGSSupportedAppearance)
{
    MGSAppearanceNameAqua                              = 0,
    MGSAppearanceNameAccessibilityHighContrastAqua     = 1 << 0,
    MGSAppearanceNameDarkAqua                          = 1 << 1,
    MGSAppearanceNameAccessibilityHighContrastDarkAqua = 1 << 2
};


/**
 *  The MGSUserDefaultsController protocol defines the properties and methods
 *  that are required for objects to be used with the Defaults Coordinator
 *  system user interface objects.
 *
 *  @discussion Both MGSUserDefaultsController (class) and
 *      MGSHybridUserDefaultsController conform to this protocol and can be
 *      used interchangeably.
 */

@protocol MGSUserDefaultsController <NSObject>


#pragma mark - Required Properties and Methods
/// @name Required Properties and Methods
@required


/** The groupID uniquely identifies the preferences that
 *  are managed by instances of this controller. */
@property (nonatomic,strong,readonly) NSString *groupID;


/** Indicates the instances of MGSFragaria whose properties are
 *  managed by an instance of this controller. */
@property (nonatomic,strong,readonly) NSSet<MGSFragariaView *> *managedInstances;


/** Indicates a set of NSString indicating the name of every property
 *  that is to be managed by this instance of this class. */
@property (nonatomic,strong,readonly) NSSet<NSString *> *managedProperties;


/** Provides KVO-compatible structure for use with NSObjectController.
 *  @discussion Use only KVC setValue:forKey: and valueForKey: with this
 *      object. In general you have no reason to manually manipulate values
 *      with this structure. Simply set MGSFragariaView properties instead. */
@property (nonatomic,strong,readonly) id values;


/** Specifies the additional appearance(s) supported by this controllers' group.
 */
@property (nonatomic,assign) MGSSupportedAppearance appearanceSubgroups;


#pragma mark - Optional Properties and Methods
/// @name Optional Properties and Methods
@optional

/** Specifies a delegate for this controller.
 */
@property (nonatomic,assign) NSObject <MGSUserDefaultsDelegate> *delegate;


@end
