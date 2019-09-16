//
//  JSDTidyModelDelegate.h
//  JSSDTidyFramework
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Foundation;

@class JSDTidyModel;
@class JSDTidyOption;

/* JSDTidyFramework will post the following NSNotifications. */
#define tidyNotifyOptionChanged                  @"JSDTidyDocumentOptionChanged"
#define tidyNotifySourceTextChanged              @"JSDTidyDocumentSourceTextChanged"
#define tidyNotifySourceTextRestored             @"JSDTidyDocumentSourceTextRestored"
#define tidyNotifyTidyTextChanged                @"JSDTidyDocumentTidyTextChanged"
#define tidyNotifyTidyErrorsChanged              @"JSDTidyDocumentTidyErrorsChanged"
#define tidyNotifyPossibleInputEncodingProblem   @"JSDTidyNotifyPossibleInputEncodingProblem"


#pragma mark - protocol JSDTidyModelDelegate


/**
 *  The @c JSDTidyModelDelegate protocol defines the interfaces for delegate
 *  methods for @c JSDTidyFramework.
 *
 *  If instances of @c JSDTidyModel are assigned a delegate, then the delegate
 *  should implement zero or more of these methods.
 *
 *  This header file also provides convenient @c #define's that can be used to
 *  register for @c NSNotification's in addition to or instead of using
 *  delegates, and correspond with the related delegate methods below.
 *
 *  @li #define tidyNotifyOptionChanged
 *  @li #define tidyNotifySourceTextChanged
 *  @li #define tidyNotifySourceTextRestored
 *  @li #define tidyNotifyTidyTextChanged
 *  @li #define tidyNotifyTidyErrorsChanged
 *  @li #define tidyNotifyPossibleInputEncodingProblem
 */
@protocol JSDTidyModelDelegate <NSObject>


@optional

/**
 *  @c tidyModelOptionChange will be called when one or more @c tidyOptions
 *  are changed. (The corresponding @c NSNotification is defined by
 *  @c tidyNotifyOptionChanged.)
 *
 *  @param tidyModel Indicates the instance of the @c JSDTidyModel that is
 *    calling the delegate.
 *  @param tidyOption Indicates which instance of @c JSDTidyOption was changed.
 */
- (void)tidyModelOptionChanged:(JSDTidyModel *)tidyModel 
                        option:(JSDTidyOption *)tidyOption;

/**
 *  @c tidyModelSourceTextChanged will be called when @c sourceText is
 *  changed. (The corresponding @c NSNotification is defined by
 *  @c tidyNotifySourceTextChanged.)
 *
 *  @param tidyModel Indicates the instance of the @c JSDTidyModel that is
 *    calling the delegate.
 *  @param text Provides the new source text.
 */
- (void)tidyModelSourceTextChanged:(JSDTidyModel *)tidyModel
                              text:(NSString *)text;

/**
 *  @c tidyModelSourceTextRestored will be called when @c sourceText is
 *  restored, or source text is set via @c setSourceTextWithData: or
 *  @c setSourceTextWithFile:. (The corresponding
 *  @c NSNotification is defined by @c tidyNotifySourceTextRestored.)
 *
 *  @param tidyModel Indicates the instance of the @c JSDTidyModel that is
 *    calling the delegate.
 *  @param text Provides the text that was restored.
 */
- (void)tidyModelSourceTextRestored:(JSDTidyModel *)tidyModel
							  text:(NSString *)text;

/**
 *  @c tidyModelTidyTextChanged will be called when @c tidyText is changed,
 *  which is usually the result of setting @c sourceText or one of the options
 *  @c tidyOptions. (The corresponding @c NSNotification is defined by
 *  @c tidyNotifyTidyTextChanged.)
 *
 *  @param tidyModel Indicates the instance of the @c JSDTidyModel that is
 *    calling the delegate.
 *  @param text Provides the new tidy'd text.
 */
- (void)tidyModelTidyTextChanged:(JSDTidyModel *)tidyModel
                            text:(NSString *)text;

/**
 *  @c tidyModelTidyMessagesChanged will be called when the @c errorText and
 *  @c errorArray changes (these represet the same information and always
 *  change together). (The corresponding @c NSNotification is defined by
 *  @c tidyNotifyTidyErrorsChanged.)
 *
 *  @param tidyModel Indicates the instance of the @c JSDTidyModel that is
 *    calling the delegate.
 *  @param messages Provides the array of error messages.
 */
- (void)tidyModelTidyMessagesChanged:(JSDTidyModel *)tidyModel
                            messages:(NSArray *)messages;

/**
 *  @c tidyModelDetectedInputEncodingIssue will be called when an
 *  @b input-encoding problem is detected when attempting to use
 *  @c setSourceTextWithData: or @c setSourceTextWithFile:, as well with
 *  ant of the @c NSObject or file-based initializers. ( The corresponding
 *  @c NSNotification is defined by @c tidyNotifyPossibleInputEncodingProblem.
 *
 *  @param tidyModel Indicates the instance of the @c JSDTidyModel that is
 *    calling the delegate.
 *  @param currentEncoding Indicates the @c NSStringEncoding that was
 *    provided that it causing an encoding issue.
 *  @param suggestedEncoding Indicates the suggested @c NSStringEncoding that
 *    should be used instead of that provided.
 */
- (void)tidyModelDetectedInputEncodingIssue:(JSDTidyModel *)tidyModel
                            currentEncoding:(NSStringEncoding)currentEncoding
                          suggestedEncoding:(NSStringEncoding)suggestedEncoding;

@end
