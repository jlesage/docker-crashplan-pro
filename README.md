# Docker container for CrashPlan PRO
[![Docker Automated build](https://img.shields.io/docker/automated/jlesage/crashplan-pro.svg)](https://hub.docker.com/r/jlesage/crashplan-pro/) [![](https://images.microbadger.com/badges/image/jlesage/crashplan-pro.svg)](http://microbadger.com/#/images/jlesage/crashplan-pro "Get your own image badge on microbadger.com") [![Build Status](https://travis-ci.org/jlesage/docker-crashplan-pro.svg?branch=master)](https://travis-ci.org/jlesage/docker-crashplan-pro) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage)

This is a Docker container for CrashPlan PRO.

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on client side) or via any VNC client.

> **_IMPORTANT_**: This container can be used to migrate from *CrashPlan for 
> Home*.  Make sure to read the
> [Migrating From CrashPlan for Home](#migrating-from-crashplan-for-home)
> section for more details.

---

[![CrashPlan PRO logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/crashplan-pro-icon.png&w=200)](https://www.crashplan.com/en-us/business/)[![CrashPlan PRO](https://dummyimage.com/400x110/ffffff/575757&text=CrashPlan+PRO)](https://www.crashplan.com/en-us/business/)

CrashPlan offers the most comprehensive online backup solution to tens of
thousands of businesses around the world.  The highly secure, automatic and
continuous service provides customers the peace of mind that their digital life
is protected and easily accessible.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the CrashPlan PRO docker container with the following command:
```
docker run -d \
    --name=crashplan-pro \
    -p 5800:5800 \
    -v /docker/appdata/crashplan-pro:/config:rw \
    -v $HOME:/storage:ro \
    jlesage/crashplan-pro
```

Where:
  - `/docker/appdata/crashplan-pro`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.

Browse to `http://your-host-ip:5800` to access the CrashPlan PRO GUI.  Files from
the host appear under the `/storage` folder in the container.

## Usage

```
docker run [-d] \
    --name=crashplan-pro \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    jlesage/crashplan-pro
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in background.  If not set, the container runs in foreground. |
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
|`SUP_GROUP_IDS`| Comma-separated list of supplementary group IDs of the application. | (unset) |
|`UMASK`| Mask that controls how file permissions are set for newly created files. The value of the mask is in octal notation.  By default, this variable is not set and the default umask of `022` is used, meaning that newly created files are readable by everyone, but only writable by the owner. See the following online umask calculator: http://wintelguy.com/umask-calc.pl | (unset) |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`KEEP_APP_RUNNING`| When set to `1`, the application will be automatically restarted if it crashes or if user quits it. | `0` |
|`APP_NICENESS`| Priority at which the application should run.  A niceness value of -20 is the highest priority and 19 is the lowest priority.  By default, niceness is not set, meaning that the default niceness of 0 is used.  **NOTE**: A negative niceness (priority increase) requires additional permissions.  In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | (unset) |
|`CLEAN_TMP_DIR`| When set to `1`, all files in the `/tmp` directory are delete during the container startup. | `1` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1280` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `768` |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via web browser or VNC client).  See the [Security](#security) section for more details. | `0` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Password](#vnc-password) section for more details. | (unset) |
|`X11VNC_EXTRA_OPTS`| Extra options to pass to the x11vnc server running in the Docker container.  **WARNING**: For advanced users. Do not use unless you know what you are doing. | (unset) |
|`ENABLE_CJK_FONT`| When set to `1`, open source computer font `WenQuanYi Zen Hei` is installed.  This font contains a large range of Chinese/Japanese/Korean characters. | `0` |
|`CRASHPLAN_SRV_MAX_MEM`| Maximum amount of memory the CrashPlan Engine is allowed to use. One of the following memory unit (case insensitive) should be added as a suffix to the size: `G`, `M` or `K`.  By default, when this variable is not set, a maximum of 1024MB (`1024M`) of memory is allowed. | (unset) |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible by the application. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 5800 | Mandatory | Port used to access the application's GUI via the web interface. |
| 5900 | Optional | Port used to access the application's GUI via the VNC protocol.  Optional if no VNC client is used. |

## Docker Compose File
Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  crashplan-pro:
    build: .
    ports:
      - "5800:5800"
    volumes:
      - "/docker/appdata/crashplan-pro:/config:rw"
      - "$HOME:/storage:ro"
```

## Docker Image Update

If the system on which the container runs doesn't provide a way to easily update
the Docker image, the following steps can be followed:

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
  4. Start the container using the `docker run` command.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exists on the host.  This could prevent the host from properly accessing files
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
    This file should contains the password in clear-text.  During the container
    startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:
  * The type of communication channel (encrypted/unencrypted).
  * How secure access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

**ATTENTION**: Password is limited to 8 characters.  This limitation comes from
the Remote Framebuffer Protocol [RFC](https://tools.ietf.org/html/rfc6143) (see
section [7.2.2](https://tools.ietf.org/html/rfc6143#section-7.2.2)).  Any
characters beyhond the limit are ignored.

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
  4. Skip *Step 2 - File Transfert*.
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

## Migrating From CrashPlan for Home

*CrashPlan for Home* [being decommissioned], users using this version have the
choice to migrate their account to *CrashPlan PRO* (aka *CrashPlan for Small
Business*).  Thus, using this container becomes a great choice for these
users.

To perform the transition, you need to:
  - [Migrate your account].
  - If *CrashPlan for Home* installation is provided by the `jlesage/crashplan`
    Docker container:
    - Keep the configuration directory used by `jlesage/crashplan` container
      (i.e. the host directory mapped to `/config`).
    - Run this container by re-using the same configuration directory.  To do
      so, map the `/config` folder to the same host directory used by the
      `jlesage/crashplan` container.
  - Else, for all other installations (Windows, Linux, Mac, other Docker
    containers):
    - Start this container, by making sure the configuration directory is
      mapped to a new, empty host directory.
    - Follow instructions detailed in the
      [Taking Over Existing Backup](#taking-over-existing-backup) section.

## Troubleshooting

### Crashes / Maximum Amount of Allocated Memory

If CrashPlan crashes unexpectedly with large backups, try to increase the
maximum amount of memory CrashPlan is allowed to use. This can be done by:

  1. Setting the `CRASHPLAN_SRV_MAX_MEM` environment variable.  See the
     [Environment Variables](#environment-variables) section for more details.
  2. Using the [solution provided by CrashPlan] from its support site.

### Inotify's Watch Limit

If CrashPlan exceeds inotify's max watch limit, real-time file watching cannot
work properly and the inotify watch limit needs to be increased on the **host**.

For more details, see the CrashPlan's [Linux real-time file watching errors]
article.

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

For example, if `/storage` is mapped to `$HOME` on the host, the container would
need to be deleted and then re-created with the same arguments, with the exception
of `-v $HOME:/storage:ro` that is replaced with `-v $HOME:/storage:rw`.

[TimeZone]: http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
[official documentation]: https://support.code42.com/CrashPlan/6/Configuring/Replace_your_device
[solution provided by CrashPlan]: https://support.code42.com/CrashPlan/6/Troubleshooting/Adjust_Code42_app_settings_for_memory_usage_with_large_backups
[Linux real-time file watching errors]: https://support.code42.com/CrashPlan/4/Troubleshooting/Linux_real-time_file_watching_errors
[being decommissioned]: https://www.crashplan.com/en-us/consumer/nextsteps/
[Migrate your account]: https://crashplanpro.com/migration/?&_ga=2.236229060.497742288.1503424785-1699368865.1503424785#

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

[create a new issue]: https://github.com/jlesage/docker-crashplan-pro/issues
