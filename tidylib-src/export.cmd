rm -R Makefile Makefile.vc6 include src console test
cvs -d :pserver:anonymous@cvs.tidy.sourceforge.net:/cvsroot/tidy login
cvs -d :pserver:anonymous@cvs.tidy.sourceforge.net:/cvsroot/tidy export -r TIDYLIB_0_1 -d d:\tidyexport Makefile Makefile.vc6 include src console test
cp \tidytag\MakeDLL.vc6 .
