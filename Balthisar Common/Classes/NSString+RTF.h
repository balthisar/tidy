//
//  NSString+RTF.h
//  Balthisar Tidy
//
//  Created by Jim Derry on 4/28/21.
//  Copyright © 2021 Jim Derry. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A simple category to NSString to process raw RTF into an attributed string in the Balthisar Tidy style.
 */
@interface NSString (RTF)

+ (NSAttributedString *)attributedStringWithRTF:(NSString *)rtfString;

@end

NS_ASSUME_NONNULL_END
