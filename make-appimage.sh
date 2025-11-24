#!/bin/sh
set -eu
ARCH=$(uname -m)
VERSION=$(pacman -Q vlc | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
#export ADD_HOOKS="self-updater.bg.hook"
#export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/128x128/apps/vlc.png
export DESKTOP=/usr/share/applications/vlc.desktop

# Deploy VLC with all plugins, libraries, Qt5, and Java for Blu-ray menus
quick-sharun \
    /usr/bin/vlc \
    /usr/bin/cvlc \
    /usr/bin/nvlc \
    /usr/bin/rvlc \
    /usr/bin/svlc \
    /usr/lib/vlc \
    /usr/share/vlc \
    /usr/lib/libQt5Core.so.5 \
    /usr/lib/libQt5Gui.so.5 \
    /usr/lib/libQt5Widgets.so.5 \
    /usr/lib/libQt5X11Extras.so.5 \
    /usr/lib/libQt5Svg.so.5 \
    /usr/lib/qt5/plugins/platforms \
    /usr/lib/jvm/java-17-openjdk \
    /usr/bin/java

# Download and extract AACS keys and BD+ files
echo "Downloading AACS KEYDB.cfg..."
mkdir -p ./AppDir/shared/aacs
wget -q -O ./AppDir/shared/aacs/KEYDB.cfg "http://www.labdv.com/aacs/KEYDB.cfg" || \
wget -q -O ./AppDir/shared/aacs/KEYDB.cfg "https://vlc-bluray.whoknowsmy.name/files/KEYDB.cfg"

echo "Downloading BD+ tables..."
mkdir -p /tmp/bdplus
wget -q -O /tmp/bdplus/libaacs_bdplus.tar.bz2 "https://vlc-bluray.whoknowsmy.name/files/libaacs_bdplus.tar.bz2"
tar -xjf /tmp/bdplus/libaacs_bdplus.tar.bz2 -C ./AppDir/shared/
rm -rf /tmp/bdplus

# Create wrapper script for VLC to use bundled AACS/BD+ files
cat > ./AppDir/shared/bin/vlc-wrapper << 'EOF'
#!/bin/sh
APPDIR="${APPDIR:-$(dirname "$(readlink -f "$0")")/../..}"

# Set up AACS and BD+ paths
export LIBAACS_KEYDB="$APPDIR/shared/aacs/KEYDB.cfg"
export LIBBDPLUS_PATH="$APPDIR/shared/bdplus"

# Execute VLC
exec "$APPDIR/shared/bin/vlc" "$@"
EOF

chmod +x ./AppDir/shared/bin/vlc-wrapper

# Update desktop file to use wrapper
sed -i 's|Exec=vlc|Exec=vlc-wrapper|g' ./AppDir/shared/applications/vlc.desktop

# Turn AppDir into AppImage
quick-sharun --make-appimage
