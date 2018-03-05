Balthisar Tidy
==============

by Jim Derry, <http://www.balthisar.com>
Copyright © 2003-2017 by Jim Derry. All rights reserved.
See “Legal Stuff” below for license details.


About
-----

Sweep Away your Poor HTML Clutter.

Use _Balthisar Tidy_ to make sure your HTML is clean, error free, and
accessible. Now with the latest builds from HTACG, _Balthisar Tidy_ surpasses
Mac OS X’s built-in, terminal version of this venerable tool.

- Supports every Mac OS X file encoding.
- Advanced text editor features.
- See a live preview of the effects each Tidy option has on your code.
- Identify errors and be directed to their exact location in your source code in
  an instant.
- Correct errors in the source document immediately.
- Identifies and automatically corrects several potential errors.
- Automatically cleans up ugly code from HTML generator applications.
- Identifies opportunities to ensure accessibility compliance.
- Pretty-print formats your source code for maximum legibility.


System Requirements
-------------------

_Balthisar Tidy_ has been released with support for macOS 10.10 and newer.


Change Log
----------

Please see the commit history.


Building From Source
--------------------

If you’re building from source, be aware that there are several build targets,
which collectively make up a single application. Although there’s a single
“Balthisar Tidy” build target, you can generate the different versions via the
different configurations.

Refer to How To Build, below, for important information.

### Configurations

- **Balthisar Tidy (web)** will build the version distributed on the 
  www.balthisar.com website, and will include support for Sparkle for 
  auto-updating.

- **Balthisar Tidy (app)** will be build the version distributed on Apple's App
  Store, and does not include anything remotely associated with Sparkle. It is
  otherwise identical with the `(web)` build.

- **Balthisar Tidy (pro)** will build the version distributed as “Balthisar Tidy
  for Work” on the App Store. Yes, this is the paid version that includes 
  AppleScript support and the ability to export Tidy configuration files, as 
  well as future, unspecified changes. If you want to build it yourself and 
  avoid paying for it in the App Store, you can!


### Additional Build Targets

The build targets above have dependencies on additional build targets. 
Dependencies will be built automatically when needed, such as when selecting
the application configuration to build.

- **Tidy Extension** and **TidyBody Extension** will build the action extension
  that _Balthisar Tidy_ makes available to apps that support extensions.

- **Balthisar Tidy Service Helper** will build the separate application that 
  handles Tidy as a system service. This helper application within the main 
  application bundle performs Tidying without the need for the main 
  _Balthisar Tidy_ application to open every time the service is invoked.

- **JSDTidyFramework** is used by most of the other targets, and is the
  interface to the LibTidy library.

- **libtidy-balthisar.dylib** will build a dynamic library that JSDTidyFramework
  will use. Although the implementation as a dylib helps reduce code redundancy
  within the bundle, the main reason for building as a dylib is to allow the 
  dynamic linker to use updated versions in ``/usr/local/lib``. This allows
  advanced users to upgrade _Balthisar Tidy_’s tidying engine in between
  _Balthisar Tidy_ releases.


### How to Build

If you try to build any of the targets immediately upon opening the project the
first time, the build _will_ fail. All versions of _Balthisar Tidy_ include 
System Services and Action Extensions, and this means that Apple _requires_ a
code signing identity and provisioning profile.

#### If you’re an Apple Developer
If you’re already an Apple Developer simply ensure that your developer Apple ID
is added to **Preferences** > **Accounts** in Xcode. Then for each build target,
in the **General** tab, **Identity** section, select your own team.

The first time you build Xcode will probably complain about provisioning 
profiles. Go ahead and use the **Fix** button to let Xcode make its changes.

At this point XCode will build any of the targets and you are all set.

#### If you’re _not_ an Apple Developer
If you’re not an Apple Developer then don’t worry. Starting with Xcode 7 Apple
supports free provisioning profiles associated with your Apple ID. This means 
that you do have to use Xcode 7 or newer, and have an Apple ID though.

The first step is to add your Apple ID to **Preferences** > **Accounts** in
Xcode, which should be straightforward enough. After completing this use the
**View Details…** button on the same screen. This will cause a sheet to open. 
In the upper pane (“Signing Identities”) use the **Create** button for “Mac 
Development” and then use the **Done** button. You can close **Preferences** 
now.

Next, for each build target, go to the **Build Settings** panel and look for 
the **Code Signing** section. Change the **Code Signing Identity** to “Mac 
Developer” for each target. Then for each target, verify that in the **General**
tab, **Identity** section, your own team is selected.

The first time you build Xcode will probably complain about provisioning 
profiles. Go ahead and use the **Fix** button to let Xcode make its changes.

At this point XCode will build any of the targets and you are all set.



Experimental Support for `/usr/local/lib/` versions of tidylib
--------------------------------------------------------------

Apple currently allows sandboxed apps to reference libraries (even unsigned) in
certain protected OS directories, including within `/usr/local/lib/`, which is
the traditional install location for Unix libraries.

_Balthisar Tidy_ is now built to to use a `libtidy-balthisar.dylib` instead of
the built-in library if one is found in `/usr/local/lib`. This means that if you
install the console version of HTML Tidy with a different `libtidy.dylib`, then
_Balthisar Tidy_ can use it. This can be useful in cases where HTML Tidy is
released at a faster pace than _Balthisar Tidy_, for example. Mac using HTML
Tidy developers can also quickly switch between HTML Tidy versions without
having to build _Balthisar Tidy_.

I suggest creating a symlink within `/usr/local/lib/` to the specific version of
tidylib that you want _Balthisar Tidy_ to use. For example:

`ln -sf /usr/local/lib/libtidy.5.1.9.dylib /usr/local/lib/libtidy-balthisar.dylib`

Because HTML Tidy installation scripts automatically create their own symlinks
to the most recently installed libtidy, you could also link to this generic
link, ensuring that _Balthisar Tidy_ will always use the most recently installed
library:

`ln -sf /usr/local/lib/libtidy.dylib /usr/local/lib/libtidy-balthisar.dylib`

_Balthisar Tidy_ will _not_ support simply using the already-present
`libtidy.dylib`. Apple's dynamic loader does not allow the application to choose
a specific version or installed location of a dynamic library, and so
namespacing in this way ensures that _Balthisar Tidy_ can always operate without
regard to the version of HTML Tidy that is installed.


Legal Stuff
-----------

### Open Source

_Balthisar Tidy_ and all of its source code (including third party source code)
have been released under free and open source licenses.

Refer to licenses in third party source code for rights and responsibilities
related to that source code.

All source code in this project copyrighted by Jim Derry is available to you
under license via the standard MIT License, reproduced below. Items that are not
source code, such as artwork and the name "Balthisar" and "Balthisar Tidy" are
not licensed for your private or public use and remain the property of Jim
Derry. See the Trademark and Artwork Policy, below.


The MIT License (MIT)
---------------------

Copyright (c) 2003 to 2015 Jim Derry <http://www.balthisar.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


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
