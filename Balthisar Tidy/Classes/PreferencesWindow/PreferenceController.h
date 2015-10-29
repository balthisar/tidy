/**************************************************************************************************

	PreferenceController
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import "MASPreferencesWindowController.h"

@class JSDTidyModel;


/**
 *  The main preference controller. Here we'll control the following:
 *
 *  - Handles the application preferences.
 *  - Implements class methods to be used before instantiation.
 *
 *  This controller is a subclass of MASPreferencesController, upon which we are piggybacking
 *  to continue to use the singleton instance of this class as our main preference controller.
 *  As the application preferences model is not very large or sophisticated, this is a logical
 *  place to manage it for the time being.
 */
@interface PreferenceController : MASPreferencesWindowController


#pragma mark - Class Methods


/** Singleton accessor for this class. */
+ (id)sharedPreferences;

/** An array of the tidy options that Balthisar Tidy supports. */
+ (NSArray*)optionsInEffect;


#pragma mark - Instance Methods


/** Registers Balthisar Tidy's defaults with Mac OS X' defaults system. */
- (void)registerUserDefaults;

/** Mirror standardUserDefaults into the application group preferences. */
- (void)handleUserDefaultsChanged:(NSNotification*)note; 


@end
