/***************************************************************************************
    MyDocument.m -- part of Balthisar Tidy

    The main document controller. Here we'll control the following:
        o File I/O, including the use of type/creator codes.
        o Dirty file detection.
        o Handle Preferences
        o Handle Options for running Tidy
        o Tidy
 ***************************************************************************************/

//=============================================================================================
//    NOTES ABOUT "DIRTY FILE" DETECTION
//        We're doing a few convoluted things to allow undo in the
//    sourceView while not messing up the document dirty flags.
//    Essentially, whenever the [sourceView] <> [tidyView], we're going
//    to call it dirty. Whenever we write a file, it's obviously fit to be the source file,
//    and we can then put it in the sourceView.
//=============================================================================================

//=============================================================================================
//    NOTES ABOUT TYPE/CREATOR CODES
//        Mac OS X is trying to kill type/creator codes. Oh well. But they're still supported
//    and I continue to believe they're betting than Windows-ish file extensions. We're going
//    to try to make everybody happy by doing the following:
//       o For files that Tidy creates by the user typing into the sourceView, we'll save them
//         with the Tidy type/creator codes. We'll use WWS2 for Balthisar Tidy creator, and
//         TEXT for filetype. (I shouldn't use WWS2 'cos that's Balthisar Cascade type!!!).
//       o For *existing* files that Tidy modifies, we'll check to see if type/creator already
//         exists, and if so, we'll re-write with the existing type/creator, otherwise we'll
//         not use any type/creator and let the OS do its own thing in Finder.
//=============================================================================================

#import "MyDocument.h"
#import "CocoaTidy.h"
#import "PreferenceController.h"

@implementation MyDocument

//=============================================================================================
//                                      FILE I/O HANDLING
//=============================================================================================

/********************************************************************
    readFromFile:
    Called as part of the responder chain. We already have a name
    and type as a result of (1) the file picker, or (2) opening a
    document from Finder. Here, we'll merely load the file contents
    into a string, and process it when the nib awakes (since we're
    likely to be called here before the nib and its controls exist).
*********************************************************************/
- (BOOL)readFromFile:(NSString *)filename ofType:(NSString *)docType {
    [processString release];
    processString = [NSString stringWithContentsOfFile:filename]; // load the file.
    [processString retain];
    tidyOriginalFile = NO; // the current file was OPENED, not a Tidy original.
    return YES; // yes, it was loaded successfully.
}

/********************************************************************
    dataRepresentationOfType
    Called as a result of saving files. All we're going to do is
    pass back a string, because we're only dealing with simple text
    file.
*********************************************************************/
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    return (NSData *)[tidyView string];
}

/********************************************************************
    writeToFile
    Called as a result of saving files, and does the actual writing.
    We're going to override it so that we can update the sourceView
    automatically any time the file is saved. The logic is, once the
    file is saved, the sourceview ought to reflect the actual file
    contents, which is the tidy'd view.
*********************************************************************/
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
    bool success = [super writeToFile:fileName ofType:type];
        if (success) {
            [sourceView setString:[tidyView string]]; 	// update the sourceView with the newly-saved contents.
            yesSavedAs = YES;				// this flag disables the warnings, since they're meaningless now.
        }
    return success;
}

/********************************************************************
    fileAttributesToWriteToFile:ofType:saveOperation
    Called as a result of saving files. We're going to support the
    use of HFS+ type/creator codes, since Cocoa doesn't do this
    automatically. We only do this on files that haven't been
    opened by Tidy. That way, Tidy-created documents show the Tidy
    icons, and documents that were merely opened retain thier
    original file associations. We COULD make this a preference
    item such that Tidy will always add type/creator codes.
*********************************************************************/
- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath
                                       ofType:(NSString *)documentTypeName
                                saveOperation:(NSSaveOperationType)saveOperationType {
    // get the inherited dictionary.
    NSMutableDictionary *myDict = (NSMutableDictionary *)[super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType];
    // ONLY add type/creator if this is an original file -- NOT if we opened the file.
    if (tidyOriginalFile) {
        [myDict setObject:[NSNumber numberWithUnsignedLong:'WWS2'] forKey:NSFileHFSCreatorCode];
        [myDict setObject:[NSNumber numberWithUnsignedLong:'TEXT'] forKey:NSFileHFSTypeCode];
    } else { // use original type/creator codes, if any.
        OSType macType = [ [ [ NSFileManager defaultManager ] fileAttributesAtPath: fullDocumentPath traverseLink: YES ] fileHFSTypeCode];
        OSType macCreator = [ [ [ NSFileManager defaultManager ] fileAttributesAtPath: fullDocumentPath traverseLink: YES ] fileHFSCreatorCode];
        if ((macType != 0) && (macCreator != 0)) {
            [myDict setObject:[NSNumber numberWithUnsignedLong:macCreator] forKey:NSFileHFSCreatorCode];
            [myDict setObject:[NSNumber numberWithUnsignedLong:macType] forKey:NSFileHFSTypeCode];
        }
    }
    return myDict;
}

/********************************************************************
    revertToSavedFromFile:ofType
    allow the default reversion to take place, and then put the
    correct value in the editor if it took place.
*********************************************************************/
- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type {
    bool didRevert = [super revertToSavedFromFile:fileName ofType:type];
    if (didRevert)
        [sourceView setString:processString];
    return didRevert;
}

/********************************************************************
    saveDocument
    we're going to override the default save to make sure we can
    comply with the user's preferences. We're being over-protective
    because we want to not get blamed for screwing up the users'
    data if Tidy doesn't process something correctly.
*********************************************************************/
- (IBAction)saveDocument:(id)sender {
    // normal save, but with a warning and chance to back out. Here's the logic for how this works:
    // (1) the user requested a warning before overwriting original files.
    // (2) the sourceView isn't empty.
    // (3) the file hasn't been saved already. This last is important, because if the file has
    //     already been edited and saved, there's no longer an "original" file to protect.
    // warning will only apply if there's a current file and it's NOT been saved yet, and it's not new.
    if ((saveBehavior == 1) && (saveWarning) && (yesSavedAs == NO) && ([[self fileName] length] != 0 )) {
        int i = NSRunAlertPanel(NSLocalizedString(@"WarnSaveOverwrite", nil), NSLocalizedString(@"WarnSaveOverwriteExplain", nil),
                                NSLocalizedString(@"continue save", nil),NSLocalizedString(@"do not save", nil) , nil);
        if (i == NSAlertAlternateReturn)
            return; // don't let user continue the save operation if he chose don't save.
    }
    
    // save is completely disabled -- tell user to Save As…
    if (saveBehavior == 2) {
        NSRunAlertPanel(NSLocalizedString(@"WarnSaveDisabled", nil), NSLocalizedString(@"WarnSaveDisabledExplain", nil),
                            NSLocalizedString(@"cancel", nil), nil, nil);
        return; // don't let user continue the save operation.
    }
    
    return [super saveDocument:sender];
} // end saveDocument

//=============================================================================================
//                         INITIALIZATION, DESTRUCTION, AND SETUP
//=============================================================================================

/********************************************************************
    init
    Our creator -- create the tidy processor and the processString.
    Also be registered to receive preference notifications for the
    file-saving preferences.
*********************************************************************/
- (id)init
{
    if ([super init]) {
        tidyProcess = [[CocoaTidy init] alloc];
        processString = @"";
        tidyOriginalFile = YES; // if yes, we'll write file/creator codes.
        // register for notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSavePrefChange:) name:@"JSDSavePrefChange" object:nil];
    }
    return self;
}

/*********************************************************************
    dealloc
    our destructor -- get rid of the tidy processor and processString
**********************************************************************/
- (void)dealloc
{   
    // don't foget to removed ourselves from the Notification Center!
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [tidyProcess release];
    [processString release];
    [super dealloc];
}

/********************************************************************
    configureViewSettings
        given aView, make it non-wrapping. Also set fonts.
*********************************************************************/
- (void)configureViewSettings:(NSTextView *)aView {
    const float LargeNumberForText = 1.0e7;
    NSScrollView *scrollView = (NSScrollView *)[[aView superview] superview];	// get the TextView's scroll-view.
    NSTextContainer *container = [aView textContainer];				// get the textContainer object.

    [scrollView setHasHorizontalScroller:YES];					// sets the scroll-view attributes.
    [scrollView setHasVerticalScroller:YES];					// sets the scroll-view attributes.
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];// sets auto-resizing.
    [[scrollView contentView] setAutoresizesSubviews:YES];			// sets auto-resizing.

    [container setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [container setWidthTracksTextView:NO];
    [container setHeightTracksTextView:NO];
    
    [aView setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [aView setHorizontallyResizable:YES];
    [aView setVerticallyResizable:YES];
    [aView setAutoresizingMask:NSViewNotSizable];

    [aView setFont:[NSFont fontWithName:@"Courier" size:12]];			// set the font for the views.
}

/********************************************************************
    windowControllerDidLoadNib:
    The nib is loaded. If there's a string in processString, it will
    appear in the sourceView.
*********************************************************************/
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    
    // configure the view settings that we can't in IB.
    [self configureViewSettings:sourceView];
    [self configureViewSettings:tidyView];
    [self configureViewSettings:errorView];
    
    // honor the defaults system defaults.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [checkIndent setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:0]]];
    [checkOmit setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:1]]];
    [checkWrap setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:2]]];
    [valWrap setStringValue:[defaults stringForKey: [PreferenceController keyNameForKeyNumber:3]]];
    [checkUppercase setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:4]]];
    [checkClean setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:5]]];
    [checkBare setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:6]]];
    [checkNumeric setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:7]]];
    [checkXML setState:[defaults boolForKey: [PreferenceController keyNameForKeyNumber:8]]];
    [menuEncoding selectItemAtIndex:[defaults integerForKey: [PreferenceController keyNameForKeyNumber:9]]];

    // saving behavior settings
    saveBehavior = [defaults integerForKey:[PreferenceController keyNameForKeyNumber:10]];
    saveWarning = [defaults boolForKey:[PreferenceController keyNameForKeyNumber:11]];
    yesSavedAs = NO;
    
    // make the sourceView string the same as our processString.
    [sourceView setString:processString];

    // force the processing to occur.
    [self optionChanged:self];
}

/********************************************************************
    windowNibName
    return the name of the Nib associated with this class.
*********************************************************************/
- (NSString *)windowNibName
{
    return @"MyDocument";
}

//=============================================================================================
//                        PREFERENCES, TIDY OPTIONS, AND TIDYING
//=============================================================================================

/********************************************************************
    handleSavePrefChange
    this method receives "JSDSavePrefChange" notifications, so that
    we can keep abreast of the user's desired "Save" behaviours.
*********************************************************************/
- (void)handleSavePrefChange:(NSNotification *)note
{
    saveBehavior = [[NSUserDefaults standardUserDefaults] integerForKey:[PreferenceController keyNameForKeyNumber:10]];
    saveWarning = [[NSUserDefaults standardUserDefaults] boolForKey:[PreferenceController keyNameForKeyNumber:11]];
}

/********************************************************************
    TidyCurrentDocument
        do the actual tidying of the document.
*********************************************************************/
-(void)TidyCurrentDocument {
    // set the text in the tidyProcess
    [tidyProcess setOriginalText:[sourceView string]];
    //perform the tidy process
    [tidyProcess performTidy];
    // show the output in the document window.
    [tidyView setString:[tidyProcess tidyText]];
    [errorView setString:[tidyProcess errorText]];
    // our definition of "dirty" will be any time the tidyText is not the same as originalText
    // granted, the user can cheat by copying the tidyText to the originalText, but oh well. The point is
    // we want to make sure the user has the chance to save if the tidy is not the same as source.
    if (([[sourceView string] isEqual:[tidyView string]]) || ([[sourceView string] length] == 0))
        [self updateChangeCount:NSChangeCleared];
    else
        [self updateChangeCount:NSChangeDone];
}

/********************************************************************
    textDidChange:
        we arrived here by virtue of this document class being the
        delegate of sourceView. Whenever the text changes, let's
        reprocess all of the text. Hopefully the user won't be
        inclined to type everything, 'cos this is bound to be slow.
 *********************************************************************/
- (void)textDidChange:(NSNotification *)aNotification {
    [self TidyCurrentDocument];
}

/********************************************************************
    optionChanged:
    One of the options changed! Let the CocoaTidy object know, and
    retidy the document.
*********************************************************************/
- (IBAction)optionChanged:(id)sender {
    // create a temporary CocoaTidyOptions object to set all of our options
    CocoaTidyOptions* myOpts = [[CocoaTidyOptions alloc] init];
    
    // set all of the options in the CocoaTidyOptions object.
    [myOpts optIndent:[checkIndent state]];
    [myOpts optOmit:[checkOmit state]];
    [myOpts optWrapAtColumn:[checkWrap state]];
    [myOpts optWrapAtColumnNr:[valWrap intValue]];
    [myOpts optUpper:[checkUppercase state]];
    [myOpts optClean:[checkClean state]];
    [myOpts optBare:[checkBare state]];
    [myOpts optNumeric:[checkNumeric state]];
    [myOpts optXML:[checkXML state]];
    
    // grok the encoding option -- position dependant, maybe not the best way.
    switch ( [menuEncoding indexOfSelectedItem] ) {
        case 0:
            [myOpts optRaw:YES];
            break;
        case 1:
            [myOpts optASCII:YES];
            break;
        case 2:
            [myOpts optLatin1:YES];
            break;
        case 3:
            [myOpts optISO2022:YES];
            break;
        case 4:
            [myOpts optUTF8:YES];
            break;
        case 5:
            [myOpts optMac:YES];
            break;
        case 6:
            [myOpts optUTF16LE:YES];
            break;
        case 7:
            [myOpts optUTF16BE:YES];
            break;
        case 8:
            [myOpts optUTF16:YES];
            break;
        case 9:
            [myOpts optWin1252:YES];
            break;
        case 10:
            [myOpts optBig5:YES];
            break;
        case 11:
            [myOpts optShiftJIS:YES];
            break;
    } // end switch

    [tidyProcess setOptionsWithOptions: myOpts];	// set the options.
    [myOpts release];					// free the temporary CocoaTidyOptions object.
    [self TidyCurrentDocument];				// tidy the current document.
}


@end
