/**************************************************************************************************

	NSApplication+TidyApplication

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

/**
 *  This category to NSApplication handles some of our application-level AppleScript support.
 */
@interface NSApplication (TidyApplication)

#ifdef FEATURE_SUPPORTS_APPLESCRIPT

/**
 *  Handles AppleScript `preferencesWindowIsVisible` property.
 *
 *  This property can set or determine the visibility of Balthisar Tidy's
 *  Preferences window.
 */
@property (nonatomic, assign) BOOL preferencesWindowIsVisible;

/**
 *  Handles AppleScript `countOfPrefsWindowPanels` property.
 *
 *  @returns Returns 0 if the window isn't visible, or else a 1-based
 *  index of the currently-visible panel.
 */
@property (nonatomic, assign, readonly) NSInteger countOfPrefsWindowPanels;

/**
 *  Handles AppleScript `indexOfVisiblePrefsWindowPanel` property.
 *
 *  @returns Returns the number of preferences panels, which is useful
 *  when we don't know how many we have, such as nosparkle builds.
 */
@property (nonatomic, assign) NSInteger indexOfVisiblePrefsWindowPanel;

/**
 *  Handles AppleScript `saveAsDestination` property.
 *
 *  Sandboxed applications won't let AppleScript choose destination
 *  directories for Save As… operations, however the sandboxed
 *  application _does_ have this privilege.
 *
 *  Upon reading this property Bathisar Tidy will ask the user to
 *  choose a directory, giving it permission to save to the
 *  user-chosen directory. At this point the directory is available
 *  to Balthisar Tidy until the application quits, giving AppleScripts
 *  the ability to tell Balthisar Tidy to save to these directories.
 */
@property (nonatomic, strong, readonly) NSString *saveAsDestination;

#endif

@end
