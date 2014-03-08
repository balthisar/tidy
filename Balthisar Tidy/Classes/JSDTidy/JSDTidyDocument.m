/**************************************************************************************************

	JSDTidyDocument.m

	A Cocoa wrapper for tidylib.


	The MIT License (MIT)

	Copyright (c) 2001 to 2013 James S. Derry <http://www.balthisar.com>

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

#import "JSDTidyDocument.h"
#import "buffio.h"
#import "config.h"


#pragma mark - CATEGORY - Non-Public

@interface JSDTidyDocument ()
{
@private
	
	__strong NSDictionary* tidyOptionsThatCannotAcceptNULLSTR;
	
	__strong NSMutableArray* _errorArray;					// This backing iVar must be NSMutableArray
	
	__strong NSData* _originalData;							// The original data that the file was loaded from.

	TidyDoc _prefDoc;										// |TidyDocument| instance for holding preferences.
	
	BOOL _sourceDidChange;									// States whether whether _sourceText has changed.
	
}

/*
	We'll use these as internal properties because we want to
    privately access them from other instances, such as when
	copying preferences from instance to instance.
*/

@property (nonatomic, assign) NSStringEncoding inputEncoding;	// User-specified input-encoding. OVERRIDE TidyLib.

@property (nonatomic, assign) NSStringEncoding outputEncoding;	// User-specified output-encoding. OVERRIDE TidyLib.


@end


#pragma mark - IMPLEMENTATION


@implementation JSDTidyDocument


#pragma mark - iVar Synthesis


@synthesize sourceText = _sourceText;
@synthesize tidyText = _tidyText;
@synthesize errorText = _errorText;


#pragma mark - Standard C Functions

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyCallbackFilter (regular C-function)
		In order to support TidyLib's callback function for
		building an error list on the fly, we need to set up this
		standard C function to handle the callback.

		|tidyGetAppData| result will already contain a reference to
		|self| that we set via |tidySetAppData| during processing.
		Essentially we're calling
		[self errorFilter:Level:Line:Column:Message]
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
BOOL tidyCallbackFilter ( TidyDoc tdoc, TidyReportLevel lvl, uint line, uint col, ctmbstr mssg )
{
	return [(__bridge JSDTidyDocument*)tidyGetAppData(tdoc) errorFilter:tdoc Level:lvl Line:line Column:col Message:mssg];
}


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
	if (self = [super init]) {
		_originalData = nil;
		_sourceText = @"";
		_tidyText = @"";
		_errorText = @"";
		_errorArray = [[NSMutableArray alloc] init];
		_prefDoc = tidyCreate();
		_inputEncoding = tidyDefaultInputEncoding;
		_outputEncoding = tidyDefaultOutputEncoding;
		_sourceDidChange = NO;
		
		// TODO: we'll replace this travesty with a unified, in-code
		// exception handling process in next version. This will simply
		// make sure we're not logging errors for this re-release.
		tidyOptionsThatCannotAcceptNULLSTR = @{	@"doctype"     : @NO,
													@"slide-style" : @NO,
													@"language"    : @NO,
													@"css-prefix"  : @NO };
	}
	
	//[[self class] optionDumpDocsToConsole];
	//NSLog(@"%@", [[self class] availableEncodingDictionariesByLocalizedIndex]);
	//NSLog(@"%@", [[self class] availableEncodingDictionariesByNSStringEncoding]);
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	tidyRelease(_prefDoc);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithString:(NSString *)value
{
	self = [self init];
	if (self)
	{
		[self setSourceText:value];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 initWithString:copyOptionsFromDocument
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithString:(NSString *)value copyOptionsFromDocument:(JSDTidyDocument *)theDocument
{
	self = [self init];
	if (self)
	{
		[self optionCopyFromDocument:theDocument];
		[self setSourceText:value];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithFile
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithFile:(NSString *)path
{
	self = [self init];
	if (self)
	{
		[self setSourceTextWithFile:path];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 initWithFile:copyOptionsFromDocument
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithFile:(NSString *)path copyOptionsFromDocument:(JSDTidyDocument *)theDocument
{
	self = [self init];
	if (self)
	{
		[self optionCopyFromDocument:theDocument];
		[self setSourceTextWithFile:path];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithData
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithData:(NSData *)data
{
	self = [self init];
	if (self)
	{
		[self setSourceTextWithData:data];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 initWithData:copyOptionsFromDocument
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithData:(NSData *)data copyOptionsFromDocument:(JSDTidyDocument *)theDocument
{
	self = [self init];
	if (self)
	{
		[self optionCopyFromDocument:theDocument];
		[self setSourceTextWithData:data];
	}
	return self;
}


#pragma mark - String Encoding Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	allAvailableEncodingLocalizedNames
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)allAvailableEncodingLocalizedNames
{
	static NSMutableArray *encodingNames = nil; // Only do this once
	
	if (!encodingNames)
	{
		NSMutableArray *tempNames = [[NSMutableArray alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			[tempNames addObject:[NSString localizedNameOfStringEncoding:*encoding]];
			encoding++;
		}
		
		encodingNames = (NSMutableArray*)[tempNames sortedArrayUsingComparator:^(NSString *a, NSString *b) { return [a localizedCaseInsensitiveCompare:b]; }];
	}
	return encodingNames;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	availableEncodingDictionariesByLocalizedName
		Can retrieve `NSStringEncoding` or `LocalizedIndex`.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSDictionary *)availableEncodingDictionariesByLocalizedName
{
	static NSMutableDictionary *dictionary = nil; // Only do this once
	
	if (!dictionary)
	{
		
		if (!dictionary)
		{
			dictionary = [[NSMutableDictionary alloc] init];
			
			const NSStringEncoding *encoding = [NSString availableStringEncodings];
			
			while (*encoding)
			{
				NSDictionary *items = @{@"LocalizedName" : [NSString localizedNameOfStringEncoding:*encoding],
									    @"NSStringEncoding" : @(*encoding),
									    @"LocalizedIndex" : @([[[self class] allAvailableEncodingLocalizedNames]
															   indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])};
				
				dictionary[[NSString localizedNameOfStringEncoding:*encoding]] = items;

				encoding++;
			}
		}
	}
	return dictionary;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	availableEncodingDictionariesByNSStringEncoding
		Can retrieve `LocalizedName` and `LocalizedIndex`.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSDictionary *)availableEncodingDictionariesByNSStringEncoding
{
	static NSMutableDictionary *dictionary = nil; // Only do this once
	
	if (!dictionary)
	{
		
		if (!dictionary)
		{
			dictionary = [[NSMutableDictionary alloc] init];
			
			const NSStringEncoding *encoding = [NSString availableStringEncodings];
			
			while (*encoding)
			{
				NSDictionary *items = @{@"LocalizedName" : [NSString localizedNameOfStringEncoding:*encoding],
									    @"NSStringEncoding" : @(*encoding),
									    @"LocalizedIndex" : @([[[self class] allAvailableEncodingLocalizedNames]
															   indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])};
				
				dictionary[@(*encoding)] = items;
				
				encoding++;
			}
		}
	}
	return dictionary;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	availableEncodingDictionariesByLocalizedIndex
		Can retrieve `LocalizedName` and `NSStringEncoding`.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSDictionary *)availableEncodingDictionariesByLocalizedIndex
{
	static NSMutableDictionary *dictionary = nil; // Only do this once
	
	if (!dictionary)
	{
		
		if (!dictionary)
		{
			dictionary = [[NSMutableDictionary alloc] init];
			
			const NSStringEncoding *encoding = [NSString availableStringEncodings];
			
			while (*encoding)
			{
				NSDictionary *items = @{@"LocalizedName" : [NSString localizedNameOfStringEncoding:*encoding],
									    @"NSStringEncoding" : @(*encoding),
									    @"LocalizedIndex" : @([[[self class] allAvailableEncodingLocalizedNames]
																indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])};
				
				dictionary[@([[[self class] allAvailableEncodingLocalizedNames]
													  indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])] = items;
				
				encoding++;
			}
		}
	}
	return dictionary;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	fixSourceCoding (private)
		Repairs the character encoding whenever the `input-encoding`
		has changed. If the source never changed and we have original
		data present, then setting _sourceText with the orginal
		data will cause Tidy to use the new input-encoding.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)fixSourceCoding
{
	if (_originalData && !_sourceDidChange)
	{
		[self setSourceTextWithData:_originalData];
	}
}


#pragma mark - Text


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	sourceText
		Read the source text as an NSString.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)sourceText
{
	return _sourceText;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setSourceText
		Set the source text from an NSString. It's up to the client
		application to ensure that a correct NSString is used; no
		support for encoding or changing encoding is provided,
		because that information is not available in a string.
 
		In general TidyLib is file- and data-based, but setting
		the source from a string may be convenient for live editors,
		such as Balthisar Tidy, where string encoding is already
		controlled.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setSourceText:(NSString *)value
{
	_sourceText = value;
	
	if (!_originalData)
	{
		/* 
			If this is a fresh instance, then _originalData will
			be nil, so we can store an original copy of the string
			as NSData. Unlike with the file- and data-based
			setters, this is a one time event since presumably
			setting via NSString may happen repeatedly, such as
			with text editors.
		*/
		
		_originalData = [[NSData alloc] initWithData:[_sourceText dataUsingEncoding:_outputEncoding]];
		_sourceDidChange = NO;
		
		/*
			This is the only circumstance in which we will ever
			fire a tidyNotifySourceTextChanged notification
			while setting the source text as a string.
		*/
		
		[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifySourceTextChanged object:self];
	}
	else
	{
		/*
			Presumably the user is typing, making this document
			dirty now. Now it will be impossible to recover the
			original document if input-encoding is changed.
		*/
		
		_sourceDidChange = YES;
	}
	
	[self processTidy];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setSourceTextWithData
		Set the source text from an NSData using the `input-encoding`
		setting to decode.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setSourceTextWithData:(NSData *)data
{
	
	if (data != _originalData)
	{
		/*
			Unlike with setting via NSString, the presumption for file-
			and data-based setters is that this is a one-time occurrence,
			and so |_originalData| will be overwritten. This supports
			the use of TidyLib in a text editor so: the |_originalData|
			is set only once; text changes set via NSString will not
			overwrite the original data.
		*/
		
		_originalData = [[NSData alloc] initWithData:data];
	}
	
	/*
		It's possible that the _inputEncoding (chosen by the user) is
		incorrect. We will honor the user's choice anyway, but set
		the source text to an empty string if NSString is unable to
		decode the string with the user's preference.
	*/
	
	NSString *testText = nil;
	
	if ((testText = [[NSString alloc] initWithData:data encoding:_inputEncoding] ))
	{
		_sourceText = testText;
	}
	else
	{
		_sourceText = @"";
	}
	
	
	_sourceDidChange = NO;

	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifySourceTextChanged object:self];
	[self processTidy];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setSourceTextWithFile
		Set the source text from a file using the `input-encoding`
		setting to decode.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setSourceTextWithFile:(NSString *)path
{
	[self setSourceTextWithData:[NSData dataWithContentsOfFile:path]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyText
		Return the tidy'd text.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyText
{
	return _tidyText;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setTidyText
		Setter for the tidyText property.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setTidyText:(NSString *)tidyText
{
	_tidyText = tidyText;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyTextAsData
		Return the tidy'd text in the output-encoding format.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSData *)tidyTextAsData
{
	return [[self tidyText] dataUsingEncoding:_outputEncoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyTextToFile
		Write the tidy'd text to a file in the output-encoding format.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidyTextToFile:(NSString *)path
{
	[[[self tidyText] dataUsingEncoding:_outputEncoding] writeToFile:path atomically:YES];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	isDirty
		Indicates whether or not we think the current document is
		"dirty," meaning either the source text has changed since
		it was initially set, or the source text is not the same
		as the Tidy'd text.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)isDirty
{
	return (_sourceDidChange) || (![_sourceText isEqualToString:_tidyText]);
}


#pragma mark - Errors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	errorText
		Read the error text.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)errorText
{
	return _errorText;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	errorArray
		Read the error array.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)errorArray
{
	return (NSArray *)_errorArray;
}


#pragma mark - Options management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	isTidyEncodingOption (private)
		Convenience method just to decide if
		|optionId| is a Tidy encoding option.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (bool)isTidyEncodingOption:(TidyOptionId)opt
{
	return ( (opt == TidyCharEncoding) || (opt == TidyInCharEncoding) || (opt == TidyOutCharEncoding) );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionGetOptionInstance (private)
		Given an option id, return an instance of a tidy option.
		This is required because many of the TidyLib functions
		require an instance in order to return data.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (TidyOption)optionGetOptionInstance:(TidyOptionId)idf
{
	TidyDoc dummyDoc = tidyCreate();					// Create a dummy document.
	TidyOption result = tidyGetOption( dummyDoc, idf);	// Get an instance of an option.
	tidyRelease(dummyDoc);								// Release the document.
	return result;										// Return the instance of the option.
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionGetList
		Returns NSArray of NSString for all options built into Tidy.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)optionGetList
{
	static NSMutableArray *theArray = nil;							// Just do this once.
	
	if (!theArray) 
	{
		theArray = [[NSMutableArray alloc] init];					// Create an array.
		
		TidyDoc dummyDoc = tidyCreate();							// Create a dummy document (we're a CLASS method).
		
		TidyIterator i = tidyGetOptionList( dummyDoc );				// Set up an iterator.
		
		while ( i )
		{
			TidyOption topt = tidyGetNextOption( dummyDoc, &i );	// Get an option.
			
			[theArray addObject:@(tidyOptGetName( topt ))];			// Add the name to the array
		}
		tidyRelease(dummyDoc);										// Release the dummy document.
	}
	return theArray;												// Return the array of results.
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionCount
		Returns the number of Tidy options that exist.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (int)optionCount
{
	return N_TIDY_OPTIONS;	// defined in config.c of TidyLib
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionDocForId:
		TidyLib's built-in definition for |idf|.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSString *) optionDocForId:(TidyOptionId)idf;
{
	TidyDoc dummyDoc = tidyCreate();				// Create a dummy document (we're a CLASS method).
	
	NSString* tidyResultString;
	const char* tidyResultCString = tidyOptGetDoc(dummyDoc, tidyGetOption(dummyDoc, idf));
	
	if (!tidyResultCString)
	{
		tidyResultString = @"No description provided by TidyLib.";
	}
	else
	{
		tidyResultString = @(tidyResultCString);
	}
	
	tidyRelease(dummyDoc);
	
	return tidyResultString;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionDumpDocsToConsole
		Dump all TidyLib descriptions to error console. This is a
		cheap way to get the descriptions for Localizable.strings.
		This will produce a fairly nice, formatted list of strings
		that you might use directly. Double-check quotes, etc.,
		before building. There are probably a couple of entities
		that are missed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void) optionDumpDocsToConsole
{
	NSArray* optionList = [[self class] optionGetList];
	NSString* paddedOptionName;
	NSString* filteredDescription;
	NSAttributedString* convertingString;
	
	NSLog(@"%@", @"----START----");
	
	for (NSString* optionName in optionList)
	{
		paddedOptionName = [[NSString stringWithFormat:@"\"%@\"", optionName]
							stringByPaddingToLength:40
							withString:@" "
							startingAtIndex:0];
		
		filteredDescription = [[[self class] optionDocForId:[[self class] optionIdForName:optionName]]
							   stringByReplacingOccurrencesOfString:@"\""
							   withString:@"'"];

		filteredDescription = [filteredDescription
							   stringByReplacingOccurrencesOfString:@"<br />"
							   withString:@"\\n"];
		
		convertingString = [[NSAttributedString alloc]
							 initWithHTML:[filteredDescription dataUsingEncoding:NSUnicodeStringEncoding]
							 documentAttributes:nil];
		
		filteredDescription = [convertingString string];
		
		NSLog(@"%@= \"%@: %@\";", paddedOptionName, optionName, filteredDescription);
	}
	
	NSLog(@"%@", @"----STOP----");

}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionIdForName
		Returns the TidyOptionId for the given option name.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (TidyOptionId)optionIdForName:(NSString *)name
{
	TidyOptionId optID = tidyOptGetIdForName( [name UTF8String] );
	
	if (optID < N_TIDY_OPTIONS)
	{
		return optID;
	}
	return TidyUnknownOption;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionNameForId
		Returns the name for the given TidyOptionId.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSString *)optionNameForId:(TidyOptionId)idf
{
	return @(tidyOptGetName( [self optionGetOptionInstance:idf] ));
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionCategoryForId
		Returns the TidyConfigCategory for the given TidyOptionId.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (TidyConfigCategory)optionCategoryForId:(TidyOptionId)idf
{
	return tidyOptGetCategory( [self optionGetOptionInstance:idf] );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionTypeForId
		Returns the TidyOptionType: string, int, or bool.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (TidyOptionType)optionTypeForId:(TidyOptionId)idf
{
	return tidyOptGetType( [self optionGetOptionInstance:idf] );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionDefaultValueForId
		Returns the factory default value for the given TidyOptionId.
		All values are converted to type NSString -- that's all we deal
		with because Cocoa makes it easy to convert, and it
		simplifies everything else -- we can use all one datatype.
		
		We OVERRIDE the `encoding` options to return our own in order
		to support using Mac OS X encoding functions instead.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSString *)optionDefaultValueForId:(TidyOptionId)idf
{
	// ENCODING OPTIONS -- special case, so handle first.
	if ([self isTidyEncodingOption:idf])
	{
		if (idf == TidyCharEncoding)
		{
			return [NSString stringWithFormat:@"%u", tidyDefaultInputEncoding];
		}
		
		if (idf == TidyInCharEncoding)
		{
			return [NSString stringWithFormat:@"%u", tidyDefaultInputEncoding];
		}
		
		if (idf == TidyOutCharEncoding)
		{
			return [NSString stringWithFormat:@"%u", tidyDefaultOutputEncoding];
		}
	}

	TidyOptionType optType = [JSDTidyDocument optionTypeForId:idf];

	if (optType == TidyString)
	{
		ctmbstr tmp = tidyOptGetDefault( [self optionGetOptionInstance:idf] );
		return ( (tmp != nil) ? @(tmp) : @"" );
	}

	if (optType == TidyBoolean)
	{
		// Return string of the bool.
		return [NSString stringWithFormat:@"%u", tidyOptGetDefaultBool( [self optionGetOptionInstance:idf] )];
	}

	if (optType == TidyInteger) 
	{
		// Return string of the integer.
		return [NSString stringWithFormat:@"%lu", tidyOptGetDefaultInt( [self optionGetOptionInstance:idf] )];
	}

	return @"";
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionIsReadOnlyForId
		Indicates whether the option is read-only
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (bool)optionIsReadOnlyForId:(TidyOptionId)idf
{
	return tidyOptIsReadOnly( [self optionGetOptionInstance:idf] );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionPickListForId
		Returns an NSArray of NSString for the given |TidyOptionId|
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)optionPickListForId:(TidyOptionId)idf
{
	NSMutableArray *theArray = [[NSMutableArray alloc] init];	
	
	if ([self isTidyEncodingOption:idf])
	{
		return [[self class] allAvailableEncodingLocalizedNames];
	}
	else 
	{
		TidyIterator i = tidyOptGetPickList( [self optionGetOptionInstance:idf] );
		while ( i )
		{
			[theArray addObject:@(tidyOptGetNextPick([self optionGetOptionInstance:idf], &i))];
		}
	}

	return theArray;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionValueForId
		Returns the value for the item as an NSString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)optionValueForId:(TidyOptionId)idf
{
	/*
		We need to treat user-defined tags specially because
		TidyLib doesn't return them as config options.
	*/
	if ((idf == TidyInlineTags) || (idf == TidyBlockTags) || (idf == TidyEmptyTags) || (idf == TidyPreTags)) 
	{
		NSMutableArray *theArray = [[NSMutableArray alloc] init];
		
		ctmbstr tmp;
		
		TidyIterator i = tidyOptGetDeclTagList( _prefDoc );
		
		while ( i ) 
		{
			tmp = tidyOptGetNextDeclTag(_prefDoc, idf, &i);
			
			if (tmp)
			{
				[theArray addObject:@(tmp)];
			}
		}
		
		return [theArray componentsJoinedByString:@", "];
	}

	/*
		We need to treat encoding options specially, because we
		override Tidy's treatment of them. We're keeping these
		values in our own ivars, because TidyLib won't keep
		them for us.
	*/
	if ( [[self class] isTidyEncodingOption:idf])
	{
		if (idf == TidyCharEncoding) 
		{
			return [@(_inputEncoding) stringValue];
		}
		
		if (idf == TidyInCharEncoding) 
		{
			return [@(_inputEncoding) stringValue];
		}
		
		if (idf == TidyOutCharEncoding)
		{
			return [@(_outputEncoding) stringValue];
		}
	}
	
	TidyOptionType optType = [JSDTidyDocument optionTypeForId:idf];

	if (optType == TidyString)
	{
		ctmbstr tmp = tidyOptGetValue( _prefDoc, idf );
		return ( (tmp != nil) ? @(tmp) : @"" );
	} 

	if (optType == TidyBoolean)
	{
		return [@((BOOL)tidyOptGetBool( _prefDoc, idf )) stringValue];
	}

	if (optType == TidyInteger)
	{
		// Special occasion for TidyWrapLen
		if (idf == TidyWrapLen)
		{
			if (tidyOptGetInt( _prefDoc, idf) >= INT_MAX)
			{
				return @"0";
			}
		}
		return [@(tidyOptGetInt( _prefDoc, idf )) stringValue];
	}

	return @"";
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setOptionValueForId:fromObject
		Sets the value for the item in the |_prefDoc|.
		We're using fromObject rather than fromString so that we
		can accept NSString and NSNumber both.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionValueForId:(TidyOptionId)idf fromObject:(id)value
{
	[self setOptionValueForId:idf fromObject:value suppressNotification:NO];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setOptionValueForId:fromObject:suppressNotification
		Same as setOptionValueForId:fromObject with the possibility
		to suppress the notification. Useful when making lots of
		option changes, and used internally to prevent the
		event chain from running all over the place when setting
		lots of tidy options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionValueForId:(TidyOptionId)idf fromObject:(id)value suppressNotification:(BOOL)suppress
{
	/*
	 We need to treat encoding options specially, because we
	 override Tidy's treatment of them. We're keeping these
	 values in our own ivars, because TidyLib won't keep
	 them for us.
	 */
	if ( [[self class] isTidyEncodingOption:idf])
	{
		if (idf == TidyCharEncoding)
		{
			_inputEncoding = [value longLongValue];
			_outputEncoding = [value longLongValue];
			if (!suppress)
			{
				[self fixSourceCoding];
			}
		}
		
		if (idf == TidyInCharEncoding)
		{
			_inputEncoding = [value longLongValue];
			{
				[self fixSourceCoding];
			}
		}
		
		if (idf == TidyOutCharEncoding)
		{
			_outputEncoding = [value longLongValue];
		}
	}
	else
	{
		// Here we could be passed any object, but we'll test for ones we can use.
		if ([value isKindOfClass:[NSString class]])
		{
			if ([value length] == 0)
			{
				/*
				 Some tidy options can't accept NULLSTR but can be reset to default
				 NULLSTR. Some, though require a NULLSTR and resetting to default
				 doesn't work. WTF.
				 */
				
				if ([tidyOptionsThatCannotAcceptNULLSTR valueForKey:[JSDTidyDocument optionNameForId:idf]])
				{
					tidyOptResetToDefault( _prefDoc, idf );
				}
				else
				{
					tidyOptParseValue( _prefDoc, [[JSDTidyDocument optionNameForId:idf] UTF8String], NULLSTR );
				}
			}
			else
			{
				tidyOptParseValue( _prefDoc, [[JSDTidyDocument optionNameForId:idf] UTF8String], [value UTF8String] );
			}
		}
		else
		{
			if ([value isKindOfClass:[NSNumber class]])
			{
				if ([JSDTidyDocument optionTypeForId:idf] == TidyBoolean)
				{
					tidyOptSetBool( _prefDoc, idf, [value boolValue]);
				}
				else
				{
					if ([JSDTidyDocument optionTypeForId:idf] == TidyInteger)
					{
						tidyOptSetInt( _prefDoc, idf, [value unsignedIntValue]);
					}
				}
			}
		}
	}
	
	if (!suppress)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self];
		[self processTidy];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 optionResetToDefaultForId
		 Resets the designated ID to factory default
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionResetToDefaultForId:(TidyOptionId)idf
{
	/*
		 We need to treat encoding options specially, because we
		 override Tidy's treatment of them. We're keeping these
		 values in our own ivars, because TidyLib won't keep
		 them for us.
	*/
	if ( [[self class] isTidyEncodingOption:idf])
	{
		if (idf == TidyCharEncoding)
		{
			_inputEncoding = tidyDefaultInputEncoding;
			_outputEncoding = tidyDefaultInputEncoding;
			[self fixSourceCoding];
		}
		
		if (idf == TidyInCharEncoding)
		{
			_inputEncoding = tidyDefaultInputEncoding;
			[self fixSourceCoding];
		}
		
		if (idf == TidyOutCharEncoding)
		{
			_outputEncoding = tidyDefaultOutputEncoding;
		}
	}
	else
	{
		tidyOptResetToDefault( _prefDoc, idf );
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self];
	[self processTidy];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 optionResetAllToDefault
		 Resets all options to factory default.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionResetAllToDefault
{
	tidyOptResetAllToDefault( _prefDoc );
	
	_inputEncoding = tidyDefaultInputEncoding;
	_outputEncoding	= tidyDefaultOutputEncoding;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self];
	[self processTidy];

	[self fixSourceCoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionCopyFromDocument
		Copies all options from theDocument into our _prefDoc.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionCopyFromDocument:(JSDTidyDocument *)theDocument
{
	tidyOptCopyConfig( _prefDoc, [theDocument tidyDocument] );
	
	_inputEncoding = [theDocument inputEncoding];
	_outputEncoding = [theDocument outputEncoding];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self];
	[self processTidy];

	[self fixSourceCoding];
}


#pragma mark - Raw access exposure


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyDocument
		return the address of |_prefDoc|
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (TidyDoc)tidyDocument
{
	return _prefDoc;
}


#pragma mark - Diagnostics and Repair


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 processTidy (private)
		 Performs tidy'ing and sets _tidyText and _errorText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)processTidy
{
	// Use a FRESH TidyDocument each time to cover up some issues with library code
	TidyDoc newTidy = tidyCreate();			// This is the TidyDoc we will really process. Eventually will be |_prefDoc|.
	tidyOptCopyConfig( newTidy, _prefDoc );	// Put our options into the working copy |newTidy|.
	
	
	// Setup the |outBuffer| to copy to an NSString instead of writing to stdout
	TidyBuffer *outBuffer = malloc(sizeof(TidyBuffer));
	tidyBufInit( outBuffer );
	
	
	// Setup out out-of-class C function callback.
	tidySetAppData( newTidy, (__bridge void *)(self) );										// Need to send a message from outside self to self.
	tidySetReportFilter( newTidy, (TidyReportFilter)&tidyCallbackFilter);	// Callback will go to this out-of-class C function.
	
	
	// Setup the error buffer to catch errors here instead of stdout
	TidyBuffer *errBuffer = malloc(sizeof(TidyBuffer));						// Allocate a buffer for our error text.
	tidyBufInit( errBuffer );												// Init the buffer.
	tidySetErrorBuffer( newTidy, errBuffer );								// And let tidy know to use it.
	
	
	// Clear out all of the previous errors from our collection.
	[_errorArray removeAllObjects];
	
	
	// Setup tidy to use UTF8 for all internal operations.
	tidyOptSetValue( newTidy, TidyCharEncoding, [@"utf8" UTF8String] );
	tidyOptSetValue( newTidy, TidyInCharEncoding, [@"utf8" UTF8String] );
	tidyOptSetValue( newTidy, TidyOutCharEncoding, [@"utf8" UTF8String] );

	
	// Parse the |_sourceText| and clean, repair, and diagnose it.
	tidyParseString(newTidy, [_sourceText UTF8String]);
	tidyCleanAndRepair( newTidy );
	tidyRunDiagnostics( newTidy );
	
	
	/*
		Save the tidy'd text to an NSString. If the Tidy result
		is different than the existing Tidy text, then save
		the new result and post a notification.
	*/
	tidySaveBuffer( newTidy, outBuffer );	// Save it to the buffer we set up above.
	NSString *tidyResult;
	if (outBuffer->size > 0)
	{
		tidyResult = [[NSString alloc] initWithUTF8String:(char *)outBuffer->bp];
	}
	else {
		tidyResult = @"";
	}

	if ( ![tidyResult isEqualToString:_tidyText])
	{
		[self setTidyText:tidyResult];
		[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyTextChanged object:self];
	}

	
	/*
		Give the Tidy general info at the end of the
		_errorText. Note that this information is
		NOT captured in the error filter.
	*/
	tidyErrorSummary( newTidy );
	tidyGeneralInfo( newTidy );
	
	
	/*
		Copy the error buffer into an NSString -- the |_errorArray| is built using
		callbacks so we don't need to do anything at all to build it right here.
	*/
	if (errBuffer->size > 0)
	{
		_errorText = [[NSString alloc] initWithUTF8String:(char *)errBuffer->bp];
	}
	else
	{
		_errorText = @"";
	}

	// Clean up our old buffers.
	tidyBufFree(outBuffer);
	tidyBufFree(errBuffer);
	
	
	/*
		Tidy's processing screws up some of its preferences for some reason,
		and so now |newTidy| has corrupt preferences. However we want to
		expose |newTidy| to the using application for whatever reason. So
		we will copy our good preferences from existing |_prefDoc| into
		|newTidy|, and |newTidy| will become the new |_prefDoc|.
	*/
	tidyOptCopyConfig( newTidy, _prefDoc );	// Save our uncorrupted preferences.
	tidyRelease(_prefDoc);					// Kill the old _prefDoc.
	_prefDoc = newTidy;						// Now _prefDoc is the just-tidy'd document.
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyDetectedHtmlVersion
		Returns 0, 2, 3, 4, or 5.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (int)tidyDetectedHtmlVersion
{
	return tidyDetectedHtmlVersion( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyDetectedXhtml
		 Detects if the document is XHTML.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (bool)tidyDetectedXhtml
{
	return tidyDetectedXhtml( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyDetectedGenericXml
		Detects if the document is generic XML.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (bool)tidyDetectedGenericXml
{
	return tidyDetectedGenericXml( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyStatus
		 Returns 0 if there are no errors, 2 for doc errors, 
		1 for other type of error.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (int)tidyStatus
{
	return tidyStatus( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyErrorCount
		 Returns number of document errors.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)tidyErrorCount
{
	return tidyErrorCount( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyWarningCount
		 Returns number of document warnings.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)tidyWarningCount
{
	return tidyWarningCount( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyAccessWarningCount
		 Returns number of document accessibility warnings.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)tidyAccessWarningCount
{
	return tidyAccessWarningCount( _prefDoc );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	errorFilter:Level:Line:Column:Message
		This is the REAL TidyError filter, and is called by the
		standard C |tidyCallBackFilter| function implemented at the
		top of this file.

		TidyLib doesn't maintain a structured list of all of its
		errors so here we capture them one-by-one as Tidy tidy's.
		In this way we build our own structured list.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (bool)errorFilter:(TidyDoc)tDoc Level:(TidyReportLevel)lvl Line:(uint)line Column:(uint)col Message:(ctmbstr)mssg
{
	NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];
	
	errorDict[@"level"] = @((int)lvl);	// lvl is a c enum
	errorDict[@"line"] = @(line);
	errorDict[@"column"] = @(col);
	errorDict[@"message"] = @(mssg);
	
	[_errorArray addObject:errorDict];
	
	
	return YES; // Always return yes otherwise _errorText will be surpressed by TidyLib.
}


#pragma mark - Miscelleneous


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidyReleaseDate
		 Returns the TidyLib release date.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyReleaseDate
{
	return @(tidyReleaseDate());
}


#pragma mark - Configuration List Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	loadConfigurationListFromResource:ofType (class method)
		Returns an array of NSString from a file-resource. This
		compares each item with the linked-in TidyLib to ensure 
		items are supported, and ensures there are no duplicates.
		There is nothing in JSDTidyDocument that uses this except
		for the optional defaults system support below, and it aids
		support of Balthisar Tidy's preferences implementation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)loadConfigurationListFromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	NSMutableArray *optionsInEffect = [[NSMutableArray alloc] init];
	NSString *contentPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
	
	if (contentPath != nil)
	{
		NSString *tmpStr;
		NSEnumerator *enumerator = [[[NSString stringWithContentsOfFile:contentPath
															   encoding:NSUTF8StringEncoding
																  error:NULL]
									 componentsSeparatedByString:@"\n"] objectEnumerator];
		
		while (tmpStr = [enumerator nextObject])
		{
			if (([JSDTidyDocument optionIdForName:tmpStr] != 0) && (![optionsInEffect containsObject:tmpStr]))
			{
				[optionsInEffect addObject:tmpStr];
			}
		}
	}
	return optionsInEffect;
}


#pragma mark - Mac OS X Prefs Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary (class method)
		Parses through each default defined in Tidy to ascertain its
		value and add it to the passed-in dictionary. Useful for
		working with the Cocoa preference system. We DON'T register
		the defaults because there may be other defaults to register.
		The calling class can have other items in the passed-in
		dictionary.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
{
	NSEnumerator *enumerator = [[JSDTidyDocument optionGetList] objectEnumerator];
	NSString *optionName;
	
	while (optionName = [enumerator nextObject])
	{
		defaultDictionary[[tidyPrefPrefix stringByAppendingString:optionName]] = [JSDTidyDocument optionDefaultValueForId:[JSDTidyDocument optionIdForName:optionName]];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary:fromResource:ofType (class method)
		Same as |addDefaultsToDictionary|, except uses a resource
		file list of options, instead of ALL TidyLib options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary fromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	NSEnumerator *enumerator = [[JSDTidyDocument loadConfigurationListFromResource:fileName ofType:fileType] objectEnumerator];
	NSString *optionName;
	
	while (optionName = [enumerator nextObject])
	{
		defaultDictionary[[tidyPrefPrefix stringByAppendingString:optionName]] = [JSDTidyDocument optionDefaultValueForId:[JSDTidyDocument optionIdForName:optionName]];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	writeOptionValuesWithDefaults
		Parses through the current configuration values and registers
		the current value with the Cocoa preference system. We DO
		register the preference changes, since the calling class can
		also register its own changes when necessary.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults
{
	NSEnumerator *enumerator = [[JSDTidyDocument optionGetList] objectEnumerator];
	NSString *optionName;
	
	while (optionName = [enumerator nextObject])
	{
		TidyOptionId	optId = [JSDTidyDocument optionIdForName:optionName];
		NSString		*keyName = [tidyPrefPrefix stringByAppendingString:optionName];
		
		[defaults setObject:[self optionValueForId:optId] forKey:keyName];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	takeOptionValuesFromDefaults
		Given a defaults instance, attempts to set all of its options
		from what's registered in the Apple defaults system.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults
{
	NSEnumerator *enumerator = [[JSDTidyDocument optionGetList] objectEnumerator];
	NSString *optionName;
	
	while (optionName = [enumerator nextObject])
	{
		TidyOptionId	optId = [JSDTidyDocument optionIdForName:optionName];
		TidyOptionType	optType = [JSDTidyDocument optionTypeForId:optId];
		NSString		*keyName = [tidyPrefPrefix stringByAppendingString:optionName];
		NSObject		*myObj = [defaults objectForKey:keyName];
		
		/*
			Most options in TidyLib have string parsers and we can happily
			pass string representations of integers to TidyLib. Except that
			`doctype-mode` doesn't accept strings. We're working with strings,
			but we'll convert strings to NSNumber objects so we can use integers
			natively instead of trying to force strings into TidyLib, even though
			it's supposed to work.
		*/
		if (optType == TidyInteger)
		{
			[self setOptionValueForId:optId fromObject:@([(NSString *)myObj longLongValue]) suppressNotification:YES];
		}
		else
		{
			[self setOptionValueForId:optId fromObject:myObj suppressNotification:YES];
		}
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self];
	[self processTidy];
}

@end
