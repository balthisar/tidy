/**************************************************************************************************
 
	JSDTidyMessage
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.
 
 **************************************************************************************************/

#import "JSDTidyMessage.h"
#import "JSDTidyCommonHeaders.h"


#pragma mark - Category

@interface JSDTidyMessage ()

@property (nonatomic, assign, readonly) NSArray *errorTypeNames;

@property (nonatomic, assign, readonly) NSDictionary *errorImages;

@end


#pragma mark - Implementation

@implementation JSDTidyMessage


#pragma mark - Initialization


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - initWithLevel:Line:Column:Message:Arguments:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype) initWithLevel:(TidyReportLevel)level
						  Line:(uint)line
						Column:(uint)column
					   Message:(ctmbstr)message
					 Arguments:(va_list)arguments
{
	if (self = [super init])
	{
		/* Localize the message.
		 * We're localizing the string a couple of times, because the
		 * message might arrive in the message parameter, or it might
		 * arrive as one of the argumentss. For example, many messages
		 * are simply %s, and once the args are applied we want to
		 * localize this single string. In other cases, e.g.,
		 * "replacing %s by %s" we want to localize that message before
		 * applying the args. This new string won't be found in the
		 * .strings file, so it will be used as is.
		 */
		
		NSString *formatString = JSDLocalizedString(@(message), nil);
		
		NSString *intermediateString = [[NSString alloc] initWithFormat:formatString arguments:arguments];
		
		_message = JSDLocalizedString(intermediateString, nil);
		
		
		/* Set the rest of the remaining backing iVars */
		
		_level = level;
		_line = line;
		_column = column;
		
	}
	
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype) init
{
	NSLog(@"%@", @"WARNING: Consult the header and don't use `init` with this class.");
	return [self initWithLevel:0 Line:0 Column:0 Message:"" Arguments:nil];
}


#pragma mark - Private Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property errorTypeNames
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)errorTypeNames
{
	static NSArray *errorTypeNames;
	
	if (!errorTypeNames)
	{
		errorTypeNames = @[@"messagesInfo",       // 0
						   @"messagesWarning",    // 1
						   @"messagesConfig",     // 2
						   @"messagesAccess",     // 3
						   @"messagesError",      // 4
						   @"messagesDocument",   // 5
						   @"messagesPanic"];     // 6
	}
	
	return errorTypeNames;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property errorImages
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSDictionary *)errorImages
{
	static NSMutableDictionary *errorImages;
	
	if (!errorImages)
	{
		errorImages = [[NSMutableDictionary alloc] init];
		
		for (NSString *errorType in self.errorTypeNames)
		{
			NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:errorType ofType:@"pdf"]];
			[errorImages setObject:img forKey:errorType];
		}
	}
	
	return errorImages;
}



#pragma mark - Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property levelImage
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSImage *)levelImage
{
	return self.errorImages[self.errorTypeNames[self.level]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property levelDescription
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)levelDescription
{
	return JSDLocalizedString(self.errorTypeNames[self.level], nil);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property lineString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)lineString
{
	if (self.line == 0)
	{
		return JSDLocalizedString(@"N/A", @"");
	}
	else
	{
		return [NSString stringWithFormat:@"%@ %u", JSDLocalizedString(@"line", nil), self.line];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property columnString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)columnString
{
	if (self.column == 0)
	{
		return JSDLocalizedString(@"N/A", @"");
	}
	else
	{
		return [NSString stringWithFormat:@"%@ %u", JSDLocalizedString(@"column", nil), self.column];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property locationString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)locationString
{
	if ((self.line == 0) || (self.column == 0))
	{
		return JSDLocalizedString(@"N/A", @"");
	}
	else
	{
		return [NSString stringWithFormat:@"%@, %@", self.lineString, self.columnString];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property sortKey
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)sortKey
{
	return [NSString stringWithFormat:@"%08u%08u%@", self.line, self.column, self.message];
}


#pragma mark - Keyed Subscripting


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - objectForKeyedSubscript:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)objectForKeyedSubscript:(NSString *)key
{
	return [self valueForKey:key];
}


#pragma mark - Object Comparison


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - isEqualToJSDTidyMessage:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)isEqualToJSDTidyMessage:(JSDTidyMessage *)JSDTidyMessage
{
	if (!JSDTidyMessage)
	{
		return NO;
	}
	
	BOOL equalLocationString = [self.locationString isEqualToString:JSDTidyMessage.locationString];
	BOOL equalMessage = [self.message isEqualToString:JSDTidyMessage.message];
	
	return equalLocationString && equalMessage;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - isEqual:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)isEqual:(id)object
{
	if (self == object)
	{
		return YES;
	}
	
	if (![object isKindOfClass:[JSDTidyMessage class]])
	{
		return NO;
	}
	
	return [self isEqualToJSDTidyMessage:(JSDTidyMessage *)object];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - hash
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSUInteger)hash
{
  return [self.locationString hash] ^ [self.message hash];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - tidyMessageLocationCompare
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
-(NSComparisonResult)tidyMessageLocationCompare:(JSDTidyMessage *)message
{
	NSComparisonResult result;
	
	result = [@(self.line) compare:@(message.line)];
	
	if (result == NSOrderedSame)
	{
		result = [@(self.column) compare:@(message.column)];
		
		if (result == NSOrderedSame)
		{
			result = [self.message localizedStandardCompare:message.message];
		}
	}
	
	return result;
}

@end
