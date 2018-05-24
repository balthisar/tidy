/**************************************************************************************************

    JSDNuVMessage

    Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/** Gives a typeID to the major message types, in order of severity. */
typedef NS_OPTIONS(NSUInteger, JSDNuVMessageTypes) {
	JSDNuVNone   = 0,
	JSDNuVNonDoc = 1,
	JSDNuVInfo   = 2,
	JSDNuVError  = 4,
};


/**
 *  **JSDNuVMessage** implements a structure for maintaining information
 *  about a single validator message.
 */

@interface JSDNuVMessage : NSObject


#pragma mark - Initialization
/** @name Initialization */

/**
 *  Create an array of JSDValidatorMessage given a validator-native dictionary.
 */
+ (NSArray<JSDNuVMessage*>*) messageArrayFromResponseObject:(NSDictionary *)responseObject;


/**
 *  Initializes a new instance with data from the validator response data.
 *  This is the designated initialzer for the class. Given that all of the
 *  properties are read-only, this is the only practical way to create an
 *  instance.
 *
 *  @param dict The TidyReportLevel of the message.
 */
- (instancetype) initWithDictionary:(NSDictionary *)dict;


#pragma mark - Property Accessors
/** @name Property Accessors */


/**
 *  The original dictionary entry.
 */
@property (nonatomic, strong, readonly) NSDictionary *dictionary;


/**
 *  Indicates an image commensurate with the `type`:`subtype`.
 */
@property (nonatomic, assign, readonly) NSImage *typeImage;


/**
 *  Indicates the type of message from the validator.
 */
@property (nonatomic, assign, readonly) JSDNuVMessageTypes typeID;


/**
 *  Indicates the type of message from the validator.
 */
@property (nonatomic, strong, readonly) NSString *type;


/**
 *  Indicates the subtype of message from the validtor, if present.
 *  - info: warning
 *  - error: fatal
 *  - non-document-error: io, schema, internal
 */
@property (nonatomic, strong, readonly) NSString *subtype;


/**
 *  Specifies the localized string representing the type-subtype combinations
 *  available.
 */
@property (nonatomic, assign, readonly) NSString *typeLocalized;


/**
 *  The message provided by the validator.
 */
@property (nonatomic, strong, readonly) NSString *message;


/**
 *  The localized message provided by the validator. This probably doesn’t
 *  work completely because we don’t use the validator’s source code.
 */
@property (nonatomic, assign, readonly) NSString *messageLocalized;


/**
 *  The extract provided by the validator.
 */
@property (nonatomic, strong, readonly) NSString *extract;


/**
 *  The url provided by the validator.
 */
@property (nonatomic, strong, readonly) NSString *url;


/**
 *  The offset provided by the validator.
 */
@property (nonatomic, assign, readonly) uint offset;


/**
 *  The firstLine provided by the validator.
 */
@property (nonatomic, assign, readonly) uint firstLine;


/**
 *  The firstColumn provided by the validator.
 */
@property (nonatomic, assign, readonly) uint firstColumn;


/**
 *  The lastLine provided by the validator.
 */
@property (nonatomic, assign, readonly) uint lastLine;


/**
 *  The lastColumn provided by the validator.
 */
@property (nonatomic, assign, readonly) uint lastColumn;


/**
 *  The hiliteStart provided by the validator.
 */
@property (nonatomic, assign, readonly) uint hiliteStart;


/**
 *  The hiliteLength provided by the validator.
 */
@property (nonatomic, assign, readonly) uint hiliteLength;


/**
 *  The startLine as a localized string.
 */
@property (nonatomic, strong, readonly) NSString *lineString;


/**
 *  The startColumn as a localized string.
 */
@property (nonatomic, strong, readonly) NSString *columnString;


/**
 *  The location, localized with row and column.
 */
@property (nonatomic, strong, readonly) NSString *locationString;


/**
 *  This property can be used to specify a sort order against
 *  the line number, column number, and localized description
 *  of a particular message.
 *
 *  It's suggested to use the custom comparitor instead.
 */
@property (nonatomic, strong, readonly) NSString *sortKey;


#pragma mark - Instance Methods
/** @name Instance Methods */


/**
 *  Compares the receiver with JSDValidatorMessage to determine if they
 *  are equal. They are considered equal if the lines, columns, and
 *  message contain the same values.
 *  @param message An instance of JSDValidatorMessage to compare
 *  for equality.
 */
- (BOOL)isEqualToJSDValidatorMessage:(JSDNuVMessage *)message;


/**
 *  A comparator that can be used for sorting messages based on
 *  location: lines, columns, and message (as a tie-breaker).
 *  @param message An instance of JSDValidatorMessage to be
 *  compared against.
 */
-(NSComparisonResult)validatorMessageLocationCompare:(JSDNuVMessage *)message;


@end

