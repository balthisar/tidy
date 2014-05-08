/**************************************************************************************************

	JSDTidyModel.m

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

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"


#pragma mark - CATEGORY - Non-Public

@interface JSDTidyModel ()
{
@private
	
	__strong NSMutableDictionary* _tidyOptions;				// This backing iVar must be NSMutableDictionary.
		
	__strong NSMutableArray* _errorArray;					// This backing iVar must be NSMutableArray
	
	__strong NSData* _originalData;							// The original data that the file was loaded from.

	BOOL _sourceDidChange;									// States whether whether _sourceText has changed.
}

@end


#pragma mark - IMPLEMENTATION


@implementation JSDTidyModel


#pragma mark - iVar Synthesis


@synthesize sourceText = _sourceText;
@synthesize tidyText   = _tidyText;
@synthesize errorText  = _errorText;


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
- (id)init
{
	if (self = [super init])
	{
		_tidyOptions     = [[NSMutableDictionary alloc] init];
		_originalData    = nil;
		_sourceText      = @"";
		_tidyText        = @"";
		_errorText       = @"";
		_errorArray      = [[NSMutableArray alloc] init];
		_sourceDidChange = NO;
		
		[self optionsPopulateTidyOptions];
	}
			
	return self;
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
	initWithString:copyOptionsFromModel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithString:(NSString *)value copyOptionsFromModel:(JSDTidyModel *)theModel
{
	self = [self init];
	
	if (self)
	{
		[self optionsCopyFromModel:theModel];
		[self setSourceText:value];
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
	initWithData:copyOptionsFromModel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithData:(NSData *)data copyOptionsFromModel:(JSDTidyModel *)theModel
{
	self = [self init];
	
	if (self)
	{
		[self optionsCopyFromModel:theModel];
		[self setSourceTextWithData:data];
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
	initWithFile:copyOptionsFromModel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithFile:(NSString *)path copyOptionsFromModel:(JSDTidyModel *)theModel
{
	self = [self init];
	
	if (self)
	{
		[self optionsCopyFromModel:theModel];
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
	return [[self.tidyOptions[@"input-encoding"] valueForKey:@"optionValue"] integerValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	outputEncoding
		Shortuct to expose the output-encoding value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)outputEncoding
{
	return [[self.tidyOptions[@"output-encoding"] valueForKey:@"optionValue"] integerValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	checkSourceCoding (private)
		Checks the passed-in data to perform a sanity check versus
		the current input-encoding. Returns suggested encoding,
		and if the current input-encoding is okay, returns that.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)checkSourceCoding:(NSData*)data
{
	if ( data )
	{
		NSUInteger dataSize   = data.length;
		NSUInteger stringSize = [[[NSString alloc] initWithData:data encoding:self.inputEncoding] length];

		if ( (dataSize > 0) && (stringSize < 1) )
		{
			/*
			 It's likely that the string wasn't decoded properly, so we will
			 prepare and present a friendly NSPopover with an explanation and
			 some options.
			 */

			/*
			 We will try all of the following encodings until we get a hit.
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


#pragma mark - TidyOptions


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyOptions
		Note that accessors are synthesized.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/


#pragma mark - Key-Value Access

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	objectForKeyedSubscript:
		We will use this as a convenience accessor to the values
		in tidyOptions. As such they can be read using
		`jsdmodelInstance[@"encoding"], for example.
 
		Additionally we will conveniently provide this easy access
		to other properties as shown in the code.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
	if ([[NSSet setWithObjects:@"sourceText", @"tidyText", @"errorArray", nil] member:key])
	{
		return [self valueForKey:[NSString stringWithFormat:@"%@", key]];
	}
	else
	{
		// Hopefully it's a tidyOption.
		return [[self.tidyOptions objectForKey:key] valueForKey:@"optionValue"];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setObject:ForKeyedSubscript:
		We will use this as a convenience accessor to the values
		in tidyOptions. As such they can be set using
		`jsdmodelInstance[@"wrap"] = @(32), for example.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
	if ([[NSSet setWithObjects:@"sourceText", @"tidyText", @"errorArray", nil] member:key])
	{
		// Handle the items above.
		[self setValue:obj forKey:[NSString stringWithFormat:@"%@", key]];
	}
	else
	{
		// Hopefully it's a tidyOption.
		[[self.tidyOptions objectForKey:key] setValue:obj forKey:@"optionValue"];
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
	
	[self processTidyInThread];
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
	
	if ((testText = [[NSString alloc] initWithData:data encoding:self.inputEncoding] ))
	{
		_sourceText = testText;
	}
	else
	{
		_sourceText = @"";
	}
	
	_sourceDidChange = NO;

	[self notifyTidyModelSourceTextChanged];
	[self processTidyInThread];

	/* Sanity check the input-encoding */
	NSStringEncoding suggestedEncoding = [self checkSourceCoding:data];

	if (suggestedEncoding != self.inputEncoding)
	{
		[self notifyTidyModelDetectedInputEncodingIssue:suggestedEncoding];
	}
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

/// @todo why would I want to set TidyText?
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
	return [[self tidyText] dataUsingEncoding:self.outputEncoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	tidyTextToFile
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
	errorArray
		Read the error array.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)errorArray
{
	return (NSArray *)_errorArray;
}


#pragma mark - Options Management


#pragma mark - Options Management - Class Methods

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
	static NSMutableArray *theArray = nil;							// Just do this once.
	
	if (!theArray)
	{
		theArray         = [[NSMutableArray alloc] init];			// Create an array.
		
		TidyDoc dummyDoc = tidyCreate();							// Create a dummy document (we're a CLASS method).
		
		TidyIterator i   = tidyGetOptionList( dummyDoc );			// Set up an iterator.
		
		while ( i )
		{
			TidyOption topt = tidyGetNextOption( dummyDoc, &i );	// Get an option.
			
			[theArray addObject:@(tidyOptGetName( topt ))];			// Add the name to the array
		}
		tidyRelease(dummyDoc);										// Release the dummy document.
	}
	
	return theArray;												// Return the array of results.
}


#pragma mark - Options Management - Instance Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsCopyFromModel
		Copies all options from theDocument into our tidyOptions.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsCopyFromModel:(JSDTidyModel *)theModel
{
	_tidyOptions = [[theModel tidyOptions] copy];

	[self notifyTidyModelOptionChanged:nil];

	[self processTidyInThread];
	
	[self fixSourceCoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsCopyFromDictionary
		Copies all options from theDictionary into our tidyOptions.
		Key is the option name and the value is the value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsCopyFromDictionary:(NSDictionary *)theDictionary
{
	NSString *localVal;
	
	for (NSString *key in [self.tidyOptions allKeys])
	{
		if ((localVal = [theDictionary valueForKey:key]))
		{
			JSDTidyOption *optionRef = self.tidyOptions[key];
			optionRef.optionValue = localVal;
		}
	}

	[self notifyTidyModelOptionChanged:nil];

	[self processTidyInThread];
	
	[self fixSourceCoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsResetAllToBuiltInDefaults
		Resets all options to factory default.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsResetAllToBuiltInDefaults
{
	for (NSString *key in [self.tidyOptions allKeys])
	{
		NSString *newValue = [self.tidyOptions[key] valueForKey:@"builtInDefaultValue"];
		
		[self.tidyOptions[key] setString:newValue forKey:@"optionValue"];
	}
	
	[self notifyTidyModelOptionChanged:nil];

	[self processTidyInThread];
	
	[self fixSourceCoding];
}


#pragma mark - Options Management - Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	> optionsInEffect
		If set, only options in the array will normally be used.
		Options not in the array won't have values set or read,
		and will maintain their default values. If set to nil,
		then all built-in options will be used.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionsInEffect:(NSArray *)options
{
	_optionsInEffect = options;
	for (NSString *key in [self.tidyOptions allKeys])
	{
		if (_optionsInEffect)
		{
			[self.tidyOptions[key] setValue:@([_optionsInEffect indexOfObject:key] == NSNotFound) forKey:@"optionIsSuppressed"];
		}
		else
		{
			[self.tidyOptions[key] setValue:@(NO) forKey:@"optionIsSuppressed"];
		}
	}
}


#pragma mark - Options Management - Private Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionsPopulateTidyOptions (private)
		Builds the tidyOptions dictionary structure using all of
		TidyLib's available options.
	@todo do I ever really need to access the optionID index?
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsPopulateTidyOptions
{
	NSArray *optionsList = [[self class] optionsBuiltInOptionList];
		
	for (NSString *tmpStr in optionsList)
	{
		JSDTidyOption *newOption = [[JSDTidyOption alloc] initWithName:tmpStr sharingModel:self];
		
		if (!(TidyUnknownOption == [newOption optionId]))
		{
			[self.tidyOptions setValue:newOption forKey:newOption.name];
		}
	}
}


#pragma mark - Diagnostics and Repair



/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 processTidyInThread (private)
		 Performs tidy'ing and sets _tidyText and _errorText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)processTidyInThread
{
//	dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//	dispatch_async(myQueue, ^{
		[self processTidy];
//	});
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 processTidy (private)
		 Performs tidy'ing and sets _tidyText and _errorText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)processTidy
{
	// Create a TidyDoc and sets its options.
	TidyDoc newTidy = tidyCreate();
	
	for (NSString *key in [self.tidyOptions allKeys])
	{
		[self.tidyOptions[key] applyOptionToTidyDoc:newTidy];
	}
	
	
	// Setup the |outBuffer| to copy to an NSString instead of writing to stdout
	TidyBuffer *outBuffer = malloc(sizeof(TidyBuffer));
	tidyBufInit( outBuffer );
	

	/*
		Setup for using and out-of-class C function as a callback
		from TidyLib in order to collect cleanup and diagnostic
		information. The C function is defined near the top of
		this file.
	 */

	tidySetAppData( newTidy, (__bridge void *)(self) );						// Need to send a message from outside self to self.

	/* 
		This version maintains compatability with NATIVE TidyLib.
		I'll maintain this in source code just in case forks want
		to stick to original TidyLib distributions.
	 */
	//tidySetReportFilter( newTidy, (TidyReportFilter)&tidyCallbackFilter);

	/*
		This version uses my modification to TidyLib allowing for
		localization of the error strings. 
	 */
	tidySetReportFilter2( newTidy, (TidyReportFilter2)&tidyCallbackFilter2);

	
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
	tidyParseString( newTidy, [_sourceText UTF8String] );
	tidyCleanAndRepair( newTidy );
	tidyRunDiagnostics( newTidy );
	
	
	// Save the tidy'd text to an NSString. If the Tidy result
	// is different than the existing Tidy text, then save
	// the new result and post a notification.
	// In any case post an error update notification so
	// that apps have a chance to update their error tables.
	// This covers a case where the source text may change but
	// the TidyText stays identical anyway.
	tidySaveBuffer( newTidy, outBuffer );

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
		[self setTidyText:tidyResult];
		[self notifyTidyModelTidyTextChanged];
	}

	[self notifyTidyModelMessagesChanged];

	
	// Give the Tidy general info at the end of the
	// _errorText. Note that this information is
	// NOT captured in the error filter.
	tidyErrorSummary( newTidy );
	tidyGeneralInfo( newTidy );
	
	
	// Copy the error buffer into an NSString -- the |_errorArray| is built using
	// callbacks so we don't need to do anything at all to build it right here.
	if (errBuffer->size > 0)
	{
		_errorText = [[NSString alloc] initWithUTF8String:(char *)errBuffer->bp];
	}
	else
	{
		_errorText = @"";
	}
	
	
	// Set ivars for properties.
	_tidyDetectedHtmlVersion = tidyDetectedHtmlVersion( newTidy );
	_tidyDetectedXhtml       = tidyDetectedXhtml( newTidy );
	_tidyDetectedGenericXml  = tidyDetectedGenericXml( newTidy );
	_tidyStatus              = tidyStatus( newTidy );
	_tidyErrorCount          = tidyErrorCount( newTidy );
	_tidyWarningCount        = tidyWarningCount( newTidy );
	_tidyAccessWarningCount  = tidyAccessWarningCount( newTidy );

	
	// Clean up.
	tidyBufFree(outBuffer);
	tidyBufFree(errBuffer);
	tidyRelease(newTidy);
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
	errorFilterWithLocalization:Level:Line:Column:Message:Arguments
		This is the REAL TidyError filter, and is called by the
		standard C |tidyCallBackFilter2| function implemented at the
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
	__strong NSMutableDictionary *errorDict = [[NSMutableDictionary alloc] init];

	NSString *formatString = NSLocalizedStringFromTable(@(mssg), @"JSDTidyModel", nil);
	NSString *intermediateString = [[NSString alloc] initWithFormat:formatString arguments:args];
	NSString *messageString = NSLocalizedStringFromTable(intermediateString, @"JSDTidyModel", nil);

	errorDict[@"level"]   = @((int)lvl);	// lvl is a c enum
	errorDict[@"line"]    = @(line);
	errorDict[@"column"]  = @(col);
	errorDict[@"message"] = messageString;

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
	 notifyTidyModelDetectedInputEncodingIssue (private)
		 Fires notification and performs delegation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelDetectedInputEncodingIssue:(NSStringEncoding)suggestedEncoding;
{
	NSDictionary *userData = @{@"currentEncoding"   : @(self.inputEncoding),
							   @"suggestedEncoding" : @(suggestedEncoding)};

	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyPossibleInputEncodingProblem object:self userInfo:userData];

	if ([[self delegate] respondsToSelector:@selector(tidyModelDetectedInputEncodingIssue:currentEncoding:suggestedEncoding:)])
	{
		[[self delegate] tidyModelDetectedInputEncodingIssue:self currentEncoding:self.inputEncoding suggestedEncoding:suggestedEncoding];
	}
}




#pragma mark - Configuration List Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	loadConfigurationListFromResource:ofType (class method)
		Returns an array of NSString from a file-resource. This
		compares each item with the linked-in TidyLib to ensure 
		items are supported, and ensures there are no duplicates.
		There is nothing in JSDTidyModel that uses this except
		for the optional defaults system support below, and it aids
		support of Balthisar Tidy's preferences implementation.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)loadConfigurationListFromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	NSMutableArray *desiredOptions = [[NSMutableArray alloc] init];
	
	NSString *contentPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
	
	if (contentPath)
	{
		NSString *tmpStr;
		NSEnumerator *enumerator = [[[NSString stringWithContentsOfFile:contentPath
															   encoding:NSUTF8StringEncoding
																  error:NULL]
									 componentsSeparatedByString:@"\n"] objectEnumerator];
		
		while (tmpStr = [enumerator nextObject])
		{
			if ((tidyOptGetIdForName( [tmpStr UTF8String] ) != N_TIDY_OPTIONS) && (![desiredOptions containsObject:tmpStr]))
			{
				[desiredOptions addObject:tmpStr];
			}
		}
	}
	return desiredOptions;
}


#pragma mark - Mac OS X Prefs Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary (class method)
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
	addDefaultsToDictionary:fromResource:ofType (class method)
		Same as |addDefaultsToDictionary|, except uses a resource
		file list of options instead of ALL TidyLib options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
				   fromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	[[self class] addDefaultsToDictionary:defaultDictionary fromArray:[JSDTidyModel loadConfigurationListFromResource:fileName ofType:fileType]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	addDefaultsToDictionary:fromArray (class method)
		Same as |addDefaultsToDictionary|, except uses an array
		of strings instead of ALL TidyLib options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
					  fromArray:(NSArray *)stringArray
{
	NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] init];
	
	for (NSString *optionName in stringArray)
	{
		optionsDict[optionName] = [[[JSDTidyOption alloc] initWithName:optionName sharingModel:nil] builtInDefaultValue];
	}
	
	defaultDictionary[JSDKeyTidyTidyOptionsKey] = optionsDict;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	writeOptionValuesWithDefaults
		Iterates through all of the current `tidyOptions` and
		registers their values to the defaults system.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)writeOptionValuesWithDefaults:(NSUserDefaults *)defaults
{
	NSMutableDictionary *optionsDict = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in [self.tidyOptions allKeys])
	{
		JSDTidyOption *optionRef = self.tidyOptions[key];
		optionsDict[key] = optionRef.optionValue;
	}
	
	[defaults setObject:optionsDict forKey:JSDKeyTidyTidyOptionsKey];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	takeOptionValuesFromDefaults
		Given a defaults instance, attempts to set optionValue for
		each tidyOptions item from the value registered int the
		defaults system.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)takeOptionValuesFromDefaults:(NSUserDefaults *)defaults
{
	for (NSString *optionName in [[self class] optionsBuiltInOptionList])
	{
		NSString *myString = [[defaults objectForKey:JSDKeyTidyTidyOptionsKey] stringForKey:optionName];

		[self.tidyOptions[optionName] setOptionValue:[myString copy]];
	}

	[self notifyTidyModelOptionChanged:nil];
	
	[self processTidyInThread];
}

@end
