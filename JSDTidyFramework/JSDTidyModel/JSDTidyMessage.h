/**************************************************************************************************
 
	JSDTidyMessage
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.
 
 **************************************************************************************************/

@import Cocoa;

#import "config.h"             // from HTML Tidy


/**
 *  **JSDTidyMessage** implements a structure for maintaining information
 *  about a single Tidy message.
 */

@interface JSDTidyMessage : NSObject


#pragma mark - Initialization
/** @name Initialization */

/**
 *  Initializes a new instance with data from a tidyReportFilter3 callback.
 *  This is the designated initialzer for the class. Given that all of the
 *  properties are read-only, this is the only practical way to create an
 *  instance.
 *  
 *  The parameter types given make it uneccessary to bridge the data
 *  provided by `libtidy`; they can be used directly.
 *
 *  @param level The TidyReportLevel of the message.
 *  @param line The line in the source text where the message occurs.
 *  @param column The column number in `line` where the message occurs.
 *  @param message The message code.
 *  @param arguments A va_list of arguments.
 */
- (instancetype) initWithLevel:(TidyReportLevel)level
						  Line:(uint)line
						Column:(uint)column
					   Message:(ctmbstr)message
					 Arguments:(va_list)arguments NS_DESIGNATED_INITIALIZER;


#pragma mark - Property Accessors
/** @name Property Accessors */


/**
 *  Indicates an image commensurate with the `level`.
 */
@property (nonatomic, assign, readonly) NSImage *levelImage;

/**
 *  Indicates the error level of the message from `libtidy`.
 */
@property (nonatomic, assign, readonly) TidyReportLevel level;

/**
 *  A localized, human-readable description for `level`.
 */
@property (nonatomic, assign, readonly) NSString *levelDescription;

/**
 *  The line number that the message applies to.
 */
@property (nonatomic, assign, readonly) uint line;

/**
 *  Represents `line` as a string.
 */
@property (nonatomic, assign, readonly) NSString *lineString;

/**
 *  The column within `line` that the message applies to.
 */
@property (nonatomic, assign, readonly) uint column;

/**
 *  Represents `column` as a string.
 */
@property (nonatomic, assign, readonly) NSString *columnString;

/**
 *  A human readable string representing the line and column
 *  that the message applies to.
 */
@property (nonatomic, strong, readonly) NSString *locationString;

/**
 *  The message text provided by `libtidy` for the error.
 */
@property (nonatomic, strong, readonly) NSString *message;

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
 *  Compares the receiver with JSDTidyMessage to determine if they
 *  are equal. They are considered equal if the line, column, and
 *  message contain the same values.
 *  @param JSDTidyMessage An instance of JSDTidyMessage to compare
 *  for equality.
 */
- (BOOL)isEqualToJSDTidyMessage:(JSDTidyMessage *)JSDTidyMessage;


/**
 *  A comparator that can be used for sorting messages based on
 *  location: line, column, and message (as a tie-breaker).
 *  @param JSDTidyMessage An instance of JSDTidyMessage to be 
 *  compared against.
 */
-(NSComparisonResult)tidyMessageLocationCompare:(JSDTidyMessage *)JSDTidyMessage;


@end
