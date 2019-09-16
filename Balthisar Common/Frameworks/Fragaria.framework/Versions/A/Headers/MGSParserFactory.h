//
//  MGSParserFactory.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 26/12/2018.
//

#import <Foundation/Foundation.h>
#import "MGSSyntaxParserClient.h"

NS_ASSUME_NONNULL_BEGIN


@class MGSSyntaxParser;


/** MGSParserFactory objects are used by MGSSyntaxController to find
 *  available MGSSyntaxParser objects. Additionally, they provide
 *  metadata about the languages supported by the parsers they can instantiate. */
@protocol MGSParserFactory <NSObject>


/** The list of language identifiers provided by this object. */
@property (nonatomic, readonly) NSArray<NSString *> *syntaxDefinitionNames;

/** Returns a MGSSyntaxParser suitable for parsing a string of the specified
 *  language.
 *  @param syndef One of the language identifiers from this object's
 *         syntaxDefinitionNames list.
 *  @returns A parser for the specified language. */
- (MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef;


@optional

/** Returns a list of language identifiers corresponding to the given
 *  filename extension.
 *  @param extension The extension for which to search matching languages.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note This method shall not return a language identifier not included in
 *        syntaxDefinitionNames. */
- (NSArray <NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension;

/** Returns a list of file extensions corresponding to the given
 *  language identifier.
 *  @param sdname The language identifier.
 *  @returns A list of file extensions (without dot prefixes).
 *  @note The list of extensions returned must be coherent with the return values
 *    of -syntaxDefinitionNamesWithExtension:. */
- (NSArray <NSString *> *)extensionsForSyntaxDefinitionName:(NSString *)sdname;

/** Returns a list of language identifiers corresponding to the given
 *  Universal Type Identifier (UTI).
 *  @param uti The UTI for which to search matching languages.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note This method shall not return a language identifier not included in
 *        syntaxDefinitionNames. */
- (NSArray <NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti;

/** Returns a list of language identifiers guessed based on the first line of
 *  a text file.
 *  @param firstLine The first line of a text file.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note This method shall not return a language identifier not included in
 *        syntaxDefinitionNames. */
- (NSArray <NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine;


/** The list of MGSSyntaxGroups that the parsers provided by this
 *  factory can use, intended for UX purposes.
 *  @note This property is not intended as an exhaustive list, but as an
 *    implementation aid for colour scheme editors. Thus, if the parsers
 *    only wrap an existing parser already registered by another parser
 *    factory, this method can be ignored. */
@property (nonatomic, readonly) NSArray<MGSSyntaxGroup> *syntaxGroupsForParsers;

/** Returns a user-consumable name for a syntax group.
 *  @param syntaxGroup The syntax group identifier.
 *  @returns A localized string associated with the syntax group.
 *  @note Typically this method is called only with the syntax groups
 *    returned by syntaxGroupsForParsers. It is not necessary to return
 *    a string for syntax groups declared by Fragaria itself. */
- (nullable NSString *)localizedDisplayNameForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;


@end

NS_ASSUME_NONNULL_END
