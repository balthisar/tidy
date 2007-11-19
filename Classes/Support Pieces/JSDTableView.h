/***************************************************************************************
    JSDTableView.h

    override TextDidEndEditing so that after changing a value, the selection doesn't
    advance to the next text field.
    
    FOR SOME REASON, you cannot implement this in IB -- you'll have to swap out the
    type in awakeFromNib in the controller that you use. See these methods to assist:
        initReplacingTableView:
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>


@interface JSDTableView : NSTableView {

}

- (void)textDidEndEditing:(NSNotification *)notification;		// overridden to prevent auto-advancing of cell focus


@end
