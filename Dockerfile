#
# crashplan Dockerfile
#
# https://github.com/jlesage/docker-crashplan
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-glibc-v3.3.0

# Define software versions.
ARG CRASHPLANPRO_VERSION=6.6.0
ARG CRASHPLANPRO_VERSION_SUFFIX=1506661200660_4347

# Define software download URLs.
#ARG CRASHPLANPRO_URL=https://web-lbm-msp.crashplanpro.com/client/installers/CrashPlanSmb_${CRASHPLANPRO_VERSION}_${CRASHPLANPRO_VERSION_SUFFIX}_Linux.tgz
ARG CRASHPLANPRO_URL=https://raw.githubusercontent.com/jlesage/docker-crashplan-pro/master/vendor/CrashPlanSmb_${CRASHPLANPRO_VERSION}_${CRASHPLANPRO_VERSION_SUFFIX}_Linux.tgz

# Define container build variables.
ARG TARGETDIR=/usr/local/crashplan

# Define working directory.
WORKDIR /tmp

# Install CrashPlan.
RUN \
    add-pkg --virtual build-dependencies cpio curl && \
    echo "Installing CrashPlan PRO..." && \
    # Download CrashPlan.
    curl -# -L ${CRASHPLANPRO_URL} | tar -xz && \
    mkdir -p ${TARGETDIR} && \
    # Extract CrashPlan.
    cat $(ls crashplan-install/*.cpi) | gzip -d -c - | cpio -i --no-preserve-owner --directory=${TARGETDIR} && \
    mv "${TARGETDIR}"/*.asar "${TARGETDIR}/electron/resources" && \
    chmod 755 "${TARGETDIR}/electron/crashplan" && \
    # Keep a copy of the default config.
    mv ${TARGETDIR}/conf /defaults/conf && \
    cp crashplan-install/scripts/run.conf /defaults/ && \
    # Make sure the UI connects by default to the engine using the loopback IP address (127.0.0.1).
    sed-patch '/<orgType>BUSINESS<\/orgType>/a \\t<serviceUIConfig>\n\t\t<serviceHost>127.0.0.1<\/serviceHost>\n\t<\/serviceUIConfig>' /defaults/conf/default.service.xml && \
    # Set manifest directory to default config.  It should not be used, but do
    # like the install script.
    sed-patch "s|<backupConfig>|<backupConfig>\n\t\t\t<manifestPath>/usr/local/var/crashplan</manifestPath>|g" /defaults/conf/default.service.xml && \
    mkdir -p /usr/local/var/crashplan && \
    # Prevent automatic updates.
    rm -r /usr/local/crashplan/upgrade && \
    touch /usr/local/crashplan/upgrade && chmod 400 /usr/local/crashplan/upgrade && \
    # The configuration directory should be stored outside the container.
    ln -s /config/conf $TARGETDIR/conf && \
    # The run.conf file should be stored outside the container.
    ln -s /config/bin/run.conf $TARGETDIR/bin/run.conf && \
    # The cache directory should be stored outside the container.
    ln -s /config/cache $TARGETDIR/cache && \
    # The log directory should be stored outside the container.
    rm -r $TARGETDIR/log && \
    ln -s /config/log $TARGETDIR/log && \
    # The '/var/lib/crashplan' directory should be stored outside the container.
    ln -s /config/var /var/lib/crashplan && \
    # The '/repository' directory should be stored outside the container.
    ln -s /config/repository /repository && \
    # Download and install the JRE.
    echo "Installing JRE..." && \
    source crashplan-install/install.defaults && \
    curl -# -L ${JRE_X64_DOWNLOAD_URL} | tar -xz -C ${TARGETDIR} && \
    chown -R root:root ${TARGETDIR}/jre && \
    # Cleanup
    del-pkg build-dependencies && \
    rm -rf /tmp/*

# Misc adjustments.
RUN  \
    # Clear stuff from /etc/fstab to avoid showing irrelevant devices in the open
    # file dialog window.
    echo > /etc/fstab && \
    # CrashPlan requires the machine-id to be the same to avoid re-login.
    ln -s /config/machine-id /etc/machine-id && \
    # Save the current CrashPlan version.
    echo "${CRASHPLANPRO_VERSION}" > /defaults/cp_version

# Install dependencies.
RUN \
    echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    add-pkg \
        gtk+2.0 \
        libxscrnsaver \
        nss \
        eudev \
        gconf \
        libselinux@edge \
        # For the monitor.
        yad \
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

# Temporary fix for glibc cache not being updated automatically.
RUN /usr/glibc-compat/sbin/ldconfig

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV S6_WAIT_FOR_SERVICE_MAXTIME=10000 \
    APP_NAME="CrashPlan for Small Business" \
    KEEP_GUIAPP_RUNNING=1 \
    CRASHPLAN_DIR=${TARGETDIR} \
    JAVACOMMON="${TARGETDIR}/jre/bin/java"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="crashplan-pro" \
      org.label-schema.description="Docker container for CrashPlan PRO" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-crashplan-pro" \
      org.label-schema.schema-version="1.0"
