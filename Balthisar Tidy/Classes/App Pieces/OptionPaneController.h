/**************************************************************************************************

	OptionPaneController.h
 
	part of Balthisar Tidy

	The main controller for the multi-use option pane. implemented separately for

		o use on a document window
		o use on the preferences window

	This controller parses optionsInEffect.txt in the application bundle, and compares
	the options listed there with the linked-in TidyLib to determine which options are
	in effect and valid. We use an instance of |JSDTidyDocument| to deal with this.


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
#import "JSDTidyDocument.h"
#import "JSDTableColumn.h"

@interface OptionPaneController : NSObject <JSDTableColumnProtocol>

	@property (nonatomic, strong) IBOutlet NSView *View;			// Pointer to the NIB's |View|.

	@property (nonatomic) SEL action;								// Specify an |action| when options change.

	@property (nonatomic, strong) id target;						// Specify a |target| for option changes.

	@property (nonatomic, strong) JSDTidyDocument *tidyDocument;	// Exposed so others can get settings and/or use the processor.


- (id)init;													// Initialize the view so we can use it.

- (void)putViewIntoView:(NSView *)dstView;					// Put this controller's |View| into |dstView|.

@end
