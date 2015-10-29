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

	#define JSDKeyShowNewDocumentLineNumbers      @"ShowNewDocumentLineNumbers"
	#define JSDKeyShowNewDocumentMessages         @"ShowNewDocumentMessages"
	#define JSDKeyShowNewDocumentTidyOptions      @"ShowNewDocumentTidyOptions"
	#define JSDKeyShowNewDocumentSideBySide       @"ShowNewDocumentSideBySide"
	#define JSDKeyShowNewDocumentSyncInOut        @"ShowNewDocumentSyncInOut"


	/* Saving - File Saving Options */

	#define JSDKeySavingPrefStyle                 @"SavingPrefStyle"


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


#if defined(TARGET_WEB)
	#define FEATURE_ADVERTISE_PRO
	#define FEATURE_SPARKLE
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
	#define FEATURE_SUPPORTS_SERVICE
	#define FEATURE_SUPPORTS_EXTENSIONS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
//	#define FEATURE_SUPPORTS_SXS_DIFFS
#elif defined(TARGET_APP)
	#define FEATURE_ADVERTISE_PRO
//	#define FEATURE_SPARKLE
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
	#define FEATURE_SUPPORTS_SERVICE
	#define FEATURE_SUPPORTS_EXTENSIONS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
//	#define FEATURE_SUPPORTS_SXS_DIFFS
#elif defined(TARGET_PRO)
//	#define FEATURE_ADVERTISE_PRO
//	#define FEATURE_SPARKLE
	#define FEATURE_EXPORTS_CONFIG
	#define FEATURE_SUPPORTS_APPLESCRIPT
	#define FEATURE_SUPPORTS_SERVICE
	#define FEATURE_SUPPORTS_EXTENSIONS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
	#define FEATURE_SUPPORTS_SXS_DIFFS
#else
//	#define FEATURE_ADVERTISE_PRO
//	#define FEATURE_SPARKLE
//	#define FEATURE_EXPORTS_CONFIG
//	#define FEATURE_SUPPORTS_APPLESCRIPT
	#define FEATURE_SUPPORTS_SERVICE
//	#define FEATURE_SUPPORTS_EXTENSIONS
    #define APP_GROUP_PREFS @"9PN2JXXG7Y.com.balthisar.Balthisar-Tidy.prefs"
//	#define FEATURE_SUPPORTS_SXS_DIFFS
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


#pragma mark - Special Development Tasks
/*=======================================================*
   These defs are used for special development tasks.
 *=======================================================*/

/* FAKE Sparkle so Pro Version can use Applescript to take screenshots. */
//#define FEATURE_FAKE_SPARKLE

/* Make the document window transparent when the encoding helper starts. */
//#define FEATURE_EMPHASIZE_HELPER


#endif
