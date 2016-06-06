README
======

About the “Middlemac” Build System for Help
-------------------------------------------
This directory is the help project for _Balthisar Tidy_ series of applications.
Because of the differing build and feature configurations for _Balthisar Tidy_,
a more flexible build system for its help files is necessary, too. This is why
we developed _Middlemac_. 

If you're working on your own forks of _Balthisar Tidy_ and don’t wish to
depend on an external build system for help files, you can still modify the
built help files in the `Balthisar Tidy (xxx).help` bundles. On the other hand
if you wish to participate in the development of _Balthisar Tidy_ and issue pull
requests, please make changes to the source files in the build system in this
directory, in `Contents/`.

The build system strongly leverages [_Middleman_](http://middlemanapp.com/) and
is a well-known static website development tool that's available for all
platforms that can run Ruby. The template system depends on very basic Ruby
knowledge, but the learning curve is quite small. If you can develop
Objective-C, then you can very easily understand the small amount of Ruby that's
used.

_Middlemac_ builds on _Middleman_ to provide tools and configuration specific to
building Apple help files targeting different application versions.

The `.idea` folder is included in version control so that I can replicate my
editor development across machines. If you are using a JetBrains IDE to open
the project folder, then your editor will inherit my settings. Please make
sure that your pull requests do not include anything from this file (please
.gitignore it on your system).


Build Configurations
--------------------
In order to tailor the help file to each specific version of _Balthisar Tidy_
the there are multiple build configurations for Tidy help, too. This avoids,
for example, any mention of the Sparkle Update Framework for versions that
appear in the App Store, and avoids mention of features in the help files of
applications that don't have those features.

From within the help project directory in Terminal you can build any of the
help targets by using Middleman. For example: 

`bundle exec middleman build --target pro`


Build System Configuration
--------------------------
All configuration is performed in `config.rb`, although if you're contributing
to _Balthisar Tidy_ there should be no need for any changes here.


Dependencies
------------
Executing `bundle install` from the project directory should take care of any
dependencies.


Frontmatter Content
-------------------
Frontmatter in yaml format has the following meanings:

~~~~~~~~~~~~
---
title:  Page title
blurb:  A sentence or short paragraph that will be included in TOC's.
layout: Layout file to use.
order:  local sort order (if missing, won't be included in auto TOC's).
targets:
 - array of
 - targets, or
 - features that are true
exclude:
 - array
 - same as above, but will exclude items that equal yes.
 - exclude overrides targets. If something included then excluded, will be
   excluded.
---
~~~~~~~~~~~~


Examples of the targets array:

targets:
 - pro (equals web)
 - feature_sparkle (equals yes)
 - feature_exports_config (equals no)

This item will be included because all feature_sparkle is allowed.

targets:
 - pro (equals web)
 - features_sparkle (equals no)
 - feature_exports_config (equals no)

None of these is valid, so the item will be excluded.

exclude:
 - pro (equals web)
 - features_sparkle (equals no)

Nothing will be excluded, because we are currently web, and features_sparkle is
not yes.
