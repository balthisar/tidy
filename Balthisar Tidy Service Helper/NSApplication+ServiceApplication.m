/**************************************************************************************************

	NSApplication+ServiceApplication

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import <objc/runtime.h>
#import "NSApplication+ServiceApplication.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"


static char sourceTextKey;

@implementation NSApplication (ServiceApplication)


#pragma mark - Properties useful to implementors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 @property sourceText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)sourceText
{
	return objc_getAssociatedObject(self, &sourceTextKey);
}

- (void)setSourceText:(NSString *)sourceText
{
	objc_setAssociatedObject(self, &sourceTextKey, sourceText, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property tidyText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyText
{
	return [self performTidy:self.sourceText bodyOnly:NO];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property tidyBodyText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyBodyText
{
	return [self performTidy:self.sourceText bodyOnly:YES];
}


#pragma mark - Private


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 - performTidy (private)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)performTidy:(NSString *)sourceText bodyOnly:(BOOL)bodyOnly
{
	
	/* Perform the Tidying and get the current Preferences. */
	
	JSDTidyModel *localModel = [[JSDTidyModel alloc] initWithString:sourceText];
	
	
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
	
	localModel.sourceText = sourceText;

	return localModel.tidyText;
}


@end
