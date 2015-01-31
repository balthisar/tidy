/**************************************************************************************************

	EncodingHelperController

	Implements the encoding helper for Balthisar Tidy documents.


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

#import "EncodingHelperController.h"


@interface EncodingHelperController ()

/* Internal Properties */

@property (strong) TidyDocument *documentReference;
@property (strong) NSView *documentViewReference;
@property (assign) NSStringEncoding currentEncoding;
@property (assign) NSStringEncoding suggestedEncoding;


/* Outlets and Actions */

@property (weak) IBOutlet NSPopover   *popoverEncoding;
@property (weak) IBOutlet NSButton    *buttonEncodingDoNotWarnAgain;
@property (weak) IBOutlet NSButton    *buttonEncodingAllowChange;
@property (weak) IBOutlet NSButton    *buttonEncodingIgnoreSuggestion;
@property (weak) IBOutlet NSTextField *textFieldEncodingExplanation;

- (IBAction)popoverEncodingHandler:(id)sender;

@end


@implementation EncodingHelperController


/*———————————————————————————————————————————————————————————————————*
	initWithNote:fromDocument:
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)initWithNote:(NSNotification*)note fromDocument:(TidyDocument*)document forView:(NSView*)view
{
	self = [super initWithNibName:@"TidyEncodingHelper" bundle:nil];

	if (self)
	{
		self.documentReference = document;

		self.documentViewReference = view;

		self.currentEncoding = [[document valueForKeyPath:@"tidyProcess.inputEncoding"] unsignedLongValue];

		self.suggestedEncoding = [[[note userInfo] objectForKey:@"suggestedEncoding"] longValue];
	}

	return self;
}


/*———————————————————————————————————————————————————————————————————*
	awakeFromNib
		called only as a result of loadView.
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
	NSString *encodingCurrent = [NSString localizedNameOfStringEncoding:self.currentEncoding];

	NSString *encodingSuggested = [NSString localizedNameOfStringEncoding:self.suggestedEncoding];

	NSString *docName    = self.documentReference.fileURL.lastPathComponent;

	NSString *newMessage = [NSString stringWithFormat:self.textFieldEncodingExplanation.stringValue, docName, encodingCurrent, encodingSuggested];

	self.textFieldEncodingExplanation.stringValue = newMessage;

	self.buttonEncodingAllowChange.tag = self.suggestedEncoding;	// We'll fetch this later in popoverHandler.
}


/*———————————————————————————————————————————————————————————————————*
	startHelper
		Starts the helper with loadView and positions it near
		the targetView;
 *———————————————————————————————————————————————————————————————————*/
- (void)startHelper;
{
	if ([self.documentViewReference class] == [NSTextView class])
	{
		[(NSTextView*)self.documentViewReference setEditable:NO];
	}
	
	[self loadView];

	[self.popoverEncoding showRelativeToRect:self.documentViewReference.bounds
									  ofView:self.documentViewReference
							   preferredEdge:NSMaxYEdge];
}


/*———————————————————————————————————————————————————————————————————*
	popoverEncodingHandler:
		Handles all possibles actions from the input-encoding
		helper popover. The only two senders should be
		buttonAllowChange and buttonIgnoreSuggestion.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)popoverEncodingHandler:(id)sender
{
	if (sender == self.buttonEncodingAllowChange)
	{
		[self.documentReference setValue:[@(self.buttonEncodingAllowChange.tag) stringValue]
							  forKeyPath:@"windowController.optionController.tidyDocument.tidyOptions.input-encoding.optionValue"];
	}

	if ([self.documentViewReference class] == [NSTextView class])
	{
		[(NSTextView*)self.documentViewReference setEditable:YES];
	}

	[self.popoverEncoding performClose:self];
}



@end
