#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

function log {
    echo ">>> $*"
}

if [ -z "${1:-}" ]; then
    echo "ERROR: CrashPlan URL not provided."
    exit 1
fi

CRASHPLAN_URL="$1"

CRASHPLAN_ROOTFS="/tmp/crashplan-rootfs"
CRASHPLAN_INSTALL_DIR="/usr/local/crashplan"

log "Updating APT cache..."
apt update

log "Installing build prerequisites..."
apt upgrade -y
apt install -y --no-install-recommends \
    build-essential \
    locales \
    curl \
    rsync \
    ca-certificates \
    patchelf \
    cpio \
    libxss1 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxshmfence1 \
    libasound2 \
    libgbm1 \
    libgconf-2-4 \

# Generate locale.
locale-gen en_US.UTF-8

# Download CrashPlan.
log "Downloading CrashPlan..."
mkdir /tmp/crashplan
curl -# -L -f ${CRASHPLAN_URL} | tar -xz --strip 1 -C /tmp/crashplan

# Install CrashPlan.
log "Installing CrashPlan..."
mkdir -p /usr/share/applications
sed 's/^start_service/#start_service/' -i /tmp/crashplan/install.sh
/tmp/crashplan/install.sh

# Perform some post-install fixes.
chmod 755 "$CRASHPLAN_INSTALL_DIR"/bin/Code42Service
cp /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders.cache "$CRASHPLAN_INSTALL_DIR"/
sed "s|/usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/|$CRASHPLAN_INSTALL_DIR/nlib/|" -i "$CRASHPLAN_INSTALL_DIR"/loaders.cache

# Remove unneeded libraries.
find "$CRASHPLAN_INSTALL_DIR"/electron -type f -maxdepth 1 -name "*.so" -not -name "libffmpeg.so" -delete
rm -r \
    "$CRASHPLAN_INSTALL_DIR"/electron/swiftshader \
    "$CRASHPLAN_INSTALL_DIR"/jre/legal \

# Compile the wrapper.
log "Compiling wrapper..."
gcc -o "$CRASHPLAN_INSTALL_DIR"/nlib/libwrapper.so /build/libwrapper.c -Wall -Werror -fPIC -shared -ldl
strip /"$CRASHPLAN_INSTALL_DIR"/nlib/libwrapper.so

# Extra libraries that need to be installed into the CrashPlan lib
# folder.  These libraries are loaded dynamically (dlopen) and are not catched
# by tracking dependencies.
EXTRA_LIBS="
    /lib/x86_64-linux-gnu/libnss_dns
    /lib/x86_64-linux-gnu/libnss_files
    /lib/x86_64-linux-gnu/libnss_compat
    /lib/x86_64-linux-gnu/libudev.so.1
    /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.so
    /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-png.so
    /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1
"

echo "Copying extra libraries..."
for LIB in $EXTRA_LIBS
do
    cp -av "$LIB"* "$CRASHPLAN_INSTALL_DIR"/nlib/
done

# Extract dependencies of all binaries and libraries.
find "$CRASHPLAN_INSTALL_DIR" -name Code42Service -or -name code42 -or -type f -name 'lib*.so*' | while read BIN
do
    RAW_DEPS="$(LD_LIBRARY_PATH="$CRASHPLAN_INSTALL_DIR"/nlib:"$CRASHPLAN_INSTALL_DIR"/jre/lib/server ldd "$BIN")"
    echo "Dependencies for $BIN:"
    echo "================================"
    echo "$RAW_DEPS"
    echo "================================"

    if echo "$RAW_DEPS" | grep -q " not found"; then
        echo "ERROR: Some libraries are missing!"
        exit 1
    fi

    LD_LIBRARY_PATH="$CRASHPLAN_INSTALL_DIR"/nlib:"$CRASHPLAN_INSTALL_DIR"/jre/lib/server ldd "$BIN" | (grep " => " || true) | cut -d'>' -f2 | sed 's/^[[:space:]]*//' | cut -d'(' -f1 | while read dep
    do
        dep_real="$(realpath "$dep")"
        dep_basename="$(basename "$dep_real")"

        # Skip already-processed libraries.
        if [[ "$dep_real" == "$CRASHPLAN_INSTALL_DIR"/* ]]; then
            continue
        fi

        echo "  -> Found library: $dep"
        cp "$dep_real" "$CRASHPLAN_INSTALL_DIR"/nlib/
        while true; do
            [ -L "$dep" ] || break;
            ln -sf "$dep_basename" "$CRASHPLAN_INSTALL_DIR"/nlib/"$(basename $dep)"
            dep="$(readlink -f "$dep")"
        done
    done
done

log "Patching ELF of binaries..."
find "$CRASHPLAN_INSTALL_DIR" '(' -name Code42Service -or -name code42 ')' -exec echo "  -> Setting interpreter of {}..." ';' -exec patchelf --set-interpreter "$CRASHPLAN_INSTALL_DIR/nlib/ld-linux-x86-64.so.2" {} ';'
find "$CRASHPLAN_INSTALL_DIR" -type f -name code42 -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN:$ORIGIN/../nlib' {} ';'
find "$CRASHPLAN_INSTALL_DIR" -type f -name Code42Service -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN:$ORIGIN/../jre/lib:$ORIGIN/../jre/lib/jli:$ORIGIN/../jre/lib/server:$ORIGIN/../nlib' {} ';'

log "Patching ELF of libraries..."
find "$CRASHPLAN_INSTALL_DIR"/nlib -type f -name "*.so*" -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath '$ORIGIN' {} ';'
find "$CRASHPLAN_INSTALL_DIR"/jre/lib -maxdepth 1 -type f -name "lib*.so*" -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath "\$ORIGIN:\$ORIGIN/jli::$CRASHPLAN_INSTALL_DIR/nlib" {} ';'
find "$CRASHPLAN_INSTALL_DIR"/jre/lib -mindepth 2 -type f -name "lib*.so*" -exec echo "  -> Setting rpath of {}..." ';' -exec patchelf --set-rpath "\$ORIGIN:\$ORIGIN/../:$CRASHPLAN_INSTALL_DIR/nlib" {} ';'

log "Copying interpreter..."
cp -av /lib/x86_64-linux-gnu/ld-* "$CRASHPLAN_INSTALL_DIR"/nlib/

log "Creating rootfs..."
mkdir "$CRASHPLAN_ROOTFS"
ROOTFS_CONTENT="\
    $CRASHPLAN_INSTALL_DIR
    /usr/share/glib-2.0/schemas
    /usr/share/icons/Adwaita/index.theme
    /usr/share/icons/Adwaita/scalable
    /usr/lib/locale/locale-archive
    /etc/fonts
    /usr/share/mime
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
"
echo "$ROOTFS_CONTENT" | while read i
do
    if [ -n "$i" ]; then
        rsync -Rav "$i" "$CRASHPLAN_ROOTFS"
    fi
done

log "CrashPlan built successfully."
