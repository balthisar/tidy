/*
 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria

 Smultron version 3.6b1, 2009-09-12
 Written by Peter Borg, pgw3@mac.com
 Find the latest version at http://smultron.sourceforge.net

 Copyright 2004-2009 Peter Borg

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 this file except in compliance with the License. You may obtain a copy of the
 License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed
 under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 CONDITIONS OF ANY KIND, either express or implied. See the License for the
 specific language governing permissions and limitations under the License.
 */

#import <Cocoa/Cocoa.h>
#import "MGSParserFactory.h"

NS_ASSUME_NONNULL_BEGIN


@class MGSSyntaxParser;


/** MGSSyntaxController manages syntax definitions for Fragaria.
 *
 *  A syntax definition describes a programming language supported by
 *  Fragaria. It consists by a parser for a language, and by
 *  metadata about associated file extensions and UTIs. Each
 *  syntax definition is associated to a human-readable name, which
 *  uniquely identifies it. This name is also denoted as the
 *  Language Identifier.
 *
 *  Each syntax definition is handled by a MGSParserFactory.
 *  The default Fragaria parser factory uses syntax definition files
 *  located in the framework bundle, in your app bundle and from
 *  /Users/{user}/Library/Application Support/{appname}/. */
@interface MGSSyntaxController : NSObject


#pragma mark - Retrieving the Shared Instance
/// @name Retrieving the Shared Instance


/** Returns a shared instance of the MGSSyntaxController. */
+ (instancetype)sharedInstance;


#pragma mark - Finding Syntax Definitions
/// @name Finding Syntax Definitions


/** Returns the definition name for the Standard syntax definition.
 *  The Standard syntax definition is an unremarkable syntax which performs
 *  no colouring but is always available. */
+ (NSString *)standardSyntaxDefinitionName;

/** Array of all known syntax definition names. */
@property (strong,nonatomic,readonly) NSArray<NSString *> *syntaxDefinitionNames;

/** Returns a list of language identifiers corresponding to the given
 *  filename extension.
 *  @param extension The extension for which to search matching languages.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note Language identifiers returned by this method are always included in
 *        syntaxDefinitionNames. */
- (NSArray<NSString *> *)syntaxDefinitionNamesWithExtension:(NSString *)extension;

/** Returns a list of file extensions corresponding to the given
 *  language identifier.
 *  @param sdname The language identifier.
 *  @returns A list of file extensions (without dot prefixes).
 *  @note The list of extensions returned is coherent with the return values
 *    of -syntaxDefinitionNamesWithExtension:. */
- (NSArray<NSString *> *)extensionsForSyntaxDefinitionName:(NSString *)sdname;

/** Returns a list of language identifiers corresponding to the given
 *  Universal Type Identifier (UTI).
 *  @param uti The UTI for which to search matching languages.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note Language identifiers returned by this method are always included in
 *        syntaxDefinitionNames. */
- (NSArray<NSString *> *)syntaxDefinitionNamesWithUTI:(NSString *)uti;

/** Returns a list of language identifiers guessed based on the first line of
 *  a text file.
 *  @param firstLine The first line of a text file.
 *  @returns A list of language identifiers, subset of syntaxDefinitionNames.
 *  @note Language identifiers returned by this method are always included in
 *        syntaxDefinitionNames. */
- (NSArray<NSString *> *)guessSyntaxDefinitionNamesFromFirstLine:(NSString *)firstLine;

/** Instantiates a parser for the given language identifier.
 *  @param syndef The language identifier.
 *  @returns An instance of MGSSyntaxParser, or nil if the language identifier
 *    does not match any supported syntax definition. */
- (nullable MGSSyntaxParser *)parserForSyntaxDefinitionName:(NSString *)syndef;


#pragma mark - Finding Syntax Groups
/// @name Finding Syntax Groups


/** The list of MGSSyntaxGroups that all the parsers can use, intended
 *  for UX purposes.
 *  @note This property is not intended as an exhaustive list, but as an
 *    implementation aid for colour scheme editors. */
@property (nonatomic, readonly) NSArray<MGSSyntaxGroup> *syntaxGroupsForParsers;

/** Returns a user-consumable name for a syntax group.
 *  @param syntaxGroup The syntax group identifier.
 *  @returns A localized string associated with the syntax group, or a
 *    generic non-localized name if such string is not available. */
- (NSString *)localizedDisplayNameForSyntaxGroup:(MGSSyntaxGroup)syntaxGroup;


#pragma mark - Adding Syntax Definitions
/// @name Adding Syntax Definitions


/** Registers a new parser factory instance.
 *  @param parserFactory The new parser factory.
 *  @note If multiple different parser factories expose syntax definitions with
 *    the same name, the names are altered in order to maintain the
 *    uniqueness of the elements of syntaxDefinitionNames. */
- (void)registerParserFactory:(id <MGSParserFactory>)parserFactory;


@end


NS_ASSUME_NONNULL_END
