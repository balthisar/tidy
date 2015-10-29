/**************************************************************************************************

	JSDTidyModelDelegate.h

	Copyright © 2003-2015 by Jim Derry. All rights reserved.
	
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

/**
 *  The **JSDTidyModelDelegate** protocol defines the interfaces for delegate methods for **JSDTidyFramework**.
 *  If instances of **JSDTidyModel** are assigned a delegate, then the delegate should implement zero or more
 *  of these methods.
 *
 *  This header file also provides convenient `#define`s that can be used to register for `NSNotification`s in
 *  addition to or instead of using delegates, and correspond with the related delegate methods below.
 *
 *  - `#define tidyNotifyOptionChanged`
 *  - `#define tidyNotifySourceTextChanged`
 *  - `#define tidyNotifySourceTextRestored`
 *  - `#define tidyNotifyTidyTextChanged`
 *  - `#define tidyNotifyTidyErrorsChanged`
 *  - `#define tidyNotifyPossibleInputEncodingProblem`
 */
@protocol JSDTidyModelDelegate <NSObject>


@optional

/**
 *  **tidyModelOptionChange** will be called when one or more [JSDTidyModel tidyOptions] are changed.
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifyOptionChanged`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param tidyOption Indicates which instance of **JSDTidyOption** was changed.
 */
- (void)tidyModelOptionChanged:(JSDTidyModel *)tidyModel 
                        option:(JSDTidyOption *)tidyOption;

/**
 *  **tidyModelSourceTextChanged** will be called when [JSDTidyModel sourceText] is changed.
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifySourceTextChanged`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param text Provides the new source text.
 */
- (void)tidyModelSourceTextChanged:(JSDTidyModel *)tidyModel
                              text:(NSString *)text;

/**
 *  **tidyModelSourceTextRestored** will be called when [JSDTidyModel sourceText] is restored, 
 *  source text is set via [JSDTidyModel setSourceTextWithData:] or [JSDTidyModel setSourceTextWithFile:].
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifySourceTextRestored`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param text Provides the text that was restored.
 */
- (void)tidyModelSourceTextRestored:(JSDTidyModel *)tidyModel
							  text:(NSString *)text;

/**
 *  **tidyModelTidyTextChanged** will be called when [JSDTidyModel tidyText] is changed, which is usually
 *  the result of setting [JSDTidyModel sourceText] or one of the options in [JSDTidyModel tidyOptions].
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifyTidyTextChanged`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param text Provides the new tidy'd text.
 */
- (void)tidyModelTidyTextChanged:(JSDTidyModel *)tidyModel
                            text:(NSString *)text;

/**
 *  **tidyModelTidyMessagesChanged** will be called when the [JSDTidyModel errorText]
 *  and [JSDTidyModel errorArray] changes (these represet the same information and always
 *  change together).
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifyTidyErrorsChanged`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param messages Provides the array of error messages.
 */
- (void)tidyModelTidyMessagesChanged:(JSDTidyModel *)tidyModel
                            messages:(NSArray *)messages;

/**
 *  **tidyModelDetectedInputEncodingIssue** will be called when an `input-encoding` problem is detected
 *  when attempting to use [JSDTidyModel setSourceTextWithData:] or [JSDTidyModel setSourceTextWithFile:],
 *  as well with and of the **NSObject** or file-based initializers.
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifyPossibleInputEncodingProblem`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param currentEncoding Indicates the `NSStringEncoding` that was provided that it causing an encoding issue.
 *  @param suggestedEncoding Indicates the suggested `NSStringEncoding` that should be used instead of that provided.
 */
- (void)tidyModelDetectedInputEncodingIssue:(JSDTidyModel *)tidyModel
                            currentEncoding:(NSStringEncoding)currentEncoding
                          suggestedEncoding:(NSStringEncoding)suggestedEncoding;

@end

