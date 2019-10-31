//
//  NSImage+Tinted.h
//
//  Copyright © 2018-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;


/**
 *  A simple category to NSImage that adds a tinted variation.
 */
@interface NSImage (Tinted)


/**
 *  Returns a copy of the image tinted with the specified color.
 */
- (NSImage *)tintedWithColor:(NSColor *)tint;


@end
