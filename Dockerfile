#
# crashplan Dockerfile
#
# https://github.com/jlesage/docker-crashplan
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-glibc-v3.1.3

# Define software versions.
ARG CRASHPLANPRO_VERSION=4.9.0_1436674888490_33

# Define software download URLs.
ARG CRASHPLANPRO_URL=https://web-lbm-msp.crashplanpro.com/client/installers/CrashPlanPRO_${CRASHPLANPRO_VERSION}_Linux.tgz

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
    # Keep a copy of the default config.
    mv ${TARGETDIR}/conf /defaults/conf && \
    cp crashplan-install/scripts/run.conf /defaults/ && \
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
    # Download and install the JRE.
    echo "Installing JRE..." && \
    source crashplan-install/install.defaults && \
    curl -# -L ${JRE_X64_DOWNLOAD_URL} | tar -xz -C ${TARGETDIR} && \
    chown -R root:root ${TARGETDIR}/jre && \
    # Cleanup
    del-pkg build-dependencies && \
    rm -rf /tmp/*

# Install dependencies.
RUN \
    add-pkg \
        gtk+2.0 \
        # For the monitor.
        yad \
        bc

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" class="CrashPlan PRO">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" class="CrashPlan PRO">/a \    <layer>below</layer>' \
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
ENV S6_WAIT_FOR_SERVICE_MAXTIME=9000 \
    APP_NAME="CrashPlan PRO" \
    KEEP_GUIAPP_RUNNING=1 \
    CRASHPLAN_DIR=${TARGETDIR} \
    JAVACOMMON="${TARGETDIR}/jre/bin/java"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Expose ports.
#   - 4243: Connection to the CrashPlan service.
EXPOSE 4243

# Metadata.
LABEL \
      org.label-schema.name="crashplan-pro" \
      org.label-schema.description="Docker container for CrashPlan PRO" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-crashplan-pro" \
      org.label-schema.schema-version="1.0"
