#!/bin/sh

# Add documents to the user's desktop.
QR="Tidy Quick Reference.html"
RM="Tidy README.rtf"

cp "$QR" "$HOME/Desktop/"
cp "$RM" "$HOME/Desktop/"

chown $USER "$QR"
chown $USER "$RM"

# Add path to .bash_profile if not already there.


new=/usr/local/bin
BP="$HOME/.bash_profile"
touch $BP
chown $USER $BP 
echo "\n" >> $BP
echo "# Tidy for Mac OS X by balthisar.com is adding the new path for Tidy." >> $BP
echo "export PATH=$new:\$PATH" >> $BP
echo "\n" >> $BP
