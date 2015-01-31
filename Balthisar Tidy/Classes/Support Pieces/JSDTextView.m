/**************************************************************************************************
 
	JSDTextView

	Simple NSTextView subclass that

		- receives file contents instead of file name when dropping files.

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

#import "JSDTextView.h"


@implementation JSDTextView

/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	concludeDragOperation:sender
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
