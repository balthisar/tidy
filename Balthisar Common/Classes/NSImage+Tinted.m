/**************************************************************************************************
 
	NSImage+Tinted

	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

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
		NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
		[image unlockFocus];
	}
	return image;
}


@end
