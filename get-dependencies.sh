#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
bash \
hicolor-icon-theme \
vlc-gui-qt \
vlc-gui-ncurses \
vlc-gui-skins2 \
vlc-plugins-all \
vlc-plugins-extra \
vlc-plugins-visualization \
a52dec \
aalib \
abseil-cpp \
alsa-lib \
aom \
aribb24 \
aribb25 \
avahi \
ca-certificates \
cairo \
dav1d \
dbus \
faad2 \
ffmpeg4.4 \
flac \
fluidsynth \
fontconfig \
freetype2 \
fribidi \
gcc-libs \
gdk-pixbuf2 \
glib2 \
glibc \
gnutls \
gst-plugins-base-libs \
gtk3 \
harfbuzz \
hicolor-icon-theme \
jre17-openjdk \
pipewire-jack \
libarchive \
libass \
libavc1394 \
libbluray \
libcaca \
libcddb \
libdc1394 \
libdca \
libdvbpsi \
libdvdcss \
libdvdnav \
libdvdread \
libglvnd \
libgme \
libgoom2 \
libjpeg-turbo \
libkate \
libmad \
libmatroska \
libmicrodns \
libmodplug \
libmpcdec \
libmpeg2 \
libmtp \
libnfs \
libnotify \
libogg \
libpng \
libproxy \
libpulse \
librsvg \
libsamplerate \
libsecret \
libshout \
libsoxr \
libssh2 \
libtheora \
libtiger \
libupnp \
libva \
libvorbis \
libvpx \
libx11 \
libxcb \
libxinerama \
libxml2 \
libxpm \
lirc \
live-media \
lua \
mesa \
mpg123 \
opus \
pcsclite \
projectm \
protobuf \
qt5-base \
qt5-svg \
qt5-x11extras \
sdl12-compat \
sdl_image \
smbclient \
speex \
speexdsp \
srt \
systemd-libs \
taglib \
twolame \
vlc \
wayland \
wayland-protocols \
x264 \
x265 \
xcb-util-keysyms \
xosd \
zlib \
zvbi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
gpg --recv-keys F9F0A873BE9777ED
make-aur-package megatools

# If the application needs to be manually built that has to be done down here
