/**************************************************************************************************

	NSApplication+TidyApplication

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "NSApplication+TidyApplication.h"
#import "CommonHeaders.h"

#import "PreferenceController.h"

@implementation NSApplication (TidyApplication)

#ifdef FEATURE_SUPPORTS_APPLESCRIPT

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property preferencesWindowIsVisible
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (BOOL)preferencesWindowIsVisible
{
	return [[[PreferenceController sharedPreferences] window ] isVisible];
}

- (void)setPreferencesWindowIsVisible:(BOOL)preferencesWindowIsVisible
{
	if (preferencesWindowIsVisible)
	{
		[[PreferenceController sharedPreferences] showWindow:nil];
	}
	else
	{
		[[PreferenceController sharedPreferences] close];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property indexOfVisiblePrefsWindowPanel
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)indexOfVisiblePrefsWindowPanel
{
	BOOL isWindowVisible = [[[PreferenceController sharedPreferences] window ] isVisible];
	if (isWindowVisible)
	{
		return [[PreferenceController sharedPreferences] indexOfSelectedController] + 1;
	}
	else
	{
		return 0;
	}
}

- (void)setIndexOfVisiblePrefsWindowPanel:(NSInteger)indexOfVisiblePrefsWindowPanel
{
	if (self.preferencesWindowIsVisible)
	{
		[[PreferenceController sharedPreferences] selectControllerAtIndex:indexOfVisiblePrefsWindowPanel - 1];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property countOfPrefsWindowPanels
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)countOfPrefsWindowPanels
{
	return [[[PreferenceController sharedPreferences] viewControllers] count];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  @property saveAsDestination
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString*)saveAsDestination
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setTitle:NSLocalizedString(@"Select Destination", nil)];
	[openPanel setMessage:NSLocalizedString(@"ChooseFolderMessage", nil)];

	if ([openPanel runModal] == NSFileHandlingPanelOKButton)
	{
		return [[openPanel URLs][0] path];
	}
	else
	{
		return @"";
	}
}

#endif

@end
