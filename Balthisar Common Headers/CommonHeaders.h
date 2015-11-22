/**************************************************************************************************

	CommonHeaders.h
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

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

	#define LIBTIDY_V_WANT @"5.1.24"


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

	/* Document - Appearance */

	#define JSDKeyShowNewDocumentMessages         @"ShowNewDocumentMessages"
	#define JSDKeyShowNewDocumentTidyOptions      @"ShowNewDocumentTidyOptions"
	#define JSDKeyShowNewDocumentSideBySide       @"ShowNewDocumentSideBySide"
	#define JSDKeyShowNewDocumentSyncInOut        @"ShowNewDocumentSyncInOut"
    #define JSDKeyShowWrapMarginNot               @"ShowWrapMarginNot"


	/* Saving - File Saving Options */

	#define JSDKeySavingPrefStyle                 @"SavingPrefStyle"

	/* Editor - Preferences Group and Key for Editor and Color */
	#define JSDKeyTidyEditorSourceOptions         @"JSDTidyEditorSourceOptions"
	#define JSDKeyTidyEditorTidyOptions           @"JSDTidyEditorTidyOptions"


	/* Advanced - Options */

	#define JSDKeyAllowMacOSTextSubstitutions     @"AllowMacOSTextSubstitutions"
	#define JSDKeyFirstRunComplete                @"FirstRunComplete"
	#define JSDKeyIgnoreInputEncodingWhenOpening  @"IgnoreInputEncodingWhenOpeningFiles"
	#define JSDKeyAllowServiceHelperTSR           @"ServiceHelperDontForceQuit"
	#define JSDKeyAlreadyAskedServiceHelperTSR    @"ServiceHelperAskedUserTSR"

	/* Application preferences */

	#define JSDKeyMessagesTableInitialSortKey     @"MessagesTableInitialSortKey"
	#define JSDKeyMessagesTableSortDescriptors    @"MessagesTableSortDescriptors"


	/* Other */



	/*
		Note that builds that include Sparkle have Sparkle-related
		preferences keys that are implemented automatically by
		Sparkle. Nothing is defined for them.
	 */


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
 * USE_STANDARD_QUIT_MENU_NAME  Quit menu item name "for Work" versus not.
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
    #define USE_STANDARD_QUIT_MENU_NAME
//  #define FEATURE_FAKE_SPARKLE
    #define FEATURE_SUPPORTS_SERVICE
    #define FEATURE_SUPPORTS_EXTENSIONS
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
//	#define FEATURE_SUPPORTS_THEMES
//  #define FEATURE_EXPORTS_RTF
//	#define FEATURE_SUPPORTS_SXS_DIFFS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
#elif defined(TARGET_APP)
//	#define FEATURE_SPARKLE
    #define USE_STANDARD_QUIT_MENU_NAME
//  #define FEATURE_FAKE_SPARKLE
    #define FEATURE_SUPPORTS_SERVICE
    #define FEATURE_SUPPORTS_EXTENSIONS
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
//	#define FEATURE_SUPPORTS_THEMES
//  #define FEATURE_EXPORTS_RTF
//	#define FEATURE_SUPPORTS_SXS_DIFFS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
#elif defined(TARGET_PRO)
//	#define FEATURE_SPARKLE
//  #define USE_STANDARD_QUIT_MENU_NAME
//  #define FEATURE_FAKE_SPARKLE
    #define FEATURE_SUPPORTS_SERVICE
    #define FEATURE_SUPPORTS_EXTENSIONS
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
typedef enum : NSInteger
{
	kJSDSaveNormal = 0,
	kJSDSaveButWarn = 1,
	kJSDSaveAsOnly = 2
} JSDSaveType;


#pragma mark - JSDLocalizedString
/*=======================================================*
  Simple NSLocalizedString substitute.
 *=======================================================*/

#define JSDLocalizedString(key, val) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:(val) table:nil]


#endif
