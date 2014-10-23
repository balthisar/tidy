About Scripting Tests and Tools
===============================

by Jim Derry, <http://www.balthisar.com>  
Copyright © 2014 by Jim Derry. All rights reserved.  
See “Legal Stuff” below for license details.  


About
-----

This folder contains a few sample AppleScripts for working with _Balthisar Tidy_.
They’re not intended for real-world production use, but they do describe how to
use _Balthisar Tidy_’s AppleScript options.

Each of the scripts is available in a few formats:

- .app to make it work directly from Finder.
- .scpt to make it load into your script editor first, from where it can be run.
- .applescript as a text file you can view it e.g. in github.


## `Sample Dirty Document (original).html` and `Sample Dirty Document.html`

Some of the scripts expect to find an HTML document named `Sample Dirty Document.html`
in the same folder location as the script, so it's a good idea to leave this file alone.

The `_Sample Dirty Document (original).html` isn’t used by any of the scripts, but
I leave it in this directory in case I accidentally overwrite the sample document.



The Scripts
-----------

### Balthisar Tidy Batch

You can run the applet directly to use a file chooser, or drop documents onto the
applet directly from Finder. You will be asked whether to Tidy in place (not
recommended!), or to select a destination folder. Chosen files will then be
Tidy’d via _Balthisar Tidy_ using all of the Tidy options set in the application
preferences, **including input-encoding** (make sure you know what you’re doing
with your file encodings).

This sample script only allows you to choose PHP and HTML files, but you can drop
any file type at all onto the script. Balthisar Tidy will try to process them regardless
of the contents. This might result in data loss if you drop a random text file, or might
cause _Balthisar Tidy_ to crash. Caveat emptor, this is a demonstration, etcetera, etcetera.


### Balthisar Tidy Tests

This script demonstrates _Balthisar Tidy_’s current AppleScript features as well as
demonstrates how to implement them.

It requires `Sample Dirty Document.html` to be present in the same directory as the script.


### Tidy Screenshots

This script uses _Balthisar Tidy_’s developer suite and also Mac OS X UI Scripting
features to take screen shots of a document window and each of the preferences window
panels.

It was a lot easier to write this AppleScript than to keep using _Grab_ to make screenshots
for the website and help documentation.

It requires `Sample Dirty Document.html` to be present in the same directory as the script.


### Tidy - Balthisar Tidy Folder Action

This is a sample Folder Action. If added to ~/Library/Scripts/Folder Action Scripts and
setup with a folder of your choice, then any file added to that folder will be Tidy’d
automatically.

Note that this is a proof of concept and there is no file type checking at all. Use with
care.



Legal Stuff
-----------

### Public Domain

All of the included AppleScripts are released into the public domain.

