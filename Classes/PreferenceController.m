/***************************************************************************************
    PreferenceController.m -- part of Balthisar Tidy

    The main preference controller. Here we'll control the following:
        o Handles the application preferences.
        o Implements class methods to be used before instantiation.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "PreferenceController.h"

@implementation PreferenceController

/********************************************************************
    keyNameForKeyNumber -- CLASS method.
       returns the key name for the given key number. We're going
       to use numbers instenally to reference given preferences, for
       programming convenience. But, we want the keys to have names
       for the preferences file.
*********************************************************************/
+(NSString *)keyNameForKeyNumber:(int)keyNr {
    return [[NSArray arrayWithObjects: @"IndentElements",		// 0
                                      @"OmitOptionalContent",		// 1
                                      @"WrapEnabled",			// 2
                                      @"WrapColumnNumber",		// 3
                                      @"UppercaseElements",		// 4
                                      @"CleanWithCSS",			// 5
                                      @"BareConvertSymbols",		// 6
                                      @"Numeric",			// 7
                                      @"XMLOutput",			// 8
                                      @"EncodingStlye",			// 9
                                      @"SavingPrefStyle",		// 10
                                      @"WarnBeforeOverwrite",		// 11
                                      @"OBSOLETE",			// 12
                                      @"OBSOLETE",			// 13
                                      @"BatchSavingPrefStyle",		// 14
                                      @"OBSOLETE",			// 15
                                      @"OBSOLETE",			// 16
                                      nil] objectAtIndex:keyNr];
}

/********************************************************************
    registerUserDefaults -- CLASS method.
       register all of the user defaults. Implemented as a CLASS
       method in order to keep this with the preferences controller,
       but the preferences controller won't have been created yet!
*********************************************************************/
+(void)registerUserDefaults {
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary]; // create a dictionary
    // put all of the defaults in the dictionary
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:[PreferenceController keyNameForKeyNumber:0]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:1]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:2]];
    [defaultValues setObject:[NSNumber numberWithInt:72] forKey:[PreferenceController keyNameForKeyNumber:3]];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:[PreferenceController keyNameForKeyNumber:4]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:5]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:6]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:7]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:8]];
    [defaultValues setObject:[NSNumber numberWithInt:0] forKey:[PreferenceController keyNameForKeyNumber:9]];
    [defaultValues setObject:[NSNumber numberWithInt:2] forKey:[PreferenceController keyNameForKeyNumber:10]];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:[PreferenceController keyNameForKeyNumber:11]];
    [defaultValues setObject:[NSNumber numberWithInt:1] forKey:[PreferenceController keyNameForKeyNumber:14]];
    // register the defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

/********************************************************************
    init
    Our creator -- we want to load the nib "Preferences".
*********************************************************************/
- (id)init {
    if (self = [super initWithWindowNibName:@"Preferences"]) {
        [self setWindowFrameAutosaveName:@"PrefWindow"];
    }
    return self;
}

/********************************************************************
    dealloc
        clean up.
*********************************************************************/
- (void)dealloc
{
    [super dealloc];
}

/********************************************************************
    windowDidLoad
    when the window has loaded, let's put the correct preferences on.
*********************************************************************/
- (void)windowDidLoad {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //NSLog(@"Now starting to unpack preferences...");
    [indent setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:0]]];
    [omit setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:1]]];
    [wrap setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:2]]];
    [wrapColumn setStringValue:[defaults stringForKey: [PreferenceController keyNameForKeyNumber:3]]];
    [uppercase setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:4]]];
    [clean setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:5]]];
    [bare setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:6]]];
    [numeric setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:7]]];
    [xmlOutput setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:8]]];
    [encoding selectItemAtIndex:[defaults integerForKey: [PreferenceController keyNameForKeyNumber:9]]];
    
    [saving1 setState:([defaults integerForKey: [PreferenceController keyNameForKeyNumber:10]] == 1)];
    [saving2 setState:([defaults integerForKey: [PreferenceController keyNameForKeyNumber:10]] == 2)];
    [savingWarn setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:11]]];
    [savingWarn setEnabled:[saving1 state]];

    [batchSaving1 setState:([defaults integerForKey: [PreferenceController keyNameForKeyNumber:14]] == 1)];
    [batchSaving2 setState:([defaults integerForKey: [PreferenceController keyNameForKeyNumber:14]] == 2)];
}

/********************************************************************
    radioSavingChanged
        one of the radio buttons for saving options has changed.
        Handle this apart, since we're not using a matrix.
*********************************************************************/
-(IBAction)radioSavingChanged:(id)sender {
    [saving1 setState:NO];
    [saving2 setState:NO];
    [sender setState:YES];
    [savingWarn setEnabled:[saving1 state]];
    [self preferenceChanged:nil];
}


/********************************************************************
    radioBatchChanged
        one of the radio buttons for batch options has changed.
        Handle this apart, since we're not using a matrix.
*********************************************************************/
-(IBAction)radioBatchChanged:(id)sender {
    [batchSaving1 setState:NO];
    [batchSaving2 setState:NO];
    [sender setState:YES];
    [self preferenceChanged:nil];
}

/********************************************************************
    preferenceChanged
        one of the preferences changed. Log ALL of them at once for
        simplicity. No need to track them separately.
*********************************************************************/
-(IBAction)preferenceChanged:(id)sender {
    int i = 0;
    // update the preference registry
    [[NSUserDefaults standardUserDefaults] setBool:[indent state] forKey:[PreferenceController keyNameForKeyNumber:0]];
    [[NSUserDefaults standardUserDefaults] setBool:[omit state] forKey:[PreferenceController keyNameForKeyNumber:1]];
    [[NSUserDefaults standardUserDefaults] setBool:[wrap state] forKey:[PreferenceController keyNameForKeyNumber:2]];
    [[NSUserDefaults standardUserDefaults] setObject:[wrapColumn stringValue] forKey:[PreferenceController keyNameForKeyNumber:3]];
    [[NSUserDefaults standardUserDefaults] setBool:[uppercase state] forKey:[PreferenceController keyNameForKeyNumber:4]];
    [[NSUserDefaults standardUserDefaults] setBool:[clean state] forKey:[PreferenceController keyNameForKeyNumber:5]];
    [[NSUserDefaults standardUserDefaults] setBool:[bare state] forKey:[PreferenceController keyNameForKeyNumber:6]];
    [[NSUserDefaults standardUserDefaults] setBool:[numeric state] forKey:[PreferenceController keyNameForKeyNumber:7]];
    [[NSUserDefaults standardUserDefaults] setBool:[xmlOutput state] forKey:[PreferenceController keyNameForKeyNumber:8]];
    [[NSUserDefaults standardUserDefaults] setInteger:[encoding indexOfSelectedItem] forKey:[PreferenceController keyNameForKeyNumber:9]];

    if ([saving1 state]) i = 1;
    if ([saving2 state]) i = 2;
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:[PreferenceController keyNameForKeyNumber:10]];
    [[NSUserDefaults standardUserDefaults] setBool:[savingWarn state] forKey:[PreferenceController keyNameForKeyNumber:11]];
    // send the notification that a saving preference has changed!
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JSDSavePrefChange" object:nil];

    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[PreferenceController keyNameForKeyNumber:14]];
    if ([batchSaving1 state]) [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:[PreferenceController keyNameForKeyNumber:14]];
    if ([batchSaving2 state]) [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:[PreferenceController keyNameForKeyNumber:14]];
}

@end
