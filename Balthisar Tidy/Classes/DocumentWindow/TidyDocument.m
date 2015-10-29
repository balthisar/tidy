/**************************************************************************************************

	TidyDocument
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TidyDocument.h"
#import "CommonHeaders.h"

#import "TidyDocumentWindowController.h"
#import "TidyDocumentSourceViewController.h"
#import "JSDTextView.h"

#import "JSDTidyModel.h"


@implementation TidyDocument


#pragma mark - Initialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
  - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
	if ((self = [super init]))
	{
		_tidyProcess = [[JSDTidyModel alloc] init];
		_documentOpenedData = nil;
		_documentIsLoading = NO;
		_fileWantsProtection = NO;
	}

	return self;
}


#pragma mark - Setup


/*———————————————————————————————————————————————————————————————————*
  - makeWindowControllers
 *———————————————————————————————————————————————————————————————————*/
- (void)makeWindowControllers
{
	self.windowController = [[TidyDocumentWindowController alloc] init];

	[self addWindowController:self.windowController];
}


#pragma mark - File I/O Handling


/*———————————————————————————————————————————————————————————————————*
  - readFromURL:ofType:error:
    Called as part of the responder chain. We already have a
    name and type as a result of
	  (1) the file picker, or
      (2) opening a document from Finder.
    Here, we'll merely load the file contents into an NSData, and
    then defer it for processing when the nib awakes (since we're 
    likely to be called here before the nib and its controls exist).
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)readFromURL:(NSString *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	/* Save the data for use until after the Nib is awake. */

	_documentOpenedData = [NSData dataWithContentsOfFile:absoluteURL];

	/*
	   self.documentIsLoading is used later to prevent some multiple
	   notifications that aren't needed, and represents that we've
	   loaded data from a file.
	 */
	self.documentIsLoading = !(self.documentOpenedData == nil);


	/*
	  Flag that we've loaded data from a file. Our file-safety
	  checks will use this later.
	 */
	self.fileWantsProtection = !(self.documentOpenedData == nil);

	return YES;
}


/*———————————————————————————————————————————————————————————————————*
  - revertToContentsOfURL:ofType:error:
    Allow the default reversion to take place, and then put the
    correct value in the editor if it took place. The super
    method does `readFromFile`, so put the documentOpenedData
    into our `tidyProcess`.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL didRevert;

	if ((didRevert = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]))
	{
		self.documentIsLoading = YES;
		
		[self.tidyProcess setSourceTextWithData:self.documentOpenedData];
	}

	return didRevert;
}


/*———————————————————————————————————————————————————————————————————*
  - dataOfType:error:
    Called as a result of saving files. All we're going to do is
    pass back the NSData taken from the TidyDoc, using the
    encoding specified by `output-encoding`.
 *———————————————————————————————————————————————————————————————————*/
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	return self.tidyProcess.tidyTextAsData;
}


/*———————————————————————————————————————————————————————————————————*
  - writeToUrl:ofType:error:
    Called as a result of saving files, and does the actual
    writing. We're going to override it so that we can update
    the `sourceView` automatically any time the file is saved.
    Setting `sourceView` will kick off the `textDidChange` event
    chain, which will set [tidyProcess sourceText] for us later.
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL success = [super writeToURL:absoluteURL ofType:typeName error:outError];
	
	if (success)
	{
		[self.windowController documentDidWriteFile];

		self.fileWantsProtection = NO;

	}
	
	return success;
}


/*———————————————————————————————————————————————————————————————————*
  - saveDocument:
    We're going to override the default save to make sure we can
    comply with the user's preferences. We're going to be over-
    protective because we don't want to get blamed for screwing up
    the user's data if Tidy doesn't process something correctly.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)saveDocument:(id)sender
{
	NSUserDefaults *localDefaults = [NSUserDefaults standardUserDefaults];
	
	/*
		Warning will only apply if there's a current file
		and it's NOT been saved yet, and it's not new.
	 */
	if ( ([[localDefaults valueForKey:JSDKeySavingPrefStyle] longValue] == kJSDSaveButWarn) &&
		 (self.fileWantsProtection) &&
		 (self.fileURL.path.length > 0) )
	{
#ifdef FEATURE_EMPHASIZE_HELPER
		[self.windowController.window setAlphaValue:0.0f];
#endif
		NSInteger i = NSRunAlertPanel(NSLocalizedString(@"WarnSaveOverwrite", nil),
									  @"%@",
									  NSLocalizedString(@"continue save", nil),
									  NSLocalizedString(@"do not save", nil),
									  nil,
									  NSLocalizedString(@"WarnSaveOverwriteExplain", nil));

		if (i == NSAlertAlternateReturn)
		{
			return; // User chose don't save.
		}
	}

	/* Save is completely disabled -- tell user to Save As… */

	if ( ([[localDefaults valueForKey:JSDKeySavingPrefStyle] longValue] == kJSDSaveAsOnly) &&
		(self.fileWantsProtection) )
	{
#ifdef FEATURE_EMPHASIZE_HELPER
		[self.windowController.window setAlphaValue:0.0f];
#endif
		NSRunAlertPanel(NSLocalizedString(@"WarnSaveDisabled", nil),
						@"%@",
						NSLocalizedString(@"cancel", nil),
						nil,
						nil,
						NSLocalizedString(@"WarnSaveDisabledExplain", nil));

		return; // Don't continue the save operation
	}

	return [super saveDocument:sender];
}


#pragma mark - Printing Support


/*———————————————————————————————————————————————————————————————————*
  - printDocumentWithSettings:error:
 *———————————————————————————————————————————————————————————————————*/
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings
										   error:(NSError **)outError
{
	[self.printInfo setHorizontalPagination: NSFitPagination];
	[self.printInfo setVerticalPagination: NSAutoPagination];
	[self.printInfo setVerticallyCentered:NO];
	[self.printInfo setLeftMargin:36];
	[self.printInfo setRightMargin:36];
	[self.printInfo setTopMargin:36];
	[self.printInfo setBottomMargin:36];

	return [NSPrintOperation printOperationWithView:self.windowController.sourceController.tidyTextView printInfo:self.printInfo];
}


#pragma mark - Property Accessors


/*———————————————————————————————————————————————————————————————————*
  @property sourceText
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)sourceText
{
	return self.windowController.sourceController.sourceTextView.string;
}

- (void)setSourceText:(NSString *)sourceText
{
	self.windowController.sourceController.sourceTextView.string = sourceText;
	
	/*
	  Setting the text directly does not set off the event chain,
	  so this cheat will allow us to activate the delegate directly.
	 */
	
    [self.windowController.sourceController textDidChange:nil];
}

/*———————————————————————————————————————————————————————————————————*
  @proeprty tidyText
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)tidyText
{
	return self.windowController.sourceController.tidyTextView.string;
}


@end
