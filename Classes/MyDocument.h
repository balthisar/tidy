/***************************************************************************************
    MyDocument.h -- part of Balthisar Tidy

    The main document controller. Here we'll control the following:
        o
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import <CocoaTidy.h>

@interface MyDocument : NSDocument
{
    NSString *processString;		// string to hold for processing/loading
    
    // view outlets
    IBOutlet NSTextView *sourceView;	// pointer to the source HTML view.
    IBOutlet NSTextView *tidyView;	// pointer to the tidy'd HTML view.
    IBOutlet NSTextView *errorView;	// pointer to where to display the error messages.
    
    // tidy controls
    IBOutlet NSButton *checkIndent;	
    IBOutlet NSButton *checkOmit;
    IBOutlet NSButton *checkWrap;
    IBOutlet NSTextField *valWrap;
    IBOutlet NSButton *checkUppercase;
    IBOutlet NSButton *checkClean;
    IBOutlet NSButton *checkBare;
    IBOutlet NSButton *checkNumeric;
    IBOutlet NSButton *checkXML;
    IBOutlet NSPopUpButton *menuEncoding;
    
    // internally-used instance variables.
    CocoaTidy* tidyProcess;		// our tidy wrapper/processor.
    int saveBehavior;			// the save behavior from the preferences.
    bool saveWarning;			// the warning behavior for when saveBehavior == 1;
    bool yesSavedAs;			// disable warnings and protections once a save-as has been done.
    bool tidyOriginalFile;		// flags whether the file was CREATED by Tidy, for writing type/creator codes.
}

- (IBAction)optionChanged:(id)sender;	// react to a tidy'ing control being changed.

@end
