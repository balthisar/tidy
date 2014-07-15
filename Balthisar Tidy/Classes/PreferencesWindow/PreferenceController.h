/**************************************************************************************************

	PreferenceController
 
	The main preference controller. Here we'll control the following:

	- Handles the application preferences.
	- Implements class methods to be used before instantiation.
 
	This controller is a subclass of MASPreferencesController, upon which we are piggybacking
	to continue to use the singleton instance of this class as our main preference controller.
	As the application preferences model is not very large or sophisticated, this is a logical
	place to manage it for the time being.


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
#import "MASPreferencesWindowController.h"

@class JSDTidyModel;


@interface PreferenceController : MASPreferencesWindowController


#pragma mark - Class Methods


+ (id)sharedPreferences;        // Singleton accessor for this class.

+ (void)registerUserDefaults;   // Registers Balthisar Tidy's defaults with Mac OS X' defaults system.

+ (NSArray*)optionsInEffect;    // An array of the tidy options that Balthisar Tidy supports.


@end
