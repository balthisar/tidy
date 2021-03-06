/**************************************************************************************************
 *
 * JSDNuVFramework
 *
 *  The JSDNuVFramework provides utilities to perform documentation validation over the network
 *  with the W3C Nu Validator service. It also provides access to a local instance of the validator
 *  packaged within the framework, as well as the minimum Java JRE to support the validator.
 *
 *  Copyright © 2018 by Jim Derry. All rights reserved.
 *
 **************************************************************************************************/

@import Cocoa;

FOUNDATION_EXPORT double JSDNuVFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char JSDNuVFrameworkVersionString[];

#import "JSDNuVServer.h"
#import "JSDNuValidator.h"
#import "JSDNuValidatorDelegate.h"
#import "JSDNuVMessage.h"
