/***************************************************************************************
    CocoaTidy.h

    A Cocoa wrapper for tidylib.
 ***************************************************************************************/

#import <Foundation/Foundation.h>
#import "tidy.h"

/****************************************************************************************************
    CocoaTidyOptions
    A complete class for managing Tidy'd options. Implemented this
    separately from the CocoaTidy class, so that (1) the CocoaTidy
    class could simply include an instance of it, and (2) so that
    applications can use the options class for other uses (e.g., prefs)
 ****************************************************************************************************/
@interface CocoaTidyOptions : NSObject {
    // processing directives
    bool optIndent;			// -indent  or -i    to indent element content
    bool optOmit;			// -omit    or -o    to omit optional end tags
    bool optWrapAtColumn;		// -wrap <column>    to wrap text at the specified <column> (default is 68)
    int  optWrapAtColumnNr;		// the <column> for the above option.
    bool optUpper;			// -upper   or -u    to force tags to upper case (default is lower case)
    bool optClean;			// -clean   or -c    to replace FONT, NOBR and CENTER tags by CSS
    bool optBare;			// -bare    or -b    to strip out smart quotes and em dashes, etc.
    bool optNumeric;			// -numeric or -n    to output numeric rather than named entities
    bool optXML;			// -xml		     input is well-formed XML.
    bool optAsXHTML;			// -asxhtml          to convert HTML to well formed XHTML
    bool optAsHTML;			// -ashtml           to force XHTML to well formed HTML
    int optAccessLevel;			// -access <level>   to do additional accessibility checks (<level> = 1, 2, 3)

    // Character encodings
    bool optRaw;			// -raw              to output values above 127 without conversion to entities
    bool optASCII;			// -ascii            to use US-ASCII for output, ISO-8859-1 for input
    bool optLatin1;			// -latin1           to use ISO-8859-1 for both input and output
    bool optISO2022;			// -iso2022          to use ISO-2022 for both input and output
    bool optUTF8;			// -utf8             to use UTF-8 for both input and output
    bool optMac;			// -mac              to use MacRoman for input, US-ASCII for output
    bool optUTF16LE;			// -utf16le          to use UTF-16LE for both input and output
    bool optUTF16BE;			// -utf16be          to use UTF-16BE for both input and output
    bool optUTF16;			// -utf16            to use UTF-16 for both input and output
    bool optWin1252;			// -win1252          to use Windows-1252 for input, US-ASCII for output
    bool optBig5;			// -big5             to use Big5 for both input and output
    bool optShiftJIS;			// -shiftjis         to use Shift_JIS for both input and output
    
    NSString *encoding;			// the encoding value as a string, which is used by tidylib for encoding options.
}

// options
-(bool)optIndent;				// read method for optIndent;
-(void)optIndent:(bool)opt;			// set method for optIndent;

-(bool)optOmit;
-(void)optOmit:(bool)opt;

-(bool)optWrapAtColumn;
-(void)optWrapAtColumn:(bool)opt;

-(int)optWrapAtColumnNr;
-(void)optWrapAtColumnNr:(int)ColumnNr;

-(bool)optUpper;
-(void)optUpper:(bool)opt;

-(bool)optClean;
-(void)optClean:(bool)opt;

-(bool)optBare;
-(void)optBare:(bool)opt;

-(bool)optNumeric;
-(void)optNumeric:(bool)opt;

-(bool)optXML;
-(void)optXML:(bool)opt;

-(bool)optAsXHTML;
-(void)optAsXHTML:(bool)opt;

-(bool)optAsHTML;
-(void)optAsHTML:(bool)opt;

-(int)optAccessLevel;
-(void)optAccessLevel:(int)opt;

-(bool)optRaw;
-(void)optRaw:(bool)opt;

-(bool)optASCII;
-(void)optASCII:(bool)opt;

-(bool)optLatin1;
-(void)optLatin1:(bool)opt;

-(bool)optISO2022;
-(void)optISO2022:(bool)opt;

-(bool)optUTF8;
-(void)optUTF8:(bool)opt;

-(bool)optMac;
-(void)optMac:(bool)opt;

-(bool)optUTF16LE;
-(void)optUTF16LE:(bool)opt;

-(bool)optUTF16BE;
-(void)optUTF16BE:(bool)opt;

-(bool)optUTF16;
-(void)optUTF16:(bool)opt;

-(bool)optWin1252;
-(void)optWin1252:(bool)opt;

-(bool)optBig5;
-(void)optBig5:(bool)opt;

-(bool)optShiftJIS;
-(void)optShiftJIS:(bool)opt;

-(NSString *)encoding;
-(void)setEncodingAsString:(NSString *)string;

@end // CocoaTidyOptions class



/****************************************************************************************************
    CocoaTidy
    A basic TidyLib implementation in Cocoa. Regular tidy options are set
    via an attached CocoaTidyOptions. Basic support is included, which
    means that considering the supported options, Tidy can tidy a document
    and pretty-format it.
 ****************************************************************************************************/
@interface CocoaTidy : NSObject {
    NSString *origText;			// the original text to process.
    NSString *tidyText;			// the tidy'd text done processing.
    NSString *errorText;		// the error-text generated by tidy.
    CocoaTidyOptions *options;		// holds the options supported by this instance.
    TidyDoc tdoc;			// a tidy document for doing the processing.
}

// initialization and deallocation
-(id)init;				// override the initializer.
-(id)initWithString:(NSString *)string;	// initialize with a string.
-(id)initWithContentsOfFile:(NSString *)path;	// initialize with a file.
-(void)dealloc;				// override the destructor.

// strings
-(NSString *)originalText;			// read method for origText.
-(void)setOriginalText:(NSString *)string;	// set method for origText.

-(NSString *)tidyText;				// read method for tidy'd text.

-(NSString *)errorText;				// read method for error log text.

// performTidy
-(void)performTidy;

// peformTidyWithFile:toFile
-(void)performTidyWithFile:(NSString *)fSource:toFile:(NSString *)fDestination;

// option support
-(CocoaTidyOptions *)options;			  // read the options
-(void)setOptionsWithOptions:(CocoaTidyOptions *)theOptions; // set the options.

@end
