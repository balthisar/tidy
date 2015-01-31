/**************************************************************************************************

	JSDTidyModelDelegate.h

	JSDTidyModel is a nice, Mac OS X wrapper for TidyLib. It uses instances of JSDTidyOption
	to contain TidyOptions. The model works with every built-in	TidyOption, although applications
	can suppress multiple individual TidyOptions if desired.
	

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

@import Foundation;

@class JSDTidyModel;
@class JSDTidyOption;

/*
	TidyLib will post the following NSNotifications.
*/

#define tidyNotifyOptionChanged                  @"JSDTidyDocumentOptionChanged"
#define tidyNotifySourceTextChanged              @"JSDTidyDocumentSourceTextChanged"
#define tidyNotifySourceTextRestored             @"JSDTidyDocumentSourceTextRestored"
#define tidyNotifyTidyTextChanged                @"JSDTidyDocumentTidyTextChanged"
#define tidyNotifyTidyErrorsChanged              @"JSDTidyDocumentTidyErrorsChanged"
#define tidyNotifyPossibleInputEncodingProblem   @"JSDTidyNotifyPossibleInputEncodingProblem"


#pragma mark - protocol JSDTidyModelDelegate

/*
	Protocol to define the Tidy delegate expectations.
*/

@protocol JSDTidyModelDelegate <NSObject>


@optional

- (void)tidyModelOptionChanged:(JSDTidyModel *)tidyModel 
                        option:(JSDTidyOption *)tidyOption;

- (void)tidyModelSourceTextChanged:(JSDTidyModel *)tidyModel
                              text:(NSString *)text;

- (void)tidyModelSourceTextRestored:(JSDTidyModel *)tidyModel
							  text:(NSString *)text;

- (void)tidyModelTidyTextChanged:(JSDTidyModel *)tidyModel
                            text:(NSString *)text;

- (void)tidyModelTidyMessagesChanged:(JSDTidyModel *)tidyModel
                            messages:(NSArray *)messages;

- (void)tidyModelDetectedInputEncodingIssue:(JSDTidyModel *)tidyModel
                            currentEncoding:(NSStringEncoding)currentEncoding
                          suggestedEncoding:(NSStringEncoding)suggestedEncoding;

@end

