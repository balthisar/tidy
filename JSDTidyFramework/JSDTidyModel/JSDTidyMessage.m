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
        NSString *formatString;
		/* Get our localized format string from the message code. */
        if ( strcmp(message, "UNDEFINED") == 0 )
            formatString = @"%s";
        else
            formatString = JSDLocalizedString(@(message), nil);
		
		/* And fill in the arguments from the va_list. */
		_message = [[NSString alloc] initWithFormat:formatString arguments:arguments];

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
	This array maintains the same order as TidyReportLevel, and
	these will be used as key fields instead of an actual
	TidyReportLevel so that we maintain independence from actual
	enum values.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)errorTypeNames
{
	static NSArray *errorTypeNames;
	
	if (!errorTypeNames)
	{
		errorTypeNames = @[@"messagesInfo",		  
						   @"messagesWarning",	  
						   @"messagesConfig",	  
						   @"messagesAccess",	  
						   @"messagesError",	  
						   @"messagesDocument",	  
						   @"messagesPanic"];
	}
	
	return errorTypeNames;
}

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property errorImages
	The key will be the errorTypeName of the error. We don't want
	to use a possibly unstable enum value as a key.
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
	/* It's possible TidyInfo (first enum) is not zero. */
	int level = self.level - TidyInfo;
	
	return self.errorImages[self.errorTypeNames[level]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property levelDescription
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)levelDescription
{
	/* It's possible TidyInfo (first enum) is not zero. */
	int level = self.level - TidyInfo;

	return JSDLocalizedString(self.errorTypeNames[level], nil);
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
