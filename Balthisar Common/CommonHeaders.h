/**************************************************************************************************

	CommonHeaders.h
 
	Copyright © 2003-2018 by Jim Derry. All rights reserved.

	Application-wide preferences and definitions.
	- Keys for top-hierarchy preferences managed by this application.
	- Definitions for behaviors based on the build targets' preprocessor macros.
    - Provideds `JSDLocalizedString` as an `NSLocalizedString` substitute for dependencies.

 **************************************************************************************************/

@import Foundation;

#ifndef CommonHeaders_h
#define CommonHeaders_h

/*=======================================================*
  Minimum wanted libtidy version
 *=======================================================*/
#pragma mark - LibTidy version checking

	#define LIBTIDY_V_WANT @"5.6.0"


/*=======================================================*
  These defs are used as key in userDefaults.
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
	#define JSDKeyValidatorBuiltInUseLocalhost    @"ValidatorBuiltInUseLocalhost"
    #define JSDKeyValidatorAutoW3C                @"ValidatorAutoW3C"
    #define JSDKeyValidatorThrottleW3C            @"ValidatorThrottleW3C"
    #define JSDKeyValidatorAutoCustom             @"ValidatorAutoCustom"
    #define JSDKeyValidatorThrottleCustom         @"ValidatorThrottleCustom"
    #define JSDKeyValidatorCustomServer           @"ValidatorCustomServer"

	/* Other */

	#define JSDKeyWebPreviewThrottleTime          @"WebPreviewThrottleTime"


	/*
		Note that builds that include Sparkle have Sparkle-related
		preferences keys that are implemented automatically by
		Sparkle. Nothing else is defined for them.
	 */
    #define JSDSparkleDefaultIntervalKey          @"SUScheduledCheckInterval"


/*=======================================================*
  These defs determine which features and other version-
  specific behaviors and settings apply to a target. Note
  that the fallback version covers cases for components
  that we're building in that don't have multiple, per-
  version targets, e.g., the Service Helper app.
 *=======================================================*/
#pragma mark - Feature Definitions

/*************************************
 * Target Macros
 *
 * Note that not all of these macros will include a feature on thier own;
 * the only affect the compiled code. For example to enable AppleScript
 * you also have to include the SDEF in the target and set the name in
 * user-defined build settings.
 *
 * FEATURE_SPARKLE              Includes Sparkle into the build.
 * USE_STANDARD_MENU_NAME       Main and Quit menu item names "for Work" versus not.
 * FEATURE_FAKE_SPARKLE         Fakes Sparkle. Useful for automating screenshots.
 * FEATURE_SUPPORTS_SERVICE     Include support for our System Services.
 * FEATURE_SUPPORTS_EXTENSIONS  Include support for our Action Extensions.
 * FEATURE_EXPORTS_CONFIG       Target will export tidy.cfg files.
 * FEATURE_SUPPORTS_APPLESCRIPT Target will support AppleScript.
 * FEATURE_SUPPORTS_THEMES      Target allows use of Color preference panel.
 * FEATURE_EXPORTS_RTF          Target will export RTF files of Tidy'd text.
 * FEATURE_SUPPORTS_SXS_DIFFS   Not implemented yet. Side by Side diffs.
 */

#if defined(TARGET_WEB)
    #define FEATURE_SPARKLE
    #define USE_STANDARD_MENU_NAME
//  #define FEATURE_FAKE_SPARKLE
    #define FEATURE_SUPPORTS_SERVICE
    #define FEATURE_SUPPORTS_EXTENSIONS
//  #define FEATURE_SUPPORTS_DUAL_PREVIEW
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
//	#define FEATURE_SUPPORTS_THEMES
//  #define FEATURE_EXPORTS_RTF
//	#define FEATURE_SUPPORTS_SXS_DIFFS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
#elif defined(TARGET_APP)
//	#define FEATURE_SPARKLE
    #define USE_STANDARD_MENU_NAME
//  #define FEATURE_FAKE_SPARKLE
    #define FEATURE_SUPPORTS_SERVICE
    #define FEATURE_SUPPORTS_EXTENSIONS
//  #define FEATURE_SUPPORTS_DUAL_PREVIEW
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
//	#define FEATURE_SUPPORTS_THEMES
//  #define FEATURE_EXPORTS_RTF
//	#define FEATURE_SUPPORTS_SXS_DIFFS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
#elif defined(TARGET_PRO)
//	#define FEATURE_SPARKLE
//  #define USE_STANDARD_MENU_NAME
//  #define FEATURE_FAKE_SPARKLE
    #define FEATURE_SUPPORTS_SERVICE
    #define FEATURE_SUPPORTS_EXTENSIONS
    #define FEATURE_SUPPORTS_DUAL_PREVIEW
	#define FEATURE_EXPORTS_CONFIG
	#define FEATURE_SUPPORTS_APPLESCRIPT
	#define FEATURE_SUPPORTS_THEMES
    #define FEATURE_EXPORTS_RTF
	#define FEATURE_SUPPORTS_SXS_DIFFS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
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
