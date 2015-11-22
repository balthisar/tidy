/**************************************************************************************************

	JSDStringEncodingTools

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


#pragma mark - class JSDStringEncodingTools

/**
 *  Provides methods for discovering the availability of string encodings in a localized
 *  environment, and for relating encodings' localized names to their NSStringEncoding constants
 *  and to their index position within a list in localized alphabetical sorting order.
 *
 *  These may be useful in GUI apps where, for example, you must cross-reference NSStringEncoding
 *  with the localized name and its position on a pop-up menu.
 */
@interface JSDStringEncodingTools : NSObject

/**
 *  Provides a list of all available encoding names in the localized language sorted in a localized order.
 *  The `LocalizedIndex` field of the encodings dictionaries refer to the array index of this array.
 */
+ (NSArray *)encodingNames;

/**
 *  Provides a dictionary of objects containing details about string encodings, using an `NSStringEncoding`
 *  (wrapped in an `NSNumber`) as the key. Each object is itself a dictionary with the following keys:
 *  `LocalizedName`, `LocalizedIndex`, and `NSStringEncoding`.
 */
+ (NSDictionary *)encodingsByEncoding;

/**
 *  Provides a dictionary of objects containing details about string encodings, using an integer
 *  (wrapped in an `NSNumber`) as the key. Each object is itself a dictionary with the following keys:
 *  `LocalizedName`, `LocalizedIndex`, and `NSStringEncoding`.
 */
+ (NSDictionary *)encodingsByIndex;

/**
 *  Provides a dictionary of objects containing details about string encodings, using the localized name
 *  (as an `NSString`) as the key. Each object is itself a dictionary with the following keys:
 *  `LocalizedName`, `LocalizedIndex`, and `NSStringEncoding`.
 */
+ (NSDictionary *)encodingsByName;


@end
