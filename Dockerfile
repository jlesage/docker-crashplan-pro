#
# crashplan-pro Dockerfile
#
# https://github.com/jlesage/docker-crashplan-pro
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG CRASHPLAN_VERSION=11.4.0
ARG CRASHPLAN_BUILD=503

# Define software download URLs.
ARG CRASHPLAN_URL=https://download.crashplan.com/installs/agent/cloud/${CRASHPLAN_VERSION}/${CRASHPLAN_BUILD}/install/CrashPlan_${CRASHPLAN_VERSION}_${CRASHPLAN_BUILD}_Linux.tgz

# Build CrashPlan.
FROM ubuntu:22.04 AS crashplan
ARG CRASHPLAN_URL
WORKDIR /tmp
COPY src/crashplan /build
RUN /build/build.sh "${CRASHPLAN_URL}"

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.16-v4.6.4

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
    sed-patch '/<\/serviceBackupConfig>/a \\t<serviceUIConfig>\n\t\t<serviceHost>127.0.0.1<\/serviceHost>\n\t<\/serviceUIConfig>' /defaults/conf/default.service.xml && \
    # Add the javaMemoryHeapMax setting to the default service file.
    #sed-patch '/<serviceUIConfig>/i\\t<javaMemoryHeapMax nil="true"/>' /defaults/conf/default.service.xml && \
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
    # NOTE: The '/repository/metadata' directory in 6.7.0 changed to
    #       '/usr/local/crashplan/metadata' in 6.7.1.
    ln -s /config/repository/metadata /usr/local/crashplan/metadata

# Misc adjustments.
RUN  \
    # Clear stuff from /etc/fstab to avoid showing irrelevant devices in the open
    # file dialog window.
    echo > /etc/fstab && \
    # Save the current CrashPlan version.
    echo "${CRASHPLAN_VERSION}" > /defaults/cp_version

# Install dependencies.
RUN \
    add-pkg \
        # For the login.
        curl \
        jq \
        # For the monitor.
        bc

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/crashplan-pro-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "CrashPlan" && \
    set-cont-env APP_VERSION "$CRASHPLAN_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Set public environment variables.
ENV \
    CRASHPLAN_SRV_MAX_MEM=1024M

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
    org.label-schema.name="crashplan-pro" \
    org.label-schema.description="Docker container for CrashPlan" \
    org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
    org.label-schema.vcs-url="https://github.com/jlesage/docker-crashplan-pro" \
    org.label-schema.schema-version="1.0"
