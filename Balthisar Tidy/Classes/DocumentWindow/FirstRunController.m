/**************************************************************************************************
 *
 *  FirstRunController
 *
 *  Copyright © 2003-2018 by Jim Derry. All rights reserved.
 *
 **************************************************************************************************/

#import "FirstRunController.h"

#import "SWFSemanticVersion.h"

@interface FirstRunController ()

@property (nonatomic, weak) IBOutlet NSPopover   *popover;
@property (nonatomic, weak) IBOutlet NSButton    *buttonPrevious;
@property (nonatomic, weak) IBOutlet NSButton    *buttonCancel;
@property (nonatomic, weak) IBOutlet NSButton    *buttonNext;
@property (nonatomic, weak) IBOutlet NSButton    *checkboxShowAgain;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldExplanation;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldProgress;

@property (nonatomic, assign) BOOL userHasTouchedCheckbox;

@property (nonatomic, assign) NSUInteger currentStep;
@property (nonatomic, strong, readwrite) NSMutableArray *applicableSteps;

@property (nonatomic, assign, readonly) NSString *bundleVersion;
@property (nonatomic, assign, readonly) NSString *prefsVersion;



/* Redefine for category. */
@property (nonatomic, assign, readwrite, getter=isVisible ) BOOL visible;

- (IBAction)handleButtonPrevious:(NSButton *)sender;
- (IBAction)handleButtonCancel:(NSButton *)sender;
- (IBAction)handleButtonNext:(NSButton *)sender;
- (IBAction)handleCheckboxShowAgain:(NSButton *)sender;

@end



@implementation FirstRunController


#pragma mark - Initialization and Deallocation


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)init
{
    if ( (self = [super init]) )
    {
        [[NSBundle mainBundle] loadNibNamed:@"FirstRunController" owner:self topLevelObjects:nil];

        _userHasTouchedCheckbox = NO;

        _currentStep = 0;
    }
    return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - initWithSteps:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (instancetype)initWithSteps:(NSArray*)steps
{
    if ( (self = [self init]) )
    {
        _steps = steps;
    }
    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * - dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    _steps = nil;
}


#pragma mark - Property Accessors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @property bundleVersion
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)bundleVersion
{
    return [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @property prefsVersion
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)prefsVersion
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:self.preferencesKeyNameCompleteVersion];
}


#pragma mark - Sequence Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - beginFirstRunSequence
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)beginFirstRunSequence
{
    self.steps = [self configureWithSteps:self.steps];
    
    if (self.steps.count > 0)
    {
        self.currentStep = 0;

        self.checkboxShowAgain.state = ![[[NSUserDefaults standardUserDefaults] objectForKey:self.preferencesKeyNameComplete] boolValue];

        [self showPopoverHavingTag:0];

        self.visible = YES;
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - showPopoverHavingTag: (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)showPopoverHavingTag:(NSInteger)tag
{
    /* Make sure we don't overstep bounds */

    if ((NSUInteger)tag >= self.steps.count - 1 )
    {
        tag = self.steps.count - 1;
    }

    if (tag < 0)
    {
        tag = 0;
    }


    /* Setup general items. */

    self.buttonNext.title = NSLocalizedString(@"firstRun-buttonNext", nil);

    self.checkboxShowAgain.enabled = YES;

    self.buttonCancel.hidden = NO;

    self.buttonPrevious.hidden = NO;

    NSString *rawDescription = NSLocalizedString(self.steps[tag][@"message"], nil);
    self.textFieldExplanation.attributedStringValue = [self makeRTFStringFromString:rawDescription];

    self.currentStep = tag;

    self.textFieldProgress.stringValue = [NSString stringWithFormat:NSLocalizedString(@"firstRun-stepXofY", nil), tag + 1, self.steps.count];


    /* Special setup if we're on first item. */

    if (tag == 0)
    {
        self.buttonNext.title = NSLocalizedString(@"firstRun-buttonBegin", nil);

        self.buttonPrevious.hidden = YES;

        /* Reset the string in case we're showing a version number. */
        rawDescription = [NSString stringWithFormat:rawDescription, self.bundleVersion, self.prefsVersion];
        self.textFieldExplanation.attributedStringValue = [self makeRTFStringFromString:rawDescription];
    }

    /* Special setup if we're on last item. */

    if ((NSUInteger)tag >= self.steps.count - 1)
    {
        self.buttonNext.title = NSLocalizedString(@"firstRun-buttonDone", nil);

        if (!self.userHasTouchedCheckbox)
        {
            self.checkboxShowAgain.state = NO;
        }

        /* No point in allowing user to cancel now. */

        self.buttonCancel.hidden = YES;
    }

    /* If the delegate exists, try to send a setValue:forKeyPath, if applicable.
       This lets us control the UI to a small degree.
     */
    if (self.delegate && self.steps[tag][@"keyPath"] && self.steps[tag][@"keyPathValue"])
    {
        [self.delegate setValue:self.steps[tag][@"keyPathValue"] forKeyPath:self.steps[tag][@"keyPath"]];
    }

    /* Display the helper text and position the popover. */

    self.popover.contentViewController.view.wantsLayer = YES;
    [self.popover.contentViewController.view layoutSubtreeIfNeeded];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
         [context setAllowsImplicitAnimation: YES];
         context.duration = self.animationSpeed;

         [self.popover showRelativeToRect:NSRectFromString(self.steps[tag][@"showRelativeToRect"])
                                   ofView:self.steps[tag][@"ofView"]
                            preferredEdge:[self.steps[tag][@"preferredEdge"] integerValue]];

         [self.popover.contentViewController.view layoutSubtreeIfNeeded];
         
     } completionHandler:nil];

}


#pragma mark - Event Handling


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleButtonPrevious:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleButtonPrevious:(NSButton *)sender
{
    [self showPopoverHavingTag:self.currentStep - 1];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleButtonCancel:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleButtonCancel:(NSButton *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:@(!self.checkboxShowAgain.state) forKey:self.preferencesKeyNameComplete];
    [[NSUserDefaults standardUserDefaults] setObject:self.bundleVersion forKey:self.preferencesKeyNameCompleteVersion];

    [self auxilliaryViewWillClose];
    [self.popover performClose:self];

    self.visible = NO;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleButtonNext:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleButtonNext:(NSButton *)sender
{
    if (self.currentStep != self.steps.count -1)
    {
        [self showPopoverHavingTag:self.currentStep + 1];
    }
    else
    {
        [self handleButtonCancel:nil];
    }
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - handleCheckboxShowAgain:
 *   We'll simply remember if the user has ever manually touched
 *   the checkbox so that we don't change the state at the end
 *   of the helper sequence.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (IBAction)handleCheckboxShowAgain:(NSButton *)sender
{
    self.userHasTouchedCheckbox = YES;
}


#pragma mark - Delegate Methods


/*———————————————————————————————————————————————————————————————————*
 * - auxilliaryViewWillClose
 *   Handles all possibles actions from the input-encoding
 *   helper popover. The only two senders should be
 *   buttonAllowChange and buttonIgnoreSuggestion.
 *———————————————————————————————————————————————————————————————————*/
- (void)auxilliaryViewWillClose
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(auxilliaryViewWillClose:)])
    {
        [[self delegate] auxilliaryViewWillClose:self];
    }
}


#pragma mark - Private Support Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - configureWithSteps:
 *   If we're only showing an upgrade, then only return the panels
 *   appropriate to this particular upgrade, otherwise return all
 *   of the panels (except the upgrade splash page).
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSArray *)configureWithSteps:(NSArray *)steps
{
    SWFSemanticVersion *current = [SWFSemanticVersion semanticVersionWithString:self.bundleVersion];
    SWFSemanticVersion *prefs = [SWFSemanticVersion semanticVersionWithString:self.prefsVersion];
//    SWFSemanticVersion *prefs = [SWFSemanticVersion semanticVersionWithString:@"3.7.0"];
    BOOL upgraded = ([prefs compare:current] == NSOrderedAscending);

    NSMutableArray *localSteps = [[NSMutableArray alloc] init];

    if ( upgraded && [[NSUserDefaults standardUserDefaults] boolForKey:self.preferencesKeyNameComplete] )
    {
        for ( NSDictionary *step in steps )
        {
            if ( step == steps[1] || step == steps[steps.count-1] )
            {
                [localSteps addObject:step];
            }
            else if ( step[@"newInVersion"] && (current = [SWFSemanticVersion semanticVersionWithString:step[@"newInVersion"]] ) )
            {
                if ( [prefs compare:current] == NSOrderedAscending )
                {
                    [localSteps addObject:step];
                }
            }
        }
    }
    else
    {
        localSteps = [NSMutableArray arrayWithArray:steps];
        [localSteps removeObjectAtIndex:1];
    }

    // If we only have a first and last step, there is nothing new to show.
    return localSteps.count > 2 ? localSteps : nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - makeRTFStringFromString:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSAttributedString*)makeRTFStringFromString:(NSString*)rawString
{
    NSAttributedString *outString;

    /*
     RTF can be a little complex due to legacy string encoding issues.
     When strings are internationalized, RTF might not play nicely with
     non-Mac character encodings. Prefixing the strings with an
     asterisk will cause the automatic conversion to and from RTF,
     otherwise the strings will be treated normally (this maintains
     string compatability with `NSLocalizedString`).
     */
    if ([rawString hasPrefix:@"*"])
    {
        /* Make into RTF string. */

        rawString = [[@"{\\rtf1\\mac\\deff0{\\fonttbl{\\f0 Consolas;}{\\f1 Lucida Grande;}}\\f1\\fs23\\sa100" stringByAppendingString:[rawString substringFromIndex:1]] stringByAppendingString:@"}"];

        NSData *rawData = [rawString dataUsingEncoding:NSMacOSRomanStringEncoding];

        outString = [[NSAttributedString alloc] initWithRTF:rawData documentAttributes:nil];
    }
    else
    {
        /* Use the string as-is. */

        outString = [[NSAttributedString alloc] initWithString:rawString];
    }

    return outString;
}

@end

