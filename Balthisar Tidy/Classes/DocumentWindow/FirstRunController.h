//
//  FirstRunController.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;

#import "AuxilliaryViewDelegate.h"


/**
 *  Implements a first run helper using an array of programmed steps:
 *  - message as NSString
 *  - showRelativeToRect as NSRect
 *  - ofView as NSView
 *  - preferredEdge as NSRectEdge
 */
@interface FirstRunController : NSObject  <AuxilliaryViewDelegate>


/** Steps array, as documented in the class header. */
@property (nonatomic, strong) NSArray *steps;

/** Preferences key to record whether or not helper finished. */
@property (nonatomic, strong) NSString *preferencesKeyNameComplete;

/** Preferences key to record the version number when the helper finished. */
@property (nonatomic, strong) NSString *preferencesKeyNameCompleteVersion;

/** The speed that animation should run at, or 0.0f to disable. */
@property (nonatomic, assign) float animationSpeed;

/** Indicates whether or not the helper is currently shown. */
@property (nonatomic, assign, readonly, getter=isVisible) BOOL visible;


/** Initalize with a steps array directly. */
- (instancetype)initWithSteps:(NSArray*)steps;

/** Start the sequence. */
- (void)beginFirstRunSequence:(id)sender;                   

/** Delegate for instances of this class, per <AuxilliaryViewDelegate>. */
@property (nonatomic, assign) id delegate;


@end
