/**************************************************************************************************

	ActionRequestHandler

	Handles the Action Extension actions for Balthisar Tidy, in order to tidy selected text
    in a host application.


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

#import "ActionRequestHandler.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"

@implementation ActionRequestHandler


#ifdef FEATURE_SUPPORTS_EXTENSIONS


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	beginRequestWithExtensionContext
		Tidy's the provided text and returns it.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context
{
	/*
	 The macro from CommonHeaders.h initWithSuiteName is the
	 means for accessing shared preferences when everything is sandboxed.
	 */
	NSUserDefaults *localDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_PREFS];


	/* Get the input item. */
	NSExtensionItem *item = context.inputItems.firstObject;
	NSString *content = [item.attributedContentText string];

	/* Set option and perform the Tidying */
	JSDTidyModel *localModel = [[JSDTidyModel alloc] initWithString:content];
	[localModel takeOptionValuesFromDefaults:localDefaults];
	JSDTidyOption *localOption = localModel.tidyOptions[@"force-output"];
	localOption.optionValue = @"YES";

	/* Grab a current copy of tidyText */
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
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		[context cancelRequestWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
	}
}


#endif


@end
