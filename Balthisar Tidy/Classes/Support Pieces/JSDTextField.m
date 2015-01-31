/**************************************************************************************************
 
	JSDTextField

	Simple NSTextField subclass that

		- fixes the intrinsicContentSize when using auto layout and multiline, wrapping labels.

	The MIT License (MIT)

	Copyright (c) 2001 to 2013 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import "JSDTextField.h"


@implementation JSDTextField


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 drawRect:
		 Forces redraw using the new instrinsicContentSize.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)drawRect:(NSRect)dirtyRect
{
	[self invalidateIntrinsicContentSize];
	[super drawRect:dirtyRect];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 intrinsicContentSize
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
