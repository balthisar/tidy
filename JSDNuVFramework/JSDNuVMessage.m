/**************************************************************************************************

    JSDNuVMessage

    Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDNuVMessage.h"
#import "NSImage+Tinted.h"


#pragma mark - Category

@interface JSDNuVMessage ()

@property (nonatomic, assign, readonly) NSArray *errorTypeNames;

@property (nonatomic, assign, readonly) NSDictionary *errorImages;

@end


#pragma mark - Implementation

@implementation JSDNuVMessage


#pragma mark - Initialization


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * fakeMessageArrayFromNativeArray:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray<JSDNuVMessage*>*) _messageArrayFromResponseObject:(NSDictionary *)responseObject
{
    NSMutableArray *result = [[NSMutableArray alloc] init];

    NSDictionary *dicn = @{
                           @"type"       : @"error",
                           @"subtype"    : @"",
                           @"message"    : @"Hello error",
                           @"extract"    : @"Now is the time for all good men to come to the aid of their parties.\n",
                           @"lastLine"   : @"1",
                           @"lastColumn" : @"20",
                           };

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:dicn];

    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"error" forKey:@"type"];
    [dict setValue:@"fatal" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"info" forKey:@"type"];
    [dict setValue:@"" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"info" forKey:@"type"];
    [dict setValue:@"warning" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"non-document-error" forKey:@"type"];
    [dict setValue:@"" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"non-document-error" forKey:@"type"];
    [dict setValue:@"internal" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"non-document-error" forKey:@"type"];
    [dict setValue:@"io" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    [dict setValue:@"non-document-error" forKey:@"type"];
    [dict setValue:@"schema" forKey:@"subtype"];
    [result addObject: [[JSDNuVMessage alloc] initWithDictionary:dict]];

    return result;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * messageArrayFromNativeArray:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSArray<JSDNuVMessage*>*) messageArrayFromResponseObject:(NSDictionary *)responseObject
{
    NSArray *responseArray = [responseObject valueForKey:@"messages"];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:responseArray.count];

    for ( NSDictionary *local in responseArray )
    {
        [result addObject: [[JSDNuVMessage alloc] initWithDictionary:local]];
    }

    return result;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype) initWithDictionary:(NSDictionary *)dict
{
    if ( (self = [super init]) )
    {
        _dictionary = [dict copy];
    }

    return self;
}


#pragma mark - Private Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property errorTypeNames
    This array maintains a list of error type-subtype name keys, which
    are used for localized string lookups and image lookups.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)errorTypeNames
{
    static NSArray *errorTypeNames;

    if (!errorTypeNames)
    {
        errorTypeNames = @[@"validatorError",
                           @"validatorErrorFatal",
                           @"validatorInfo",
                           @"validatorInfoWarning",
                           @"validatorNonDoc",
                           @"validatorNonDocInternal",
                           @"validatorNonDocIo",
                           @"validatorNonDocSchema" ];
    }

    return errorTypeNames;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property errorImages
    The key will be the errorTypeName of the error.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSDictionary *)errorImages
{
    static NSMutableDictionary *errorImages;

	NSColorList *colors = [NSColorList colorListNamed:@"Crayons"];

    NSArray *imageSetup = @[
                            @{ @"key": @"validatorError",          @"image" : @"validatorError",           @"color": [colors colorWithKey:@"Maraschino"] },
                            @{ @"key": @"validatorErrorFatal",     @"image" : @"validatorError",           @"color": [colors colorWithKey:@"Cayenne"] },
                            @{ @"key": @"validatorInfo",           @"image" : @"validatorInfo",            @"color": [colors colorWithKey:@"Aqua"] },
                            @{ @"key": @"validatorInfoWarning",    @"image" : @"validatorInfo",            @"color": [colors colorWithKey:@"Blueberry"] },
                            @{ @"key": @"validatorNonDoc",         @"image" : @"validatorNonDoc",          @"color": [colors colorWithKey:@"Teal"] },
                            @{ @"key": @"validatorNonDocInternal", @"image" : @"validatorNonDocInternal",  @"color": [colors colorWithKey:@"Tungsten"] },
                            @{ @"key": @"validatorNonDocIo",       @"image" : @"validatorNonDocIo",        @"color": [colors colorWithKey:@"Moss"] },
                            @{ @"key": @"validatorNonDocSchema",   @"image" : @"validatorNonDocSchema",    @"color": [colors colorWithKey:@"Fern"] },
                            ];

    if (!errorImages)
    {
        errorImages = [[NSMutableDictionary alloc] initWithCapacity:[imageSetup count]];

        for ( NSDictionary *errorDict in imageSetup )
        {
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            NSString *errorType = [errorDict valueForKey:@"key"];
            NSString *filename = [errorDict valueForKey:@"image"];
            NSString *file = [bundle pathForResource:filename ofType:@"pdf"];
            NSImage *img;

            img = [[NSImage alloc] initWithContentsOfFile:file];
			img = [img tintedWithColor:[errorDict objectForKey:@"color"]];
            [errorImages setObject:img forKey:errorType];
        }
    }

    return errorImages;
}


#pragma mark - Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property typeImage
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSImage *)typeImage
{
    NSString *key = [NSString stringWithFormat:@"validator%@%@", self.type, self.subtype];

    return [self.errorImages objectForKey:key];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property typeID
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (JSDNuVMessageTypes)typeID
{
    NSString *result = [self.dictionary valueForKey:@"type"];

	if ( [result isEqualToString:@"error"] )
		return JSDNuVError;

	if ( [result isEqualToString:@"info"] )
		return JSDNuVInfo;

	if ( [result isEqualToString:@"non-document-error"] )
		return JSDNuVNonDoc;

	return JSDNuVNone;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property type
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)type
{
    NSString *result = [self.dictionary valueForKey:@"type"];

    if ( result && [result isEqualToString:@"non-document-error"] )
        return @"NonDoc";
    else
        return [result capitalizedString];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property subType
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)subtype
{
    NSString *result = [self.dictionary valueForKey:@"subtype"];

    if ( result )
        return [result capitalizedString];
    else
        return @"";
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property typeLocalized
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)typeLocalized
{
    NSString *key = [NSString stringWithFormat:@"validator%@%@", self.type, self.subtype];

    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property message
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)message
{
    return [self.dictionary valueForKey:@"message"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property messageLocalized
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)messageLocalized
{
    NSString *key = [self.dictionary valueForKey:@"message"];

    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property extract
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSAttributedString *)extract
{
    NSString *string = [[self.dictionary valueForKey:@"extract"] stringByReplacingOccurrencesOfString:@"\n" withString:@"↩︎"];

	if ( string )
	{
		NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:string];

		NSRange range = [string rangeOfString:@"↩︎" options:NSCaseInsensitiveSearch];
		while ( range.location != NSNotFound )
		{
			[result addAttribute:NSForegroundColorAttributeName value:[NSColor systemGrayColor] range:range];

			NSRange nextRange = NSMakeRange(range.location + 1, string.length - range.location - 1);
			range = [string rangeOfString:@"↩︎" options:NSCaseInsensitiveSearch range:nextRange];
		}
		return result;
	}
	return nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property url
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)url
{
    return [self.dictionary valueForKey:@"url"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property offset
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)offset
{
    NSString *value = [self.dictionary valueForKey:@"offset"];

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property firstLine
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)firstLine
{
    NSString *value = [self.dictionary valueForKey:@"firstLine"];

    if ( !value )
    {
        value = [self.dictionary valueForKey:@"lastLine"];
    }

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}

/* Synonym for KVO compatibility. */
- (uint)line
{
	return self.firstLine;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property firstColumn
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)firstColumn
{
    NSString *value = [self.dictionary valueForKey:@"firstColumn"];

    if ( !value )
    {
        value = [self.dictionary valueForKey:@"lastColumn"];
    }

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property lastLine
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)lastLine
{
    NSString *value = [self.dictionary valueForKey:@"lastLine"];

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property lastColumn
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)lastColumn
{
    NSString *value = [self.dictionary valueForKey:@"lastColumn"];

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property hiliteStart
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)hiliteStart
{
    NSString *value = [self.dictionary valueForKey:@"hiliteStart"];

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property hiliteLength
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (uint)hiliteLength
{
    NSString *value = [self.dictionary valueForKey:@"hiliteLength"];

    if ( value )
    {
        return [value intValue];
    }

    return 0;
}



/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property lineString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)lineString
{
    if (self.firstLine == 0)
    {
        return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"N/A" value:nil table:nil];
    }
    else
    {
        NSString *translate = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"line" value:nil table:nil];
        return [NSString stringWithFormat:@"%@ %u", translate, self.firstLine];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property columnString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)columnString
{
    if (self.firstColumn == 0)
    {
        return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"N/A" value:nil table:nil];
    }
    else
    {
        NSString *translate = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"column" value:nil table:nil];
        return [NSString stringWithFormat:@"%@ %u", translate, self.firstColumn];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property locationString
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)locationString
{
    if ((self.firstLine == 0) || (self.firstColumn == 0))
    {
        return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"N/A" value:nil table:nil];
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
    return [NSString stringWithFormat:@"%08u%08u%@", self.firstLine, self.firstColumn, self.message];
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
  - isEqualToJSDValidatorMessage:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)isEqualToJSDValidatorMessage:(JSDNuVMessage *)message
{
    if (!message)
    {
        return NO;
    }

    BOOL equalLocationString = [self.locationString isEqualToString:message.locationString];
    BOOL equalMessage = [self.message isEqualToString:message.message];

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

    if (![object isKindOfClass:[JSDNuVMessage class]])
    {
        return NO;
    }

    return [self isEqualToJSDValidatorMessage:(JSDNuVMessage *)object];
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
-(NSComparisonResult)validatorMessageLocationCompare:(JSDNuVMessage *)message
{
    NSComparisonResult result;

    result = [@(self.firstLine) compare:@(message.firstLine)];

    if (result == NSOrderedSame)
    {
        result = [@(self.firstColumn) compare:@(message.firstColumn)];

        if (result == NSOrderedSame)
        {
            result = [self.message localizedStandardCompare:message.message];
        }
    }

    return result;
}


@end

