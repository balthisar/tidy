//
//  ActionRequestHandler.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "ActionRequestHandler.h"
#import "CommonHeaders.h"

@import JSDTidyFramework;


@implementation ActionRequestHandler


#ifdef FEATURE_SUPPORTS_EXTENSIONS


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - beginRequestWithExtensionContext:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context
{
    /* The macro from CommonHeaders.h initWithSuiteName is the
     * means for accessing shared preferences when everything is sandboxed.
     */
    NSUserDefaults *localDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];
    
    
    /* Get the input item. */
    NSExtensionItem *item = context.inputItems.firstObject;
    NSString *content = [item.attributedContentText string];
    
    
    /* Full Tidy output, or Body only?
     * Extensions are complete, separate build targets, but both of Tidy's
     * extensions are basically the same except for one setting, so we capture
     * this in a macro set by the target settings.
     */
    
#if BODY_ONLY == 1
    BOOL showBodyOnly = 1;
#else
    BOOL showBodyOnly = 0;
#endif
    
    
    /* Set options and perform the Tidying.
     */
    JSDTidyModel *localModel = [[JSDTidyModel alloc] init];
    [localModel takeOptionValuesFromDefaults:localDefaults];
    JSDTidyOption *localOption = localModel.tidyOptions[@"force-output"];
    localOption.optionValue = @"YES";
    
    localOption = localModel.tidyOptions[@"show-body-only"];
    localOption.optionValue = showBodyOnly == 0 ? @"0" : @"1";
    
    /* Grab a current copy of tidyText.
     */
    localModel.sourceText = content;
    NSString *localTidyText = localModel.tidyText;
    
    if (localTidyText && localTidyText.length > 0)
    {
        item.attributedContentText = [[NSAttributedString alloc] initWithString:localModel.tidyText];
        [context completeRequestReturningItems:@[item] completionHandler:nil];
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:JSDLocalizedString(@"dialogOK", nil)];
        [alert setMessageText:JSDLocalizedString(@"dialogMessageText", nil)];
        [alert setInformativeText:JSDLocalizedString(@"dialogInformativeText", nil)];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert runModal];
        [context cancelRequestWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
}


#endif


@end
