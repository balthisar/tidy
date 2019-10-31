//
//  JSDNuVMessage.m
//  JSDNuVFramework
//
//  Copyright © 2018-2019 by Jim Derry. All rights reserved.
//

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
 * + messageArrayFromResponseObject:
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
 * - initWithDictionary:
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
 * @errorTypeNames
 *  This array maintains a list of error type-subtype name keys,
 *  which are used for localized string lookups and image lookups.
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
 * @property errorImages
 *  The key will be the errorTypeName of the error.
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
 * @typeImage
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSImage *)typeImage
{
    NSString *key = [NSString stringWithFormat:@"validator%@%@", self.type, self.subtype];
    
    return [self.errorImages objectForKey:key];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @typeID
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
 * @type
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
 * @subType
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
 * @typeLocalized
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)typeLocalized
{
    NSString *key = [NSString stringWithFormat:@"validator%@%@", self.type, self.subtype];
    
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @message
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)message
{
    return [self.dictionary valueForKey:@"message"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @messageLocalized
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)messageLocalized
{
    NSString *key = [self.dictionary valueForKey:@"message"];
    
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:nil table:nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @extract
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
 * @url
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)url
{
    return [self.dictionary valueForKey:@"url"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @offset
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
 * @firstLine
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
 * @firstColumn
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
 * @lastLine
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
 * @lastColumn
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
 * @hiliteStart
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
 * @hiliteLength
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
 * @lineString
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
 * @columnString
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
 * @locationString
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
 * @sortKey
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)sortKey
{
    return [NSString stringWithFormat:@"%08u%08u%@", self.firstLine, self.firstColumn, self.message];
}


#pragma mark - Keyed Subscripting


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - objectForKeyedSubscript:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)objectForKeyedSubscript:(NSString *)key
{
    return [self valueForKey:key];
}


#pragma mark - Object Comparison


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - isEqualToJSDValidatorMessage:
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
 * - isEqual:
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
 * - hash
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSUInteger)hash
{
    return [self.locationString hash] ^ [self.message hash];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - tidyMessageLocationCompare:
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

