/***************************************************************************************
    JSDTidy.h

    A Cocoa wrapper for tidylib.
 ***************************************************************************************/

#import <Foundation/Foundation.h>
#import "tidy.h"
//#import "tidyenum.h"
    
/****************************************************************************************************
    JSDTidyDocument
    A basic TidyLib implementation in Cocoa. Tries to implement all of the "good stuff" from TidyLib,
    including the TidyDoc object and methods to use it, options, and eventually true HTML parsing.
    "See config.c" for all of Tidy's configuration options.
    It should be completely self-contained but for linking to Foundation and tidy.h.
 ****************************************************************************************************/
@interface JSDTidyDocument : NSObject {

    TidyDoc tDoc;			// the TidyDocument instance. Everything is performed on it.
    NSString *originalText;		// buffer for the original text.
}

//---------------------------------------------
// INITIALIZATION and DESTRUCTION
//---------------------------------------------
-(id)init;							// override the initializer - designated initializer
-(id)initWithString:(NSString *)string;				// initialize with a string.
-(id)initWithContentsOfFile:(NSString *)path;			// initialize with a file.
-(void)dealloc;							// override the destructor.

//---------------------------------------------
// OPTIONS - methods for dealing with options
//---------------------------------------------
+(TidyOptionId)optionIdForName:(NSString *)name;		// returns the ID for the given name
+(NSString *)optionNameForId:(TidyOptionId)id;			// returns the name for the given ID
+(TidyConfigCategory)optionCategoryForId:(TidyOptionId)id;	// returns the category for the given ID
+(TidyOptionType)optionTypeForId:(TidyOptionId)id;		// returns the type: string, int, or bool.
+(NSString *)optionDefaultValueForId:(TidyOptionId)id;		// returns the factory default value for the given ID
+(uint)optionDefaultIntForId:(TidyOptionId)id;			// returns the factory default value for the given ID
+(bool)optionDefaultBoolForId:(TidyOptionId)id;			// returns the factory default value for the given ID
+(uint)optionIsReadOnlyForId:(TidyOptionId)id;			// indicates whether the propery is read-only
+(NSArray *)optionPickListForId:(TidyOptionId)id;		// returns an NSArray of NSString for the given ID

-(NSString *)optionValueForId:(TidyOptionId)id;			// returns the value for the item as an NSString
-(uint)optionIntForId:(TidyOptionId)id;				// returns the value for the item as an integer
-(bool)optionBoolForId:(TidyOptionId)id;			// returns the value for the item as a bool
-(void)setOptionValueForId:(TidyOptionId)id:fromString:(NSString *)value;	// sets the value for the item
-(void)setOptionIntForId:(TidyOptionId)id:fromInt:(int)value;	// sets the value for the item as an integer
-(void)setOptionBoolForId:(TidyOptionId)id:fromBool:(bool)value;// sets the value for the item as a bool

-(void)optionResetToDefaultForId:(TidyOptionId)id;		// resets the designated ID to factory default
-(void)optionResetAllToDefault;					// resets all options to factory default

//---------------------------------------------
// DIAGNOSTICS and REPAIR
//---------------------------------------------
-(int)tidyDetectedHtmlVersion;					// returns 0, 2, 3 or 4
-(bool)tidyDetectedXhtml;					// determines whether the document is XHTML
-(bool)tidyDetectedGenericXml;					// determines if the document is generic XML.

-(int)tidyStatus;						// returns 0 if there are no errors, 2 for doc errors, 1 for other.
-(uint)tidyErrorCount;						// returns number of document errors.
-(uint)tidyWarningCount;					// returns number of document warnings.
-(uint)tidyAccessWarningCount;					// returns number of document accessibility warnings.

//---------------------------------------------
// TEXT - the important, good stuff.
//---------------------------------------------
-(NSString *)originalText;					// read the original text.
-(void)originalText:(NSString *)text;				// set the orginal text
-(NSString *)tidyText;						// read the tidy'd text.
-(NSString *)errorText;						// read the error text.

//---------------------------------------------
// MISCELLENEOUS - misc. Tidy methods supported
//---------------------------------------------
-(NSString *)tidyReleaseDate;					// returns the TidyLib release date
-(int)tidySaveFile:(NSString *)fileName;			// saves the output to the designated file path.

//---------------------------------------------
// DOCUMENT TREE PARSING -- coming soon!
//---------------------------------------------

@end // JSDTidyDocument
