/**************************************************************************************************

	NSApplication+TidyApplication.h

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

#import <Cocoa/Cocoa.h>
#import "PreferenceController.h"

/**
	This category to NSApplication handles the application-level AppleScript support.
 */
@interface NSApplication (TidyApplication)

/** Handles AppleScript's preferencesWindowIsVisible property */
@property (nonatomic, assign) BOOL preferencesWindowIsVisible;

/** Handles AppleScript's countOfPrefsWindowPanels property */
@property (nonatomic, readonly, assign) NSInteger countOfPrefsWindowPanels;

/** Handles AppleScript's indexOfVisiblePrefsWindowPanel property */
@property (nonatomic, assign) NSInteger indexOfVisiblePrefsWindowPanel;

@end
