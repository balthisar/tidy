# Makefile - for tidy - HTML parser and pretty printer
#
#  CVS Info :
#
#     $Author: creitzel $ 
#     $Date: 2002/10/20 19:00:17 $ 
#     $Revision: 1.9.2.5 $ 
#
#  Copyright (c) 1998-2002 World Wide Web Consortium
#  (Massachusetts Institute of Technology, Institut National de
#  Recherche en Informatique et en Automatique, Keio University).
#  All Rights Reserved.
#
#  Contributing Author(s):
#
#     Dave Raggett <dsr@w3.org>
#     Terry Teague <terry_teague@users.sourceforge.net>
#     Pradeep Padala<ppadala@users.sourceforge.net>
#
#  The contributing author(s) would like to thank all those who
#  helped with testing, bug fixes, and patience.  This wouldn't
#  have been possible without all of you.
#
#  COPYRIGHT NOTICE:
#
#  This software and documentation is provided "as is," and
#  the copyright holders and contributing author(s) make no
#  representations or warranties, express or implied, including
#  but not limited to, warranties of merchantability or fitness
#  for any particular purpose or that the use of the software or
#  documentation will not infringe any third party patents,
#  copyrights, trademarks or other rights. 
#
#  The copyright holders and contributing author(s) will not be
#  liable for any direct, indirect, special or consequential damages
#  arising out of any use of the software or documentation, even if
#  advised of the possibility of such damage.
#
#  Permission is hereby granted to use, copy, modify, and distribute
#  this source code, or portions hereof, documentation and executables,
#  for any purpose, without fee, subject to the following restrictions:
#
#  1. The origin of this source code must not be misrepresented.
#  2. Altered versions must be plainly marked as such and must
#     not be misrepresented as being the original source.
#  3. This Copyright notice may not be removed or altered from any
#     source or altered source distribution.
# 
#  The copyright holders and contributing author(s) specifically
#  permit, without fee, and encourage the use of this source code
#  as a component for supporting the Hypertext Markup Language in
#  commercial products. If you use this source code in a product,
#  acknowledgment is not required but would be appreciated.
#

SHELL=/bin/sh

# Installation variables.  Spaces OK, only dir create and file copy operations.
runinst_prefix=/usr
devinst_prefix=/usr

bininst = ${runinst_prefix}/bin
libinst = ${devinst_prefix}/lib
incinst = ${devinst_prefix}/include
maninst = ${devinst_prefix}/man

# Internal variables. - No spaces allowed: libtool chokes on spaces in directory names.
TOPDIR = .
INCDIR = ${TOPDIR}/include
APPDIR = ${TOPDIR}/console
SRCDIR = ${TOPDIR}/src
OBJDIR = ${TOPDIR}/obj
LIBDIR = ${TOPDIR}/lib
BINDIR = ${TOPDIR}/bin

# CFLAGS etc..
CC= gcc
CFLAGS= -Wall -Wno-switch -Wno-parentheses -Wno-unused -I $(INCDIR)
OTHERCFLAGS= -DSUPPORT_ACCESSIBILITY_CHECKS=1 -DSUPPORT_UTF16_ENCODINGS=1 -DSUPPORT_ASIAN_ENCODINGS=1
DEBUGFLAGS=-g -DDMALLOC

LIBS=-lc
DEBUGLIBS=-ldmalloc

# Tidy lib related variables
TIDY_MAJOR = 1
TIDY_MINOR = 0

# This will come from autoconf again
LIBPREFIX = lib
LIBSUFFIX = .a

LIBRARY = $(LIBDIR)/$(LIBPREFIX)tidy$(LIBSUFFIX)
LIBTOOL=libtool

EXES = $(BINDIR)/tidy $(BINDIR)/tab2space

OBJFILES=\
        $(OBJDIR)/access.o     $(OBJDIR)/attrs.o      $(OBJDIR)/istack.o\
        $(OBJDIR)/parser.o     $(OBJDIR)/tags.o       $(OBJDIR)/entities.o\
        $(OBJDIR)/lexer.o      $(OBJDIR)/pprint.o     $(OBJDIR)/clean.o\
        $(OBJDIR)/localize.o   $(OBJDIR)/config.o     $(OBJDIR)/alloc.o\
        $(OBJDIR)/attrask.o    $(OBJDIR)/attrget.o    $(OBJDIR)/buffio.o\
        $(OBJDIR)/fileio.o     $(OBJDIR)/streamio.o   $(OBJDIR)/tagask.o\
        $(OBJDIR)/tmbstr.o     $(OBJDIR)/utf8.o\
        $(OBJDIR)/tidylib.o

CFILES= \
        $(SRCDIR)/access.c       $(SRCDIR)/attrs.c        $(SRCDIR)/istack.c \
        $(SRCDIR)/parser.c       $(SRCDIR)/tags.c         $(SRCDIR)/entities.c \
        $(SRCDIR)/lexer.c        $(SRCDIR)/pprint.c       $(SRCDIR)/clean.c \
        $(SRCDIR)/localize.c     $(SRCDIR)/config.c       $(SRCDIR)/alloc.c \
        $(SRCDIR)/attrask.c      $(SRCDIR)/attrget.c      $(SRCDIR)/buffio.c \
        $(SRCDIR)/fileio.c       $(SRCDIR)/streamio.c     $(SRCDIR)/tagask.c \
        $(SRCDIR)/tagget.c       $(SRCDIR)/tmbstr.c       $(SRCDIR)/utf8.c \
        $(SRCDIR)/tidylib.c

HFILES= $(INCDIR)/platform.h     $(INCDIR)/tidy.h         $(INCDIR)/tidyenum.h \
        $(INCDIR)/fileio.h       $(INCDIR)/buffio.h       

LIBHFILES= \
        $(SRCDIR)/access.h \
        $(SRCDIR)/attrs.h        $(SRCDIR)/clean.h \
        $(SRCDIR)/config.h       $(SRCDIR)/entities.h \
        $(SRCDIR)/forward.h      $(SRCDIR)/lexer.h        $(SRCDIR)/message.h \
        $(SRCDIR)/parser.h       $(SRCDIR)/pprint.h       $(SRCDIR)/streamio.h \
        $(SRCDIR)/tags.h \
        $(SRCDIR)/tmbstr.h       $(SRCDIR)/utf8.h         $(SRCDIR)/tidy-int.h



all:    $(LIBRARY) $(EXES)

$(LIBRARY): $(OBJFILES)
	if [ ! -d $(LIBDIR) ]; then mkdir $(LIBDIR); fi
	$(LIBTOOL) $(CC) -o $@ $(OBJFILES)

$(OBJDIR)/%.o:		$(SRCDIR)/%.c $(HFILES) $(LIBHFILES) Makefile
	if [ ! -d $(OBJDIR) ]; then mkdir $(OBJDIR); fi
	$(LIBTOOL) $(CC) -o $@ -c $(CFLAGS) $(OTHERCFLAGS) $<

$(BINDIR)/tidy:	$(APPDIR)/tidy.c $(HFILES) $(LIBRARY)
	if [ ! -d $(BINDIR) ]; then mkdir $(BINDIR); fi
	$(CC) $(CFLAGS) $(OTHERCFLAGS) -o $@ $(APPDIR)/tidy.c -I$(INCDIR) -L$(LIBDIR) -ltidy

$(BINDIR)/tab2space: $(APPDIR)/tab2space.c
	if [ ! -d $(BINDIR) ]; then mkdir $(BINDIR); fi
	$(CC) $(CFLAGS) $(OTHERCFLAGS) -o $@ $(APPDIR)/tab2space.c $(LIBS)

debug:
	@$(MAKE) CFLAGS='$(CFLAGS) $(DEBUGFLAGS)' LIBS='$(LIBS) $(DEBUGLIBS)' all

clean:
	rm -f $(OBJFILES) $(EXES) $(LIBRARY) $(OBJDIR)/*.lo
	if [ -d $(OBJDIR)/.libs ]; then rmdir $(OBJDIR)/.libs; fi
	if [ "$(OBJDIR)" != "$(TOPDIR)" -a -d $(OBJDIR) ]; then rmdir $(OBJDIR); fi
	if [ "$(LIBDIR)" != "$(TOPDIR)" -a -d $(LIBDIR) ]; then rmdir $(LIBDIR); fi
	if [ "$(BINDIR)" != "$(TOPDIR)" -a -d $(BINDIR) ]; then rmdir $(BINDIR); fi

installhdrs: $(HFILES)
	if [ ! -d "$(incinst)" ]; then mkdir -p "$(incinst)"; fi
	cp -f $(HFILES) "$(incinst)/"

installib: $(LIBRARY)
	if [ ! -d "$(libinst)" ]; then mkdir -p "$(libinst)"; fi
	cp -f $(LIBRARY) "$(libinst)/"

installexes: $(EXES)
	if [ ! -d "$(bininst)" ]; then mkdir -p "$(bininst)"; fi
	cp -f $(EXES) "$(bininst)/"

installmanpage:
	if [ -f "man_page.txt" ] ; then \
    	if [ ! -d "$(maninst)/man1" ]; then mkdir -p "$(maninst)/man1"; fi; \
    	cp -f man_page.txt "$(maninst)/man1/tidy.1"; \
	fi
   
install: installhdrs installib installmanpage installexes
