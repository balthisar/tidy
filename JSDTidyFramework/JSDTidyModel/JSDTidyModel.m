/**************************************************************************************************

	JSDTidyModel

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDTidyModel.h"

#import "JSDTidyCommonHeaders.h"
#import "JSDTidyOption.h"
#import "JSDTidyMessage.h"

#import "config.h"             // from HTML Tidy
#import "SWFSemanticVersion.h" // for version checking.


#pragma mark - CATEGORY JSDTidyModel ()


@interface JSDTidyModel ()

/* Redefinitions for private read-write access. */

@property (readwrite) NSMutableArray *errorArray;

@property (readwrite) NSString *errorText;

@property (readwrite) NSString *tidyText;

@property (readwrite) NSDictionary *tidyOptions;


/* Private properties. */

@property (nonatomic, strong) NSMutableArray *errorArrayB;        // Internal error array.

@property (nonatomic, strong) NSMutableDictionary * errorImages;  // Dictionary of error images.

@property (nonatomic, strong) NSData *originalData;               // The original data loaded from a file.

@property (nonatomic, strong) NSArray *tidyOptionHeaders;         // Holds fake options that can be used as headers.

@property (nonatomic, assign) BOOL sourceDidChange;               // Indicates whether _sourceText has changed.

@end


#pragma mark - IMPLEMENTATION


@implementation JSDTidyModel

#pragma mark - iVar Synthesis

@synthesize optionsInUse	= _optionsInUse;


#pragma mark - Standard C Functions

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
    tidyCallbackFilter2 (regular C-function)
      In order to support libtidy's callback function for
      building an error list on the fly, we need to set up
      this standard C function to handle the callback.

      `tidyGetAppData` result will already contain a reference to
      `self` that we set via `tidySetAppData` during processing.
      Essentially we're calling
      [self errorFilter:Level:Line:Column:Message]
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

BOOL tidyCallbackFilter2 ( TidyDoc tdoc, TidyReportLevel lvl, uint line, uint col, ctmbstr mssg, va_list args )
{
	return [(__bridge JSDTidyModel*)tidyGetAppData(tdoc) errorFilterWithLocalization:tdoc Level:lvl Line:line Column:col Message:mssg Arguments:args];
}


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - init
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
		_tidyOptions       = [[NSDictionary alloc] init];
		_tidyOptionHeaders = [[NSArray alloc] init];
		_errorArray        = [[NSMutableArray alloc] init];
		_errorArrayB       = nil;
		_errorImages       = [[NSMutableDictionary alloc] init];

		[self optionsPopulateTidyOptions];
	}
			
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithString:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithString:(NSString *)sourceText
{
	if (self = [self init])
	{
		self.sourceText = sourceText;
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithString:copyOptionValuesFromModel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithString:(NSString *)sourceText copyOptionValuesFromModel:(JSDTidyModel *)theModel
{
	if (self = [self init])
	{
		[self optionsCopyValuesFromModel:theModel];
		self.sourceText = sourceText;
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithData:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithData:(NSData *)data
{
	if (self = [self init])
	{
		[self setSourceTextWithData:data];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithData:copyOptionValuesFromModel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithData:(NSData *)data copyOptionValuesFromModel:(JSDTidyModel *)theModel
{
	if (self = [self init])
	{
		[self optionsCopyValuesFromModel:theModel];
		[self setSourceTextWithData:data];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithFile:(NSString *)path
{
	if (self = [self init])
	{
		[self setSourceTextWithFile:path];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithFile:copyOptionValuesFromModel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithFile:(NSString *)path copyOptionValuesFromModel:(JSDTidyModel *)theModel
{
	if (self = [self init])
	{
		[self optionsCopyValuesFromModel:theModel];
		[self setSourceTextWithFile:path];
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 + accessInstanceVariablesDirectly
	Ensure that we keep Cocoa from direct access to our ivars.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+(BOOL)accessInstanceVariablesDirectly
{
	return NO;
}


#pragma mark - String Encoding Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property inputEncoding
    Shortuct to expose the input-encoding value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)inputEncoding
{
	JSDTidyOption *localOption = self.tidyOptions[@"input-encoding"];

	return [localOption.optionValue integerValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property outputEncoding
    Shortuct to expose the output-encoding value.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSStringEncoding)outputEncoding
{
	JSDTidyOption *localOption = self.tidyOptions[@"output-encoding"];

	return [localOption.optionValue integerValue];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - checkSourceCoding: (private)
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
  - fixSourceCoding (private)
    Repairs the character encoding whenever the `input-encoding`
    has changed. If the source never changed and we have original
    data present, then setting _sourceText with the orginal
    data will cause Tidy to use the new input-encoding.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)fixSourceCoding
{
	if (self.originalData && !self.sourceDidChange)
	{
		[self setSourceTextWithData:self.originalData];
	}
}


#pragma mark - Text


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property sourceText:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setSourceText:(NSString *)value
{
	_sourceText = [self normalizeLineEndings:value];
	
	if (!self.originalData)
	{
		/* 
			If this is a fresh instance, then self.originalData will
			be nil, so we can store an original copy of the string
			as NSData. Unlike with the file- and data-based
			setters, this is a one time event since presumably
			setting via NSString may happen repeatedly, such as
			with text editors.
		*/
				
		self.originalData = [[NSData alloc] initWithData:[self.sourceText dataUsingEncoding:self.outputEncoding]];
		
		self.sourceDidChange = NO;
		
		/*
			This is the only circumstance in which we will ever
			fire a tidyNotifySourceTextChanged notification
			while setting the source text as a string. NOTE THAT
		    KVO WILL STILL FIRE.
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
		
		self.sourceDidChange = YES;
	}
	
	[self processTidy];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - setSourceTextWithData:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setSourceTextWithData:(NSData *)data
{
	if (data != self.originalData)
	{
		/*
			Unlike with setting via NSString, the presumption for file-
			and data-based setters is that this is a one-time occurrence,
			and so `self.originalData` will be overwritten. This supports
			the use of JSDTidyFramework in a text editor so: 
		    the `self.originalData` is set only once; text changes set
		    via NSString will not overwrite the original data.
		*/
		
		self.originalData = [[NSData alloc] initWithData:data];
	}
	
	/*
		It's possible that the _inputEncoding (chosen by the user) is
		incorrect. We will honor the user's choice anyway, but set
		the source text to an empty string if NSString is unable to
		decode the string with the user's preference.
	*/
	
	NSMutableString *testText = nil;

	[self willChangeValueForKey:@"sourceText"];

	if ((testText = [[NSMutableString alloc] initWithData:data encoding:self.inputEncoding] ))
	{
		_sourceText = [self normalizeLineEndings:testText];
	}
	else
	{
		_sourceText = @"";
	}

	/* Sanity check the input-encoding */
	NSStringEncoding suggestedEncoding = [self checkSourceCoding:data];

	if (suggestedEncoding != self.inputEncoding)
	{
		[self notifyTidyModelDetectedInputEncodingIssue:suggestedEncoding];
	}

	self.sourceDidChange = NO;

	[self notifyTidyModelSourceTextRestored];
	[self notifyTidyModelSourceTextChanged];
	[self processTidy];
	[self didChangeValueForKey:@"sourceText"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - setSourceTextWithFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setSourceTextWithFile:(NSString *)path
{
	[self setSourceTextWithData:[NSData dataWithContentsOfFile:path]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property tidyTextAsData
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSData *)tidyTextAsData
{
	NSMutableString *testText = [[NSMutableString alloc] initWithString:self.tidyText];

	JSDTidyOption *localOption = self.tidyOptions[@"newline"];

	if ([localOption.optionConfigString isEqualToString:@"CR"])
	{
		[testText replaceOccurrencesOfString:@"\n" withString:@"\r" options:NSLiteralSearch range:NSMakeRange(0, [testText length])];
	}
	else if ([localOption.optionConfigString isEqualToString:@"CRLF"])
	{
		[testText replaceOccurrencesOfString:@"\n" withString:@"\r\n" options:NSLiteralSearch range:NSMakeRange(0, [testText length])];
	}

	return [testText dataUsingEncoding:self.outputEncoding];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - tidyTextToFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidyTextToFile:(NSString *)path
{
	[[self.tidyText dataUsingEncoding:self.outputEncoding] writeToFile:path atomically:YES];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property isDirty
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)isDirty
{
	return (self.sourceDidChange) || (![self.sourceText isEqualToString:self.tidyText]);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - normalizeLineEndings: (private)
		Ensure that we're using modern Mac OS X line endings,
		regardless of the source line endings. We will check for 
		`newline` upon file save.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)normalizeLineEndings:(NSString*)text
{
	NSMutableString *localText = [NSMutableString stringWithString:text];

	[localText replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [localText length])];

	[localText replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [localText length])];

	return localText;
}


#pragma mark - Options Overall Management


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + optionsBuiltInOptionCount (class)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (int)optionsBuiltInOptionCount
{
	return N_TIDY_OPTIONS;	// defined in config.c of libtidy
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + optionsBuiltInOptionList (class)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)optionsBuiltInOptionList
{
	static NSMutableArray *optionsArray = nil;
	
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

		tidyRelease(dummyDoc);
	}
	
	return optionsArray;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - optionsCopyValuesFromModel:
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
  - optionsCopyValuesFromDictionary:
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
  - optionsResetAllToBuiltInDefaults
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
  @property optionsInUse
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray*)optionsInUse
{
	if (!_optionsInUse)
	{
		return [[self class] optionsBuiltInOptionList];
	}

	return _optionsInUse;
}

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
  - optionsPopulateTidyOptions (private)
    Builds the tidyOptions dictionary structure using all of
    libtidy's available options.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionsPopulateTidyOptions
{
	[self willChangeValueForKey:@"tidyOptionsBindable"];

	NSArray *optionsList = [[self class] optionsBuiltInOptionList];
	
	NSMutableDictionary *localOptions = [[NSMutableDictionary alloc] init];
		
	for (NSString *optionName in optionsList)
	{
		JSDTidyOption *newOption = [[JSDTidyOption alloc] initWithName:optionName sharingModel:self];
		
		if (!([newOption optionId] == TidyUnknownOption))
		{
			[localOptions setValue:newOption forKey:newOption.name];
		}
	}
	
	self.tidyOptions = localOptions;

	[self optionsPopulateTidyOptionHeaders];

	[self didChangeValueForKey:@"tidyOptionsBindable"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - optionsPopulateTidyOptionHeaders (private)
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
	for (JSDTidyOption *localOption in [self.tidyOptions allValues])
	{
		if ( (!localOption.optionIsHeader) && (!localOption.optionIsSuppressed) )
		{
			/* Check to make sure localOption.builtInCategory isn't already in self.tidyOptionHeaders. */

			NSArray *unionOfCategories = [self.tidyOptionHeaders valueForKeyPath:@"@unionOfObjects.builtInCategory"];

			if (![unionOfCategories containsObject:@(localOption.builtInCategory)])
			{
				JSDTidyOption *headerOption = [[JSDTidyOption alloc] initWithName:localOption.name sharingModel:self];

				headerOption.optionIsHeader = YES;

				self.tidyOptionHeaders = [self.tidyOptionHeaders arrayByAddingObject:headerOption];
			}
		}
	}
}


#pragma mark - Diagnostics and Repair


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - processTidy (private)
    Processes the current `sourceText` into `tidyText`.
    This is action takes place in the background and works quite
    well for GUI applications that wait for notifications that
    `tidyText` has been changed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)processTidy
{
	/* Create a TidyDoc and sets its options. */

	TidyDoc newTidy = tidyCreate();

	/* Capture the array locally. */
	NSArray *localOptions = [[NSArray alloc] initWithArray:[self.tidyOptions allValues]];
	for (JSDTidyOption *localOption in localOptions)
	{
		[localOption applyOptionToTidyDoc:newTidy];
	}


	/* Setup the `outBuffer` to copy later to an NSString instead of writing to stdout */

	TidyBuffer *outBuffer = malloc(sizeof(TidyBuffer));
	tidyBufInit( outBuffer );


	/*
		Setup for using and out-of-class C function as a callback
		from libtidy in order to collect cleanup and diagnostic
		information. The C function is defined near the top of
		this file.
	 */
	tidySetAppData(newTidy, (__bridge void *)(self));                          // Need to send a message from outside self to self.

	tidySetReportFilter2(newTidy, (TidyReportFilter2)&tidyCallbackFilter2);


	/* Setup the error buffer to catch errors here instead of stdout */

	TidyBuffer *errBuffer = malloc(sizeof(TidyBuffer));                        // Allocate a buffer for our error text.
	tidyBufInit(errBuffer);                                                    // Init the buffer.
	tidySetErrorBuffer(newTidy, errBuffer);                                    // And let tidy know to use it.


	/* Clear out all of the previous errors from our collection. */

	self.errorArrayB = [[NSMutableArray alloc] init];


	/* Setup tidy to use UTF8 for all internal operations. */

	tidyOptSetValue(newTidy, TidyCharEncoding, [@"utf8" UTF8String]);
	tidyOptSetValue(newTidy, TidyInCharEncoding, [@"utf8" UTF8String]);
	tidyOptSetValue(newTidy, TidyOutCharEncoding, [@"utf8" UTF8String]);


	/* Parse the `_sourceText` and clean, repair, and diagnose it. */

	tidyParseString(newTidy, [self.sourceText UTF8String]);
	tidyCleanAndRepair(newTidy);
	tidyRunDiagnostics(newTidy);


	/*
		Write additional information to the error output sink.
		Note that this information is NOT captured in the error filter.
	 */
	tidyErrorSummary(newTidy);
	tidyGeneralInfo(newTidy);


	/* Set ivars for properties. */

	_tidyDetectedHtmlVersion = tidyDetectedHtmlVersion(newTidy);
	_tidyDetectedXhtml       = tidyDetectedXhtml(newTidy);
	_tidyDetectedGenericXml  = tidyDetectedGenericXml(newTidy);
	_tidyStatus              = tidyStatus(newTidy);
	_tidyErrorCount          = tidyErrorCount(newTidy);
	_tidyWarningCount        = tidyWarningCount(newTidy);
	_tidyAccessWarningCount  = tidyAccessWarningCount(newTidy);


	/* Copy the error buffer into an NSString. */

	if (errBuffer->size > 0)
	{
		self.errorText = [[NSString alloc] initWithUTF8String:(char *)errBuffer->bp];
	}
	else
	{
		self.errorText = @"";
	}


	/* Save the tidy'd text to an NSString. */

	NSString *tidyResult;

	tidySaveBuffer(newTidy, outBuffer);

	if (outBuffer->size > 0)
	{
		tidyResult = [[NSString alloc] initWithUTF8String:(char *)outBuffer->bp];
	}
	else
	{
		tidyResult = @"";
	}

	/* Clean up. */

	tidyBufFree(outBuffer);
	tidyBufFree(errBuffer);
	tidyRelease(newTidy);


	BOOL textDidChange = ![self.tidyText isEqualToString:tidyResult];

	if (textDidChange)
	{
		self.tidyText = tidyResult;
	}


	/*****************************************************
		Now do stuff that's likely to affect the UI.
	 *****************************************************/
	/* Only send notifications if the text changed. */
	if ( textDidChange )
	{
		[self willChangeValueForKey:@"tidyText"];
		[self didChangeValueForKey:@"tidyText"];
		[self notifyTidyModelTidyTextChanged];
	}

	/* Send messages changed notification if applicable. */
    if (![self.errorArray isEqualToArray:self.errorArrayB])
    {
		self.errorArray = self.errorArrayB;
        [self notifyTidyModelMessagesChanged];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - errorFilterWithLocalization:Level:Line:Column:Message:Arguments:
	This is the REAL TidyError filter, and is called by the
    standard C `tidyCallBackFilter2` function implemented at the
    top of this file.

    libtidy doesn't maintain a structured list of all of its
    errors so here we capture them one-by-one as Tidy tidy's.
    In this way we build our own structured list.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (bool)errorFilterWithLocalization:(TidyDoc)tDoc
							  Level:(TidyReportLevel)lvl
							   Line:(uint)line
							 Column:(uint)col
							Message:(ctmbstr)mssg
						  Arguments:(va_list)args
{
	JSDTidyMessage *message = [[JSDTidyMessage alloc] initWithLevel:lvl
															   Line:line
															 Column:col
															Message:mssg
														  Arguments:args];

	[self.errorArrayB addObject:message];

	return YES; // Always return yes otherwise self.errorText will be surpressed by libtidy.
}


#pragma mark - Miscelleneous


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property tidyReleaseDate
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyReleaseDate
{
	return @(tidyReleaseDate());
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property tidyLibraryVersion
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyLibraryVersion
{
	return @(tidyLibraryVersion());
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - tidyLibraryVersionAtLeast:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL) tidyLibraryVersionAtLeast:(NSString *)semanticVersion;
{
	SWFSemanticVersion *min = [SWFSemanticVersion semanticVersionWithString:semanticVersion];
	SWFSemanticVersion *current = [SWFSemanticVersion semanticVersionWithString:self.tidyLibraryVersion];
	
	return ([min compare:current] == NSOrderedSame || [min compare:current] == NSOrderedAscending);
}


#pragma mark - Configuration List Support


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + loadOptionsInUseListFromResource:ofType: (class method)
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
  + addDefaultsToDictionary: (class method)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
{
	[[self class] addDefaultsToDictionary:defaultDictionary fromArray:[[self class] optionsBuiltInOptionList]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + addDefaultsToDictionary:fromResource:ofType: (class method)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)addDefaultsToDictionary:(NSMutableDictionary *)defaultDictionary
				   fromResource:(NSString *)fileName ofType:(NSString *)fileType
{
	[[self class] addDefaultsToDictionary:defaultDictionary fromArray:[JSDTidyModel loadOptionsInUseListFromResource:fileName ofType:fileType]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + addDefaultsToDictionary:fromArray: (class method)
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
  - writeOptionValuesWithDefaults:
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
  - takeOptionValuesFromDefaults:
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


#pragma mark - Public API and General Properties


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property tidyOptionsBindable
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)tidyOptionsBindable
{
	return [[self.tidyOptions allValues] arrayByAddingObjectsFromArray:self.tidyOptionHeaders];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - tidyOptionsConfigFile
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)tidyOptionsConfigFile:(NSString*)baseFileName
{
	NSMutableString *result = [[NSMutableString alloc] init];

    if (!baseFileName)
    {
        baseFileName = @"example.cfg";
    }

	NSString *tempString = [NSString stringWithFormat:@"%@\n", JSDLocalizedString(@"export-byline", nil)];

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
 - notifyTidyModelOptionChanged: (private)
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
 - notifyTidyModelSourceTextChanged (private)
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
 - notifyTidyModelSourceTextRestored (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelSourceTextRestored
{
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifySourceTextRestored object:self];

	if ([[self delegate] respondsToSelector:@selector(tidyModelSourceTextRestored:text:)])
	{
		[[self delegate] tidyModelSourceTextRestored:self text:self.sourceText];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - notifyTidyModelTidyTextChanged (private)
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
 - notifyTidyModelMessagesChanged (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)notifyTidyModelMessagesChanged
{
    [self willChangeValueForKey:@"errorArray"];
    [self didChangeValueForKey:@"errorArray"];
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyErrorsChanged object:self];

	if ([[self delegate] respondsToSelector:@selector(tidyModelTidyMessagesChanged:messages:)])
	{
		[[self delegate] tidyModelTidyMessagesChanged:self messages:self.errorArray];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - notifyTidyModelDetectedInputEncodingIssue: (private)
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
