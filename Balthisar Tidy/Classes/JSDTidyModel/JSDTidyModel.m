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

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"
#import "config.h"   // from vendor/tidylib/src/


#pragma mark - IMPLEMENTATION


@implementation JSDTidyModel
{
	NSMutableDictionary *_tidyOptions;         // This backing iVar must be NSMutableDictionary (can't @synthesize)

	NSMutableArray * _errorArray;              // This backing iVar must be NSMutableArray (can't @synthesize)

	NSMutableArray *_tidyOptionHeaders;        // Holds fake options that can be used as headers.

	NSData* _originalData;                     // The original data that the file was loaded from.

	BOOL _sourceDidChange;                     // States whether whether _sourceText has changed.
}


#pragma mark - iVar Synthesis


@synthesize sourceText      = _sourceText;
@synthesize tidyText        = _tidyText;
@synthesize errorText       = _errorText;
@synthesize optionsInUse	= _optionsInUse;


#pragma mark - Standard C Functions

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyCallbackFilter (regular C-function)
		In order to support TidyLib's callback function for
		building an error list on the fly, we need to set up
		this standard C function to handle the callback.

		`tidyGetAppData` result will already contain a reference to
		`self` that we set via `tidySetAppData` during processing.
		Essentially we're calling
		[self errorFilter:Level:Line:Column:Message]
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

/* Compatability with original TidyLib -- doesn't allow localization of messages. */

BOOL tidyCallbackFilter ( TidyDoc tdoc, TidyReportLevel lvl, uint line, uint col, ctmbstr mssg )
{
	return [(__bridge JSDTidyModel*)tidyGetAppData(tdoc) errorFilter:tdoc Level:lvl Line:line Column:col Message:mssg];
}


/* Requires my modifications to TidyLib, allowing localization of the messages. */

BOOL tidyCallbackFilter2 ( TidyDoc tdoc, TidyReportLevel lvl, uint line, uint col, ctmbstr mssg, va_list args )
{
	return [(__bridge JSDTidyModel*)tidyGetAppData(tdoc) errorFilterWithLocalization:tdoc Level:lvl Line:line Column:col Message:mssg Arguments:args];
}


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
	if (self = [super init])
	{
		_sourceDidChange   = NO;
		_originalData      = nil;
		_sourceText        = @"";
		_tidyText          = @"";
		_errorText         = @"";
		_tidyOptions       = [[NSMutableDictionary alloc] init];
		_tidyOptionHeaders = [[NSMutableArray alloc] init];
		_errorArray        = [[NSMutableArray alloc] init];

		[self optionsPopulateTidyOptions];
	}
			
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithString:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithString:(NSString *)value
{
	self = [self init];
	
	if (self)
	{
		[self setSourceText:value];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithString:copyOptionValuesFromModel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithString:(NSString *)value copyOptionValuesFromModel:(JSDTidyModel *)theModel
{
	self = [self init];
	
	if (self)
	{
		[self optionsCopyValuesFromModel:theModel];
		[self setSourceText:value];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithData:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithData:(NSData *)data
{
	self = [self init];
	
	if (self)
	{
		[self setSourceTextWithData:data];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithData:copyOptionValuesFromModel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithData:(NSData *)data copyOptionValuesFromModel:(JSDTidyModel *)theModel
{
	self = [self init];
	
	if (self)
	{
		[self optionsCopyValuesFromModel:theModel];
		[self setSourceTextWithData:data];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithFile:(NSString *)path
{
	self = [self init];
	
	if (self)
	{
		[self setSourceTextWithFile:path];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithFile:copyOptionValuesFromModel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithFile:(NSString *)path copyOptionValuesFromModel:(JSDTidyModel *)theModel
{
	self = [self init];
	
	if (self)
	{
		[self optionsCopyValuesFromModel:theModel];
		[self setSourceTextWithFile:path];
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
		dictionary = [[NSMutableDictionary alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			NSDictionary *items = @{@"LocalizedName"    : [NSString localizedNameOfStringEncoding:*encoding],
									@"NSStringEncoding" : @(*encoding),
									@"LocalizedIndex"   : @([[[self class] allAvailableEncodingLocalizedNames]
															 indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])};
			
			dictionary[[NSString localizedNameOfStringEncoding:*encoding]] = items;

			encoding++;
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
		dictionary = [[NSMutableDictionary alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			NSDictionary *items = @{@"LocalizedName"    : [NSString localizedNameOfStringEncoding:*encoding],
									@"NSStringEncoding" : @(*encoding),
									@"LocalizedIndex"   : @([[[self class] allAvailableEncodingLocalizedNames]
															 indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])};
			
			dictionary[@(*encoding)] = items;
			
			encoding++;
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
		dictionary = [[NSMutableDictionary alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			NSDictionary *items = @{@"LocalizedName"    : [NSString localizedNameOfStringEncoding:*encoding],
									@"NSStringEncoding" : @(*encoding),
									@"LocalizedIndex"   : @([[[self class] allAvailableEncodingLocalizedNames]
															 indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])};
			
			dictionary[@([[[self class] allAvailableEncodingLocalizedNames]
						  indexOfObject:[NSString localizedNameOfStringEncoding:*encoding]])] = items;
			
			encoding++;
		}
	}
	
	return dictionary;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	inputEncoding
		Shortuct to expose the input-encoding value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)inputEncoding
{
	JSDTidyOption *localOption = self.tidyOptions[@"input-encoding"];

	return [localOption.optionValue integerValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	outputEncoding
		Shortuct to expose the output-encoding value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)outputEncoding
{
	JSDTidyOption *localOption = self.tidyOptions[@"output-encoding"];

	return [localOption.optionValue integerValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	checkSourceCoding: (private)
		Checks the passed-in data to perform a sanity check versus
		the current input-encoding. Returns suggested encoding,
		and if the current input-encoding is okay, returns that.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)checkSourceCoding:(NSData*)data
{
	if (data)
	{
		NSUInteger dataSize = data.length;
		NSUInteger stringSize = [[[NSString alloc] initWithData:data encoding:self.inputEncoding] length];

		if ( (dataSize > 0) && (stringSize < 1) )
		{
			/*
				It's likely that the string wasn't decoded properly, so we will
				try all of the following encodings until we get a hit.
			 */

			NSArray *encodingsToTry = @[@(NSUTF8StringEncoding),
										@([NSString defaultCStringEncoding]),
										@(NSMacOSRomanStringEncoding)];

			for (NSNumber *encoding in encodingsToTry)
			{
				if ([[[NSString alloc] initWithData:data encoding:encoding.longLongValue] length] > 0)
				{
					return encoding.longLongValue;
				}
			}
		}
	}

	return self.inputEncoding;
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
	setSourceText:
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
				
		_originalData = [[NSData alloc] initWithData:[_sourceText dataUsingEncoding:self.outputEncoding]];
		
		_sourceDidChange = NO;
		
		/*
			This is the only circumstance in which we will ever
			fire a tidyNotifySourceTextChanged notification
			while setting the source text as a string.
		*/

		[self notifyTidyModelSourceTextChanged];
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
	setSourceTextWithData:
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
			and so `_originalData` will be overwritten. This supports
			the use of TidyLib in a text editor so: the `_originalData`
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
	
	[self willChangeValueForKey:@"sourceText"];

	if ((testText = [[NSString alloc] initWithData:data encoding:self.inputEncoding] ))
	{
		_sourceText = testText;
	}
	else
	{
		_sourceText = @"";
	}

	[self didChangeValueForKey:@"sourceText"];


	_sourceDidChange = NO;

	[self notifyTidyModelSourceTextChanged];
	[self processTidy];

	/* Sanity check the input-encoding */
	NSStringEncoding suggestedEncoding = [self checkSourceCoding:data];

	if (suggestedEncoding != self.inputEncoding)
	{
		[self notifyTidyModelDetectedInputEncodingIssue:suggestedEncoding];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setSourceTextWithFile:
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
	tidyTextAsData
		Return the tidy'd text in the output-encoding format.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSData *)tidyTextAsData
{
	return [[self tidyText] dataUsingEncoding:self.outputEncoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyTextToFile:
		Write the tidy'd text to a file in the output-encoding format.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidyTextToFile:(NSString *)path
{
	[[[self tidyText] dataUsingEncoding:self.outputEncoding] writeToFile:path atomically:YES];
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
	keyPathsForValuesAffectingErrorArray
		All of listed keys affect the error array.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSSet *)keyPathsForValuesAffectingErrorArray
{
    return [NSSet setWithObjects:@"sourceText", @"tidyOptions", @"tidyOptionsBindable", nil];
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	errorArray
		Read the error array.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)errorArray
{
	return (NSArray *)_errorArray;
}


#pragma mark - Options Overall Management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsBuiltInDumpDocsToConsole (class)
		Dump all TidyLib descriptions to error console. This is a
		cheap way to get the descriptions for Localizable.strings.
		This will produce a fairly nice, formatted list of strings
		that you might use directly. Double-check quotes, etc.,
		before building. There are probably a couple of entities
		that are missed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void) optionsBuiltInDumpDocsToConsole
{
	NSArray* optionList = [[self class] optionsBuiltInOptionList];
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
		
		filteredDescription = [[[[JSDTidyOption alloc] initWithName:optionName sharingModel:nil] builtInDescription]
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
	optionsBuiltInOptionCount (class)
		Returns the number of Tidy options that exist.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (int)optionsBuiltInOptionCount
{
	return N_TIDY_OPTIONS;	// defined in config.c of TidyLib
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsBuiltInOptionList (class)
		Returns NSArray of NSString for all option names built 
		into TidyLib.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)optionsBuiltInOptionList
{
	static NSMutableArray *optionsArray = nil;						     // Just do this once.
	
	if (!optionsArray)
	{
		optionsArray = [[NSMutableArray alloc] init];
		
		TidyDoc dummyDoc = tidyCreate();							     // Create a dummy document (we're a CLASS method).
		
		TidyIterator i = tidyGetOptionList( dummyDoc );			         // Set up an iterator.
		
		while ( i )
		{
			TidyOption aTidyOption = tidyGetNextOption( dummyDoc, &i );  // Get an option.
			
			[optionsArray addObject:@(tidyOptGetName( aTidyOption ))];   // Add the name to the array
		}

		tidyRelease(dummyDoc);										     // Release the dummy document.
	}
	
	return optionsArray;												 // Return the array of results.
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsCopyValuesFromModel:
		Copies all options from theModel into our tidyOptions.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsCopyValuesFromModel:(JSDTidyModel *)theModel
{
	JSDTidyOption *foreignOption;

	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		foreignOption = theModel.tidyOptions[localOption.name];

		localOption.optionValue = foreignOption.optionValue;
	}

	[self notifyTidyModelOptionChanged:nil];

	[self processTidy];
	
	[self fixSourceCoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsCopyValuesFromDictionary:
		Copies all options from theDictionary into our tidyOptions.
		Key is the option name and the value is the value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsCopyValuesFromDictionary:(NSDictionary *)theDictionary
{
	NSString *dictionaryValue;

	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		if ((dictionaryValue = [theDictionary valueForKey:localOption.name]))
		{
			localOption.optionValue = dictionaryValue;
		}
	}

	[self notifyTidyModelOptionChanged:nil];

	[self processTidy];
	
	[self fixSourceCoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsResetAllToBuiltInDefaults
		Resets all options to factory default.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsResetAllToBuiltInDefaults
{
	for (JSDTidyOption *localOption in self.tidyOptions)
	{
		localOption.optionValue = localOption.builtInDefaultValue;
	}

	[self notifyTidyModelOptionChanged:nil];

	[self processTidy];
	
	[self fixSourceCoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsInUse
		If set, only options in the array will normally be used.
		Options not in the array won't have values set or read,
		and will maintain their default values. If set to nil,
		then all built-in options will be used.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray*)optionsInUse
{
	if (!_optionsInUse)
	{
		return [[self class] optionsBuiltInOptionList];
	}

	return _optionsInUse;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setOptionsInUse:
		If set, only options in the array will normally be used.
		Options not in the array won't have values set or read,
		and will maintain their default values. If set to nil,
		then all built-in options will be used.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionsInUse:(NSArray *)options
{
	[self willChangeValueForKey:@"tidyOptionsBindable"];

	_optionsInUse = options;

	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		if (_optionsInUse)
		{
			/* Supress the items in tidyOptions that are not in _optionsInUse */
			localOption.optionIsSuppressed = [@([_optionsInUse indexOfObject:localOption.name] == NSNotFound) boolValue];
		}
		else
		{
			localOption.optionIsSuppressed = NO;
		}
	}

	[self optionsPopulateTidyOptionHeaders];

	[self didChangeValueForKey:@"tidyOptionsBindable"];
}


#pragma mark - Options Management - Private Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsPopulateTidyOptions (private)
		Builds the tidyOptions dictionary structure using all of
		TidyLib's available options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsPopulateTidyOptions
{
	[self willChangeValueForKey:@"tidyOptionsBindable"];

	NSArray *optionsList = [[self class] optionsBuiltInOptionList];
		
	for (NSString *optionName in optionsList)
	{
		JSDTidyOption *newOption = [[JSDTidyOption alloc] initWithName:optionName sharingModel:self];
		
		if (!([newOption optionId] == TidyUnknownOption))
		{
			[self.tidyOptions setValue:newOption forKey:newOption.name];
		}
	}

	[self optionsPopulateTidyOptionHeaders];

	[self didChangeValueForKey:@"tidyOptionsBindable"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsPopulateTidyOptionHeaders (private)
		When accessing the tidy options via `tidyOptionsBindable`
		we will include these fake tidy options in the array. This
		gives UIs using bindings the ability to use them as
		headers in (e.g.) tableviews (and if not wanted can be
		filtered out using predicates). We don't care what the
		option name is; we simply want one of any option from each
		category that will will flag as .optionIsHeader.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsPopulateTidyOptionHeaders
{
	[_tidyOptionHeaders removeAllObjects];

	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		if ( (!localOption.optionIsHeader) && (!localOption.optionIsSuppressed) )
		{
			/* Check to make sure localOption.builtInCategory isn't already in _tidyOptionHeaders */

			NSArray *unionOfCategories = [_tidyOptionHeaders valueForKeyPath:@"@unionOfObjects.builtInCategory"];

			if (![unionOfCategories containsObject:@(localOption.builtInCategory)])
			{
				JSDTidyOption *headerOption = [[JSDTidyOption alloc] initWithName:localOption.name sharingModel:self];

				headerOption.optionIsHeader = YES;

				[_tidyOptionHeaders addObject:headerOption];
			}
		}
	}
}


#pragma mark - Diagnostics and Repair


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 processTidy (private)
		 Performs tidy'ing and sets _tidyText and _errorText
	@todo need to refactor this to make it thread-safe.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)processTidy
{
	/* Create a TidyDoc and sets its options. */
	
	TidyDoc newTidy = tidyCreate();

	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		[localOption applyOptionToTidyDoc:newTidy];
	}

	
	/* Setup the `outBuffer` to copy later to an NSString instead of writing to stdout */
	
	TidyBuffer *outBuffer = malloc(sizeof(TidyBuffer));
	tidyBufInit( outBuffer );
	

	/*
		Setup for using and out-of-class C function as a callback
		from TidyLib in order to collect cleanup and diagnostic
		information. The C function is defined near the top of
		this file.
	 */
	tidySetAppData(newTidy, (__bridge void *)(self));                          // Need to send a message from outside self to self.

	/*
		Official TidyLib generates a complete message string that
		is difficult to localize. My fork introduces an additional
	    report filter that passes back message components which
	    can be localized and assembled in the app.
	 
		If you want to compile against virgin TidyLib source, then
	    make sure you change the comments below.
	 */
	 
	//tidySetReportFilter(newTidy, (TidyReportFilter)&tidyCallbackFilter);     // Use for virgin TidyLib compatability.
	tidySetReportFilter2(newTidy, (TidyReportFilter2)&tidyCallbackFilter2);    // Use for my fork of TidyLib.


	/* Setup the error buffer to catch errors here instead of stdout */
	
	TidyBuffer *errBuffer = malloc(sizeof(TidyBuffer));                        // Allocate a buffer for our error text.
	tidyBufInit(errBuffer);                                                    // Init the buffer.
	tidySetErrorBuffer(newTidy, errBuffer);                                    // And let tidy know to use it.
	
	
	/* Clear out all of the previous errors from our collection. */
	
	[_errorArray removeAllObjects];
	
	
	/* Setup tidy to use UTF8 for all internal operations. */
	
	tidyOptSetValue(newTidy, TidyCharEncoding, [@"utf8" UTF8String]);
	tidyOptSetValue(newTidy, TidyInCharEncoding, [@"utf8" UTF8String]);
	tidyOptSetValue(newTidy, TidyOutCharEncoding, [@"utf8" UTF8String]);

		
	/* Parse the `_sourceText` and clean, repair, and diagnose it. */
	
	tidyParseString(newTidy, [_sourceText UTF8String]);
	tidyCleanAndRepair(newTidy);
	tidyRunDiagnostics(newTidy);
	
	
	/*
		Save the tidy'd text to an NSString. If the Tidy result is different
		than the existing Tidy text, then save the new result and post a
		notification. In any case post an error update notification so that
		apps have a chance to update their error tables. This covers a case
		where the source text may change but the TidyText stays identical
		anyway.
	 */
	tidySaveBuffer(newTidy, outBuffer);

	NSString *tidyResult;
	
	if (outBuffer->size > 0)
	{
		tidyResult = [[NSString alloc] initWithUTF8String:(char *)outBuffer->bp];
	}
	else
	{
		tidyResult = @"";
	}

	if ( ![tidyResult isEqualToString:_tidyText])
	{
		[self willChangeValueForKey:@"tidyText"];
		_tidyText = tidyResult;
		[self didChangeValueForKey:@"tidyText"];
		[self notifyTidyModelTidyTextChanged];
	}

	[self notifyTidyModelMessagesChanged];

	
	/*
		Give the Tidy general info at the end of the `_errorText`. Note that
		this information is	NOT captured in the error filter.
	 */
	tidyErrorSummary(newTidy);
	tidyGeneralInfo(newTidy);
	
	
	/*
		Copy the error buffer into an NSString - the `_errorArray` is built using
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
	
	
	/* Set ivars for properties. */
	
	_tidyDetectedHtmlVersion = tidyDetectedHtmlVersion(newTidy);
	_tidyDetectedXhtml       = tidyDetectedXhtml(newTidy);
	_tidyDetectedGenericXml  = tidyDetectedGenericXml(newTidy);
	_tidyStatus              = tidyStatus(newTidy);
	_tidyErrorCount          = tidyErrorCount(newTidy);
	_tidyWarningCount        = tidyWarningCount(newTidy);
	_tidyAccessWarningCount  = tidyAccessWarningCount(newTidy);

	
	/* Clean up. */
	
	tidyBufFree(outBuffer);
	tidyBufFree(errBuffer);
	tidyRelease(newTidy);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	errorFilter:Level:Line:Column:Message:
		This is the REAL TidyError filter, and is called by the
		standard C `tidyCallBackFilter` function implemented at the
		top of this file.

		TidyLib doesn't maintain a structured list of all of its
		errors so here we capture them one-by-one as Tidy tidy's.
		In this way we build our own structured list.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (bool)errorFilter:(TidyDoc)tDoc
			  Level:(TidyReportLevel)lvl
			   Line:(uint)line
			 Column:(uint)col
			Message:(ctmbstr)mssg
{
	__strong NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];
	
	errorDict[@"level"]   = @((int)lvl);	// lvl is a c enum
	errorDict[@"line"]    = @(line);
	errorDict[@"column"]  = @(col);
	errorDict[@"message"] = @(mssg);
	
	[_errorArray addObject:errorDict];
	
	return YES; // Always return yes otherwise _errorText will be surpressed by TidyLib.
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	errorFilterWithLocalization:Level:Line:Column:Message:Arguments:
		This is the REAL TidyError filter, and is called by the
		standard C `tidyCallBackFilter2` function implemented at the
		top of this file.

		TidyLib doesn't maintain a structured list of all of its
		errors so here we capture them one-by-one as Tidy tidy's.
		In this way we build our own structured list.
 
		We're localizing the string a couple of times, because the
		message might arrive in the Message parameter, or it might
		arrive as one of the args. For example, A lot of messages
		are simply %s, and once the args are applied we want to
		localize this single string. In other cases, e.g.,
		"replacing %s by %s" we want to localize that message before
		applying the args. This new string won't be found in the
		.strings file, so it will be used as is.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (bool)errorFilterWithLocalization:(TidyDoc)tDoc
							  Level:(TidyReportLevel)lvl
							   Line:(uint)line
							 Column:(uint)col
							Message:(ctmbstr)mssg
						  Arguments:(va_list)args
{
	NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];


	/* Localize the message */

	NSString *formatString = NSLocalizedStringFromTable(@(mssg), @"JSDTidyModel", nil);

	NSString *intermediateString = [[NSString alloc] initWithFormat:formatString arguments:args];
	
	NSString *messageString = NSLocalizedStringFromTable(intermediateString, @"JSDTidyModel", nil);


	/* Localize the levelDescription and get an image */

	NSArray *errorTypes = @[@"messagesInfo", @"messagesWarning", @"messagesConfig", @"messagesAccess", @"messagesError", @"messagesDocument", @"messagesPanic"];

	NSString *levelDescription = NSLocalizedStringFromTable(errorTypes[(int)lvl], @"JSDTidyModel", nil);

	NSImage *levelImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:errorTypes[(int)lvl] ofType:@"icns"]];


	/* Localize the locaation strings */

	NSString *lineString;

	if (line == 0)
	{
		lineString = NSLocalizedStringFromTable(@"N/A", @"JSDTidyModel", @"");
	}
	else
	{
		lineString = [NSString stringWithFormat:@"%@ %u", NSLocalizedStringFromTable(@"line", @"JSDTidyModel", nil), line];
	}

	NSString *columnString;

	if (col == 0)
	{
		columnString = NSLocalizedStringFromTable(@"N/A", @"JSDTidyModel", @"");
	}
	else
	{
		columnString = [NSString stringWithFormat:@"%@ %u", NSLocalizedStringFromTable(@"column", @"JSDTidyModel", nil), col];
	}

	NSString *locationString;

	if ((line == 0) || (col == 0))
	{
		locationString = NSLocalizedStringFromTable(@"N/A", @"JSDTidyModel", @"");
	}
	else
	{
		locationString = [NSString stringWithFormat:@"%@, %@", lineString, columnString];
	}


	/* Provide an image */


	/* Build the finished array */

	[errorDict setObject:levelImage forKey:@"levelImage"];

	errorDict[@"level"]            = @((int)lvl);	// lvl is a c enum
	errorDict[@"levelDescription"] = levelDescription;
	errorDict[@"line"]             = @(line);
	errorDict[@"lineString"]       = lineString;
	errorDict[@"column"]           = @(col);
	errorDict[@"columnString"]     = columnString;
	errorDict[@"locationString"]   = locationString;
	errorDict[@"message"]          = messageString;

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
	loadOptionsInUseListFromResource:ofType: (class method)
		Returns an array of NSString from a file-resource. This
		compares each item with the linked-in TidyLib to ensure 
		items are supported, and ensures there are no duplicates.
		There is nothing in JSDTidyModel that uses this except
		for the optional defaults system support below, and it aids
		support of Balthisar Tidy's preferences implementation.
 
		NOTE: does *not* set optionsInUse for this instance.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)loadOptionsInUseListFromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	NSMutableArray *desiredOptions = [[NSMutableArray alloc] init];
	
	NSString *contentPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
	
	if (contentPath)
	{
		NSString *optionName;
		NSEnumerator *enumerator = [[[NSString stringWithContentsOfFile:contentPath
															   encoding:NSUTF8StringEncoding
																  error:NULL]
									 componentsSeparatedByString:@"\n"] objectEnumerator];
		
		while (optionName = [enumerator nextObject])
		{
			if ((tidyOptGetIdForName( [optionName UTF8String] ) != N_TIDY_OPTIONS) && (![desiredOptions containsObject:optionName]))
			{
				[desiredOptions addObject:optionName];
			}
		}
	}

	return desiredOptions;
}


#pragma mark - Mac OS X Prefs Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary: (class method)
		Adds TidyLib's default option values to the passed in
		dictionary for ALL TidyLib options.
 
		Accomplish this by parsing through instances of 
		JSDTidyOption and getting each of the built in default
		values and adding them to the passed-in dictionary.
		defined in TidyLib to ascertain its	value and add it to the
		passed-in dictionary.
 
		We DON'T register the defaults because the implementing
		application may have other defaults to add to the dictionary
		and register. This is just a dictionary.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
{
	[[self class] addDefaultsToDictionary:defaultDictionary fromArray:[[self class] optionsBuiltInOptionList]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary:fromResource:ofType: (class method)
		Same as `addDefaultsToDictionary`, except uses a resource
		file list of options instead of ALL TidyLib options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
				   fromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	[[self class] addDefaultsToDictionary:defaultDictionary fromArray:[JSDTidyModel loadOptionsInUseListFromResource:fileName ofType:fileType]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary:fromArray: (class method)
		Same as `addDefaultsToDictionary`, except uses an array
		of strings instead of ALL TidyLib options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
					  fromArray:(NSArray *)stringArray
{
	NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] init];
	
	for (NSString *optionName in stringArray)
	{
		JSDTidyOption *newOption = [[JSDTidyOption alloc] initWithName:optionName sharingModel:nil];

		if ((!newOption.optionIsSuppressed) && (!newOption.optionIsHeader))
		{
			optionsDict[optionName] = newOption.builtInDefaultValue;
		}
	}
	
	defaultDictionary[JSDKeyTidyTidyOptionsKey] = optionsDict;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	writeOptionValuesWithDefaults:
		Iterates through all of the current `tidyOptions` and
		registers their values to the defaults system.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults
{
	NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] init];

	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		if ((!localOption.optionIsSuppressed) && (!localOption.optionIsHeader))
		{
			optionsDict[localOption.name] = localOption.optionValue;
		}
	}

	[defaults setObject:optionsDict forKey:JSDKeyTidyTidyOptionsKey];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	takeOptionValuesFromDefaults:
		Given a defaults instance, attempts to set optionValue for
		each tidyOptions item from the value registered int the
		defaults system.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults
{
	[self willChangeValueForKey:@"tidyOptionsBindable"];

	JSDTidyOption *localOption;

	for (NSString *optionName in [[self class] optionsBuiltInOptionList])
	{
		NSString *valueFromPreferences = [[defaults objectForKey:JSDKeyTidyTidyOptionsKey] objectForKey:optionName];

		localOption = self.tidyOptions[optionName];

		if (localOption)
		{
			localOption.optionValue = valueFromPreferences;
		}
	}

	[self notifyTidyModelOptionChanged:nil];
	
	[self processTidy];

	[self didChangeValueForKey:@"tidyOptionsBindable"];

}


#pragma mark - Tidy Options


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	accessInstanceVariablesDirectly
		Ensure that we keep Cocoa from direct access to our ivars.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+(BOOL)accessInstanceVariablesDirectly
{
	return NO;
}


#pragma mark - Public API and General Properties


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyOptions
		Note that accessors are synthesized.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyOptionsBindable
		Provide a synthesized array that we can easily bind to.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)tidyOptionsBindable
{
	return [[_tidyOptions allValues] arrayByAddingObjectsFromArray:_tidyOptionHeaders];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyOptionsConfigFile
		Returns a string representation of the current configuration
		suitable for use with command-line Tidy. We will only output
		the values of non-supressed options, and we will set any
		encoding options to UTF8 (because we can't match between
		TidyLib's options and Mac OS X' options).
 
		We are NOT going to use TidyLib's approach of only exporting
		non-default values, because we can't count on other versions
		of Tidy using the same defaults. It's a good practice to set
		all values.
  *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)tidyOptionsConfigFile:(NSString*)baseFileName
{
	NSMutableString *result = [[NSMutableString alloc] init];


	NSString *tempString = [NSString stringWithFormat:@"# %@\n", NSLocalizedStringFromTable(@"export-byline", @"JSDTidyModel", nil)];

	[result appendString:[NSString stringWithFormat:tempString, baseFileName]];


	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];

	NSArray *localSortedOptions = [[[self.tidyOptions allValues] copy] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];


	for (JSDTidyOption *localOption in localSortedOptions)
	{
		if (!localOption.optionIsSuppressed)
		{
			[result appendString:localOption.optionConfigString];
		}
	}

	return  (NSString*)result;
}

#pragma mark - Notification and Delegation Support (Private)


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 notifyTidyModelOptionChanged: (private)
		 Fires notification and performs delegation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelOptionChanged:(JSDTidyOption *)tidyOption
{
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self];

	if ([[self delegate] respondsToSelector:@selector(tidyModelOptionChanged:option:)])
	{
		[[self delegate] tidyModelOptionChanged:self option:tidyOption];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 notifyTidyModelSourceTextChanged (private)
		 Fires notification and performs delegation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelSourceTextChanged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifySourceTextChanged object:self];

	if ([[self delegate] respondsToSelector:@selector(tidyModelSourceTextChanged:text:)])
	{
		[[self delegate] tidyModelSourceTextChanged:self text:self.sourceText];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 notifyTidyModelTidyTextChanged (private)
		 Fires notification and performs delegation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelTidyTextChanged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyTextChanged object:self];

	if ([[self delegate] respondsToSelector:@selector(tidyModelTidyTextChanged:text:)])
	{
		[[self delegate] tidyModelTidyTextChanged:self text:self.tidyText];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 notifyTidyModelMessagesChanged (private)
		 Fires notification and performs delegation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelMessagesChanged
{
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyErrorsChanged object:self];

	if ([[self delegate] respondsToSelector:@selector(tidyModelTidyMessagesChanged:messages:)])
	{
		[[self delegate] tidyModelTidyMessagesChanged:self messages:self.errorArray];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 notifyTidyModelDetectedInputEncodingIssue: (private)
		 Fires notification and performs delegation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelDetectedInputEncodingIssue:(NSStringEncoding)suggestedEncoding;
{
	NSDictionary *userData = @{@"currentEncoding"   : @(self.inputEncoding),
							   @"suggestedEncoding" : @(suggestedEncoding)};

	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyPossibleInputEncodingProblem
														object:self
													  userInfo:userData];

	if ([[self delegate] respondsToSelector:@selector(tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:)])
	{
		[[self delegate] tidyModelDetectedInputEncodingIssue:self
											 currentEncoding:self.inputEncoding
										   suggestedEncoding:suggestedEncoding];
	}
}


@end
