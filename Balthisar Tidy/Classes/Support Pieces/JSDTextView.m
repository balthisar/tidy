/**************************************************************************************************
 
	JSDTextView

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDTextView.h"


@implementation JSDTextView

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - concludeDragOperation:sender
	If we're dropping a file, then insert its contents.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pasteBoard = [sender draggingPasteboard];

	/**************************************************
		The pasteboard contains a list of file names
	 **************************************************/
	if ( [[pasteBoard types] containsObject:NSFilenamesPboardType] )
	{
		NSArray *fileNames = [pasteBoard propertyListForType:@"NSFilenamesPboardType"];

		for (NSString *path in fileNames)
		{
			NSString *contents;

			/*************************************
			  Mac OS X 10.10+: Will try to guess
			  the encoding of the dragged in file
			 *************************************/
			if ([NSString respondsToSelector:@selector(stringEncodingForData:encodingOptions:convertedString:usedLossyConversion:)])
			{
				NSData *rawData;
				if ((rawData = [NSData dataWithContentsOfFile:path]))
				{
					[NSString stringEncodingForData:rawData encodingOptions:nil convertedString:&contents usedLossyConversion:nil];
				}
			}
			/*************************************
			  Older Mac OS X can only accept UTF.
			 *************************************/
			else
			{
				NSError *error;
				contents = [NSString stringWithContentsOfFile:path usedEncoding:nil error:&error];
				if (error)
				{
					contents = nil;
				}
			}

			if (contents)
			{
				[self insertText:contents];
			}
			else
			{
				[super concludeDragOperation:sender];
			}
		}
	}
	/**************************************************
		No filenames, so implement standard behavior. 
	 **************************************************/
	else
	{
		[super concludeDragOperation:sender];
	}
}
@end
