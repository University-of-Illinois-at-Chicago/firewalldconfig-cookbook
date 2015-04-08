firewalldconfig LWRP
====================
[![Build Status](https://travis-ci.org/...fixme...)][travis]
[![Cookboook Version](https://...fixme...)][cookbook]

[travis]: https://travis-ci.org/...fixme...
[cookbook]: https://supermarket.chef.io/cookbooks/firewalldconfig

[Firewalld](https://fedoraproject.org/wiki/FirewallD) is the userland interface to dynamically managing a Linux firewall, introduced in Fedora 15 and Centos/RHEL 7.

# Resource Overview

This `firewalldconfig` cookbook provides resources for managing your firewalld configurationg using chef node attributes. It can read the current permanent firewalld configuration and store it as node attributes or convert node attributes to firewalld configuration. The advantage of this approach is that it allows the node to be inspected to get an authorative report of its firewall configuration.

## config

The `filewalld_config` resource can push firewalld configuration from node attributes to firewalld or pull firewalld node attributes from firewalld configuration.

### Actions

* `:pull` - Set the node attributes to reflect the current permanent firewalld configuration.
* `:push` - Default. Configure firewalld configuration based on the firewalld node attributes.

### Attributes

FIXME

# Recipes

* default - installs and enables `firewalld`, pushes configuration.
* pull - installs and enables `firewalld`, pulls configuration.

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
Copyright 2015, Johnathan Kupferer

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
