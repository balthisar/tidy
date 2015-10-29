/**************************************************************************************************

	TidyService

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TidyService.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"

@implementation TidyService


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - tidySelection
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidySelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    [self performTidySelection:pboard userData:userData error:error bodyOnly:NO];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - tidySelectionBodyOnly
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidySelectionBodyOnly:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    [self performTidySelection:pboard userData:userData error:error bodyOnly:YES];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - performTidySelection (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)performTidySelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error bodyOnly:(BOOL)bodyOnly
{
    /* Test for strings on the pasteboard. */

    NSArray *classes = [NSArray arrayWithObject:[NSString class]];

    NSDictionary *options = [NSDictionary dictionary];
    
    if (![pboard canReadObjectForClasses:classes options:options])
	{
        *error = JSDLocalizedString(@"tidyCantRead", nil);
        return;
    }


    /* Perform the Tidying and get the current Preferences. */

	NSString *pboardString = [pboard stringForType:NSPasteboardTypeString];

    JSDTidyModel *localModel = [[JSDTidyModel alloc] initWithString:pboardString];


	/*
	   The macro from CommonHeaders.h initWithSuiteName is the means
	   for accessing shared preferences when everything is sandboxed.
	 */
	NSUserDefaults *localDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];
	[localModel takeOptionValuesFromDefaults:localDefaults];
	JSDTidyOption *localOption = localModel.tidyOptions[@"force-output"];
	localOption.optionValue = @"YES";

	localOption = localModel.tidyOptions[@"show-body-only"];
	localOption.optionValue = bodyOnly ? @"1" : @"0";

	/* Grab a current copy of tidyText */

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
