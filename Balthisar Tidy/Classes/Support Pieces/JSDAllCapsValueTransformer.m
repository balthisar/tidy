/**************************************************************************************************

	JSDAllCapsValueTransformer

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDAllCapsValueTransformer.h"


@implementation JSDAllCapsValueTransformer


+ (Class)transformedValueClass
{
	return [NSString class];
}


+ (BOOL)allowsReverseTransformation
{
	return NO;
}


- (id)transformedValue:(id)value
{
	return [value uppercaseString];
}


@end
