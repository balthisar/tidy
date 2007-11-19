/***************************************************************************************
    BatchController.h -- part of Balthisar Tidy

    The main controller for the batch-mode interface. Here we'll control the following:
        o We're the Datasource delegate for the NSOutlineView, so handle that.
        o We're going to handle drag-and-drop on the NSOutlineView for adding files.
        o We're going to implement and control the interface for doing the Tidy'ing.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import <TreeNode.h>
#import "OptionPaneController.h"

@interface BatchController : NSWindowController {
    IBOutlet NSOutlineView *fileList;			// outlet for the NSOutlineView

    IBOutlet NSView 	 *optionPane;			// pointer to our empty optionPane.
    
    OptionPaneController *optionController;		// this will control the real option pane loaded into optionPane
    JSDTidyDocument *tidyProcess;			// this will point to the optionPaneController's tidy process.
    
    TreeNode *fileTree;					// holds a list of everything we'll batch process.
}

-(IBAction)startBatch:(id)sender;			// handler for the batch button being pressed.

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

@end
