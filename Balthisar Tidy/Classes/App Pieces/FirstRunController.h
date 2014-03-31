//
//  FirstRunController.h
//  Balthisar Tidy
//
//  Created by Jim Derry on 3/29/14.
//  Copyright (c) 2014 Jim Derry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FirstRunController : NSObject


/* Initial with Steps right off the bat */
- (id)initWithSteps:(NSArray*)steps;

- (void)beginFirstRunSequence;

/**
	An array of steps, each step consisting of a dictionary of properties
    for each step with the keys:
	- message as NSString
	- showRelativeToRect as NSRect
	- ofView as NSView
	- preferredEdge as NSRectEdge
 */
@property (nonatomic, strong) NSArray *steps;


@property (nonatomic, strong) NSString *preferencesKeyName;


@end
