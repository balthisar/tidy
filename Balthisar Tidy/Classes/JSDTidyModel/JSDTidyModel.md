JSDTidyModel Documentation
=============================
(a Cocoa wrapper for TidyLib)
-------------------------------

©2003-2014 by James S. Derry and balthisar.com

Portions Copyright ©1998-2003 World Wide Web Consortium (Massachusetts Institute of Technology, Institut National de Recherche en Informatique et en Automatique, Keio University). All Rights Reserved.


Introduction
------------

`JSDTidyModel` is a Cocoa wrapper for most of the functionality of TidyLib <http://tidy.sf.net>, the current incarnation of Dave Ragget’s original HTML Tidy program. TidyLib is a pure-C library written for the most cross-platform availability possible.

Since Cocoa is decidely not cross-platform (meaning “outside of Cocoa” independent of hardware), no effort is made in this wrapper to maintain any such cross-functionality. Additionally, because of features unique to Cocoa, some parts of TidyLib have been replaced by native Mac OS X routines (particularly file-encoding handling).

Usage
-----

JSDTidyModel defines the `JSDTidyModel` class, instances of which perform the functionality of TidyLib. For the most part usage can be determined by browsing through the documentation and comments that are in the header file. Additionally, a good, real-world resource that indicates actual implementation can be seen by looking at the source code for Balthisar Tidy <http://www.balthisar.com/tidy>. Below, however, are some important notes that will greatly ease things for you as you try to use JSDTidyModel.

Upgrading TidyLib
------------------

As much as possible I've tried to use only public interfaces into TidyLib. Therefore you should be able to get the latest version of TidyLib and successfully compile it against JSDTidyModel.

Options and Data Types
----------------------

In Tidy parlance, options are called the “configuration.” JSDTidyModel implements all of these as based on NSString, including values that are represented as numbers and booleans. This makes implementation as transparent as possible and avoids type mismatches, and makes especially easy the ability to process tidy options arbitrarily, i.e., without knowing which options are compiled in.

Character Encoding
------------------

The handling of character encoding in JSDTidyModel is admittedly the biggest weakness of previous JSDTidyModel and Balthisar Tidy releases. Both Cocoa and TidyLib offer file-encoding transformations and both can handle files of various encodings.

It seems, however, that Mac OS is more capable than Tidy when it comes to the number of encoding formats available, as well as having the benefit of being built-in to the operating system. Because of this, JSDTidyModel will override all use of TidyLib file encoding configuration options. Because file encoding can be quite complicated, it’s essential that you know how JSDTidyModel expects to handle file encoding.

The essence of this can best be described (such are my talents) with this thought excercise: You have file which happens to exist using `mac` encoding. Your JSDTidyModel is already configured such that it expects `latin1` text. You load the file into the JSDTidyModel as NSData, which is a binary copy of the file. JSDTidyModel then decodes this file as if it were `mac` encoded, and builds a UTF8 NSString called `originalText`.

Since the `originalText` changed (you just loaded a file causing it change), the UTF8 NSString `tidyText` is generated, too. The program copies the `originalText` into an NSTextView to be edited, and the user edits it. All this time, the program is keeping the `sourceText` in sync with the NSTextView, i.e., updating the `originalText`. The user, though, realizes the encoding is wrong, and changes the `JSDTidyModel` `input-encoding` to the proper `mac` type for this document. `JSDTidyModel` will then convert `originalText` from the UTF8 NSString back to latin1. Note that it's not really converting to latin1, since it was never latin1 in the first place, but merely reversing the bad conversion from latin1. JSDTidyModel will then convert from this reverted state to another Unicode NSString using the `mac` encoding. The only possible information loss will be whatever the user changed before setting the correct encoding.

Hence, our standard for internal data storage will be UTF8 NSString, which is internally Unicode encoded. Once we're in this Unicode format, we can freely change between formats with little effort.
