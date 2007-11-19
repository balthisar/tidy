/***************************************************************************************
    JSDTextView.m

    Modify NSTextView for a single, special purpose. We will:
        o non-wrapping text with a line counter to the left.
        o self contained (hence multiple classes in this header)
        
    We will:
        o hand-build an NSScrollView, NSTextView, NSLayoutManager, NSTextContainer,
          and NSTextStorage for textView, and add a JSDNumberView for numberView
        o allow turning wrapping of text to YES or NO.
        o allow turning line number counting to YES or NO.
        o allow highlighting a given row and column.
***************************************************************************************/

#import "JSDTextView.h"

const float LargeNumberForText = 1.0e7;

//========================================================================================================
// IMPLEMENTATION JSDNumberView
//========================================================================================================

@implementation JSDNumberView

/********************************************************************
    textView:
       accessor get method for _owner
*********************************************************************/
-(JSDTextView *)owner {
    return _owner;
} // textView

/********************************************************************
    setTextView:
       accessor set method for _owner -- NOT retained.
*********************************************************************/
-(void)setOwner:(JSDTextView *)theView {
    _owner = theView;
} // setTextView

/********************************************************************
    setWidth:
       sets a new width for the number drawing.
*********************************************************************/
-(void)setWidth:(float)value {
    float adjWidth = (value - [self frame].size.width);			// amount to adjust -- pos=bigger, neg=smaller.
    
    NSRect tmpFrame = [[_owner scrollView] frame];			// get the scrollView frame.
    tmpFrame.origin.x += adjWidth;					// new origin position.
    tmpFrame.size.width += -adjWidth;					// new width.
    [[_owner scrollView] setFrame:tmpFrame];				// set the new frame.
    
    tmpFrame = [self frame];						// get the current frame
    tmpFrame.size.width += adjWidth;					// new width.
    [self setFrame:tmpFrame];

    [_owner setNeedsDisplay:YES];					// flag _owner needs updated.
    [self setNeedsDisplay:YES];						// flag we need updated.
} // setTextView


/********************************************************************
    drawRect:
       overridden drawRect does the drawing of the line numbers.
*********************************************************************/
- (void)drawRect:(NSRect)rect {
    // fill in the background
    [[NSColor windowBackgroundColor] set];		// use Mac OS X' background stripe
    [NSBezierPath fillRect:rect];			// fill the rect
    
    // only draw if there's an associated _owner. This means it's assigned -- hope it's not released! Any ideas to check?
    // also only draw if _showLineNumbers is true
    if ((_owner) && (_showLineNumbers)) {

        // adjust rect so we won't later draw into the scrollbar area
        if ([[_owner scrollView] hasHorizontalScroller]) {
            float j = [[[_owner scrollView] horizontalScroller] frame].size.height / 2;	// get size of the scroller
            rect.origin.y += j;		// shift the drawing frame reference up.
            rect.size.height += -j;	// and shrink it the same distance.
        } // if scrollview present

        // setup drawing attributes for the font size and color. Later we could add accessors to do this dynamically.
        NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
        [attr setObject:[NSFont fontWithName: @"Courier" size: 12] forKey: NSFontAttributeName];
        [attr setObject:[NSColor controlTextColor] forKey: NSForegroundColorAttributeName];
        
        // setup the variables we need for the loop
        NSRange	aRange;							// a range for counting lines
        NSString *s;							// a temporary string
        int i = 0;							// glyph counter
        int j = 1; 							// line counter
        float reqWidth;							// width calculator holder -- width needed to show string
        float widest = 1;						// to calculate widest width needed - MIN 1!
        float myWidth;							// width calculator holder -- my current width
        NSRect r;							// rectange holder
        NSPoint p;							// point holder
        NSLayoutManager *lm = [[_owner textView] layoutManager];	// get _owner's layout manager.
        
        // the line number counting and drawing loop
        while ( i < [lm numberOfGlyphs] ) {
        
            // get the coordinates for the current glyph's entire-line rectangle, and converts to local coordinates.
            r = [self convertRect:[lm lineFragmentRectForGlyphAtIndex:i effectiveRange:&aRange] fromView:[_owner textView]];
            r.origin.x = rect.origin.x; 	// don't care about x -- just force it into the rect
            
            // if true, we should draw because we're in the rectangle being updated.
            if (NSPointInRect(r.origin, rect)) {
                s = [NSString stringWithFormat:@"%d", j, nil];	// make a string from the line counter.
                
                reqWidth = [s sizeWithAttributes:attr].width;	// width required to draw the string.
                if (reqWidth > widest)				// get widest width there is.
                    widest = reqWidth;	
                myWidth = [self frame].size.width;		// get my own, current width.
                if (myWidth < reqWidth)
                    [self setWidth:reqWidth];			// set a wider width if needed.
                    
                p = NSMakePoint((myWidth - reqWidth), r.origin.y);	// calculate to right-align and vertically place the string
                [s drawAtPoint:p withAttributes:attr];			// draw the current line number.
            } // if okay to draw

            i += [[[[_owner textView] string] substringWithRange:aRange] length];	// advance glyph counter to EOL
            j ++;									// increment the line number
        } // while
        [self setWidth:widest];	// set to the widest width needed, which could be narrower than before.
        [attr release];		// free up the no-longer-needed attributes
    } // if owner
} // drawRect

/********************************************************************
    showLineNumbers:
       we're going return _showLineNumbers
*********************************************************************/
-(BOOL)showLineNumbers {
    return _showLineNumbers;
} // showLineNumbers

/********************************************************************
    setShowLineNumbers:
       we're going to set whether we're showing line numbers or not.
*********************************************************************/
-(void)setShowLineNumbers:(BOOL)value {
    if (value != _showLineNumbers) {
        _showLineNumbers = !_showLineNumbers;
        if (!_showLineNumbers)
            [self setWidth:0]; // hides it effectively.
        else
            [self setWidth:1]; // just to open it up.
        [self setNeedsDisplay:YES];
    } // if
} // setShowLineNumbers

@end; // JSDNumberView



//========================================================================================================
// IMPLEMENTATION JSDTextView
//========================================================================================================

@implementation JSDTextView

/********************************************************************
    scrollView:
       expose the enclosing scrollview.
*********************************************************************/
-(NSScrollView *)scrollView {
    return _scrollView;
} // scrollView

/********************************************************************
    layoutManager:
       expose the layout manager
*********************************************************************/
-(NSLayoutManager *)layoutManager {
    return _layoutManager;
} // layoutManager

/********************************************************************
    textContainer:
       expose the text container
*********************************************************************/
-(NSTextContainer *)textContainer {
    return _textContainer;
} // textContainer

/********************************************************************
    textView:
       expose the text view
*********************************************************************/
-(NSTextView *)textView {
    return _textView;
} // textView

/********************************************************************
    numberView:
       expose the number view
*********************************************************************/
-(JSDNumberView *)numberView {
    return _numberView;
} // numberView


/********************************************************************
    setupViews:
       let's build the text system by hand.
*********************************************************************/
-(void)setupViews {
    // setup the items we need to make this work.
    NSRect textFrame;									// the frame for textView.
    NSRect numberFrame;									// the frame for numberView.
    NSRect scrollFrame;									// the frame for the scrollView.

    // Create our text storage for the NSTextView
    NSTextStorage *textStorage = [[NSTextStorage alloc] init];				// NSTextView's text storage.

    // Create and configure the numberView
    numberFrame = [self bounds];							// get our frame.
    numberFrame.origin = NSMakePoint(0.0, 0.0);						// set our origin.
    numberFrame.size.width = 1;								// default width (about invisible).
    _numberView = [[JSDNumberView allocWithZone:[self zone]] initWithFrame:numberFrame];// initialize it.
    [_numberView setAutoresizingMask:NSViewHeightSizable];				// set it's vertical resizing.
    [_numberView setShowLineNumbers:YES];						// show line numbers by default.
    [_numberView setOwner:self];							// set the numberView's owner
    [self addSubview:_numberView];   							// add it to us.

    // Create NSScrollView -- this will enclose everything else.
    scrollFrame = [self bounds];							// get our frame.
    scrollFrame.origin.x = 1+1;								// adjust the origin.
    scrollFrame.size.width = (scrollFrame.size.width - (1+1));				// adjust the width.
    _scrollView = [[NSScrollView allocWithZone:[self zone]] initWithFrame:scrollFrame];	// create and initialize it.
    [_scrollView setBorderType:NSBezelBorder];						// make the border normal.
    [_scrollView setHasVerticalScroller:YES];						// put in the Vertical scroller.
    [_scrollView setHasHorizontalScroller:YES];						// put in the Horizontal scroller.
    [_scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];	// resize mask for the scroll view.
    [[_scrollView contentView] setAutoresizesSubviews:YES];				// the contentview will autoresize subviews.
    [self addSubview:_scrollView];							// add the scrollview as our subview.
        
    // Create NSSLayoutManager
    _layoutManager = [[NSLayoutManager allocWithZone:[self zone]] init];		// create the TextView's layout manager.
    [textStorage addLayoutManager:_layoutManager];					// add it to the text storage we already created.

    // Create and configure NSTextContainer
    _textContainer = [[NSTextContainer allocWithZone:[self zone]] initWithContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [_textContainer setWidthTracksTextView:NO];						// we don't want to be the same width as view!
    [_textContainer setHeightTracksTextView:NO];					// we don't want to be the same height as view!
    [_layoutManager addTextContainer:_textContainer];					// add the text container to the layout manager.
    
    // Create and configure NSTextView
    textFrame.origin = NSMakePoint(0.0, 0.0);						// get our origin.
    textFrame.size = [_scrollView contentSize];						// frame will start at upper left.
    _textView = [[JSDTextViewSub allocWithZone:[self zone]] initWithFrame:textFrame textContainer:_textContainer]; // initialize it.
    [_textView setMinSize:textFrame.size];						// set the minimum size.
    [_textView setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];		// set the maximum size.
    [_textView setHorizontallyResizable:YES];						// it's resizable horizontally.
    [_textView setVerticallyResizable:YES];						// it's resizable vertically.
    [_textView setAutoresizingMask:NSViewNotSizable];					// don't let it autosize, though.
    [_scrollView setDocumentView:_textView];						// make this the documentview of the scroller.

    // update friend views.
    [_textView setFriendView:_numberView];						// the textview will also update our friend.
    
    // release things retained by the system
    [_textContainer release];								// release it -- already retained by adding it.
    [_scrollView release];								// release the scrollview -- already retained.
    [_textView release];								// decrease the reference count.
} // setupViews

/********************************************************************
    initWithFrame:
       initialize the view.
*********************************************************************/
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews]; // setup all of the views we need!
        if (delegate)
            [self setDelegate:delegate];
    }
    return self;
} // initWithFrame;


/********************************************************************
    string:
       we're going to pass to _textView:string (convenience)
*********************************************************************/
-(NSString *)string {
    return[ _textView string];
} // string

/********************************************************************
    setString:
       we're going to pass to _textView:setString (convenience)
*********************************************************************/
-(void)setString:(NSString *)aString {
    [_textView setString:aString];
} // setString

/********************************************************************
    setDelegate:
       set the delegate for this class, which really sets the
       delegate for the TextView underneath! We only want to
       support this for Interface Builder's sake.
*********************************************************************/
- (void)setDelegate:(id)anObject {
    [anObject retain];
    [delegate release];
    delegate = anObject;
    [_textView setDelegate:anObject];
} // setDelegate

/********************************************************************
    initWithFrame:
       return the current delegate of the textview underneath.
 *********************************************************************/
- (id)delegate {
    return [_textView delegate];
} // delegate

/********************************************************************
    showLineNumbers:
       pass this to the numberview we're hosting below.
 *********************************************************************/
-(BOOL)showLineNumbers {
    if (_numberView)
        return [_numberView showLineNumbers];
    else
        return NO;
} // showLineNumbers

/********************************************************************
    setShowLineNumbers:
       set this in the numberview we're hosting below.
 *********************************************************************/
-(void)setShowLineNumbers:(BOOL)value {
    if (_numberView)
        [_numberView setShowLineNumbers:value];
} // setShowLineNumbers

/********************************************************************
    wordWrap:
       returns the word-wrap state
*********************************************************************/
-(BOOL)wordWrap {
    return _wordWrap;
} // wordWrap

/********************************************************************
    adjustTextFrameSize:
       if we're word wrapping, adjust the size of the textcontainer
       to account for the presence of the numberview. Right now
       it's ONLY called by setWordWrap, but it's applied here
       in case I discover I need to manually force the width
       adjustment at some time.
 *********************************************************************/
-(void)adjustTextFrameSize {
    if (_wordWrap) {
        int i = [_scrollView frame].size.width;			// width of the enclosing scrollview
        if ([_numberView showLineNumbers])
            i -= ( [_numberView frame].size.width + 2 );	// account for numberView size if applicable
            
        [_textContainer setContainerSize:NSMakeSize(i, LargeNumberForText)]; // set the frame size
    } // if _wordWrap
} // adjustTextFrameSize

/********************************************************************
    setWordWrap:
       sets wordwrap to YES or NO
 *********************************************************************/
-(void)setWordWrap:(BOOL)value {
    if (_wordWrap != value) {
        _wordWrap = value;					// YES = wordWrap
        if (_wordWrap) {
            [_scrollView setHasHorizontalScroller:NO];		// don't need horizontal scroller
            [_textView setAutoresizingMask:NSViewWidthSizable];	// let it autosize.
            [self adjustTextFrameSize];
            [_textContainer setWidthTracksTextView:YES];	// will follow the width of the textview.
            [_textView sizeToFit];
        } // if wordwrap
        else {
            [_scrollView setHasHorizontalScroller:YES];		// need horizontal scroller
            [_textContainer setWidthTracksTextView:NO];		// will NOT follow the width of the textview - stays static.
            [_textContainer setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)]; // set the frame size
            [_textView setAutoresizingMask:NSViewNotSizable];	// don't let it autosize, though.
        } // else no wordwrap
        [self setNeedsDisplay:YES];
    } //if
} // setWordWrap

/********************************************************************
    setHighlightedLine:
       sets a line to be highlighted -- passed to the textview
 *********************************************************************/
-(void)setHighlightedLine:(int)line column:(int)column{
    [_textView setHighlightedLine:line column:column];
} // setHighlightedLine

@end // JSDTextview


//========================================================================================================
// IMPLEMENTATION JSDTextViewSub
//========================================================================================================
@implementation JSDTextViewSub

/********************************************************************
    highlightLightedLine:
       sets _litLine to be highlighted.
 *********************************************************************/
-(void)highlightLightedLine {
    // setup the variables we need for the loop
    NSRange aRange;						// a range for counting lines
    NSRange lineCharRange;					// a range for counting lines
    int i = 0;							// glyph counter
    int j = 1; 							// line counter
    int k;							// column counter
    NSRect r;							// rectange holder
    NSLayoutManager *lm = [self layoutManager];			// get layout manager.

    // Remove any existing coloring.
    [lm removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
    
    // only highlight if there's a row to highlight.
    if (_litLine >= 1) {
        // the line number counting loop
        while ( i < [lm numberOfGlyphs] ) {
            r = [lm lineFragmentRectForGlyphAtIndex:i effectiveRange:&aRange];	// get the range for the current line.
            // if the current line is what we're looking for, then highlight it!
            if (j == _litLine) { 
                k = [lm characterIndexForGlyphAtIndex:i] + _litColumn - 1;			// the column position
                lineCharRange = [lm characterRangeForGlyphRange:aRange actualGlyphRange:NULL];	// the whole role range
                // color them
                [lm addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor cyanColor], NSBackgroundColorAttributeName, nil] forCharacterRange:lineCharRange];
                [lm addTemporaryAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor magentaColor], NSBackgroundColorAttributeName, nil] forCharacterRange:NSMakeRange(k, 1)];
            } // if
            i += [[[self string] substringWithRange:aRange] length];		// advance glyph counter to EOL
            j ++;								// increment the line number
        } // while
    } // if
} // highlightLightedLine

/********************************************************************
    scrollIntoView:
       scrolls to line
 *********************************************************************/
-(void)scrollIntoView:(int)line {
    // setup the variables we need for the loop
    NSRange aRange;						// a range for counting lines
    int i = 0;							// glyph counter
    int j = 1; 							// line counter
    NSRect r;							// rectange holder
    NSLayoutManager *lm = [self layoutManager];			// layout manager.
    if (line >= 1) {
        // the line number counting loop
        while ( i < [lm numberOfGlyphs] ) {
            r = [lm lineFragmentRectForGlyphAtIndex:i effectiveRange:&aRange];	// get the range for the current line.
            // if the current line is what we're looking for, then scroll to it
            if (j == line) {
                [self scrollRangeToVisible:aRange];				// scroll it into view
            } // if
            i += [[[self string] substringWithRange:aRange] length];		// advance glyph counter to EOL
            j ++;								// increment the line number
        } // while
    } // if
} // scrollIntoView


/********************************************************************
    get the friend view, i.e., who else to update with me.
 *********************************************************************/
-(NSView *)friendView {
    return _friendView;
} // friendView

/********************************************************************
    set the friend view, i.e., who else to update with me.
 *********************************************************************/
-(void)setFriendView:(NSView *)theView {
    _friendView = theView;
} // setFriendView

/********************************************************************
    also draw the friend view.
 *********************************************************************/
-(void)drawRect:(NSRect)rect {
//    [self highlightLightedLine];
    [super drawRect:rect];
    [_friendView setNeedsDisplay:YES];
} // drawRect

/********************************************************************
    setHighlightedLine:
       sets a line to be highlighted.
 *********************************************************************/
-(void)setHighlightedLine:(int)line column:(int)column {
    _litLine = line;
    _litColumn = column;
    [self scrollIntoView:line];			// scroll it into view    
    [_friendView display];
    [self highlightLightedLine];		// highlight the line
} // setHighlightedLine

@end // JSDTextViewSub
