/***************************************************************************************
    JSDTidy.m

    A Cocoa wrapper for tidylib.
 ***************************************************************************************/

#import "JSDTidy.h"
#import "config.h"

@implementation JSDTidyDocument

//---------------------------------------------------------------------------------------
//                            INITIALIZATION and DESTRUCTION
//---------------------------------------------------------------------------------------

/********************************************************************
    init (the designated initializer)
    set up our local variables needed...
 ********************************************************************/
-(id)init {

} // init

/********************************************************************
    initWithString 
    initialize with an existing string.
 ********************************************************************/
-(id)initWithString:(NSString *)string {

} // initWithString

/********************************************************************
    initWithContentsOfFile 
    initialize with the contents of a file.
 ********************************************************************/
-(id)initWithContentsOfFile:(NSString *)path {

} // initWithContentsOfFile

/********************************************************************
    dealloc 
    free up everything we've allocated (I hope)
 ********************************************************************/
-(void)dealloc {
    [super dealloc];
} // dealloc


//---------------------------------------------------------------------------------------
//                      OPTIONS - methods for dealing with options
//---------------------------------------------------------------------------------------

/********************************************************************
    optionIdForName 
    returns the ID for the given name.
 ********************************************************************/
+(TidyOptionId)optionIdForName:(NSString *)name {

} // optionIdForName

/********************************************************************
    optionNameForId
    returns the name for the given ID
 ********************************************************************/
+(NSString *)optionNameForId:(TidyOptionId)id {

} // optionNameForId

/********************************************************************
    optionCategoryForId
    returns the category for the given ID
 ********************************************************************/
+(TidyConfigCategory)optionCategoryForId:(TidyOptionId)id {

} // optionCategoryForId

/********************************************************************
    optionTypeForId
    returns the type: string, int, or bool.
 ********************************************************************/
+(TidyOptionType)optionTypeForId:(TidyOptionId)id {

} // optionTypeForId

/********************************************************************
    optionDefaultValueForId
    returns the factory default value for the given ID
 ********************************************************************/
+(NSString *)optionDefaultValueForId:(TidyOptionId)id {

} // optionDefaultValueForId

/********************************************************************
    optionDefaultIntForId
    returns the factory default value for the given ID
 ********************************************************************/
+(uint)optionDefaultIntForId:(TidyOptionId)id {

} // optionDefaultIntForId

/********************************************************************
    optionDefaultBoolForId
    returns the factory default value for the given ID
 ********************************************************************/
+(bool)optionDefaultBoolForId:(TidyOptionId)id {

} // optionDefaultBoolForId

/********************************************************************
    optionIsReadOnlyForId
    indicates whether the propery is read-only
 ********************************************************************/
+(uint)optionIsReadOnlyForId:(TidyOptionId)id {

} // optionIsReadOnlyForId

/********************************************************************
    optionPickListForId
    returns an NSArray of NSString for the given ID
 ********************************************************************/
+(NSArray *)optionPickListForId:(TidyOptionId)id {

} // optionPickListForId

/********************************************************************
    optionValueForId
    returns the value for the item as an NSString
 ********************************************************************/
-(NSString *)optionValueForId:(TidyOptionId)id {

} // optionValueForId

/********************************************************************
    optionIntForId
    returns the value for the item as an intege
 ********************************************************************/
-(uint)optionIntForId:(TidyOptionId)id {

} // optionIntForId

/********************************************************************
    optionBoolForId
    returns the value for the item as a bool
 ********************************************************************/
-(bool)optionBoolForId:(TidyOptionId)id {

} // optionBoolForId

/********************************************************************
    setOptionValueForId
    sets the value for the item
 ********************************************************************/
-(void)setOptionValueForId:(TidyOptionId)id:fromString:(NSString *)value {

} // setOptionValueForId

/********************************************************************
    setOptionIntForId
    sets the value for the item as an integer
 ********************************************************************/
-(void)setOptionIntForId:(TidyOptionId)id:fromInt:(int)value {

} // setOptionIntForId

/********************************************************************
    setOptionBoolForId
    sets the value for the item as a bool
 ********************************************************************/
-(void)setOptionBoolForId:(TidyOptionId)id:fromBool:(bool)value {

} // setOptionBoolForId

/********************************************************************
    optionResetToDefaultForId
    resets the designated ID to factory default
 ********************************************************************/
-(void)optionResetToDefaultForId:(TidyOptionId)id {

} // optionResetToDefaultForId

/********************************************************************
    optionResetAllToDefault
    resets all options to factory default
 ********************************************************************/
-(void)optionResetAllToDefault {

} // optionResetAllToDefault


//---------------------------------------------------------------------------------------
//                                   DIAGNOSTICS and REPAIR
//---------------------------------------------------------------------------------------

/********************************************************************
    tidyDetectedHtmlVersion
    returns 0, 2, 3 or 4
 ********************************************************************/
-(int)tidyDetectedHtmlVersion {

} // tidyDetectedHtmlVersion

/********************************************************************
    tidyDetectedXhtml
    determines whether the document is XHTML
 ********************************************************************/
-(bool)tidyDetectedXhtml {

} // tidyDetectedXhtml

/********************************************************************
    tidyDetectedGenericXml
    determines if the document is generic XML.
 ********************************************************************/
-(bool)tidyDetectedGenericXml {

} // tidyDetectedGenericXml

/********************************************************************
    tidyStatus
    returns 0 if there are no errors, 2 for doc errors, 1 for other.
 ********************************************************************/
-(int)tidyStatus {

} // tidyStatus

/********************************************************************
    tidyErrorCount
    returns number of document errors.
 ********************************************************************/
-(uint)tidyErrorCount {

} // tidyErrorCount

/********************************************************************
    tidyWarningCount
    returns number of document warnings.
 ********************************************************************/
-(uint)tidyWarningCount {

} // tidyWarningCount

/********************************************************************
    tidyAccessWarningCount
    returns number of document accessibility warnings.
 ********************************************************************/
-(uint)tidyAccessWarningCount {

} // tidyAccessWarningCount

//---------------------------------------------------------------------------------------
//                           TEXT - the important, good stuff.
//---------------------------------------------------------------------------------------

/********************************************************************
    originalText
    read the original text.
 ********************************************************************/
-(NSString *)originalText {

} // originalText

/********************************************************************
    originalText
    set the orginal text
 ********************************************************************/
-(void)originalText:(NSString *)text {

} // originalText

/********************************************************************
    tidyText
    read the tidy'd text.
 ********************************************************************/
-(NSString *)tidyText {

} // tidyText

/********************************************************************
    errorText
    read the error text.
 ********************************************************************/
-(NSString *)errorText {

} // errorText

//---------------------------------------------------------------------------------------
//                        MISCELLENEOUS - misc. Tidy methods supported
//---------------------------------------------------------------------------------------

/********************************************************************
    tidyReleaseDate
    returns the TidyLib release date
 ********************************************************************/
-(NSString *)tidyReleaseDate {

} // tidyReleaseDate

/********************************************************************
    tidySaveFile
    saves the output to the designated file path.
 ********************************************************************/
-(int)tidySaveFile:(NSString *)fileName {

} // tidySaveFile

@end // JSDTidyDocument
