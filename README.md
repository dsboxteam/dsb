
> We apologize for the unreadable text in some README sections. The text is in the process of translation from the Google Translate to the human language :).

Dsb
===

Dsb is a wrapper application for
[Docker Compose](https://docs.docker.com/compose/).
It provides a more user-friendly interface for accessing containers
while developing software and simplifies the use of containerized applications
in a local or cloud virtual machine environment. 
Dsb does not replace or hide the Docker Compose interface,
it's just a convenient addition.

To use Dsb it is necessary to be familiar with Docker Compose
and have a basic knowledge of shell scripting
([Bash or Bourne Shell](https://tldp.org/LDP/abs/html/index.html)).

Supported operating systems: Linux and macOS (the later in testing mode).

Dsb is compatible with all Docker images - no rebuilding
of images is required.
Container management (startup, shutdown, configuration, etc.) is performed
via a simplified subcommands of the [`dsb`](#dsb-utility) utility.
To access the full range of
[`docker-compose`](https://docs.docker.com/compose/reference/)
features the [`dsb compose`](#dsb-compose) subcommand can be used.

There are two main subcommands to work with containers in CLI mode:
[`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root).
The `dsb sh` subcommand performs container operations with permissions of the
host user.
The `dsb root` subcommand provides access to containers in root mode.
When [switching to the container](#execute-commands-in-containers),
current working directory and full file paths in subcommand parameters
are mapped to the corresponding container's paths
(if such a mapping is possible).

To be more convenient, Dsb supports the execution of commands in containers
via special [host scripts](#host-scripts) which are called identically
to the original commands - just under a different name.
This allows you to run commands in containers almost as if they were present
directly in the host system, and provides seamless integration with IDE settings.
The repository contains a set of ready-made host scripts
for typical developer commands (see `host-scripts` subdirectory).
This set can be easily extended by yourself - each script consists
of a couple of self-evident lines of code.

---

Contents:
---------

* [User guide](#user-guide)
    * [Terms](#terms)
    * [Installation](#installation)
        * [Prerequisites on Linux](#prerequisites-on-linux)
        * [Prerequisites on macOS](#prerequisites-on-macos)
        * [Install Dsb](#install-dsb)
    * [Getting started](#getting-started)
    * [Dsb project structure](#dsb-project-structure)
        * [`.dsb` directory](#dsb-directory)
        * [`.dsbenv` file](#dsbenv-file)
        * [Yaml files](#yaml-files)
        * [Mounted directories](#mounted-directories)
    * [`dsb` utility](#dsb-utility)
        * [Service management](#service-management)
        * [Custom subcommands](#custom-subcommands)
        * [Execute commands in containers](#execute-commands-in-containers)
            * [Set current directory in a container](#set-current-directory-in-a-container)
            * [Convert file paths in parameters](#convert-file-paths-in-parameters)
            * [Setting up a profile in a container](#setting-up-a-profile-in-a-container)
            * [Setting `umask`](#setting-umask)
        * [`dsbuser` account](#dsbuser-account)
        * [Container indexes](#container-indexes)
    * [Network access to the host system from containers](#network-access-to-the-host-system-from-containers)
    * [Host scripts](#host-scripts)
        * [Service aliases](#service-aliases)
    * [Removing a Dsb project from the host system](#removing-a-dsb-project-from-the-host-system)
* [Reference](#reference)
    * [`dsb` utility subcommands](#dsb-utility-subcommands)
        * [`dsb cid`](#dsb-cid)
        * [`dsb clean`, `dsb clean-...`](#dsb-clean-dsb-clean-)
        * [`dsb clean-vols`](#dsb-clean-vols)
        * [`dsb compose`](#dsb-compose)
        * [`dsb down`](#dsb-down)
        * [`dsb down-all`](#dsb-down-all)
        * [`dsb init`](#dsb-init)
        * [`dsb ip`](#dsb-ip)
        * [`dsb logs`](#dsb-logs)
        * [`dsb ps`](#dsb-ps)
        * [`dsb restart`](#dsb-restart)
        * [`dsb root`](#dsb-root)
        * [`dsb scale`](#dsb-scale)
        * [`dsb sh`](#dsb-sh)
        * [`dsb start`](#dsb-start)
        * [`dsb stop`](#dsb-stop)
        * [`dsb var`](#dsb-var)
        * [`dsb vols`](#dsb-vols)
        * [`dsb yaml`](#dsb-yaml)
    * [Dsb environment variables](#dsb-environment-variables)
        * [Base Dsb variables](#base-dsb-variables)
        * [`.dsbenv` file variables](#dsbenv-file-variables)
            * [`COMPOSE_FILE`](#compose_file)
            * [`COMPOSE_...`, `DOCKER_...`](#compose_-docker_)
            * [`DSB_COMPOSE_FILE_VERSION`](#dsb_compose_file_version)
            * [`DSB_HOME_VOLUMES`](#dsb_home_volumes)
            * [`DSB_PROD_MODE`](#dsb_prod_mode)
            * [`DSB_PROJECT_ID`](#dsb_project_id)
            * [`DSB_SERVICE_...`](#dsb_service_)
            * [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout)
            * [`DSB_SPACE`](#dsb_space)
            * [`DSB_UMASK_ROOT`](#dsb_umask_root)
            * [`DSB_UMASK_SH`](#dsb_umask_sh)
        * [Variables available in yaml files](#variables-available-in-yaml-files)
        * [Variables available in host scripts](#variables-available-in-host-scripts)
    * [Functions available in host scripts](#functions-available-in-host-scripts)
        * [`dsb_docker_compose`](#dsb_docker_compose)
        * [`dsb_map_env`](#dsb_map_env)
        * [`dsb_resolve_files`](#dsb_resolve_files)
        * [`dsb_run_as_root`](#dsb_run_as_root)
        * [`dsb_run_as_user`](#dsb_run_as_user)
        * [`dsb_set_box`](#dsb_set_box)
        * [`dsb_get_container_id`](#dsb_get_container_id)
        * [`dsb_set_single_box`](#dsb_set_single_box)
        * [`dsb_...message`](#dsb_message)
* [Firewall configuration on Linux](#host-system-firewall-configuration)

---

User guide
==========

Terms
-----

* __Host system__ - operating system (OS) where Dsb is used.

* __Host user__ - OS account under which Dsb is running.

* __Service__ - in Docker Compose this term corresponds to
a single container or a group of containers that have a common named
[configuration](https://docs.docker.com/compose/compose-file/#the-compose-application-model).
In Dsb such a configuration is usually prepared as a separate [yaml file](#yaml-files).
The term __service__ hereafter can be treated simply as a synonym for the term __container__,
unless we are talking about [scaled services](#dsb-scale).  
See: [Compose specification:](https://docs.docker.com/compose/compose-file/)
[Services top-level element](https://docs.docker.com/compose/compose-file/#services-top-level-element)

* __Scaled service__ is a __service__ with multiple containers.
Scaling is performed via [`dsb scale`](#dsb-scale) subcommand.

* __Dsb project__ is a
[Docker Compose project](https://docs.docker.com/compose/#multiple-isolated-environments-on-a-single-host)
extended with Dsb configuration data.
Each Dsb project is bound to a certain directory in the host filesystem,
which is further referred to as the __Dsb root directory__.
This term is similar to terms like _Vagrant project_ or _Git repository_.  
See: [Dsb project structure](#dsb-project-structure)

* __Dsb root directory__ is a directory that contains the __`.dsb`__ subdirectory
with the project configuration and one or more subdirectories used as __mounted directories__.
This directory itself can also be __mounted directory__.
The root directories of different Dsb projects must not overlap.  
See: [Dsb project structure](#dsb-project-structure)

* __Mounted directory__ is a directory of the host filesystem,
that is accessible to one or more __services__ (containers) via
[bind mounts](https://docs.docker.com/storage/bind-mounts/).
It contains user's data to be processed in the the containers
(for example, source code). When working in CLI mode
the current working directory must be within the mounted directories
to run [`dsb sh`](#dsb-sh), [`dsb root`](#dsb-root)
or [host scripts](#host-scripts).  
See: 
[Mounted directories](#mounted-directories),
[Executing commands in containers](#execute-commands-in-containers)

* __.dsb__ is a child subdirectory of the __Dsb root directory__.
It contains configuration files of the Dsb project
and internal persistent data used or generated by containers
(log files, database files, and etc).
This directory is created and initialized by executing 
[`dsb init`](#dsb-init) subcommand.  
See: [.dsb directory](#dsb-directory)

* __.dsbenv__ is a [Bash](https://tldp.org/LDP/abs/html/variables.html) source file
that contains [Dsb config variables](#dsbenv-file-variables)
and [Compose environment variables](https://docs.docker.com/compose/reference/envvars/).
This file is located in the `.dsb/compose` subdirectory.  
See: [.dsbenv file](#dsbenv-file)

* __yaml file__ is Docker Compose configuration file located
in the `.dsb/compose` subdirectory.
In Dsb, the configuration of each __service__ is stored in a separate yaml file.
The list of the active yaml files is placed in the
[`COMPOSE_FILE`](https://docs.docker.com/compose/reference/envvars/#compose_file)
variable of the [`.dsbenv`](#dsbenv-file) file.  
To simplify the creation of yaml files, the [`dsb yaml`](#dsb-yaml) subcommand is provided.

* __dsbuser__ is a container's internal account that has the same UID and GID
as the host user account.
This internal account is created when container is started.
Creation is performed by a small bootstrap script added to yaml files as
[entrypoint](https://docs.docker.com/compose/compose-file/compose-file-v3/#entrypoint)
element (see [`dsb yaml`](#dsb-yaml)).
This ensures that [`dsb sh`](#dsb-sh) and [host scripts](#host-scripts)
have full access to the __mounted directories__.  
See: [`dsbuser` account](#dsbuser-account)

* __Host script__ is an executable Bash script containing shebang string
`#!/usr/bin/env dsb-script` and several calls to functions
defined in the `lib/dsblib.bash` source file.  
See: [Host scripts](#host-scripts)


Installation
------------

### Prerequisites on Linux

Bash (4.4+),
[Docker Engine](https://docs.docker.com/engine/install/) and
[Docker Compose](https://docs.docker.com/compose/install/) (1.24.0+)
must be installed on the host system.

The host system must also have the following commands: cp, cut, env, find,
id, ls, md5sum, readlink (greadlink on macOS), rm.
On Linux distributions the necessary packages are usually installed by default.
Missing packages can be installed later if the `dsb` command displays
the corresponding diagnostic messages.

After installing the packages create a `docker` group
on the host system and add your user to the `docker` group:

    $ sudo groupadd docker
    $ sudo usermod -a -G docker <login>

Set appropriate MTU value in the `/etc/docker/daemon.json`.
Example:

    {
        "mtu": 1450
    }

> Creating / editing `/etc/docker/daemon.json` is performed in root mode.

The set mtu-parameter value will be used by default
in new Dsb projects initialized by [`dsb init`](#dsb-init) subcommand.
The value will be present in the configuration file
`.dsb/compose/globals.yaml` (see [Yaml files](#yaml-files)).

After setting the mtu parameter reboot the host system.

> When using ready-made Dsb configurations, you should
manually correct the MTU value
in the `.dsb/compose/globals.yaml` file.

Firewall recommendations:
[Firewall configuration on Linux](#host-system-firewall-configuration).

### Prerequisites on macOS

NOTE: Dsb was not tested on macOS.
For the trial use, in addition to the requirements of the previous section
you must do the following:

* Install [Homebrew](https://brew.sh/) package manager.
* Install the latest version of the Bash (`brew install bash`)
and the GNU coreutils (`brew install coreutils`).
* [Configure](https://docs.docker.com/config/daemon/#configure-the-docker-daemon)
MTU value for Docker daemon.

### Install Dsb

This git repository also acts as an installation package.

Place the contents of the repository in any suitable location on the host system.
Using the repository requires only read and execute access
for the scripts from the `bin` and `host-scripts` subdirectories. Access to content
registration is not required.

Set the `PATH` variable to include the full path of the `bin` subdirectories
and `host-scripts`. To do this, add the following line to the end of the `~/.profile` file:

    export PATH=<dsb_repository>/bin:<dsb_repository>/host-scripts:$PATH

Alternatively, you can set symbolic links to scripts,
contained in the `bin` and `host-scripts` subdirectories in some system
or a local directory already present in the PATH variable.

If the set of [host scripts](#host-scripts) is planned to be supplemented and modified,
they can be moved to any other directory,
by including its path in the PATH variable instead of the `host-scripts` subdirectory.

Download the busybox docker helper image (any version):

    $ docker pull busybox:latest

(used in subcommands
[`dsb clean-vols`](#dsb-clean-vols) and other
[`dsb clean-...`](#dsb-clean-dsb-clean-) subcommands)

Log in again for the new value of the `PATH` variable to take effect.

Run the `dsb` command with no options to check if the installation was successful
(output list of subcommands):

    $dsb


Getting started
---------------

To get started with Dsb let's create from scratch a new Dsb project
for the Docker image `python:alpine3.15`.
This example demonstrates how you can conveniently use Docker image software in a host system.

Create the project:

    $ docker pull python:alpine3.15
    $ mkdir "$HOME/dsbexample"
    $ cd "$HOME/dsbexample"
    $ dsb init
    $ dsb yaml py python:alpine3.15
    $ mkdir src
    $ echo 'print("Hello from the Container!")' > src/hello.py

Here:

* `mkdir "$HOME/dsbexample"` creates [Dsb root directory](#terms) for the project.
* [`dsb init`](#dsb-init) creates a [`.dsb`](#dsb-directory) subdirectory
and fills it with configuration template (see `lib/init` subdirectory in this git repository).
* `dsb yaml py python:alpine3.15` generates the file `.dsb/compose/py.yaml`
with Compose service configuration for `python:alpine3.15` image.  `py`.
* The last two commands create a test case in the `src` subdirectory
Python programs.

Add the `py.yaml` file to the configuration variable [`COMPOSE_FILE`](#compose_file),
contained in the `.dsb/compose/.dsbenv` file:

    COMPOSE_FILE="globals.yaml:py.yaml"

We got a project with a single `py` service configuration.

We already have [host scripts](#host-scripts) `dsbpython`, `dsbpython2` and `dsbpython3` to run
appropriate commands in the context of containers. Scripts are configured by default
to services named `python`, `python2` and `python3`, so change the settings
in file `.dsb/compose/.dsbenv`:

    DSB_SERVICE_PYTHON=py
    DSB_SERVICE_PYTHON2=py
    DSB_SERVICE_PYTHON3=py
    
> [Host scripts](#host-scripts) is just a compact and familiar way to call commands,
tied in the project to specific containers.

Let's start the project services and check their status:

    $ dsb start
    Starting dsb ...
    docker-compose --project-name dsb-ae56c7e9c5561d254de7fcddbea3c70c up --detach --remove-orphans
    Creating network "dsb-ae56c7e9c5561d254de7fcddbea3c70c_dsbnet" with driver "bridge"
    Creating dsb-ae56c7e9c5561d254de7fcddbea3c70c_py_1 ... done

    $ dsb ps
    docker-compose --project-name dsb-ae56c7e9c5561d254de7fcddbea3c70c ps
                        Name                                 Command        State  Ports
    -------------------------------------------------- ------------------------------------
    dsb-ae56c7e9c5561d254de7fcddbea3c70c_py_1 sh -c sh /dsbutils/adduser ... Up

Let's check the performance of the host scripts:

    $ dsbpython -V
    Python 3.10.2
    $ dsbpython2 -V
    Command 'python2' not found in the container
    $ dsbpython3 -V
    Python 3.10.2

As you can see, the `python2` command is missing from the `python:alpine3.15` Docker image.

The container mounted directory in `.dsb/compose/py.yaml` is
variable [`DSB_SPACE`](#dsb_space), whose default value is
is the full path of the [Dsb root directory](#terms):

```
volumes:
  - $DSB_SPACE:/dsbspace
  ...
```

so you can use host scripts in the root directory
and in any of its subdirectories.

Run a test program in a container using host scripts
`dsbpython` and `dsbpython3`:

    $ dsbpython src/hello.py
    Hello from the Container!
    $ cd src
    $ dsbpython3 hello.py
    Hello from the Container!
    $ cd .. # return to Dsb root directory

Any command in an arbitrary project container can also be executed
using the [`dsb sh`](#dsb-sh) command:

    $ dsb sh py python src/hello.py
    Hello from the Container!
    $ cd src
    $ dsb sh py python3 hello.py
    Hello from the Container!
    $ cd .. # return to Dsb root directory

(here `py` is the name of the corresponding service)

Container commands have access to the input stream (STDIN) from the host system,
they can participate in pipes executed on the command line of the host system:

    $ dsbpython - < src/hello.py | cat
    Hello from the Container!
    $ echo 'print("Hello from the Host!")' | dsbpython -
    Hello from the Host!
    $ echo 'Hello from the Host!' | dsb sh py cat | cat
    Hello from the Host!

The exit code for container programs is also available on the host system:

    $ echo 'exit(55)' | dsbpython -
    $ echo $?
    55

(in case of own erroneous situations, Dsb environment commands return code `1`)

Container programs can run interactively:

    $dsbpython
    Python 3.10.2 (main, Jan 29 2022, 03:40:37) [GCC 10.3.1 20211027] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> print('bla-bla-bla')
    bla bla bla
    >>> exit()
    $ # host system command line

So far, we have been executing container commands on the command line of the
host systems. Commands can be executed directly
on the container command line, which is invoked using
still the same command [`dsb sh`](#dsb-sh):

    $ dsb sh py
    py:/dsbspace$ # we are on the container command line
    py:/dsbspace$pwd
    /dsbspace
    py:/dsbspace$ python src/hello.py
    Hello from the Container!
    py:/dsbspace$ ls -ld *
    drwx------ 7 dsbuser dsbuser 4096 Feb 16 12:42 .dsb
    drwxrwxr-x 2 dsbuser dsbuser 4096 Feb 16 12:01 src
    py:/dsbspace$ cd src
    py:/dsbspace/src$ python hello.py
    Hello from the Container!
    py:/dsbspace/src$ exit # exit container (or Ctrl+D)
    $ # we are back at the command line of the host system

When entering the container, a prompt appears (`py:/dsbspace$`),
containing the name of the service and the current directory. In our case, the current
directory is `/dsbspace` since the command line call was
implemented directly from the mounted directory.

If the command line is invoked from a subdirectory of the mounted directory,
in the container, we also get into the corresponding subdirectory:

    $ cd src
    $ dsb sh py
    py:/dsbspace/src$ # we are on the container command line
    py:/dsbspace/src$pwd
    /dsbspace/src
    py:/dsbspace/src$ ls -ld *
    -rw-rw-r-- 1 dsbuser dsbuser 23 Feb 16 12:01 pm hello.py
    py:/dsbspace/src$ exit

From the listings above, you can see that the mounted directory files are displayed
in the container as files owned by the 
[`dsbuser`](#dsbuser-account) account and the group of the same name.
These user and group are created in the container at startup
and have the same UID and GID as the host user.

You can also work with the container in root mode. For this purpose it is intended
the [`dsb root`](#dsb-root) command, which is called according to the same rules,
same as [`dsb sh`](#dsb-sh).

To stop project services without deleting containers
from the host system, the command is used:

    $ dsb stop

Stop project services with container removal
you can use the command:

    $ dsb down

Deleting all named project volumes:

    $ dsb compose down -v

Removing all Dsb projects from the host system of containers and networks:

    dsb down-all

At the end of the review, consider the contents of the host script
`dsbpython`:

    #!/usr/bin/env dsb-script
    dsb_resolve_files py
    dsb_run_as_user "@PYTHON" python "$@"

For comparison, here are the texts of the host scripts `dsbnode` and `dsbnpm`,
designed to work with Node.js:
```
#!/usr/bin/env dsb-script
dsb_resolve_files js
dsb_run_as_user "@NODE" node "$@"
```

```
#!/usr/bin/env dsb-script
dsb_run_as_user "@NODE" npm "$@"
```

As you can see, everything is quite simple.
The strings `@PYTHON` and `@NODE` are replaced on execution with the names of the services,
extracted from the variables `DSB_SERVICE_PYTHON` and `DSB_SERVICE_NODE`
in the `.dsb/compose/.dsbenv` file (see: [service-aliases](#service-aliases)).
The string `"$@"` is used in Bash to denote a list of positional parameters
host script.

> To perform actions in root mode in the host script, you can use
function `dsb_run_as_root`.


Dsb project structure
---------------------

Each Dsb project provides containerized support to one
or multiple software projects that share
one set of containers.

In the case of several related software projects (for example, microservices)
The file structure of a Dsb project might look like this:

```
Dsb root directory
   |__ .dsb directory
   |__ mounted directory 1
   |__ mounted directory 2
   |__ ...
```

Separate git repositories can act as mounted directories here
or some of their subdirectories. Each mounted directory can be accessed
in [bind mounts](https://docs.docker.com/storage/bind-mounts/) mode
one or more services of the Dsb project.

When working on a single software project, you can use
simplified diagrams:

```
root directory == git repository == mounted directory
  |__ .dsb directory
  |__ ...
```

```
root directory == git repository
  |__ .dsb directory
  |__ mount subdirectory of git repository 1
  |__ mount subdirectory of git repository 2
  |__ ...
```

In this case, the Dsb root directory can be the same
as the git repository, and the `.dsb` subdirectory
can be part of the git working tree.

> Pay attention to the contents of the `.gitignore` files in the `.dsb` subdirectories.

The second option is more preferable from a security point of view,
because in this case the `.dsb` directory is outside the mounted directory.


### `.dsb` directory 

The `.dsb` directory is the location of the Dsb project configuration
and container data that needs to be preserved during temporary deletion
containers from the host system (for example, when switching to another project).

The original contents of the directory can be prepared
DevOps Engineer and then just handed off to developers for use
specific software project. In this sense, `.dsb` is a kind of
"package" containing all the information needed to run a typical
set of containers.

The directory has the following structure:

```
.dsb
  |__ bin
  |__ compose
  |__config
  |__ home
  |__logs
  |__ skel
  |__ storage
```

* `bin` contains [custom subcommands](#custom-subcommands) of a specific Dsb project
(the directory is optional).

* `compose` contains [yaml files](#yaml-files) of Compose services
and the file [`.dsbenv`](#dsbenv-file), which stores configuration
Dsb and Compose environment variables.

* `config` contains configuration files and directories mounted
in containers in readonly mode and used by internal container processes.
The specific content of `config` is generated by the user of the Dsb environment
and depends on the Docker images used.

* `home` contains the home directories of the containers' 
[`dsbuser`](#dsbuser-account) accounts. Each service is assigned
a separate subdirectory mounted in the container in readwrite mode.

* `logs` contains directories that can be used to place log files
individual project services.

* `skel` contains the user home directory template for the project's
[`dsbuser`](#dsbuser-account) (directory is optional).

* `storage` contains directories where other
persistent service data, such as databases.
Using `storage` is an alternative to using
[named Compose volumes](https://docs.docker.com/compose/compose-file/compose-file-v3/#volume-configuration-reference).

The initial formation of the `.dsb` directory is done with the [`dsb init`](#dsb-init) subcommand.
The `home`, `logs` and `storage` subdirectories are automatically created when executing
[`dsb start`](#dsb-start).

The `skel` subdirectory is optional and is not automatically created.
If it is absent, the [`dsb yaml`](#dsb-yaml) subcommand uses the default
home directory template contained in `lib/skel` subdirectory
given git repository.

The `dsb start` subcommand always creates in each of the `home`, `logs` and `storage` subdirectories
a set of internal subdirectories with the names of configured Dsb project services.
This supports the possibility of using such subdirectories
in yaml files of individual project services.

When creating internal subdirectories in `logs` and `storage` with the `dsb start` subcommand
each such subdirectory is given `a=rwx` permissions.
This provides default access for any container processes.
This takes into account that the main processes of containers can be executed with the rights of
arbitrary users.
You can restrict access to host directories in containers by
mounts inside parent directories
with the appropriate access rights.


#### `.dsbenv` file

The `.dsbenv` file is located in the subdirectory [`.dsb/compose`](#dsb-directory)
and contains the values ​​of the configuration variables of the Dsb project and the Compose environment.

This file is similar to the file
[`.env`](https://docs.docker.com/compose/env-file/)
Compose environment, with the only difference being that it is processed
Bash interpreter and must be styled according to
[Bash syntax rules](https://tldp.org/LDP/abs/html/variables.html):

    SOMEVAR=somevalue
    ...

When assigning values ​​to variables, spaces are not allowed on either side of the `=` sign.
The value of a variable can be enclosed in single or double quotes.
The `#` character is the start of a comment line.

> Using the `.env` file is also valid, but redundant.

In the context of `.dsbenv` are available
[base Dsb project variables](#base-dsb-variables),
which can be used when assigning values to
configuration variables.
The current directory at the time `.dsbenv` is called is `.dsb/compose`.

The following configuration variables are supported:

* [`COMPOSE_FILE`](#compose_file) - required list of project yaml files;
* [`COMPOSE_...`, `DOCKER_...`](https://docs.docker.com/compose/reference/envvars/) - Compose environment variables;
* [`DSB_COMPOSE_FILE_VERSION`](#dsb_compose_file_version) - version of yaml files for the [`dsb yaml`](#dsb-yaml) subcommand.
* [`DSB_HOME_VOLUMES`](#dsb_home_volumes) - option to use named volumes for [`dsbuser`](#dsbuser-account) home directories;
* [`DSB_PROD_MODE`](#dsb_prod_mode) - production mode option of [`dsb`](#dsb-utility);
* [`DSB_PROJECT_ID`](#dsb_project_id) - unique Dsb project ID;
* [`DSB_SERVICE_...`](#dsb_service_) - service names for [host scripts](#host scripts);
* [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout) - timeout for shutting down containers;
* [`DSB_SPACE`](#dsb_space) - mounted directory path (used by [`dsb yaml`](#dsb-yaml) subcommand);
* [`DSB_UMASK_ROOT`](#dsb_umask_root) - fixed `umask` value for [`dsb root`](#dsb-root) subcommand;
* [`DSB_UMASK_SH`](#dsb_umask_sh) - fixed `umask` value for [`dsb sh`](#dsb-sh) subcommand;

See the [manual](#dsbenv-file-variables) for a detailed description of the individual variables.

Significantly:

* Mandatory configuration variables are [`DSB_PROJECT_ID`](#dsb_project_id)
and [`COMPOSE_FILE`](#compose_file).
Based on the value of `DSB_PROJECT_ID`, the value of the variable is automatically set
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/reference/envvars/#compose_project_name).

* An initial random value of `DSB_PROJECT_ID` is set
when generating the `.dsbenv` file with the subcommand
[`dsb init`](#dsb-init). You can change the value immediately if you wish.
to a more visual one. Latin letters A-Z, a-z, symbols "_", "-" and numbers 0-9 should be used.

* The `COMPOSE_FILE` variable must always include the `globals.yaml` file,
which contains the project's global network settings.

In addition to the above variables, `.dsbenv` can contain
arbitrary user variables intended for
use in [yaml files](#yaml-files) and [host scripts](#host-scripts).

Variables with `DSB_`, `DSBUSR_`, `COMPOSE_` and `DOCKER_` prefixes
(including [base variables](#base-dsb-variables)), and all
variables explicitly set in the `.dsbenv` file,
are automatically exported to the called command environment and available to utilities
`docker-compose` and `docker` when calling them internally.

Note that variables with the above prefixes
are reset at the start of the `dsb` utility and cannot be set
by some external means. For automatically reset user
variables are prefixed with `DSBUSR_`.

See also:
* [Environment variables in Compose](https://docs.docker.com/compose/environment-variables/)
* [Variable substitution in Compose](https://docs.docker.com/compose/compose-file/compose-file-v3/#variable-substitution)
* [Compose Variables Reference](https://docs.docker.com/compose/reference/envvars/)


#### Yaml files

The Compose environment allows you to store your project configuration in the form of one or [multiple
yaml files](https://docs.docker.com/compose/reference/#specifying-multiple-compose-files) - in
Dsb the second option is used. All project yaml files are placed in a subdirectory
[`.dsb/compose`](#dsb-directory) and in the same place, in the file [`.dsbenv`](#dsbenv-file),
their list is stored - in the configuration variable
[`COMPOSE_FILE`](#compose_file).

When creating a Dsb project using the [`dsb init`](#dsb-init) subcommand
the `.dsb/compose` subdirectory contains the initial required file `globals.yaml`,
containing [MTU value](#prerequisites):
```
version: '3.3'
networks:
  dsbnet:
    driver:bridge
    driver_opts:
      com.docker.network.driver.mtu: MTU_VALUE
```

> When transferring a project configuration to another computer, you may need to
adjusting the MTU value.

`dsbnet` is used as the name of the main project network in `globals.yaml`.
The same name is added to the yaml file templates generated by the subcommand
[`dsb yaml`](#dsb-yaml):

```
version: '3.3'
services:
  SERVICE_NAME:
    ...
    networks:
      dsbnet:
    ...
```

The presence of the specified `networks` element is the only
requirement for the design of yaml files. The presence of other elements depends
on the specifics of the service, as well as on the need to use subcommands
`dsb sh`, `dsb root` and [host scripts](#host-scripts).

To create the initial content of the yaml file, use
subcommand [`dsb yaml`](#dsb-yaml). subcommand automatically
adds to the yaml file all service elements necessary for support
`dsb sh`, `dsb root` and [host scripts](#host-scripts) subcommands.

For links in the yaml file to configuration subdirectories
[`.dsb`](#dsb-directory) variable should be used
[`DSB_BOX`](#base-dsb-variables).

For references to a common for all services [mounted directory](#mounted-directories)
you can use the [`DSB_SPACE`](#dsb_space) variable .
The corresponding mount point is automatically added
to a yaml file with the [`dsb yaml`](#dsb-yaml) subcommand.

For references to additional [mounted directories](#mounted-directories),
located in the Dsb root directory, you can
use the [`DSB_ROOT`](#base-dsb-variables) variable.

Starting a new service and activating current changes in yaml files
is done with the [`dsb start`](#dsb-start) subcommand without parameters.

See also:
* [Variables available in Dsb yaml files](#variables-available-in-yaml-files)
* [Compose file version 3 reference](https://docs.docker.com/compose/compose-file/compose-file-v3/)
* [Compose variables - COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file)


### Mounted directories

A mounted directory is a host filesystem directory
accessible to one or more containers via
[bind mounts](https://docs.docker.com/storage/bind-mounts/).
Such a directory can be, for example, a git repository.

You can mount any number of host directories in a container.
The corresponding mount points in containers can be arbitrary,
except for mount points `/dsbutils`, `/dsbhome`, and `/dsbskel`,
which are added to the container to create a user
[`dsbuser`](#dsbuser-container-user) and
subcommand support [`dsb sh`](#dsb-sh), [`dsb root`](#dsb-root)
and [host scripts](#host-scripts).

Requirements for the location of mounted directories
exist only for the directories used in parameters of the
[`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root) subcommands,
and [host scripts](#host-scripts).
In this case, the current working directory should be
within the Dsb root directory and the data processed in containers
should also be placed there (see [Dsb project structure](#dsb-project-structure)).

> Additional options are supported in [host scripts](#host-scripts)
selecting a Dsb project, allowing you to remove the above restriction.
In particular, host scripts can be unambiguously executed within
specific projects in the host system.

In addition to data directly related to software projects under development,
containers also mount configuration and other data related to
to the inner workings of the services. In Dsb to place such data
use [dir `.dsb`](#dsb-directory) and
[named Compose volumes](https://docs.docker.com/compose/compose-file/compose-file-v3/#volume-configuration-reference).

To simplify the configuration of new services and automatic mounting
Dsb service directories, the [`dsb yaml`](#dsb-yaml) subcommand is provided,
which forms the initial `yaml` template of the new service. `yaml` configuration independence
from the specific location of the Dsb root directory provide
[basic Dsb variables](#base-dsb-variables).


`dsb` utility
-------------

The `dsb` utility provides a command interface to access the Dsb project.

Usage:

     $ dsb SUBCOMMAND [ ...PARAMETERS ]

Supported subcommands:

* Dsb project configuration:
    * [`dsb init`](#dsb-init) - create `.dsb` directory
    * [`dsb yaml`](#dsb-yaml) - create yaml file
    * [`dsb clean`, `dsb clean-...`](#dsb-clean-dsb-clean-) - cleaning `.dsb` subdirectories
* Execute commands in containers:
    * [`dsb sh`](#dsb-sh) - execute commands with [`dsbuser`](#dsbuser-account) permissions
    * [`dsb root`](#dsb-root) - execute commands with `root` permissions
* Service management:
    * [`dsb start`](#dsb-start) - start project services
    * [`dsb restart`](#dsb-restart) - restart project services
    * [`dsb stop`](#dsb-stop) - stop services without removing containers
    * [`dsb down`](#dsb-down) - shutdown services with container removal
    * [`dsb down-all`](#dsb-down-all) - delete containers of all Dsb projects
    * [`dsb scale`](#dsb-scale) - project service scaling
    * [`dsb ps`](#dsb-ps) - current status of project services
    * [`dsb clean-vols`](#dsb-clean-vols) - clean up the contents of the named volume
    * [`dsb compose`](#dsb-compose) - call `docker-compose` in Dsb project context
* Auxiliary subcommands:
    * `dsb help` - display a list of supported subcommands
    * [`dsb logs`](#dsb-logs) - output log files of a service or a single container
    * [`dsb cid`](#dsb-cid) - output Docker container ID
    * [`dsb ip`](#dsb-ip) - display the IP address of the container
    * [`dsb var`](#dsb-var) - display the value of the configuration variable
    * [`dsb vols`](#dsb-vols) - display Docker names of named project volumes
    * [`dsb ...`](#custom-subcommands) - custom subcommands

A detailed description of the subcommands is given in the [reference](#dsb-utility-subcommands).
A brief description can be obtained by entering the `dsb` command without parameters
or with the `dsb help` subcommand.

All subcommands except [`dsb init`](#dsb-init)
and [`dsb down-all`](#dsb-down-all), are executed in context
specific Dsb project. The project configuration is searched
from the current working directory up
through the chain of parent directories until it is found
nearest root directory with `.dsb` subdirectory.

Several Dsb projects can be running simultaneously on the host system.
Sub-commands addressed to different projects must be executed within
root directories of these projects.

### Service management

The `dsb` utility supports a simplified set of subcommands for starting and shutting down services:
[`dsb start`](#dsb-start), [`dsb stop`](#dsb-stop), [`dsb restart`](#dsb-restart),
[`dsb down`](#dsb-down).

Starting services when calling subcommands [`dsb start`](#dsb-start) and [`dsb restart`](#dsb-restart)
is done with the [`--detach`](https://docs.docker.com/compose/reference/up/) option.

Access to the full range of features
[`docker-compose`](https://docs.docker.com/compose/reference/)
provides the [`dsb compose`](#dsb-compose) subcommand.

### Custom subcommands

Custom subcommands are scripts placed in the configuration subdirectory `.dsb/bin`.
Such scripts can be used to comfortably perform operations not covered by
a set of [built-in subcommands of the `dsb` utility](#dsb-utility-subcommands).

If the first argument to the `dsb` utility call does not match any name
built-in subcommand, the utility checks for the existence of a file
with the appropriate name in the `.dsb/bin` directory. If one exists,
then, depending on whether the file has an `execute` attribute,
one of the following:

* If the `execute` attribute is present, the file is launched for execution
like a normal command. The first line of such a file must be a shebang line.
Next should be the code in the appropriate scripting language;

* In the absence of the `execute` attribute, the presence of a Bash script is implied,
the execution of which is carried out according to the same rules as the execution
[host scripts](#host-scripts). The shebang line is not required. In the text of the script
you can use [host script functions](#functions-available-in-host-scripts).
The [`dsb_set_box`](#dsb_set_box) function has already been executed at the time the script is called
and the corresponding Dsb environment variables are available to the script.

Call arguments are passed to the custom subcommand script as arguments
`dsb` utilities following the script name:

    $ dsb <script_name> [ ...<script_arguments> ]

The current directory when calling the script is the current directory where the `dsb` utility is called.

The script has access to [basic Dsb variables](#base-dsb-variables)
and [`.dsbenv` file variables](#dsbenv-file-variables).


### Execute commands in containers

To execute commands in the context of containers, there are
subcommands [`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root),
and also [host scripts](#host-scripts):

* The `dsb sh` subcommand performs container operations with permissions
user [`dsbuser`](#dsbuser-user),
added to containers at startup and having the same numeric IDs
`UID` and `GID` as the host user.

* The `dsb root` subcommand performs container operations
with `root` user rights.

* When executed with one parameter - service name - subcommands
`dsb sh` and `dsb root` switch command line
host system to the command line of the corresponding container.
Additional parameters are interpreted as a command that is required
execute in a container without switching the command line.

* Direct access to the container is carried out using an internal call
[`docker exec`](https://docs.docker.com/engine/reference/commandline/exec/).

Using and preparing host scripts [reviewed separately](#host-scripts).

#### Set current directory in a container

If the host system's current working directory is
within the boundaries of one or more mounted directories available to the container,
when executing subcommands [`dsb sh`](#dsb-sh), [`dsb root`](#dsb-root)
and [host scripts](#host-scripts) the same directory is set
as current in the context of the container.

If there are multiple nested mounted directories with different access modes
(`readwrite` and `readonly`) to display the host path
the parent directory is selected in the container directory
the topmost level with `readwrite` access mode. If all mounted directories
have the same access mode, the top-level directory is selected.

If the host system's current working directory is outside
container mounts, in the container as the current directory
the home directory of the container user is set
([`dsbuser`](#dsbuser-account) or `root`).

#### Convert file paths in parameters

Relative file paths in the parameters of the subcommands [`dsb sh`](#dsb-sh) and
[`dsb root`](#dsb-root) are passed to the container context unchanged.

> When executing [host scripts](#host-scripts), the relative paths of some files
can be pre-converted to full paths, allowing
map them to container paths even if the current directory
command line is outside the mounted directory
(essential for IDE integration).

The full paths of files are replaced with the corresponding ones when transferred to the
container paths, if such mapping is possible.
If the file path belongs to multiple nested mounts,
transformation is carried out according to the same rules as for
[display current directory](#set-current-directory-in-a-container).

Guaranteed to unmap file paths in a specific setting
can be prefixed with `dsbnop:` to the parameter value.

#### Setting up a profile in a container

Before executing commands inside the subcommand container [`dsb sh`](#dsb-sh),
[`dsb root`](#dsb-root) and [host scripts](#host-scripts)
always perform profile configuration in the container in the same way as
as is done when invoking a shell with the `-l` (login shell) option.
At this point, the container file `/etc/profile` is accessed
and the `~/.profile` file of the `dsbuser` or `root` accounts.

The above applies both to an explicit switch to the command line
container - to execute `dsb sh` and `dsb root` without specifying a command, - and to execute
single container commands using `dsb sh`, `dsb root` and host scripts.

The home directory of the `dsbuser` account is stored permanently - separately for each
service - and is not removed when the container is temporarily removed. Directory content,
including the `~/.profile` file, can be additionally configured by the host user
(See [`dsbuser` account](#dsbuser-account)).


#### Setting `umask`

By default, the files creation mode mask `umask` is always set in the container context
that match the current `umask` value
on the command line of the host system.

The value of `umask` can be explicitly fixed at the project level
in file [`.dsbenv`](#dsbenv-file) using variables
[`DSB_UMASK_SH`](#dsb_umask_sh) and [`DSB_UMASK_ROOT`](#dsb_umask_root).

At the individual service level, the value of `umask` can be explicitly fixed
using the `DSB_UMASK_SH` and `DSB_UMASK_ROOT` variables in the corresponding yaml file:

```
environment:
  DSB_UMASK_SH: "0027"
  ...
```
(the `umask` value must be quoted in this case)

### `dsbuser` account

Processing data in containers in many cases requires performing operations
with the same file access rights as the host user.
In Dsb, this problem is solved by creating user containers
with the same numeric `UID` and `GID` as the host user.

The `dsbuser` account is created on containers when they are started with
a small bootstrap script automatically added to templates
new yaml files with the [`dsb yaml`](#dsb-yaml) subcommand ([see description](#dsb-yaml)).

In the context of the `dsbuser` user, container operations and
subcommands [`dsb sh`](#dsb-sh) and [host scripts](#host-scripts) are performed.
The name `dsbuser` can be used in container software settings.

The home directory of the `dsbuser` account is persisted in the host filesystem,
separately for each service, in the corresponding subdirectory `.dsb/home`
or in a separate [named volume](#dsb_home_volumes).

Initial home directory template
(subdirectory `lib/skel` of this git repository)
contains a `~/bin` subdirectory that is included in the PATH variable
in the configuration file `~/.profile`. The `~/bin` subdirectory can contain
custom scripts and programs that will be available to call using
`dsb sh` subcommands. You can make any other setting for each
services individually, in particular, to customize the content
files `~/.profile` and `~/.bashrc`.

If desired, you can place your own template in the `.dsb/skel` subdirectory
home directory. Mount point of this template
will be automatically substituted by the [`dsb yaml`](#dsb-yaml) subcommand
into yaml files of new services and be used in containers
instead of the built-in template.

### Container indexes

In most subcommands `dsb` as an additional parameter
specifies the name of the service to which the subcommand action belongs.
In some cases, the parameter designates exactly the service,
in others, a single container running as part of a service.

The difference in parameter interpretation becomes significant
when scaling the service ([`dsb scale`](#dsb-scale)),
when a particular service has several active containers.
In this case, to limit the effect of the `dsb` subcommand to one container,
the service name can be colon-completed with the numeric index of the container.

> Container index can also be added to [service aliases](#service-aliases)
in [host scripts](#host-scripts).

Example:

    $ dsb scale os 2
    $ dsb ip os:1
    172.16.10.2
    $ dsb ip os:2
    172.16.10.4

The numbering of service containers starts from the value "1". It's the same meaning
used by default if the container index is not specified in the parameter,
and the action of the subcommand refers specifically to a single container.

The current container indexes can be obtained using the [`dsb ps`](#dsb-ps) subcommand.

> Continuous numbering order for scaled service containers
may be broken when individual containers are removed.

Subcommands that always apply to a single container:
[`dsb sh`](#dsb-sh),
[`dsb root`](#dsb-root),
[`dsb-cid`](#dsb-cid),
[`dsb ip`](#dsb-ip).

Subcommands, the action of which can be related to the service as a whole,
and for single containers:
[`dsb start`](#dsb-start),
[`dsb restart`](#dsb-restart),
[`dsb stop`](#dsb-stop),
[`dsb down`](#dsb-down),
[`dsb logs`](#dsb-logs).


Network access to the host system from containers
--------------------------------------------------

The host system is assigned two domain names in containers:
`dsbhost` and `dsbhost.localhost`.
These names are added to the `/etc/hosts` files of containers when they are started.

The setting of `/etc/hosts` is performed in the container,
if `awk` utility is available (it's available in almost all Docker images).
The configuration is performed by the same entrypoint script,
which adds a [`dsbuser`](#dsbuser-account) account to the container.

> If a firewall is used on the host system, its configuration must
there are rules that open incoming access from containers,
see: [Firewall configuration on Linux](#host-system-firewall-configuration)

Host scripts
------------

The main purpose of host scripts is to call container commands
in the host system is identical to calling the original commands
in a container. Wherein:

* simplifies work in the command line of the host system;
* integration with IDE settings is provided,
where as a rule you can specify custom "runtime executable".

Each host script is a regular Bash script that has access to
[Dsb project variables](#variables-available-in-host-scripts)
and a few additional [functions](#functions-available-in-host-scripts).

The simplest script looks like this:

    #!/usr/bin/env dsb-script
    dsb_run_as_user "@SOME_ALIAS" SOME_COMMAND "$@"

This script allows you to execute a specific
command `SOME_COMMAND` with arbitrary parameters.

Here:
* `#!/usr/bin/env dsb-script`
Shebang string for calling the initializing script `dsb-script`,
whose sole role is to load a library of supported functions,
after which control is transferred directly to the host script;
* `@SOME_ALIAS` - [service alias](#service-aliases),
in which container to run the command.
(instead of an alias, a specific service name can be used)
* `SOME_COMMAND` - name or full path of the command in the container;
* `"$@"` is a Bash construct that invokes substitution
all arguments of the call to the host script.

Two additional connection options are supported in host scripts
to Dsb projects. In particular, scripts can be uniquely linked
to specific projects in the host system - this allows you to execute in the command
line container commands from different projects without switching the current directory
(see [`dsb_set_box`](#dsb_set_box) and [`dsb_set_single_box`](#dsb_set_single_box)).

Dsb functions and variables that can be used in host scripts,
given in the handbook:

* [Functions available in host scripts](#functions-available-in-host-scripts)
* [Variables available in host scripts](#variables-available-in-host-scripts)

This git repository contains a set of ready-made host scripts
to call typical developer commands (subdirectory `host-scripts`).

### Service aliases

Service names can change from project to project,
therefore, it is more convenient to use fixed aliases in the text of host scripts
and then bind them to specific services at the project configuration level.
In Dsb, the variables [`DSB_SERVICE_...`](#dsb_service_) serve for this purpose
file [`.dsbenv`](#dsbenv-file) and their corresponding aliases.

Each variable `DSB_SERVICE_...` corresponds to an alias string obtained from
from the variable name by dropping the `DSB_SERVICE_` prefix and then
adding a `@` character to the beginning.
Variable names `DSB_SERVICE_...` and aliases must be in upper case.

Example:

    DSB_SERVICE_PYTHON=py

In host scripts, the variable `DSB_SERVICE_PYTHON` will correspond to the alias `@PYTHON`.
When executing the functions in the host script:

    dsb_run_as_user "@PYTHON" python "$@"

the `python` command will be executed in the `py` service container.

The file [`.dsbenv`](#dsbenv-file) can also contain a default service for aliases,
not covered by specific `DSB_SERVICE_...` variables.
The `DSB_SERVICE` variable is used for this.

In the absence of a suitable `DSB_SERVICE_...` variable and a `DSB_SERVICE` variable,
the default service name is the string obtained from the alias by
stripping the first `@` character and then converting to lower case
(the default service for `@PYTHON` is `python`).

Service aliases can also be used in utility subcommands [`dsb`](#dsb-utility-subcommands):

    dsb sh "@PYTHON" python -c 'print("Hello")'

To aliases, as well as to regular service names, if necessary
you can add a numeric [container index](#container-indexes) separated by a colon.

> Aliases prefixed with `@DSB_` are reserved for future use.


Removing a Dsb project from the host system
-------------------------------------------

In order to complete the work with a specific Dsb project,
go to the root directory of the project
or to any of its subdirectories and run the commands:

    $ cd <dsb_root_dir>
    $ dsb compose down -v
    $ dsb clean

This will remove all named project volumes.
and internal contents of subdirectories `.dsb/home`, `.dsb/logs`
and `.dsb/storage`, after which you can delete the `.dsb` directory itself.

Delete containers and networks of all Dsb projects from the host system
you can use the command:

    $ dsb down-all

Removing all named and anonymous volumes that are not assigned to containers:

* [`docker volume prune`](https://docs.docker.com/engine/reference/commandline/volume_prune/)

Viewing and deleting docker images:

* [`docker image ls`](https://docs.docker.com/engine/reference/commandline/image_ls/)
* [`docker image rm`](https://docs.docker.com/engine/reference/commandline/image_rm/)

---


Reference
==========

`dsb` utility subcommands
-------------------------

* [`dsb cid`](#dsb-cid)
* [`dsb clean`, `dsb clean-...`](#dsb-clean-dsb-clean-)
* [`dsb clean-vols`](#dsb-clean-vols)
* [`dsb compose`](#dsb-compose)
* [`dsb down`](#dsb-down)
* [`dsb down-all`](#dsb-down-all)
* [`dsb init`](#dsb-init)
* [`dsb ip`](#dsb-ip)
* [`dsb logs`](#dsb-logs)
* [`dsb ps`](#dsb-ps)
* [`dsb restart`](#dsb-restart)
* [`dsb root`](#dsb-root)
* [`dsb scale`](#dsb-scale)
* [`dsb sh`](#dsb-sh)
* [`dsb start`](#dsb-start)
* [`dsb stop`](#dsb-stop)
* [`dsb var`](#dsb-var)
* [`dsb vols`](#dsb-vols)
* [`dsb yaml`](#dsb-yaml)

> See also ["Custom subcommands"](#custom-subcommands).

Subcommand descriptions use the following notation:
* `SERVICE` - Docker Compose service name;
* `SERVICE:INDEX` - Docker Compose service name with
numeric index of a specific container
(see ["Container indexes"](#container-indexes));
* `IMAGE` - Docker image URL.

---

### `dsb cid`

    $ dsb cid SERVICE
    $ dsb cid SERVICE:INDEX

> See also ["Container indexes"](#container-indexes).

The subcommand outputs the container's Docker ID to the output stream.
This identifier can be used further as a parameter
commands [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/).

Example:

     $ docker cp $( dsb cid nginx ):/etc/nginx ./nginx/

In this example, the contents are copied to the current directory of the host system.
`/etc/nginx` directory of the container related to the `nginx` service.

---

### `dsb clean`, `dsb clean-...`

    $ dsb clean         [ SERVICE ] 
    $ dsb clean-home    [ SERVICE ] 
    $ dsb clean-logs    [ SERVICE ] 
    $ dsb clean-storage [ SERVICE ] 

Subcommands are provided to quickly clean up `.dsb` service subdirectories.
If these subdirectories contain nested subdirectories or files,
inaccessible for removal directly by the host user,
deletion is done via the `sudo` command.

> Removing subdirectories is done using the command
`rm -rf <directory_path>`

Purpose of subcommands:

* `dsb clean-home` - cleaning the `.dsb/home` directory
* `dsb clean-logs` - cleaning the `.dsb/logs` directory
* `dsb clean-storage` - cleaning the `.dsb/storage` directory
* `dsb clean` - equivalent to `clean-home` + `clean-logs` + `clean-storage`

If there is a parameter specifying the name of the service in the cleared
directory, only the contents of the nested subdirectory are deleted
with the corresponding name. Otherwise, in the cleaned
directory, all internal subdirectories are deleted.

If the [`.dsbenv`](#dsbenv-file) file has the mode:

    DSB_HOME_VOLUMES=true

the `dsb clean-home` and `dsb clean` subcommands automatically remove named
volumes that contain [`dsbuser`](#dsbuser-account) home directories.

The `dsb clean` subcommand without a parameter can be used
when you finish working with the Dsb project.

---

### `dsb clean-vols`

    $ dsb clean-vols COMPOSE_VOLUME

The subcommand removes the contents of the named Compose volume. The volume itself is not removed.

If there are running containers in the host system to which the cleaned volume is assigned,
then these containers are pre-stopped
([`docker container stop`](https://docs.docker.com/engine/reference/commandline/container_stop/)).
After cleaning the volume the containers are started again
([`docker container start`](https://docs.docker.com/engine/reference/commandline/container_start/)).

A typical use of this subcommand is to reset and initialize a database from scratch.

---

### `dsb compose`

    $ dsb compose ...PARAMETERS

The subcommand provides a call to any commands
[Docker Compose CLI](https://docs.docker.com/compose/reference/)
in the context of a specific Dsb project.

Examples:

     $ dsb compose top
     $ dsb compose down -v

When calling the `docker-compose` command internally, automatically
add `--project-name` and `--project-directory` options
(full path of the `.dsb/compose` directory).

---

### `dsb down`

    $ dsb down
    $ dsb down SERVICE
    $ dsb down SERVICE:INDEX

> See also ["Container indexes"](#container-indexes).

The subcommand terminates all services of the Dsb project
or specific service/container and then removes
from the host system, the corresponding containers:

* Shutdown of all containers of the project is carried out using the command
[`docker-compose down`](https://docs.docker.com/compose/reference/down/).

* The shutdown of all containers of a particular service is carried out
by sequential execution of commands
[`docker-compose stop`](https://docs.docker.com/compose/reference/stop/)
and [`docker-compose rm`](https://docs.docker.com/compose/reference/stop/).

* Shut down a specific container (`SERVICE:INDEX`)
carried out by sequential execution of commands
[`docker container stop`](https://docs.docker.com/engine/reference/commandline/container_restart/)
and [`docker container rm`](https://docs.docker.com/engine/reference/commandline/container_rm/)

This subcommand does not remove named project volumes.
To delete all existing named volumes in a project, you can use
command:

    dsb compose down -v

---

### `dsb down-all`

    $ dsb down-all

The subcommand terminates the work in the host system of all services related to Dsb projects,
and removes the corresponding containers and networks.

---

### `dsb init`

    $ dsb init [ YML_VERSION ]

The subcommand creates a subdirectory `.dsb` in the current directory and copies into it
initial Dsb project configuration template.

The `.dsb/compose/.dsbenv` file is set to
initial random value of the variable [`DSB_PROJECT_ID`](#dsb_project_id).
The value of this variable is used in container names
and named project volumes, so must be unique within the host system.
__If desired, the value of `DSB_PROJECT_ID` can be immediately changed to a more descriptive__ - in
value, you can use Latin letters A-Z, a-z, symbols "_", "-" and numbers 0-9.

Optional parameter `YML_VERSION`
sets the value of the variable [`DSB_COMPOSE_FILE_VERSION`](#dsb_compose_file_version)
in the file `.dsb/compose/.dsbenv`. Default value: `3.3`

---

### `dsb ip`

    $ dsb ip SERVICE

> See also ["Container indexes"](#container-indexes).

The subcommand outputs the container's IP address to the output stream.

---

### `dsb logs`

    $ dsb logs SERVICE

> See also ["Container indexes"](#container-indexes).

The subcommand displays the contents of the service / container log.

---

### `dsb ps`

    $ dsb ps [ SERVICE ]

The subcommand prints the current status of all containers in the project
or only containers of a specific service.

---

### `dsb restart`

    $ dsb restart
    $ dsb restart SERVICE
    $ dsb restart SERVICE:INDEX

> See also ["Container indexes"](#container-indexes).

The subcommand restarts all services of the Dsb project
or restart a specific service / container:

* Restart services is performed using the command
[`docker-compose restart`](https://docs.docker.com/compose/reference/restart/).

* Restart a specific container (`SERVICE:INDEX`)
executed with the command
[`docker container restart`](https://docs.docker.com/engine/reference/commandline/container_restart/).

It should be noted that changes made to yaml files are not activated when this subcommand is executed.
To activate the changes, use the [`dsb start`](#dsb-start) subcommand without parameters.

---

### `dsb root`

    $ dsb root SERVICE
    $ dsb root SERVICE COMMAND [ ...PARAMETERS ]
    $ dsb root SERVICE COMMAND_STRING

> See also ["Container indexes"](#container-indexes).

The subcommand execution rules are similar to the subcommand execution rules [`dsb sh`](#dsb-sh)
with the only difference being that the operations of the `dsb root` subcommand are executed in the container as the `root` user.

For more details on the execution of the subcommand, see the sections:
* [dsb-sh](#dsb-sh)
* [Execute commands in containers](#execute-commands-in-containers).

Subcommand call examples:

     $ dsb root os find /etc
     $ dsb root os cat /etc/shadow

---

### `dsb scale`

    $ dsb scale SERVICE REPLICAS

The subcommand scales the service by increasing or decreasing
the number of service containers up to the number specified by the `REPLICAS` parameter:

    $ dsb scale os 3
    docker-compose --project-name dsb-af2a42f0315ac55c0553a5ec2e4c7e38 up --detach --scale os=3
    Starting dsb-af2a42f0315ac55c0553a5ec2e4c7e38_os_1 ... done
    Creating dsb-af2a42f0315ac55c0553a5ec2e4c7e38_os_2 ... done
    Creating dsb-af2a42f0315ac55c0553a5ec2e4c7e38_os_3 ... done

Scaling is done with the command
[`docker-compose up`](https://docs.docker.com/compose/reference/up/)
with the `--scale` option.

Keep in mind that when scaling a service, all of its containers
use the same instances of named volumes and
[mounted directories](#mounted-directories)
(including mounted subdirectories [`.dsb`](#dsb-directory))

> See also ["Container indexes"](#container-indexes).

---

### `dsb sh`

    $ dsb sh SERVICE
    $ dsb sh SERVICE COMMAND [ ...PARAMETERS ]
    $ dsb sh SERVICE COMMAND_STRING

> See also ["Container indexes"](#container-indexes).

The subcommand ensures that operations are performed in a container with rights
user [`dsbuser`](#dsbuser-account). This user is created
in containers when they are launched and has the same numeric identifiers `UID` and `GID`,
the same as the host user.

When executing a subcommand with only one `SERVICE` parameter,
switch to container command line:

    $ dsb sh py
    py:/dsbspace$ # we are on the container command line
    py:/dsbspace$ python src/hello.py
    py:/dsbspace$ cd src
    py:/dsbspace/src$ python hello.py
    Hello from the Container!
    py:/dsbspace/src$ exit # exit the container
    $ # we are back at the command line of the host system

As a shell shell on the container command line, use
in order of precedence `bash` or `sh` (depending on their availability).

If there are additional parameters, they are interpreted as a command,
which should be executed in a container without switching the command line
host systems.

In case of multiple parameters, the first one is taken as the name of the command,
and the rest - the parameters of this command:

    $ dsb sh py python src/hello.py
    Hello from the Container!
    $ cd src
    $ dsb sh py python3 hello.py
    Hello from the Container!

If there is only one additional parameter, it is interpreted
just as a line of one or more commands:

    $ dsb sh py "python src/hello.py ; cd src ; python3 hello.py"
    Hello from the Container!
    Hello from the Container!

> The command separator character in `bash` and `sh` is `;`.
The command line is executed in the context of `bash` or `sh` with the `-c` option.

The difference between the two options for calling a subcommand is manifested
when using the wildcard characters `*` and `?`. In the first variant
substitution of wildcard symbols is carried out in the command line of the host system.
In the second - in the context of the container.

If the current working directory is
within the boundaries of the [mounted directory](#mounted-directories) of the service,
it is also set as current and in the context of the container.
When passing command parameters containing full paths to the container
host system files, automatic substitution is carried out
file paths in the container context.

For more details on the execution of a subcommand, see the section
["Execute commands in containers"](#execute-commands-in-containers).

---

### `dsb start`

    $ dsb start
    $ dsb start SERVICE
    $ dsb start SERVICE:INDEX

> See also ["Container indexes"](#container-indexes).

The subcommand activates the work of all services of the Dsb project or a specific service / container.
Calling a subcommand without parameters can be used for quick activation
changes made to yaml files.

If the service name is not specified, then the command is executed
[`docker-compose up`](https://docs.docker.com/compose/reference/up/):

    $ dsb compose up --detach --remove-orphans

If the name of an unstarted service is specified, the command is executed
[`docker-compose up`](https://docs.docker.com/compose/reference/up/)
with the name of the given service as a parameter:

    $ dsb compose up --no-deps --detach SERVICE

If the name of the previously launched service is specified (there are containers), then the command is executed
[`docker-compose start`](https://docs.docker.com/compose/reference/start/):

    $ dsb compose start SERVICE

If a specific container reference is specified (`SERVICE:INDEX`),
then the command is executed
[`docker container start`](https://docs.docker.com/engine/reference/commandline/container_start/):

    $ docker container start $( dsb cid SERVICE:INDEX )

---

### `dsb stop`

    $ dsb stop
    $ dsb stop SERVICE
    $ dsb stop SERVICE:INDEX

> See also ["Container indexes"](#container-indexes).

The subcommand terminates all services of the Dsb project
or a specific service/container:

* Shutting down services is done with the command
[`docker-compose stop`](https://docs.docker.com/compose/reference/stop/).

* Shut down a specific container (`SERVICE:INDEX`)
executed with the command
[`docker container stop`](https://docs.docker.com/engine/reference/commandline/container_restart/).

Containers remain in the host system with the status `exited`
and can be restarted with subcommands
[`dsb start`](#dsb-start) or [`dsb restart`](#dsb-restart).

---

### `dsb var`

    $ dsb var [ VARIABLE_NAME ]

The subcommand prints to STDOUT the values of the
[Dsb Environment variables](#dsb-environment-variables)
available in the context `dsb` utility after reading the
[`.dsbenv`](#dsbenv-file) file.

When called with a parameter, the subcommand prints the value
of the corresponding variable.

Example:

     $ dsb var COMPOSE_FILE
     globals.yaml:py.yaml
     $ dsb var DSB_BOX
     /home/mylogin/MyProject/.dsb

When called without parameters, the subcommand prints а list of all available
variables (with prefixes `DSB_`, `COMPOSE_` and `DOCKER_`)
and their values.

This subcommand can be used for reference purposes when preparing
[yaml files](#yaml-files) and [host scripts](#host-scripts).

---

### `dsb vols`

    $ dsb vols [ COMPOSE_VOLUME ]

The subcommand allows you to get the names belonging to the project
named Docker volumes.

If there is no parameter, the subcommand lists all existing
in the host system named Docker volumes related to the context
Dsb project.

The `COMPOSE_VOLUME` parameter specifies a specific
[named Docker Compose volume](https://docs.docker.com/compose/compose-file/#volumes),
for which you want to print the name of the Docker volume to the output stream.
This name can be used later as a subcommand parameter of
[docker volume](https://docs.docker.com/engine/reference/commandline/volume/).

---

### `dsb yaml`

    $ dsb yaml SERVICE IMAGE [ --sleep | --cmd ] [ --initd ]

The subcommand generates an initial yaml file template for a new service named `SERVICE`
based on the `IMAGE` Docker image. The template is placed in the `.dsb/compose/SERVICE.yaml` file
and contains the elements necessary to use the service in conjunction with subcommands
[`dsb sh`](#dsb-sh), [`dsb root`](#dsb-root) and [host scripts](#host-scripts).
The template also contains commented sample additional elements,
which may be required to finalize the yaml file.

Example:

     $ dsb yaml py python:alpine3.15


```
version: '3.3'
services:
  py:
    image: 'python:alpine3.15'
    user:  root
    networks:
      dsbnet:
    environment:
      DSB_SERVICE: py
    volumes:
      - $DSB_SPACE:/dsbspace
      - $DSB_LIB_UTILS:/dsbutils:ro
      - $DSB_LIB_SKEL:/dsbskel:ro
      - $DSB_BOX/home/py:/dsbhome
    #
    # ... commented-out sample elements ...
    #
    entrypoint:
      - sh
      - '-c'
      - |
        sh /dsbutils/adduser.sh "$DSB_UID_GID"
        exec sh /dsbutils/sleep.sh
```

Here:

* `$DSB_SPACE:/dsbspace` - attach [mounted directory of ​​Dsb project](#mounted-directories);
* `$DSB_LIB_UTILS:/dsbutils:ro` - connection of a set of Dsb service scripts;
* `$DSB_LIB_SKEL:/dsbskel:ro` - include home directory template;
* `$DSB_BOX/home/SERVICE:/dsbhome` - connection of the host directory containing the user's home directory
[`dsbuser`](#dsbuser-user).
* [`entrypoint: ...`](https://docs.docker.com/compose/compose-file/compose-file-v3/#entrypoint) - small
bootstrap script containing user creation commands
[`dsbuser`](#dsbuser-account)
and then transferring control to the container's main process.

`yaml-file` version
([version: '...'](https://docs.docker.com/compose/compose-file/compose-versioning/))
set based on the value of the [`DSB_COMPOSE_FILE_VERSION`](#dsb_compose_file_version) variable.
If the variable does not exist, the default value `3.3` is used.

> All project yaml files must contain the same version number.

As [mounted directory](#mounted-directories) in template
the value of the variable [`DSB_SPACE`](#dsb_space) is used,
and the container directory `/dsbspace` as the mount point.
Both can be changed if desired. Variable value
[`DSB_SPACE`](#dsb_space) is the full path of the
[Dsb root directory](#terms) by default. Explicitly set a different value
possible in the file [`.dsbenv`](#dsbenv-file).

You can mount any number of arbitrary directories.
Mount points in containers can also be arbitrary.
Only fixed mount points are
service directories: `/dsbutils`, `/dsbhome`, `/dsbskel`.

> If there is a `.dsb/skel` directory containing a custom homepage template
user directory [`dsbuser`](#dsbuser-account), mount point
`$DSB_LIB_SKEL:/dsbskel:ro` is replaced by `$DSB_BOX/skel:/dsbskel:ro`.

The content of the `entrypoint` script is generated differently in the template depending on
from additional options of the `dsb yaml` subcommand. As the first in it
there is always a command to create a user
`dsbuser`: `sh /dsbutils/adduser.sh "$DSB_UID_GID"`.

The above example used the `--sleep` option by default,
so the main container process after creating `dsbuser`
put to sleep: `exec sh /dsbutils/sleep.sh`.
This option is designed to use a Docker image
just to execute [host scripts](#host-scripts) and subcommands
[`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root).

If you want to run a program as the main process of a container,
specified in the Dockerfile using the [`CMD`](https://docs.docker.com/engine/reference/builder/#cmd) directives and
[`ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint),
then you can use the `--cmd` option. Example:

    $ dsb yaml phpfpm php:fpm-alpine --cmd

```
    ...
    entrypoint:
      - sh
      - '-c'
      - |
        sh /dsbutils/adduser.sh "$DSB_UID_GID"
        cd "/var/www/html"
        exec "docker-php-entrypoint" "php-fpm"
```
> Command `cd "/var/www/html"` in above snippet added
according to the Dockerfile directive
[`WORKDIR`](https://docs.docker.com/engine/reference/builder/#workdir).

The set of service scripts of the `/dsbutils` directory contains the script `initd.sh`,
designed to perform additional configuration actions in the container.
This script executes scripts with `.sh` and `.bash` extensions,
located in the directory, the path of which is indicated to it as a parameter
(see `lib/utils/initd.sh` in this git repository).

You can enable `initd.sh` support with the `--initd` option. Example:

    $ dsb yaml phpfpm php:fpm-alpine --cmd --initd

```
    volumes:
      ...
      - $DSB_BOX/config/phpfpm/dsbinit.d:/dsbinit.d

    entrypoint:
      - sh
      - '-c'
      - |
        sh /dsbutils/adduser.sh "$DSB_UID_GID"
        sh /dsbutils/initd.sh /dsbinit.d
        cd "/var/www/html"
        exec "docker-php-entrypoint" "php-fpm"
```
With the `--initd` option, the `dsb yaml` subcommand configures the service to run
configuration scripts from the automatically created directory `.dsb/config/SERVICE/dsbinit.d`.
Scripts are executed in a container with `root` user rights.

> Some Docker images have built-in support for custom configuration scripts.
In this case, the `--initd` option is not required - you just need to
create a subdirectory in `.dsb/config/SERVICE` and add a mount point to the yaml file
this directory.

Configuration commands can also be added directly to the `entrypoint` script.

After the yaml file is finalized, its name is added to the variable
[`COMPOSE_FILE`](#compose_file) of file [`.dsbenv`](#dsbenv-file).
To quickly activate a new service or current changes in the yaml file
the [`dsb start`](#dsb-start) subcommand without parameters is used.


#### Mount named volumes

If the mode is set in the [`.dsbenv`](#dsbenv-file) file:

     DSB_HOME_VOLUMES=true

(the mode is more optimal for macOS)

then instead of the mount point:

```
     volumes:
       ...
       - $DSB_BOX/home/SERVICE_NAME:/dsbhome
```

named volume is added:

```
     volumes:
       ...
       - dsbuser-SERVICE_NAME:/dsbhome
...
volumes:
   dsbuser-SERVICE_NAME:
```


Dsb Environment variables
--------------------

### Base Dsb variables

Base variables are set in the context of the `dsb` utility
immediately after finding the root directory of the project.

At the time of accessing the file [`.dsbenv`](#dsbenv-file)
the following variables are set:

* `DSB_ROOT` - full path of the Dsb root directory;
* [`DSB_SPACE`](#dsb_space) - the default value is the same as the value of the `DSB_ROOT` variable,
but can be explicitly overridden at the file level [`.dsbenv`](#dsbenv-file);
* `DSB_BOX` - full path of `.dsb` directory;
* `DSB_COMPOSE` - full path of `.dsb/compose` directory;
* `DSB_LIB_UTILS` is the full path of the `lib/utils` subdirectory of this git repository;
* `DSB_LIB_SKEL` - full path of the `lib/skel` subdirectory of this git repository;
* `DSB_UID` - `UID` of the host user;
* `DSB_GID` - `GID` of the host user;
* `DSB_UID_GID` - `UID:GID` string.

Variables can be used in the file [`.dsbenv`](#dsbenv-file),
in [yaml files](#yaml-files) and [host scripts](#host-scripts).
All variables except `DSB_SPACE` are readonly variables.

The `DSB_ROOT`, `DSB_SPACE` and `DSB_BOX` variables are intended primarily for
for use in yaml files and allow you to format these
files without being tied to a specific location of
mounted directories in the host system.

The `DSB_COMPOSE` variable contains the full path of the `.dsb/compose` directory,
where the `.dsbenv` file and project yaml files are located.
The path of this directory is specified as an option.
[`--project-directory`](https://docs.docker.com/compose/reference/#specifying-multiple-compose-files)
on all internal calls to the `docker-compose` utility.

The `DSB_LIB_UTILS` and `DSB_LIB_SKEL` variables contain the full paths of the utility
Dsb directories mounted in containers in readonly mode to support
user [`dsbuser`](#dsbuser-account),
subcommands [`dsb sh`](#dsb-sh), [`dsb root`](#dsb-root)
and [host scripts](#host-scripts)
(see `lib/utils` and `lib/skel` subdirectories in this git repository
and description [`dsb yaml`](#dsb-yaml)).

> If there is a `.dsb/skel` directory, the subcommand [`dsb yaml`](#dsb-yaml)
substitutes the mount point `$DSB_BOX/skel:/dsbskel:ro` into the yaml file
instead of `$DSB_LIB_SKEL:/dsbskel:ro`.

The variables `DSB_UID`, `DSB_GID` and `DSB_UID_GID` are intended
for use in yaml files. Variable `DSB_UID_GID`
used, in particular, as a call parameter
service script `adduser.sh` in `entrypoint` element
yaml files (see [`dsb yaml`](#dsb-yaml)).


### `.dsbenv` file variables

* [`COMPOSE_FILE`](#compose_file)
* [`COMPOSE_...`, `DOCKER_...`](#compose_-docker_)
* [`DSB_COMPOSE_FILE_VERSION`](#dsb_compose_file_version)
* [`DSB_HOME_VOLUMES`](#dsb_home_volumes)
* [`DSB_PROD_MODE`](#dsb_prod_mode)
* [`DSB_PROJECT_ID`](#dsb_project_id)
* [`DSB_SERVICE_...`](#dsb_service_)
* [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout)
* [`DSB_SPACE`](#dsb_space)
* [`DSB_UMASK_ROOT`](#dsb_umask_root)
* [`DSB_UMASK_SH`](#dsb_umask_sh)

In addition to the above variables in the file [`.dsbenv`](#dsbenv-file)
arbitrary user variables can be set.
All specified variables are automatically exported to [yaml files](#yaml-files).

Immediately after calling `.dsbenv`, the value of the variable is automatically set:
* [`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/reference/envvars/#compose_project_name)

Please note that all external variables with prefixes
`DSB_`, `DSBUSR_`, `COMPOSE_`, `DOCKER_` at the beginning
`dsb` utility work is reset - assign values
such variables are allowed only in the file [`.dsbenv`](#dsbenv-file).

> The `DSBUSR_` prefix is ​​for custom
variables whose values ​​must be reset at the start of the `dsb` utility.


---

#### `COMPOSE_FILE`

The variable is required and contains a list of names of the yaml files of the Dsb project.
A colon is used as a separator character for yaml files. Example:

     COMPOSE_FILE="globals.yaml:py.yaml"

The `globals.yaml` file is a required element of the list - it contains
contains general project network settings.

See also:

* [Compose CLI environment variables - COMPOSE_FILE](https://docs.docker.com/compose/reference/envvars/#compose_file)
* [Specifying multiple Compose files](https://docs.docker.com/compose/reference/#specifying-multiple-compose-files)

---

#### `COMPOSE_...`, `DOCKER_...`

Variables that set the operating modes of the Docker and Docker Compose utilities:

* [Compose CLI environment variables](https://docs.docker.com/compose/reference/envvars/)

Note that the value of the variable
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/reference/envvars/#compose_project_name)
set automatically by the [`dsb`](#dsb-utility) utility.

The requirements for the `COMPOSE_FILE` variable are set out [separately](#compose_file).

---

#### `DSB_COMPOSE_FILE_VERSION`

The version of the yaml file set by the [`dsb yaml`](#dsb-yaml) subcommand
in output template yaml file:

     version: '3.3'

The initial value of the variable is set at run time
subcommands [`dsb init`](#dsb-init).

Default value: `3.3`

> All project yaml files must contain the same version value.

See also: [Compose file version](https://docs.docker.com/compose/compose-file/compose-versioning/)

---

#### `DSB_HOME_VOLUMES`

The `true` value of this variable enables the mode of storing home directories of
user [`dsbuser`](#dsbuser-account)
as named volumes:

     DSB_HOME_VOLUMES=true

In this mode, the [`dsb yaml`](#dsb-yaml) subcommand automatically adds to the yaml file
the appropriate mount point.

> The mode is automatically activated when calling the [`dsb init`](#dsb-init) subcommand on macOS.

---

#### `DSB_PROD_MODE`

__Experimental mode - support may change__

The `true` value of this variable enables the production mode of the utility
[`dsb`](#dsb-utility-subcommands):

     DSB_PROD_MODE=true

Subcommand support is disabled in this mode
[`dsb clean`, `dsb clean-...`](#dsb-clean-dsb-clean-)
and guaranteed not to change the access rights of all
existing subdirectories [`.dsb` directories](#dsb-directory).

By default, the mode is disabled.

---

#### `DSB_PROJECT_ID`

The variable specifies the unique ID of the Dsb project within the host system.
In the value, you can use Latin letters A-Z, a-z, symbols "_", "-" and numbers 0-9.

The initial random value of the identifier is set by the subcommand
[`dsb init`](#dsb-init).
If desired, this value can be immediately changed to a more visual one.

Identifier is used as a component
[compose project name](https://docs.docker.com/compose/reference/envvars/#compose_project_name),
which is assigned to a variable
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/reference/envvars/#compose_project_name)
and passed to the [`docker-compose`](https://docs.docker.com/compose/reference/) utility
as the `--project-name` (or `-p`) option.

Please note that the project name is included as part of the names
containers and named volumes, so when you change the ID, you should
previously remove existing containers and volumes of the project:

    $ dsb compose down -v

See also:
* [FAQ: How do I run multiple copies of a Compose file on the same host?](https://docs.docker.com/compose/faq/#how-do-i-run-multiple-copies-of-a-compose-file-on-the-same-host)

---

#### `DSB_SERVICE_...`

Variables are used when executing [host scripts](#host-scripts)
and set the mapping of fixed aliases to specific service names:

    DSB_SERVICE_PYTHON=py

Variable names must be in upper case.

Each variable `DSB_SERVICE_...` corresponds to an alias string obtained from
from the variable name by dropping the `DSB_SERVICE_` prefix and then
adding a `@` character to the beginning. For example, the variable `DSB_SERVICE_PYTHON`
in host scripts will match the `@PYTHON` alias.

If desired, you can set a default service for aliases that do not fall under
the effect of specific variables `DSB_SERVICE_...`. For this, it is used
variable `DSB_SERVICE`.

Further see: [Service aliases](#service-aliases)

> Aliases prefixed with `@DSB_` are reserved for future use.

---

#### `DSB_SHUTDOWN_TIMEOUT`

The variable sets the timeout for shutting down containers in seconds:

     DSB_SHUTDOWN_TIMEOUT=10

The value of the variable is used as the value of the `-t` option
when calling commands internally:
`docker-compose stop`,
`docker-compose down`,
`docker-compose up`,
`docker-compose restart`,
`docker container stop`,
`docker container restart`.

---

#### `DSB_SPACE`

The variable is used in output yaml files of the
[`dsb yaml`](#dsb-yaml) subcommand
and specifies the default mounted directory of the Dsb project:

```
volumes:
  - $DSB_SPACE:/dsbspace
```

The use of the variable is optional - it's just
provides a way to easily configure a common mounted directory
for all Dsb project services.

The initial value of `DSB_SPACE` is the same as the value of the
[`DSB_ROOT`](#base-dsb-variables) variable (the full path of the Dsb root directory).
This value can be explicitly changed in the [`.dsbenv`](#dsbenv-file) file
to the path of any other directory in the host system.
If the mounted directory is in the Dsb root directory,
it is recommended to set the value with the `DSB_ROOT` variable.
Example:

    DSB_SPACE="$DSB_ROOT/src"

---

#### `DSB_UMASK_ROOT`

The variable specifies a fixed value for the file creation mode mask `umask`
when executing the [`dsb root`](#dsb-root) subcommand.

Example:

    DSB_UMASK_ROOT="0022"

In the absence of a variable, the file creation mode mask is set by default,
matching the current `umask` value on the host system command line
when calling the [`dsb root`](#dsb-root) subcommand.

At the individual service level, the value of `umask` can be explicitly fixed
using the `DSB_UMASK_ROOT` variable in the corresponding yaml file.

Example:

```
environment:
  DSB_UMASK_ROOT="0027"
  ...
```

(the `umask` value must be quoted in this case)

---

#### `DSB_UMASK_SH`

The variable specifies a fixed value for the file creation mode mask `umask`
when executing the [`dsb sh`](#dsb-sh) subcommand.

Example:

    DSB_UMASK_SH="0022"

In the absence of a variable, the file creation mode mask is set by default,
matching the current `umask` value on the host system command line
when calling the [`dsb sh`](#dsb-sh) subcommand.

At the individual service level, the value of `umask` can be explicitly fixed
using the `DSB_UMASK_SH` variable in the corresponding yaml file.

Example:

```
environment:
  DSB_UMASK_SH="0027"
  ...
```

The value of `umask` must be quoted in this case.

---


### Variables available in yaml files

In [yaml files](#yaml-files) all
[basic Dsb variables](#base-dsb-variables)
and arbitrary variables set in files
[`.dsbenv` and `.env`](#dsbenv-file).
In particular, base variables are available:

* `DSB_ROOT` - full path of the Dsb root directory;
* [`DSB_SPACE`](#dsb_space) - the default value is the same as the value of the `DSB_ROOT` variable,
but can be explicitly overridden at the file level [`.dsbenv`](#dsbenv-file);
* `DSB_BOX` - full path of `.dsb` directory;
* `DSB_LIB_UTILS` is the full path of the `lib/utils` subdirectory of this git repository;
* `DSB_LIB_SKEL` - full path of the `lib/skel` subdirectory of this git repository;
* `DSB_UID` - `UID` of the host user;
* `DSB_GID` - `GID` of host-user;
* `DSB_UID_GID` - host user's `UID:GID` string.

Variables `DSB_ROOT`, `DSB_SPACE` and `DSB_BOX` are used
in host directory mount directives:

* `DSB_ROOT` and [`DSB_SPACE`](#dsb_space) support mounting (in portable form)
arbitrary subdirectories of the Dsb root directory;
* `DSB_BOX` is used to mount configuration files and directories,
located in the internal subdirectories `.dsb/config`, `.dsb/logs` and `.dsb/storage`.

The remaining base variables are used in directives,
automatically added to the yaml file with the [`dsb yaml`](#dsb-yaml) subcommand.
  
---

### Variables available in host scripts

At the initial moment of the call to the host script, variables are available:

* `DSB_SCRIPT_NAME` - host script name;
* `DSB_SCRIPT_PATH` - full path of the host script;
* `DSB_WORKDIR` - full path of the current working directory
at the time of the call.

After successful execution of the function [`dsb_set_box`](#dsb_set_box)
or [`dsb_set_single_box`](#dsb_set_single_box)
the script has access to
[base project variables](#base-dsb-variables) and
[`.dsbenv` file variables](#dsbenv-file-variables).

After each function call [`dsb_get_container_id`](#dsb_get_container_id)
its output variables are available:
`DSB_CONTAINER_ID`, `DSB_CONTAINER_SERVICE` and `DSB_CONTAINER_STATUS`.


Functions available in host scripts
-----------------------------------

* [`dsb_docker_compose`](#dsb_docker_compose)
* [`dsb_map_env`](#dsb_map_env)
* [`dsb_resolve_files`](#dsb_resolve_files)
* [`dsb_run_as_root`](#dsb_run_as_root)
* [`dsb_run_as_user`](#dsb_run_as_user)
* [`dsb_set_box`](#dsb_set_box)
* [`dsb_get_container_id`](#dsb_get_container_id)
* [`dsb_set_single_box`](#dsb_set_single_box)
* [`dsb_...message`](#dsb_message)

---

### `dsb_docker_compose`

    dsb_docker_compose ...<docker-compose-args>

Calling the `docker-compose` command in the context of the current Dsb project.

Options are automatically added to the command:

* `--project-name` - Compose project name, formed based on the value of [`DSB_PROJECT_ID`](#dsb_project_id);
* `--project-directory` is the full path of the `.dsb/compose` directory.

The current directory when the command is invoked is `.dsb/compose`.

For command are available
[base project variables](#base-dsb-variables) and
[`.dsbenv` file variables](#dsbenv-file-variables)
(in particular, [`COMPOSE_FILE`](#compose_file)
and [`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/reference/envvars/#compose_project_name)).

The command also has access to external variables of the host environment, with the exception of variables
forcibly reset at the beginning of the execution of the host script
(variables with prefixes `DSB_`, `DSBUSR_`, `DSBLIB_`, `COMPOSE_`, `DOCKER_` are reset).

Example:

    #!/usr/bin/env dsb-script
    MYSERVICES="$( dsb_docker_compose config --services )"
    for NAME in $MYSERVICES ; do
        echo "$NAME"
    done


---

### `dsb_map_env`

     dsb_map_env VARNAME1 VARNAME2 ...

The function specifies a list of host script variable names that should
be exported to the container when calling functions
[`dsb_run_as_user`](#dsb_run_as_user)
and [`dsb_run_as_root`](#dsb_run_as_root).

Each call to the `dsb_map_env` function overrides previous calls.
Calling a function with no parameters overrides all previous calls.

Example:

     #!/usr/bin/env dsb-script
     dsb_map_env MYHOSTVAR
     MYHOSTVAR="Host variable value"
     dsb_run_as_user "@PYTHON" python -c "import os ; print(os.environ['MYHOSTVAR'])"

---

### `dsb_resolve_files`

    dsb_resolve_files EXT1 EXT2 ...

The function specifies a list of file extensions whose relative paths
when performing functions
[`dsb_run_as_user`](#dsb_run_as_user)
and [`dsb_run_as_root`](#dsb_run_as_root)
should be cast to absolute form to display in appropriate paths
inside the container.

The need for such a preliminary step may arise when calling the host script
in the IDE, when the current directory is not in the mounted directory,
and the file specified as a parameter is included.

Example:

    #!/usr/bin/env dsb-script
    dsb_resolve_files php
    dsb_run_as_user "@PHP" php "$@"

The function only applies to files located in the home
directory of the host user (the HOME host variable is used for verification).
The selection criterion for parameters for preliminary
converting to absolute paths is simply the presence in the value
corresponding suffix.

Each call to `dsb_resolve_files` undoes previous calls.
Calling a function with no parameters overrides all previous calls.

---

### `dsb_run_as_root`

     dsb_run_as_root SERVICE COMMAND [ ...COMMAND_ARGS ]
     dsb_run_as_user @ALIAS COMMAND [ ...COMMAND_ARGS ]

The function is similar to the function [`dsb_run_as_user`](#dsb_run_as_user)
with the only difference that the command is executed in a container
with `root` user rights.

See also: [dsb root](#dsb-root), [Service aliases](#service-aliases)

---

### `dsb_run_as_user`

    dsb_run_as_user SERVICE COMMAND [ ...COMMAND_ARGS ]
    dsb_run_as_user @ALIAS COMMAND [ ...COMMAND_ARGS ]

The function executes a command in a container with `dsbuser` user rights.

The execution of a function is subject to
previously executed functions [`dsb_map_env`](#dsb_map_env)
and [`dsb_resolve_files`](#dsb_resolve_files).

As the first parameter of a function call, you can specify
service name (`SERVICE`) or [alias](#service-aliases) prefixed with `@` (`@ALIAS`).
Mapping aliases to specific service names
set in the file [`.dsbenv`](#dsbenv-file) using variables
[`DSB_SERVICE_...`](#dsb_service_).

> When working with scaled services, the name of the service or alias
can be padded with a colon
[container index](#container-indexes).

If the current directory in the script at the time of the function call is
within the boundaries of the [mounted directory](#mounted-directories) of the service,
it is also set as the current one when the command is executed
in a container. When passing command parameters containing
full paths of host system files, automatic
substitution of the paths of these files in the context of the container.

More details of displaying the current directory and paths
files into a container context are outlined in the section:
[Execute commands in containers](#execute-commands-in-containers).

See also: [dsb sh](#dsb-sh), [Service aliases](#service-aliases), [Container indexes](#container-indexes)

---

### `dsb_set_box`

    dsb_set_box [ --check ] [ --dir STARTDIR ]

The function searches for [Dsb root directory](#terms)
and initializes [base Dsb variables](#base-dsb-variables).

An explicit call to this function must be preceded in the host script
call all other Dsb functions except
[`dsb_map_env`](#dsb_map_env) and [`dsb_resolve_files`](#dsb_resolve_files).
Otherwise, this function is called internally by default
without parameters.

In the absence of the `--dir` option, the search for the Dsb root directory is performed
starting from the current host script call directory. If there is a search option
starts at the directory specified as the option value.

> The `--dir` option allows you to unambiguously bind host scripts
to specific Dsb projects in the host system. Calling such scripts, unlike
subcommands of the `dsb` utility and typical host scripts,
can be executed from an arbitrary current directory.

With the `--check` option, a conditional search for the root directory is performed,
and if none is found, the function exits with a return code of `1`.
In this case, the function call can be repeated with other parameters.
On success, the function exits with code `0`.

If the `--check` option is missing and the function fails
the host script is terminated immediately.

Calling the function again after it has successfully completed is simply ignored.
If you need to refer to several Dsb projects in one script
(with different values ​​of the `--dir` option),
then to refer to each Dsb project, you should use a separate
[subshell block](https://tldp.org/LDP/abs/html/subshells.html).

See also: [dsb_set_single_box](#dsb_set_single_box)

---

### `dsb_get_container_id`

    dsb_get_container_id SERVICE [ --anystatus ]
    dsb_get_container_id @ALIAS [ --anystatus ]

The function allows you to get a specific container ID, which
further can be used when calling various subcommands of the utility
[`docker`](https://docs.docker.com/engine/reference/commandline/docker/)

As the first parameter of a function call, you can specify
service name (`SERVICE`) or [alias](#service-aliases) (`@ALIAS`)
prefixed with `@`. Mapping aliases to specific service names
set in the file [`.dsbenv`](#dsbenv-file) using variables
[`DSB_SERVICE_...`](#dsb_service_).

When working with scaled services, the name of the service or alias
can be padded with a colon
[container index](#container-indexes).

Upon successful execution of the function, the values ​​are set
following output variables:

* `DSB_CONTAINER_ID` - container identifier;
* `DSB_CONTAINER_SERVICE` - the name of the Compose service to which the container belongs;
* `DSB_CONTAINER_STATUS` - container status.

> The contents of the specified output variables may change as a result of subsequent
calling the functions `dsb_run_as_root` and `dsb_run_as_user`.

If there is no `--anystatus` option, the function succeeds
only if there is a container with a status of `running`.
Otherwise, the host script will stop immediately.

If the `--anystatus` option is used, the function ends
with return code `0` if there is a container with any status.
If there is no container, the function exits with a return code of `1`.

The result of the last function call when there is a container is always cached
and subsequent function calls without the `--anystatus` option for the same service
determine the presence of the container and its status by the contents of the internal cache.
Calls with the `--anystatus` option always check the current state of the container.

---

### `dsb_set_single_box`

    dsb_set_single_box [ --check ]

The function supports an additional option to search for the project configuration,
designed for the case when there are only containers of one Dsb project in the host system.
In this case, an internal function call is made
[`dsb_set_box`](#dsb_set_box) with the corresponding value of the `--dir` option.

An explicit call to this function must be preceded in the host script
call all other Dsb functions except
[`dsb_map_env`](#dsb_map_env) and [`dsb_resolve_files`](#dsb_resolve_files).
Otherwise, the default function call is [`dsb_set_box`](#dsb_set_box)
without parameters.

Example:

    #!/usr/bin/env dsb-script
    dsb_set_single_box
    dsb_resolve_files js
    dsb_run_as_user "@NODE" node "$@"

The absence of containers in the host system or the presence of containers,
related to multiple projects causes the function to fail.
With the `--check` option, the function simply exits with a return code of `1`.
In the absence of this option, the operation of the host script is immediately terminated.

Calling a function again after it has successfully completed, or calling after
success [`dsb_set_box`](#dsb_set_box)
is simply ignored.

See also: [dsb_set_box](#dsb_set_box)

---

### `dsb_...message`

     dsb_message MESSAGE
     dsb_green_message MESSAGE
     dsb_red_message MESSAGE
     dsb_yellow_message MESSAGE

Functions for displaying color messages.

The `dsb_message` function outputs a message to the STDOUT output stream.
The rest of the functions print messages to the STDERR output stream.

---

Firewall configuration on Linux
===============================

When using some easy firewall configuration utility (UFW, GUFW,
CSF, etc.), keep in mind that Docker dynamically adds its own
rules directly into the Netfilter system firewall tables, bypassing
the configuration of the specified utilities and ignoring the logic of their work.
This can lead to conflict situations and undesirable
consequences - Docker rules may violate intended policy
security or may be removed from Netfilter when upgrading
simplified firewall configuration.
So to share Docker and utilities
firewall configuration requires additional configuration steps,
utility-specific:

* [Option to configure UFW and GUFW utilities](https://github.com/chaifeng/ufw-docker)

The essential point is to provide access from containers
to host system services. An example of such an interaction is
debugging PHP code, in which the debugging module running in the container
PHP-Xdebug connects to IDE running directly
in the host system. In the firewall for incoming Xdebug traffic
the corresponding TCP port and IP address of the container must be opened.

Docker allocates IP addresses to containers dynamically using ranges
`10.0.0.0/8`, `172.16.0.0/12` and `192.168.0.0/16`.
IP addresses can change when containers are restarted.

> The current IP address and virtual subnet of a running container can be found
using the `dsb ip` command.

The above ranges of IP addresses can also be used in the work
home network and other local networks (Internet cafes, coworking, etc.).
Therefore, it is recommended to limit Docker to only one range `172.16.0.0/16`
specifying it in the configuration file `/etc/docker/daemon.json`:

    {
        mtu: 1450
        "default-address-pools": [
            { "base": "172.16.0.0/16", "size": 24 }
        ]
    }

(creating/editing `daemon.json` is done in root mode)

In this case, it is enough to set an allow rule in the firewall
only for subnet `172.16.0.0/16`.

__Links:__

* [Docker and iptables](https://docs.docker.com/network/iptables/)
* [https://github.com/chaifeng/ufw-docker](https://github.com/chaifeng/ufw-docker)

---
