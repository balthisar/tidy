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
TARGET="${CONFIGURATION:0:3}"    # app, pro, or web
JAVA_PLUGIN="${BUILT_PRODUCTS_DIR}/${PLUGINS_FOLDER_PATH}/Java.bundle"
F_ENTITLEMENTS="${SRCROOT}/JSDNuVFramework/java.entitlements"
CODE_SIGN_AS="Developer ID Application: James Derry (9PN2JXXG7Y)"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/balthisar-${TARGET}-16.jdk/Contents/Home
if [ ! -d "${JAVA_HOME}" ]; then
    export JAVA_HOME=$(/usr/libexec/java_home)
    echo "warning: The customized JDK wasn't found. Using the default JDK."
fi

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
# Build the JDK.
# In order to be included in the App Store, we
# must have CFBundleIdentifiers in the java and
# other executables that are not in use by another
# application in the store. We used to be able to
# patch the executables with a custom string, but
# with hardened runtime and strict signing, that
# no longer works. Instead, we'll build entire
# custom JDK's.
#
# This is NOT part of the build process. Since you
# are probably NOT submitting copies of my app to
# the App Store, you're probably okay using your
# existing JDK. This is meant to be called from
# the terminal, and will build the JDK on your
# desktop.
#===================================================
build_jdk()
{
	TARGET="${2}"
    BUILD_ROOT=$(mktemp -d -t balthisar-sdk)
    BUILD_WORK="${BUILD_ROOT}/openjdk-build"
    BUILD_OUTP="${BUILD_ROOT}/openjdk-build/workspace/target/OpenJDK.tar.gz"
	GIT_SRC="https://github.com/AdoptOpenJDK/openjdk-build.git"
	JDK_BUNDLE_ID="com.balthisar.jvm-${TARGET}"
	JDK_VENDOR_VS="balthisar-${TARGET}"
	JDK_OUTP_DEST="${HOME}/Desktop"
    JDK_OUTP_NAME="balthisar-${TARGET}-16.jdk"
     
#     trap "rm -rf ${BUILD_ROOT}" EXIT

	echo "CFBundleIdentifier:    ${JDK_BUNDLE_ID}" 
	echo "Vendor Version String: ${JDK_VENDOR_VS}"
	echo "JDK Output Name:       ${JDK_OUTP_NAME}"  

	cd "${BUILD_ROOT}"
	git clone "${GIT_SRC}"
	cd "${BUILD_WORK}"
    
    sh ./makejdk-any-platform.sh \
        -J "/Library/Java/JavaVirtualMachines/jdk-15.0.2.jdk/Contents/Home" \
        --codesign-identity "${CODE_SIGN_AS}" \
        --vendor "balthisar.com" \
        --configure-args "--with-macosx-bundle-id-base=${JDK_BUNDLE_ID} --with-vendor-url=https://www.balthisar.com/ --with-vendor-version-string=${JDK_VENDOR_VS}" \
        --skip-freetype \
        --release \
        jdk16u
    
set -x
    ARCHIVED_NAME=$(tar tzf "${BUILD_OUTP}" | sed -e 's@/.*@@' | uniq) # e.g., jdk-16+36
    tar -xf "${BUILD_OUTP}" --directory "${JDK_OUTP_DEST}"
    mv "${JDK_OUTP_DEST}/${ARCHIVED_NAME}" "${JDK_OUTP_DEST}/${JDK_OUTP_NAME}" 
	xattr -c "${JDK_OUTP_DEST}/${JDK_OUTP_NAME}"
}


#===================================================
# Build the JAR.
# We can't sign it yet because we have to use it
# from the shell later to get its version number.
# We will build into BUILT_PRODUCTS_DIR and use it
# as a flag for whether or not we build.
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
# Build the JRE
# We'll build a custom, reduced-size JRE containing
# only the Java modules needed for the JAR to run.
# Note that you must already have a JDK installed.
# Note that for app store releases, you MUST have
# a custom JDK installed with CFBundleIdentifiers
# that are not in use by another application in
# the App Store.
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

    #
    # Need the libjli.dylib in MacOS
    #
    mkdir -p "${JAVA_PLUGIN}/Contents/MacOS"
    cp "${JAVA_PLUGIN}/Contents/Home/lib/libjli.dylib" \
        "${JAVA_PLUGIN}/Contents/MacOS/"

    cp "${SRCROOT}/JSDNuVFramework/java-info.plist" \
        "${JAVA_PLUGIN}/Contents/Info.plist"


    #
    # Code-sign, apply entitlements, and enable the hardened runtime as necessary.
    #
    if [ "$TARGET" = "web" ]; then
        # In order to notarize, we have to apply this codesigning to the bundle as
        # a whole, and we CANNOT apply it individually to the files below, because
        # this will just cause sandbox errors.
        codesign \
            --verbose=4 \
            --deep \
            --force \
            --sign "${CODE_SIGN_AS}" \
            --options runtime \
            --entitlements "${F_ENTITLEMENTS}" \
            "${JAVA_PLUGIN}"
    else
        # The App Store, on the other hand, wants us specifically to sign these two
        # files, otherwise AppStoreConnect will complain that entitlements are missing,
        # even if we sign the whole bundle. Additionally, you cannot submit hardened
        # runtime apps to the App Store!
        codesign -f -s "${CODE_SIGN_AS}" --entitlements "${F_ENTITLEMENTS}" "${JAVA_PLUGIN}/Contents/Home/bin/java"
        codesign -f -s "${CODE_SIGN_AS}" --entitlements "${F_ENTITLEMENTS}" "${JAVA_PLUGIN}/Contents/Home/lib/jspawnhelper"
        codesign \
            --verbose=4 \
            --deep \
            --force \
            --sign "${CODE_SIGN_AS}" \
            --entitlements "${F_ENTITLEMENTS}" \
            "${JAVA_PLUGIN}"
    fi
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
${COMMAND} $*
