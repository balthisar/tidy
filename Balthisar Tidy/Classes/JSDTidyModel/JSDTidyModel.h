/**************************************************************************************************

	JSDTidyModel.h

	JSDTidyModel acts as a model to provide Tidy services to a cocoa application.
	

	The MIT License (MIT)

	Copyright (c) 2001 to 2014 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import <Foundation/Foundation.h>
#import "tidy.h"
#import "tidyenum.h"
#import "buffio.h"
#import "config.h"

@class JSDTidyOption;
@class JSDTidyModel;


#pragma mark - Some defines


/*
	This is the main key in the implementing application's prefs file
	under which all of the TidyLib options will be written. You might
	change this if your application uses Cocoa's native preferences
	system.
 */
#define JSDKeyTidyTidyOptionsKey @"JSDTidyTidyOptions"

/*
	The default encoding styles that override the TidyLib-implemented
	character encodings. These are present in the header in case you
	want to provide your own defaults.
*/

#define tidyDefaultInputEncoding	NSUTF8StringEncoding
#define tidyDefaultOutputEncoding	NSUTF8StringEncoding


/*
	TidyLib will post the following NSNotifications.
*/

#define tidyNotifyOptionChanged					@"JSDTidyDocumentOptionChanged"
#define tidyNotifySourceTextChanged				@"JSDTidyDocumentSourceTextChanged"
#define tidyNotifyTidyTextChanged				@"JSDTidyDocumentTidyTextChanged"
#define tidyNotifyTidyErrorsChanged				@"JSDTidyDocumentTidyErrorsChanged"
#define tidyNotifyPossibleInputEncodingProblem	@"JSDTidyNotifyPossibleInputEncodingProblem"


#pragma mark - protocol JSDTidyModelDelegate

/**
 Tidy supports GUI
 */
@protocol JSDTidyModelDelegate <NSObject>

@optional

- (void)tidyModelOptionChanged:(JSDTidyModel *)tidyModel option:(JSDTidyOption *)tidyOption;

- (void)tidyModelSourceTextChanged:(JSDTidyModel *)tidyModel text:(NSString *)text;

- (void)tidyModelTidyTextChanged:(JSDTidyModel *)tidyModel text:(NSString *)text;

- (void)tidyModelTidyMessagesChanged:(JSDTidyModel *)tidyModel messages:(NSArray *)messages;

- (void)tidyModelDetectedInputEncodingIssue:(JSDTidyModel *)tidyModel
							currentEncoding:(NSStringEncoding)currentEncoding
						  suggestedEncoding:(NSStringEncoding)suggestedEncoding;

@end




#pragma mark - class JSDTidyModel

/**
	JSDTidyModel is a nice, Mac OS X wrapper for TidyLib. It uses instances
	JSDTidyOption to contain TidyOptions. The model works with every built-
	in TidyOption, although applications can suppress multiple individual
	TidyOptions if desired.
 */
@interface JSDTidyModel : NSObject


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	INITIALIZATION and DEALLOCATION
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

- (id)init;			///< Standard init.

/**
	The convenience initializers assume that strings and data
	are already processed to NSString standard. File-based intializers
	will try to convert to NSString standard using the default tidy
	option `input-encoding`.
	
	Given original text in these initalizers, the working text will
	be generated immediately.
*/
- (id)initWithString:(NSString *)value;

- (id)initWithString:(NSString *)value copyOptionsFromModel:(JSDTidyModel *)theModel;		///< @copydoc initWithString:

- (id)initWithData:(NSData *)data;															///< @copydoc initWithString:

- (id)initWithData:(NSData *)data copyOptionsFromModel:(JSDTidyModel *)theModel;			///< @copydoc initWithString:

- (id)initWithFile:(NSString *)path;														///< @copydoc initWithString:

- (id)initWithFile:(NSString *)path copyOptionsFromModel:(JSDTidyModel *)theModel;			///< @copydoc initWithString:


#pragma mark - Delegate Support


@property (nonatomic, weak) id <JSDTidyModelDelegate> delegate;											///< delegate for implementors.


#pragma mark - String Encoding Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	ENCODING SUPPORT
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/**
	These class methods return convenience collections that
	might be useful in implementing a user interface for the
	encoding support of JSDTidyModel. The dictionaries all
	return dictionaries with potentially useful information.

	The simple array is a list of all available encoding names
	in the localized language sorted in a localized manner.
 
	The dictionaries are dictionaries of the same data differing
	only by the key. They all contain `NSStringEncoding`,
	`LocalizedIndex`, and `LocalizedName`.
*/
+ (NSArray *)allAvailableEncodingLocalizedNames;

+ (NSDictionary *)availableEncodingDictionariesByLocalizedName;		///< @copydoc allAvailableEncodingLocalizedNames

+ (NSDictionary *)availableEncodingDictionariesByNSStringEncoding;	///< @copydoc allAvailableEncodingLocalizedNames

+ (NSDictionary *)availableEncodingDictionariesByLocalizedIndex;	///< @copydoc allAvailableEncodingLocalizedNames


@property (readonly, nonatomic) NSStringEncoding inputEncoding;		///< Convenience shortcut for reading current input-encoding

@property (readonly, nonatomic) NSStringEncoding outputEncoding;	///< Convenience shortcut for reading current output-encoding


#pragma mark - TidyOptions


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	TIDYOPTIONS
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/**
	The `tidyOptions` structure is a dictionary of keys=>tidyOption,
	where the key is the built-in TidyOption name, and tidyOption is
	an instance of tidyOption for that key.
 */
@property (strong, readonly, nonatomic) NSDictionary *tidyOptions;


/** Support for KVC access to the TidyOptions and main properties. */
- (id)objectForKeyedSubscript:(id <NSCopying>)key;


/** Support for KVC access to the TidyOptions and main properties. */
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;


#pragma mark - Text


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	TEXT - the important, good stuff.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/**
	sourceText -- this is the text that Tidy will actually tidy up.
	The non-string set methods decode using the current encoding
	setting in `input-encoding`.
 */

@property (strong, nonatomic) NSString *sourceText;

- (void)setSourceTextWithData:(NSData *)data;		///< @copydoc sourceText

- (void)setSourceTextWithFile:(NSString *)path;		///< @copydoc sourceText


/**
	tidyText -- this is the text that Tidy generates from the
	workingText. Note that these are read-only.
*/

@property (readonly, strong, nonatomic) NSString *tidyText;

@property (readonly, weak, nonatomic) NSData *tidyTextAsData;	///< @copydoc tidyText

- (void)tidyTextToFile:(NSString *)path;						///< @copydoc tidyText


/**
	isDirty - indicates that the source text is considered "dirty",
	meaning that the source-text has changed, or the source-text
	is not equal to the tidy'd-text.
*/

@property (readonly, nonatomic) BOOL isDirty;


#pragma mark - Errors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	ERRORS reported by tidy
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

@property (readonly, strong, nonatomic) NSString *errorText;			///< Return the error text in traditional tidy format.

@property (readonly, strong, nonatomic) NSArray  *errorArray;			///< Error text as an array of |NSDictionary| of the errors.


#pragma mark - Options management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	OPTIONS - methods for dealing with options
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

+ (void)		optionsBuiltInDumpDocsToConsole;							///< dumps all TidyLib descriptions to error console.

+ (int)			optionsBuiltInOptionCount;									///< returns the number of options built into Tidy.

+ (NSArray *)	optionsBuiltInOptionList;									///< returns an NSArray of NSString for all options built into Tidy.


- (void)		optionsCopyFromModel:(JSDTidyModel *)theModel;				///< sets options based on those in theDocument.

- (void)		optionsCopyFromDictionary:(NSDictionary *)theDictionary;	///< sets options from values in a dictionary.

- (void)		optionsResetAllToBuiltInDefaults;							///< resets all options to factory default

@property (nonatomic) NSArray* optionsInEffect;								///< default is all option; otherwise is list of options.


#pragma mark - Diagnostics and Repair


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	DIAGNOSTICS and REPAIR
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

@property (readonly, nonatomic) int tidyDetectedHtmlVersion;	///< Returns 0, 2, 3, 4, or 5.

@property (readonly, nonatomic) bool tidyDetectedXhtml;			///< Indicates whether the document is XHTML.

@property (readonly, nonatomic) bool tidyDetectedGenericXml;	///< Indicates if the document is generic XML.

@property (readonly, nonatomic) int tidyStatus;					///< Returns 0 if there are no errors, 2 for doc errors, 1 for other.

@property (readonly, nonatomic) uint tidyErrorCount;			///< Returns number of document errors.

@property (readonly, nonatomic) uint tidyWarningCount;			///< Returns number of document warnings.

@property (readonly, nonatomic) uint tidyAccessWarningCount;	///< Returns number of document accessibility warnings.


#pragma mark - Miscelleneous


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	MISCELLENEOUS - misc. Tidy methods supported
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

// TODO: These can all be properties.

@property (readonly, nonatomic) NSString *tidyReleaseDate;		///< returns the TidyLib release date


#pragma mark - Configuration List Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	SUPPORTED CONFIG LIST SUPPORT
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

+ (NSArray *)loadConfigurationListFromResource:(NSString *)fileName ofType:(NSString *)fileType;	///< get list of config options.


#pragma mark - Mac OS X Prefs Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	MAC OS PREFS SUPPORT
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/** Puts *all* TidyLib defaults values into a dictionary. */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary;

/** Puts only the TidyLib defaults specified in a resource file into a dictionary. */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
				   fromResource:(NSString *)fileName
						 ofType:(NSString *)fileType;

/** Puts only the TidyLib defaults specified in an array of strings into a dictionary. */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
					  fromArray:(NSArray *)stringArray;


- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults;			///< write the values right into prefs.

- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults;			///< take config from passed-in defaults.


@end

