/***************************************************************************************
    CocoaTidy.m

    A Cocoa wrapper for tidylib.
 ***************************************************************************************/

#import "CocoaTidy.h"
#import "tidy.h"
#import "buffio.h"

@implementation CocoaTidy

///////////////////////////////////////////////////////////////////////////////
/// INITIALIZATION AND DESTRUCTION
///////////////////////////////////////////////////////////////////////////////

/********************************************************************
    init -- designated initializer!
    Our creator. We need to set up our local variables.
 ********************************************************************/
- (id)init {
    if (self = [super init]) {
        origText = @"";
        tidyText = @"";
        errorText = @"";
        options = [[CocoaTidyOptions init] alloc];
        tdoc = tidyCreate();
    }
    return self;
}

/********************************************************************
    dealloc
    Our deallocator in order to dispose of finished variables.
 ********************************************************************/
-(void)dealloc {
    [origText release];
    [tidyText release];
    [errorText release];
    [options release];
    tidyRelease(tdoc);
    [super dealloc];
}

/********************************************************************
    initWithString
    init, but with a string
 ********************************************************************/
-(id)initWithString:(NSString *)string {
    [self init];
    [self setOriginalText:string];
    return self;
}

/********************************************************************
    initWithContentsOfFile
    init, but with the contents of a file
 ********************************************************************/
-(id)initWithContentsOfFile:(NSString *)path {
    [self init];
    [self setOriginalText:[NSString stringWithContentsOfFile:path]];
    return self;
}



///////////////////////////////////////////////////////////////////////////////
/// STRING ACCESS (THE GOOD STUFF)
///////////////////////////////////////////////////////////////////////////////


/********************************************************************
    originalText
    return origText
 ********************************************************************/
-(NSString *)originalText {
    return origText;
}

/********************************************************************
    SetOriginalText
    set origText
 ********************************************************************/
-(void)setOriginalText:(NSString *)string {
    [string retain];
    [origText release];
    origText = string;
}

/********************************************************************
    tidyText
    return tidyText
 ********************************************************************/
-(NSString *)tidyText {
    return tidyText;
}

/********************************************************************
    errorText
    return errorText
 ********************************************************************/
-(NSString *)errorText {
    return errorText;
}


///////////////////////////////////////////////////////////////////////////////
/// OPTIONS SUPPORT
///////////////////////////////////////////////////////////////////////////////
-(CocoaTidyOptions *)options {
    return options;
}

-(void)setOptionsWithOptions:(CocoaTidyOptions *)theOptions {
    [options release];
    options = theOptions;
    [options retain];
}

///////////////////////////////////////////////////////////////////////////////
/// TIDYING ROUTINES -- DO THE ACTUAL TIDY'ING.
///////////////////////////////////////////////////////////////////////////////

/********************************************************************
    prepareTidyOptions
        prepare the options in the tidyDoc to get ready for the op.
 ********************************************************************/
-(void)prepareTidyOptions {
    tidyRelease(tdoc);		// release the old tDoc
    tdoc = tidyCreate();	// create a virgin tDoc
    
    // set the options based on the options record -- encoding options
    tidySetCharEncoding( tdoc, [[options encoding] cString] );

    // set the options based on the options record -- processing directives
    if ([options optIndent])					// indent or not
        tidyOptSetInt( tdoc, TidyIndentContent, 5 );
    if ([options optOmit])					// omit optional end tags
        tidyOptSetBool( tdoc, TidyHideEndTags, YES );
    if ([options optWrapAtColumn])				// word wrap
        tidyOptSetInt( tdoc, TidyWrapLen, [options optWrapAtColumnNr] );
    else
        tidyOptSetInt( tdoc, TidyWrapLen, 0 );			// default to NO wrapping, NOT at 72 characters!
    if ([options optUpper])					// upper case tags
        tidyOptSetBool( tdoc, TidyUpperCaseTags, YES );
    if ([options optClean])					// replace with CSS
        tidyOptSetBool( tdoc, TidyMakeClean, YES );
    if ([options optBare])					// strip smart quotes, etc.
        tidyOptSetBool( tdoc, TidyMakeBare, YES );
    if ([options optNumeric])					// use numberic entities.
        tidyOptSetBool( tdoc, TidyNumEntities, YES );
    if ([options optAsXHTML])					// return XHTML
        tidyOptSetBool( tdoc, TidyXhtmlOut, YES );    
}

/********************************************************************
    performTidy
    run the operation.
 ********************************************************************/
-(void)performTidy{
    int status = 0;			// status at each step of processing

    // setup the tidy options in the tdoc
    [self prepareTidyOptions];

    // setup the output buffer to copy to an NSString instead of writing to stdout
    TidyBuffer *outBuffer = malloc(sizeof(TidyBuffer));
    tidyBufInit( outBuffer );

    // setup the error buffer to catch errors here instead of stdout
    TidyBuffer *errBuffer = malloc(sizeof(TidyBuffer));
    tidyBufInit( errBuffer );
    tidySetErrorBuffer( tdoc, errBuffer );

    // parse the original text into the TidyDoc
    status = tidyParseString(tdoc, [origText cString] /*content*/);

    // clean and repair -- this adds document-type info and meta-data if doc isn't proprietary
    if ( status >= 0 )
        status = tidyCleanAndRepair( tdoc );

    // runs diagnostics on the document for us, which shows additional information.
    if ( status >= 0 )
        status = tidyRunDiagnostics( tdoc );

    // save the tidy'd text to a string
    if ( status >= 0) {
        tidySaveBuffer( tdoc, outBuffer );
        [tidyText release];
        if (outBuffer->size > 0)
            tidyText = [[NSString alloc] initWithCString:outBuffer->bp];
        else
            tidyText = @"";
        [tidyText retain];
    }

    // give the Tidy general info at the bottom.
    tidyGeneralInfo( tdoc );
        
    // copy the error buffer into an NSString
    [errorText release];
    if (errBuffer->size > 0)
        errorText = [[NSString alloc] initWithCString:errBuffer->bp];
    else
        errorText = @"";
    [errorText retain];
    
    tidyBufFree(outBuffer);
    tidyBufFree(errBuffer);		// free the error buffer.
} // end peformTidy


/********************************************************************
    performTidyWithFile:toFile
    run the operation using the already set options, but use file-
    system I/O directly to eliminate possible strangeness with the
    use of NSString (if any?). This wraps the native tidylib calls.
 ********************************************************************/
-(void)performTidyWithFile:(NSString *)fSource:toFile:(NSString *)fDestination {
    int status = 0;			// status at each step of processing

    // setup the tidy options in the tdoc
    [self prepareTidyOptions];

    // parse the original text into the TidyDoc
    status = tidyParseFile( tdoc, [fSource cString] );

    // clean and repair -- this formats the document for us, and reports errors to stderr.
    if ( status >= 0 )
        status = tidyCleanAndRepair( tdoc );

    // runs diagnostics on the document for us.
    if ( status >= 0 )
        status = tidyRunDiagnostics( tdoc );

    // save the tidy'd text to a string
    if ( status >= 0)
        status = tidySaveFile( tdoc, [fDestination cString] );

    // give the Tidy general info at the bottom.
    tidyGeneralInfo( tdoc );
} // end performTidyWithFile:toFile


@end // implementation CocoaTidy



@implementation CocoaTidyOptions

///////////////////////////////////////////////////////////////////////////////
/// INITIALIZATION AND DESTRUCTION
///////////////////////////////////////////////////////////////////////////////

/********************************************************************
    init -- designated initializer!
    Our creator. We need to set up our local variables.
 ********************************************************************/
- (id)init {
    if (self = [super init]) {
        encoding = @"raw";
        optRaw = YES;
    }
    return self;
}

/********************************************************************
    dealloc
    Our deallocator in order to dispose of finished variables.
 ********************************************************************/
-(void)dealloc {
    [encoding release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////
/// OPTION SETTING -- regular options
///////////////////////////////////////////////////////////////////////////////

// optIndent
-(bool)optIndent {
    return optIndent;
}
-(void)optIndent:(bool)opt {
    optIndent = opt;
}

// optOmit
-(bool)optOmit {
    return optOmit;
}
-(void)optOmit:(bool)opt {
    optOmit = opt;
}

// optWrapAtColumn
-(bool)optWrapAtColumn {
    return optWrapAtColumn;
}
-(void)optWrapAtColumn:(bool)opt {
    optWrapAtColumn = opt;
}

// optWrapAtColumnNr
-(int)optWrapAtColumnNr {
    return optWrapAtColumnNr;
}
-(void)optWrapAtColumnNr:(int)ColumnNr {
    optWrapAtColumnNr = ColumnNr;
}

// optUpper
-(bool)optUpper {
    return optUpper;
}
-(void)optUpper:(bool)opt {
    optUpper = opt;
}

// optClean
-(bool)optClean {
    return optClean;
}
-(void)optClean:(bool)opt {
    optClean = opt;
}

// optBare
-(bool)optBare {
    return optBare;
}
-(void)optBare:(bool)opt {
    optBare = opt;
}

// optNumeric
-(bool)optNumeric {
    return optNumeric;
}
-(void)optNumeric:(bool)opt {
    optNumeric = opt;
}

// optXML
-(bool)optXML {
    return optXML;
}
-(void)optXML:(bool)opt {
    optXML = opt;
}

// optAsXHTML
-(bool)optAsXHTML {
    return optAsXHTML;
}
-(void)optAsXHTML:(bool)opt{
    optAsXHTML = opt;
}

// optAsHTML
-(bool)optAsHTML {
   return optAsHTML; 
}
-(void)optAsHTML:(bool)opt {
    optAsHTML = opt;
}

// optAccessLevel
-(int)optAccessLevel {
    return optAccessLevel;
}
-(void)optAccessLevel:(int)opt {
    optAccessLevel = opt;
}


///////////////////////////////////////////////////////////////////////////////
/// OPTION SETTING -- encoding options
///////////////////////////////////////////////////////////////////////////////

-(void)clearAllEncodings {
    optRaw = NO;
    optASCII = NO;
    optLatin1 = NO;
    optISO2022 = NO;
    optUTF8 = NO;
    optMac = NO;
    optUTF16LE = NO;
    optUTF16BE = NO;
    optUTF16 = NO;
    optWin1252 = NO;
    optBig5 = NO;
    optShiftJIS = NO;
}

-(bool)optRaw {
    return optRaw;
}

-(void)optRaw:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"raw"];
    optRaw = YES;
}

-(bool)optASCII {
    return optASCII;
}

-(void)optASCII:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"ascii"];
    optASCII = YES;
}

-(bool)optLatin1 {
    return optLatin1;
}

-(void)optLatin1:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"latin1"];
    optLatin1 = YES;
}

-(bool)optISO2022 {
    return optISO2022;
}

-(void)optISO2022:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"iso2022"];
    optISO2022 = YES;
}

-(bool)optUTF8 {
    return optUTF8;
}

-(void)optUTF8:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"utf8"];
    optUTF8 = YES;
}

-(bool)optMac {
    return optMac;
}

-(void)optMac:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"mac"];
    optMac = YES;
}

-(bool)optUTF16LE {
    return optUTF16LE;
}

-(void)optUTF16LE:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"utf16le"];
    optUTF16LE = YES;
}

-(bool)optUTF16BE {
    return optUTF16BE;
}

-(void)optUTF16BE:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"utf16be"];
    optUTF16BE = YES;
}

-(bool)optUTF16  {
    return optUTF16;
}

-(void)optUTF16:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"utf16"];
    optUTF16 = YES;
}

-(bool)optWin1252 {
    return optWin1252;
}

-(void)optWin1252:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"win1252"];
    optWin1252 = YES;
}

-(bool)optBig5 {
    return optBig5;
}

-(void)optBig5:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"big5"];
    optBig5 = YES;
}

-(bool)optShiftJIS {
    return optShiftJIS;
}

-(void)optShiftJIS:(bool)opt {
    [self clearAllEncodings];
    [self setEncodingAsString:@"shiftjis"];
    optShiftJIS = YES;
}

-(NSString *)encoding {
    return encoding;
}

-(void)setEncodingAsString:(NSString *)string {
    [encoding release];
    encoding = [string lowercaseString];
    [encoding retain];
}


@end // implementation CocoaTidyOptions
