//
//  JSDAllCapsValueTransformer.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

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
