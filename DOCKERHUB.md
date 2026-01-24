# Docker container for CrashPlan
[![Release](https://img.shields.io/github/release/jlesage/docker-crashplan-pro.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-crashplan-pro/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/crashplan-pro/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/crashplan-pro/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/crashplan-pro?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/crashplan-pro)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/crashplan-pro?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/crashplan-pro)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-crashplan-pro/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-crashplan-pro/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-crashplan-pro)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [CrashPlan](https://www.crashplan.com).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

This Docker container can be used with all CrashPlan products: Essential,
Professional, Enterprise, MSPs and Small Business (no longer sold).

> This Docker container is entirely unofficial and not made by the creators of
> CrashPlan.

---

[![CrashPlan logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/crashplan-pro-icon.png&w=110)](https://www.crashplan.com)[![CrashPlan](https://images.placeholders.dev/?width=288&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=CrashPlan&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.crashplan.com)

CrashPlan provides peace of mind through secure, scalable, and
straightforward endpoint data backup. We help organizations recover from
any worst-case scenario, whether it is a disaster, simple human error, a
stolen laptop, ransomware or an as-of-yet undiscovered calamity.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the CrashPlan docker container with the following command:
```shell
docker run -d \
    --name=crashplan-pro \
    -p 5800:5800 \
    -v /docker/appdata/crashplan-pro:/config:rw \
    -v /home/user:/storage:ro \
    jlesage/crashplan-pro
```

Where:

  - `/docker/appdata/crashplan-pro`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the CrashPlan GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-crashplan-pro.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-crashplan-pro/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
