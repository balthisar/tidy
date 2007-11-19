/***************************************************************************************
    TidyDocument.h -- part of Balthisar Tidy

    The main document controller. Here we'll control the following:
        o
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "JSDTidy.h"
#import "OptionPaneController.h"
#import "JSDTextView.h"

@interface TidyDocument : NSDocument
{
    // view outlets
    IBOutlet JSDTextView *sourceView;	// pointer to the source HTML view.
    IBOutlet JSDTextView *tidyView;	// pointer to the tidy'd HTML view.
    IBOutlet NSTableView *errorView;	// pointer to where to display the error messages.
    
    // items for the option controller and pane
    IBOutlet NSView *optionPane;		// pointer to our empty optionPane.
    OptionPaneController *optionController;	// this will control the real option pane loaded into optionPane
       
    // internally-used instance variables.
    JSDTidyDocument* tidyProcess;		// our tidy wrapper/processor.
    int saveBehavior;				// the save behavior from the preferences.
    bool saveWarning;				// the warning behavior for when saveBehavior == 1;
    bool yesSavedAs;				// disable warnings and protections once a save-as has been done.
    bool tidyOriginalFile;			// flags whether the file was CREATED by Tidy, for writing type/creator codes.
}

- (IBAction)optionChanged:(id)sender;	// react to a tidy'ing control being changed.

- (IBAction)errorClicked:(id)sender;	// react to an error row being clicked.

- (void)retidy;				// tidy's itself.        
@end
