/**************************************************************************************************

	JSDStringEncodingTools

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDStringEncodingTools.h"


#pragma mark - IMPLEMENTATION JSDStringEncodingTools

@implementation JSDStringEncodingTools


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	allAvailableEncodingLocalizedNames
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray *)encodingNames
{
	static NSArray *encodingNames = nil; // Only do this once
	
	if (!encodingNames)
	{
		NSMutableArray *tempNames = [[NSMutableArray alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			[tempNames addObject:[NSString localizedNameOfStringEncoding:*encoding]];
			encoding++;
		}
		
		encodingNames = [tempNames sortedArrayUsingComparator:^(NSString *a, NSString *b) { return [a localizedCaseInsensitiveCompare:b]; }];
	}
	
	return encodingNames;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	encodingsByEncoding
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSDictionary *)encodingsByEncoding
{
	static NSMutableDictionary *dictionary = nil; // Only do this once
	
	if (!dictionary)
	{
		dictionary = [[NSMutableDictionary alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			NSString *currentName = [NSString localizedNameOfStringEncoding:*encoding];
			NSNumber *currentIndex = @([[[self class] encodingNames] indexOfObject:currentName]);
			
			NSDictionary *items = @{@"LocalizedName"    : currentName,
									@"NSStringEncoding" : @(*encoding),
									@"LocalizedIndex"   : currentIndex};
			
			dictionary[@(*encoding)] = items;
			
			encoding++;
		}
	}
	
	return dictionary;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	encodingsByIndex
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSDictionary *)encodingsByIndex
{
	static NSMutableDictionary *dictionary = nil; // Only do this once
	
	if (!dictionary)
	{
		dictionary = [[NSMutableDictionary alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			NSString *currentName = [NSString localizedNameOfStringEncoding:*encoding];
			NSNumber *currentIndex = @([[[self class] encodingNames] indexOfObject:currentName]);

			NSDictionary *items = @{@"LocalizedName"    : currentName,
									@"NSStringEncoding" : @(*encoding),
									@"LocalizedIndex"   : currentIndex};
			
			dictionary[currentIndex] = items;
			
			encoding++;
		}
	}
	
	return dictionary;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	encodingsByName
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSDictionary *)encodingsByName
{
	static NSMutableDictionary *dictionary = nil; // Only do this once
	
	if (!dictionary)
	{
		dictionary = [[NSMutableDictionary alloc] init];
		
		const NSStringEncoding *encoding = [NSString availableStringEncodings];
		
		while (*encoding)
		{
			NSString *currentName = [NSString localizedNameOfStringEncoding:*encoding];
			NSNumber *currentIndex = @([[[self class] encodingNames] indexOfObject:currentName]);
			
			NSDictionary *items = @{@"LocalizedName"    : currentName,
									@"NSStringEncoding" : @(*encoding),
									@"LocalizedIndex"   : currentIndex};
			
			dictionary[currentName] = items;

			encoding++;
		}
	}
	
	return dictionary;
}


@end
