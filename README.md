firewalldconfig LWRP
====================

[Firewalld](https://fedoraproject.org/wiki/FirewallD) the dynamic firewall
manager introduced in Fedora 15, Centos/RHEL 7, and Ubuntu 14.10.

# Resource Overview

This `firewalldconfig` cookbook provides resources for managing firewalld
configuration. This cookbook treats firewalld in the manner in which it is
designed, with zones and services as resources and source IPs, open ports,
etc. as state attributes on firewalld zones.

Other firewall configuration LWRPs treat open ports as resources. This is a
mistake because a port being open is only in firewalld is only meaningful in
relation to the source network traffic matched to the zone. Also, managing
individual ports as resources makes it quite difficult to write a recipe that
implements a firewall security policy for an organization.

To understand how to use this cookbook, the first step must be to understand
the design of firewalld. In short, firewalld is organized around zones. A
zone has incoming traffic matched to it by interface or source. Within a zone
there are allowed services and ports, with a service simply being a simple way
to refer to a list of ports. Firewall rich-rules add more specific behavior
within a zone such as to target particular hosts within the zone to be allowed
or denied access to a service.

In addition to the LWRP resources and providers, this cookbook provides recipes
that can save your node's firewalld configuration to your node attributes and
deploy your firewall configuration from node attributes. This allows you to
centrally audit or manage your firewall configurations through the node
attributes.

## default

The filewalldconfig default resource manages your main firewall configuration
in `firewalld.conf`.

### Actions

* `:create` - Create firewalld configuration with default options.
* `:create_if_missing` - Create firewalld configuration only if config is missing.
* `:merge` - Default. Configure firewalld configuration, using existing configuration for defaults.

### Attributes

* `file` - Name attribute. Configuration file name or path. You probably always want to specify "firewalld.conf"
* `cleanup_on_exit` - Remove firewall rules when firewalld stops. Sets firewalld `CleanupOnExit`. Boolean, default `true`.
* `default_zone` - Default Firewalld zone. Sets firewalld `DefaultZone`. String, default `public`.
* `ipv6_rpfilter` - Reverse path filter test on IPv6 packets. Sets firewalld `IPV6_rpfilter`. Boolean, default `true`.
* `lockdown` - Firewalld lockdown mode. Sets firewalld `Lockdown`. Boolean, default `false`.
* `minimal_mark` - Sets firewalld `MinimalMark`. Integer, default `100`.

## service

The filewalldconfig `service` resource manages firewalld service entries.
A service is simply a list of TCP/UDP network ports with a name and
description.

Please note that firewalld services have default settings stored in
`/usr/lib/firewalld/services` and configured values in
`/etc/firewalld/services`. This resource creates and deletes configurations,
but not the defaults provided by firewalld. So deleting a service will only
remove customizations if the service is also defined by a default.

### Actions

* `:create` - Default. Create firewalld service.
* `:create_if_missing` - Create firewalld service if not configured.
* `:delete` - Remove configuration for service.

### Attributes

* `:name` - Name attribute. Service name. String.
* `:description` - Service description. String.
* `:short` - Service short description. String.
* `:ports` - Ports included in service. Array of Strings of the form `portid[-portid]/protocol`.

## zone

The filewalldconfig `zone` resource manages firewalld zones. A zone consists
of `interfaces` and `sources` to match incoming traffic, `ports` and `services`
to permit designated traffic, and `rules` for rich-rule specifications to
implement more sophisiticated behavior. All of these zone features are
specified as arrays. Actions for zones provide capabilites to add and remove
features for a zone.

Please note that firewalld zones have default settings stored in
`/usr/lib/firewalld/zones` and configured values in
`/etc/firewalld/zones`. This resource creates and deletes configurations,
but not the defaults provided by firewalld. So deleting a zone will only
remove customizations if the service is also defined by a default.

### Actions

* `:create` - Create firewalld zone as specified.
* `:create_if_missing` - Create firewalld zone if not configured.
* `:delete` - Remove configuration for zone.
* `:filter` - Remove any features for a zone not explicitly listed.
* `:merge` - Default. Add listed features to zone.
* `:prune` - Remove listed features from zone.

### Attributes

* `:name` - Name attribute. Zone name. String.
* `:description` - Zone description. String.
* `:short` - Zone short description. String.
* `:interfaces` - Interfaces for matching incoming traffic to zone. Array of interfaces names.
* `:sources` - Sources for matching incoming traffic to zone. Array of IP address specifications.
* `:ports` - Ports allowed to zone. Array of Strings of the form `portid[-portid]/protocol`.
* `:rules` - Rich-rule specifications. Array of Hashes as described below.
* `:services` - Services allowed to zone. Array of service names.
* `:target` - Target for zone. May be one of `default`, `accept`, `drop`, or `reject`.

#### Rich-rule specification

_ATTENTION_ The rich-rule support for this LWRP is still evolving. While the
Hash syntax given below will be supported, it may also be desirable to support
the firewalld richlanguage directly. Also not all rich-rule functionality is
supported or tested yet.

* `:family` - String, `ipv4` or `ipv6`
* `:source` - String, IP address specification, requires family.
* `:source_invert` - If set to `true`, invert source matching.
* `:destination` - String, IP address specification, requires family.
* `:destination_invert` - If set to `true`, invert destination matching.
* `:service` - String, service name to match.
* `:port` - String, port specification to match, `portid[-portid]/protocol`.
* `:protocol` - String, protocol to match (see `/etc/protocols`).
* `:icmp_block` - String, icmp-block value. Not allowed with `:action`.
* `:masquerade` - If set to `true`, masuerade matched traffic. Not allowed with `:action`.
* `:forward_port` - Hash... FIXME: Not Implemented!
* `:log` - Hash... FIXME: Not Implemented
* `:audit` - Boolean. FIXME: Not Implemented
* `:action` - String, `accept`, `reject`, `drop`.
* `:reject_with` - Rejection type. See `iptables-extensions(8)`.

# Recipes

* `default` - Installs and enables `firewalld`.
* `deploy_from_node_attributes` - Installs, enables, and configures `firewalld` from node attributes.
* `record` - Records firewalld configuration to node attributes.

# Usage

If you're using [Berkshelf](http://berkshelf.com/), just add `firewalldconfig` to your
`Berksfile` and `metadata.rb`:

```ruby
# Berksfile
cookbook 'firewalldconfig'

# metadata.rb
depends 'firewalldconfig'
```

Contributing
------------
1. Fork the project
2. Create a feature branch corresponding to you change
3. Commit and test thoroughly
4. Create a Pull Request on github


License & Authors
-----------------
- Author:: Johnathan Kupferer <jtk@uic.edu>

```text
Copyright 2015, The University of Illinois at Chicago

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
