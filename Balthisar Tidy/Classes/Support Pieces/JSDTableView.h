/**************************************************************************************************

	JSDTableView

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

#import "JSDTableViewDelegate.h"


/**
 *  This simple NSTableView subclass that adds a couple of things:
 *
 *  - captures keyDown and reports this to the delegate.
 *
 *  - overrides validateProposedFirstResponder:forEvent in order to allow controls
 *    in a table view that would ordinarily never be allowed to be first responder.
 *
 *  - binds to JSDKeyOptionsAlternateRowColors in preferences to control its own
 *    usesAlternatingRowBackgroundColors property.
 */
@interface JSDTableView : NSTableView <JSDTableViewDelegate>

@end

