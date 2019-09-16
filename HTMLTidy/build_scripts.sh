#!/usr/bin/env bash

############################################################
# Building and Installation Scripts.
############################################################

#===================================================
# Build the prefix header, which we're using to
# set LibTidy's project version and date.
#===================================================
build_prefix_header()
{
    echo "Processing the date and version file to build a dynamic header."
    HEADER="${SRCROOT}/HTMLTidy/xcode-version.h"
    cd ${SRCROOT}
    echo "// This file is generated automatically. Do not edit. Edit version.txt instead." > $HEADER
    echo "// The libtidy-balthisar.dylib target Build Rules for *.txt files has produced this file." >> $HEADER
    echo "// Make sure you include this file as the libtidy-balthisar.dylib target prefix header." >> $HEADER

    IFS=$'\n' read -d '' -r -a LINES < "${INPUT_FILE_PATH}"

cat << EOF >> $HEADER
#ifdef LIBTIDY_VERSION
#undef LIBTIDY_VERSION
#endif
#ifdef RELEASE_DATE
#undef RELEASE_DATE
#endif
#ifdef PLATFORM_NAME
#undef PLATFORM_NAME
#endif
EOF

    echo "#define LIBTIDY_VERSION \"${LINES[0]}\"" >> $HEADER
    echo "#define RELEASE_DATE \"${LINES[1]}\"" >> $HEADER
    echo "#define PLATFORM_NAME \"Balthisar Tidy on macOS,\"" >> $HEADER

    echo "// Updated on "`date` >> $HEADER
}

COMMAND=$1
echo "Executing: ${COMMAND}"
${COMMAND}
