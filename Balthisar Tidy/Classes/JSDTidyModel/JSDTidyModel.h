/**************************************************************************************************

	JSDTidyModel

	JSDTidyModel is a nice, Mac OS X wrapper for TidyLib. It uses instances of JSDTidyOption
	to contain TidyOptions. The model works with every built-in	TidyOption, although applications
	can suppress multiple individual TidyOptions if desired.
	

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
#import "JSDTidyModelDelegate.h"

@class JSDTidyOption;


#pragma mark - Definitions

/*
	This is the main key in the implementing application's prefs file
	under which all of the TidyLib options will be written. You might
	change this if your application uses Cocoa's native preferences
	system.
*/

#define JSDKeyTidyTidyOptionsKey @"JSDTidyTidyOptions"


#pragma mark - class JSDTidyModel


@interface JSDTidyModel : NSObject


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	INITIALIZATION and DEALLOCATION
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

- (instancetype)init;

/*
	The convenience initializers assume that strings and data
	are already processed to NSString standard. File-based intializers
	will try to convert to NSString standard using the default tidy
	option `input-encoding`.
	
	Given original text in these initalizers, the working text will
	be generated immediately.
*/

- (instancetype)initWithString:(NSString *)value;

- (instancetype)initWithString:(NSString *)value copyOptionValuesFromModel:(JSDTidyModel *)theModel;

- (instancetype)initWithData:(NSData *)data;														

- (instancetype)initWithData:(NSData *)data copyOptionValuesFromModel:(JSDTidyModel *)theModel;

- (instancetype)initWithFile:(NSString *)path;														

- (instancetype)initWithFile:(NSString *)path copyOptionValuesFromModel:(JSDTidyModel *)theModel;


#pragma mark - Delegate Support


@property (weak) id <JSDTidyModelDelegate> delegate;


#pragma mark - String Encoding Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	ENCODING SUPPORT
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/*
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

+ (NSDictionary *)availableEncodingDictionariesByLocalizedName;

+ (NSDictionary *)availableEncodingDictionariesByNSStringEncoding;

+ (NSDictionary *)availableEncodingDictionariesByLocalizedIndex;


/*
	These convenience properties are just shortcuts for reading the
	current input-encoding and output-encoding for this instance.
 */

@property (readonly) NSStringEncoding inputEncoding;		

@property (readonly) NSStringEncoding outputEncoding;


#pragma mark - Text


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	TEXT - the important, good stuff.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/*
	sourceText -- this is the text that Tidy will actually tidy up.
	The non-string set methods decode using the current encoding
	setting in `input-encoding`.
 */

@property NSString *sourceText;

- (void)setSourceTextWithData:(NSData *)data;

- (void)setSourceTextWithFile:(NSString *)path;


/*
	tidyText -- this is the text that Tidy generates from the
	sourceText. Note that these are read-only.
	The non-string set methods decode using the current encoding
	setting in `output-encoding`.
*/

@property (readonly) NSString *tidyText;

@property (readonly) NSData *tidyTextAsData;

- (void)tidyTextToFile:(NSString *)path;


/*
	isDirty - indicates that the source text is considered "dirty",
	meaning that the source-text has changed, or the source-text
	is not equal to the tidy'd-text.
*/

@property (readonly) BOOL isDirty;


#pragma mark - Errors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	MESSAGES reported by tidy
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

@property (readonly) NSString *errorText;      // Return the error text in traditional tidy format.

@property (readonly) NSArray  *errorArray;     // Message text as an array of NSDictionary of the errors.


#pragma mark - Options Overall management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	OPTIONS - methods for dealing with options overall
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

+ (void)      optionsBuiltInDumpDocsToConsole;     // Dumps all TidyLib descriptions to error console.

+ (int)       optionsBuiltInOptionCount;           // Returns the number of options built into Tidy.

+ (NSArray *) optionsBuiltInOptionList;            // Returns an NSArray of NSString for all options built into Tidy.

- (void)      optionsCopyValuesFromModel:(JSDTidyModel *)theModel;            // Sets options based on those in theModel.

- (void)      optionsCopyValuesFromDictionary:(NSDictionary *)theDictionary;  // Sets options from values in a dictionary.

- (void)      optionsResetAllToBuiltInDefaults;							      // Resets all options to factory default.

- (NSString *)tidyOptionsConfigFile:(NSString*)baseFileName;                  // Returns a string of current config.

@property NSArray* optionsInUse;                   // Default is all options; otherwise is list of options.


#pragma mark - Diagnostics and Repair


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	DIAGNOSTICS and REPAIR
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

@property (readonly) int tidyDetectedHtmlVersion;   // Returns 0, 2, 3, 4, or 5.

@property (readonly) bool tidyDetectedXhtml;        // Indicates whether the document is XHTML.

@property (readonly) bool tidyDetectedGenericXml;   // Indicates if the document is generic XML.

@property (readonly) int tidyStatus;                // Returns 0 if there are no errors, 2 for doc errors, 1 for other.

@property (readonly) uint tidyErrorCount;           // Returns number of document errors.

@property (readonly) uint tidyWarningCount;         // Returns number of document warnings.

@property (readonly) uint tidyAccessWarningCount;   // Returns number of document accessibility warnings.


#pragma mark - Miscelleneous


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	MISCELLENEOUS - Misc. Tidy methods supported
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

@property (readonly) NSString *tidyReleaseDate;     // Returns the TidyLib release date.


#pragma mark - Configuration List Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	SUPPORTED CONFIG LIST SUPPORT
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/*
	Loads a list of named potential tidy options from  file, compares
	them to what TidyLib supports, and returns the array containing
	only the names of the supported options.
 */
+ (NSArray *)loadOptionsInUseListFromResource:(NSString *)fileName
									   ofType:(NSString *)fileType;


#pragma mark - Mac OS X Prefs Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	MAC OS PREFS SUPPORT
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/* Puts *all* TidyLib defaults values into a dictionary. */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary;

/* Puts only the TidyLib defaults specified in a resource file into a dictionary. */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
                   fromResource:(NSString *)fileName
                         ofType:(NSString *)fileType;

/* Puts only the TidyLib defaults specified in an array of strings into a dictionary. */
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
                      fromArray:(NSArray *)stringArray;

/* Places the current option values into the specified user defaults instance. */
- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults;

/* Takes option values from the specified user defaults instance. */
- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults;


#pragma mark - TidyOptions


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	TIDYOPTIONS
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/


#pragma mark - Public API and General Properties

@property (readonly) NSDictionary *tidyOptions;

@property (readonly) NSArray *tidyOptionsBindable;

@end

