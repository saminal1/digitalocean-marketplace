# CSMM for DigitalOcean Marketplace

A one click installer for CSMM on DigitalOcean marketplace.

## Software included

| Package                | Version   | License        |
|------------------------|-----------|----------------|
| [Docker CE][docker-ce] | `18.09.7` | [Apache 2][lic-apache-2] |

## Getting started

> @TODO

## Networking

To keep this Droplet secured, the UFW firewall is enabled. All ports are
BLOCKED except the following:

| Port   | Protocol | Service | Description                                                      |
|--------|----------|---------|------------------------------------------------------------------|
| `22`   | `tcp`    | ssh     | -                                                                |
| `80`   | `tcp`    | http    | -                                                                |
| `443`  | `tcp`    | https   | -                                                                |

## Developing

### Prerequisites

* [Packer](https://www.packer.io/)

## License

This project is open source software released under the [GNU General Public License, version 3 license][lic-gpl-v3].

[docker-ce]: https://docs.docker.com/release-notes/docker-ce/
[lic-apache-2]: https://github.com/docker/docker/blob/master/LICENSE
[lic-gpl-v3]: https://opensource.org/licenses/GPL-3.0
