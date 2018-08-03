# SIMP-METADATA Tool

The simp-metadata tool is a powerful multi-use tool that utilizes the simp-metadata database. This tool can perform
multiple actions, including searches, comparisons, downloads, and builds.

## Component Command

The `component` command is used with the following subcommands:
* view
* diff
* download
* build
* create(Permission restricted)
* update(Permission restricted)

Notes:
* All options require a setting, i.e `-v 6.2.0-RC1` to specify you want to use the 6.2.0-RC1 version of SIMP.
* By default, unless SIMP version is a required argument, it will default to use the latest, unstable component list.
* Versions are case sensitive, so `6.2.0-rc1` will not return results, you must enter `6.2.0-RC1`

***

#### Component View

The `simp-metadata component view` command is used to view the details of a specific component for a release.
All output from the `simp-metadata component view` command is formatted in hiera.

##### Syntax:

`simp-metadata component view [-v <release>] <component> [attribute]`

##### Examples:

###### Command:

`simp-metadata component view -v 6.1.0-0 puppet-grafana`

###### Output:

```
---
   component_type: puppet-module
   authoritative: 'false'
   asset_name: grafana
   extension: tgz
   module_name: grafana
   url: https://github.com/simp/puppet-grafana
   method: git
   extract: 'false'
   ref: 6d426d5ccc52ff23dbbcfc45290dafd224b5d2bc
   version: 6d426d5ccc52ff23dbbcfc45290dafd224b5d2bc
   release_source: simp-metadata
   component_source: simp-metadata
   location:
     extract: 'false'
     primary: 'true'
     method: git
     url: https://github.com/simp/puppet-grafana
```

###### Command: 

`simp-metadata component view -v 6.1.0-0 pupmod-simp-rsync version`

###### Output:

```
---
version: 6.0.2
```

***

#### Component Diff

The `simp-metadata component diff` command is used to view the difference between component attributes from one release
to another. This command is formatted without using `-v`(or unstable by default) to specify a release, but by using two
required arguments. An attribute can be specified, or the diff command will output all differences by default.
As with the previous command, the output is in hiera format.

##### Syntax:

`simp-metadata component diff <release 1> <release 2> <component> [attribute]`

##### Examples:

###### Command:

`simp-metadata component diff 6.1.0-0 6.2.0-RC1 pupmod-simp-rsyslog`

###### Output:

```
---
branch:
  original: ''
  changed: master
tag:
  original: 7.0.2
  changed: 7.2.0
ref:
  original: 14f0ef46df315121c0e136281ac124c57aaf7b91
  changed: 74d6139036748257e451db316189cfe117360eb4
version:
  original: 7.0.2
  changed: 7.2.0
```

###### Command:

`simp-metadata component diff 6.1.0-0 6.2.0-RC1 pupmod-simp-rsyslog version`

###### Output:

```
---
version:
  original: 7.0.2
  changed: 7.2.0
```

***

#### Component Download

The `simp-metadata component download` command is used to download a specified component from a release.

##### Syntax:

`simp-metadata component download [-v <release>] [-d <destination>] [-s <source>] component`

##### Examples:

###### Command:

`simp-metadata component download -v 6.2.0-RC1 -d ./rpms puppet-grafana`

###### Output:
```
Copied pupmod-puppet-grafana-4.1.1-0.noarch.rpm from https://download.simp-project.com/simp/yum/simp6/el/7/x86_64
simp-metadata@example> ls ./rpms
pupmod-puppet-grafana-4.1.1-0.noarch.rpm
```

***

#### Component Build

The `simp-metadata component build` command is used to build a specified RPM, based on the passed component name
and version.

##### Syntax:

`simp-metadata component build [-v <release>]`

##### Examples:

###### Command:

`simp-metadata component build -v 6.2.0-RC1 -d ./rpms puppet-grafana`

###### Output:
```
Cloning into 'source'...
remote: Counting objects: 483, done.
remote: Total 483 (delta 0), reused 0 (delta 0), pack-reused 483
Receiving objects: 100% (483/483), 111.81 KiB | 5.32 MiB/s, done.
Resolving deltas: 100% (219/219), done.
Note: checking out '6.0.6'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by performing another checkout.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -b with the checkout command again. Example:

  git checkout -b <new-branch-name>

HEAD is now at b3534c8... (SIMP-4951) travis.yml missing 'on:' tag in puppetforge deploy provider (#45)
RPM pupmod-simp-rsync-6.0.6-0.noarch.rpm built successfully
<simp-metadata@example> ls ./rpms
pupmod-puppet-grafana-4.1.1-0.noarch.rpm pupmod-simp-rsync-6.0.6-0.noarch.rpm
```

Any RPMs that are build will be unsigned, but contain all normal build info for SIMP:
```
simp-metadata@example> rpm -qpi pupmod-simp-rsync-6.0.6-0.noarch.rpm 
Name        : pupmod-simp-rsync
Version     : 6.0.6
Release     : 0
Architecture: noarch
Install Date: (not installed)
Group       : Applications/System
Size        : 84120
License     : Apache-2.0
Signature   : (none)
Source RPM  : pupmod-simp-rsync-6.0.6-0.src.rpm
Build Date  : Fri 31 Aug 2018 03:05:30 PM EDT
Relocations : usr/share/simp/modules 
Packager    : info@onyxpoint.com
Vendor      : Onyx Point, Inc
URL         : https://github.com/simp/pupmod-simp-rsync
Summary     : Rsync Puppet Module
Description :
manage and rsync server, secured by stunnel
```

***

#### Component Create (Permission required)

The `simp-metadata component create` command is used to create a new component in the releases .yaml in simp-metadata. 

##### Syntax:

`simp-metadata component create <component_name> name=<value>`

***

#### Component Update (Permission required)

The `simp-metadata component update` is used to update a specific attribute on a component.

##### Syntax:
`simp-metadata component update <component_name> <attribute> <value>`

***

## Release Command

The `release` command has the following optional subcommands:
* components
* diff
* puppetfile

#### Release

By default the release command will output a formatted list of components with the header 'components:' at the top
based on the release given.

##### Syntax:

`simp-metadata release [-v <release>]`

##### Example:

###### Command:

`simp-metadata release -v 6.2.0-RC1`

###### Output:

```
components:
    simp-metadata
    simp-core
    simp-doc
    pupmod-simp-rsync
    simp-rsync_skeleton
    simp-adapter
    simp-environment
    
...
```

***

#### Release Components

The `components` subcommand will remove the 'components:' leading line. This is to allow for easier use of piping
and variable assignment.

##### Syntax:

`simp-metadata release components [-v <release>]`

##### Example:

###### Command:

`simp-metadata release components -v 6.2.0-RC1`

###### Output:

```
simp-metadata
simp-core
simp-doc
pupmod-simp-rsync
simp-rsync_skeleton
simp-adapter
simp-environment

...
```

***

#### Release Diff

The `diff` subcommand is used to compare the difference between two releases. This has an optional `attribute` setting
to narrow down the diff, but by default will return all differences. As with some of the component subcommands,
the output is in hiera format.

##### Syntax:

`simp-metadata release diff <release 1> <release 2> [attribute]`

##### Examples:

###### Command:

`simp-metadata release diff 6.1.0-0 6.2.0-RC1`

###### Output:

```
---
pupmod-simp-site:
  branch:
    original: ''
    changed: master
  tag:
    original: 2.0.3
    changed: 2.0.4
  ref:
    original: 61327ae260572365cab6f778cd78f7769aa0d16e
    changed: 0ba070f208ce5965ff0e701d286df55ab6806fd6
  version:
    original: 2.0.3
    changed: 2.0.4
pupmod-simp-ssh:
  branch:
    original: ''
    changed: master
  tag:
    original: 6.1.0
    changed: 6.4.3
  ref:
    original: 2ff26a6690be2fdbd9e68210bcaf5f4cdc9088bc
    changed: 22a817680126e3ff9cd2497fbe6d3ebf92722730
  version:
    original: 6.1.0
    changed: 6.4.3

    ...
```

###### Command:

`simp-metadata release diff 6.1.0-0 6.2.0-RC1 version`

###### Output:

```
---
puppetlabs-apache:
  version:
    original: 1.11.0
    changed: 3.0.0
puppetlabs-concat:
  version:
    original: simp6.0.0-2.2.0
    changed: 4.1.1
puppetlabs-inifile:
  version:
    original: simp6.0.0-1.6.0
    changed: 2.2.0
puppetlabs-java:
  version:
    original: simp-1.6.0-post1
    changed: 2.4.0
puppetlabs-motd:
  version:
    original: simp6.0.0-1.4.0
    changed: 1.9.0
puppetlabs-mysql:
  version:
    original: simp6.0.0-3.10.0
    changed: 5.3.0
    
    ...
```

***

#### Release Puppetfile

The `puppetfile` subcommand is used to create a Puppetfile based on a releases .yaml file. This subcommand has an
optional `simp-core` argument that will format the Puppetfile for use with simp-core.

##### Syntax:

`simp-metadata release puppetfile [-v <release>] [simp-core]`

##### Examples:

###### Command:

`simp-metadata release -v 6.2.0-RC1 puppetfile simp-core > Puppetfile`

###### Result:

This will create a simp-core style Puppetfile with sections for moduledirs 'src', 'src/assets', and
'src/puppet/modules'.

```
moduledir 'src'

mod 'simp-doc',
  :git => 'https://github.com/simp/simp-doc',
  :ref => 'dfdd6a349526280922d5d81a82e743330c73dd38'

moduledir 'src/assets'

mod 'simp-rsync_skeleton',
  :git => 'https://github.com/simp/simp-rsync-skeleton',
  :ref => 'aaf439407429acd8a1f07d9f7505eb232a8bcd62'

mod 'simp-adapter',
  :git => 'https://github.com/simp/simp-adapter',
  :ref => 'c1cb4e2cc03bc9bed0f828d4bf30fcb46b540216'

mod 'simp-environment',
  :git => 'https://github.com/simp/simp-environment-skeleton',
  :ref => '86ffad13755cd6e5e97a4de683a1a1a967d50854'

...

moduledir 'src/puppet/modules'

mod 'simp-rsync',
  :git => 'https://github.com/simp/pupmod-simp-rsync',
  :ref => 'b3534c8eb35d9dd527e6459a54277feb8d614f80'

mod 'puppet-grafana',
  :git => 'https://github.com/simp/puppet-grafana',
  :ref => '9ccb9bbe66cb44118ebbc9f91ab2a5c99440dbe3'

mod 'camptocamp-kmod',
  :git => 'https://github.com/simp/puppet-kmod',
  :ref => '7c17b7dbc4fbf1f63f6bae197acdbab78f7f12fd'

mod 'elastic-elasticsearch',
  :git => 'https://github.com/simp/puppet-elasticsearch',
  :ref => '7d297e0002f1519e488620b7580963c80fe89f18'

...
```

###### Command:

`simp-metadata release -v 6.2.0-RC1 puppetfile > Puppetfile`

###### Output:

This will create a Puppetfile without the moduledir sections.

```
mod 'simp-rsync',
  :git => 'https://github.com/simp/pupmod-simp-rsync',
  :ref => 'b3534c8eb35d9dd527e6459a54277feb8d614f80'

mod 'puppet-grafana',
  :git => 'https://github.com/simp/puppet-grafana',
  :ref => '9ccb9bbe66cb44118ebbc9f91ab2a5c99440dbe3'

mod 'camptocamp-kmod',
  :git => 'https://github.com/simp/puppet-kmod',
  :ref => '7c17b7dbc4fbf1f63f6bae197acdbab78f7f12fd'

mod 'elastic-elasticsearch',
  :git => 'https://github.com/simp/puppet-elasticsearch',
  :ref => '7d297e0002f1519e488620b7580963c80fe89f18'

mod 'elastic-logstash',
  :git => 'https://github.com/simp/puppet-logstash',
  :ref => '212439a83fa900f0212095a84a420e49d9788fc7'

mod 'herculesteam-augeasproviders_apache',
  :git => 'https://github.com/simp/augeasproviders_apache',
  :ref => '4e9ff96f1fc919fb96e59d03a3180bcb70c9cf65'

mod 'herculesteam-augeasproviders_core',
  :git => 'https://github.com/simp/augeasproviders_core',
  :ref => '604680cb5fe7e32fd1ad1051fc34ef100a4d6923'

mod 'herculesteam-augeasproviders_grub',
  :git => 'https://github.com/simp/augeasproviders_grub',
  :ref => 'aa550a1b1df303eb2a07b80634f5e83b5ad718b8'

...
```
