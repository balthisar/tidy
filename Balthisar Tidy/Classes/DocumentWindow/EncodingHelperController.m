/**************************************************************************************************

	EncodingHelperController

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "EncodingHelperController.h"


@interface EncodingHelperController ()

/* Internal Properties */

@property (nonatomic, strong) TidyDocument *documentReference;
@property (nonatomic, strong) NSView *documentViewReference;
@property (nonatomic, assign) NSStringEncoding currentEncoding;
@property (nonatomic, assign) NSStringEncoding suggestedEncoding;


/* Outlets and Actions */

@property (nonatomic, weak) IBOutlet NSPopover   *popoverEncoding;
@property (nonatomic, weak) IBOutlet NSButton    *buttonEncodingDoNotWarnAgain;
@property (nonatomic, weak) IBOutlet NSButton    *buttonEncodingAllowChange;
@property (nonatomic, weak) IBOutlet NSButton    *buttonEncodingIgnoreSuggestion;
@property (nonatomic, weak) IBOutlet NSTextField *textFieldEncodingExplanation;

- (IBAction)popoverEncodingHandler:(id)sender;

@end


@implementation EncodingHelperController


/*———————————————————————————————————————————————————————————————————*
  - initWithNote:fromDocument:
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
  - awakeFromNib
    Called only as a result of loadView.
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
  - startHelper
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
  - popoverEncodingHandler:
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
