/**************************************************************************************************

	JSDTidyModel

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import "JSDTidyModelDelegate.h"

@class JSDTidyOption;


#pragma mark - class JSDTidyModel


/**
 *  **JSDTidyFramework** provides a wrapper for the [HTML Tidy project][1]’s `libtidy` for
 *  Objective-C and Cocoa. It consists of a fat wrapper geared towards GUI development.
 *
 *  In general once an instance of **JSDTidyModel** is instantiated it's easy to use.
 *
 *  - Set sourceText with untidy data.
 *  - Use tidyOptions to set the tidy options that you want.
 *  - Retrieve the Tidy'd text from tidyText.
 *
 *  In addition there is wide support for GUI applications both in **JSDTidyModel** and
 *  **JSDTidyOption**.
 *
 *  [1]: http://www.html-tidy.org
 *
 *  See also JSDTidyModelDelegate for delegate methods and **NSNotification**s.
 */
@interface JSDTidyModel : NSObject


#pragma mark - Initialization and Deallocation
/** @name Initialization and Deallocation */


/**
 *  Initializes an instance of **JSDTidyModel** with no default data. This method is the designated intializer
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 *  Initializes an instance of **JSDTidyModel** with initial source text.
 *  **JSDTidyModel** assumes that this string is already a satisfactory string with no
 *  encoding issues, and no efforts to decode the string are made.
 *  @param sourceText Initial, untidy'd source text.
 */
- (instancetype)initWithString:(NSString *)sourceText;

/**
 *  Initializes an instance of **JSDTidyModel** with initial source text, and also copies
 *  option values from another specified instance of **JSDTidyModel**.
 *  **JSDTidyModel** assumes that this string is already a satisfactory string with no
 *  encoding issues, and no efforts to decode the string are made.
 *  @param sourceText Initial, untidy'd source text.
 *  @param theModel The **JSDTidyModel** instance from which to copy option values.
 */
- (instancetype)initWithString:(NSString *)sourceText copyOptionValuesFromModel:(JSDTidyModel *)theModel;

/**
 *  Initializes an instance of **JSDTidyModel** with initial source text in an **NSData** instance.
 *  **JSDTidyModel** will use its `input-encoding` option value to decode this file, and
 *  will sanity check the decoded text.
 *
 *  If **JSDTidyModel** thinks that the specified `input-encoding` is not correct, then
 *  `tidyNotifyPossibleInputEncodingProblem` notification will be sent, and the delegate
 *  [JSDTidyModelDelegate tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:] will be called.
 *  @param data An NSData instance containing a string of the initial, untidy'd source text.
 */
- (instancetype)initWithData:(NSData *)data;

/**
 *  Initializes an instance of **JSDTidyModel** with initial source text in an **NSData** instance,
 *  and also copies option values from another specified instance of **JSDTidyModel**.
 *  **JSDTidyModel** will use its `input-encoding` option value to decode this file, and
 *  will sanity check the decoded text.
 *
 *  If **JSDTidyModel** thinks that the specified `input-encoding` is not correct, then
 *  `tidyNotifyPossibleInputEncodingProblem` notification will be sent, and the delegate
 *  [JSDTidyModelDelegate tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:] will be called.
 *  @param data An **NSData** instance containing a string of the initial, untidy'd source text.
 *  @param theModel The **JSDTidyModel** instance from which to copy option values.
 */
- (instancetype)initWithData:(NSData *)data copyOptionValuesFromModel:(JSDTidyModel *)theModel;

/**
 *  Initializes an instance of **JSDTidyModel** with initial source text from a file.
 *  **JSDTidyModel** will use its `input-encoding` option value to decode this file, and
 *  will sanity check the decoded text.
 *
 *  If **JSDTidyModel** thinks that the specified `input-encoding` is not correct, then
 *  `tidyNotifyPossibleInputEncodingProblem` notification will be sent, and the delegate
 *  [JSDTidyModelDelegate tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:] will be called.
 *  @param path The complete path to the file containing the initial, untidy'd source text.
 */
- (instancetype)initWithFile:(NSString *)path;

/**
 *  Initializes an instance of **JSDTidyModel** with initial source text from a file.
 *  **JSDTidyModel** will use its `input-encoding` option value to decode this file, and
 *  will sanity check the decoded text.
 *
 *  If **JSDTidyModel** thinks that the specified `input-encoding` is not correct, then
 *  `tidyNotifyPossibleInputEncodingProblem` notification will be sent, and the delegate
 *  [JSDTidyModelDelegate tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:] will be called.
 *  @param path The complete path to the file containing the initial, untidy'd source text.
 *  @param theModel The **JSDTidyModel** instance from which to copy option values.
 */
- (instancetype)initWithFile:(NSString *)path copyOptionValuesFromModel:(JSDTidyModel *)theModel;


#pragma mark - Delegate Support
/** @name Delegate Support */

/**
 *  Assigns the delegate for this instance of **JSDTidyModel**. Refer to JSDTidyModelDelegate to
 *  see what delegate methods (and **NSNotification**s) are used.
 */
@property (nonatomic, weak) id <JSDTidyModelDelegate> delegate;


#pragma mark - String Encoding Support
/** @name String Encoding Support */


/**
 *  A convenience method for accessing this instance's `input-encoding` Tidy option.
 */
@property (nonatomic, assign, readonly) NSStringEncoding inputEncoding;

/**
 *  A convenience method for accessing this instance's `output-encoding` Tidy option.
 */
@property (nonatomic, assign, readonly) NSStringEncoding outputEncoding;


#pragma mark - Text
/** @name Text (the important, good stuff) */


/**
 *  This is the text that Tidy will actually tidy up.
 *  **JSDTidyModel** assumes that this string is already a satisfactory string with no
 *  encoding issues, and no efforts to decode the string are made.
 */
@property (nonatomic, strong) NSString *sourceText;

/**
 *  This sets the text that Tidy will actually tidy up, encapsulated as **NSData**.
 *  **JSDTidyModel** will use its `input-encoding` option value to decode this file, and
 *  will sanity check the decoded text.
 *
 *  If **JSDTidyModel** thinks that the specified `input-encoding` is not correct, then
 *  `tidyNotifyPossibleInputEncodingProblem` notification will be sent, and the delegate
 *  [JSDTidyModelDelegate tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:] will be called.
 *  @param data The **NSData** object containing the source text string.
 */
- (void)setSourceTextWithData:(NSData *)data;

/**
 *  This sets the text that Tidy will actually tidy up, loaded from a file.
 *  **JSDTidyModel** will use its `input-encoding` option value to decode this file, and
 *  will sanity check the decoded text.
 *
 *  If **JSDTidyModel** thinks that the specified `input-encoding` is not correct, then
 *  `tidyNotifyPossibleInputEncodingProblem` notification will be sent, and the delegate
 *  [JSDTidyModelDelegate tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:] will be called.
 *  @param path Indicates the complete path to the file containing the source text.
 */
- (void)setSourceTextWithFile:(NSString *)path;

/**
 *  The result of the tidying operation.
 */
@property (nonatomic, strong, readonly) NSString *tidyText;

/**
 *  The result of the tidying operation, available as an **NSData** object, using
 *  the instance's current `output-encoding` Tidy option and the correct line endings
 *  per `newline`.
 */
@property (nonatomic, strong, readonly) NSData *tidyTextAsData;

/**
 *  Writes the result of the tidying operation to the file system, using
 *  the instance's current `output-encoding` Tidy option and the correct line endings
 *  per `newline`.
 *
 *  This method writes using native Cocoa file-writing, and not any file-writing
 *  methods from `libtidy`.
 *  @param path The complete path and filename to write.
 */
- (void)tidyTextToFile:(NSString *)path;

/**
 *  Indicates whether or not sourceText is considered "dirty", meaning that sourceText has changed,
 *  or sourceText is not equal to tidyText.
*/
@property (nonatomic, assign, readonly) BOOL isDirty;


#pragma mark - Messages
/** @name Messages */


/**
 *  Returns tidylib's error report text in traditional tidy format, directly from `libtidy`.
 *
 *  For delegate and notifications, see [JSDTidyModelDelegate tidyModelTidyMessagesChanged:messages:].
 */
@property (nonatomic, strong, readonly) NSString *errorText;

/**
 *  Makes available tidylib's error report as an **NSArray** of **JSDTidyMessage** of the errors.
 *  For backwards compatability purposes instances of JSDTidyMessage support custom keyed
 *  subscripting, so it's perfectly safe to treat instances as if they were NSDictionary.
 *
 *  For delegate and notifications, see [JSDTidyModelDelegate tidyModelTidyMessagesChanged:messages:].
 */
@property (nonatomic, strong, readonly) NSArray  *errorArray;


#pragma mark - Options Overall Management
/** @name Options Overall Management */

/**
 *  Returns the number of options built into `libtidy`.
 *  @returns Returns the number of options.
 */
+ (int)       optionsBuiltInOptionCount;

/**
 *  Returns an NSArray of NSString for all options built into Tidy.
 *  @returns Returns an NSArray of NSString for all options built into Tidy.
 */
+ (NSArray *) optionsBuiltInOptionList;

/**
 *  Sets this instance's tidyOptions from another instance.
 *  @param theModel The instance of **JSDTidyModel** from which to copy to tidyOptions.
 */
- (void)      optionsCopyValuesFromModel:(JSDTidyModel *)theModel;

/**
 *  Sets this instance's tidyOptions from an instance of **NSDictionary**. Each key must be
 *  an **NSString** with the name of a tidy option, e.g., `input-encoding`.
 *  @param theDictionary Contains they key-value pairs representing the tidy options to set.
 */
- (void)      optionsCopyValuesFromDictionary:(NSDictionary *)theDictionary;

/**
 *  Resets all of the options in tidyOptions back to `libtidy`'s built-in defaults.
 */
- (void)      optionsResetAllToBuiltInDefaults;


/**
 *  Returns a string representation of the current configuration suitable for use with
 *  command-line Tidy. It will only output the values of non-supressed options, and it
 *  will set any encoding options to UTF8 (because we can't match between `libtidy`'s
 *  options and Mac OS X' options yet).
 *
 *  It will _not_ use `libtidy`'s approach of only exporting non-default values
 *  because we can't count on other versions of Tidy using the same defaults.
 *
 *  The configuration will be pre- and append instructions taken from `Localizable.strings`,
 *  and these instructions include using the name of the eventual config file which you
 *  can specify with `baseFileName` parameter.
 *
 *  @param baseFileName Indicates the name of the file to use in the example instructions
 *  appended to the text. If not specific the non-localized value "example.cfg" will be used.
 *
 *  @returns Returns a string that can be saved to a file that is suitable for use as
 *  a command line Tidy configuration file.
 */
- (NSString *)tidyOptionsConfigFile:(NSString*)baseFileName;

/**
 *  Indicates all of the Tidy options that should be considered "in-use" by **JSDTidyModel**.
 *  Unless set the default is _all_ `libtidy` options will be used and available in methods
 *  that use Tidy options. In GUI applications it may be preferable to hide from the user
 *  redundant Tidy options (there are a few), or to hide options that you don't want the
 *  user to have control over.
 *  
 *  Note that `libtidy` will still use all of its own built-in option values if they have
 *  not been set with **JSDTidyModel**.
 */
@property (nonatomic, strong) NSArray* optionsInUse;


#pragma mark - Diagnostics and Repair
/** @name Diagnostics and Repair */


/**
 *  Echoes 'libtidy`'s version of the same, indicating the HTML version number.
 *  @returns Returns 0, 2, 3, 4, or 5 to reflect the HTML version.
 */
@property (nonatomic, assign, readonly) int tidyDetectedHtmlVersion;

/**
 *  Echoes 'libtidy`'s version of the same, indicating whether the document
 *  is XHTML.
 */
@property (nonatomic, assign, readonly) bool tidyDetectedXhtml;

/**
 *  Echoes 'libtidy`'s version of the same, indicating whether the document
 *  is generic XML.
 */
@property (nonatomic, assign, readonly) bool tidyDetectedGenericXml;

/**
 *  Echoes 'libtidy`'s version of the same, indicating the document
 *  error status.
 *  @returns Returns 0 if there are no errors, 2 for doc errors, 1 for other.
 */
@property (nonatomic, assign, readonly) int tidyStatus;

/**
 *  Echoes 'libtidy`'s version of the same, indicating the number of document errors.
 */
@property (nonatomic, assign, readonly) uint tidyErrorCount;

/**
 *  Echoes 'libtidy`'s version of the same, indicating the number of document warnings.
 */
@property (nonatomic, assign, readonly) uint tidyWarningCount;

/**
 *  Echoes 'libtidy`'s version of the same, returning the number of accessibility warnings.
 */
@property (nonatomic, assign, readonly) uint tidyAccessWarningCount;


#pragma mark - Miscelleneous
/** @name Miscelleneous */


/**
 *  Returns the `libtidy` release date.
 */
@property (nonatomic, assign, readonly) NSString *tidyReleaseDate;

/**
 *  Returns the `libtidy` semantic release version.
 */
@property (nonatomic, assign, readonly) NSString *tidyLibraryVersion;

/**
 *  Indicates whether or not the linked `libtidy` is at least the
 *  version specified by `semanticVersion`.
 *  @param semanticVersion The semantic version string against
 *    which to check.
 */
- (BOOL) tidyLibraryVersionAtLeast:(NSString *)semanticVersion;


#pragma mark - Configuration List Support
/** @name Configuration List Support */


/**
 *  Loads a list of named potential tidy options from a resourcefile,
 *  compares them to what `libtidy` supports, and returns the array
 *  containing only the names of the supported options. One might then
 *  feed this into optionsInUse.
 *
 *  @param fileName The name of the resource file to load. Because
 *   the file is only loaded from the application bundle and so no
 *   path is required.
 *  @param fileType The file extension of the resource file to load.
 *
 *  The resource file is simply a text file with tidy option names
 *  on each line.
 */
+ (NSArray *)loadOptionsInUseListFromResource:(NSString *)fileName
									   ofType:(NSString *)fileType;


#pragma mark - Mac OS X Prefs Support
/** @name Mac OS X Prefs Support */


/**
 *  Adds libtidy's default option values to the passed in **NSMutableDictionary**
 *  for ALL `libtidy` options. This is accomplished by parsing through
 *  an instance of `libtidy` and retrieving each of the built in default
 *  values and adding them to the passed-in dictionary.
 *
 *  @param defaultDictionary The dictionary to add the `libtidy` defaults to.
 */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary;

/**
 *  Similar to addDefaultsToDictionary, but only adds defaults that are
 *  specified in a resource file.
 *
 *  @param defaultDictionary The dictionary to add the `libtidy` defaults to.
 *  @param fileName The name of the resource file to load. Because
 *   the file is only loaded from the application bundle and so no
 *   path is required.
 *  @param fileType The file extension of the resource file to load.
 *
 *  The resource file is simply a text file with tidy option names
 *  on each line.
 */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
                   fromResource:(NSString *)fileName
                         ofType:(NSString *)fileType;

/**
 *  Similar to addDefaultsToDictionary, but only adds defaults that are
 *  specified in an array.
 *
 *  @param defaultDictionary The dictionary to add the `libtidy` defaults to.
 *  @param stringArray The array of `libtidy` option names.
 */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
                      fromArray:(NSArray *)stringArray;

/**
 *  Places the current option values into the specified user defaults instance.
 *
 *  @param defaults The instance of **NSUserDefaults** on which to write the
 *  current Tidy option values.
 */
- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults;

/**
 *  Sets the Tidy option values for this instance from the specified user
 *  defaults instance.
 *
 *  @param defaults The instance of **NSUserDefaults** on which to write the
 *  current Tidy option values.
 */
- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults;


#pragma mark - Tidy Options
/** @name Tidy Options */


/**
 *  Provides an NSDictionary where each key consists of a Tidy option name,
 *  e.g., @"wrap", and each corresponding value is an instance of JSDTidyOption.
 */
@property (nonatomic, strong, readonly) NSDictionary *tidyOptions;

/**
 *  Provides a KVO-compatible NSArray of JSDTidyOptions representing all of
 *  the in-use Tidy options.
 */
@property (nonatomic, strong, readonly) NSArray *tidyOptionsBindable;

@end

