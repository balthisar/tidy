//
//  JSDTidyModel.h
//  JSSDTidyFramework
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//
//  `JSDTidyFramework` provides a wrapper for the [HTML Tidy project][1]’s
//  `libtidy` for Objective-C and Cocoa. It consists of a fat wrapper geared
//  towards GUI development.
//
//    [1]: http://www.html-tidy.org
//

@import Cocoa;

#import <JSDTidyFramework/JSDTidyModelDelegate.h>

@class JSDTidyOption;


#pragma mark - class JSDTidyModel


/**
 *  @c JSDTidyModel provides HTML Tidy service to an application via different
 *  text interfaces.
 *
 *  In general, once an instance of @c JSDTidyModel is instantiated it's easy
 *  to use:
 *
 *  @li - Set @c sourceText with untidy data.
 *  @li - Use @c tidyOptions to set the tidy options that you want.
 *  @li - Retrieve the Tidy'd text from @c tidyText.
 *
 *  In addition there is wide support for GUI applications both in
 *  @c JSDTidyModel and @c JSDTidyOption.
 *
 *  @remarks
 *  See Also @c JSDTidyModelDelegate for delegate methods and any
 *  @c NSNotification's that apply.
 *
 */
@interface JSDTidyModel : NSObject


#pragma mark - Initialization and Deallocation


/**
 *  Initializes an instance of @c JSDTidyModel with no default data. This
 *  method is the designated intializer.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 *  Initializes an instance of @c JSDTidyModel with initial source text.
 *
 *  @c JSDTidyModel assumes that this string is already a satisfactory string
 *  with no encoding issues, and no efforts to decode the string are made.
 *
 *  @param sourceText Initial, untidy'd source text.
 */
- (instancetype)initWithString:(NSString *)sourceText;

/**
 *  Initializes an instance of @c JSDTidyModel with initial source text, and
 *  also copies option values from another specified instance of
 *  @c JSDTidyModel.
 *
 *  @c JSDTidyModel assumes that this string is already a satisfactory string
 *  with no encoding issues, and no efforts to decode the string are made.
 *
 *  @param sourceText Initial, untidy'd source text.
 *  @param theModel The @c JSDTidyModel instance from which to copy option
 *    values.
 */
- (instancetype)initWithString:(NSString *)sourceText
	 copyOptionValuesFromModel:(JSDTidyModel *)theModel;

/**
 *  Initializes an instance of @C JSDTidyModel with initial source text in
 *  an @c NSData instance.
 *
 *  @c JSDTidyModel will use its @b input-encoding option value to decode
 *  this file, and will sanity check the decoded text.
 *
 *  If @c JSDTidyModel thinks that the specified @b input-encoding is not
 *  correct, then @c tidyNotifyPossibleInputEncodingProblem notification
 *  will be sent, and the delegate
 *  @c [JSDTidyModelDelegate @c tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:]
 *  message will be sent.
 *
 *  @param data An NSData instance containing a string of the initial,
 *    untidy'd source text.
 */
- (instancetype)initWithData:(NSData *)data;

/**
 *  Initializes an instance of @c JSDTidyModel with initial source text in
 *  an @c NSData instance, and also copies option values from another specified
 *  instance of @c JSDTidyModel.
 *
 *  @c JSDTidyModel will use its @b input-encoding option value to decode
 *  this file, and will sanity check the decoded text.
 *
 *  If @c JSDTidyModel thinks that the specified @b input-encoding is not
 *  correct, then @c tidyNotifyPossibleInputEncodingProblem notification
 *  will be sent, and the delegate
 *   @c [JSDTidyModelDelegate @c tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:]
 *  message will be sent.
 *
 *  @param data An @c NSData instance containing a string of the initial,
 *    untidy'd source text.
 *  @param theModel The @c JSDTidyModel instance from which to copy option
 *    values.
 */
- (instancetype)initWithData:(NSData *)data copyOptionValuesFromModel:(JSDTidyModel *)theModel;

/**
 *  Initializes an instance of @c JSDTidyModel with initial source text from
 *  a file. @c JSDTidyModel will use its @b input-encoding option value to
 *  decode this file, and will sanity check the decoded text.
 *
 *  If @c JSDTidyModel thinks that the specified @b input-encoding is not
 *  correct, then @c tidyNotifyPossibleInputEncodingProblem notification
 *  will be sent, and the delegate
 *  @c [JSDTidyModelDelegate @c tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:]
 *  message will be sent.
 *
 *  @param path The complete path to the file containing the initial, untidy'd
 *    source text.
 */
- (instancetype)initWithFile:(NSString *)path;

/**
 *  Initializes an instance of @c JSDTidyModel with initial source text from
 *  a file. @c JSDTidyModel will use its @b input-encoding option value to
 *  decode this file, and will sanity check the decoded text.
 *
 *  If @c JSDTidyModel thinks that the specified @b input-encoding is not
 *  correct, then @c tidyNotifyPossibleInputEncodingProblem notification
 *  will be sent, and the delegate
 *  @c [JSDTidyModelDelegate @c tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:]
 *  message will be sent.
 *
 *  @param path The complete path to the file containing the initial,
 *    untidy'd source text.
 *  @param theModel The @c JSDTidyModel instance from which to copy option
 *    values.
 */
- (instancetype)initWithFile:(NSString *)path copyOptionValuesFromModel:(JSDTidyModel *)theModel;


#pragma mark - Delegate Support


/**
 *  Assigns the delegate for this instance of @c JSDTidyModel. Refer to
 *  @c JSDTidyModelDelegate to see what delegate methods (and
 *  @c NSNotification) are used.
 */
@property (nonatomic, weak) id <JSDTidyModelDelegate> delegate;


#pragma mark - String Encoding Support


/**
 *  A convenience method for accessing this instance's @b input-encoding
 *  Tidy option.
 */
@property (nonatomic, assign, readonly) NSStringEncoding inputEncoding;

/**
 *  A convenience method for accessing this instance's @c output-encoding
 *  Tidy option.
 */
@property (nonatomic, assign, readonly) NSStringEncoding outputEncoding;


#pragma mark - Text


/**
 *  This is the text that Tidy will actually tidy up.
 *
 *  @c JSDTidyModel assumes that this string is already a satisfactory string
 *  with no encoding issues, and no efforts to decode the string are made.
 */
@property (nonatomic, strong) NSString *sourceText;

/**
 *  The source text, as UTF8-encoded data. This is a read-only property
 *  provided as a convenience. Use @c setSourceTextWithData to set the
 *  source text.
 */
@property (nonatomic, assign, readonly) NSData *sourceTextAsData;

/**
 *  This sets the text that Tidy will actually tidy up, encapsulated as
 *  @c NSData. @c JSDTidyModel will use its @b input-encoding option value
 *  to decode this file, and will sanity check the decoded text.
 *
 *  If @c JSDTidyModel thinks that the specified @b input-encoding is not
 *  correct, then @c tidyNotifyPossibleInputEncodingProblem notification
 *  will be sent, and the delegate
 *  @c [JSDTidyModelDelegate @c tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:]
 *  message will be sent.
 *
 *  @param data The @c NSData object containing the source text string.
 */
- (void)setSourceTextWithData:(NSData *)data;

/**
 *  This sets the text that Tidy will actually tidy up, loaded from a file.
 *  @c JSDTidyModel will use its @b input-encoding option value to decode
 *  this file, and will sanity check the decoded text.
 *
 *  If @c JSDTidyModel thinks that the specified @b input-encoding is not
 *  correct, then @c tidyNotifyPossibleInputEncodingProblem notification
 *  will be sent, and the delegate
 *  @c [JSDTidyModelDelegate @c tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:]
 *  message will be sent.
 *
 *  @param path Indicates the complete path to the file containing the
 *    source text.
 */
- (void)setSourceTextWithFile:(NSString *)path;

/**
 *  The result of the tidying operation.
 */
@property (nonatomic, strong, readonly) NSString *tidyText;

/**
 *  The result of the tidying operation, available as an @c NSData object,
 *  using the instance's current @b output-encoding Tidy option and the
 *  correct line endings per the @b newline Tidy option.
 */
@property (nonatomic, strong, readonly) NSData *tidyTextAsData;

/**
 *  Writes the result of the tidying operation to the file system, using
 *  the instance's current @b output-encoding Tidy option and the correct
 *  line endings per @b newline.
 *
 *  This method writes using native Cocoa file-writing, and not any
 *  file-writing methods from @b libtidy.
 *
 *  @param path The complete path and filename to write.
 */
- (void)tidyTextToFile:(NSString *)path;

/**
 *  Indicates whether or not @c sourceText is considered "dirty," meaning
 *  that @c sourceText has changed, or @c sourceText is not equal to
 *  @c tidyText.
*/
@property (nonatomic, assign, readonly) BOOL isDirty;


#pragma mark - Messages


/**
 *  Returns @b libtidy's error report text in traditional tidy format,
 *  directly from @b libtidy.
 *
 *  For delegate and notifications, see
 *  @c [JSDTidyModelDelegate @c tidyModelTidyMessagesChanged:messages:].
 */
@property (nonatomic, strong, readonly) NSString *errorText;

/**
 *  Makes available @b libtidy's error report as an @c NSArray of
 *  @c JSDTidyMessage of the errors.
 *
 *  For backwards compatability purposes instances of @c JSDTidyMessage
 *  support custom keyed subscripting, so it's perfectly safe to treat
 *  instances as if they were @c NSDictionary.
 *
 *  For delegate and notifications, see
 *  @c [JSDTidyModelDelegate @c tidyModelTidyMessagesChanged:messages:].
 */
@property (nonatomic, strong, readonly) NSArray  *errorArray;


#pragma mark - Options Overall Management

/**
 *  Returns the number of options built into @b libtidy.
 *
 *  @returns Returns the number of options.
 */
+ (int)       optionsBuiltInOptionCount;

/**
 *  Returns an @c NSArray of @c NSString for all options built into Tidy.
 *
 *  @returns Returns an NSArray of NSString for all options built into Tidy.
 */
+ (NSArray *) optionsBuiltInOptionList;

/**
 *  Sets this instance's @c tidyOptions from another instance.
 *
 *  @param theModel The instance of @c JSDTidyModel from which to copy to
 *    @c tidyOptions.
 */
- (void)      optionsCopyValuesFromModel:(JSDTidyModel *)theModel;

/**
 *  Sets this instance's @c tidyOptions from an instance of @c NSDictionary.
 *  Each key must be an @c NSString with the name of a tidy option,
 *  e.g., @b input-encoding.
 *
 *  @param theDictionary Contains they key-value pairs representing the tidy
 *    options to set.
 */
- (void)      optionsCopyValuesFromDictionary:(NSDictionary *)theDictionary;

/**
 *  Resets all of the options in @c tidyOptions back to @b libtidy's
 *  built-in defaults.
 */
- (void)      optionsResetAllToBuiltInDefaults;

/**
 *  Sets the current Tidy options from a Tidy configuration file.
 *
 *  @c JSDTidyModel follows the behavior of HTML Tidy; items in a configuration
 *  file only specify settings to change versus the default settings, and so
 *  options that are not specified in the configuration file will be set to
 *  factory default values.
 *
 *  @param fileURL The @c NSURL of the file to load.
 *  @returns Returns @c YES on success or @c NO on failure.
 */
- (BOOL)optionsTidyLoadConfig:(NSURL *)fileURL;

/**
 *  Returns a string representation of the current configuration suitable for
 *  use with command-line Tidy. It will only output the values of non-supressed
 *  options, and it will set any encoding options to UTF8 (because we can't
 *  match between @b libtidy's options and macOS' options yet).
 *
 *  It will @a not use @b libtidy's approach of only exporting non-default
 *  values because we can't count on other versions of Tidy using the same
 *  defaults.
 *
 *  The configuration will be pre- and append instructions taken from
 *  @c Localizable.strings, and these instructions include using the name of
 *  the eventual config file which you can specify with @c baseFileName
 *  parameter.
 *
 *  @param baseFileName Indicates the name of the file to use in the example
 *    instructions appended to the text. If not specific the non-localized
 *    value "example.cfg" will be used.
 *  @returns Returns a string that can be saved to a file that is suitable
 *    for use as a command line Tidy configuration file.
 */
- (NSString *)tidyOptionsConfigFile:(NSString*)baseFileName;

/**
 *  Indicates all of the Tidy options that should be considered "in-use" by
 *  @c JSDTidyModel.
 *
 *  Unless set, the default is that @a all @b libtidy options will be used and
 *  available in methods that use Tidy options. In GUI applications it may be
 *  preferable to hide from the user redundant Tidy options (there are a few),
 *  or to hide options that you don't want the user to have control over.
 *
 *  Note that @b libtidy will still use all of its own built-in option values
 *  if they have not been set with @c JSDTidyModel.
 */
@property (nonatomic, strong) NSArray* optionsInUse;


#pragma mark - Diagnostics and Repair


/**
 *  Echoes @b libtidy's version of the same, indicating the HTML version number.
 *
 *  Value is 0, 2, 3, 4, or 5 to reflect the HTML version.
 */
@property (nonatomic, assign, readonly) int tidyDetectedHtmlVersion;

/**
 *  Echoes @b libtidy's version of the same, indicating whether the document
 *  is XHTML.
 */
@property (nonatomic, assign, readonly) bool tidyDetectedXhtml;

/**
 *  Echoes @b libtidy's version of the same, indicating whether the document
 *  is generic XML.
 */
@property (nonatomic, assign, readonly) bool tidyDetectedGenericXml;

/**
 *  Echoes @b libtidy's version of the same, indicating the document
 *  error status.
 *
 *  The value is 0 if there are no errors, 2 for doc errors, 1 for other.
 */
@property (nonatomic, assign, readonly) int tidyStatus;

/**
 *  Echoes @b libtidy's version of the same, indicating the number of
 *  document errors.
 */
@property (nonatomic, assign, readonly) uint tidyErrorCount;

/**
 *  Echoes @b libtidy's version of the same, indicating the number of
 *  document warnings.
 */
@property (nonatomic, assign, readonly) uint tidyWarningCount;

/**
 *  Echoes @b libtidy's version of the same, returning the number of
 *  accessibility warnings.
 */
@property (nonatomic, assign, readonly) uint tidyAccessWarningCount;


#pragma mark - Miscelleneous


/**
 *  Returns the @b libtidy release date.
 */
@property (nonatomic, assign, readonly) NSString *tidyReleaseDate;

/**
 *  Returns the @b libtidy semantic release version.
 */
@property (nonatomic, assign, readonly) NSString *tidyLibraryVersion;

/**
 *  Indicates whether or not the linked @b libtidy is at least the
 *  version specified by @c semanticVersion.
 *
 *  @param semanticVersion The semantic version string against
 *    which to check.
 */
- (BOOL) tidyLibraryVersionAtLeast:(NSString *)semanticVersion;


#pragma mark - Configuration List Support


/**
 *  Loads a list of named potential tidy options from a resource file,
 *  compares them to what @b libtidy supports, and returns the array
 *  containing only the names of the supported options. One might then
 *  feed this into @c optionsInUse.
 *
 *  The resource file is simply a text file with tidy option names
 *  on each line.

 *  @param fileName The name of the resource file to load. Because
 *    the file is only loaded from the application bundle, no
 *    path is required.
 *  @param fileType The file extension of the resource file to load.
 *
 */
+ (NSArray *)loadOptionsInUseListFromResource:(NSString *)fileName
                                       ofType:(NSString *)fileType;


#pragma mark - macOS Prefs Support


/**
 *  Adds libtidy's default option values to the passed-in
 *  @c NSMutableDictionary for ALL @b libtidy options. This is accomplished
 *  by parsing through an instance of @b libtidy and retrieving each of the
 *  built in default values and adding them to the passed-in dictionary.
 *
 *  @param defaultDictionary The dictionary to add the @b libtidy defaults to.
 */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary;

/**
 *  Similar to @c addDefaultsToDictionary, but only adds defaults that are
 *  specified in a resource file.
 *
 *  @param defaultDictionary The dictionary to add the @b libtidy defaults to.
 *  @param fileName The name of the resource file to load. Because
 *    the file is only loaded from the application bundle and so no
 *    path is required.
 *  @param fileType The file extension of the resource file to load.
 *
 *  The resource file is simply a text file with tidy option names
 *  on each line.
 */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
                   fromResource:(NSString *)fileName
                         ofType:(NSString *)fileType;

/**
 *  Similar to @c addDefaultsToDictionary, but only adds defaults that are
 *  specified in an array.
 *
 *  @param defaultDictionary The dictionary to add the @b libtidy defaults to.
 *  @param stringArray The array of @b libtidy option names.
 */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
                      fromArray:(NSArray *)stringArray;

/**
 *  Places the current option values into the specified user defaults instance.
 *
 *  @param defaults The instance of @c NSUserDefaults on which to write the
 *  current Tidy option values.
 */
- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults;

/**
 *  Sets the Tidy option values for this instance from the specified user
 *  defaults instance.
 *
 *  @param defaults The instance of @c NSUserDefaults on which to write the
 *    current Tidy option values.
 */
- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults;


#pragma mark - Tidy Options


/**
 *  Provides an @c NSDictionary where each key consists of a Tidy option name,
 *  e.g., @"wrap", and each corresponding value is an instance of
 *  @c JSDTidyOption.
 */
@property (nonatomic, strong, readonly) NSDictionary *tidyOptions;

/**
 *  Provides a KVO-compatible @c NSArray of @c JSDTidyOptions representing
 *  all of the in-use Tidy options.
 */
@property (nonatomic, strong, readonly) NSArray *tidyOptionsBindable;

@end
