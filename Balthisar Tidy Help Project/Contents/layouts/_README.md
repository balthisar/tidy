About Layouts
=============

This directory contains layouts and templates for your Apple HelpBook
project. Adhering to the following conventions will make things very
easy for you.

Files
-----

None of these files become standalone HTML documents, and as such should have
a single `.erb` extension and should use HTML and embedded Ruby exclusively.

For organization, the convention is to name HTML containers with a `layout`
prefix and visual templates with a `template` prefix.

 - `layout.erb` - This is Middleman's default HTML5 template, and should be
   left alone as a fallback. Nothing in this project uses it.

 - `layout-apple_main.erb` - Apple's help landing page (the main page) is
   supposed to be an XHTML 1.0 Strict document, and every other help page
   is supposed to be HTML 4.01. Thus this unique layout contains the view
   template as well. If you follow convention and have icons named
   `icon_32x32@2x.png` and `icon_256x256@2x.png` in the shared folder,
   then the only thing you should have to change is the content in the
   innermost div.

 - `layout-html4.erb` - This is just an HTML 4.01 wrapper template and if you
   follow all of the conventions there's nothing you should have to change
   here.

 - `template-logo-large.erb` - This visual template has the same appearance as
   `layout-apple_main.erb`, and is suitable for other “main”-like pages. If
   you follow conventions you should only have to change the content of the
   first innermost div.

 - `template-logo-medium.erb`  and `template-logo-small.erb` are other
    additional visual templates. If you follow the image conventions there is
    no reason you should have to modify these templates.


“Absolute” Paths
----------------

When using Middleman's helpers, absolute paths will be converted to relative
paths during the build. Absolute paths are relative to the `Contents (source)`
directory and _not_ the filesystem root.

In general it’s _not_ recommended to use absolute paths unless you need assets
outside of Middleman's configuration. Middleman will automatically build the
correct path using only the asset name when you use its helpers, if the assets
are in the correct directories (e.g., images in `images`).

However you will use absolute paths to refer to items in the `shared` directory
since this it outside of Middleman's normal search scope. The view templates
use this approach, for example.