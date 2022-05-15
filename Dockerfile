#
# crashplan-pro Dockerfile
#
# https://github.com/jlesage/docker-crashplan-pro
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG CRASHPLAN_VERSION=10.0.0
ARG CRASHPLAN_TIMESTAMP=15252000061000
ARG CRASHPLAN_BUILD=303

# Define software download URLs.
ARG CRASHPLAN_URL=https://download.code42.com/installs/agent/cloud/${CRASHPLAN_VERSION}/${CRASHPLAN_BUILD}/install/CrashPlanSmb_${CRASHPLAN_VERSION}_${CRASHPLAN_TIMESTAMP}_${CRASHPLAN_BUILD}_Linux.tgz

# Build CrashPlan.
FROM ubuntu:20.04 AS crashplan
ARG CRASHPLAN_URL
WORKDIR /tmp
COPY src/crashplan /crashplan-build
RUN /crashplan-build/build.sh "${CRASHPLAN_URL}"

# Build YAD.
FROM alpine:3.14 AS yad
COPY src/yad/build.sh /build-yad.sh
RUN /build-yad.sh

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.14-v3.5.8
ARG DOCKER_IMAGE_VERSION
ARG CRASHPLAN_VERSION

# Define container build variables.
ARG TARGETDIR=/usr/local/crashplan

# Define working directory.
WORKDIR /tmp

# Install CrashPlan.
COPY --from=crashplan /tmp/crashplan-rootfs /
RUN \
    # Keep a copy of the default config.
    mv ${TARGETDIR}/conf /defaults/conf && \
    # Make sure the UI connects by default to the engine using the loopback IP address (127.0.0.1).
    sed-patch '/<orgType>BUSINESS<\/orgType>/a \\t<serviceUIConfig>\n\t\t<serviceHost>127.0.0.1<\/serviceHost>\n\t<\/serviceUIConfig>' /defaults/conf/default.service.xml && \
    # Add the javaMemoryHeapMax setting to the default service file.
    sed-patch '/<serviceUIConfig>/i\\t<javaMemoryHeapMax nil="true"/>' /defaults/conf/default.service.xml && \
    # Prevent automatic updates.
    rm -r /usr/local/crashplan/upgrade && \
    touch /usr/local/crashplan/upgrade && chmod 400 /usr/local/crashplan/upgrade && \
    # The configuration directory should be stored outside the container.
    ln -s /config/conf $TARGETDIR/conf && \
    # The cache directory should be stored outside the container.
    ln -s /config/cache $TARGETDIR/cache && \
    # The log directory should be stored outside the container.
    rm -r $TARGETDIR/log && \
    ln -s /config/log $TARGETDIR/log && \
    # The '/var/lib/crashplan' directory should be stored outside the container.
    ln -s /config/var /var/lib/crashplan && \
    # The '/repository' directory should be stored outside the container.
    # NOTE: The '/repository/metadata' directory changed in 6.7.0 changed to
    #       '/usr/local/crashplan/metadata' in 6.7.1.
    ln -s /config/repository/metadata /usr/local/crashplan/metadata

# Install YAD.
COPY --from=yad /tmp/yad-install/usr/bin/yad /usr/bin/

# Misc adjustments.
RUN  \
    # Remove the 'nobody' user.  This is to avoid issue when the container is
    # running under ID 65534.
    sed-patch '/^nobody:/d' /defaults/passwd && \
    sed-patch '/^nobody:/d' /defaults/group && \
    sed-patch '/^nobody:/d' /defaults/shadow && \
    # Clear stuff from /etc/fstab to avoid showing irrelevant devices in the open
    # file dialog window.
    echo > /etc/fstab && \
    # Save the current CrashPlan version.
    echo "${CRASHPLAN_VERSION}" > /defaults/cp_version

# Install dependencies.
RUN \
    add-pkg libselinux --repository http://dl-cdn.alpinelinux.org/alpine/edge/community && \
    add-pkg \
        # The following package is used to send key presses to the X process.
        xdotool \
        # For the monitor.
        bc

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="Code42">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="Code42">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Enable log monitoring.
RUN \
    sed-patch 's|LOG_FILES=|LOG_FILES=/config/log/service.log.0|' /etc/logmonitor/logmonitor.conf && \
    sed-patch 's|STATUS_FILES=|STATUS_FILES=/config/log/app.log|' /etc/logmonitor/logmonitor.conf

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/crashplan-pro-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV S6_WAIT_FOR_SERVICE_MAXTIME=10000 \
    APP_NAME="CrashPlan for Small Business" \
    KEEP_APP_RUNNING=1

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="crashplan-pro" \
      org.label-schema.description="Docker container for CrashPlan PRO" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-crashplan-pro" \
      org.label-schema.schema-version="1.0"
