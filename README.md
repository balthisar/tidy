Balthisar Tidy
==============

by Jim Derry, <http://www.balthisar.com>
Copyright © 2003-2015 by Jim Derry. All rights reserved.
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

### Balthisar Tidy 2.2.1 (October 2015)

- Bug Fixes
    - Updated Apple Transport Security settings so that _Balthisar Tidy_ web version
      can check for updates.

- Changes developers will notice
    - README updated with information about building the project.
	- Header and implementation documentation improved.
	- Updated bundled binaries' bundle versions to match the containing application,
	  as the App Store verification process now flags differences.

### Balthisar Tidy 2.2.0 (October 2015)

- New Features
    - New built-in version of Tidy. Now uses HTACG HTML Tidy 5.1.9.
    - Balthisar Tidy will automatically use `/usr/local/lib/libtidy-balthisar.dylib`
      instead of the built-in version (if present).
    - New System Service and Extension can selectively Tidy text without producing a full
      document. As a result the existing System Service and Extension will _always_
      produce a full document, ignoring _Balthisar Tidy_’s `show-body-only` setting.

- Visible Changes
    - Fixed the horrible appearance in the Tidy options panel introduced in 
      Mac OS X 10.11 El Capitan.

- Bug Fixes
    - Fixed a condition in which the messages table would not be updated in certain
      circumstances.
    - Print now works again. We overlooked a sandbox permissions setting, which previously
      caused users who tried to print to see a message indicating that _Balthisar Tidy_
      didn't have permission.
      
- Other Changes
    - Significantly reduced file size by using PDF instead of icns for the messages table
      images.


### Balthisar Tidy 2.1.3 (January 2015)

- New Features
    - Added system service "Tidy selection in new Balthisar Tidy document" (Mac OS X 10.8 and above)
    - Added system service "Tidy selection using Balthisar Tidy" (Mac OS X 10.9 and above)
    - Added Action Extension "Balthisar Tidy" (Mac OS X 10.10+ only)

- Visible Changes
    - Updated Tidy Options list to assume default Yosemite appearance.
    - Updated support contact information in About… and in Help.
    - Fixed a view updating bug when used via external sources such as AppleScript. In some cases when setting a document's source text with `.sourceText` via AppleScript the Tidy'd text would not update.
    - Fixed reversion wherein the Preference for showing/hiding the Tidy and Options panes preferences weren't honored.
    - Fixed reversion wherein is wasn't always possible to show/hide the description text in the Tidy Options panel.
    - New help content to support new features.
    - Updated help images to Yosemite images.

- Additional Release Notes
    - Services — To enable the new services you may have to logoff your user account and login again (this is a Mac OS X restriction). The services will then be available in most apps after enabling them in System Preferences > Keyboard > Shortcuts > Services in the Text group.
    - Action Extension — To enable the new extension run the updated Balthisar Tidy one time. Then enable the extension in System Preference > Extensions > Balthisar Tidy > Actions check box.


### Balthisar Tidy 2.0.3 (November 2014)

- New Features
    - You can drag contents of files into the source HTML Panel.
        - On Mac OS X 10.10 and above, Mac OS X will attempt to decode the input encoding, even if the
          file is a bitmap. Non-readable files (e.g., folders) will paste the filename.
        - On Mac OS X 10.9 and below, only UTF files will allow their contents to be dragged in, otherwise
          the filename will be pasted.
- Visible changes
    - Version change to 2.0.3.
    - Contact information added to help file.
    - Contact information added to About… box.
    - Fixed instructions in help for deleting preferences.
    - Word-wrap in non-vertical layout fixed.
    - New version of Tidylib
        - New base source
        - Aria attributes corrected.
        - Role attribute corrected.
        - Itemscope series of microdata support added.
    - Properly deal with legacy line endings. This previously could cause a problem where closing body and
      html tags were missing.
    - Properly respect `newline` setting upon saving files.
    - Run-in meta tags in head section fixed.
    - Fixed Encoding helper logic so it only offers help when opening file.
    - Not properly updating the error table when opening a file. This was infamously seen as
      `adding missing title tag`.
- Changes developers will notice
    - Added a non-signed dev target to the Xcode project.
    - Updated to latest versions of third party libraries such as Sparkle.


### Balthisar Tidy 2.0.1 (October 2014)
- Visible Changes
    - Changed the appearance of the Quick Tutorial for better appearance in Yosemite.
    - Fixed several typographic errors in the help file.
    - Reorganized the help content slightly.
    - Added a table of contents to the Reference section of the help file.
    - Added breadcrumbs to the help file.
- Changes developers will notice
    - Updated project files to XCode6.
    - Compiled against the Mac OS X 10.10 (Yosemite SDK).
    - Improved the help build system considerably (introducing Middlemac).


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
- Tweaked other preferences’ layouts for better usability and to support Cocoa bindings
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
- Some migration to modern Objective-C style
- Patched some memory leaks
- Removed all deprecated calls
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

If you’re building from source, be aware that there are three different build targets:

    - Balthisar Tidy (web)
    - Balthisar Tidy (app)
    - Balthisar Tidy (pro)

Refer to How To Build, below, for important information.

### Main Build Targets

- **Balthisar Tidy (web)** will build the version distributed on the www.balthisar.com 
  website, and will include support for Sparkle for auto-updating.

- **Balthisar Tidy (app)** will be build the version distributed on Apple's App Store, and
  does not include anything remotely associated with Sparkle. It is otherwise identical
  with the `(web)` build.

- **Balthisar Tidy (pro)** will build the version distributed as “Balthisar Tidy for Work”
  on the App Store. Yes, this is the paid version that includes AppleScript support and
  the ability to export Tidy configuration files, as well as future, unspecified changes.
  If you want to build it yourself and avoid paying for it in the App Store, you can! 
  
  
### Additional Build Targets

The build targets above have dependencies on additional build targets. Dependencies will
be built automatically when needed.

- **Balthisar Tidy Extension (web/app/pro)** will build the action extension that _Balthisar Tidy_ makes
  available to apps that support extensions. Each target builds identical code; the primary difference is
  related to the requirement that extension bundle identifiers must match the host application.
  
- **Balthisar Tidy Service Helper** will build the separate application that handles Tidy as a system
  service. This helper application within the main application bundle performs Tidying without the
  need for the main _Balthisar Tidy_ application to open every time the service is invoked.
  
- **JSDTidyFramework** is used by most of the other targets. Many of the target types are restricted by
  security protocols that prohibit dynamic binding meaning that this dependency is statically linked in
  many of the modules. However it is allowed to use dynamically linked libraries.

- **libtidy-balthisar.dylib** will build a dynamic library that JSDTidyFramework will use. Although the
  implementation as a dylib helps reduce code redundancy within the bundle, the main reason for building
  as a dylib is to allow the dynamic linker to use updated versions in /usr/local/lib. This allows
  advanced users to upgrade _Balthisar Tidy_’s tidying engine in between _Balthisar Tidy_ releases.


### How to Build

If you try to build any of the targets immediately upon opening the project the first
time, the build _will_ fail. All versions of _Balthisar Tidy_ include System Services and
Action Extensions, and this means that Apple _requires_ a code signing identity and
provisioning profile.

#### If you’re an Apple Developer
If you’re already an Apple Developer simply ensure that your developer Apple ID is added
to **Preferences** > **Accounts** in Xcode. Then for each build target, in the
**General** tab, **Identity** section, select your own team. 

The first time you build Xcode will probably complain about provisioning profiles. Go
ahead and use the **Fix** button to let Xcode make its changes. 

At this point XCode will build any of the targets and you are all set.

#### If you’re _not_ an Apple Developer
If you’re not an Apple Developer then don’t worry. Starting with Xcode 7 Apple supports
free provisioning profiles associated with your Apple ID. This means that you do have to
use Xcode 7 or newer, and have an Apple ID though.

The first step is to add your Apple ID to **Preferences** > **Accounts** in Xcode, which
should be straightforward enough. After completing this use the **View Details…** button
on the same screen. This will cause a sheet to open. In the upper pane 
(“Signing Identities”) use the **Create** button for “Mac Development” and then use the
**Done** button. You can close **Preferences** now.

Next, for each build target, go to the **Build Settings** panel and look for the **Code
Signing** section. Change the **Code Signing Identity** to “Mac Developer” for each
target. Then for each target, verify that in the **General** tab, **Identity** section, 
your own team is selected.

The first time you build Xcode will probably complain about provisioning profiles. Go
ahead and use the **Fix** button to let Xcode make its changes. 

At this point XCode will build any of the targets and you are all set.



Experimental Support for `/usr/local/lib/` versions of tidylib
--------------------------------------------------------------

Apple currently allows sandboxed apps to reference libraries (even unsigned) in certain
protected OS directories, including within `/usr/local/lib/`, which is the traditional
install location for Unix libraries.

_Balthisar Tidy_ is now built to to use a `libtidy-balthisar.dylib` instead of the
built-in library if one is found in `/usr/local/lib`. This means that if you install
the console version of HTML Tidy with a different `libtidy.dylib`, then _Balthisar Tidy_
can use it. This can be useful in cases where HTML Tidy is released at a faster pace than
_Balthisar Tidy_, for example. Mac using HTML Tidy developers can also quickly switch
between HTML Tidy versions without having to build _Balthisar Tidy_.

I suggest creating a symlink within `/usr/local/lib/` to the specific version of tidylib
that you want _Balthisar Tidy_ to use. For example:

`ln -sf /usr/local/lib/libtidy.5.1.9.dylib /usr/local/lib/libtidy-balthisar.dylib`

Because HTML Tidy installation scripts automatically create their own symlinks to the
most recently installed libtidy, you could also link to this generic link, ensuring that
_Balthisar Tidy_ will always use the most recently installed library:

`ln -sf /usr/local/lib/libtidy.dylib /usr/local/lib/libtidy-balthisar.dylib`

_Balthisar Tidy_ will _not_ support simply using the already-present `libtidy.dylib`.
Apple's dynamic loader does not allow the application to choose a specific version or
installed location of a dynamic library, and so namespacing in this way ensures that
_Balthisar Tidy_ can always operate without regard to the version of HTML Tidy that is
installed.


Legal Stuff
-----------

### Open Source

_Balthisar Tidy_ and all of its source code (including third party source code) have been
released under free and open source licenses.

Refer to licenses in third party source code for rights and responsibilities related to
that source code.

All source code in this project copyrighted by Jim Derry is available to you under license
via the standard MIT License, reproduced below. Items that are not source code, such as
artwork and the name "Balthisar" and "Balthisar Tidy" are not licensed for your private
or public use and remain the property of Jim Derry. See the Trademark and Artwork Policy,
below.


The MIT License (MIT)
---------------------

Copyright (c) 2003 to 2015 Jim Derry <http://www.balthisar.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


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

The entirety of _Balthisar Tidy_ is Copyright ©2003-2015 by Jim Derry. The
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
