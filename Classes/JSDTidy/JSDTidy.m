/***************************************************************************************
    JSDTidy.m

    A Cocoa wrapper for tidylib.
 ***************************************************************************************/

#import "JSDTidy.h"
#import "buffio.h"
#import "config.h"

// let the compiler know this function exists.
extern id objc_msgSend( id self, SEL op, ...);

@implementation JSDTidyDocument

/********************************************************************
    tidyCallbackFilter
       In order to support TidyLib's callback function for process-
       ing errors on the fly, we need to set up a standard C-function
       to handle the callback. In the TidyDoc that we receive, we
       will have put a pointer to self, so that we can call the
       correct instance method from here.
 ********************************************************************/
BOOL tidyCallbackFilter ( TidyDoc tdoc, TidyReportLevel lvl, uint line, uint col, ctmbstr mssg ) {
    typedef Bool (*myTemp)( id, SEL, TidyDoc, TidyReportLevel, uint, uint, ctmbstr ); // to cast objc_msgSend properly.
    bool k = (myTemp)objc_msgSend((id)tidyGetAppData( tdoc ), @selector(errorFilter:Level:Line:Column:Message:), tdoc, lvl, line, col, mssg);
    return k;
} // tidyCallbackFilter


//------------------------------------------------------------------------------------------------------------
// ENCODING SUPPORT -- support the full extent of Mac OS X character encoding.
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    encodingCompare (regular C-function).
    Sort using the equivalent Mac encoding as the major key.
    Secondary key is the actual encoding value, which works well.
    Treat Unicode encodings as special case, and put them at top.
    THIS ROUTINE BASED ON THE ROUTINE FROM THE TEXTEDIT EXAMPLE.
 ********************************************************************/
static int encodingCompare(const void *firstPtr, const void *secondPtr) {
    CFStringEncoding first = *(CFStringEncoding *)firstPtr;
    CFStringEncoding second = *(CFStringEncoding *)secondPtr;
    CFStringEncoding macEncodingForFirst = CFStringGetMostCompatibleMacStringEncoding(first);
    CFStringEncoding macEncodingForSecond = CFStringGetMostCompatibleMacStringEncoding(second);
    if (first == second) return 0;	// Should really never happen
    if (macEncodingForFirst == kCFStringEncodingUnicode || macEncodingForSecond == kCFStringEncodingUnicode) {
        if (macEncodingForSecond == macEncodingForFirst) return (first > second) ? 1 : -1;	// Both Unicode; compare second order
        return (macEncodingForFirst == kCFStringEncodingUnicode) ? -1 : 1;			// First is Unicode
    } // if
    if ((macEncodingForFirst > macEncodingForSecond) || ((macEncodingForFirst == macEncodingForSecond) && (first > second))) return 1;
    return -1;
} // encodingCompare

/********************************************************************
    allAvailableStringEncodings
    returns an array of all available string encodings on the current
    system. The array is of NSNumber containing the NSStringEncoding.
    This will also sort the list, and only includes those encodings
    with human-readable names.
    THIS ROUTINE BASED ON THE ROUTINE FROM THE TEXTEDIT EXAMPLE.
 ********************************************************************/
+(NSArray *)allAvailableStringEncodings {
    static NSMutableArray *allEncodings = nil;	// only do this once
    if (!allEncodings) {
        const CFStringEncoding *cfEncodings = CFStringGetListOfAvailableEncodings();
        CFStringEncoding *tmp;
        int cnt, num = 0;
        while (cfEncodings[num] != kCFStringEncodingInvalidId) num++;	// Count
        tmp = malloc(sizeof(CFStringEncoding) * num);
        memcpy(tmp, cfEncodings, sizeof(CFStringEncoding) * num);	// Copy the list
        qsort(tmp, num, sizeof(CFStringEncoding), encodingCompare);	// Sort it
        allEncodings = [[NSMutableArray alloc] init];			// Now put it in an NSArray
        for (cnt = 0; cnt < num; cnt++) {
            NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(tmp[cnt]);
            if (nsEncoding && [NSString localizedNameOfStringEncoding:nsEncoding]) [allEncodings addObject:[NSNumber numberWithUnsignedInt:nsEncoding]];
        } // for
        free(tmp);
    } // if
    return allEncodings;
} // allAvailableStringEncodings
 
/********************************************************************
    allAvailableStringEncodingsNames
    returns an array of all available string encodings on the current
    system. The array is of NSString containing the human-readable
    names of the encoding types.
 ********************************************************************/
+(NSArray *)allAvailableStringEncodingsNames {
    static NSMutableArray *encodingNames = nil; // only do this once
    if (!encodingNames) {
        encodingNames = [[NSMutableArray alloc] init];
        NSArray *allEncodings = [[self class] allAvailableStringEncodings];			// reference the list of encoding numbers.
        int cnt;										// init counter.
        int numEncodings = [allEncodings count];						// get number of encodings usable.
        for (cnt = 0; cnt < numEncodings; cnt++) {						// loop through the encodings present.
            NSStringEncoding encoding = [[allEncodings objectAtIndex:cnt] unsignedIntValue];	// get the encoding type.
            NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];		// get the encoding name.
            [encodingNames addObject:encodingName];						// add to the array.
        } // for
    } // if
    return encodingNames;
} // allAvailableStringEncodingsNames       

/********************************************************************
    fixSourceCoding
    repairs the character decoding whenever the input-coding has
    changed. This is the logic of how this works here:
        o Our NSString is Unicode, and was decoded FROM lastEncoding.
        o So using lastEncoding make the NSString into an NSData.
        o Using inputEncoding, make the NSData into a new string.
    We're going to process both originalText and workingText.
 ********************************************************************/
-(void)fixSourceCoding {
    // only go through the trouble if the encoding isn't the same!
    if (lastEncoding != inputEncoding) {
        NSString *newText;
        newText = [[NSString alloc] initWithData:[originalText dataUsingEncoding:lastEncoding] encoding:inputEncoding];
        [originalText release];
        originalText = newText;
        newText = [[NSString alloc] initWithData:[workingText dataUsingEncoding:lastEncoding] encoding:inputEncoding];
        [workingText release];
        workingText = newText;
#warning HERE is where to call encodingChange event.
    } // if
} // fixSourceCoding


//------------------------------------------------------------------------------------------------------------
// INITIALIZATION and DESTRUCTION
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    init (the designated initializer)
    set up our local variables needed.
 ********************************************************************/
-(id)init {
    if (self = [super init]) {
        originalText = @"";				// initialize the originalText.
        workingText = @"";				// initialize the workingText.
        tidyText = @"";					// initialize the tidyText.
        errorText = @"";				// initialize the errorText.
        errorArray = [[NSMutableArray alloc] init];	// initialize the errorArray.
        prefDoc = tidyCreate();				// create the preference container.
        inputEncoding = defaultInputEncoding;		// set default user-specified input-encoding.
        lastEncoding = defaultLastEncoding;		// set default user-specified previous encoding for reversion.
        outputEncoding = defaultOutputEncoding;		// set default user-specified output-encoding.
    }
    return self;
} // init

/********************************************************************
    dealloc 
    free up everything we've allocated (I hope).
 ********************************************************************/
-(void)dealloc {
    [originalText release];
    [workingText release];
    [tidyText release];
    [errorText release];
    [errorArray release];
    tidyRelease(prefDoc);
    [super dealloc];
} // dealloc

/********************************************************************
    initWithString 
    initialize with an existing string.
 ********************************************************************/
-(id)initWithString:(NSString *)value {
    [[self init] setOriginalText:value];
    return self;
} // initWithString

/********************************************************************
    initWithFile 
    initialize with the contents of a file.
 ********************************************************************/
-(id)initWithFile:(NSString *)path {
    [[self init] setOriginalTextWithFile:path];
    return self;
} // initWithFile

/********************************************************************
    initWithData 
    initialize with the contents of a file.
 ********************************************************************/
-(id)initWithData:(NSData *)data {
    [[self init] setOriginalTextWithData:data];
    return self;
} // initWithData


//------------------------------------------------------------------------------------------------------------
// TEXT - the important, good stuff.
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    processTidy - regard as PRIVATE
    do the actual tidy processing to set the tidyText and errorText
 ********************************************************************/
-(void)processTidy {
    // use a FRESH TidyDocument each time to cover up some issues with it.
    TidyDoc newTidy = tidyCreate();		// this is the TidyDoc will will really process. Eventually will be prefDoc.
    tidyOptCopyConfig( newTidy, prefDoc );	// put our preferences into the working copy newTidy.
    
    // setup the output buffer to copy to an NSString instead of writing to stdout
    TidyBuffer *outBuffer = malloc(sizeof(TidyBuffer));
    tidyBufInit( outBuffer );

    // setup the error buffer to catch errors here instead of stdout
    tidySetAppData( newTidy, (uint)self );					// so we can send a message from outside ourself to ourself.
    tidySetReportFilter( newTidy, (TidyReportFilter)&tidyCallbackFilter);	// the callback will go to this out-of-class C function.
    [errorArray removeAllObjects];						// clear out all of the previous errors.
    TidyBuffer *errBuffer = malloc(sizeof(TidyBuffer));				// allocate a buffer for our error text.
    tidyBufInit( errBuffer );							// init the buffer.
    tidySetErrorBuffer( newTidy, errBuffer );					// and let tidy know to use it.

    // parse the workingText and clean, repair, and diagnose it.
    tidyOptSetValue( newTidy, TidyCharEncoding, [@"utf8" cString] );					// set all internal char-encoding to UTF8.
    tidyOptSetValue( newTidy, TidyInCharEncoding, [@"utf8" cString] );					// set all internal char-encoding to UTF8.
    tidyOptSetValue( newTidy, TidyOutCharEncoding, [@"utf8" cString] );					// set all internal char-encoding to UTF8.
//    tidyParseBuffer(newTidy, (void*)[[workingText dataUsingEncoding:NSUTF8StringEncoding] bytes]);	// parse the original text into the TidyDoc	
    tidyParseString(newTidy, [workingText UTF8String]);							// parse the original text into the TidyDoc	
    tidyCleanAndRepair( newTidy );									// clean and repair
    tidyRunDiagnostics( newTidy );									// runs diagnostics on the document for us.
    
    // save the tidy'd text to an NSString
    tidySaveBuffer( newTidy, outBuffer );				// save it to the buffer we set up above.
    [tidyText release];							// release the current tidyText.
    if (outBuffer->size > 0) {						// case the buffer to an NSData that we can use to set the NSString.
        tidyText = [[NSString alloc] initWithUTF8String:outBuffer->bp];	// make a string from the data.
    } else
        tidyText = @"";							// set to null string -- no output.
    [tidyText retain];

    // give the Tidy general info at the bottom.
    tidyErrorSummary (newTidy);
    tidyGeneralInfo( newTidy );
        
    // copy the error buffer into an NSString -- the errorArray is built using
    // callbacks so we don't need to do anything at all to build it right here.
    [errorText release];
    if (errBuffer->size > 0)
        errorText = [[NSString alloc] initWithCString:errBuffer->bp];
    else
        errorText = @"";
    [errorText retain];
    
    tidyBufFree(outBuffer);		// free the output buffer.
    tidyBufFree(errBuffer);		// free the error buffer.
    
    // prefDoc has "good" preferences, not corrupted by tidy's processing. But we want to keep newTidy to expose it to
    // the using application. So, we'll assign newTidy as prefDoc after putting prefDoc's preferences into newTidy.
    tidyOptCopyConfig( newTidy, prefDoc );	// save our uncorrupted preferences.
    tidyRelease(prefDoc);			// kill the old prefDoc.
    prefDoc = newTidy;				// now prefDoc is the just-tidy'd document.
} // processTidy

/********************************************************************
    originalText
    read the original text as an NSString.
 ********************************************************************/
-(NSString *)originalText {
    return originalText;
} // originalText

/********************************************************************
    setOriginalText
    set the original & working text from an NSString.
 ********************************************************************/
-(void)setOriginalText:(NSString *)value {
    [value retain];
    [originalText release];
    originalText = value;
    [self setWorkingText:originalText]; // will also process tidy.
} // setOriginalText

/********************************************************************
    setOriginalTextWithData
    set the original & working text from an NSData. Use the current
    user-specified setting for input-encoding to decode.
 ********************************************************************/
-(void)setOriginalTextWithData:(NSData *)data {
    [originalText release];
    originalText = [[NSString alloc] initWithData:data encoding:inputEncoding];
    [originalText retain];
    [self setWorkingText:originalText]; // will also process tidy.
} // setOriginalTextWithData

/********************************************************************
    setOriginalTextWithFile
    set the original & working text from a file.
 ********************************************************************/
-(void)setOriginalTextWithFile:(NSString *)path {
    [originalText release];
    originalText = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:inputEncoding];
    [originalText retain];
    [self setWorkingText:originalText]; // will also process tidy.
} // setOriginalTextWithFile

/********************************************************************
    workingText
    read the original text as an NSString.
 ********************************************************************/
-(NSString *)workingText {
    return workingText;
} // workingText

/********************************************************************
    setWorkingText
    set the original & working text from an NSString.
 ********************************************************************/
-(void)setWorkingText:(NSString *)value {
    [value retain];
    [workingText release];
    workingText = value;
    [self processTidy];
} // setWorkingText

/********************************************************************
    setWorkingTextWithData
    set the original & working text from an NSData.
 ********************************************************************/
-(void)setWorkingTextWithData:(NSData *)data {
    [workingText release];
    workingText = [[NSString alloc] initWithData:data encoding:inputEncoding];
    [workingText retain];
    [self processTidy];
} // setWorkingTextWithData

/********************************************************************
    setWorkingTextWithFile
    set the original & working text from a file.
 ********************************************************************/
-(void)setWorkingTextWithFile:(NSString *)path {
    [workingText release];
    workingText = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:inputEncoding];
    [workingText retain];
    [self processTidy];
} // setWorkingTextWithFile

/********************************************************************
    tidyText
    return the tidy'd text.
 ********************************************************************/
-(NSString *)tidyText {
    return tidyText;
} // tidyText

/********************************************************************
    tidyTextAsData
    return the tidy'd text in the output-encoding format.
 ********************************************************************/
-(NSData *)tidyTextAsData {
    return [tidyText dataUsingEncoding:outputEncoding];
} // tidyTextAsData

/********************************************************************
    tidyTextToFile
    write the tidy'd text to a file in the current format.
 ********************************************************************/
-(void)tidyTextToFile:(NSString *)path {
    [[tidyText dataUsingEncoding:outputEncoding] writeToFile:path atomically:YES];
} // tidyTextToFile

/********************************************************************
    errorText
    read the error text.
 ********************************************************************/
-(NSString *)errorText {
    return errorText;
} // errorText

/********************************************************************
    errorArray
    read the error array.
 ********************************************************************/
-(NSArray *)errorArray {
    return (NSArray *)errorArray;
} // errorArray


/********************************************************************
    areEqualOriginalWorking
    are the original and working text identical?
 ********************************************************************/
-(bool)areEqualOriginalWorking {
    return [originalText isEqualToString:workingText];
} // areEqualOriginalWorking

/********************************************************************
    areEqualWorkingTidy
    are the working and tidy text identical?
 ********************************************************************/
-(bool)areEqualWorkingTidy {
    return [tidyText isEqualToString:tidyText];
} // areEqualWorkingTidy

/********************************************************************
    areEqualOriginalTidy
    are the orginal and tidy text identic
 ********************************************************************/
-(bool)areEqualOriginalTidy{
    return [originalText isEqualToString:tidyText];
} // areEqualOriginalTidy


//------------------------------------------------------------------------------------------------------------
// OPTIONS - methods for dealing with options
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    isTidyEncodingOption
    convenience method just to decide if an optionId is an Tidy
    encoding option.
 ********************************************************************/
+(bool)isTidyEncodingOption:(TidyOptionId)opt {
    return ( (opt == TidyCharEncoding) || (opt == TidyInCharEncoding) || (opt == TidyOutCharEncoding) );
} // isTidyEncodingOption

/********************************************************************
    optionGetOptionInstance -- regard as PRIVATE 
    given an option id, return an instance of a tidy option. This
    is defined because inexplicably some of the TidyLib functions
    require a "real" option in order to return data.
 ********************************************************************/
+(TidyOption)optionGetOptionInstance:(TidyOptionId)idf {
    TidyDoc dummyDoc = tidyCreate();				// create a dummy document.
    TidyOption result = tidyGetOption( dummyDoc, idf);		// get an instance of an option.
    tidyRelease(dummyDoc);					// release the document.
    return result;						// return the instance of the option.
} // optionGetOptionInstance

/********************************************************************
    optionGetList
    returns an NSArray of NSString for all options built into Tidy.
 ********************************************************************/
+(NSArray *)optionGetList {
    static NSMutableArray *theArray = nil;							// just do this once.
    if (!theArray) {
        theArray = [[NSMutableArray alloc] init];						// create an array.
        TidyDoc dummyDoc = tidyCreate();							// create a dummy document (we're a CLASS method).
        TidyIterator i = tidyGetOptionList( dummyDoc );						// set up an iterator
        while ( i ) {										// loop...
            TidyOption topt = tidyGetNextOption( dummyDoc, &i );				// get an option
            [theArray addObject:[NSString stringWithCString:tidyOptGetName( topt )]];		// add the name to the array
        } // while
        tidyRelease(dummyDoc);									// release the dummy document.
    } // if
    return theArray;										// return the array of results.
} // optionGetList

/********************************************************************
    optionCount
    returns the number of Tidy options that exist.
 ********************************************************************/
+(int)optionCount {
    return N_TIDY_OPTIONS;	// defined in config.c of TidyLib
} // optionCount

/********************************************************************
    optionIdForName 
    returns the TidyOptionId for the given option name.
 ********************************************************************/
+(TidyOptionId)optionIdForName:(NSString *)name {
    TidyOptionId optID = tidyOptGetIdForName( [name cString] );
    if (optID < N_TIDY_OPTIONS)
        return optID;			// return the optionId.
    return TidyUnknownOption;		// optionId 0 is TidyUnknownOption
} // optionIdForName

/********************************************************************
    optionNameForId
    returns the name for the given TidyOptionId.
 ********************************************************************/
+(NSString *)optionNameForId:(TidyOptionId)idf {
    return [NSString stringWithCString:tidyOptGetName( [self optionGetOptionInstance:idf] )];
} // optionNameForId

/********************************************************************
    optionCategoryForId
    returns the TidyConfigCategory for the given TidyOptionId.
 ********************************************************************/
+(TidyConfigCategory)optionCategoryForId:(TidyOptionId)idf {
    return tidyOptGetCategory( [self optionGetOptionInstance:idf] );
} // optionCategoryForId

/********************************************************************
    optionTypeForId
    returns the TidyOptionType: string, int, or bool.
 ********************************************************************/
+(TidyOptionType)optionTypeForId:(TidyOptionId)idf {	
    return tidyOptGetType( [self optionGetOptionInstance:idf] );
} // optionTypeForId

/********************************************************************
    optionDefaultValueForId
    returns the factory default value for the given TidyOptionId.
    all values are converted to type NSString -- that's all we deal
    with because Cocoa makes it sooooo easy to convert, and it
    simplifies everything else -- we can use all one datatype.
    We OVERRIDE the encoding options to return our own.
 ********************************************************************/
+(NSString *)optionDefaultValueForId:(TidyOptionId)idf {
    // ENCODING OPTIONS -- special case, so handle first.
    if ([self isTidyEncodingOption:idf]) {	// override tidy encodings with our own. 
        if (idf == TidyCharEncoding) return [NSString stringWithFormat:@"%hu", defaultInputEncoding];
        if (idf == TidyInCharEncoding) return [NSString stringWithFormat:@"%hu", defaultInputEncoding];
        if (idf == TidyOutCharEncoding) return [NSString stringWithFormat:@"%hu", defaultOutputEncoding];
    } // if

    TidyOptionType optType = [JSDTidyDocument optionTypeForId:idf];						// get the option type

    if (optType == TidyString) {
        ctmbstr tmp = tidyOptGetDefault( [self optionGetOptionInstance:idf] );
        return ( (tmp != nil) ? [NSString stringWithCString:tmp] : @"" );					// return either the string or null.
    } // string type

    if (optType == TidyBoolean) {
        return [NSString stringWithFormat:@"%hu", tidyOptGetDefaultBool( [self optionGetOptionInstance:idf] )];	// return string of the bool.
    } // bool type
    
    if (optType == TidyInteger) {
        return [NSString stringWithFormat:@"%hu", tidyOptGetDefaultInt( [self optionGetOptionInstance:idf] )];	// return string of the integer.
    } // integer type

    return @"";
} // optionDefaultValueForId


/********************************************************************
    optionIsReadOnlyForId
    indicates whether the option is read-only
 ********************************************************************/
+(bool)optionIsReadOnlyForId:(TidyOptionId)idf {
    return tidyOptIsReadOnly( [self optionGetOptionInstance:idf] );
} // optionIsReadOnlyForId

/********************************************************************
    optionPickListForId
    returns an NSArray of NSString for the given TidyOptionId
 ********************************************************************/
+(NSArray *)optionPickListForId:(TidyOptionId)idf {
    NSMutableArray *theArray = [[[NSMutableArray alloc] init] autorelease];	// declare our return array
    // if we're an encoding option, return OUR OWN pick list.
    if ([self isTidyEncodingOption:idf]) {
        return [[self class] allAvailableStringEncodingsNames];
    } // if
    else {
        TidyIterator i = tidyOptGetPickList( [self optionGetOptionInstance:idf] );
        while ( i )
            [theArray addObject:[NSString stringWithCString:tidyOptGetNextPick([self optionGetOptionInstance:idf], &i)]];
    } // else - if    
    
    return theArray;
} // optionPickListForId

/********************************************************************
    optionValueForId
    returns the value for the item as an NSString
 ********************************************************************/
-(NSString *)optionValueForId:(TidyOptionId)idf {

    // we need to treat user-defined tags specially, 'cos TidyLib doesn't return them as config options!
    if ((idf == TidyInlineTags) || (idf == TidyBlockTags) || (idf == TidyEmptyTags) || (idf == TidyPreTags)) {
        NSMutableArray *theArray = [[[NSMutableArray alloc] init] autorelease];
        ctmbstr tmp;
        TidyIterator i = tidyOptGetDeclTagList( prefDoc );
        while ( i ) {
            tmp = tidyOptGetNextDeclTag(prefDoc, idf, &i);
            if (tmp)
                [theArray addObject:[NSString stringWithCString:tmp]];
        } // while
        return [theArray componentsJoinedByString:@", "];
    } // if user-defined tags.
    
    // we need to treat encoding options specially, 'cos we're override Tidy's treatment of them.
    if ( [[self class] isTidyEncodingOption:idf]) {
        if (idf == TidyCharEncoding) return [[NSNumber numberWithInt:inputEncoding] stringValue];
        if (idf == TidyInCharEncoding) return [[NSNumber numberWithInt:inputEncoding] stringValue];
        if (idf == TidyOutCharEncoding) return [[NSNumber numberWithInt:outputEncoding] stringValue];
    } // if tidy coding option

    TidyOptionType optType = [JSDTidyDocument optionTypeForId:idf];

    if (optType == TidyString) {
        ctmbstr tmp = tidyOptGetValue( prefDoc, idf );
        return ( (tmp != nil) ? [NSString stringWithCString:tmp] : @"" );
    } // if string type

    if (optType == TidyBoolean) {
        return [[NSNumber numberWithBool:tidyOptGetBool( prefDoc, idf )] stringValue];
    } // if bool type
    
    if (optType == TidyInteger) {
        if (idf == TidyWrapLen) {
            if (tidyOptGetInt( prefDoc, idf) == LONG_MAX) 
                return @"0";
        } // if - special occassion for TidyWrapLen
        return [[NSNumber numberWithInt:tidyOptGetInt( prefDoc, idf )] stringValue];
    } // if integer type

    return @"";
} // optionValueForId

/********************************************************************
    setOptionValueForId:fromObject
    sets the value for the item
 ********************************************************************/
-(void)setOptionValueForId:(TidyOptionId)idf fromObject:(id)value {
    // we need to treat encoding options specially, 'cos we're override Tidy's treatment of them.
    if ( [[self class] isTidyEncodingOption:idf]) {
        if (idf == TidyCharEncoding) {
            lastEncoding = inputEncoding;
            inputEncoding = [value unsignedIntValue];
            outputEncoding = [value unsignedIntValue];
            [self fixSourceCoding];
        } // if TidyCharEncoding;
        if (idf == TidyInCharEncoding) {
            lastEncoding = inputEncoding;
            inputEncoding = [value unsignedIntValue];
            [self fixSourceCoding];
        } // if TidyInCharEncoding;
        if (idf == TidyOutCharEncoding) {
            outputEncoding = [value unsignedIntValue];
        } // if TidyOutCharEncoding;
        return;
    } // if tidy coding option
    
    // here we could be passed any object -- hope it's a string or number or bool!
    if ([value isKindOfClass:[NSString class]])
        tidyOptParseValue( prefDoc, [[JSDTidyDocument optionNameForId:idf] cString], [value cString] );
    else
        if ([value isKindOfClass:[NSNumber class]]) {
            if ([JSDTidyDocument optionTypeForId:idf] == TidyBoolean)
                tidyOptSetBool( prefDoc, idf, [value boolValue]);
            else
                if ([JSDTidyDocument optionTypeForId:idf] == TidyInteger)
                    tidyOptSetInt( prefDoc, idf, [value unsignedIntValue]);            
        } // if
} // setOptionValueForId:fromObject

/********************************************************************
    optionResetToDefaultForId
    resets the designated ID to factory default
 ********************************************************************/
-(void)optionResetToDefaultForId:(TidyOptionId)idf {
    tidyOptResetToDefault( prefDoc, idf );   
} // optionResetToDefaultForId

/********************************************************************
    optionResetAllToDefault
    resets all options to factory default
 ********************************************************************/
-(void)optionResetAllToDefault {
    tidyOptResetAllToDefault( prefDoc );
} // optionResetAllToDefault

/********************************************************************
    optionCopyFromDocument
    copies all options from theDocument
 ********************************************************************/
-(void)optionCopyFromDocument:(JSDTidyDocument *)theDocument {
    tidyOptCopyConfig( prefDoc, [theDocument tidyDocument] );
} // optionCopyFromDocument

//------------------------------------------------------------------------------------------------------------
// RAW ACCESS EXPOSURE
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    tidyDocument
    return the address of prefDoc
 ********************************************************************/
-(TidyDoc)tidyDocument {
    return prefDoc;
} // tidyDocument


//------------------------------------------------------------------------------------------------------------
// DIAGNOSTICS and REPAIR
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    tidyDetectedHtmlVersion
    returns 0, 2, 3 or 4
 ********************************************************************/
-(int)tidyDetectedHtmlVersion {
    return tidyDetectedHtmlVersion( prefDoc );
} // tidyDetectedHtmlVersion

/********************************************************************
    tidyDetectedXhtml
    determines whether the document is XHTML
 ********************************************************************/
-(bool)tidyDetectedXhtml {
    return tidyDetectedXhtml( prefDoc );
} // tidyDetectedXhtml

/********************************************************************
    tidyDetectedGenericXml
    determines if the document is generic XML.
 ********************************************************************/
-(bool)tidyDetectedGenericXml {
    return tidyDetectedGenericXml( prefDoc );
} // tidyDetectedGenericXml

/********************************************************************
    tidyStatus
    returns 0 if there are no errors, 2 for doc errors, 1 for other.
 ********************************************************************/
-(int)tidyStatus {
        return tidyStatus( prefDoc );
} // tidyStatus

/********************************************************************
    tidyErrorCount
    returns number of document errors.
 ********************************************************************/
-(uint)tidyErrorCount {
    return tidyErrorCount( prefDoc );
} // tidyErrorCount

/********************************************************************
    tidyWarningCount
    returns number of document warnings.
 ********************************************************************/
-(uint)tidyWarningCount {
    return tidyWarningCount( prefDoc );
} // tidyWarningCount

/********************************************************************
    tidyAccessWarningCount
    returns number of document accessibility warnings.
 ********************************************************************/
-(uint)tidyAccessWarningCount {
    return tidyAccessWarningCount( prefDoc );
} // tidyAccessWarningCount

/********************************************************************
    errorFilter:Level:Line:Column:Message
       This is the REAL TidyError filter, and is called by the
       standard C tidyCallBackFilter function implemented at the
       top of this file. We CAN'T setup standard C callbacks such
       that they directly callback to an Obj-C method without
       changing the C library to include Obj-C's hidden id and SEL
       parameterss. So this is how it is.
 ********************************************************************/
-(bool)errorFilter:(TidyDoc)tDoc Level:(TidyReportLevel)lvl Line:(uint)line Column:(uint)col Message:(ctmbstr)mssg {
    NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];	// create a dictionary to hold the error report
    [errorDict setObject:[NSNumber numberWithInt:lvl] forKey:errorKeyLevel];
    [errorDict setObject:[NSNumber numberWithInt:line] forKey:errorKeyLine];
    [errorDict setObject:[NSNumber numberWithInt:col] forKey:errorKeyColumn];
    [errorDict setObject:[NSString stringWithCString:mssg] forKey:errorKeyMessage];
    [errorArray addObject:errorDict];
    return YES; // always return yes so errorText works, also. 
} // errorFilter:Level:Line:Column:Message


//------------------------------------------------------------------------------------------------------------
// MISCELLENEOUS - misc. Tidy methods supported
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    tidyReleaseDate
    returns the TidyLib release date
 ********************************************************************/
-(NSString *)tidyReleaseDate {
    return [NSString stringWithCString:tidyReleaseDate()];
} // tidyReleaseDate


//------------------------------------------------------------------------------------------------------------
// SUPPORTED CONFIG LIST SUPPORT
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    loadConfigurationListFromResource:ofType -- CLASS method
    returns an array of NSString from a file-resource. This compares
    each item with the linked-in TidyLib to ensure items are support-
    ed, and ensures there are no duplicates. There is nothing in
    JSDTidyDocument that uses this except for the optional defaults
    system support below, and it aids support of Balthisar
    Tidy's preferences implementation.
 ********************************************************************/
+(NSArray *)loadConfigurationListFromResource:(NSString *)fileName ofType:(NSString *)fileType {
    NSMutableArray *optionsInEffect = [[NSMutableArray alloc] init];
    NSString *contentPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    if (contentPath != nil) {      
    NSEnumerator *enumerator = [[[NSString stringWithContentsOfFile: contentPath] componentsSeparatedByString:@"\n"] objectEnumerator];
        NSString *tmpStr;
        while (tmpStr = [enumerator nextObject]) {
            if (([JSDTidyDocument optionIdForName:tmpStr] != 0) && (![optionsInEffect containsObject:tmpStr]))
                [optionsInEffect addObject:tmpStr];
        } // while
    } // if
    return optionsInEffect;
} // loadConfigurationListFromResource:ofType


//------------------------------------------------------------------------------------------------------------
// MAC OS PREFS SUPPORT
//------------------------------------------------------------------------------------------------------------

/********************************************************************
    addDefaultsToDictionary -- CLASS method
    parses through EVERY default defined in Tidy to ascertain their
    values and add them to the passed-in dictionary. Useful for
    working with the Cocoa preference system. We DON'T register
    the defaults because there may be other defaults to register.
    The calling class can have other items in the passed-in
    dictionary.
 ********************************************************************/
+(void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary {
    NSEnumerator *enumerator = [[JSDTidyDocument optionGetList] objectEnumerator];	// uses ALL tidy options.
    NSString *optionName;
    while (optionName = [enumerator nextObject]) 
        [defaultDictionary setObject:[JSDTidyDocument optionDefaultValueForId:[JSDTidyDocument optionIdForName:optionName]] forKey:[tidyPrefPrefix stringByAppendingString:optionName]];   
} // addDefaultsToDictionary


/********************************************************************
    addDefaultsToDictionary:fromResource:ofType -- CLASS method
    parses through EVERY default defined in the specified resource
    file to ascertain their values and add them to the passed-in
    dictionary. Useful for working with the Cocoa preference system.
    We DON'T register the defaults because there may be other defaults
    to register. The calling class can have other items in the
    passed-in dictionary. Same as addDefaultsToDictionary, except
    uses a resource file list of options, instead of ALL TidyLib
    options.
 ********************************************************************/
+(void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary fromResource:(NSString *)fileName ofType:(NSString *)fileType {
    NSEnumerator *enumerator = [[JSDTidyDocument loadConfigurationListFromResource:fileName ofType:fileType] objectEnumerator]; // just resource options.
    NSString *optionName;
    while (optionName = [enumerator nextObject]) 
        [defaultDictionary setObject:[JSDTidyDocument optionDefaultValueForId:[JSDTidyDocument optionIdForName:optionName]] forKey:[tidyPrefPrefix stringByAppendingString:optionName]];   
} // addDefaultsToDictionary


/********************************************************************
    writeOptionValuesWithDefaults
    parses through the current configuration values and registers
    the current value with the Cocoa preference system. We DO
    register the preference changes, since the calling class can
    also register its own changes when necessary.
 ********************************************************************/
-(void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults {
    NSEnumerator *enumerator = [[JSDTidyDocument optionGetList] objectEnumerator];		// enumerate all built-in options.
    NSString *optionName;									// buffer for an option name.
    while (optionName = [enumerator nextObject]) {						// loop the enumerator.
        TidyOptionId   optId = [JSDTidyDocument optionIdForName:optionName];			// get the optionId
        NSString       *keyName = [tidyPrefPrefix stringByAppendingString:optionName];		// get the name
        [defaults setObject:[self optionValueForId:optId] forKey:keyName];			// write the default
    } // while
} // writeOptionValuesWithDefaults


/********************************************************************
    takeOptionValuesFromDefaults
    given a defaults instance, attempts to set all of its options
    from what's registered in the Apple defaults system.
 ********************************************************************/
-(void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults {
    NSEnumerator *enumerator = [[JSDTidyDocument optionGetList] objectEnumerator];		// enumerate all built-in options.
    NSString *optionName;
    while (optionName = [enumerator nextObject]) {						// loop the enumerator.
        TidyOptionId   optId = [JSDTidyDocument optionIdForName:optionName];			// get the current optionId.
        TidyOptionType optType = [JSDTidyDocument optionTypeForId:optId];			// get the type.
        NSString       *keyName = [tidyPrefPrefix stringByAppendingString:optionName];		// get the key name
        NSObject *myObj = [defaults objectForKey:keyName];					// get the object (value) from the prefs.
        // we've got to convert TidyInteger items into NSNumbers to use them from here. We shouldn't HAVE to,
        // but doctype-mode in TidyLib doesn't have a string parser, so we'll force integers to integers.
        if (optType == TidyInteger)
            [self setOptionValueForId:optId fromObject:[NSNumber numberWithInt:[(NSString *)myObj intValue]]];
        else
            [self setOptionValueForId:optId fromObject:myObj];
    }    
} // takeOptionValuesFromDefaults

@end // JSDTidyDocument
