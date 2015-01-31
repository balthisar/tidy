/**************************************************************************************************

	TidyService

	This class provides the functions for allowing Balthisar Tidy to provide a service.
	It operates as a faceless app only and thus only provides the faceless services.
    Balthisar Tidy proper will provide other services.


	The MIT License (MIT)

	Copyright (c) 2001 to 2014 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import "TidyService.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"

@implementation TidyService


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 tidySelection
	 - Returns a Tidy'd version of the pasteboard text with a tidy'd
       version using the preferences defaults. We will try with
       force-output if no response.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)tidySelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
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


	/* Grab a current copy of tidyText */

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
