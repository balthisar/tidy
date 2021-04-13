#!/usr/bin/env bash

############################################################
# Building and Installation Scripts for building
# JSDNuVFramework from source, so that we don't have to
# keep large binaries in version control.
#
# We must do things in a certain order:
# - The JAR has to be built first, because we need its
#   version number in order to build the C header that
#   contains version information. We can't sign it yet,
#   because it will no longer work in the shell if signed.
# - We need to build the C header next, so that we can
#   compile the framework code.
# - Next we can do normal Xcode build stuff.
# - Build the JRE in place, and sign it.
# - Move the JAR into place, and sign it.
############################################################

#---------------------------------------------------
# Common variables
#---------------------------------------------------
export JAVA_HOME=$(/usr/libexec/java_home)
JAVA_PLUGIN="${BUILT_PRODUCTS_DIR}/${PLUGINS_FOLDER_PATH}/Java.bundle"
F_ENTITLEMENTS="${SRCROOT}/JSDNuVFramework/java.entitlements"

#===================================================
# Satisfy Prerequisites, to make sure we have a JDK
# installed and is of a relatively recent vintage.
#===================================================
satisfy_prerequisites()
{
    # Ensure that Java is installed and version.
    if [ -z $(command -v "/usr/libexec/java_home") ]; then
        echo "error: Java is NOT installed, and is required in order to build the JAR."
        exit 1
    fi

    JAVA_VERSION=$("${JAVA_HOME}/bin/java" -version 2>&1 | awk -F '"' '/version/ {print $2}')

    echo "JAVA_HOME: ${JAVA_HOME}"
    echo "     JAVA: ${JAVA_HOME}/bin/java"
    echo "  Version: ${JAVA_VERSION}"

    if [[ "$JAVA_VERSION" < "10.0" ]]; then
        echo "error: Only Java 10.0+ and above should be used to build this framework."
        exit 1
    fi
}


#===================================================
# Build the JAR. We can't sign it yet because we
# have to use it from the shell later to get its
# version number. We will build into the directory
# BUILT_PRODUCTS_DIR and use it as a flag for
# whether or not we build.
#===================================================
build_jar()
{
    P_INTRM="${SRCROOT}/JSDNuVFramework/validator/build/dist/vnu.jar"
    P_BUILD="${BUILT_PRODUCTS_DIR}/vnu.jar"

    if [ -f "${P_BUILD}" ]; then
        echo "note: The JAR is already built, and no further action will be performed."
        exit
    fi

    # (In case you have proxy settings in your .zshenv.)
    source "${HOME}/.zshenv"

    cd "${SRCROOT}/JSDNuVFramework/validator"

    git submodule init
    git submodule update

    python ./checker.py dldeps
    if [ $? -ne 0 ]; then
        echo "error: Dependencies could not be downloaded. Check the network or proxy."
        exit 1
    fi

    python ./checker.py --bind-address=127.0.0.1 build
    if [ $? -ne 0 ]; then
        echo "error: The JAR could not be built."
        exit 1
    fi

    mkdir -p "${BUILT_PRODUCTS_DIR}"
    cp "${P_INTRM}" "${P_BUILD}"
}


#===================================================
# Build the JRE. This requires a Java SDK to be
# installed. We will use the JAR to determine the
# smallest feasible JRE that we can build.
#===================================================
build_jre()
{
    if [ ! -f "${BUILT_PRODUCTS_DIR}/vnu.jar" ]; then
        echo "error: The JAR has not been built for some reason. Aborting."
        exit 1
    fi

    if [ -f "${JAVA_PLUGIN}/Contents/Info.plist" ]; then
        echo "note: The JRE is already built, and no further action will be performed."
        exit
    fi

    MODULES=$("${JAVA_HOME}/bin/jdeps" --print-module-deps "${BUILT_PRODUCTS_DIR}/vnu.jar" | tail -1)

    echo "Building a minimal JRE with the following modules:"
    echo "${MODULES}"

    "${JAVA_HOME}/bin/jlink" \
    --module-path "${BUILT_PRODUCTS_DIR}" \
    --add-modules "${MODULES}" \
    --output "${JAVA_PLUGIN}/Contents/Home" \
    --no-header-files \
    --no-man-pages \
    --strip-debug \
    --compress=2

    if [ $? -ne 0 ]; then
        echo "error: The JRE could not be built."
        exit 1
    fi

    # Clean up unneeded binaries.
    find "${JAVA_PLUGIN}/Contents/Home/bin" -type f ! -name 'java' -delete

    # Need the libjli.dylib in MacOS TODO: CONFIRM, since loader isn't loading it.
    mkdir -p "${JAVA_PLUGIN}/Contents/MacOS"
    cp "${JAVA_PLUGIN}/Contents/Home/lib/libjli.dylib" \
        "${JAVA_PLUGIN}/Contents/MacOS/"

    cp "${SRCROOT}/JSDNuVFramework/java-info.plist" \
        "${JAVA_PLUGIN}/Contents/Info.plist"

    #
    # Now let's adjust the plist so that it's unique per application.
    #
    echo "Creating Unique Java Executable"

    F_JDK="${JAVA_PLUGIN}/Contents/Home/bin/java"
    F_APP="${JAVA_PLUGIN}/Contents/Home/bin/javaapp"

    # Which configuration are we building? We're going to change the bundle
    # identifier of the resuling javaapp based on the build target. Because
    # this is a binary file, replacement must be the exact same length.
    TARGET="${CONFIGURATION:0:3}"
    S_JDK="net.java.openjdk.cmd"
    S_APP="com.balthisar.jdk${TARGET}"

    echo "New bundle identifier is ${S_APP}; applying it now..."

    # Convert the bundle identifiers to hex representation.
    SO="<string>"
    SC="</string>"

    SN_JDK="$(printf ${SO}${S_JDK}${SC} | xxd -g 0 -u -ps -c 256)"
    SN_APP="$(printf ${SO}${S_APP}${SC} | xxd -g 0 -u -ps -c 256)"

    # We'll use hexdump and xxd to round-trip the file, replacing the bundle
    # identifier with the one built above.
    hexdump -ve '1/1 "%.2X"' "${F_JDK}" | sed "s/${SN_JDK}/${SN_APP}/g" | xxd -r -p > "${F_APP}"

    rm "${F_JDK}"
    chmod +x "${F_APP}"
    mv "${F_APP}" "${F_JDK}"

    # Need to apply entitlements to certain files.
    F_JSH="${JAVA_PLUGIN}/Contents/Home/lib/jspawnhelper"
    # Todo: will this work with ad hoc instead of committing my id?
#     CODE_SIGN_AS="Developer ID Application: James Derry (9PN2JXXG7Y)" # <- original
    CODE_SIGN_AS="Apple Development: James Derry (4W42G64FPJ)"
    codesign -f -s "${CODE_SIGN_AS}" --entitlements "${F_ENTITLEMENTS}" "${F_JDK}"
    codesign -f -s "${CODE_SIGN_AS}" --entitlements "${F_ENTITLEMENTS}" "${F_JSH}"
}


#===================================================
# Build the header with the JRE and JAR versions.
# We will have to have already built the JAR, but
# not have signed it. We can get the JRE version
# from the built-in JDK right now, because it's
# the same version we will build customized later.
#===================================================
build_version_header()
{
    echo "Processing the JAR and JRE files to build a dynamic header."
    HEADER="${SRCROOT}/JSDNuVFramework/xcode-version.h"
    JAR="${BUILT_PRODUCTS_DIR}/vnu.jar"
    JRE="${JAVA_HOME}/bin/java"
    cd ${SRCROOT}
    echo "// This file is generated automatically. Do not edit. Data is gathered from the" > $HEADER
    echo "// JAR and JRE. The JSDNuVFramework target Build Phases has produced this file." >> $HEADER
    echo "// Make sure you include this file as a JSDNuVFramework target header." >> $HEADER

    JAR_VERSION=$("${JRE}" -jar "${JAR}" --version)
    JRE_VERSION=$("${JRE}" --version | head -n 1)

cat << EOF >> $HEADER
#ifdef JAR_VERSION
#   undef JAR_VERSION
#endif
#ifdef JRE_VERSION
#   undef JRE_VERSION
#endif
EOF

    echo "#define JAR_VERSION @\"${JAR_VERSION}\"" >> $HEADER
    echo "#define JRE_VERSION @\"${JRE_VERSION}\"" >> $HEADER
}


#===================================================
# Main
#===================================================

satisfy_prerequisites
COMMAND=$1
echo "Executing: ${COMMAND}"
${COMMAND}
