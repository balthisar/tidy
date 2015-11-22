JSDTidyFramework Documentation
==============================

Description
-----------

`JSDTidyFramework` implements `JSDTidyModel` and W3C’s **libtidy** in a Cocoa- and UI-friendly manner. 


Copyright (summary)
-------------------

**JSDTidyFramework**  
by Jim Derry and balthisar.com  
Copyright ©2003-2015 Jim Derry and balthisar.com  
Released under the terms of the “MIT License,” below.

**libtidy**  
by Dave Raggett, Charles Reitzel, HTACG Contributors, et al  
Copyright © 2002-2014 World Wide Web Consortium  
Used under the terms of the “WC3 License,” below.



Introduction
------------

`JSDTidyModel` is a Cocoa wrapper for most of the functionality of `libtidy` <http://www.html-tidy.org>, the current incarnation of Dave Ragget’s original HTML Tidy program. `libtidy` is a pure-C library written for the most cross-platform availability possible.

Since Cocoa is decidely not cross-platform (meaning “outside of Cocoa” independent of hardware), no effort is made in this wrapper to maintain any such cross-functionality. Additionally, because of features unique to Cocoa, some parts of `libtidy` have been replaced by native Mac OS X routines (particularly file-encoding handling).


Usage
-----

JSDTidyModel defines the `JSDTidyModel` class, instances of which perform the functionality of libtidy. For the most part usage can be determined by browsing through the documentation and comments that are in the header file. Additionally, a good, real-world resource that indicates actual implementation can be seen by looking at the source code for Balthisar Tidy <http://www.balthisar.com/tidy>. Below, however, are some important notes that will greatly ease things for you as you try to use JSDTidyModel.


Options and Data Types
----------------------

In Tidy parlance, options are called the “configuration.” JSDTidyModel implements all of these as based on NSString, including values that are represented as numbers and booleans. This makes implementation as transparent as possible and avoids type mismatches, and makes especially easy the ability to process tidy options arbitrarily, i.e., without knowing which options are compiled in.


Character Encoding
------------------

The handling of character encoding in JSDTidyModel is admittedly the biggest weakness of previous JSDTidyModel and Balthisar Tidy releases. Both Cocoa and libtidy offer file-encoding transformations and both can handle files of various encodings.

It seems, however, that Mac OS is more capable than Tidy when it comes to the number of encoding formats available, as well as having the benefit of being built-in to the operating system. Because of this, JSDTidyModel will override all use of libtidy file encoding configuration options. Because file encoding can be quite complicated, it’s essential that you know how JSDTidyModel expects to handle file encoding.

The essence of this can best be described (such are my talents) with this thought excercise: You have file which happens to exist using `mac` encoding. Your JSDTidyModel is already configured such that it expects `latin1` text. You load the file into the JSDTidyModel as NSData, which is a binary copy of the file. JSDTidyModel then decodes this file as if it were `mac` encoded, and builds a UTF8 NSString called `originalText`.

Since the `originalText` changed (you just loaded a file causing it change), the UTF8 NSString `tidyText` is generated, too. The program copies the `originalText` into an NSTextView to be edited, and the user edits it. All this time, the program is keeping the `sourceText` in sync with the NSTextView, i.e., updating the `originalText`. The user, though, realizes the encoding is wrong, and changes the `JSDTidyModel` `input-encoding` to the proper `mac` type for this document. `JSDTidyModel` will then convert `originalText` from the UTF8 NSString back to latin1. Note that it's not really converting to latin1, since it was never latin1 in the first place, but merely reversing the bad conversion from latin1. JSDTidyModel will then convert from this reverted state to another Unicode NSString using the `mac` encoding. The only possible information loss will be whatever the user changed before setting the correct encoding.

Hence, our standard for internal data storage will be UTF8 NSString, which is internally Unicode encoded. Once we're in this Unicode format, we can freely change between formats with little effort.


* * * * *


The WC3 License
---------------
License

By obtaining, using and/or copying this work, you (the licensee) agree that you have read, understood, and will comply with the following terms and conditions.

Permission to copy, modify, and distribute this software and its documentation, with or without modification, for any purpose and without fee or royalty is hereby granted, provided that you include the following on ALL copies of the software and documentation or portions thereof, including modifications:

- The full text of this NOTICE in a location viewable to users of the redistributed or derivative work.
- Any pre-existing intellectual property disclaimers, notices, or terms and conditions. If none exist, the W3C Software Short Notice should be included (hypertext is preferred, text is permitted) within the body of any redistributed or derivative code.
- Notice of any changes or modifications to the files, including the date changes were made. (We recommend you provide URIs to the location from which the code is derived.)

Disclaimers

THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS," AND COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.

COPYRIGHT HOLDERS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF ANY USE OF THE SOFTWARE OR DOCUMENTATION.

The name and trademarks of copyright holders may NOT be used in advertising or publicity pertaining to the software without specific, written prior permission. Title to copyright in this software and any associated documentation will at all times remain with copyright holders.

Notes

This version: http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

This formulation of W3C's notice and license became active on December 31 2002. This version removes the copyright ownership notice such that this license can be used with materials other than those owned by the W3C, reflects that ERCIM is now a host of the W3C, includes references to this specific dated version of the license, and removes the ambiguous grant of "use". Otherwise, this version is the same as the previous version and is written so as to preserve the Free Software Foundation's assessment of GPL compatibility and OSI's certification under the Open Source Definition.


* * * * *


The MIT License (MIT)
---------------------

Copyright (c) <year> <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

