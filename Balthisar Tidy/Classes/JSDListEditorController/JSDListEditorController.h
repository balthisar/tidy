//
//  JSDListEditorController.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;


/**
 *  An NSViewController that handles a simple list editor similar to Xcode's
 *  configuration editor.
 */
@interface JSDListEditorController : NSViewController


#pragma mark - Initializers


/**
 * Initializes with a comma separated string.
 */
- (instancetype)initWithString:(NSString *)string;

/**
 * Initializes with an array of strings.
 */
- (instancetype)initWithArray:(NSArray<NSString*> *)array;


#pragma mark - Main Properties


/**
 * The array of NSStrings to be represented in the list.
 */
@property (readwrite, assign) NSArray<NSString*> *items;

/**
 * The array of strings represented as a comma-separated list.
 */
@property (readwrite, assign) NSString *itemsText;



#pragma mark - Public Methods


@end
