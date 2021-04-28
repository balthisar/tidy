//
//  NSString+RTF.m
//  Balthisar Tidy
//
//  Created by Jim Derry on 4/28/21.
//  Copyright © 2021 Jim Derry. All rights reserved.
//

#import "NSString+RTF.h"

@implementation NSString (RTF)

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - drawRect:
    Forces redraw using the new instrinsicContentSize.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

+ (NSAttributedString *)attributedStringWithRTF:(NSString *)rtfString
{
    /* RTF can be a little complex due to legacy string encoding issues.
     * When JSDTidy is internationalized, RTF might not play nicely with
     * non-Mac character encodings. Prefixing the .plist strings with an
     * asterisk will cause the automatic conversion to and from RTF,
     * otherwise the strings will be treated normally (this maintains
     * string compatability with `NSLocalizedString`).
     */

    NSAttributedString *result;
    
    NSString *fixedFont;
    if (@available(macos 10.15, *))
    {
        fixedFont = [[NSFont monospacedSystemFontOfSize:12.0 weight:NSFontWeightRegular] familyName];
    }
    else
    {
        fixedFont = @"Andale Mono";
    }

    if ([rtfString hasPrefix:@"*"])
    {
        /* Make into RTF string. */
        
        NSString *preamble = [NSString stringWithFormat:@"{\\rtf1\\mac\\deff0{\\fonttbl{\\f0 %@;}{\\f1 .AppleSystemUIFont;}}\\f1\\fs22\\qj\\sa100", fixedFont];
        
        NSString *rawString = [[preamble stringByAppendingString:[rtfString substringFromIndex:1]] stringByAppendingString:@"}"];
        
        NSData *rawData = [rawString dataUsingEncoding:NSMacOSRomanStringEncoding];

        result = [[NSAttributedString alloc] initWithRTF:rawData documentAttributes:nil];
    }
    else
    {
        /* Use the string as-is. */

        result = [[NSAttributedString alloc] initWithString:rtfString];
    }

    return  result;
}


@end
