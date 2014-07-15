Balthisar Tidy (version 2.0)
============================

by Jim Derry, <http://www.balthisar.com>
Copyright © 2003-2014 by Jim Derry. All rights reserved.
See “Legal Stuff” below for license details.


About
-----

Sweep Away your Poor HTML Clutter.

Use Balthisar Tidy to make sure your HTML is clean, error free, and accessible. Now with HTML5 support
Balthisar Tidy surpasses Mac OS X’s built-in, terminal version of this venerable tool.

- Supports every Mac OS X file encoding.
- See a live preview of the effects each Tidy option has on your code.
- Identify errors and be directed to their exact location in your source code in an instant.
- Correct errors in the source document immediately.
- Identifies and automatically corrects several potential errors.
- Automatically cleans up ugly code from HTML generator applications.
- Identifies opportunities to ensure accessibility compliance.
- Pretty-print formats your source code for maximum legibility.


System Requirements
-------------------

_Balthisar Tidy_ has been released with support for Mac OS X 10.8 and newer.


Change Log
----------

### Balthisar Tidy 2.0.0 (June 2014)
- New Features
	- Toolbar with quick access to Balthisar Tidy's new features.
	- Show/Hide the Tidy Options panel on documents.
	- Show/Hide the Tidy Messages panel on documents.
	- Can display the source code view vertically now in addition to the traditional, horizontal layout.
	- Tidy options are much more beautiful with groups headers to indicate option categories.
	- New, modern Preferences system with lots of new options.
	- Brand new, improved help file.
	- New application and document icons. 
	- New main menu items to support new functionality.
	- Fixed a bug that allows two first-run helpers to be opened at the same time, which caused a crash.
	- Renamed the "first run helper" to "Quick Tutorial."
- New Features (Balthisar Tidy for Work)
	- Introducing Balthisar Tidy for Work.
	- Can export option settings to Unix configuration files.
	- AppleScript support.
- Changes developers will notice
	- JSDTidyModel has been refactored just a little bit.
	- The entire TidyDocument architecture has been re-written from the ground up in order to implement a better MVC object model and break apart the massive DocumentController.
	- OptionPaneController has been slightly refactored to become a ViewController.
	- Bit the bullet and use my own fork of TidyLib. Source is still compatible. This was done in order to incorporate the community pull requests that haven't been accepted by the maintainer yet.
	- New help building automation system. 
	- Some build flags meant to be used temporarily in order to facilitate screen shots, etc.
	

### Balthisar Tidy 1.5.0 (May 2014)

#### Visible changes
- The application in general has had several improvements.
	- New application and documents icons retaining the trademark Tidy Broom).
	- Added missing View menu in the main menu.
	- Added support for printing the Tidy'd text.
	- Added a Show New User Helper to the Help Menu.
- The documents window is now improved.
	- New documents retain the position and size of last-used document.
	- New documents splitter positions are retained based on last-used document.
- The Tidy options panel is improved.
	- It is now a modern Mac OS source list, including new controls.
	- Apply document's Tidy options to preferences (in a document).
	- Reset document options to preferences settings (in a document).
	- Revert to Tidy factory presets (while in Preferences).
- The Messages panel has some improvements.
	- It now has some pretty icons to help distinguish severity.
	- Columns are now all sortable.



#### Invisible changes
- Project directory layout changes.
- Back to icns files for all icons.
- Separated JSDTidyModel .strings into its own file.
- Modified base TidyLib to allow a new callback filter to enable localization of output messages.
- Added lots of strings to the new JSDTidyModel.strings to allow easy localization.


### Balthisar Tidy 1.1.0 (April 2014)

#### Visible changes
- Keyboard shortcuts! You can cycle through the values in nearly every option with the left and right cursor keys while the options list is focused.
- Now works with nearly any file type and extension.
- First-run helper reworked to prevent annoying users.
- Auto-size the description for items in the list of Tidy options.
- Description can be hidden or shown.
- Changes to many of the Tidy options descriptions.
- Pretty, styled descriptions of the Tidy options to increase legibility.
- Removed extraneous menu items in the application menus.
- Prevent automatic text substitutions in source editor.
- Tidy properly Tidy's new, blank documents.
- Pasting into a new, blank document now properly Tidy's immediately.
- Fixed a crash related to messages table when a change to the HTML source fixes an error but doesn't cause the Tidy'd document to change.
- Fixed an issue where messages table didn't update after saving a file.
- New default font in editor views.
- Existing preferences will be lost. Sorry, this is a one time occurrence. We changed a 12 year old preferences system into a modern one. We hope that a little bit of change after 12 years is acceptable.

#### Invisible changes
- Internal code refactoring include rewrite of core Cocoa wrapper to TidyLib.
- Move non-localized resources to resources root: Contents/Resources/
- TidyLib preferences are nested in the preferences dictionary.
- The main Tidy process now uses GCD to operate in another thread.


### Balthisar Tidy 1.0.1 (March 2014)
- Introduced backward support to Mac OS X 10.8 Mountain Lion
- Added a "first run helper" to give an overview to new users
- Added an Apple Help Help Book to provide fairly good documentation
- Added a file encoding helper to help users when Tidy thinks that the input-encoding is set wrong
- Added the Sparkle update engine to offer automatic updates
- Added preferences to support Sparkle
- Tweaked other preferences’s layouts for better usability and to support Cocoa bindings
- Other code tweaks, changes, and simplification

### Balthisar Tidy 0.72 (January 2014)
- Balthisar Tidy now properly saves in the user-chosen file encoding.
- Balthisar Tidy now properly opens files in non-UTF formats.

### Balthisar Tidy 0.7 (December 2013)

#### Visible changes
- Built for Mac OS X 10.9 (now minimum supported OS)
- Added Mac OS X full-screen support
- Added developer signature to make Gatekeeper happy
- Added Retina display App icons
- New file icons including support for Retina displays
- Improved the line numbers for the HTML and Tidy'd View
- Added and changed information in Tidy->About
- Default document window is larger.
- Tweaked the document window layout and appearance
- Tweaked the preferences window
- Adopted the most recent version of W3C TidyLib (more options!)
- Cleaned up remaining batch mode references. Will add in roadmap later.
- Cleaned up file encoding mechanism

#### Invisible changes
- Significant source code cleanup for legibility
- Some refactorization
- Some migrration to modern Objective-C style
- Patched some memory leaks
- Removed alldeprecated calls
- Started ivar to property conversion
- Eliminated all compiler warnings (except for TidyLib proper)


### Balthisar Tidy 0.6 (November 2007)

- Added support for universal binary.
- Now requires Mac OS X 10.4 or higher.

### Balthisar Tidy 0.5 (February 2003)

- Added support for a live error list in the document window.

### Balthisar Tidy 0.1 (December 2002)

- Initial release of _Balthisar Tidy_.
- Requires Mac OS X 10.2 or higher.


Building From Source
--------------------

If you’re building from source, be aware that there are now three (3) different build targets setup:

	- Balthisar Tidy (web)
	- Balthisar Tidy (app)
	- Balthisar Tidy (pro)

_Note that you will probably have to turn off code-signing unless you have an Apple Developer Account_. You
will still build the same product; it simply won’t be signed with a developer certificate.

### Build Targets

- **Balthisar Tidy (web)** will build the version distributed on the www.balthisar.com website, and will
  include support for Sparkle for auto-updating.

- **Balthisar Tidy (app)** will be build the version distributed on Apple's App Store, and does not include
  anything remotely associated with Sparkle. It is otherwise identical with the `(web)` build.

- **Balthisar Tidy (pro)** will build the version distributed as “Balthisar Tidy for Work” on the App Store.
  Yes, this is the paid version that includes AppleScript support and the ability to export Tidy configuration
  files, as well as future, unspecified changes. If you want to build it yourself and avoid paying for it in
  the App Store, you can! 


Legal Stuff
-----------

### Open Source

_Balthisar Tidy_ and all of its source code (including third party libraries) have been released under the MIT
license, or similar licenses. You can refer to the licenses in the source code.

Items that are not source code, such as artwork and the name "Balthisar" and "Balthisar Tidy" are not licensed
and remain the property of James S. Derry. See the Trademark and Artwork Policy, next.

Trademark and Artwork Policy
----------------------------

This text does not constitute a license; it is meant to clarify a general
policy regarding certain intellectual property, copyrights, and trademarks
that belong to Balthisar and/or Jim Derry.

"Balthisar Tidy™" is currently in commerce use to describe a software product
for personal computers that performs operations on files. This trademark is
used stylistically as "Balthisar Tidy."

"Balthisar™" is currently in commerce use to distinguish products, services, and
written content via electronic and other media. This trademark is used
stylistically as "balthisar," "balthisar.com," and "www.balthisar.com."

The entirety of _Balthisar Tidy_ is Copyright ©2003-2014 by Jim Derry. The
source code (including HTML files that constitute the Apple Help system) has
been released under the MIT License. Although you may use the source code for
any purpose allowed by the license, you may not use Jim Derry's artwork or
trademarks for any commercial purpose without explicit, personal permission. You
may not represent forks or other distributions (including binary distributions)
as having originated directly from balthisar.com or Jim Derry.

### Examples

You may choose to maintain the Balthisar artwork only if you maintain the
Balthisar branding.

You may choose to maintain the Balthisar branding. Forks that maintain Balthisar
branding must clearly indicate that they are forks in any public repository and
any publicly available binary. Github, for example, clearly indicates this
status on your behalf. You should modify the copyright information in the header
files to indicate additional copyright information for the changes you
introduce.

Binary distributions may use Balthisar branding and artwork, but it must be
obvious to the user that the application is a non-original version. For example,
"Bob's Improved Balthisar Tidy," or "YA Balthisar Tidy" make it clear that the
product origin is not balthisar.com or Jim Derry.

Binary distributions that completely remove all Balthisar branding and artwork
are perfectly acceptable, even if for sale. This is your right under the MIT
License. The MIT license does not extend to the Balthisar brands and artwork,
however.
