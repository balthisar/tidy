//
//  MGSMutableColourScheme.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 20/09/18.
//

#import <Foundation/Foundation.h>
#import "MGSColourScheme.h"

NS_ASSUME_NONNULL_BEGIN


/**
 *  The mutable subclass of MGSColourScheme.
 */
@interface MGSMutableColourScheme : MGSColourScheme


#pragma mark - Saving and Loading Colour Schemes
/// @name Saving and Loading Colour Schemes


/** Sets its values from a plist file.
 *  @param file The complete path and file to read.
 *  @param err Upon return, if the loading failed, contains an NSError object
 *         that describes the problem. */
- (BOOL)loadFromSchemeFileURL:(NSURL *)file error:(out NSError **)err;


#pragma mark - Colour Scheme Properties
/// @name Colour Scheme Properties


/** Display name of the color scheme. */
@property (nonatomic, strong) NSString *displayName;

/** Base text color. */
@property (nonatomic, strong) NSColor *textColor;
/** Editor background color. */
@property (nonatomic, strong) NSColor *backgroundColor;
/** Syntax error background highlighting color. */
@property (nonatomic, strong) NSColor *defaultSyntaxErrorHighlightingColour;
/** Editor invisible characters color. */
@property (nonatomic, strong) NSColor *textInvisibleCharactersColour;
/** Editor current line highlight color. */
@property (nonatomic, strong) NSColor *currentLineHighlightColour;
/** Editor insertion point color. */
@property (nonatomic, strong) NSColor *insertionPointColor;


/** Sets if the specified syntax group will be coloured.
 *  @param enabled YES to enable the syntax group, NO otherwise.
 *  @param group The syntax group identifier. */
- (void)setColours:(BOOL)enabled syntaxGroup:(MGSSyntaxGroup)group;

/** Sets the highlighting colour for the specified syntax group.
 *  @param color The colour to use for highlighting the group.
 *  @param group The syntax group identifier. */
- (void)setColour:(NSColor *)color forSyntaxGroup:(MGSSyntaxGroup)group;

/** Sets the font variant used for highlighting the specified syntax
 *  group.
 *  @param variant The font variant to use for highlighting the group.
 *  @param syntaxGroup The syntax group identifier. */
- (void)setFontVariant:(MGSFontVariant)variant forSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;

/** Sets the options for the specified syntax group to the values in the
 *  given dictionary.
 *  @param options A dictionary of options for the syntax group.
 *  @param syntaxGroup The syntax group identifier.
 *  @note When an option key is missing from the dictionary, the default values
 *    are set for that option instead. */
- (void)setOptions:(NSDictionary<MGSColourSchemeGroupOptionKey, id> *)options forSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;

/** A dictionary containing the option dictionaries of all
 *  syntax groups recognized by this colour scheme. */
@property (nonatomic, copy) NSDictionary<MGSSyntaxGroup, NSDictionary<MGSColourSchemeGroupOptionKey, id> *> *syntaxGroupOptions;


@end


NS_ASSUME_NONNULL_END
