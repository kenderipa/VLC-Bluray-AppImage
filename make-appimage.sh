#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q PACKAGENAME | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export OUTPATH=./dist
#export ADD_HOOKS="self-updater.bg.hook"
#export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/128x128/apps/vlc.png
export DESKTOP=/usr/share/applications/vlc.desktop

# Deploy dependencies
quick-sharun \
    /usr/bin/vlc \
    /usr/bin/cvlc \
    /usr/bin/nvlc \
    /usr/bin/rvlc \
    /usr/bin/svlc \
    /usr/lib/vlc \
    /usr/share/vlc

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
