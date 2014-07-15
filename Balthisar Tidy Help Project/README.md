README
======

About the Build System for Help
-------------------------------
This directory is the help project for _Balthisar Tidy_ series of applications.
Because of the differing build and feature configurations for _Balthisar Tidy_,
a more flexible build system for its help files is necessary, too.

If you're working on your own forks of _Balthisar Tidy_ and don’t wish to
depend on an external build system for help file, you can still modify the
built help files in the `Balthisar Tidy.help` bundles. On the other hand if you
wish to participate in the development of _Balthisar Tidy_ and issue pull
requests, please make changes to the source files in the build system in this
directory, in `source`.

The build system is [middleman](http://middlemanapp.com/) and is a well-known
static website development tool that's available for all platforms that can
run Ruby. The templating system depends on very basic Ruby knowledge, but the
learning curve is quite small.

The `.idea` folder is included in version control so that I can replicate my
editor development across machines. If you are using a JetBrains IDE to open
the project folder, then your editor will inherit my settings. Please make
sure that your pull requests do not include anything from this file (please
.gitignore it on your system).


Build Configurations
--------------------
In order to tailor the help file to each specific version of Balthisar Tidy
the there are multiple build configurations for Tidy help, too. This avoids,
for example, any mention of the Sparkle Update Framework for versions that
appear in the App Store.

`middleman build` will build the “pro” target by default. Because middleman
won't accept CLI parameters, we have to pass targets to it in an environment
variable, e.g.,

`HBTARGET=pro middleman build`

Current valid targets are
 - web
 - app
 - pro


Editing the Title Page / Landing Page
-------------------------------------
Note that the standard Apple Help Book “title page” content should only be
edited in `_title_page.md.erb`, and if you want to set the page title, you
should modify `layouts/layout-apple_main.erb`. Apple Help requires that the
main title page be and XHTML file, while the remaining files are HTML 4.0.1
(this the purpose of having two layout files).

Additionally, by modifying only `_title_page.html.md.erb`, the build system can
properly manage the name of the file for the title page (it just makes a
duplicate of `_title_page.html.md.erb`).


Dependencies
------------
Executing `bundle install` from the project directory should take care of any
dependencies.


Front Matter Content
--------------------

---

title: Page title
blurb: A sentence or short paragraph that will be included in TOC's.
layout: layout to use
order: local sort order (if missing, won't be included)
targets:
 - array of
 - targets, or
 - features that are true
exclude:
 - array
 - same as above, but will exclude items that equal yes.
 - exclude overrides targets. If something included then excluded, will be excluded.
---


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

Nothing will be excluded, because we are currently web, and features_sparkle is not yes.
