# Docker container for CrashPlan PRO
[![Release](https://img.shields.io/github/release/jlesage/docker-crashplan-pro.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-crashplan-pro/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/crashplan-pro/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/crashplan-pro/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/crashplan-pro?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/crashplan-pro)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/crashplan-pro?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/crashplan-pro)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-crashplan-pro/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-crashplan-pro/actions/workflows/build-image.yml)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This project implements a Docker container for [CrashPlan PRO](https://www.crashplan.com).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

---

[![CrashPlan PRO logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/crashplan-pro-icon.png&w=110)](https://www.crashplan.com)[![CrashPlan PRO](https://images.placeholders.dev/?width=416&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=CrashPlan%20PRO&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.crashplan.com)

CrashPlan offers the most comprehensive online backup solution to tens of
thousands of businesses around the world.  The highly secure, automatic and
continuous service provides customers the peace of mind that their digital life
is protected and easily accessible.

---

## Table of Content

   * [Quick Start](#quick-start)
   * [Usage](#usage)
      * [Environment Variables](#environment-variables)
         * [Deployment Considerations](#deployment-considerations)
      * [Data Volumes](#data-volumes)
      * [Ports](#ports)
      * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
   * [Docker Compose File](#docker-compose-file)
   * [Docker Image Versioning](#docker-image-versioning)
   * [Docker Image Update](#docker-image-update)
      * [Synology](#synology)
      * [unRAID](#unraid)
   * [User/Group IDs](#usergroup-ids)
   * [Accessing the GUI](#accessing-the-gui)
   * [Security](#security)
      * [SSVNC](#ssvnc)
      * [Certificates](#certificates)
      * [VNC Password](#vnc-password)
   * [Reverse Proxy](#reverse-proxy)
      * [Routing Based on Hostname](#routing-based-on-hostname)
      * [Routing Based on URL Path](#routing-based-on-url-path)
   * [Shell Access](#shell-access)
   * [Taking Over Existing Backup](#taking-over-existing-backup)
   * [Why CrashPlan Self Update Is Disabled](#why-crashplan-self-update-is-disabled)
   * [Troubleshooting](#troubleshooting)
      * [Crashes / Maximum Amount of Allocated Memory](#crashes--maximum-amount-of-allocated-memory)
      * [Inotify's Watch Limit](#inotifys-watch-limit)
         * [Synology](#synology-1)
      * [Empty /storage](#empty-storage)
      * [Device Status Is Waiting For Connection](#device-status-is-waiting-for-connection)
      * [Cannot Restore Files](#cannot-restore-files)
      * [Upgrade Failed Error Message](#upgrade-failed-error-message)
   * [Support or Contact](#support-or-contact)

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the CrashPlan PRO docker container with the following command:
```shell
docker run -d \
    --name=crashplan-pro \
    -p 5800:5800 \
    -v /docker/appdata/crashplan-pro:/config:rw \
    -v /home/user:/storage:ro \
    jlesage/crashplan-pro
```

Where:
  - `/docker/appdata/crashplan-pro`: This is where the application stores its configuration, states, log and any files needing persistency.
  - `/home/user`: This location contains files from your host that need to be accessible to the application.

Browse to `http://your-host-ip:5800` to access the CrashPlan PRO GUI.
Files from the host appear under the `/storage` folder in the container.

## Usage

```shell
docker run [-d] \
    --name=crashplan-pro \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    jlesage/crashplan-pro
```

| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in the background.  If not set, the container runs in the foreground. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`SUP_GROUP_IDS`| Comma-separated list of supplementary group IDs of the application. | (no value) |
|`UMASK`| Mask that controls how file permissions are set for newly created files. The value of the mask is in octal notation.  By default, the default umask value is `0022`, meaning that newly created files are readable by everyone, but only writable by the owner.  See the online umask calculator at http://wintelguy.com/umask-calc.pl. | `0022` |
|`LANG`| Set the [locale](https://en.wikipedia.org/wiki/Locale_(computer_software)), which defines the application's language, **if supported**.  Format of the locale is `language[_territory][.codeset]`, where language is an [ISO 639 language code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes), territory is an [ISO 3166 country code](https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes) and codeset is a character set, like `UTF-8`.  For example, Australian English using the UTF-8 encoding is `en_AU.UTF-8`. | `en_US.UTF-8` |
|`TZ`| [TimeZone](http://en.wikipedia.org/wiki/List_of_tz_database_time_zones) used by the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`KEEP_APP_RUNNING`| When set to `1`, the application will be automatically restarted when it crashes or terminates. | `0` |
|`APP_NICENESS`| Priority at which the application should run.  A niceness value of -20 is the highest priority and 19 is the lowest priority.  The default niceness value is 0.  **NOTE**: A negative niceness (priority increase) requires additional permissions.  In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | `0` |
|`INSTALL_PACKAGES`| Space-separated list of packages to install during the startup of the container.  Packages are installed from the repository of the Linux distribution this container is based on.  **ATTENTION**: Container functionality can be affected when installing a package that overrides existing container files (e.g. binaries). | (no value) |
|`CONTAINER_DEBUG`| Set to `1` to enable debug logging. | `0` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1920` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `1080` |
|`DARK_MODE`| When set to `1`, dark mode is enabled for the application. | `0` |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via a web browser or VNC client).  See the [Security](#security) section for more details. | `0` |
|`SECURE_CONNECTION_VNC_METHOD`| Method used to perform the secure VNC connection.  Possible values are `SSL` or `TLS`.  See the [Security](#security) section for more details. | `SSL` |
|`SECURE_CONNECTION_CERTS_CHECK_INTERVAL`| Interval, in seconds, at which the system verifies if web or VNC certificates have changed.  When a change is detected, the affected services are automatically restarted.  A value of `0` disables the check. | `60` |
|`WEB_LISTENING_PORT`| Port used by the web server to serve the UI of the application.  This port is used internally by the container and it is usually not required to be changed.  By default, a container is created with the default bridge network, meaning that, to be accessible, each internal container port must be mapped to an external port (using the `-p` or `--publish` argument).  However, if the container is created with another network type, changing the port used by the container might be useful to prevent conflict with other services/containers.  **NOTE**: a value of `-1` disables listening, meaning that the application's UI won't be accessible over HTTP/HTTPs. | `5800` |
|`VNC_LISTENING_PORT`| Port used by the VNC server to serve the UI of the application.  This port is used internally by the container and it is usually not required to be changed.  By default, a container is created with the default bridge network, meaning that, to be accessible, each internal container port must be mapped to an external port (using the `-p` or `--publish` argument).  However, if the container is created with another network type, changing the port used by the container might be useful to prevent conflict with other services/containers.  **NOTE**: a value of `-1` disables listening, meaning that the application's UI won't be accessible over VNC. | `5900` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Password](#vnc-password) section for more details. | (no value) |
|`ENABLE_CJK_FONT`| When set to `1`, open-source computer font `WenQuanYi Zen Hei` is installed.  This font contains a large range of Chinese/Japanese/Korean characters. | `0` |
|`CRASHPLAN_SRV_MAX_MEM`| Maximum amount of memory the CrashPlan Engine is allowed to use. One of the following memory unit (case insensitive) should be added as a suffix to the size: `G`, `M` or `K`.  By default, when this variable is not set, a maximum of 1024MB (`1024M`) of memory is allowed. **NOTE**: Setting this variable as the same effect as running the `java mx VALUE, restart` command from the CrashPlan command line. | `1024M` |

#### Deployment Considerations

Many tools used to manage Docker containers extract environment variables
defined by the Docker image and use them to create/deploy the container.  For
example, this is done by:
  - The Docker application on Synology NAS
  - The Container Station on QNAP NAS
  - Portainer
  - etc.

While this can be useful for the user to adjust the value of environment
variables to fit its needs, it can also be confusing and dangerous to keep all
of them.

A good practice is to set/keep only the variables that are needed for the
container to behave as desired in a specific setup.  If the value of variable is
kept to its default value, it means that it can be removed.  Keep in mind that
all variables are optional, meaning that none of them is required for the
container to start.

Removing environment variables that are not needed provides some advantages:

  - Prevents keeping variables that are no longer used by the container.  Over
    time, with image updates, some variables might be removed.
  - Allows the Docker image to change/fix a default value.  Again, with image
    updates, the default value of a variable might be changed to fix an issue,
    or to better support a new feature.
  - Prevents changes to a variable that might affect the correct function of
    the container.  Some undocumented variables, like `PATH` or `ENV`, are
    required to be exposed, but are not meant to be changed by users.  However,
    container management tools still show these variables to users.
  - There is a bug with the Container Station on QNAP and the Docker application
    on Synology, where an environment variable without value might not be
    allowed.  This behavior is wrong: it's absolutely fine to have a variable
    without value.  In fact, this container does have variables without value by
    default.  Thus, removing unneeded variables is a good way to prevent
    deployment issue on these devices.

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, states, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible to the application. |

### Ports

Here is the list of ports used by the container.

When using the default bridge network, ports can be mapped to the host via the
`-p` parameter (one per port mapping).  Each mapping is defined with the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number used inside
the container might not be changeable, but you are free to use any port on the
host side.

See the [Docker Container Networking](https://docs.docker.com/config/containers/container-networking)
documentation for more details.

| Port | Protocol | Mapping to host | Description |
|------|----------|-----------------|-------------|
| 5800 | TCP | Optional | Port to access the application's GUI via the web interface.  Mapping to the host is optional if access through the web interface is not wanted.  For a container not using the default bridge network, the port can be changed with the `WEB_LISTENING_PORT` environment variable. |
| 5900 | TCP | Optional | Port to access the application's GUI via the VNC protocol.  Mapping to the host is optional if access through the VNC protocol is not wanted.  For a container not using the default bridge network, the port can be changed with the `VNC_LISTENING_PORT` environment variable. |

### Changing Parameters of a Running Container

As can be seen, environment variables, volume and port mappings are all specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container.  The general idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```
docker stop crashplan-pro
```
  2. Remove the container:
```
docker rm crashplan-pro
```
  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

**NOTE**: Since all application's data is saved under the `/config` container
folder, destroying and re-creating a container is not a problem: nothing is lost
and the application comes back with the same state (as long as the mapping of
the `/config` folder remains the same).

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  crashplan-pro:
    image: jlesage/crashplan-pro
    ports:
      - "5800:5800"
    volumes:
      - "/docker/appdata/crashplan-pro:/config:rw"
      - "/home/user:/storage:ro"
```

## Docker Image Versioning

Each release of a Docker image is versioned.  Prior to october 2022, the
[semantic versioning](https://semver.org) was used as the versioning scheme.

Since then, versioning scheme changed to
[calendar versioning](https://calver.org).  The format used is `YY.MM.SEQUENCE`,
where:
  - `YY` is the zero-padded year (relative to year 2000).
  - `MM` is the zero-padded month.
  - `SEQUENCE` is the incremental release number within the month (first release
    is 1, second is 2, etc).

## Docker Image Update

Because features are added, issues are fixed, or simply because a new version
of the containerized application is integrated, the Docker image is regularly
updated.  Different methods can be used to update the Docker image.

The system used to run the container may have a built-in way to update
containers.  If so, this could be your primary way to update Docker images.

An other way is to have the image be automatically updated with [Watchtower].
Watchtower is a container-based solution for automating Docker image updates.
This is a "set and forget" type of solution: once a new image is available,
Watchtower will seamlessly perform the necessary steps to update the container.

Finally, the Docker image can be manually updated with these steps:

  1. Fetch the latest image:
```
docker pull jlesage/crashplan-pro
```
  2. Stop the container:
```
docker stop crashplan-pro
```
  3. Remove the container:
```
docker rm crashplan-pro
```
  4. Create and start the container using the `docker run` command, with the
the same parameters that were used when it was deployed initially.

[Watchtower]: https://github.com/containrrr/watchtower

### Synology

For owners of a Synology NAS, the following steps can be used to update a
container image.

  1.  Open the *Docker* application.
  2.  Click on *Registry* in the left pane.
  3.  In the search bar, type the name of the container (`jlesage/crashplan-pro`).
  4.  Select the image, click *Download* and then choose the `latest` tag.
  5.  Wait for the download to complete.  A  notification will appear once done.
  6.  Click on *Container* in the left pane.
  7.  Select your CrashPlan PRO container.
  8.  Stop it by clicking *Action*->*Stop*.
  9.  Clear the container by clicking *Action*->*Reset* (or *Action*->*Clear* if
      you don't have the latest *Docker* application).  This removes the
      container while keeping its configuration.
  10. Start the container again by clicking *Action*->*Start*. **NOTE**:  The
      container may temporarily disappear from the list while it is re-created.

### unRAID

For unRAID, a container image can be updated by following these steps:

  1. Select the *Docker* tab.
  2. Click the *Check for Updates* button at the bottom of the page.
  3. Click the *update ready* link of the container to be updated.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exist on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:

```
http://<HOST IP ADDR>:5800
```

  * Any VNC client:

```
<HOST IP ADDR>:5900
```

## Security

By default, access to the application's GUI is done over an unencrypted
connection (HTTP or VNC).

Secure connection can be enabled via the `SECURE_CONNECTION` environment
variable.  See the [Environment Variables](#environment-variables) section for
more details on how to set an environment variable.

When enabled, application's GUI is performed over an HTTPs connection when
accessed with a browser.  All HTTP accesses are automatically redirected to
HTTPs.

When using a VNC client, the VNC connection is performed over SSL.  Note that
few VNC clients support this method.  [SSVNC] is one of them.

[SSVNC]: http://www.karlrunge.com/x11vnc/ssvnc.html

### SSVNC

[SSVNC] is a VNC viewer that adds encryption security to VNC connections.

While the Linux version of [SSVNC] works well, the Windows version has some
issues.  At the time of writing, the latest version `1.0.30` is not functional,
as a connection fails with the following error:
```
ReadExact: Socket error while reading
```
However, for your convenience, an unofficial and working version is provided
here:

https://github.com/jlesage/docker-baseimage-gui/raw/master/tools/ssvnc_windows_only-1.0.30-r1.zip

The only difference with the official package is that the bundled version of
`stunnel` has been upgraded to version `5.49`, which fixes the connection
problems.

### Certificates

Here are the certificate files needed by the container.  By default, when they
are missing, self-signed certificates are generated and used.  All files have
PEM encoded, x509 certificates.

| Container Path                  | Purpose                    | Content |
|---------------------------------|----------------------------|---------|
|`/config/certs/vnc-server.pem`   |VNC connection encryption.  |VNC server's private key and certificate, bundled with any root and intermediate certificates.|
|`/config/certs/web-privkey.pem`  |HTTPs connection encryption.|Web server's private key.|
|`/config/certs/web-fullchain.pem`|HTTPs connection encryption.|Web server's certificate, bundled with any root and intermediate certificates.|

**NOTE**: To prevent any certificate validity warnings/errors from the browser
or VNC client, make sure to supply your own valid certificates.

**NOTE**: Certificate files are monitored and relevant daemons are automatically
restarted when changes are detected.

### VNC Password

To restrict access to your application, a password can be specified.  This can
be done via two methods:
  * By using the `VNC_PASSWORD` environment variable.
  * By creating a `.vncpass_clear` file at the root of the `/config` volume.
    This file should contain the password in clear-text.  During the container
    startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:
  * The type of communication channel (encrypted/unencrypted).
  * How secure the access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

**ATTENTION**: Password is limited to 8 characters.  This limitation comes from
the Remote Framebuffer Protocol [RFC](https://tools.ietf.org/html/rfc6143) (see
section [7.2.2](https://tools.ietf.org/html/rfc6143#section-7.2.2)).  Any
characters beyond the limit are ignored.

## Reverse Proxy

The following sections contain NGINX configurations that need to be added in
order to reverse proxy to this container.

A reverse proxy server can route HTTP requests based on the hostname or the URL
path.

### Routing Based on Hostname

In this scenario, each hostname is routed to a different application/container.

For example, let's say the reverse proxy server is running on the same machine
as this container.  The server would proxy all HTTP requests sent to
`crashplan-pro.domain.tld` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-crashplan-pro {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	server_name crashplan-pro.domain.tld;

	location / {
	        proxy_pass http://docker-crashplan-pro;
	}

	location /websockify {
		proxy_pass http://docker-crashplan-pro;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_read_timeout 86400;
	}
}

```

### Routing Based on URL Path

In this scenario, the hostname is the same, but different URL paths are used to
route to different applications/containers.

For example, let's say the reverse proxy server is running on the same machine
as this container.  The server would proxy all HTTP requests for
`server.domain.tld/crashplan-pro` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-crashplan-pro {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	location = /crashplan-pro {return 301 $scheme://$http_host/crashplan-pro/;}
	location /crashplan-pro/ {
		proxy_pass http://docker-crashplan-pro/;
		location /crashplan-pro/websockify {
			proxy_pass http://docker-crashplan-pro/websockify/;
			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection $connection_upgrade;
			proxy_read_timeout 86400;
		}
	}
}

```
## Shell Access

To get shell access to the running container, execute the following command:

```shell
docker exec -ti CONTAINER sh
```

Where `CONTAINER` is the ID or the name of the container used during its
creation.

## Taking Over Existing Backup

If this container is replacing a CrashPlan installation (from Linux, Windows,
MAC or another Docker container), your existing backup can be taken over to
avoid re-uploading all your data.

To proceed, make sure to carefully read the [official documentation].

Here is a summary of what needs to be done:
  1. Start CrashPlan Docker container.  Make sure the configuration directory
     is not mapped to a folder used by a different CrashPlan container.
  2. Sign in to your account.
  3. Click the **Replace Existing** button to start the wizard.
  4. Skip *Step 2 - File Transfer*.
  4. Once done with the wizard, go to your device's details and click
     *Manage Files*.  You will probably see missing items in the file
     selection.  This is normal, since path to your files may be different in
     the container.
  5. Update the file selection by re-adding your files.  **Do not unselect
     missing items yet**.
  6. Perform a backup.  Because of deduplication, files will not be uploaded
     again.
  7. Once the backup is terminated, you can remove missing items **if you
     don't care about file versions**.  Else, keep missing items.

**NOTE**: Don't be confused by the directory structure from your old being
visible in the *Manage Files* window.  By default, your files are now located
under the `/storage` folder.

[official documentation]: https://support.code42.com/hc/en-us/articles/14827668736279-Replace-your-device

## Why CrashPlan Self Update Is Disabled

One advantage of a Docker image is that it can be versioned and predictable,
meaning that a specific version of the image always behaves the same way.  So
if, for any reason, a new image version has a problem and doesn't work as
expected, it's easy for one to revert to the previous version and be back on
track.

Allowing CrashPlan to update itself obviously breaks this benefit.  Also, since
the container has only the minimal set of libraries and tools required to run
CrashPlan, it would be easy for an automatic update to break the container by
requiring new dependencies.  Finally, the automatic update script is not adapted
for Alpine Linux (the distribution on which this container is based on) and
assumes it is running on a full-featured distribution.  For example, this image
doesn't have a desktop like normal installations and some of the tools required
to perform the update are missing.

## Troubleshooting

### Crashes / Maximum Amount of Allocated Memory

If CrashPlan crashes unexpectedly with large backups, try to increase the
maximum amount of memory CrashPlan is allowed to use. This can be done by:

  1. Setting the `CRASHPLAN_SRV_MAX_MEM` environment variable.  See the
     [Environment Variables](#environment-variables) section for more details.
  2. Using the [solution provided by CrashPlan] from its support site.

[solution provided by CrashPlan]: https://support.code42.com/hc/en-us/articles/14827635282583-Adjust-Code42-agent-settings-for-memory-usage-with-large-backups

### Inotify's Watch Limit

If CrashPlan exceeds inotify's max watch limit, real-time file watching cannot
work properly and the inotify watch limit needs to be increased on the **host**,
not the container.

For more details, see the CrashPlan's [Linux real-time file watching errors]
article.

[Linux real-time file watching errors]: https://support.code42.com/hc/en-us/articles/14827708807959-Linux-real-time-file-watching-errors

#### Synology

On Synology NAS, the instructions provided by the article mentioned in the
previous section apply, except that the inotify's max watch limit must be set in
`/etc.defaults/sysctl.conf` (instead of `/etc/sysctl.conf`) to make the setting
permanent.

**NOTE**: After an upgrade of the DSM software, verify that the content of the
file has not been overwritten.

### Empty `/storage`

If the `/storage` folder inside the container is empty:

  - Make sure the folder is properly mapped to the host.  This is done via the
    `-v` parameter of the `docker run` command.  See the [Usage](#usage)
    section.
  - Make sure permissions and ownership of files on the host are correct and are
    compatible with the user under which the container application is running
    (defined by the `USER_ID` and `GROUP_ID` environment variables).  See the
    [User/Group IDs](#usergroup-ids) section.

NOTE: If running the application as root (`USER_ID=0` and `GROUP_ID=0`) makes
the files visible, it confirms that there is a permission issue.

### Device Status Is Waiting For Connection

If the status of your device is stuck on *Waiting for connection*, clearing the
the cache of CrashPlan can help resolve the issue:

  - Stop the container.
  - Remove all the content of the `cache` directory found under the container's
    configuration directory.  For example, if the `/config` folder of the
    container is mapped to `/docker/appdata/crashplan-pro` on the host, the
    following command (ran on the host) would clear the cache:
    ```
    rm -rf /docker/appdata/crashplan-pro/cache/*
    ```
  - Start the container.

### Cannot Restore Files

If CrashPlan fails to restore files, make sure the location where files are
restored have write permission.

A typical installation has the data to be backup under the `/storage` folder.
This folder is usually mapped to the host with *read-only* permission.  Thus,
restoring files to `/storage` won't be allowed.  The solution is to temporarily
change the permission of the volume to *read-write*.

For example, if `/storage` is mapped to `/home/user` on the host, the container
would need to be deleted and then re-created with the same arguments, with the
exception of `-v /home/user:/storage:ro` that is replaced with
`-v /home/user:/storage:rw`.

### Upgrade Failed Error Message

Because the CrashPlan's self-upgrade feature is disabled in this container, an
error message about failed upgrade can be seen when a new CrashPlan version is
released.

To fix this, [updating the container's image](#docker-image-update) to the
latest version will also bring the latest version of CrashPlan.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-crashplan-pro/issues
