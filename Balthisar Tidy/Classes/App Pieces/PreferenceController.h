/**************************************************************************************************

	PreferenceController.h
 
	part of Balthisar Tidy

	The main preference controller. Here we'll control the following:

		o Handles the application preferences.
		o Implements class methods to be used before instantiation.


	The MIT License (MIT)

	Copyright (c) 2001 to 2013 James S. Derry <http://www.balthisar.com>

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
#import "OptionPaneController.h"

extern NSString *JSDKeySavingPrefStyle;
extern NSString *JSDKeyWarnBeforeOverwrite;

@interface PreferenceController : NSWindowController {

	IBOutlet NSButton *saving1;				// pointer to enable save
	IBOutlet NSButton *saving2;				// pointer to disable save
	IBOutlet NSButton *savingWarn;			// pointer to warn on save

	IBOutlet NSView 	 *optionPane;		// pointer to our empty optionPane.
	OptionPaneController *optionController;	// this will control the real option pane loaded into optionPane

	JSDTidyDocument *tidyProcess;			// this will point to the optionPaneController's tidy process.

}
+ (void)registerUserDefaults;

- (IBAction)preferenceChanged:(id)sender;	// handler for a configuration option change.
@end
