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

# Install megatools if not present
#if ! command -v megadl >/dev/null 2>&1; then
#    echo "Installing megatools..."
#    pacman -S --noconfirm megatools
#fi

# Download AACS KEYDB.cfg
echo "Downloading AACS KEYDB.cfg..."
mkdir -p ./AppDir/shared/aacs
wget -O ./AppDir/shared/aacs/KEYDB.cfg "http://fvonline-db.bplaced.net/fv_download.php?lang=eng" || {
    echo "Error: Failed to download KEYDB.cfg"
    exit 1
}

# Download BD+ tables from MEGA
echo "Downloading BD+ tables..."
mkdir -p /tmp/bdplus
cd /tmp/bdplus

megadl 'https://mega.nz/file/Jd1xEQbJ#DRhG9eWLNnrmA5dcwHugnKxmVUpIsT9X-HKuuGjU7n8' || echo "Warning: Failed to download BD+ table 0"
megadl 'https://mega.nz/file/ZZdA3QCJ#FaL2ohltwFCtX91UMngB_dUtqht8JZ3-nRgnTAJD8jk' || echo "Warning: Failed to download BD+ table 1"
megadl 'https://mega.nz/file/pc0VTaYY#Tl1XMSex_Y9iCKmvYEKddr7GQQVQbMDEHJbw0uXumj0' || echo "Warning: Failed to download BD+ table 2"
megadl 'https://mega.nz/file/gVsRQQ7Y#JOJwO5woXdz2X73rrvHHBTYCdLposz7aiSVkEX4vChM' || echo "Warning: Failed to download BD+ table 3"
megadl 'https://mega.nz/file/AR8DDaib#GgSUMnNGBlVXdJT0BEkNkGm5f4NfodBaQ8SSgFFM4ZA' || echo "Warning: Failed to download BD+ table 4"

# Download BD+ VM files
echo "Downloading BD+ VM files..."
megadl 'https://mega.nz/#!MFlTDYiT!I-laau3lrg9OgcAL-1DPk-c9ytxbOCKUj73NBhI8Cr0' || echo "Warning: Failed to download BD+ VM files"

# Extract all archives to AppDir
mkdir -p ../../AppDir/shared/bdplus
for archive in /tmp/bdplus/*.7z; do
    [ -f "$archive" ] || continue
    echo "Extracting $(basename "$archive")..."
    7z x -aoa "$archive" -o../../AppDir/shared/bdplus/ || echo "Warning: Failed to extract $archive" ;;
done

cd -
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
