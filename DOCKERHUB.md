# Docker container for CrashPlan PRO
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/crashplan-pro/latest)](https://hub.docker.com/r/jlesage/crashplan-pro/tags) [![Build Status](https://github.com/jlesage/docker-crashplan-pro/actions/workflows/build-image.yml/badge.svg?branch=master)](https://github.com/jlesage/docker-crashplan-pro/actions/workflows/build-image.yml) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-crashplan-pro.svg)](https://github.com/jlesage/docker-crashplan-pro/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage)

This is a Docker container for [CrashPlan PRO](https://www.crashplan.com).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

---

[![CrashPlan PRO logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/crashplan-pro-icon.png&w=110)](https://www.crashplan.com)[![CrashPlan PRO](https://images.placeholders.dev/?width=416&height=110&fontFamily=Georgia,sans-serif&fontWeight=400&fontSize=52&text=CrashPlan%20PRO&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.crashplan.com)

CrashPlan offers the most comprehensive online backup solution to tens of
thousands of businesses around the world.  The highly secure, automatic and
continuous service provides customers the peace of mind that their digital life
is protected and easily accessible.

---

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

## Documentation

Full documentation is available at https://github.com/jlesage/docker-crashplan-pro.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-crashplan-pro/issues
