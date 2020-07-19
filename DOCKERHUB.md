# Docker container for CrashPlan PRO
[![Docker Image Size](https://img.shields.io/microbadger/image-size/jlesage/crashplan-pro)](http://microbadger.com/#/images/jlesage/crashplan-pro) [![Build Status](https://drone.le-sage.com/api/badges/jlesage/docker-crashplan-pro/status.svg)](https://drone.le-sage.com/jlesage/docker-crashplan-pro) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-crashplan-pro.svg)](https://github.com/jlesage/docker-crashplan-pro/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage/0usd)

This is a Docker container for [CrashPlan PRO](https://www.crashplan.com/en-us/business/).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via any VNC client.

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

Browse to `http://your-host-ip:5800` to access the CrashPlan PRO GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-crashplan-pro.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-crashplan-pro/issues
