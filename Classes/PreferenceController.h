/***************************************************************************************
    PreferenceController.h -- part of Balthisar Tidy

    The main preference controller. Here we'll control the following:
        o Handles the application preferences.
        o Implements class methods to be used before instantiation.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>

@interface PreferenceController : NSWindowController {
        IBOutlet NSButton *indent;
        IBOutlet NSButton *omit;
        IBOutlet NSButton *wrap;
        IBOutlet NSTextField *wrapColumn;
        IBOutlet NSButton *uppercase;
        IBOutlet NSButton *clean;
        IBOutlet NSButton *bare;
        IBOutlet NSButton *numeric;
        IBOutlet NSButton *xmlOutput;
        IBOutlet NSPopUpButton *encoding;

        IBOutlet NSButton *saving1;
        IBOutlet NSButton *saving2;
        IBOutlet NSButton *savingWarn;

        IBOutlet NSButton *batchSaving1;
        IBOutlet NSButton *batchSaving2;
}
+(NSString *)keyNameForKeyNumber:(int)keyNr;
+(void)registerUserDefaults;

-(IBAction)preferenceChanged:(id)sender;
-(IBAction)radioSavingChanged:(id)sender;
-(IBAction)radioBatchChanged:(id)sender;
@end
