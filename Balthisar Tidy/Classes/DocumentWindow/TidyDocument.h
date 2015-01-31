/**************************************************************************************************

	TidyDocument
	 
	The main document controller, TidyDocument manages a single Tidy document and mediates
	access between the TidyDocumentWindowController and the JSDTidyModel processor.


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

@import Cocoa;

@class JSDTidyModel;
@class TidyDocumentWindowController;


@interface TidyDocument : NSDocument


@property (readonly) JSDTidyModel *tidyProcess;             // Instance of JSDTidyModel that will perform all work.

@property (readonly) NSData *documentOpenedData;            // The original, loaded data if opened from file.

@property (assign) BOOL documentIsLoading;                  // Flag to indicate that the document is in loading process.

@property TidyDocumentWindowController *windowController;   // The associated windowcontroller.

@property (assign) BOOL fileWantsProtection;                // Indicates whether we need special type of save.


/* Properties used for AppleScript support */

@property (assign) NSString *sourceText;           // Source Text, mostly for AppleScript KVC support.

@property (readonly, assign) NSString *tidyText;   // Tidy'd Text, mostly for AppleScript KVC support.


@end
