JSDTidyDocument Documentation
=============================
(a Cocoa wrapper for TidyLib)
-------------------------------

_©2003-2013 by James S. Derry and balthisar.com_

_Portions Copyright ©1998-2003 World Wide Web Consortium (Massachusetts Institute of Technology, Institut National de Recherche en Informatique et en Automatique, Keio University). All Rights Reserved._


Introduction
------------

`JSDTidyDocument` is a Cocoa wrapper for most of the functionality of TidyLib <http://tidy.sf.net>, the current incarnation of Dave Ragget’s original HTML Tidy program. TidyLib is a pure-C library written for the most cross-platform availability possible.

Since Cocoa is decidely not cross-platform (meaning “outside of Cocoa” independent of hardware), no effort is made in this wrapper to maintain any such cross-functionality. Additionally, because of features unique to Cocoa, some parts of TidyLib have been replaced by native Mac OS X routines (particularly file-encoding handling).

Usage
-----

JSDTidyDocument defines the `JSDTidyDocument` class, instances of which perform the functionality of TidyLib. For the most part usage can be determined by browsing through the documentation and comments that are in the header file. Additionally, a good, real-world resource that indicates actual implementation can be seen by looking at the source code for Balthisar Tidy <http://www.balthisar.com/tidy>. Below, however, are some important notes that will greatly ease things for you as you try to use JSDTidyDocument.

Upgrading TidyLib
------------------

As much as possible I've tried to use only public interfaces into TidyLib. Therefore you should be able to get the latest version of TidyLib and successfully compile it against JSDTidyDocument.
        
Options and Data Types
----------------------

In Tidy parlance, options are called the “configuration.” JSDTidyDocument implements all of these as based on NSString, including values that are represented as numbers and booleans. This makes implementation as transparent as possible and avoids type mismatches, and makes especially easy the ability to process tidy options arbitrarily, i.e., without knowing which options are compiled in.

Options and Auto-Fixing
-----------------------

After a TidyDocument in TidyLib has processed itself (that is, the document has been Tidy’d), it “fixes” the configuration settings, and doesn’t leave tham at the desired setting. For example, if you set `text-indent` to `5`, and set `indent` to `no`, TidyLib will automatically reset `text-indent` to `0` after Tidy’ing the document.

This behavior isn't a very pretty sight from user interface perspective. Therefore when managing Tidying preferences with an instance of JSDTidyDocument, it’s recommend that this instance be used exclusively for managing preferences and that it never actually Tidy anything. This will ensure that the configuration values don’t seem to randomly change for your user. You can then use optionCopyFromDocument to get the configuration options from your configuration instance into the instance that will actually do the Tidy’ing.

Character Encoding
------------------

The handling of character encoding in JSDTidyDocument is admittedly the biggest weakness of previous JSDTidyDocument and Balthisar Tidy releases. Both Cocoa and TidyLib offer file-encoding transformations and both can handle files of various encodings.

It seems, however, that Mac OS is more capable than Tidy when it comes to the number of encoding formats available, as well as having the benefit of being built-in to the operating system. Because of this, JSDTidyDocument will override all use of TidyLib file encoding configuration options. Because file encoding can be quite complicated, it’s essential that you know how JSDTidyDocument expects to handle file encoding.

The essence of this can best be described (such are my talents) with this thought excercise: You have file which happens to exist using `mac` encoding. Your JSDTidyDocument is already configured such that it expects `latin1` text. You load the file into the JSDTidyDocument as NSData, which is a binary copy of the file. JSDTidyDocument then decodes this file as if it were `mac` encoded, and builds a UTF8 NSString called `originalText`.

Since the `originalText` changed (you just loaded a file causing it change), the UTF8 NSString `tidyText` is generated, too. The program copies the `originalText` into an NSTextView to be edited, and the user edits it. All this time, the program is keeping the `sourceText` in sync with the NSTextView, i.e., updating the `originalText`. The user, though, realizes the encoding is wrong, and changes the `JSDTidyDocument` `input-encoding` to the proper `mac` type for this document. `JSDTidyDocument` will then convert `originalText` from the UTF8 NSString back to latin1. Note that it's not really converting to latin1, since it was never latin1 in the first place, but merely reversing the bad conversion from latin1. JSDTidyDocument will then convert from this reverted state to another Unicode NSString using the `mac` encoding. The only possible information loss will be whatever the user changed before setting the correct encoding.

Hence, our standard for internal data storage will be UTF8 NSString, which is internally Unicode encoded. Once we're in this Unicode format, we can freely change between formats with little effort.
