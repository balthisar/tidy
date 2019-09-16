//
//  MGSSyntaxAwareEditor.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 01/12/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/** Protocol used to support syntax-aware editing commands in Fragaria.
 *  Implemented by syntax parsers. */
@protocol MGSSyntaxAwareEditor <NSObject>


/** Returns YES if the object supports `-commentOrUncomment:`. */
@property (readonly, nonatomic) BOOL providesCommentOrUncomment;


@optional

/** Toggle comments as appropriate for the language on the
 *  given mutable string.
 *  @param string The string to be mutated. */
- (void)commentOrUncomment:(NSMutableString *)string;


@end


NS_ASSUME_NONNULL_END
