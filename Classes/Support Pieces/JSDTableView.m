/***************************************************************************************
    JSDTableView.h

    override TextDidEndEditing so that after changing a value, the selection doesn't
    advance to the next text field.
    
    FOR SOME REASON, you cannot implement this in IB -- you'll have to swap out the
    type in awakeFromNib in the controller that you use. See these methods to assist:
        initReplacingTableView:
 ***************************************************************************************/


#import "JSDTableView.h"


@implementation JSDTableView

/********************************************************************
    textDidEndEditing:
    make the tableview not advance to the next focusable item unless
    the user uses the tab/shift-tab key.
*********************************************************************/
- (void)textDidEndEditing:(NSNotification *)aNotification {
    //This is ugly, but just about the only way to do it. NSTableView
    //is determined to select and edit something else, even the text field
    //that it just finished editing, unless we mislead it about what key
    //was pressed to end editing.
    NSMutableDictionary *newUserInfo;
    NSNotification *newNotification;

    newUserInfo = [NSMutableDictionary dictionaryWithDictionary:[aNotification userInfo]];
    [newUserInfo setObject:[NSNumber numberWithInt:0] forKey:@"NSTextMovement"];
    newNotification = [NSNotification notificationWithName:[aNotification name] object:[aNotification object] userInfo:newUserInfo];
    [super textDidEndEditing:newNotification];
    [[self window] makeFirstResponder:self];
    [NSApp sendAction:_action to:_target from:self];    // good thing the inherited _action and _target are so named! doing this
                                                        // override doesn't send the action unless we send it ourself!

} // textDidEndEditing


@end
