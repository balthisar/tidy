//
//  TidyService.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "TidyService.h"
#import "CommonHeaders.h"

@import JSDTidyFramework;


@implementation TidyService


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - tidySelection:userData:error:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidySelection:(NSPasteboard *)pboard
             userData:(NSString *)userData
                error:(NSString * __autoreleasing *)error
{
    [self performTidySelection:pboard userData:userData error:error bodyOnly:NO];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - tidySelectionBodyOnly:userData:error:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidySelectionBodyOnly:(NSPasteboard *)pboard
                     userData:(NSString *)userData
                        error:(NSString * __autoreleasing *)error
{
    [self performTidySelection:pboard userData:userData error:error bodyOnly:YES];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - performTidySelection:userData:error:bodyOnly (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)performTidySelection:(NSPasteboard *)pboard
                    userData:(NSString *)userData
                       error:(NSString * __autoreleasing *)error
                    bodyOnly:(BOOL)bodyOnly
{
    /* Test for strings on the pasteboard. */

    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
    
    NSDictionary *options = [NSDictionary dictionary];
    
    if (![pboard canReadObjectForClasses:classes options:options])
    {
        *error = JSDLocalizedString(@"tidyCantRead", nil);
        return;
    }
    
    NSString *pboardString = [pboard stringForType:NSPasteboardTypeString];
    
    JSDTidyModel *localModel = [[JSDTidyModel alloc] initWithString:pboardString];
    NSUserDefaults *localDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];

    [localModel takeOptionValuesFromDefaults:localDefaults];
    JSDTidyOption *localOption = localModel.tidyOptions[@"force-output"];
    localOption.optionValue = @"YES";
    
    localOption = localModel.tidyOptions[@"show-body-only"];
    localOption.optionValue = bodyOnly ? @"1" : @"0";
    
    /* Grab a current copy of tidyText
     */
    localModel.sourceText = pboardString;
    NSString *localTidyText = localModel.tidyText;
    
    
    if (!localTidyText)
    {
        *error = JSDLocalizedString(@"tidyDidntWork", nil);
    }
    else
    {
        /* Write the string onto the pasteboard. */
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObject:localTidyText]];
    }
}


@end
