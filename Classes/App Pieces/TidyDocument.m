/***************************************************************************************
    TidyDocument.m -- part of Balthisar Tidy

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

#import "TidyDocument.h"
#import "PreferenceController.h"
#import "JSDTidy.h"

@implementation TidyDocument

//=============================================================================================
//                                      FILE I/O HANDLING
//=============================================================================================

/********************************************************************
    readFromFile:
    Called as part of the responder chain. We already have a name
    and type as a result of (1) the file picker, or (2) opening a
    document from Finder. Here, we'll merely load the file contents
    into an NSData, and process it when the nib awakes (since we're
    likely to be called here before the nib and its controls exist).
*********************************************************************/
- (BOOL)readFromFile:(NSString *)filename ofType:(NSString *)docType {
    [tidyProcess setOriginalTextWithData:[NSData dataWithContentsOfFile:filename]]; 	// give our tidyProcess the data.
    tidyOriginalFile = NO;						    		// the current file was OPENED, not a Tidy original.
    return YES; 									// yes, it was loaded successfully.
} // readFromFile

/********************************************************************
    dataRepresentationOfType
    Called as a result of saving files. All we're going to do is
    pass back the NSData taken from the TidyDoc
*********************************************************************/
- (NSData *)dataRepresentationOfType:(NSString *)aType {
    return [tidyProcess tidyTextAsData];				// return the raw data in user-encoding to be written.
} // dataRepresentationOfType

/********************************************************************
    writeToFile
    Called as a result of saving files, and does the actual writing.
    We're going to override it so that we can update the sourceView
    automatically any time the file is saved. The logic is, once the
    file is saved, the sourceview ought to reflect the actual file
    contents, which is the tidy'd view.
*********************************************************************/
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
    bool success = [super writeToFile:fileName ofType:type];		// inherited method does the actual saving
        if (success) {
            [tidyProcess setOriginalText:[tidyProcess tidyText]];	// make the tidyText the new originalText.
            [sourceView setString:[tidyProcess workingText]]; 		// update the sourceView with the newly-saved contents.
            yesSavedAs = YES;						// this flag disables the warnings, since they're meaningless now.
        }
    return success;
} // writeToFile

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
        [myDict setObject:[NSNumber numberWithUnsignedLong:'WWS2'] forKey:NSFileHFSCreatorCode];	// set creator code.
        [myDict setObject:[NSNumber numberWithUnsignedLong:'TEXT'] forKey:NSFileHFSTypeCode];		// set file type.
    } else { // use original type/creator codes, if any.
        OSType macType = [ [ [ NSFileManager defaultManager ] fileAttributesAtPath: fullDocumentPath traverseLink: YES ] fileHFSTypeCode];
        OSType macCreator = [ [ [ NSFileManager defaultManager ] fileAttributesAtPath: fullDocumentPath traverseLink: YES ] fileHFSCreatorCode];
        if ((macType != 0) && (macCreator != 0)) {
            [myDict setObject:[NSNumber numberWithUnsignedLong:macCreator] forKey:NSFileHFSCreatorCode];
            [myDict setObject:[NSNumber numberWithUnsignedLong:macType] forKey:NSFileHFSTypeCode];
        }
    }
    return myDict;
} // fileAttributesToWriteToFile:ofType:saveOperation

/********************************************************************
    revertToSavedFromFile:ofType
    allow the default reversion to take place, and then put the
    correct value in the editor if it took place. The inherited
    method does readFromFile, so our tidyProcess will already
    have the reverted data.
*********************************************************************/
- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type {
    bool didRevert = [super revertToSavedFromFile:fileName ofType:type];
    if (didRevert) {
        [sourceView setString:[tidyProcess workingText]];	// update the display, since the reversion already loaded the data.
        [self retidy];						// retidy the document.
    } // if
    return didRevert;						// flag whether we reverted or not.
} // revertToSavedFromFile:ofType

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
    if ( (saveBehavior == 1) && 		// behavior is protective AND
         (saveWarning) && 			// we want to have a warning AND
         (yesSavedAs == NO) && 			// we've NOT yet done a save as... AND
         ([[self fileName] length] != 0 )) {	// the filename isn't zero length
        int i = NSRunAlertPanel(NSLocalizedString(@"WarnSaveOverwrite", nil), NSLocalizedString(@"WarnSaveOverwriteExplain", nil),
                                NSLocalizedString(@"continue save", nil),NSLocalizedString(@"do not save", nil) , nil);
        if (i == NSAlertAlternateReturn)
            return; // don't let user continue the save operation if he chose don't save.
    } // if
    
    // save is completely disabled -- tell user to Save AsÉ
    if (saveBehavior == 2) {
        NSRunAlertPanel(NSLocalizedString(@"WarnSaveDisabled", nil), NSLocalizedString(@"WarnSaveDisabledExplain", nil),
                            NSLocalizedString(@"cancel", nil), nil, nil);
        return; // don't let user continue the save operation.
    } // if
    
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
        tidyOriginalFile = YES; 			// if yes, we'll write file/creator codes.
        tidyProcess = [[JSDTidyDocument alloc] init]; 	// use our own tidy process, NOT the controller's instance.
        // register for notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSavePrefChange:) name:@"JSDSavePrefChange" object:nil];
    } // if
    return self;
} // init

/*********************************************************************
    dealloc
    our destructor -- get rid of the tidy processor and processString
**********************************************************************/
- (void)dealloc {   
    [[NSNotificationCenter defaultCenter] removeObserver:self];	// remove ourselves from the notification center!
    [tidyProcess release];					// release the tidyProcess.
    [optionController release];					// remove the optionController pane.
    [super dealloc];						// do the inherited dealloc.
} // dealloc

/********************************************************************
    configureViewSettings
        given aView, make it non-wrapping. Also set fonts.
*********************************************************************/
- (void)configureViewSettings:(NSTextView *)aView {
    [aView setFont:[NSFont fontWithName:@"Courier" size:12]];			// set the font for the views.
    [aView setRichText:NO];							// don't allow rich text.
    [aView setUsesFontPanel:NO];						// don't allow the font panel.
    [aView setContinuousSpellCheckingEnabled:NO];				// turn off spell checking.
    [aView setSelectable:YES];							// text can be selectable.
    [aView setEditable:NO];							// text shouldn't be editable.
    [aView setImportsGraphics:NO];						// don't let user import graphics.
    [aView setUsesRuler:NO];							// no, the ruler won't be used.
}  // configureViewSettings

/********************************************************************
    awakeFromNib
    When we wake from the nib file, setup the option controller
*********************************************************************/
-(void) awakeFromNib {
    // create a OptionPaneController and put it in place of optionPane
    if (!optionController)
        optionController = [[OptionPaneController alloc] init];
    [optionController putViewIntoView:optionPane];
    [optionController setTarget:self];
    [optionController setAction:@selector(optionChanged:)];
} // awakeFromNib

/********************************************************************
    windowControllerDidLoadNib:
    The nib is loaded. If there's a string in processString, it will
    appear in the sourceView.
*********************************************************************/
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];				// inherited method needs to be called.
    
    // configure the view settings that we can't in IB.
    [self configureViewSettings:[sourceView textView]];				// setup the sourceView's options.
    [[sourceView textView] setEditable:YES];					// make the sourceView editable.
    [self configureViewSettings:[tidyView textView]];				// setup the tidyView's options.

    // honor the defaults system defaults.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		// get the default default system
    [[optionController tidyDocument] takeOptionValuesFromDefaults:defaults]; 	// make the optionController take the values

    // saving behavior settings
    saveBehavior = [defaults integerForKey:JSDKeySavingPrefStyle];
    saveWarning = [defaults boolForKey:JSDKeyWarnBeforeOverwrite];
    yesSavedAs = NO;
    
    // make the sourceView string the same as our loaded text.
    [sourceView setString:[tidyProcess workingText]];
    
    // force the processing to occur.
    [self optionChanged:self];
} // windowControllerDidLoadNib

/********************************************************************
    windowNibName
    return the name of the Nib associated with this class.
*********************************************************************/
- (NSString *)windowNibName {
    return @"TidyDocument";
} // windowNibName


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
    saveBehavior = [[NSUserDefaults standardUserDefaults] integerForKey:JSDKeySavingPrefStyle];
    saveWarning = [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyWarnBeforeOverwrite];
} // handleSavePrefChange

/********************************************************************
    retidy
        do the actual re-tidy'ing
 *********************************************************************/
-(void)retidy {
    [tidyProcess setWorkingText:[sourceView string]];	// put the sourceView text into the tidyProcess.
    [tidyView setString:[tidyProcess tidyText]];	// put the tidy'd text into the view.
    [errorView reloadData];				// reload the error data
    [errorView deselectAll:self];			// get rid of the selected row.

    // handle document dirty detection -- we're NOT dirty if the source and tidy string are
    // the same, or there is no source view, of if the source is the same as the original.
    if ( ( [tidyProcess areEqualOriginalTidy])  ||		// the original text and tidy text are equal OR
         ( [[tidyProcess originalText] length] == 0 )  || 	// the originalText was never there OR
         ( [tidyProcess areEqualOriginalWorking ] ))		// the workingText is the same as the original.
        [self updateChangeCount:NSChangeCleared];
    else
        [self updateChangeCount:NSChangeDone];
} // retidy

/********************************************************************
    textDidChange:
        we arrived here by virtue of this document class being the
        delegate of sourceView. Whenever the text changes, let's
        reprocess all of the text. Hopefully the user won't be
        inclined to type everything, 'cos this is bound to be slow.
 *********************************************************************/
- (void)textDidChange:(NSNotification *)aNotification {
    [self retidy];
} // textDidChange


/********************************************************************
    optionChanged:
    One of the options changed! We're here by virtue of being the
    action of the optionController instance. Let's retidy here.
*********************************************************************/
- (IBAction)optionChanged:(id)sender {
    [tidyProcess optionCopyFromDocument:[optionController tidyDocument]];
    [self retidy];
} // optionChanged


//=============================================================================================
//                             SUPPORT FOR THE ERROR TABLE
//=============================================================================================


/********************************************************************
    numberOfRowsInTableView
    we're here because we're the datasource of the tableview.
    We need to specify how many items are in the table view.
*********************************************************************/
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[tidyProcess errorArray] count];
} // numberOfRowsInTableView


/********************************************************************
    tableView:objectValueForTableColumn:row
    we're here because we're the datasource of the tableview.
    We need to specify what to show in the row/column.
*********************************************************************/
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSDictionary *error = [[tidyProcess errorArray] objectAtIndex:rowIndex];	// get the current error

    // list of error types -- no localized; users can localize based on this string.
    NSArray *errorTypes = [NSArray arrayWithObjects:@"Info:", @"Warning:", @"Config:", @"Access:", @"Error:", @"Document:", @"Panic:", nil];

    // handle returning the severity of the error, localized.
    if ([[aTableColumn identifier] isEqualToString:@"severity"])
        return NSLocalizedString([errorTypes objectAtIndex: [[error objectForKey:@"level"] intValue] ], nil);

    // handle the location, localized, or "N/A" if not applicable
    if ([[aTableColumn identifier] isEqualToString:@"where"]) {
        if (([[error objectForKey:@"line"] intValue] == 0) || ([[error objectForKey:@"column"] intValue] == 0)) {
            return NSLocalizedString(@"N/A", nil);
        } // if (N/A)
        return [NSString stringWithFormat:@"%@ %@, %@ %@", NSLocalizedString(@"line", nil), [error objectForKey:@"line"], NSLocalizedString(@"column", nil), [error objectForKey:@"column"]];        
    } // if where

    if ([[aTableColumn identifier] isEqualToString:@"description"])
        return [error objectForKey:@"message"];
    return @"";
} //tableView:objectValueForTableColumn:row

/********************************************************************
    errorClicked:
        we arrived here by virtue of this controller class and this
        method being the action of the table. Whenever the selection
        changes we're going to highlight and show the related
        column/row in the sourceView.
*********************************************************************/
- (IBAction)errorClicked:(id)sender {
    int errorViewRow = [errorView selectedRow];
    if (errorViewRow >= 0) {
        int highlightRow = [[[[tidyProcess errorArray] objectAtIndex:errorViewRow] objectForKey:@"line"] intValue];
        int highlightCol = [[[[tidyProcess errorArray] objectAtIndex:errorViewRow] objectForKey:@"column"] intValue];
        [sourceView setHighlightedLine:highlightRow column:highlightCol];
    }
    else
        [sourceView setHighlightedLine:0 column:0];
} // errorClicked

/********************************************************************
    tableViewSelectionDidChange:
        we arrived here by virtue of this controller class being the
        delegate of the table. Whenever the selection changes
        we're going to highlight and show the related column/row
        in the sourceView.
*********************************************************************/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    // get the description of the selected row.
    if ([aNotification object] == errorView)
        [self errorClicked:self];
} // tableViewSelectionDidChange


@end
