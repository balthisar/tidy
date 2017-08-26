/**************************************************************************************************
 
	JSDTextField

	Copyright © 2003-2017 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  A simple subclass of NSTextField that
 *
 *  - fixes the `intrinsicContentSize` when using auto layout and multiline, wrapping labels.
 */
@interface JSDTextField : NSTextField

@end
