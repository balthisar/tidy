//
//  JSDIntegerValueTransformer.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "JSDIntegerValueTransformer.h"


@implementation JSDIntegerValueTransformer


+ (Class)transformedValueClass 
{
    return [NSNumber class];
}


+ (BOOL)allowsReverseTransformation
{
    return YES;
}


- (id)transformedValue:(id)value
{
    return [NSNumber numberWithInteger:[value integerValue]];
}


@end
