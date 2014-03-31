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

#import <Foundation/Foundation.h>
#import "JSDTidyModel.h"

//@class JSDTidyModel;

/**
	Instances of JSDTidyOption belong to a sharedTidyModel, but are largely self aware
	handle most aspects of their operation on their own. They also provide good exposure
	to implementing user interfaces.
 
	The priniciple purpose is to hold and store options, and return information about options.
	There is some interactivity among options (e.g., where we override character encodings),
	but this is always mediated back through to the `sharedTidyModel`. Setting an instance of
	an option does not cause tidying per se; this is all managed by the JSDTidyModel.
 */
@interface JSDTidyOption : NSObject

@property (nonatomic, assign, readonly) JSDTidyModel *sharedTidyModel;					///< Model to which this option belongs.

@property (nonatomic, strong)           NSString *optionValue;							///< Current value of this option.

@property (nonatomic, strong)			NSString *optionUIValue;						///< Current value of this option used by UI's.

@property (nonatomic, strong, readonly) NSString *name;									///< Built-in option name.

@property (nonatomic, strong, readonly) NSString *defaultOptionValue;					///< Default value of this option (from user options).

@property (nonatomic, strong, readonly) NSArray *possibleOptionValues;					///< Array of string values for possible option values.

@property (nonatomic, assign, readonly) BOOL optionIsReadOnly;							///< Indicates whether or not option is read-only.

@property (nonatomic, strong, readonly) NSString *localizedHumanReadableName;			///< Localized, humanized name of the option.

@property (nonatomic, strong, readonly) NSAttributedString *localizedHumanReadableDescription;	///< Localized description of the option.

@property (nonatomic, strong, readonly) NSString *localizedHumanReadableCategory;		///< Localized name of the option category.

@property (nonatomic, assign, readonly) TidyOptionId optionId;							///< Tidy's internal TidyOptionId for this option.

@property (nonatomic, assign, readonly) TidyOptionType optionType;						///< Actual type that TidyLib expects.

@property (nonatomic, strong, readonly) NSString *builtInDefaultValue;					///< Tidy's built-in default value for this option.

@property (nonatomic, strong, readonly) NSString *builtInDescription;					///< Tidy's built-in description for this option.

@property (nonatomic, assign, readonly) TidyConfigCategory builtInCategory;				///< Tidy's built-in category for this option.

@property (nonatomic, assign)           BOOL optionIsSuppressed;						///< Indicates whether or not this option is unused by JSDTidyModel.

@property (nonatomic, assign, readonly) BOOL optionIsEncodingOption;					///< Indicates whether or not this option is an encoding option.

@property (nonatomic, assign, readonly) BOOL optionCanAcceptNULLSTR;					///< Indicates whether or not this option can accept NULLSTR.


- (id)initSharingModel:(JSDTidyModel *)sharedTidyModel;

- (id)initWithName:(NSString *)name sharingModel:(JSDTidyModel *)sharedTidyModel;

- (id)initWithName:(NSString *)name optionValue:(NSMutableString *)value sharingModel:(JSDTidyModel *)sharedTidyModel;


- (BOOL)applyOptionToTidyDoc:(TidyDoc)destinationTidyDoc;


- (void)optionUIValueIncrement;															///< Possibly useful for UI's, increments to next possible option value.

- (void)optionUIValueDecrement;															///< Possibly useful for UI's, decrements to next possible option value.



@end
