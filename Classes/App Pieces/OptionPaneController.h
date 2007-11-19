/***************************************************************************************
    OptionPaneController.h -- part of Balthisar Tidy

    The main controller for the multi-use option pane. implemented separately for
        o use on a document window
        o use on the preferences window
        
    This controller parses optionsInEffect.txt in the application bundle, and compares
    the options listed there with the linked-in TidyLib to determine which options are
    in effect and valid. We use an instance of JSDTidyDocument to deal with this.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "JSDTidy.h"

@interface OptionPaneController : NSObject {
    IBOutlet NSView 	 *myView;		// pointer to the view -- will be returned by getView.
    IBOutlet NSTableView *theTable;		// pointer to the table
    IBOutlet NSTextField *theDescription;	// pointer to the description field.
    
    SEL _action;				// routine to be called (action method) when an option changes.
    id _target;					// the target for the action method (optional--can be nil targeted).
    
    NSArray 		 *optionsInEffect;	// array of NSString that holds the options we really want to use.
    NSArray		 *optionsExceptions;	// array of NSString that holds the options we want to treat as STRINGS
    JSDTidyDocument      *tidyProcess;		// our tidy wrapper/processor for dealing with valid options dynamically.

}

-(id)init;					// initialize the view so we can use it.
-(NSView *)getView;				// return the view so that it can be used in a parent window.
-(void)putViewIntoView:(NSView *)dstView;	// make the view of this controller the view of dstView.

-(IBAction)optionChanged:(id)sender;		// handle an option changing in the tableview.

-(SEL)action;					// returns the action for this controller when options change.
-(void)setAction:(SEL)theAction;		// sets the action for this controller when options change.
-(id)target;					// returns the target for this controller.
-(void)setTarget:(id)theTarget;			// sets the target -- optional, can be nil-targeted action.

-(void)tidyDocument:(JSDTidyDocument *)theDoc;	// set method for tidyProcess
-(JSDTidyDocument *)tidyDocument;		// get method for tidyProcess

@end
