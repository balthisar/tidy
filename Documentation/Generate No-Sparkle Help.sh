#!/bin/bash
# This will modify helpbook in order to use the no-sparkle resources
# instead of the default resources. This works okay for one, single
# localization, but a better solution for multiple localizations
# might be in order.
#
# The intent here is to be pasted into a "Run Script" phase of the
# Balthisar Tidy (no sparkle) build target.

LOCATION="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Balthisar Tidy.help/Contents/Resources/Base.lproj"

#ONLY DO THIS IF NOT ALREADY DONE:
if [ ! -f "$LOCATION/ns-complete.flag" ]; then
	mv "$LOCATION/pages/preferences.html" "$LOCATION/pages/preferences-hs.html"
	mv "$LOCATION/pages/reference.html" "$LOCATION/pages/reference-hs.html"

	mv "$LOCATION/pages/preferences-ns.html" "$LOCATION/pages/preferences.html"
	mv "$LOCATION/pages/reference-ns.html" "$LOCATION/pages/reference.html"

	mv "$LOCATION/img/prefs-misc.png" "$LOCATION/img/prefs-misc-hs.png"
	mv "$LOCATION/img/prefs-saving.png" "$LOCATION/img/prefs-saving-hs.png"
	mv "$LOCATION/img/prefs-tidy.png" "$LOCATION/img/prefs-tidy-hs.png"
	mv "$LOCATION/img/prefs-updates.png" "$LOCATION/img/prefs-updates-hs.png"

	mv "$LOCATION/img/prefs-misc-ns.png" "$LOCATION/img/prefs-misc.png"
	mv "$LOCATION/img/prefs-saving-ns.png" "$LOCATION/img/prefs-saving.png"
	mv "$LOCATION/img/prefs-tidy-ns.png" "$LOCATION/img/prefs-tidy.png"

	touch "$LOCATION/ns-complete.flag"
fi
