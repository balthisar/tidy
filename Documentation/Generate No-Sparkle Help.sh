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

	mv "$LOCATION/img/tidy-prefs-01.png" "$LOCATION/img/tidy-prefs-01-hs.png"
	mv "$LOCATION/img/tidy-prefs-02.png" "$LOCATION/img/tidy-prefs-02-hs.png"
	mv "$LOCATION/img/tidy-prefs-03.png" "$LOCATION/img/tidy-prefs-03-hs.png"
	mv "$LOCATION/img/tidy-prefs-04.png" "$LOCATION/img/tidy-prefs-04-hs.png"

	mv "$LOCATION/img/tidy-prefs-01-ns.png" "$LOCATION/img/tidy-prefs-01.png"
	mv "$LOCATION/img/tidy-prefs-02-ns.png" "$LOCATION/img/tidy-prefs-02.png"
	mv "$LOCATION/img/tidy-prefs-03-ns.png" "$LOCATION/img/tidy-prefs-03.png"

	touch "$LOCATION/ns-complete.flag"
fi
