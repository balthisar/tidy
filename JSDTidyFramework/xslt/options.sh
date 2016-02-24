#!/usr/bin/env sh

# Generates an `options.txt` file using `options.xml` and `options.xsl`.
# We will do the following:
#  - Transform the XML into a strings file using `saxon`
#  - Post-process the file with Perl to unescape the HTML elements.

base_name=`basename $0`

saxon -s:options.xml -xsl:options.xsl -o:options-temp.txt

cat options-temp.txt | perl -n -mHTML::Entities -e ' ; print HTML::Entities::decode_entities($_) ;' > options.txt

rm options-temp.txt
