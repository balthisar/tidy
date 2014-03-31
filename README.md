Balthisar Tidy (version 1.1.0)
==============================

by Jim Derry, <http://www.balthisar.com>
Copyright © 2003-2014 by James S. Derry. All rights reserved.
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

If you’re building from source, be aware that there are now two (2) different build targets setup:

	- Balthisar Tidy
	- Balthisar Tidy (no sparkle)

_You should always make sure that you are using the `Balthisar Tidy (no sparkle)` build!_

### Brief Explanation of the no sparkle target

Sparkle is popular application update framework, but it requires code signing to work properly, which requires an Apple Mac OS X developer signature. Although I have a developer signature, I won’t assume that you have a developer signature, and so the `Balthisar Tidy (no sparkle)` target was added for all source builders’ convenience.

Note that both targets use the same resources, plists, and produce identical product names, and have identical bundle ID's. This is by design.


Legal Stuff
-----------

### Open Source

_Balthisar Tidy_ and all of its source code (including third party libraries) have been released under the MIT license.

### The MIT License (MIT)

by Jim Derry, <http://www.balthisar.com>
Copyright © 2003-2013 by Jim Derry. All rights reserved.

*All files in this project are released according to the MIT license.*

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
