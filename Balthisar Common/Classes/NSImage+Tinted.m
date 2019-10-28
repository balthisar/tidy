//
//  NSImage+Tinted.m
//
//  Copyright © 2018-2019 by Jim Derry. All rights reserved.
//

#import "NSImage+Tinted.h"


@implementation NSImage (Tinted)


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - drawRect:
    Forces redraw using the new instrinsicContentSize.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/

- (NSImage *)tintedWithColor:(NSColor *)tint
{
    NSImage *image = [self copy];
    if (tint)
    {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        [image unlockFocus];
    }
    return image;
}


@end
