/***************************************************************************************
    PreferenceController.h -- part of Balthisar Tidy

    The main preference controller. Here we'll control the following:
        o Handles the application preferences.
        o Implements class methods to be used before instantiation.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "OptionPaneController.h"

extern NSString *JSDKeySavingPrefStyle;
extern NSString *JSDKeyWarnBeforeOverwrite;
extern NSString *JSDKeyBatchSavingPrefStyle;

@interface PreferenceController : NSWindowController {

    IBOutlet NSButton *saving1;			// pointer to enable save
    IBOutlet NSButton *saving2;			// pointer to disable save
    IBOutlet NSButton *savingWarn;		// pointer to warn on save

    IBOutlet NSButton *batchSaving1;		// pointer to overwrite
    IBOutlet NSButton *batchSaving2;		// pointer to backup
    
    IBOutlet NSView 	 *optionPane;		// pointer to our empty optionPane.
    OptionPaneController *optionController;	// this will control the real option pane loaded into optionPane
    
    JSDTidyDocument *tidyProcess;		// this will point to the optionPaneController's tidy process.

}
+(void)registerUserDefaults;

-(IBAction)preferenceChanged:(id)sender;	// handler for a configuration option change.
-(IBAction)radioSavingChanged:(id)sender;	// handler for a saving preference change.
-(IBAction)radioBatchChanged:(id)sender;	// handler for a batch preference change.
@end
