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
export PATH_MAPPING_HARDCODED='*aacs*'


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
    /usr/lib/qt5/plugins/platforms \
    /usr/lib/jvm/java-17-openjdk \
    /usr/bin/java \
    /usr/lib/libaacs.so.0 \
    /usr/lib/libbluray.so.2

# NOW add AACS and BD+ files to the AppDir that was just created

# Download and extract AACS KEYDB.cfg
echo "Downloading AACS KEYDB.cfg..."
mkdir -p ./AppDir/shared/config/aacs /tmp/keydb_extract
wget -O /tmp/keydb.zip "http://fvonline-db.bplaced.net/fv_download.php?lang=eng"
unzip -q /tmp/keydb.zip -d /tmp/keydb_extract/
find /tmp/keydb_extract -name "keydb.cfg" -exec cp {} ./AppDir/shared/config/aacs/KEYDB.cfg \;
rm -rf /tmp/keydb.zip /tmp/keydb_extract

# Verify KEYDB.cfg was copied
if [ ! -f ./AppDir/shared/config/aacs/KEYDB.cfg ]; then
    echo "ERROR: KEYDB.cfg not found after extraction!"
    exit 1
fi
echo "KEYDB.cfg successfully added to AppDir"

# Download BD+ tables from MEGA
echo "Downloading BD+ tables..."
mkdir -p /tmp/bdplus ./AppDir/shared/lib/libbluray/bdplus
APPDIR_ABS="$(pwd)/AppDir/shared/lib/libbluray/bdplus"
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
for archive in *.7z *.zip; do
    [ -f "$archive" ] || continue
    echo "Extracting $(basename "$archive")... to $APPDIR_ABS"
    case "$archive" in
        *.7z) 7z x "$archive" -o"$APPDIR_ABS/" -y || echo "Warning: Failed to extract $archive" ;;
        *.zip) unzip -q "$archive" -d "$APPDIR_ABS/" || echo "Warning: Failed to extract $archive" ;;
    esac
done

cd -
rm -rf /tmp/bdplus

# Verify BD+ files were extracted
if [ -z "$(ls -A ./AppDir/shared/lib/libbluray/bdplus 2>/dev/null)" ]; then
    echo "WARNING: BD+ directory is empty!"
else
    echo "BD+ files successfully added to AppDir"
fi

# Create wrapper script in ./AppDir/bin where binaries are executed
cat > ./AppDir/bin/vlc-wrapper << 'EOF'
#!/bin/sh
APPDIR="${APPDIR:-$(dirname "$(readlink -f "$0")")/..}"

# Set up AACS and BD+ paths
export LIBAACS_PATH="$APPDIR/shared/lib"
export LIBBDPLUS_PATH="$APPDIR/shared/lib/libbluray/bdplus"
export XDG_CONFIG_HOME="$APPDIR/shared/config"

# Debug output (remove after testing)
echo "APPDIR=$APPDIR" >&2
echo "LIBAACS_PATH=$LIBAACS_PATH" >&2
echo "LIBBDPLUS_PATH=$LIBBDPLUS_PATH" >&2
echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME" >&2
echo "KEYDB exists: $(test -f "$XDG_CONFIG_HOME/aacs/KEYDB.cfg" && echo yes || echo no)" >&2

# Execute VLC (from bin directory)
exec "$APPDIR/bin/vlc" "$@"
EOF

chmod +x ./AppDir/bin/vlc-wrapper

# Update desktop file to use wrapper
sed -i 's|Exec=/usr/bin/vlc --started-from-file %U|Exec=vlc-wrapper|g' ./AppDir/vlc.desktop
#sed -i 's|Exec=vlc|Exec=vlc-wrapper|g' ./AppDir/vlc.desktop

# Turn AppDir into AppImage
quick-sharun --make-appimage
