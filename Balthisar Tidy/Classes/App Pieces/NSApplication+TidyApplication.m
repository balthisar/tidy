/**************************************************************************************************

	NSApplication+TidyApplication.m

	This category to NSApplication handles some of our application-level AppleScript support.


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

#import "NSApplication+TidyApplication.h"

@implementation NSApplication (TidyApplication)


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 preferencesWindowIsVisible
	 - We don't need an AppleScript command by using a property
	   to control and report the preferences window status.
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
	 indexOfVisiblePrefsWindowPanel
	 - Returns 0 if the window isn't visible, or else a 1-based
	   index of the currently-visible panel.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger)indexOfVisiblePrefsWindowPanel
{
	BOOL isWindowVisible = [[[PreferenceController sharedPreferences] window ] isVisible];
	if (isWindowVisible)
	{
		return [[PreferenceController sharedPreferences] indexOfCurrentTabView] + 1;
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
		[[PreferenceController sharedPreferences] setIndexOfCurrentTabView:indexOfVisiblePrefsWindowPanel - 1];
	}
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	 countOfPrefsWindowPanels
	 - Returns the number of preferences panels, which is useful
	   when we don't know how many we have, such as nosparkle builds.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSInteger) countOfPrefsWindowPanels
{
	return [[PreferenceController sharedPreferences] countOfTabViews];
}


@end
