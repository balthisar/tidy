/**************************************************************************************************
 
	JSDTextField

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDTextField.h"


@implementation JSDTextField


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - drawRect:
    Forces redraw using the new instrinsicContentSize.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)drawRect:(NSRect)dirtyRect
{
	[self invalidateIntrinsicContentSize];
	[super drawRect:dirtyRect];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - intrinsicContentSize
    Properly calculates the intrinsicContentSize taking into
    consideration the actual size the text will occupy.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
-(NSSize)intrinsicContentSize
{
    if ( ![self.cell wraps] )
	{
        return [super intrinsicContentSize];
    }

	NSRect frame;
	CGFloat width;
	CGFloat height;

	if (!self.isHiddenOrHasHiddenAncestor)
	{
		frame = [self frame];
		width = frame.size.width;

		frame.size.height = CGFLOAT_MAX;

		height = [self.cell cellSizeForBounds: frame].height;
	}
	else
	{
		width = 0;
		height = 0;
	}

    return NSMakeSize(width, height);
}

@end
