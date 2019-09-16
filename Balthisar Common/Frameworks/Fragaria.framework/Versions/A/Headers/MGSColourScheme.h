//
//  MGSColourScheme.h
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxParserClient.h"

NS_ASSUME_NONNULL_BEGIN


/** Errors returned by MGSColourScheme */
extern NSString * const MGSColourSchemeErrorDomain;

/** Error code associated to the MGSColourSchemeErrorDomain error domain. */
typedef NS_ENUM(NSUInteger, MGSColourSchemeErrorCode) {
    /** The file or PList has an invalid format. */
    MGSColourSchemeWrongFileFormat = 1
};

/** Bitmask of font variants used for highlighting a syntax group. */
typedef NS_OPTIONS(NSUInteger, MGSFontVariant) {
    /** A mask that specifies a bold font. */
    MGSFontVariantBold = 1 << 0,
    /** A mask that specifies an italic font. */
    MGSFontVariantItalic = 1 << 1,
    /** A mask that specifies that the token should be underlined. */
    MGSFontVariantUnderline = 1 << 2
};

/** Keys in syntax group option dictionaries. */
typedef NSString * const MGSColourSchemeGroupOptionKey NS_EXTENSIBLE_STRING_ENUM;
/** Key associated to a boolean NSNumber which specifies if highlighting the
 *  syntax group is enabled. */
extern MGSColourSchemeGroupOptionKey MGSColourSchemeGroupOptionKeyEnabled;
/** Key associated to the NSColor used for highlighting the syntax group. */
extern MGSColourSchemeGroupOptionKey MGSColourSchemeGroupOptionKeyColour;
/** Key associated to an NSNumber wrapping a MGSFontVariant specifying the
 *  font variant used for highlighting the syntax group. */
extern MGSColourSchemeGroupOptionKey MGSColourSchemeGroupOptionKeyFontVariant;


/**
 *  MGSColourScheme wraps all the properties related to how the text
 *  in an instance of MGSFragaria is highlighted.
 *
 *  A colour scheme includes both global properties like the colour of the
 *  text and the background, and a collection of options specific to each
 *  MGSSyntaxGroup. The options can be accessed by methods that handle
 *  one option at a time, one syntax group at a time, or all syntax group at
 *  once.
 */
@interface MGSColourScheme : NSObject <NSCopying, NSMutableCopying>


#pragma mark - Initializing a Colour Scheme
/// @name Initializing a Colour Scheme


/** Initialize a new colour scheme instance from a dictionary.
 *  @param dictionary A dictionary in the same format as what is
 *    returned by -dictionaryRepresentation. */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/** Initializes a new colour scheme instance from a file.
 *  @param file The URL of the plist file.
 *  @param err Upon return, if the initialization failed, contains an NSError object
 *         that describes the problem. */
- (instancetype)initWithSchemeFileURL:(NSURL *)file error:(out NSError **)err;

/** Initializes a new colour scheme instance from a deserialized property list.
 *  @param plist The deserialized plist
 *  @param err   Upon return, if the initialization failed, contains an NSError object
 *               which describes the problem. */
- (instancetype)initWithPropertyList:(id)plist error:(out NSError **)err;

/** Initializes a new colour scheme instance by copying another colour scheme.
 *  @param scheme The original colour scheme to copy. */
- (instancetype)initWithColourScheme:(MGSColourScheme *)scheme;

/** Initializes a new colour scheme instance with the default properties for the current
 * appearance. */
- (instancetype)init;

/** Returns a colour scheme instance with the default properties for
 * the specified appearance (or the current appearance if appearance is nil)
 * @param appearance The appearance appropriate for the returned scheme */
+ (instancetype)defaultColorSchemeForAppearance:(NSAppearance *)appearance;


#pragma mark - Saving Colour Schemes
/// @name Saving Loading Colour Schemes


/** Writes the object as a plist to the given file.
 *  @param file The complete path and file to write.
 *  @param err Upon return, if the operation failed, contains an NSError object
 *         that describes the problem.
 *  @returns YES if the operation succeeded, otherwise NO. */
- (BOOL)writeToSchemeFileURL:(NSURL *)file error:(out NSError **)err;


/** An NSDictionary representation of the Colour Scheme.
 *  @warning The structure used by the returned dictionary is private. To access
 *     the contents of a dictionary representation of an MGSColourScheme, always
 *     initialize a new MGSColourScheme instead of accessing the contents of the
 *     dictionary directly. */
@property (nonatomic, assign, readonly) NSDictionary *dictionaryRepresentation;

/** A serializable NSDictionary representation of the Colour Scheme.
 *  @discussion Like for dictionaryRepresentation, the structure of the returned
 *     object is private as well. However, the dictionary returned by this property is
 *     forwards and backwards compatible with other versions of Fragaria when
 *     used to initialize a new MGSColourScheme via -initWithPropertyList:error:. */
@property (nonatomic, assign, readonly) id propertyListRepresentation;


#pragma mark - Getting Information on Properties
/// @name Getting Information of Properties


/** An array of colour schemes included with Fragaria.
 *  @discussion A new copy of the schemes is generated for every invocation
 *      of this method, as colour schemes are mutable. */
+ (NSArray <MGSColourScheme *> *)builtinColourSchemes;


#pragma mark - Colour Scheme Properties
/// @name Colour Scheme Properties


/** Display name of the color scheme. */
@property (nonatomic, strong, readonly) NSString *displayName;

/** Base text color. */
@property (nonatomic, strong, readonly) NSColor *textColor;
/** Editor background color. */
@property (nonatomic, strong, readonly) NSColor *backgroundColor;
/** Syntax error background highlighting color. */
@property (nonatomic, strong, readonly) NSColor *defaultSyntaxErrorHighlightingColour;
/** Editor invisible characters color. */
@property (nonatomic, strong, readonly) NSColor *textInvisibleCharactersColour;
/** Editor current line highlight color. */
@property (nonatomic, strong, readonly) NSColor *currentLineHighlightColour;
/** Editor insertion point color. */
@property (nonatomic, strong, readonly) NSColor *insertionPointColor;

/** Returns the highlighting colour of specified syntax group, or nil
 *  if the specified group is not associated with an highlighting colour.
 *  @param syntaxGroup The syntax group identifier. */
- (nullable NSColor *)colourForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;

/** Returns the font variant used for highlighting the specified syntax
 *  group.
 *  @param syntaxGroup The syntax group identifier. */
- (MGSFontVariant)fontVariantForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;

/** Returns if the specified syntax group will be highlighted.
 *  @param syntaxGroup The syntax group identifier. */
- (BOOL)coloursSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;

/** Returns a dictionary containing all the options associated to the
 *  highlighting of the specified syntax group.
 *  @param syntaxGroup The syntax group identifier. */
- (nullable NSDictionary<MGSColourSchemeGroupOptionKey, id> *)optionsForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;

/** A dictionary containing the option dictionaries of all
 *  syntax groups recognized by this colour scheme. */
@property (nonatomic, copy, readonly) NSDictionary<MGSSyntaxGroup, NSDictionary<MGSColourSchemeGroupOptionKey, id> *> *syntaxGroupOptions;


#pragma mark - Resolving Syntax Groups for Highlighting
/// @name Resolving Syntax Groups for Highlighting


/** Resolves a syntax group to the closest super-group known to
 *  this colour scheme.
 *  @param group A syntax group
 *  @returns The resolved syntax group or nil if no super-group
 *    of the specified group is known to this colour scheme. */
- (nullable MGSSyntaxGroup)resolveSyntaxGroup:(MGSSyntaxGroup)group;

/** Returns the dictionary of attributes to use for colouring a
 *  token of a given syntax group.
 *  @param group The syntax group of the token.
 *  @param font The font used for non-highlighted text.
 *  @note This method also does syntax group resolution. */
- (NSDictionary<NSAttributedStringKey, id> *)attributesForSyntaxGroup:(MGSSyntaxGroup)group textFont:(NSFont *)font;


#pragma mark - Checking Equality
/// @name Checking Equality


/** Indicates if two schemes have the same colour settings.
 *  @param scheme The scheme that you want to compare to the receiver. */
- (BOOL)isEqualToScheme:(MGSColourScheme *)scheme;


@end

NS_ASSUME_NONNULL_END

