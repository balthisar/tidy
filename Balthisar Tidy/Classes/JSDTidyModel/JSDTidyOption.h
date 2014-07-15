/**************************************************************************************************
 
	JSDTidyOption

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

#import <Foundation/Foundation.h>
#import "config.h"   // from vendor/tidylib/src/


@class JSDTidyModel;

/*
	Instances of JSDTidyOption belong to a sharedTidyModel, but are largely self aware and
	handle most aspects of their operation on their own. They also provide good exposure
	to implementing user interfaces.
 
	The principle purpose is to hold and store options, and return information about options.
	There is some interactivity among options (e.g., where we override character encodings),
	but this is always mediated back through to the `sharedTidyModel`. Setting an instance of
	an option does not cause tidying per se; this is all managed by the JSDTidyModel, which
	receives notifications that an item has changed.
 */
@interface JSDTidyOption : NSObject


#pragma mark - Intializers

- (instancetype)initSharingModel:(JSDTidyModel *)sharedTidyModel;

- (instancetype)initWithName:(NSString *)name sharingModel:(JSDTidyModel *)sharedTidyModel;

- (instancetype)initWithName:(NSString *)name optionValue:(NSString *)value sharingModel:(JSDTidyModel *)sharedTidyModel;


#pragma mark - Main properties

@property (readonly)         NSString *name;                            // Built-in option name.

@property                    NSString *optionValue;                     // Current value of this option.

@property (readonly)         NSString *defaultOptionValue;              // Default value of this option (from user options).

@property (readonly)         NSArray *possibleOptionValues;             // Array of string values for possible option values.

@property (readonly)         BOOL optionIsReadOnly;                     // Indicates whether or not option is read-only.

@property (readonly)         NSString *localizedHumanReadableName;      // Localized, humanized name of the option.

@property (readonly)         NSAttributedString *localizedHumanReadableDescription; // Localized description of the option.

@property (readonly)         NSString *localizedHumanReadableCategory;  // Localized name of the option category.


#pragma mark - Properties useful for implementing user interfaces

@property                    NSString *optionUIValue;                   // Current value of this option used by UI's.

@property (readonly)         NSString *optionUIType;                    // Suggested UI type for setting options.

@property (readonly)         NSString *optionConfigString;              // Option suitable for use in a config file.


#pragma mark - Properties maintained for original TidyLib compatability (may be used internally)

@property (readonly)         TidyOptionId optionId;                     // Tidy's internal TidyOptionId for this option.

@property (readonly)         TidyOptionType optionType;                 // Actual type that TidyLib expects.

@property (readonly)         NSString *builtInDefaultValue;             // Tidy's built-in default value for this option.

@property (readonly)         NSString *builtInDescription;              // Tidy's built-in description for this option.

@property (readonly)         TidyConfigCategory builtInCategory;        // Tidy's built-in category for this option.


#pragma mark - Properties used mostly internally or for implementing user interfaces

@property (readonly, assign) JSDTidyModel *sharedTidyModel;             // Model to which this option belongs.

@property (readonly, assign) BOOL optionCanAcceptNULLSTR;               // Indicates whether or not this option can accept NULLSTR.

@property (readonly, assign) BOOL optionIsEncodingOption;               // Indicates whether or not this option is an encoding option.

@property (assign)           BOOL optionIsHeader;                       // Fake option is only a header row for UI use.

@property (assign)           BOOL optionIsSuppressed;                   // Indicates whether or not this option is unused by JSDTidyModel.


#pragma mark - Other Public Methods

- (BOOL)applyOptionToTidyDoc:(TidyDoc)destinationTidyDoc;               // Applies this option to a TidyDoc instance.

- (void)optionUIValueIncrement;                                         // Possibly useful for UI's, increments to next possible option value.

- (void)optionUIValueDecrement;                                         // Possibly useful for UI's, decrements to next possible option value.

-(NSComparisonResult)tidyGroupedNameCompare:(JSDTidyOption *)tidyOption;	    // Comparitor for localized sorting and grouping of tidyOptions.

-(NSComparisonResult)tidyGroupedHumanNameCompare:(JSDTidyOption *)tidyOption;   // Comparitor for localized sorting and grouping of tidyOptions.


@end

