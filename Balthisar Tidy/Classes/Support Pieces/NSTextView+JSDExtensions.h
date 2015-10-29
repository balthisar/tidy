/**************************************************************************************************

	NSTextView+JSDExtensions

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  Some nice extensions to NSTextView, adding some features:
 *
 *  - Highlight a logical line number and column in the text view.
 *  - Turn word-wrapping on and off.
 *  - Own and instantiate its own NoodleLineNumberView.
 *
 *  Please note dependency on JanX2’s fork of Noodlekit: <https://github.com/JanX2/NoodleKit>
 */
@interface NSTextView (JSDExtensions)

/**
 *  Specifies the row number to highlight, or 0 for none.
 */
@property (nonatomic, assign) NSInteger highlitLine;

/**
 *  Specifies the the column of the row to highlight, or 0 for none.
 */
@property (nonatomic, assign) NSInteger highlitColumn;

/**
 *  Specifies if highlighting is currently shown.
 */
@property (nonatomic, assign) BOOL showsHighlight;

/**
 *  Specifies the current wordwrap state.
 */
@property (nonatomic, assign) BOOL wordwrapsText;

/**
 *  Specifies whether or not line numbers appear.
 */
@property (nonatomic, assign) BOOL showsLineNumbers;


/**
 *  Ensures that a logical line is visible in the view.
 */
- (void)scrollLineToVisible:(NSInteger)line;

/**
 *  A convenience method to highlight a row and column at once,
 *  and causing the line to scroll into view.
 */
- (void)highlightLine:(NSInteger)line Column:(NSInteger)column;

@end
