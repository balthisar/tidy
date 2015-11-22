/**************************************************************************************************

	NSApplication+ServiceApplication

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;

/**
 *  This category to NSApplication handles some of our AppleScript support.
 *  Specifically the "Balthisar Tidy Service Helper" is a perfect, headless
 *  engine for providing quick and dirty Tidy service via AppleScript. As a
 *  headless application it launches quickly without cluttering the user's
 *  display.
 *
 *  It only provides the tidy options as set in Balthisar Tidy, however, and
 *  as such should only be regarded as a companion.
 */
@interface NSApplication (ServiceApplication)


#pragma mark - Properties useful to implementors
/** @name Properties useful to implementors */

/**
 *  Handles AppleScript `sourceText` property.
 *
 *  @returns Set this text to contain the dirty text that you want to be Tidy'd.
 */
@property (nonatomic, strong) NSString *sourceText;

/**
 *  Handles AppleScript `tidyText` property.
 *
 *  @returns This property contains the tidy'd version of the `sourceText`.
 *  It will always contain a complete HTML document regardless of the
 *  `show-body-only` option setting. It uses the defaults specified in
 *  Balthisar Tidy's Preferences.
 */
@property (nonatomic, assign, readonly) NSString *tidyText;

/**
 *  Handles AppleScript `tidyBodyText` property.
 *
 *  @returns This property contains the tidy'd version of the `sourceText`. It will
 *  always return the body only section of a tidy'd document, regardless of the
 *  `show-body-only` option setting. It uses the defaults specified in
 *  Balthisar Tidy's Preferences.
 */
@property (nonatomic, assign, readonly) NSString *tidyBodyText;


@end
