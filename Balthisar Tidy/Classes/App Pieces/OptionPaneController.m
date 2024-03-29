//
//  OptionPaneController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "OptionPaneController.h"
#import "CommonHeaders.h"

#import "JSDTableCellView.h"

@import JSDTidyFramework;


#pragma mark - CATEGORY - Non-Public


@interface OptionPaneController ()


/* Important Stuff inside in the NIB */

@property (nonatomic, weak) IBOutlet NSTableView *theTable;

@property (nonatomic, strong) IBOutlet NSArrayController *theArrayController;


/* Properties for managing the toggling of theDescription's visibility */

@property (nonatomic, weak) IBOutlet NSTextField *theDescription;

@property (nonatomic, strong) NSLayoutConstraint *theDescriptionConstraint;


/* Behavior and display properties */

@property (nonatomic, assign) BOOL isShowingFriendlyTidyOptionNames;

@property (nonatomic, assign) BOOL isShowingOptionsInGroups;


/* Exposing sort descriptors and predicates */

@property (nonatomic, strong, readonly) NSArray *sortDescriptor;

@property (nonatomic, strong, readonly) NSPredicate *filterPredicate;


/* Gradient button actions */

- (IBAction)handleResetOptionsToFactoryDefaults:(id)sender;

- (IBAction)handleResetOptionsToPreferences:(id)sender;

- (IBAction)handleSaveOptionsToPreferences:(id)sender;

- (IBAction)handleSaveOptionsToUnixConfigFile:(id)sender;

- (IBAction)handleLoadOptionsFromUnixConfigFile:(id)sender;


/* awakeFromNib control */

@property (nonatomic, assign) BOOL awokenFromNib;

@end


#pragma mark - IMPLEMENTATION


@implementation OptionPaneController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
    self = [super initWithNibName:@"OptionPane" bundle:nil];
    
    if (self)
    {
        _tidyDocument = [[JSDTidyModel alloc] init];
        
        /* These options are on a per-window basis, but originate from user defauts */
        
        self.isShowingFriendlyTidyOptionNames = [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyOptionsShowHumanReadableNames];
        
        self.isShowingOptionsInGroups = [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyOptionsAreGrouped];
        
        _descriptionIsVisible = YES; // Default from the nib is that it is visible; will correct in awakeFromNib.
        
        self.isInPreferencesView = NO;
    }
    
    return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - awakeFromNib
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)awakeFromNib
{
    if (!self.awokenFromNib)
    {
        self.awokenFromNib = YES;
        
        self.theDescriptionConstraint = [NSLayoutConstraint constraintWithItem:self.theDescription
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:0.0];
        
        self.theDescription.wantsLayer = YES;
        self.descriptionIsVisible = [[[NSUserDefaults standardUserDefaults] valueForKey:JSDKeyOptionsShowDescription] boolValue];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @property optionsInEffect
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)optionsInEffect
{
    return self.tidyDocument.optionsInUse;
}

- (void)setOptionsInEffect:(NSArray *)optionsInEffect
{
    self.tidyDocument.optionsInUse = optionsInEffect;
    
    [self.theArrayController bind:NSContentBinding toObject:self withKeyPath:@"tidyDocument.tidyOptionsBindable" options:nil];
    
    [self.theTable reloadData];
}


#pragma mark - View Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - viewDidLayout
 *  Multi-line NSTextFields in auto-layouts are notoriously finicky.
 *  Let's make sure it behaves properly without having to subclass it.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)viewDidLayout
{
    [super viewDidLayout];
    self.theDescription.preferredMaxLayoutWidth = self.theDescription.frame.size.width;
    [self.theDescription layoutSubtreeIfNeeded];
    [self.theDescription setNeedsDisplay];
}


#pragma mark - Table Handling - Datasource and Delegate Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - tableView:shouldSelectRow:
 *  We're here because we're the delegate of the `theTable`.
 *  We need to specify if it's okay to select the row.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    JSDTidyOption *localOption = self.theArrayController.arrangedObjects[rowIndex];
    
    return !localOption.optionIsHeader;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - tableView:keyWasPressed:row:
 *  Respond to table view keypresses.
 *  In this case we're allowing the left and right cursors keys
 *  to increment/decrement option values.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)tableView:(NSTableView *)aTableView keyWasPressed:(NSInteger)keyCode row:(NSInteger)rowIndex
{
    
    if ((rowIndex >= 0) && (( keyCode == 123) || (keyCode == 124)))
    {
        JSDTidyOption *localOption = self.theArrayController.arrangedObjects[rowIndex];
        
        if (keyCode == 123)
        {
            [localOption optionUIValueDecrement];
        }
        else
        {
            [localOption optionUIValueIncrement];
        }
        
        return YES;
    }
    
    return NO;
}


#pragma mark - Sorting and Filtering Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * + keyPathsForValuesAffectingFilterPredicate
 *  Signal to KVO that if one of the included keys changes,
 *  then it should also be aware that filterPredicate changed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSSet *)keyPathsForValuesAffectingFilterPredicate
{
    return [NSSet setWithObjects:@"isShowingFriendlyTidyOptionNames", @"isShowingOptionsInGroups", nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - filterPredicate
 *  We never want to show option that are supressed. If we are
 *  not showing options in groups, then we want to also hide
 *  the groups.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSPredicate*)filterPredicate
{
    if (self.isShowingOptionsInGroups)
    {
        return [NSPredicate predicateWithFormat:@"(optionIsSuppressed == %@)", @(NO)];
    }
    else
    {
        return [NSPredicate predicateWithFormat:@"(optionIsSuppressed == %@) AND (optionIsHeader == NO)", @(NO)];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * + keyPathsForValuesAffectingSortDescriptor
 *  Signal to KVO that if one of the included keys changes,
 *  then it should also be aware that sortDescriptor changed.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (NSSet *)keyPathsForValuesAffectingSortDescriptor
{
    return [NSSet setWithObjects:@"isShowingFriendlyTidyOptionNames", @"isShowingOptionsInGroups", nil];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - sortDescriptor
 *  We have four ways that we have to sort.
 *
 *  If we are not in groups, then we have to sort by name or by
 *  localizedHumanReadableName.
 *
 *  If we are grouped, then we also have to get the headers
 *  and sort by name or localizedHumanReadableName.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray*)sortDescriptor
{
    NSString *nameSortKey;
    SEL sortingSelector;
    
    if (self.isShowingFriendlyTidyOptionNames)
    {
        nameSortKey = @"localizedHumanReadableName";
        sortingSelector = @selector(tidyGroupedHumanNameCompare:);
    }
    else
    {
        nameSortKey = @"name";
        sortingSelector = @selector(tidyGroupedNameCompare:);
    }
    
    
    if (self.isShowingOptionsInGroups)
    {
        return @[[NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES selector:sortingSelector]];
    }
    else
    {
        return @[[NSSortDescriptor sortDescriptorWithKey:nameSortKey ascending:YES selector:@selector(localizedStandardCompare:)]];
    }
    
}


#pragma mark - Gradient Button Event Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @property descriptionIsVisible
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setDescriptionIsVisible:(BOOL)descriptionIsVisible
{
    _descriptionIsVisible = descriptionIsVisible;
    
    self.theDescription.layerContentsRedrawPolicy = NSViewLayerContentsRedrawCrossfade;
    self.theDescription.layerContentsPlacement = NSViewLayerContentsPlacementTop;
    [self.view layoutSubtreeIfNeeded];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
        [context setAllowsImplicitAnimation: YES];
        
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAnimationReduce] )
        {
            context.duration = 0.0f;
        }
        else
        {
            context.duration = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyAnimationStandardTime];
        }
        
        if (descriptionIsVisible)
        {
            if ([self.theDescription.constraints containsObject:self.theDescriptionConstraint])
            {
                [self.theDescription removeConstraint:self.theDescriptionConstraint];
            }
        }
        else
        {
            if (![self.theDescription.constraints containsObject:self.theDescriptionConstraint])
            {
                [self.theDescription addConstraint:self.theDescriptionConstraint];
            }
        }
        
        [self.view layoutSubtreeIfNeeded];
    }
                        completionHandler:^
     {
        [[self theTable] scrollRowToVisible:self.theTable.selectedRow];
    }];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleResetOptionsToFactoryDefaults:
 *  - get factory default values for all optionsInEffect
 *  - set the tidyDocument to those.
 *  - notification system will handle the rest:
 *  - the tidyDocument will send a notification that the
 *    implementor (the PreferenceController) is responsible
 *    for detecting.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleResetOptionsToFactoryDefaults:(id)sender
{
    NSMutableDictionary *tidyFactoryDefaults = [[NSMutableDictionary alloc] init];
    
    [JSDTidyModel addDefaultsToDictionary:tidyFactoryDefaults fromArray:self.tidyDocument.optionsInUse];
    
    [self.tidyDocument optionsCopyValuesFromDictionary:tidyFactoryDefaults[JSDKeyTidyTidyOptionsKey]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleResetOptionsToPreferences:
 *  - tell the tidyDocument to use the stored defaults.
 *  - notification system should handle the rest.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleResetOptionsToPreferences:(id)sender
{
    [self.tidyDocument takeOptionValuesFromDefaults:[NSUserDefaults standardUserDefaults]];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleSaveOptionsToPreferences:
 *  - the Preferences window might not exist yet, so all we
 *    can really do is write out the preferences, and try
 *    sending a notification.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleSaveOptionsToPreferences:(id)sender
{
    [self.tidyDocument writeOptionValuesWithDefaults:[NSUserDefaults standardUserDefaults]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"appNotifyStandardUserDefaultsChanged" object:self];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleSaveOptionsToUnixConfigFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleSaveOptionsToUnixConfigFile:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    [savePanel setNameFieldStringValue:@"tidy.cfg"];
    [savePanel setNameFieldLabel:NSLocalizedString(@"ExportAs", nil)];
    [savePanel setPrompt:NSLocalizedString(@"Export", nil)];
    [savePanel setMessage:NSLocalizedString(@"ExportMessage", nil)];
    [savePanel setShowsHiddenFiles:YES];
    [savePanel setExtensionHidden:NO];
    [savePanel setCanSelectHiddenExtension: NO];
    
    [savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            [savePanel orderOut:self];
            
            NSString *contents = [self.tidyDocument tidyOptionsConfigFile:[savePanel nameFieldStringValue]];
            
            [contents writeToURL:[savePanel URL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleLoadOptionsFromUnixConfigFile:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleLoadOptionsFromUnixConfigFile:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setPrompt:JSDLocalizedString(@"importPanelSelect", nil)];
    [openPanel setMessage:JSDLocalizedString(@"importPanelMessage", nil)];
    [openPanel setShowsHiddenFiles:YES];
    [openPanel setExtensionHidden:NO];
    [openPanel setCanSelectHiddenExtension:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setAllowsMultipleSelection:NO];
    
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            [openPanel orderOut:self];
            if (![self.tidyDocument optionsTidyLoadConfig:openPanel.URLs[0]])
            {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:JSDLocalizedString(@"importPanelFailureMessage", nil)];
                [alert addButtonWithTitle:JSDLocalizedString(@"importPanelFailureButton", nil)];
                [alert setAlertStyle:NSAlertStyleWarning];
                [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
                [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
            }
        }
    }];
}


@end
