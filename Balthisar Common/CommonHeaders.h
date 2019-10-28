//
//  CommonHeaders.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//
//  Application-wide preferences and definitions.
//  - Keys for top-hierarchy preferences managed by this application.
//  - Definitions for behaviors based on the build targets' preprocessor macros.
//  - Provideds `JSDLocalizedString` as an `NSLocalizedString` substitute for
//    dependencies.
//

@import Foundation;

#ifndef CommonHeaders_h
#define CommonHeaders_h

/*=======================================================*
  These defs are used as keys in userDefaults.
 *=======================================================*/
#pragma mark - User Defaults Keys

    /* Tidy - Key under which to store TidyOptions */

    #ifdef JSDKeyTidyTidyOptionsKey
        #undef JSDKeyTidyTidyOptionsKey
    #endif
    #define JSDKeyTidyTidyOptionsKey              @"JSDTidyTidyOptions"

    /* Options - List Appearance */

    #define JSDKeyOptionsAlternateRowColors       @"OptionsAlternateRowColors"
    #define JSDKeyOptionsAreGrouped               @"OptionsAreGrouped"
    #define JSDKeyOptionsShowDescription          @"OptionsShowDescriptions"
    #define JSDKeyOptionsShowHumanReadableNames   @"OptionsShowHumanReadableNames"
    #define JSDKeyOptionsUseHoverEffect           @"OptionsUseHoverEffect"

    /* Document - Document */

    #define JSDKeyShowNewDocumentMessages         @"ShowNewDocumentMessages"
    #define JSDKeyShowNewDocumentTidyOptions      @"ShowNewDocumentTidyOptions"
    #define JSDKeyShowNewDocumentSideBySide       @"ShowNewDocumentSideBySide"
    #define JSDKeyShowNewDocumentSyncInOut        @"ShowNewDocumentSyncInOut"
    #define JSDKeyShowWrapMarginNot               @"ShowWrapMarginNot"
    #define JSDKeyShouldOpenUntitledFile          @"ShouldOpenUntitledFile"


    /* Saving - File Saving Options */

    #define JSDKeySavingPrefStyle                 @"SavingPrefStyle"

    /* Editor - Preferences Group and Key for Editor and Color */

    #define JSDKeyTidyEditorSourceOptions         @"JSDTidyEditorSourceOptions"
    #define JSDKeyTidyEditorTidyOptions           @"JSDTidyEditorTidyOptions"


    /* Advanced - Options */

    #define JSDKeyAllowMacOSTextSubstitutions     @"AllowMacOSTextSubstitutions"
    #define JSDKeyFirstRunComplete                @"FirstRunComplete"
    #define JSDKeyFirstRunCompleteVersion         @"FirstRunCompleteVersion"
    #define JSDKeyIgnoreInputEncodingWhenOpening  @"IgnoreInputEncodingWhenOpeningFiles"
    #define JSDKeyAllowServiceHelperTSR           @"ServiceHelperDontForceQuit"
    #define JSDKeyAlreadyAskedServiceHelperTSR    @"ServiceHelperAskedUserTSR"
    #define JSDKeyAnimationReduce                 @"AnimationReduce"
    #define JSDKeyAnimationStandardTime           @"AnimationStandardTime"

    /* Application preferences */

    #define JSDKeyMessagesTableSortDescriptors    @"MessagesTableSortDescriptors"
    #define JSDKeyValidatorTableSortDescriptors   @"ValidatorTableSortDescriptors"

    /* Validator */

    #define JSDKeyValidatorSelection              @"ValidatorSelection"
    #define JSDKeyValidatorAuto                   @"ValidatorAuto"
    #define JSDKeyValidatorThrottleTime           @"ValidatorThrottleTime"
    #define JSDKeyValidatorURL                    @"ValidatorURL"

    #define JSDKeyValidatorAutoBuiltIn            @"ValidatorAutoBuiltIn"
    #define JSDKeyValidatorThrottleBuiltIn        @"ValidatorThrottleBuiltIn"
    #define JSDKeyValidatorBuiltInPort            @"ValidatorBuiltInPort"
    #define JSDKeyValidatorAutoW3C                @"ValidatorAutoW3C"
    #define JSDKeyValidatorThrottleW3C            @"ValidatorThrottleW3C"
    #define JSDKeyValidatorAutoCustom             @"ValidatorAutoCustom"
    #define JSDKeyValidatorThrottleCustom         @"ValidatorThrottleCustom"
    #define JSDKeyValidatorCustomServer           @"ValidatorCustomServer"

    /* Other */

    #define JSDKeyWebPreviewThrottleTime          @"WebPreviewThrottleTime"
	#define JSDKeyServiceHelperAllowsAppleScript  @"ObfuscatedPreferenceSeriousSecurityHere"

    /*
        Note that builds that include Sparkle have Sparkle-related
        preferences keys that are implemented automatically by
        Sparkle. Nothing else is defined for them.
     */
    #define JSDSparkleDefaultIntervalKey          @"SUScheduledCheckInterval"


/*=======================================================*
  This defines the key used for our application groups.
 *=======================================================*/
#pragma mark - Application Group Identifier

    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"


/*=======================================================*
  These defs determine which features and other version-
  specific behaviors and settings apply to a target when
  they must be hard-coded, such as Sparkle, which can't
  be included in App Store builds.
 *=======================================================*/
#pragma mark - Hard-Code Feature Definitions

#if defined(TARGET_WEB)
    #define FEATURE_SPARKLE
#endif


#pragma mark - Other Definitions
/*=======================================================*
  This enum is used in the DocumentWindow classes and
  value is stored in preferences to manage the type of
  save behavior that is applied to open, dirty documents.
 *=======================================================*/

/* The values for the save type behaviours related to app preferences. */
typedef NS_OPTIONS(NSUInteger, JSDSaveType)
{
    kJSDSaveNormal = 0,
    kJSDSaveButWarn = 1,
    kJSDSaveAsOnly = 2
};


/*=======================================================*
  This enum is used in the Validator preferences and
  stored in user defaults to control which validator is
  used.
 *=======================================================*/

/* The values for the validator type related to app preferences. */
typedef NS_OPTIONS(NSUInteger, JSDValidatorSelectionType)
{
    JSDValidatorUndefined = 0,
    JSDValidatorBuiltIn = 1,
    JSDValidatorW3C = 2,
    JSDValidatorCustom = 3
};


#pragma mark - JSDLocalizedString
/*=======================================================*
  Simple NSLocalizedString substitute.
 *=======================================================*/

#define JSDLocalizedString(key, val) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:(val) table:nil]


#endif
