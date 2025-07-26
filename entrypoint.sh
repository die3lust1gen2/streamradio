#!/bin/sh
set -e

# Default UID and GID if not set
: "${UID:=1000}"
: "${GID:=1000}"

# Create group if not exists
if ! getent group "$GID" >/dev/null; then
    addgroup -g "$GID" "$APPNAME"
fi

# Create user if not exists
if ! id -u "$UID" >/dev/null 2>&1; then
    adduser -D -u "$UID" -G "$APPNAME" "$APPNAME"
fi

# Ensure HOME exists and owned properly
#mkdir -p /home/$APPNAME
#chown "$UID:$GID" /home/$APPNAME

# Drop privileges and run the app
exec su-exec "$UID:$GID" "$@"
