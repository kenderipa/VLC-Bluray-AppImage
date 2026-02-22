#!/bin/sh
set -eu
ARCH=$(uname -m)
VERSION=$(pacman -Q vlc | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export ICON=/usr/share/icons/hicolor/128x128/apps/vlc.png
export DESKTOP=/usr/share/applications/vlc.desktop

# Deploy VLC with all plugins, libraries, Qt5, Java, and Blu-ray libraries
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
#    /usr/lib/qt5/plugins/platforms \
    /usr/lib/jvm/java-17-openjdk/bin/ \
    /usr/bin/java \
    /usr/lib/libaacs.so.0 \
    /usr/lib/libbluray.so.2

# Download and extract AACS KEYDB.cfg to standard location
echo "Downloading AACS KEYDB.cfg..."
mkdir -p ./AppDir/etc/xdg/aacs /tmp/keydb_extract
wget -O /tmp/keydb.zip "http://fvonline-db.bplaced.net/fv_download.php?lang=eng"
unzip -q /tmp/keydb.zip -d /tmp/keydb_extract/
find /tmp/keydb_extract -name "keydb.cfg" -exec cp {} ./AppDir/etc/xdg/aacs/KEYDB.cfg \;
rm -rf /tmp/keydb.zip /tmp/keydb_extract

if [ ! -f ./AppDir/etc/xdg/aacs/KEYDB.cfg ]; then
    echo "ERROR: KEYDB.cfg not found after extraction!"
    exit 1
fi
echo "KEYDB.cfg successfully added to AppDir/etc/xdg/aacs/"

# Download BD+ tables to standard location
echo "Downloading BD+ tables..."
mkdir -p /tmp/bdplus ./AppDir/shared/lib/libbluray/bdplus/conv_tab
APPDIR_ABS="$(pwd)/AppDir/shared/lib/libbluray/bdplus"
cd /tmp/bdplus

#megadl 'https://mega.nz/file/Jd1xEQbJ#DRhG9eWLNnrmA5dcwHugnKxmVUpIsT9X-HKuuGjU7n8' || echo "Warning: Failed to download BD+ table 0"
#megadl 'https://mega.nz/file/ZZdA3QCJ#FaL2ohltwFCtX91UMngB_dUtqht8JZ3-nRgnTAJD8jk' || echo "Warning: Failed to download BD+ table 1"
##megadl 'https://mega.nz/file/pc0VTaYY#Tl1XMSex_Y9iCKmvYEKddr7GQQVQbMDEHJbw0uXumj0' || echo "Warning: Failed to download BD+ table 2"
#megadl 'https://mega.nz/file/gVsRQQ7Y#JOJwO5woXdz2X73rrvHHBTYCdLposz7aiSVkEX4vChM' || echo "Warning: Failed to download BD+ table 3"
#megadl 'https://mega.nz/file/AR8DDaib#GgSUMnNGBlVXdJT0BEkNkGm5f4NfodBaQ8SSgFFM4ZA' || echo "Warning: Failed to download BD+ table 4"

# Download BD+ VM files
#echo "Downloading BD+ VM files..."
#megadl 'https://mega.nz/#!MFlTDYiT!I-laau3lrg9OgcAL-1DPk-c9ytxbOCKUj73NBhI8Cr0' || echo "Warning: Failed to download BD+ VM files"

# Extract all archives
for archive in *.7z *.zip; do
    [ -f "$archive" ] || continue
    echo "Extracting $(basename "$archive")..."
    case "$archive" in
        *.7z) 7z x "$archive" -o"$APPDIR_ABS/" -y || echo "Warning: Failed to extract $archive" ;;
        *.zip) unzip -q "$archive" -d "$APPDIR_ABS/" || echo "Warning: Failed to extract $archive" ;;
    esac
done

cd -
rm -rf /tmp/bdplus

#if [ -z "$(ls -A ./AppDir/shared/lib/libbluray/bdplus)" ]; then
#    echo "WARNING: BD+ directory is empty!"
#else
#    echo "BD+ files successfully added to AppDir/shared/lib/libbluray/bdplus/"
#fi

# Use PATH_MAPPING_HARDCODED to tell quick-sharun to patch these paths
export PATH_MAPPING_HARDCODED="libaacs.so.0 libbluray.so.2"

# Turn AppDir into AppImage
quick-sharun --make-appimage
