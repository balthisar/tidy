/**************************************************************************************************

	FirstRunController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  Implements a first run helper using an array of programmed steps:
 *  - message as NSString
 *  - showRelativeToRect as NSRect
 *  - ofView as NSView
 *  - preferredEdge as NSRectEdge
 */
@interface FirstRunController : NSObject


/** Steps array, as documented in the class header. */
@property (nonatomic, strong) NSArray *steps;

/** Preferences key to record whether or not helper finished. */
@property (nonatomic, strong) NSString *preferencesKeyName;

/** Indicates whether or not the helper is currently shown. */
@property (nonatomic, assign, readonly) BOOL isVisible;


/** Initalize with a steps array directly. */
- (instancetype)initWithSteps:(NSArray*)steps;

/** Start the sequence. */
- (void)beginFirstRunSequence;                   


@end
