//
//  MGSSyntaxParser.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 30/10/2018.
//

#import <Cocoa/Cocoa.h>
#import "MGSSyntaxParserClient.h"
#import "MGSSyntaxAwareEditor.h"
#import "MGSAutoCompleteDelegate.h"

NS_ASSUME_NONNULL_BEGIN


/** Syntax Parsers are objects that perform several language-related services
 *  for Fragaria: syntax-aware editing, language-specific autocompletion, but
 *  primarily string parsing for syntax highlighting.
 *
 *  Syntax Parsers are accessed by setting the appropriate syntax definition
 *  name on an instance of MGSFragaria. The parser is instantiated by a
 *  MGSParserFactory which was previously registered on MGSSyntaxController.
 *  Every instance of MGSParserFactory provides the list of syntax definition
 *  names it handles.
 *
 *  Fragaria already provides default parsers which support a variety of
 *  languages, but it is possible to implement your own MGSSyntaxParser and
 *  MGSParserFactory.
 *
 *  ## Tokens
 *
 *  Parsers work by creating tokens in strings. When a range of text is updated
 *  or comes into view for the first time, the
 *  `-parseString:inRange:forParserClient:` method is invoked.
 *  In that method, the parser uses the specified MGSSyntaxParserClient to
 *  create tokens in the text. Each token is then coloured by the parser client
 *  depending on the colour scheme chosen by the user.
 *
 *  In the context of Fragaria, a token is a contiguous range of characters
 *  with the same MGSSyntaxGroup attribute.
 *  There are two types of tokens: atomic tokens and non-atomic tokens. Their
 *  behavior is different when the characters that were already part of the
 *  token are assigned to a new group. Since a character can only be part of
 *  one group at a time, existing tokens would break into new tokens instead of
 *  just creating a single new token.
 *  Atomic tokens cannot break, they disappear instead. Non-atomic tokens break
 *  as described.
 *
 *  For example, consider the string "123456", which forms a single token of
 *  group A.
 *  If such token is atomic, creating a new group B token for the substring
 *  "34" results in a single "34" token. Afterwards, "12" and "56" are not
 *  part of any token anymore.
 *  Instead, if the token is not atomic, creating a new group B token for the
 *  substring "34" results in the creation of three tokens: "12" (group A),
 *  "34" (group B), and "56" (group A).
 *
 *  The distinction between atomic and non-atomic tokens is largely irrelevent
 *  for single-pass parsers. */
@interface MGSSyntaxParser : NSObject <MGSSyntaxAwareEditor, MGSAutoCompleteDelegate>


#pragma mark - Entry Point for Parsing
/// @name Entry Point for Parsing


/** Parse a string range and set appropriate syntax group tokens for the specified
 *  parser client.
 *  @param client The parser client to use for retrieving the string and to
 *    create tokens.
 *  @returns The actual string range affected. May be larger or smaller than the
 *    initial range.
 *  @note Any pre-existing tokens created by previous invocations of this methods
 *    are always retained, whether the range overlapped or not. Your parser can
 *    take advantage of this if needed.
 *  @warning Successive invocations of this methods on multiple ranges of the string
 *    must always produce the same result as a single invocation of the method on
 *    the union of all the ranges.
 *  @warning Returning a new range smaller than the passed range can easily cause
 *     infinite loops if there is no way for Fragaria to completely cover the whole
 *     string. Avoid doing so as much as possible. */
- (NSRange)parseForClient:(id<MGSSyntaxParserClient>)client;


#pragma mark - Parser Configuration
/// @name Parser Configuration


/** If multiline strings should be identified by this parser.
 *  @discussion This property was implemented because the built-in Fragaria parser
 *    sometimes handles multiline strings incorrectly. If your parser always
 *    handles them properly, you may ignore this property. */
@property (nonatomic, assign) BOOL coloursMultiLineStrings;
/** If parsing of multiline structures other than strings should end at end
 *  of line.
 *  @discussion This property was implemented because the built-in Fragaria parser
 *    sometimes handles multiline syntactic elements incorrectly. If your parser always
 *    handles them properly, you may ignore this property. */
@property (nonatomic, assign) BOOL coloursOnlyUntilEndOfLine;


#pragma mark - Language-Specific Autocompletion
/// @name Language-Specific Autocompletion


/** The list of keywords used by autocompletion when the autoCompleteWithKeywords option
 *  is enabled. */
@property (nonatomic, readonly) NSArray <NSString *> *autocompletionKeywords;


@end


NS_ASSUME_NONNULL_END
