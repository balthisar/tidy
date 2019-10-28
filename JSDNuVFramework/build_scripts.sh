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
# - Build the JREs in place, and sign them.
# - Move the JAR into place, and sign it.
############################################################

#---------------------------------------------------
# Common variables
#---------------------------------------------------
TARGET="${CONFIGURATION:0:3}"    # app, pro, or web
F_ENTITLEMENTS="${SRCROOT}/JSDNuVFramework/java.entitlements"
CODE_SIGN_AS="Developer ID Application: James Derry (9PN2JXXG7Y)"

JDK_intel="${HOME}/Development/balthisar_tidy_jdks/balthisar-${TARGET}-intel-17.jdk/Contents/Home"
JDK_arm64="${HOME}/Development/balthisar_tidy_jdks/balthisar-${TARGET}-arm64-17.jdk/Contents/Home"

PLUGIN_intel="${BUILT_PRODUCTS_DIR}/${PLUGINS_FOLDER_PATH}Java-intel.bundle"
PLUGIN_arm64="${BUILT_PRODUCTS_DIR}/${PLUGINS_FOLDER_PATH}Java-arm64.bundle"
PLUGIN_fat64="${BUILT_PRODUCTS_DIR}/${PLUGINS_FOLDER_PATH}Java-fat64.bundle"

echo "Intel: ${JDK_intel}"
echo "Arm64: ${JDK_arm64}"

if [ ! -d "${JDK_intel}" ]; then
    echo "error: The customized x86_64 JDK wasn't found. You can try editing this file to specify your own if you like."
fi

if [ ! -d "${JDK_arm64}" ]; then
    echo "error: The customized arm64 JDK wasn't found. You can try editing this file to specify your own if you like."
fi


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
    JDK_OUTP_NAME="balthisar-${TARGET}-17.jdk"
     
    trap "rm -rf ${BUILD_ROOT}" EXIT

    echo "CFBundleIdentifier:    ${JDK_BUNDLE_ID}"
    echo "Vendor Version String: ${JDK_VENDOR_VS}"
    echo "JDK Output Name:       ${JDK_OUTP_NAME}"

    cd "${BUILD_ROOT}"
    git clone "${GIT_SRC}"
    cd "${BUILD_WORK}"
    
    sh ./makejdk-any-platform.sh \
        -J "/Library/Java/JavaVirtualMachines/adoptopenjdk-16.jdk/Contents/Home" \
        --codesign-identity "${CODE_SIGN_AS}" \
        --vendor "balthisar.com" \
        --configure-args "--with-macosx-bundle-id-base=${JDK_BUNDLE_ID} --with-vendor-url=https://www.balthisar.com/ --with-vendor-version-string=${JDK_VENDOR_VS}" \
        --skip-freetype \
        --release \
        jdk
    
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

    # Presumably building this project on x86_64.
    export JAVA_HOME="${JDK_intel}"

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
# Build a JRE
# We'll build a custom, reduced-size JRE containing
# only the Java modules needed for the JAR to run.
# Note that you must already have a JDK installed.
# Note that for app store releases, you MUST have
# a custom JDK installed with CFBundleIdentifiers
# that are not in use by another application in
# the App Store.
#===================================================
build_one_jre()
{
    if [ ! -f "${BUILT_PRODUCTS_DIR}/vnu.jar" ]; then
        echo "error: The JAR has not been built for some reason. Aborting."
        exit 1
    fi

    if [ -f "${JAVA_PLUGIN}/Contents/Info.plist" ]; then
        echo "note: The JRE is already built, and no further action will be performed."
        exit
    fi

    MODULES=$("${JDK_intel}/bin/jdeps" --print-module-deps "${BUILT_PRODUCTS_DIR}/vnu.jar" | tail -1)

    echo "Building a minimal JRE with the following modules:"
    echo "${MODULES}"

    #
    # todo: don't automatically assume we're building on Intel. But for
    # now, we will use the Intel JDK to build both architectures of JRE.
    #
    "${JDK_intel}/bin/jlink" \
        --module-path "${JAVA_HOME}/jmods" \
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
}


#===================================================
# Sign a JRE
# Sign the JRE. How we do so depends on whether we
# are building for the Mac App Store, or are going
# to notarize.
#===================================================
sign_one_jre()
{

    #
    # Code-sign, apply entitlements, and enable the hardened runtime as necessary.
    #
set -x
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
        codesign -f -s "${CODE_SIGN_AS}" --entitlements "${F_ENTITLEMENTS}" "${JAVA_PLUGIN}/Contents/Home/bin/java_arm"
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
# Make a fat bundle combining both architectures.
# This is more likely to pass future App Store
# requirements that all binaries be fat, rather
# than deciding at runtime which architecture to
# use.
#===================================================
lipo_two_jres()
{
    # Use the Intel Plugin as a base for the fat plugin.
    rm -rf "${PLUGIN_fat64}"
    cp -R "${PLUGIN_intel}" "${PLUGIN_fat64}"

    # Delete all of the existing binaries.
    find "${PLUGIN_fat64}/Contents/macOS" -type f -delete
#    find "${PLUGIN_fat64}/Contents/Home/bin" -type f -delete
    find "${PLUGIN_fat64}/Contents/Home/lib" -type f -name 'jspawnhelper' -delete
    find "${PLUGIN_fat64}/Contents/Home/lib" -type f -name '*.dylib' -delete
    find "${PLUGIN_fat64}/Contents/Home/lib/server" -type f -name '*.dylib' -delete

    # We already have the Intel Java that we didn't delete with the other binaries.
    # Let's copy the new architecture there, too, with a different name. Because
    # they're signed and hardened, re-signing will just upset the notarization process.
    cp "${PLUGIN_arm64}/Contents/Home/bin/java" "${PLUGIN_fat64}/Contents/Home/bin/java_arm"

    # Assemble a list of relative paths of all of the binaries we just deleted.
    cd "${PLUGIN_intel}"
    manifest=(Contents/macOS/libjli.dylib)
#    manifest+=(Contents/Home/bin/java)
    manifest+=(Contents/Home/lib/jspawnhelper)
    manifest+=(Contents/Home/lib/*.dylib)
    manifest+=(Contents/Home/lib/server/*.dylib)

    # And lipo them together.
    for binary in "${manifest[@]}"; do
        printf "$binary\n"
        lipo -create "${PLUGIN_intel}/${binary}" "${PLUGIN_arm64}/${binary}" -o "${PLUGIN_fat64}/${binary}"
        lipo -info "${PLUGIN_fat64}/${binary}"
    done
}


#===================================================
# Build the JRE's.
#===================================================
build_jre()
{
    JAVA_PLUGIN="${PLUGIN_intel}"
    export JAVA_HOME="${JDK_intel}"
    build_one_jre

    JAVA_PLUGIN="${PLUGIN_arm64}"
    export JAVA_HOME="${JDK_arm64}"
    build_one_jre
    
    lipo_two_jres
    
    JAVA_PLUGIN="${PLUGIN_fat64}"
    sign_one_jre
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
    JRE="${JDK_intel}/bin/java"
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

COMMAND=$1
echo "Executing: ${COMMAND}"
${COMMAND} $*
