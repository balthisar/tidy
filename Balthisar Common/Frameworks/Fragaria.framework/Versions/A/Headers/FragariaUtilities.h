//
//  FragariaUtilities.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 07/07/2019.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MGSColourScheme;
@class MGSSyntaxParser;


/** Colors an attributed string with the specified parser and color scheme.
 *  @param str The attributed string to modify.
 *  @param parser The parser to use.
 *  @param scheme The color scheme. If nil, the default color scheme will
 *     be used.
 *  @warning Existing attributes are not guaranteed to be retained. On return,
 *     all font attributes will be based on the font attribute of the first
 *     character of the string. */
void MGSHighlightAttributedString(NSMutableAttributedString *str, MGSSyntaxParser *parser, MGSColourScheme * __nullable scheme);


NS_ASSUME_NONNULL_END
