//
//  JSSDTidyFramework.h
//  JSSDTidyFramework
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//
//  The JSDTidyFramework builds JSDTidyModel and its associated classes
//  and dependencies into a single, shared framework.
//

@import Cocoa;

FOUNDATION_EXPORT double JSDTidyFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char JSDTidyFrameworkVersionString[];

#import "JSDTidyModel.h"
#import "JSDTidyModelDelegate.h"
#import "JSDTidyOption.h"
#import "JSDTidyMessage.h"
#import "JSDTidyModel+Developer.h"
