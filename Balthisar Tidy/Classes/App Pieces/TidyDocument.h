/**************************************************************************************************

	TidyDocument.h
	 
	The main document controller.


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
#import "JSDTidyModel.h"
#import "OptionPaneController.h"
#import "PreferenceController.h"
#import "NSTextView+JSDExtensions.h"
#import "FirstRunController.h"

/**
	TidyDocument manages the user interaction between the document
	window and the JSDTidyModel processor.
 */
@interface TidyDocument : NSDocument <NSTableViewDelegate, NSSplitViewDelegate, NSTextViewDelegate>

/**
	Source Text, mostly for AppleScript KVC support.
*/
@property (nonatomic, assign) NSString *sourceText;

/**
	Tidy'd Text, mostly for AppleScript KVC support.
 */
@property (nonatomic, assign, readonly) NSString *tidyText;


/**
	Allow a menu item to trigger this.
 */
- (IBAction)kickOffFirstRunSequence:(id)sender;

@end
