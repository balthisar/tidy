//
//  JSDNuVFramework.h
//  JSDNuVFramework
//
//  Copyright © 2018-2019 by Jim Derry. All rights reserved.
//
//  The JSDNuVFramework provides utilities to perform documentation validation over the network
//  with the W3C Nu Validator service. It also provides access to a local instance of the validator
//  packaged within the framework, as well as the minimum Java JRE to support the validator.
//

@import Cocoa;

FOUNDATION_EXPORT double JSDNuVFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char JSDNuVFrameworkVersionString[];

#import <JSDNuVFramework/JSDNuVServer.h>
#import <JSDNuVFramework/JSDNuValidator.h>
#import <JSDNuVFramework/JSDNuValidatorDelegate.h>
#import <JSDNuVFramework/JSDNuVMessage.h>
