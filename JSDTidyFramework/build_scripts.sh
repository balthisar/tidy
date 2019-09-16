#!/usr/bin/env bash

############################################################
# Building and Installation Scripts.
############################################################

#===================================================
# Install the correct Helpbook for the given
# configuration.
#===================================================
sign_dylib()
{
    # Xcode simply won't sign dylibs, and we want to avoid higher level
    # frameworks and apps from having to use --deep, so we'll force the
    # dylib to be signed after copying it here. For some reason, "sign on
    # copy" doesn't work with dylibs.
    #
    # Also, Xcode won't sign a dylib when it's built, even when settings are
    # provided, and there's not an EXPANDED_CODE_SIGN_IDENTITY_NAME available
    # to shield the identity.

    DYLIB="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/libtidy-balthisar.dylib"

    printf "Signing ${DYLIB}\n"
    printf "Signing as ${EXPANDED_CODE_SIGN_IDENTITY_NAME}\n"

    codesign --verbose --force --sign "${EXPANDED_CODE_SIGN_IDENTITY_NAME}" "${DYLIB}"
}

COMMAND=$1
echo "Executing: ${COMMAND}"
${COMMAND}
