//
//  JSDIntegerValueTransformer.m
//  Balthisar Tidy
//
//  Created by Jim Derry on 5/5/14.
//  Copyright (c) 2014 Jim Derry. All rights reserved.
//

#import "JSDIntegerValueTransformer.h"

@implementation JSDIntegerValueTransformer

+ (Class)transformedValueClass {
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
