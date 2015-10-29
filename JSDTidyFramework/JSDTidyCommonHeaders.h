/**************************************************************************************************

	JSDTidyCommonHeaders.h

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#ifndef JSDTidyCommonHeaders_h
#define JSDTidyCommonHeaders_h


#pragma mark - Defines

/*
 This is the main key in the implementing application's prefs file under which all of the TidyLib
 options will be written. You might change this if your application uses Cocoa's native preferences
 system.
 */

#define JSDKeyTidyTidyOptionsKey @"JSDTidyTidyOptions"


#pragma mark - JSDLocalizedString

/* Simple NSLocalizedString substitute. */
#define JSDLocalizedString(key, val) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:(val) table:nil]


#endif
