/**************************************************************************************************
 
	JSDTidyOption.h

	Provides most of the options-related services to JSDTidyModel.


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

#import "JSDTidyOption.h"
#import "buffio.h"
#import "config.h"

@class JSDTidyModel;

#pragma mark - IMPLEMENTATION


@implementation JSDTidyOption


#pragma mark - iVar Synthesis


@synthesize optionValue = _optionValue;


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initSharingModel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initSharingModel:(JSDTidyModel *)sharedTidyModel
{
	if (self = [super init])
	{
		_sharedTidyModel = sharedTidyModel;
		_name            = @"undefined";
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithName:sharingModel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithName:(NSString *)name
	  sharingModel:(JSDTidyModel *)sharedTidyModel
{
	if (self = [super init])
	{
		_sharedTidyModel = sharedTidyModel;
		_name            = name;
		
		if ((TidyUnknownOption == self.optionId) || ( N_TIDY_OPTIONS == self.optionId))
		{
			_name = @"undefined";
		}
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	initWithName:optionValue:sharingModel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)initWithName:(NSString *)name
	   optionValue:(NSString *)value
	  sharingModel:(JSDTidyModel *)sharedTidyModel
{
	if (self = [super init])
	{
		_sharedTidyModel = sharedTidyModel;
		_name            = name;
		
		if (TidyUnknownOption == self.optionId)
		{
			_name = @"undefined";
		}
		else
		{
			self.optionValue = value;
		}
	}
	return self;
}


#pragma mark - Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	> setOptionValue
		Sets the optionValue, and intercepts special circumstances.
		Note that you must always ensure the encoding option values
		always contain the NSStringEncoding value, and not the
		localized name.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionValue:(NSString *)optionValue
{
	if ((!self.optionIsReadOnly) && (!self.optionIsSuppressed))
	{
		if ( self.optionIsEncodingOption)
		{
			if (self.optionId == TidyCharEncoding)
			{
				[self.sharedTidyModel setValue:optionValue forKeyPath:@"tidyOptions.input-encoding.optionValue"];
				
				[self.sharedTidyModel setValue:optionValue forKeyPath:@"tidyOptions.output-encoding.optionValue"];
			}
			
			if (self.optionId == TidyInCharEncoding)
			{
				_optionValue = optionValue;
				// Reserved in case we want special action here
			}
			
			if (self.optionId == TidyOutCharEncoding)
			{
				_optionValue = optionValue;
				// Reserved in case we want special action here
			}
		}
		else
		{
			_optionValue = optionValue;
		}

		
		[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyOptionChanged object:self.sharedTidyModel];

		if ([self.sharedTidyModel.delegate respondsToSelector:@selector(tidyModelOptionChanged:option:)])
		{
			[self.sharedTidyModel.delegate tidyModelOptionChanged:self.sharedTidyModel option:self];
		}
	}
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	< optionValue
		If the current value is nil, then ensure we return the
		built-in default value instead.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)optionValue
{
	if (!_optionValue)
	{
		return [self builtInDefaultValue];
	}
	else
	{
		return _optionValue;
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	> setOptionUIValue
		Sets option values using values from the user-interface
		instead of setting the TidyLib TidyOption values directly.
		Most TidyOptions have the same UI value and native value,
		but `doctype` and the encoding options require some
		special treatment. 
 
		If you're building a UI for TidyLib, then you can set the
		UI value directly, and the correct optionValue will be set.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setOptionUIValue:(NSString *)optionValue
{
	if ((!self.optionIsReadOnly) && (!self.optionIsSuppressed))
	{
		if ( self.optionIsEncodingOption)
		{
			// We have the alphabetical index, but need to find the NSStringEncoding.
			// The real optionValue will be the NSString encoding.
			NSString *tmp = [JSDTidyModel availableEncodingDictionariesByLocalizedIndex][@([optionValue integerValue])][@"NSStringEncoding"];
			
			// For some reason Objective-C wants to convert this to __NSCFNumber.
			// It probably has something to do with properties. This keeps it as string.
			[self setValue:[NSString stringWithFormat:@"%@", tmp] forKey:@"optionValue"];
		}
		else if ( [self.name isEqualToString:@"doctype"] )
		{
			// We have the index value from the menu, but we require a string value
			// for this option. The real optionValue will be the string value.
			[self setValue:self.possibleOptionValues[[optionValue integerValue]] forKey:@"optionValue"];
		}
		else
		{
			// Everything else is okay.
			[self setValue:optionValue forKey:@"optionValue"];
		}
	}
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	< optionUIValue
		Gets option values suitable for use in user-interfaces.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)optionUIValue
{
	if ( self.optionIsEncodingOption )
	{
		// Our value is an NSStringEncoding, but we want to return
		// the menu index in the current locale.
		return [JSDTidyModel availableEncodingDictionariesByNSStringEncoding][@([self.optionValue integerValue])][@"LocalizedIndex"];
	}
	else if ( [self.name isEqualToString:@"doctype"] )
	{
		// If we're working with doctype we need the index value, not the string value.
		return [NSString stringWithFormat:@"%lu", [self.possibleOptionValues indexOfObject:self.optionValue]];
	}
	else
	{
		// Everything else is okay.
		return self.optionValue;
	}
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	defaultOptionValue
		Returns the default option value from the Cocoa preferences
		system. We're doing a little bit of cheating by counting
		on the use of the constant defined in the JSDTidyModel
		class.
 
		If no Cocoa preference is available, then the built-in
		value will be returned instead.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)defaultOptionValue
{
	NSString *cocoaDefault = [[[NSUserDefaults standardUserDefaults] objectForKey:JSDKeyTidyTidyOptionsKey] stringForKey:self.name];
	
	if (cocoaDefault)
	{
		return cocoaDefault;
	}
	else
	{
		return self.builtInDefaultValue;
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	possibleOptionValues
		Returns an array of strings consisting of the possible
		option values for this TidyOption.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray*)possibleOptionValues
{
	/*
		Check for items that should NOT return their built-in
	    list of possible option values.
	 */
/*	if ([[NSSet setWithObjects:@"doctype", nil] member:self.name])
	{
		return [[NSArray alloc] initWithObjects:nil];
	}
*/	
	
	NSMutableArray *theArray = [[NSMutableArray alloc] init];
	
	if (self.optionIsEncodingOption)
	{
		return [JSDTidyModel allAvailableEncodingLocalizedNames];
	}
	else
	{
		TidyOption tidyOptionInstance = [self createTidyOptionInstance:self.optionId];
		
		TidyIterator i = tidyOptGetPickList( tidyOptionInstance );

		while ( i )
		{
			[theArray addObject:@(tidyOptGetNextPick(tidyOptionInstance, &i))];
		}
		
		// Special treatment for `doctype`
		if (([self.name isEqual: @"doctype"]) && ([theArray count] > 0))
		{
			[theArray removeLastObject];
		}
	}
	
	return theArray;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionIsReadOnly
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)optionIsReadOnly
{
	return tidyOptIsReadOnly([self createTidyOptionInstance:self.optionId]);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	localizedHumanReadableName
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)localizedHumanReadableName
{
	return NSLocalizedString(([NSString stringWithFormat:@"tag-%@", self.name]), nil);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	localizedHumanReadableDescription
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSAttributedString*)localizedHumanReadableDescription
{
	// parentheses around brackets required lest preprocessor get confused.
	NSString *rawString = NSLocalizedString(([NSString stringWithFormat:@"description-%@", self.name]), nil);
	
	NSAttributedString *outString;
	
	/*
		RTF can be a little complex due to legacy string encoding issues.
		When JSDTidy is internationalized, RTF might not play nicely with
		non-Mac character encodings. Prefixing the .plist strings with an
		asterisk will cause the automatic conversion to and from RTF,
		otherwise the strings will be treated normally (this maintains
		string compatability with `NSLocalizedString`).
	 */
	if ([rawString hasPrefix:@"*"])
	{
		// Make into RTF string.
		rawString = [[@"{\\rtf1\\mac\\deff0{\\fonttbl{\\f0 Consolas;}{\\f1 Lucida Grande;}}\\f1\\fs22\\qj\\sa100" stringByAppendingString:[rawString substringFromIndex:1]] stringByAppendingString:@"}"];

		NSData *rawData = [rawString dataUsingEncoding:NSMacOSRomanStringEncoding];

		outString = [[NSAttributedString alloc] initWithRTF:rawData documentAttributes:nil];
	}
	else
	{
		// Use the string as-is.
		outString = [[NSAttributedString alloc] initWithString:rawString];
	}
	
	return outString;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	localizedHumanReadableCategory
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)localizedHumanReadableCategory
{
	TidyConfigCategory temp = tidyOptGetCategory( [self createTidyOptionInstance:self.optionId] );
	return NSLocalizedString(([NSString stringWithFormat:@"category-%u", temp]), nil);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 optionId
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (TidyOptionId)optionId
{
	TidyOptionId optID = tidyOptGetIdForName( [[self name] UTF8String] );
	
	if (optID < N_TIDY_OPTIONS)
	{
		return optID;
	}
	
	return TidyUnknownOption;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 optionType
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (TidyOptionType)optionType
{
	return tidyOptGetType( [self createTidyOptionInstance:self.optionId] );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	builtInDefaultValue
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)builtInDefaultValue
{
	// ENCODING OPTIONS -- special case, so handle first.
	if (self.optionIsEncodingOption)
	{
		if (self.optionId == TidyCharEncoding)
		{
			return [NSString stringWithFormat:@"%u", tidyDefaultInputEncoding];
		}
		
		if (self.optionId == TidyInCharEncoding)
		{
			return [NSString stringWithFormat:@"%u", tidyDefaultInputEncoding];
		}
		
		if (self.optionId == TidyOutCharEncoding)
		{
			return [NSString stringWithFormat:@"%u", tidyDefaultOutputEncoding];
		}
	}
	
	
	TidyOption tidyOptionInstance = [self createTidyOptionInstance:self.optionId];

	TidyOptionType optType        = tidyOptGetType( tidyOptionInstance );
	
	
	if (optType == TidyString)
	{
		ctmbstr tmp = tidyOptGetDefault( tidyOptionInstance );
		return ( (tmp != nil) ? @(tmp) : @"" );
	}
	
	if (optType == TidyBoolean)
	{
		return [NSString stringWithFormat:@"%u", tidyOptGetDefaultBool( tidyOptionInstance )];
	}
	
	if (optType == TidyInteger)
	{
		return [NSString stringWithFormat:@"%lu", tidyOptGetDefaultInt( tidyOptionInstance )];
	}
	
	return @"";
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	builtInDescription
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)builtInDescription
{
	NSString *tidyResultString;

	TidyDoc dummyDoc              = tidyCreate();
	
	const char *tidyResultCString = tidyOptGetDoc(dummyDoc, tidyGetOption(dummyDoc, self.optionId));
	
	
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
	builtInCategory
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (TidyConfigCategory)builtInCategory
{
	return tidyOptGetCategory( [self createTidyOptionInstance:self.optionId] );
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionIsSuppressed
		The implementing application may want to suppress certain
		built-in TidyLib options. Setting this to true will hide
		instances of this option from most operations.
 
		This method is implemented automatically by compiler.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionIsEncodingOption
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)optionIsEncodingOption
{
	return ((self.optionId == TidyCharEncoding) ||
			(self.optionId == TidyInCharEncoding) ||
			(self.optionId == TidyOutCharEncoding));
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionCanAcceptNULLSTR
		Some TidyLib options can have a NULLSTR value, but they can't
		accept a NULLSTR assignment. This convenience property flags
		the condition.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)optionCanAcceptNULLSTR
{
	return ([[NSSet setWithObjects:@"doctype", @"slide-style", @"language", @"css-prefix", nil] member:self.name]) == nil;
}


#pragma mark - Public Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	applyOptionToTidyDoc
		Given a TidyDoc instance, apply our setting to the TidyDoc.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)applyOptionToTidyDoc:(TidyDoc)destinationTidyDoc
{
	if (self.optionIsEncodingOption)
	{
		// Force TidyLib to use UTF8 internally. Mac OS X will handle
		// file encoding and file input-output.
		return tidyOptSetValue(destinationTidyDoc, self.optionId, [@"utf8" UTF8String]);
	}
	
	if ((!self.optionIsSuppressed) && (!self.optionIsReadOnly))
	{
		if ( self.optionType == TidyString)
		{
			if ([self.optionValue length] == 0)
			{
				 // Some tidy options can't accept NULLSTR but can be reset to default
				 // NULLSTR. Some, though require a NULLSTR and resetting to default
				 // doesn't work. WTF?
				if (!self.optionCanAcceptNULLSTR)
				{
					return tidyOptResetToDefault( destinationTidyDoc, self.optionId );
				}
				else
				{
					return tidyOptSetValue(destinationTidyDoc, self.optionId, NULLSTR);
				}
			}
			else
			{
				return tidyOptSetValue( destinationTidyDoc, self.optionId, [self.optionValue UTF8String] );
			}
		}
		
		if ( self.optionType == TidyInteger)
		{
			return tidyOptSetInt( destinationTidyDoc, self.optionId, [self.optionValue integerValue] );
		}
		
		if ( self.optionType == TidyBoolean)
		{
			return tidyOptSetBool( destinationTidyDoc, self.optionId, [self.optionValue boolValue] );
		}
	}
	return YES;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionUIValueIncrement
		Increments the current option value to the next option value
		in UI order. There's either a picklist, or there's not.
		If there's a picklist, then we cycle through the picklist
		values. If there's not a picklist, then if it's TidyInteger
		we will allow changes and not allow values less than 0.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionUIValueIncrement
{
	[self optionUIValueAdjust:+1];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionUIValueDecrement
		Increments the current option value to the next option value
		in UI order. There's either a picklist, or there's not.
		If there's a picklist, then we cycle through the picklist
		values. If there's not a picklist, then if it's TidyInteger
		we will allow changes and not allow values less than 0.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionUIValueDecrement
{
	[self optionUIValueAdjust:-1];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	optionUIValueAdjust: (private)
		Increments the current option value to the next option value
		in UI order. There's either a picklist, or there's not.
		If there's a picklist, then we cycle through the picklist
		values. If there's not a picklist, then if it's TidyInteger
		we will allow changes and not allow values less than 0.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)optionUIValueAdjust:(NSInteger)byAmount
{
	NSInteger lastIndex = self.possibleOptionValues.count - 1;
	NSInteger newPick;

	if (lastIndex > 0)
	{
		// There *is* a picklist, so advance it.

		newPick = [self.optionUIValue integerValue] + byAmount;

		if (newPick > lastIndex)
		{
			newPick = 0;
		}

		if (newPick < 0)
		{
			newPick = lastIndex;
		}

		self.optionUIValue = [NSString stringWithFormat:@"%ld", (long)newPick];
	}
	else
	{
		// There is no picklist, but if it's an integer, then increment its value.
		if (self.optionType == TidyInteger)
		{
			newPick = [self.optionValue integerValue] + byAmount;

			if (newPick < 0)
			{
				newPick = SHRT_MAX;
			}

			if (newPick > SHRT_MAX)
			{
				newPick = 0;
			}

			self.optionValue = [NSString stringWithFormat:@"%ld", newPick];
		}
	}
}



#pragma mark - Private


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	createTidyOptionInstance
		Given an option id, return an instance of a tidy option.
		This is required because many of the TidyLib functions
		require an instance in order to return data.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (TidyOption)createTidyOptionInstance:(TidyOptionId)idf
{
	TidyDoc dummyDoc  = tidyCreate();
	
	TidyOption result = tidyGetOption( dummyDoc, idf);
	
	tidyRelease(dummyDoc);
	
	return result;
}


@end
