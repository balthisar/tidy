/**************************************************************************************************

	JSDAllCapsValueTransformer

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDBoolToStringValueTransformer.h"


@implementation JSDBoolToStringValueTransformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}


+ (BOOL)allowsReverseTransformation
{
	return NO;
}


- (id)transformedValue:(id)value
{
	if ([(NSNumber*)value boolValue])
	{
		return @"yes";
	}
	else
	{
		return @"no";
	}
}


@end
