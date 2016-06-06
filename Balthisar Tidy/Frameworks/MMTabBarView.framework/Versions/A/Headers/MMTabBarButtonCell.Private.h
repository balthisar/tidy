//
//  MMTabBarButtonCell.Private.h
//  MMTabBarView
//
//  Created by Michael Monscheuer on 23/05/15.
//  Copyright (c) 2016 Michael Monscheuer. All rights reserved.
//

@interface MMTabBarButtonCell (PrivateDrawing)

- (NSRect)_closeButtonRectForBounds:(NSRect)theRect;
- (CGFloat)_leftMargin;
- (CGFloat)_rightMargin;

- (void)_drawObjectCounterWithFrame:(NSRect)frame inView:(NSView *)controlView;
- (void)_drawIconWithFrame:(NSRect)frame inView:(NSView *)controlView;

@end