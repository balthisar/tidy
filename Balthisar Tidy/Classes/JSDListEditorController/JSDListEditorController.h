/**************************************************************************************************

	JSDListEditorController

	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;
@import Foundation;


/** 
 *  An NSViewController that handles a simple list editor similar to Xcode's
 *  configuration editor.
 */
@interface JSDListEditorController : NSViewController


#pragma mark - Initializers
/** @name Initializers */


/**
 * Initializes with a comma separated string.
 */
- (instancetype)initWithString:(NSString *)string;

/**
 * Initializes with an array of strings.
 */
- (instancetype)initWithArray:(NSArray<NSString*> *)array;


#pragma mark - Main Properties
/** @name Main Properties */


/**
 * The array of NSStrings to be represented in the list.
 */
@property (readwrite, assign) NSArray<NSString*> *items;

/**
 * The array of strings represented as a comma-separated list.
 */
@property (readwrite, assign) NSString *itemsText;



#pragma mark - Public Methods
/** @name Public Methods */


@end
