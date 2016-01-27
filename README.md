puppet-control
==============
[![Travis](https://img.shields.io/travis/LandRegistry-Ops/puppet-control.svg?style=flat-square)](https://travis-ci.org/LandRegistry-Ops/puppet-control/)
[![Early development](https://img.shields.io/badge/status-early%20%20development-yellow.svg?style=flat-square)](#)
Control repository for Land Registry's beta project

## Requirements:
- Ruby >= 1.9.3
- Puppet >= 3.6.0 (may work with earlier builds but not tested)

## Puppet config

#### puppet.conf

The __puppet.conf__ file needs to be configured with __server__ and __environment__ variables.

_/etc/puppet/puppet.conf_
```
...
[agent]
environment = development
server = puppet-master-91.zone1.control.net
...
```
#### host.yaml

Puppet is configured to use fact information. The fact should be called __host.yaml__
and stored in __/etc/puppetlabs/facter/facts.d/__.

* __network_location__: The location on the network the server will reside (e.g. zone1, zone2)
* __puppet_role__: The hiera profile name that the machine will apply (e.g. migration-app)
* __server_type__: Similar to 'puppet_role' but specific to an environment.
* __application_environment__: The environment name of the application (e.g. production, pre-production)
* __hosting_platform__: The platform the code will be hosted on (e.g. aws, internal, vagrant)

_/etc/puppetlabs/facter/facts.d/host.yaml_
```
network_location: zone1
puppet_role: digital-register-frontend
server_type: drf-production
application_environment: production
hosting_platform: aws
```
