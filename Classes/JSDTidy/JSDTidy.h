/***************************************************************************************
    JSDTidy.h

    A Cocoa wrapper for tidylib.

 IMPORTANT NOTES: please see the file JSDTidy.rtf for some important notes.
 "FORMAL" DOCUMENATATION: please see the file JSDTidy.html for the "formal," Apple-
                          style documentation. If it shows up as plain-text in
                          Project-Builder, right-click it and open-as an HTML file.
       
 ***************************************************************************************/

#import <Foundation/Foundation.h>
#import "tidy.h"
#import "tidyenum.h"

//-----------------------------------------------------------------------------------------------------------------
// SOME DEFINES
//-----------------------------------------------------------------------------------------------------------------
// In the prefs file, this prefix will prepend all TidyLib options stored there. This would only be used if you're
// using the convenience preferences methods defined in JSDTidyDocument that work with the native Cocoa preferences
// system. This "prefix" support exists in order to isolate the TidyLib configuration names from your own pref names.
#define tidyPrefPrefix @"-tidy-"

// The keys for dealing with errors in errorArray, which is an array of NSDictionary objects with these keys.
#define errorKeyLevel    @"level"
#define errorKeyLine     @"line"
#define errorKeyColumn   @"column"
#define errorKeyMessage  @"message"

// the default encoding styles that override the tidy-implemented character encodings.
#define defaultInputEncoding	NSMacOSRomanStringEncoding
#define defaultLastEncoding	NSMacOSRomanStringEncoding
#define defaultOutputEncoding	NSMacOSRomanStringEncoding

      
/****************************************************************************************************
    JSDTidyDocument
    A basic TidyLib implementation in Cocoa. Tries to implement all of the "good stuff" from TidyLib,
    including the TidyDoc object and methods to use it, options, and eventually true HTML parsing.
    "See config.c" for all of Tidy's configuration options.
    It should be completely self-contained but for linking to Foundation and tidy.h.
 ****************************************************************************************************/
@interface JSDTidyDocument : NSObject {
//------------------------------------------------------------------------------------------------------------
// INSTANCE VARIABLES -- they're protected for subclassing. Use the accessor methods instead of these.
//------------------------------------------------------------------------------------------------------------
@protected
    TidyDoc prefDoc;			// the TidyDocument instance for HOLDING PREFERENCES and nothing more.
    NSString *originalText;		// buffer for the original text - Note this is an NSString instance.
    NSString *workingText;		// buffer the current working text - Note this an an NSString instance.
    NSString *tidyText;			// buffer for the tidy'd text   - Note this is an NSString instance.
    NSString *errorText;		// buffer for the error text    - This is a standard NSString.
    NSMutableArray *errorArray;		// buffer for the error text as an array of NSDictionary of the errors.
    NSStringEncoding inputEncoding;	// the user-specified input-encoding to process everything. OVERRIDE tidy.
    NSStringEncoding lastEncoding;	// the PREVIOUS user-specified input encoding. This is so we can REVERT.
    NSStringEncoding outputEncoding;	// the user-specified output-encoding to process everything. OVERRIDE tidy.
}


//------------------------------------------------------------------------------------------------------------
// ENCODING SUPPORT
//------------------------------------------------------------------------------------------------------------
+(NSArray *)allAvailableStringEncodings;			// returns an array of NSStringEncoding.
+(NSArray *)allAvailableStringEncodingsNames;			// returns an array of NSString, correlated to above.

//------------------------------------------------------------------------------------------------------------
// INITIALIZATION and DESTRUCTION
//------------------------------------------------------------------------------------------------------------
-(id)init;							// override the initializer - designated initializer
-(void)dealloc;							// override the destructor.

// the following convenience initializer assumes you know you're putting in a correctly-decoded NSString.
-(id)initWithString:(NSString *)value;				// sets original & working text at initialization.

// these convenience initializers will DECODE to the Unicode string using the default set for input-encoding
-(id)initWithFile:(NSString *)path;				// initialize with a given file.
-(id)initWithData:(NSData *)data;				// initialize with the given data.
                                    

//------------------------------------------------------------------------------------------------------------
// TEXT - the important, good stuff.
//------------------------------------------------------------------------------------------------------------

//---------------------------------------------
// originalText -- this allows an optional ref-
// erence copy of the really original text as
// a convenience for changes. The non-string
// set methods decode using the current en-
// coding set in input-encoding.
//---------------------------------------------
-(NSString *)originalText;				// read the original text as an NSString.
-(void)setOriginalText:(NSString *)value;		// set the original & working text from an NSString.
-(void)setOriginalTextWithData:(NSData *)data;		// set the original & working text from an NSData.
-(void)setOriginalTextWithFile:(NSString *)path;	// set the original & working text from a file.

//---------------------------------------------
// workingText -- this is the text that Tidy
// will actually tidy up. The non-string set
// methods decode using the current encoding
// setting in input-encoding.
//---------------------------------------------
-(NSString *)workingText;				// read the working text as an NSString.
-(void)setWorkingText:(NSString *)value;		// set the working text from an NSString.
-(void)setWorkingTextWithData:(NSData *)data;		// set the working text from an NSData.
-(void)setWorkingTextWithFile:(NSString *)path;		// set the working text from a file.

//---------------------------------------------
// tidyText -- this is the text that Tidy
// generates from the workingText.
//---------------------------------------------
-(NSString *)tidyText;					// return the tidy'd text.
-(NSData *)tidyTextAsData;				// return the tidy'd text in the output-encoding format.
-(void)tidyTextToFile:(NSString *)path;			// write the tidy'd text to a file in the current format.

//---------------------------------------------
// errors reported by tidy
//---------------------------------------------
-(NSString *)errorText;					// return the error text in traditional tidy format.
-(NSArray *)errorArray;					// return the array of tidy errors and warnings.

//---------------------------------------------
// comparing the text.
//---------------------------------------------
-(bool)areEqualOriginalWorking;				// are the original and working text identical?
-(bool)areEqualWorkingTidy;				// are the working and tidy text identical?
-(bool)areEqualOriginalTidy;				// are the orginal and tidy text identical?

//------------------------------------------------------------------------------------------------------------
// OPTIONS - methods for dealing with options
//------------------------------------------------------------------------------------------------------------
+(NSArray *)         optionGetList;				// returns an NSArray of NSString for all options built into Tidy.
+(int)               optionCount;				// returns the number of options built into Tidy.

+(TidyOptionId)      optionIdForName:(NSString *)name;		// returns the TidyOptionId for the given option name.

+(NSString *)        optionNameForId:(TidyOptionId)idf;		// returns the name for the given TidyOptionId.
+(TidyConfigCategory)optionCategoryForId:(TidyOptionId)idf;	// returns the TidyConfigCategory for the given TidyOptionId.
+(TidyOptionType)    optionTypeForId:(TidyOptionId)idf;		// returns the TidyOptionType: string, int, or bool.
+(NSString *)        optionDefaultValueForId:(TidyOptionId)idf;	// returns the factory default value for the given TidyOptionId.
+(bool)              optionIsReadOnlyForId:(TidyOptionId)idf;	// indicates whether the option is read-only.
+(NSArray *)	     optionPickListForId:(TidyOptionId)idf;	// returns an NSArray of NSString for the given TidyOptionId.

-(NSString *)	     optionValueForId:(TidyOptionId)idf;	// returns the value for the item as an NSString
-(void)		     setOptionValueForId:(TidyOptionId)idf	// sets the value for the given TidyOptionId.
                              fromObject:(id)value;		// Works with NSString or NSNumber only!

-(void)		     optionResetToDefaultForId:(TidyOptionId)id;// resets the designated TidyOptionId to factory default
-(void)		     optionResetAllToDefault;			// resets all options to factory default

-(void)		     optionCopyFromDocument:(JSDTidyDocument *)theDocument;	// sets options based on those in theDocument.

//------------------------------------------------------------------------------------------------------------
// RAW ACCESS EXPOSURE
//------------------------------------------------------------------------------------------------------------
-(TidyDoc)tidyDocument;						// return the TidyDoc attached to this instance.

//------------------------------------------------------------------------------------------------------------
// DIAGNOSTICS and REPAIR
//------------------------------------------------------------------------------------------------------------
-(int) tidyDetectedHtmlVersion;					// returns 0, 2, 3 or 4
-(bool)tidyDetectedXhtml;					// determines whether the document is XHTML.
-(bool)tidyDetectedGenericXml;					// determines if the document is generic XML.

-(int) tidyStatus;						// returns 0 if there are no errors, 2 for doc errors, 1 for other.
-(uint)tidyErrorCount;						// returns number of document errors.
-(uint)tidyWarningCount;					// returns number of document warnings.
-(uint)tidyAccessWarningCount;					// returns number of document accessibility warnings.

// the errorFilter is the instance method that is called from the c-callback in the implementation file. So, callback-to-c-to-this.
-(bool)errorFilter:(TidyDoc)tDoc Level:(TidyReportLevel)lvl Line:(uint)line Column:(uint)col Message:(ctmbstr)mssg;

//------------------------------------------------------------------------------------------------------------
// MISCELLENEOUS - misc. Tidy methods supported
//------------------------------------------------------------------------------------------------------------
-(NSString *)tidyReleaseDate;					// returns the TidyLib release date

//------------------------------------------------------------------------------------------------------------
// SUPPORTED CONFIG LIST SUPPORT
//------------------------------------------------------------------------------------------------------------
+(NSArray *)loadConfigurationListFromResource:(NSString *)fileName ofType:(NSString *)fileType;	// get list of config options.

//------------------------------------------------------------------------------------------------------------
// MAC OS PREFS SUPPORT
//------------------------------------------------------------------------------------------------------------
+(void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary;		// sucks the defaults into a dictionary.
+(void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary			// same as above, but with list of tidy options.
                  fromResource:(NSString *)fileName
                        ofType:(NSString *)fileType;
-(void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults;			// write the values right into prefs.
-(void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults;				// take config from passed-in defaults.

//------------------------------------------------------------------------------------------------------------
// DOCUMENT TREE PARSING -- coming soon!
//------------------------------------------------------------------------------------------------------------

@end // JSDTidyDocument
