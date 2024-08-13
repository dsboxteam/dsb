
> THIS IS BETA VERSION  (__git history can be reset__)  
We apologize for the unreadable text in some README sections.
The text is in the process of being translated into human english.

Dsb
===

Dsb is a wrapper application for
[Docker Compose](https://docs.docker.com/compose/).
It provides a user-friendly interface for accessing containers on a local machine
and simplifies the day-to-day use of CLI applications running in containers.
Here, containers act just as an extension of the host system's runtime environment
for running such applications.
The same approach can also be used when developing applications.

Supported operating systems: Linux, macOS.

To use Dsb it is necessary to be familiar with Docker Compose.
Some knowledge of [Bash scripting](https://tldp.org/LDP/abs/html/index.html)
is also helpful.

Dsb is compatible with most ready-made Docker images, from busybox
to entire OS images. No image rebuilding is required.
Container management (start, stop, shutdown, configuration, etc.) is performed
via simplified subcommands of the [`dsb`](#dsb-utility) utility.
The [`dsb compose`](#dsb-compose) subcommand can be used
to access the full range of Compose CLI commands.

The [`dsb`](#dsb-utility) utility has two subcommands for executing commands
in containers: [`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root).
The [`dsb sh`](#dsb-sh) executes commands with file access rights of the current host system's user.
The [`dsb root`](#dsb-root) behaves similar to [`dsb sh`](#dsb-sh), but executes
commands in root mode.
User's host system directories are mapped to containers using "bind mounts".
Running the [`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root) without specifying
container commands starts the shell of the corresponding container.
If possible, the host system's current working directory is set in the container.

For more convenience, Dsb supports execution of frequently used
container commands via [Dsb scripts](#dsb-scripts),
which can be called identically to the container's native commands,
just under different names. This allows to run container commands
almost as if they were present directly on a host system
(useful for seamless integration with IDE settings).

The `dsbscripts` subdirectory of this repository contains a collection
of ready-made Dsb scripts for some developer commands.
Most of the scripts consist of a couple of lines of self-evident code.
You can easily extend this collection yourself.

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
            * [Using variables in yaml files](#using-variables-in-yaml-files)
            * [`globals.yaml` file](#globalsyaml-file)
        * [Mounted directories](#mounted-directories)
    * [`dsb` utility](#dsb-utility)
        * [Service management](#compose-service-management)
        * [Executing commands in containers](#executing-commands-in-containers)
            * [Mapping the working directory](#mapping-the-working-directory)
            * [Mapping file paths in parameters](#mapping-file-paths-in-parameters)
            * [Setting up a profile in a container](#setting-up-a-profile-in-a-container)
            * [Setting `umask`](#setting-umask)
        * [`dsbuser` account](#dsbuser-account)
        * [Container indexes](#container-indexes)
        * [Custom subcommands](#custom-subcommands)
    * [Dsb scripts](#dsb-scripts)
        * [Service aliases](#service-aliases)
    * [Network access to the host system from containers](#network-access-to-the-host-system-from-containers)
    * [Removing Dsb projects from the host system](#removing-dsb-projects-from-the-host-system)
* [Reference](#reference)
    * [`dsb` utility subcommands](#dsb-utility-subcommands)
        * [`dsb cid`](#dsb-cid)
        * [`dsb compose`](#dsb-compose)
        * [`dsb down`](#dsb-down)
        * [`dsb help`](#dsb-help)
        * [`dsb init`](#dsb-init)
        * [`dsb ip`](#dsb-ip)
        * [`dsb logs`](#dsb-logs)
        * [`dsb ps`](#dsb-ps)
        * [`dsb restart`](#dsb-restart)
        * [`dsb rm-vols`](#dsb-rm-vols)
        * [`dsb root`](#dsb-root)
        * [`dsb scale`](#dsb-scale)
        * [`dsb sh`](#dsb-sh)
        * [`dsb start`](#dsb-start)
        * [`dsb stop`](#dsb-stop)
        * [`dsb var`](#dsb-var)
        * [`dsb vols`](#dsb-vols)
        * [`dsb yaml`](#dsb-yaml)
    * [Dsb project variables](#dsb-project-variables)
        * [Dsb base variables](#dsb-base-variables)
            * [`DSB_ROOT`](#dsb-base-variables)
            * [`DSB_BOX`](#dsb-base-variables)
            * [`DSB_UTILS`](#dsb-base-variables)
            * [`DSB_SKEL`](#dsb-base-variables)
            * [`DSB_UID`](#dsb-base-variables)
            * [`DSB_GID`](#dsb-base-variables)
            * [`DSB_UID_GID`](#dsb-base-variables)
        * [Variables defined in `.dsbenv` file](#variables-defined-in-dsbenv-file)
            * [`COMPOSE_FILE`](#compose_file)
            * [`COMPOSE_...`, `DOCKER_...`](#compose_-docker_)
            * [`DSB_ARGS_MAPPING`](#dsb_args_mapping)
            * [`DSB_HOME_VOLUMES`](#dsb_home_volumes)
            * [`DSB_PROD_MODE`](#dsb_prod_mode)
            * [`DSB_PROJECT_ID`](#dsb_project_id)
            * [`DSB_SERVICE_...`](#dsb_service_)
            * [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout)
            * [`DSB_SPACE`](#dsb_space)
            * [`DSB_STANDALONE_SYNTAX`](#dsb_standalone_syntax)
            * [`DSB_UMASK_ROOT`](#dsb_umask_root)
            * [`DSB_UMASK_SH`](#dsb_umask_sh)
            * [`DSBUSR_...`](#dsbusr_)
        * [Variables used in Dsb scripts](#variables-used-in-dsb-scripts)
            * [`DSB_OUT_...`](#variables-used-in-dsb-scripts)
            * [`DSB_SCRIPT_NAME`](#variables-used-in-dsb-scripts)
            * [`DSB_SCRIPT_PATH`](#variables-used-in-dsb-scripts)
            * [`DSB_WORKDIR`](#variables-used-in-dsb-scripts)
        * [Variables used in yaml files](#variables-used-in-yaml-files)
    * [Functions available in Dsb scripts](#functions-available-in-dsb-scripts)
        * [`dsb_docker_compose`](#dsb_docker_compose)
        * [`dsb_exec`](#dsb_exec)
        * [`dsb_get_container_id`](#dsb_get_container_id)
        * [`dsb_map_env`](#dsb_map_env)
        * [`dsb_resolve_files`](#dsb_resolve_files)
        * [`dsb_run_as_root`](#dsb_run_as_root)
        * [`dsb_run_as_user`](#dsb_run_as_user)
        * [`dsb_run_command`](#dsb_run_command)
        * [`dsb_run_dsb`](#dsb_run_dsb)
        * [`dsb_set_box`](#dsb_set_box)
        * [`dsb_set_single_box`](#dsb_set_single_box)
        * [`dsb_...message`](#dsb_message)
* [Appendices](#appendices)
    * [Configure MTU value](#configure-mtu-value)


---

User guide
==========

Terms
-----

* __host system__  
The operating system where Dsb is being used.

* __host user__  
The host system's user account under which Dsb is being used.

* __service__  
This [Docker Compose term](https://docs.docker.com/compose/compose-file/05-services/)
refers to a container or a group of containers
with one shared configuration labeled with a particular name
(further referred to as _service name_). In this guide,
the term can be considered synonymous with the term _container_,
unless we are talking about _scaled services_.

* __scaled service__  
Docker Compose _service_ with several running containers.
See [`dsb scale`](#dsb-scale), [Container indexes.](#container-indexes) for details.

* __Dsb project__  
[Docker Compose project](https://docs.docker.com/compose/features-uses/#have-multiple-isolated-environments-on-a-single-host)
extended with Dsb configuration.
Each Dsb project is bound to a certain host system's directory
further referred to as _Dsb root directory_.
See [Dsb project structure](#dsb-project-structure) for details.

* __dsb utility__  
A CLI utility named `dsb` that provides a user interface for working with Dsb projects.
See [`dsb` utility](#dsb-utility) and [`dsb` subcommands](#dsb-utility-subcommands)
for details.

* __Dsb root directory__  
A host system's directory containing a `.dsb` subdirectory
and one or more subdirectories used as _mounted directories_
(the directory itself can also be _mounted directory_).
There can be several _Dsb root directories_ on a host system,
but they must not overlap.
See [Dsb project structure](#dsb-project-structure) for details.    

* __mounted directory__  
A host system's directory that is exposed to one or more containers using
[bind mounts](https://docs.docker.com/storage/bind-mounts/).
There can be any number of _mounted directories_ on a host system.
They can overlap. See [Mounted directories](#mounted-directories) for details.

* __.dsb directory__  
A child subdirectory named `.dsb` of the Dsb root directory that contains the Dsb project's configuration.
This subdirectory is initialized using the [`dsb init`](#dsb-init) subcommand.
See [`.dsb` directory](#dsb-directory) for details.

* __.dsbenv file__  
Bash source file that contains [Dsb project variables](#variables-defined-in-dsbenv-file)
and [Docker Compose variables](https://docs.docker.com/compose/environment-variables/envvars/).
It serves the same purpose as an
[.env file](https://docs.docker.com/compose/environment-variables/env-file/) in Docker Compose.
The file is placed in the `.dsb/compose` directory.
See [`.dsbenv` file](#dsbenv-file) for details.

* __yaml file__  
A file with a `.yaml` extension containing the
[definition of a single _service_](https://docs.docker.com/compose/compose-file/05-services/).
In Dsb, _yaml files_ are stored in the `.dsb/compose` directory.
The list of enabled _yaml files_ is specified manually using the [`COMPOSE_FILE`](#compose_file)
variable in the [`.dsbenv` file](#dsbenv-file).  
See [Yaml files](#yaml-files), [`dsb yaml`](#dsb-yaml) for details.

* __dsbuser__  
Container's account named `dsbuser` with the same `UID` and `GID` as the _host user's_ ones.
This account is created in Dsb project's containers every time they are started.
See [`dsbuser` account](#dsbuser-account), [`dsb yaml`](#dsb-yaml) for details.

* __Dsb script__  
An executable Bash script that containes shebang string `#!/usr/bin/env dsb-script`
and [Dsb function](#functions-available-in-dsb-scripts) calls.
See [Dsb scripts](#dsb-scripts) for details.

Installation
------------

### Prerequisites on Linux

* [Docker Engine](https://docs.docker.com/engine/install/) (v19.03.0+)
or [Docker Desktop](https://docs.docker.com/desktop/install/linux-install/)
* [Docker Compose](https://docs.docker.com/compose/install/) (v1.27.0+)

The host system must also have the following commands:
`bash (v4.4+)`, `cp`, `cut`, `env`, `find`,
`id`, `ls`, `md5sum`, `readlink`, `rm`.
On Linux distributions, the necessary commands are usually installed by default.
Missing commands (packages) can be installed later if the `dsb` command prints
the corresponding diagnostic messages.

If you chose to install Docker Engine as the container runtime, you need to perform
additional post-installation steps:
* [Create and configure the `docker` group](https://docs.docker.com/engine/install/linux-postinstall/)
* [Configure MTU value](#configure-mtu-value) (if needed)

### Prerequisites on macOS

* [Homebrew](https://brew.sh/) package manager
* Bash (`brew install bash`)
* GNU coreutils (`brew install coreutils`)
* [Docker Desktop for macOS](https://docs.docker.com/desktop/install/mac-install/)

As an alternative for Docker Desktop,
you can also use [Colima](https://github.com/abiosoft/colima):

    brew install colima
    brew install docker docker-compose
    colima start
    ...


### Install Dsb

This git repository serves also as the installation package.
To install Dsb, place the contents of the repository in any suitable location
on the host system. Using the contents requires only "file read"
permission, and "execute" permission for scripts in the `bin`
and `dsbscripts` subdirectories.
"Write" permission is not required.

Add the full paths to the `bin` and `dsbscripts` subdirectories to the `PATH` variable.
To do this, place the following line somewhere in the `~/.profile` file:

    export PATH=<dsb_repository>/bin:<dsb_repository>/dsbscripts:$PATH

Note that scripts in the `dsbscripts` subdirectory are just examples.
If you plan to modify them or add additional Dsb scripts,
you can instead move them to some local directory and add it to the PATH variable.

After updating `~/.profile`, re-login to activate the new `PATH` value.
Run the `dsb` command without parameters to be sure that the installation was successful:

    $ dsb

A summary of the `dsb` subcommands will be printed.


Getting started
---------------

### Creating Dsb project

Let's create a simple Dsb project with one service `py` for the Docker image `python:alpine`:

    $ docker pull python:alpine
    $ mkdir ~/dsbexample
    $ cd ~/dsbexample
    $ dsb init
    $ dsb yaml py python:alpine
    $ mkdir src
    $ echo 'print("Hello from Python!")' > src/hello.py

Here:

* The `mkdir ~/dsbexample` command creates a subdirectory in the host user's home directory,
which will be used as [Dsb root directory](#dsb-project-structure).
* The [`dsb init`](#dsb-init) command initializes the [Dsb root directory](#dsb-project-structure)
by creating a [`.dsb`](#dsb-directory) subdirectory and filling it with the initial template
(see the `lib/init` subdirectory in this git repository).
* The `dsb yaml py python:alpine` command generates a service configuration file
`.dsb/compose/py.yaml` for the `python:alpine` service named `py`.
* The last two commands create a sample Python program in the `src` subdirectory
of the Dsb root directory.

To activate the just-created [yaml file](#yaml-files) in the Dsb project,
add the `py.yaml` substring to the value of the [`COMPOSE_FILE`](#compose_file)
variable in the [`.dsb/compose/.dsbenv`](#dsbenv-file) file:

    COMPOSE_FILE="globals.yaml:py.yaml"

This git repository already contains [Dsb scripts](#dsb-scripts) for running
Python commands: `dsbpython`, `dsbpython2`, `dsbpython3`, and `dsbpip`.
The listed Dsb scripts are bound by default to services with names `python`, `python2`, and `python3`.
So, assign the appropriate value to [`DSB_SERVICE_...`](#dsb_service_) variables
in the [`.dsb/compose/.dsbenv`](#dsbenv-file) file:

    DSB_SERVICE_PYTHON=py
    DSB_SERVICE_PYTHON2=py
    DSB_SERVICE_PYTHON3=py

> See also [Service aliases](#service-aliases).


Each Dsb project has a unique identifier on the host system, that is specified by
[`DSB_PROJECT_ID`](#dsb_project_id) variable in the [`.dsb/compose/.dsbenv`](#dsbenv-file) file.
The [`dsb init`](#dsb-init) command assigns an initial random value to this variable.
Let's assign it a more descriptive value:

    DSB_PROJECT_ID="dsbexample"

Now we have the Dsb project with the one service named `py`, which can be used
to run Python commands.

### Starting services
    
Start the Dsb project services (the one service in our case) and check its state:

    $ cd ~/dsbexample
    $ dsb start
    Starting Dsb ...
    docker compose --project-name dsb-dsbexample up -t 15 --detach --remove-orphans
    ✔ Network dsb-dsbexample_dsbnet  created
    ✔ Container dsb-dsbexample-py-1  Started

    $ dsb ps
    CONTAINER            SERVICE  STATE    STATUS         PORTS
    dsb-dsbexample-py-1  py       running  Up 11 seconds

As we see from output, the name of the Docker Compose project begins with the `dsb-` prefix followed by the lowercase value of the [`DSB_PROJECT_ID`](#dsb_project_id) variable.

Note that there can be several Dsb projects on the host filesystem.
To work with different Dsb projects, you should invoke
[`dsb` utility](#dsb-utility) subcommands and Dsb scripts in the corresponding
[Dsb root directories](#dsb-project-structure).
So, we `cd` into the `~/dsbexample` directory before running
the [`dsb start`](#dsb-start) subcommand.

### Running container commands from the host system command line

Let's check the proper functioning of the [Dsb scripts](#dsb-scripts):

    $ dsbpython -V
    Python 3.11.2
    $ dsbpython2 -V
    Command 'python2' not found in the container
    $ dsbpython3 -V
    Python 3.11.2

As we see, the `python2` executable is missing in the `python:alpine` image.

The same actions in the container can also be performed
with the [`dsb sh`](#dsb-sh) subcommand:

    $ dsb sh py python -V
    Python 3.11.2
    $ dsb sh py python2 -V
    Command 'python2' not found in the container
    $ dsb sh py python3 -V
    Python 3.11.2

but the Dsb scripts syntax is more convenient in case of everyday use.

In this Dsb project we can run Dsb scripts in the
[Dsb root directory](#dsb-project-structure)
and in any of its subdirectories. This is because the default
[mounted directory](#mounted-directories) is defined as Dsb root directory:

```
# .dsb/compose/.dsbenv file:
DSB_SPACE="$DSB_ROOT"
  ...
# .dsb/compose/py.yaml file:
volumes:
  - $DSB_SPACE:/dsbspace
```
(see [`DSB_ROOT`](#dsb-base-variables) and
[`DSB_SPACE`](#dsb_space) variables)

Run a test program in a container using Dsb scripts
`dsbpython` and `dsbpython3`:

    $ dsbpython src/hello.py
    Hello from Python!
    $ cd src
    $ dsbpython3 hello.py
    Hello from Python!
    $ cd .. # return to Dsb root directory

Container commands have access to the input stream (STDIN) from the host system,
they can participate in pipes executed on the command line of the host system:

    $ dsbpython - < src/hello.py | cat
    Hello from Python!
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

    $ dsbpython
    Python 3.10.2 (main, Jan 29 2022, 03:40:37) [GCC 10.3.1 20211027] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> print('bla-bla-bla')
    bla bla bla
    ...
    >>> exit()
    $   # host system's command line

### Running arbitrary container commands

Any command in an arbitrary project container can also be executed
using the [`dsb sh`](#dsb-sh) command:

    $ dsb sh py python src/hello.py
    Hello from Python!
    $ cd src
    $ dsb sh py python3 hello.py
    Hello from Python!
    $ cd .. # return to Dsb root directory

(here `py` is the name of the corresponding service)

So far, we have been executing container commands on the host system's command line.
Commands can be executed directly on the container's command line:

    $ dsb sh py
    py:/dsbspace$   # container's command line
    py:/dsbspace$ pwd
    /dsbspace
    py:/dsbspace$ python src/hello.py
    Hello from Python!
    py:/dsbspace$ ls -ld *
    drwx------ 7 dsbuser dsbuser 4096 Feb 16 12:42 .dsb
    drwxrwxr-x 2 dsbuser dsbuser 4096 Feb 16 12:01 src
    py:/dsbspace$ cd src
    py:/dsbspace/src$ python hello.py
    Hello from Python!
    py:/dsbspace/src$ exit # leaving the container (or Ctrl+D)
    $   # host system's command line

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


From the listing above, you can see that the mounted directory files appear
in the container as files owned by the [`dsbuser`](#dsbuser-account) account
and a group of the same name.
These user and group are created in the container on startup
and have the same `UID` and `GID` as the host user's ones.

You can also work with the container in root mode. For this purpose it is intended
the [`dsb root`](#dsb-root) command which is called according to the same rules,
same as [`dsb sh`](#dsb-sh).

### Stopping the services

Stop project services without removing containers:

    $ dsb stop

Remove all project containers:

    $ dsb down

Remove all project containers and named volumes:

    $ dsb compose down -v

### Dsb script contents

At the end of the review, consider the contents of the Dsb script
`dsbpython`:

    #!/usr/bin/env dsb-script
    dsb_resolve_files py
    dsb_run_as_user "@PYTHON" python "$@"

For comparison, here are the texts of the Dsb scripts `dsbnode` and `dsbnpm`,
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
Dsb script.

> To run container commands in root mode,
you can use the Dsb function [`dsb_run_as_root`](#dsb_run_as_root).


Dsb project structure
---------------------

Each Dsb project provides support to one or several software projects
that share the same set of containers.

In the case of several software projects the Dsb project structure
may look like this:

```
Dsb root directory
   |__ .dsb directory
   |__ mounted directory 1
   |__ mounted directory 2
   |__ ...
```

Here, the mounted directories can be, for example, git repositories or some
of their subdirectories. Each mounted directory can be exposed to one
or more containers.

When working on a single software project, the simplified structure can be used:

```
Dsb root directory == git repository == mounted directory
  |__ .dsb directory
  |__ ...
```

```
Dsb root directory == git repository
  |__ .dsb directory
  |__ mounted subdirectory 1
  |__ mounted subdirectory 2
  |__ ...
```
(the latter variant is preferable for security reasons)

When placing the `.dsb` directory in a git working tree,
please pay attention to nested `.gitignore` files.


### `.dsb` directory

The `.dsb` directory contains configuration files of the Dsb project and possibly
persistent container data that should be preserved when containers are temporarily removed.

The contents of the directory can be considered as a "configuration package",
containing all the information needed to run a particular set of containers.
Such a "package" can be placed anywhere on the host's file system and can be shared
among developers using the same programming tools and services.

You can use prebuilt `.dsb` contents or initialize it from scratch
with the [`dsb init`](#dsb-init) subcommand. When initializing from scratch,
the [`dsb yaml`](#dsb-yaml) subcommand is also used.

The `.dsb` directory has the following structure:

```
.dsb
  |__ bin
  |__ compose
  |__ config
  |__ home
  |__ logs
  |__ skel
```

The purpose of subdirectories:

* `.dsb/bin` (optional)  
The directory contains project's [custom subcommands](#custom-subcommands) of the [`dsb`](#dsb-utility) utility.

* `.dsb/compose`  
The directory contains [yaml files](#yaml-files) of the Docker Compose services
and the [`.dsbenv` file](#dsbenv-file)
with [project variables](#variables-defined-in-dsbenv-file).

* `.dsb/config`  
The directory contains configuration files that are mounted in containers
and used by container processes.
Specific contents of the directory depend on the Docker images used in the Dsb project.

* `.dsb/home`  
The directory can be used to persist the home directories of the container `dsbuser` accounts.
You can also use
[named volumes](https://docs.docker.com/storage/volumes/#use-a-volume-with-docker-compose)
for this purpose.
See [`dsbuser` account](#dsbuser-account) and [`DSB_HOME_VOLUMES` variable](#dsb_home_volumes)
for details.

* `.dsb/logs`  
The directory contains a separate subdirectory for each service, with the same name,
which can be bind-mounted to the corresponding container and used to store log files
of the container's processes.

* `.dsb/skel` (optional)  
The directory, if present, contains a custom template that is used to initialize the home directory
of the [`dsbuser`](#dsbuser-account) account when it is first created in the container.
If not present, the [`dsb yaml`](#dsb-yaml) subcommand uses
the default template contained in the `lib/skel` subdirectory of this git repository.

You can add other subdirectories and files to the `.dsb` directory, if you wish.

Note that the [`dsb start`](#dsb-start) and [`dsb restart`](#dsb-restart) subcommands
automatically create subdirectories with the names of the Docker Compose services
in the `.dsb/home` and `.dsb/logs` directories.
Therefore, you just need to add appropriate bind-mounts directives
to the [yaml files](#yaml-files) in the `.dsb/compose` directory.
To make things easier, the [`dsb yaml`](#dsb-yaml) subcommand provides examples
of such directives when creating [yaml files](#yaml-files).

Also note that before starting containers,
the [`dsb start`](#dsb-start) and [`dsb restart`](#dsb-restart) subcommands assign
access permissions to services subdirectories of the `.dsb/home` and `.dsb/logs` directories.
Subdirectories of the `.dsb/logs` directory are assigned `a=rwx` access permissions.
That's because the main container workload can be run under arbitrary container's account.
Subdirectories of the `.dsb/home` directory are assigned `u=rwx,go-rwx` access permissions for security reasons.

If you wish, you can disable presetting access permissions for already existing subdirectories
by specifying [`DSB_PROD_MODE=true`](#dsb_prod_mode) in the [`.dsbenv` file](#dsbenv-file).


#### `.dsbenv` file

The `.dsbenv` file is used to define [Dsb configuration variables](#variables-defined-in-dsbenv-file).
It is stored in the [`.dsb/compose`](#dsb-directory) directory and serves the same purpose as an
[.env file](https://docs.docker.com/compose/environment-variables/env-file/)
in Docker Compose, the only difference being that it is a Bash source file.

> Using an .env file (`.dsb/compose/.env`) is also possible, but this file is redundant
and cannot replace the `.dsbenv` file. Its variables cannot be used in Dsb scripts.

When you create a [`.dsb`](#dsb-directory) directory, the [`dsb init`](#dsb-init) subcommand
populates the `.dsbenv` file with the original contents.
Then you just need to adjust the values of the [Dsb variables](#variables-defined-in-dsbenv-file)
and maybe define some custom variables specific to the Dsb project.

You should follow [Bash syntax rules](https://tldp.org/LDP/abs/html/variables.html)
when editing the file:

    SOMEVAR1=someValueWithoutSpaces
    SOMEVAR2="someValue"
    SOMEVAR3="somePrefix${SOMEOTHERVAR}someSuffix"
    ...

> Spaces are not allowed on either side of the assignment operator `=`.
The value of a variable can be enclosed in single or double quotes.
The `#` character is the beginning of the comment string.  
It should be noted that [Bash syntax](https://tldp.org/LDP/abs/html/variables.html)
is very similar to the
[.env file syntax](https://docs.docker.com/compose/environment-variables/env-file/)
in Docker Compose.

The following configuration variables can be defined:

* [`COMPOSE_FILE`](#compose_file) - the list of [yaml files](#yaml-files) of the Dsb project
* [`COMPOSE_...`, `DOCKER_...`](https://docs.docker.com/compose/reference/envvars/) - Docker Compose and Docker environment variables
* [`DSB_HOME_VOLUMES`](#dsb_home_volumes) - home directory placement option for [`dsbuser`](#dsbuser-account)
* [`DSB_PROD_MODE`](#dsb_prod_mode) - production mode option
* [`DSB_PROJECT_ID`](#dsb_project_id) - Dsb project ID, unique within the host system
* [`DSB_SERVICE_...`](#dsb_service_) - specific service names for [Dsb scripts](#dsb-scripts) (see [Service aliases](#service-aliases))
* [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout) - shutdown timeout for containers
* [`DSB_SPACE`](#dsb_space) - the full path to the default [mounted directory](#mounted-directories) (see [`dsb yaml`](#dsb-yaml))
* [`DSB_UMASK_ROOT`](#dsb_umask_root) - `umask` value for [`dsb root`](#dsb-root) subcommand
* [`DSB_UMASK_SH`](#dsb_umask_sh) - `umask` value for [`dsb sh`](#dsb-sh) subcommand
* [`DSBUSR_...`](#dsbusr_) - custom project variables

Please keep in mind:

* When assigning values to configuration variables, you can use [Dsb base variables](#dsb-base-variables).

* Сonfiguration variables [`COMPOSE_FILE`](#compose_file)
and [`DSB_PROJECT_ID`](#dsb_project_id) are mandatory.
The last one is used as part of the Compose project name,
that is automatically assigned to the 
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/environment-variables/envvars/#compose_project_name)
variable and passed to Compose CLI utility as the `--project-name` option.
You should never explicitly spicify Compose project name in Dsb.

* The [`dsb init`](#dsb-init) subcommand assign an initial random value to the [`DSB_PROJECT_ID`](#dsb_project_id) variable.
It is advisable to immediately change it to a more descriptive one.
The value must only contain Latin letters A-Z, a-z, symbols '_', '-' and digits 0-9.

* The list of [yaml files](#yaml-files) specified by the [`COMPOSE_FILE`](#compose_file) variable
must always include `globals.yaml`. The `globals.yaml` file is created by the [`dsb init`](#dsb-init) subcommand
and containes the Dsb project's network settings.

* The `.dsbenv` file is a Bash source file __that is executed__ as part of execution of the [`dsb` utility](#dsb-utility)
and [Dsb scripts](#dsb-scripts). The current working directory when executing the file
is the [`.dsb/compose`](#dsb-directory).
After executing the file, all variables with the prefixes `DSB_`, `DSBUSR_`, `COMPOSE_`, `DOCKER_`
are automatically exported and made available to Docker Compose CLI and other OS commands
called by the [`dsb` utility](#dsb-utility) and [Dsb scripts](#dsb-scripts).
All these variables can be used in [yaml files](#yaml-files).

For other details, see [Variables defined in `.dsbenv` file](#variables-defined-in-dsbenv-file).

See also [Yaml files](#yaml-files), [Environment variables in Compose](https://docs.docker.com/compose/environment-variables/).


#### Yaml files

Docker Compose allows to store project configuration as one or
[more yaml files](https://docs.docker.com/compose/reference/#specifying-multiple-compose-files).
In Dsb, the "more" option is used. All yaml files are stored in the `.dsb/compose` directory,
where the [`.dsbenv`](#dsbenv-file) file is located.

When creating the [`.dsb`](#dsb-directory) directory, the [`dsb init`](#dsb-init) subcommand
saves the default network settings in the [`globals.yaml`](#globalsyaml-file) file.
All other yaml files containing [definitions of separate services](https://docs.docker.com/compose/compose-file/05-services/)
are created using the [`dsb yaml`](#dsb-yaml) subcommand. Example:

    $ dsb yaml py python:alpine

When created, each yaml file already contains all the necessary elements to use Dsb.
You can then customize the file by adding other elements that the service requires.
To make things easier, the [`dsb yaml`](#dsb-yaml) subcommand provides commented examples
of some elements that can be used. These examples are based on parameters
extracted from the corresponding Docker image.

The list of enabled yaml files is set __manually__ using
the [`COMPOSE_FILE`](#compose_file) variable in the [`.dsbenv`](#dsbenv-file) file:

    COMPOSE_FILE="globals.yaml:py.yaml:mysql.yaml"

A quick way to activate changes made to the yaml files and to the value of the [`COMPOSE_FILE`](#compose_file)
variable is to execute the [`dsb start`](#dsb-start) subcommand without parameters.

See also [Compose Specification: Services top-level elements](https://docs.docker.com/compose/compose-file/05-services/)

##### Using variables in yaml files

In [yaml files](#yaml-files) you can use all [Dsb base variables](#dsb-base-variables)
as well as arbitrary custom variables with the [`DSBUSR_`](#dsbusr_) prefix
defined in the [`.dsbenv`](#dsbenv-file) file.
You can also use other custom variables defined in the [`.dsbenv`](#dsbenv-file) file,
but these variables are not automatically exported. So you must export them explicitly
in the `.dsbenv` file.

Using variables from the [Compose `.env` file](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file)
is also possible, but this file  (`.dsb/compose/.env`) is redundant in Dsb.

See also [Dsb base variables](#dsb-base-variables),
[`DSB_SPACE`](#dsb_space), [`DSBUSR_...` variables](#dsbusr_), [`dsb yaml`](#dsb-yaml).


##### `globals.yaml` file

File contains default settings of the Dsb project for
[Compose named network](https://docs.docker.com/compose/compose-file/06-networks/)
`dsbnet`.
This file can then be used to store other settings shared by project services.


with Compose top-level `networks` element


```
networks:
  dsbnet:
    driver:bridge
    driver_opts:
      com.docker.network.driver.mtu: MTU_VALUE
```

> When transferring a project configuration to another computer, you may need to
[adjusting the MTU value](#configure-mtu-value).

`dsbnet` is used as the name of the main project network in `globals.yaml`.
The same name is added to the yaml file templates generated by the subcommand
[`dsb yaml`](#dsb-yaml):

```
services:
  SERVICE_NAME:
    ...
    networks:
      dsbnet:
    ...
```

The presence of the specified `networks` element is the only
requirement for the design of yaml files. The presence of other elements depends
on the specifics of the service.


### Mounted directories

A mounted directory in this guide refers to a host system's directory
that is exposed to one or more containers using
[bind mounts](https://docs.docker.com/storage/bind-mounts/).
Such a directory could be, for example, a git repository or its subdirectory.

You can mount any number of host system's directories in a container.
The corresponding mount points can be arbitrary,
except for special mount points `/dsbutils`, `/dsbskel`, and `/dsbhome`,
which are used to mount Dsb helper directories and [`dsbuser`](#dsbuser-account)
home directory.

One optional mount point, `/dsbspace`, is generally used in Dsb if all host user's files
processed in the containers are located in the same mounted directory.
See the [`DSB_SPACE` variable description](#dsb_space) for details.

There are no strict restrictions on the location of mounted directories on a host system,
but given [the way the `dsb` utility looks for project configuration](#dsb-utility), 
it is reasonable to place the mounted directories inside the corresponding Dsb root directories.
In this case the [`dsb`](#dsb-utility-subcommands) subcommands and [Dsb scripts](#dsb-scripts)
can be executed anywhere in the mounted directories.

If you wish, you can prepare custom Dsb scripts associated with the fixed Dsb root directories
on the host system (see [`dsb_set_box --dir STARTDIR`](#dsb_set_box)).
Such scripts can be launched from any working directory,
and the mounted directories of the corresponding Dsb projects
can be outside the Dsb root directories.

In addition to host user's files being processed, mounted data may include internal container's data
that must be preserved when containers are temporarily removed.
Configuration files, log files, and other frequently viewed/edited files of this kind
should be placed in the [`.dsb`](#dsb-directory) subdirectories.
To persist databases and some other internal data, it is preferable to use
[Compose named volumes](https://docs.docker.com/compose/compose-file/07-volumes/).

See also
[Executing commands in containers](#executing-commands-in-containers),
[`dsb yaml`](#dsb-yaml).


`dsb` utility
-------------

The `dsb` utility provides a command line interface to work with Dsb projects.

Usage:

     $ dsb SUBCOMMAND [ ...PARAMETERS ]

The `dsb` utility looks for project configuration starting from the current
working directory up through the chain of parent directories
until the [Dsb root directory](#dsb-project-structure) is found
that directly contains the [`.dsb`](#dsb-directory) subdirectory.
To address the utility to different Dsb projects, you should run it
within the corresponding Dsb root directories.
See also [how to bind the `dsb` utility to a fixed Dsb project](#dsb_run_dsb).

Supported subcommands:

* Dsb project configuration:
    * [`dsb init`](#dsb-init) - create `.dsb` directory
    * [`dsb yaml`](#dsb-yaml) - create yaml file
* Execute commands in containers:
    * [`dsb sh`](#dsb-sh) - execute commands with [`dsbuser`](#dsbuser-account) access rights
    * [`dsb root`](#dsb-root) - execute commands with `root` access rights
* Service management:
    * [`dsb start`](#dsb-start) - start project services
    * [`dsb restart`](#dsb-restart) - restart project services
    * [`dsb stop`](#dsb-stop) - stop services without removing containers
    * [`dsb down`](#dsb-down) - stop services and remove containers
    * [`dsb scale`](#dsb-scale) - project service scaling
    * [`dsb ps`](#dsb-ps) - output the current status of project services
    * [`dsb rm-vols`](#dsb-rm-vols) - remove all or specified Compose volumes
    * [`dsb compose`](#dsb-compose) - execute an arbitrary Compose CLI command
* Auxiliary subcommands:
    * [`dsb help`](#dsb-help) - output the list of supported subcommands
    * [`dsb logs`](#dsb-logs) - output log records of a service or a single container
    * [`dsb cid`](#dsb-cid) - output Docker container ID
    * [`dsb ip`](#dsb-ip) - output an IP address of the container
    * [`dsb var`](#dsb-var) - output a Dsb variable value
    * [`dsb vols`](#dsb-vols) - output Compose and Docker names of project volumes
    * [`dsb CUSTOM_SUBCOMMAND`](#custom-subcommands) - [custom subcommands](#custom-subcommands)

All subcommands except [`dsb init`](#dsb-init), [`dsb down --host`](#dsb-down),
and [`dsb rm-vols --host`](#dsb-rm-vols) are executed in the context of particular Dsb projects.

A detailed description of the subcommands is given in the [Reference](#dsb-utility-subcommands).
A brief summary can be displayed by running the `dsb` command without parameters
or with the `dsb help` subcommand.

### Compose service management

The `dsb` utility supports a simplified set of subcommands for starting, stopping,
and shutting down services:
[`dsb start`](#dsb-start), [`dsb stop`](#dsb-stop), [`dsb restart`](#dsb-restart),
[`dsb down`](#dsb-down).

The [`dsb start`](#dsb-start) and [`dsb restart`](#dsb-restart) subcommands
always start services
in [`--detach` mode](https://docs.docker.com/compose/reference/up/).
The [`dsb start`](#dsb-start) subcommand without parameters
can be used to quickly activate changes made to [yaml files](#yaml-files).

Note that the [`dsb stop`](#dsb-stop) and [`dsb restart`](#dsb-restart) subcommands never destroy
containers. The [`dsb down`](#dsb-down) is used for that purpose.

The [`dsb compose`](#dsb-compose) subcommand provides access
to the full set of [Compose CLI commands](https://docs.docker.com/compose/reference/).

> The provided set of built-in `dsb` subcommands can be expanded by the user
with his own [custom subcommands](#custom-subcommands) and [Dsb scripts](#dsb-scripts).
The Dsb functions
[`dsb_set_box`](#dsb_set_box),
[`dsb_docker_compose`](#dsb_docker_compose), and
[`dsb_get_container_id`](#dsb_get_container_id)
will be useful in this case.


### Executing commands in containers

Dsb provides the following features for executing commands in containers:

* The [`dsb sh`](#dsb-sh) subcommand executes container's commands with access rights
of the [`dsbuser`](#dsbuser-account) account. This account is created in containers on startup
and has the same `UID` and `GID` values as the host user's ones.

* The [`dsb root`](#dsb-root) subcommand behaves similar to [`dsb sh`](#dsb-sh),
but executes container's commands with `root` access rights.

* [Dsb scripts](#dsb-scripts) can have a run syntax similar to the syntax
for running container's native commands. This allows to execute container's commands
almost as if they were present directly on a host system.
The scripts can be stored in any directory specified in the `PATH` environment variable,
and can be applied to any Dsb project on the host system.

* [Custom subcommands](#custom-subcommands) can be used to automate
frequently performed actions specific to particular Dsb project.
The subcommand files are stored in the `.dsb/bin` directory of the project.

Using the [`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root) subcommands
with only service name parameter simply runs the shell of the corresponding container:

    $ dsb sh py
    py:/dsbspace$  # container's command line
    py:/dsbspace$ pwd
    /dsbspace
    ...
    py:/dsbspace$ exit  # leaving the container (or Ctrl+D)
    $  # host system's command line

#### Mapping the working directory

When executing [`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root) subcommands,
and when calling [Dsb functions](#functions-available-in-dsb-scripts) in [Dsb scripts](#dsb-scripts), 
the host system's current working directory is mapped to the container's directory
if the former is within the boundaries of at least one mounted directory.

If the current working directory belongs to several nested mounted directories
with different access permissions (`readwrite` and `readonly`), the topmost level
directory with `readwrite` permissions is selected. If all mounted directories
have the same access permissions, the top level directory is selected.

If the current working directory of the host system is outside all the mounted
directories of the container, the home directory of the container's
account [`dsbuser`](#dsbuser-account) or `root` is applied.

#### Mapping file paths in parameters

When executing [`dsb sh`](#dsb-sh) and [`dsb root`](#dsb-root) subcommands,
and when calling [Dsb functions](#functions-available-in-dsb-scripts) in [Dsb scripts](#dsb-scripts), 
the full paths to the host system's files and directories in the specified parameters
can be mapped to container's paths, if such a mapping is enabled and possible.
The "mapping file paths" mode is only used when working with services
specified in the [`DSB_ARGS_MAPPING`](#dsb_args_mapping) variable
of the [`.dsbenv`](#dsbenv-file) file.

> The mapping file paths can be useful when integrating Dsb scripts with IDE settings
containing substitution variables whose values are full file paths.

The mapped file path can be the entire parameter or its substring.
The following characters are considered as path substring limiters:
`space`, `=`, `:`, `,`, `;`, `>`, `<`, `"`, `'`, \`, `(`, `)`.
This is quite enough for real use.

If the file path in the parameter belongs to several nested
[mounted directories](#mounted-directories),
the mapping is performed according to the same rules as for
[current working directory](#mapping-the-working-directory).

You can explicitly disable file path mapping for any parameter
by appending the `dsbnop:` prefix to it.
Full paths that match the system directories `/dev`, `/bin`, `/etc`, `/lib`, `/logs`,
`/proc`, `/run`, `/sbin`, `/snap`, `/sys`, `/tmp`, `/usr`, `/var`
are always passed transparently, without mapping.

When creating [Dsb scripts](#dsb-scripts), you can use the additional option
of pre-converting relative file paths to full paths before path mapping.
This option is explained in detail in the description of the
[`dsb_resolve_files`](#dsb_resolve_files) function.

See also [`DSB_ARGS_MAPPING`](#dsb_args_mapping),
[`dsb_resolve_files`](#dsb_resolve_files).

#### Setting up a profile in a container

Before executing commands inside the subcommand container [`dsb sh`](#dsb-sh),
[`dsb root`](#dsb-root) and [Dsb scripts](#dsb-scripts)
always perform profile configuration in the container in the same way as
as is done when invoking a shell with the `-l` (login shell) option.
At this point, the container file `/etc/profile` is accessed
and the `~/.profile` file of the `dsbuser` or `root` accounts.

The above applies both to an explicit switch to the command line
container - to execute `dsb sh` and `dsb root` without specifying a command, - and to execute
single container commands using `dsb sh`, `dsb root` and Dsb scripts.

The home directory of the `dsbuser` account is stored permanently - separately for each
service. Docker _bind mounts_ or _named volumes_ are used for this purpose
(see [`DSB_HOME_VOLUMES`](#dsb_home_volumes) variable).
The default contents of the directory, including the `~/.profile` file, 
can be customized on a per Dsb project basis via the `.dsb/skel` directory.

See also: [`dsbuser` account](#dsbuser-account).


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

Processing host user's data in containers requires appropriate file access rights.
Dsb solves this problem by creating a special container account `dsbuser`
with the same `UID` and `GID` as the host user's ones.

The `dsbuser` account is created by a small bootstrap script that is executed
every time the container is started. The bootstrap script is
automatically added to yaml files when they are initialized
with the [`dsb yaml`](#dsb-yaml) subcommand.

In the context of the `dsbuser` user, container operations and
[`dsb sh`](#dsb-sh) subcommand and [Dsb scripts](#dsb-scripts) are performed.
The name `dsbuser` can be used in container software settings.

The home directory of the `dsbuser` account is persisted in the host filesystem,
separately for each service, in the corresponding subdirectory `.dsb/home`
or in a separate [named volume](#dsb_home_volumes).

Initial home directory template
(the `lib/skel` subdirectory of this git repository)
contains a `~/bin` subdirectory that is included in the PATH variable
in the configuration file `~/.profile`. The `~/bin` subdirectory can contain
custom scripts and programs that will be available to call using
`dsb sh` subcommands. 
After starting the services, you can manually customize the settings for each service separately, in particular, customize the contents of the `/.profile` and `~/.bashrc` files.

If desired, you can place your own template in the `.dsb/skel` directory.
Mount point of this template
will be automatically substituted by the [`dsb yaml`](#dsb-yaml) subcommand
into yaml files of new services and be used in containers
instead of the built-in template.

### Container indexes

Container indexes are used when working with [scaled services](#dsb-scale)
where the service name alone is not enough to identify a particular container.
In this case, you can specify a numeric container index after the service name,
using the `#` character as a separator:

    $ dsb scale py 3
    docker compose --project-name dsb-dsbexample up -t 15 --detach --remove-orphans --scale py=2 py
    ✔ Container dsb-dsbexample-py-1  Started
    ✔ Container dsb-dsbexample-py-2  Started
    ✔ Container dsb-dsbexample-py-3  Started

    $ dsb ip py#1
    192.168.1.2
    $ dsb ip py#2
    192.168.1.3

> In [Docker Compose CLI](https://docs.docker.com/compose/reference/)
the `--index` option is used for the same purpose.

Container indexes can also be used with [service aliases](#service-aliases):

    $ dsb ip @PYTHON#2
    192.168.1.3

The numbering of a particular service containers starts with `1`.
This index value is also used by default if no container index is specified
and the `dsb` subcommand can only be applied to one container.
Such subcommands include:
[`dsb sh`](#dsb-sh),
[`dsb root`](#dsb-root),
[`dsb cid`](#dsb-cid),
[`dsb ip`](#dsb-ip).

The following `dsb` subcommands can be applied to one specific container
or to all service containers:
[`dsb start`](#dsb-start),
[`dsb restart`](#dsb-restart),
[`dsb stop`](#dsb-stop),
[`dsb down`](#dsb-down),
[`dsb ps`](#dsb-ps),
[`dsb logs`](#dsb-logs).

Note that contiguous numbering order of service containers may be broken
if some of them are removed. The current indexes of the running containers
can be displayed with the [`dsb ps`](#dsb-ps) subcommand:

    $ dsb down py#2
    ...
    $ dsb ps py
    CONTAINER            SERVICE  STATE    STATUS        PORTS
    dsb-dsbexample-py-1  py       running  Up 40 seconds
    dsb-dsbexample-py-3  py       running  Up 42 seconds


### Custom subcommands

Custom subcommands can be used to automate frequently performed actions
specific to particular Dsb projects.

Usage:

    $ dsb SUBCOMMAND_NAME [ ...PARAMETERS ]

Here:
* `SUBCOMMAND_NAME` is the name of the Bash script or executable file
stored in the project's [`.dsb/bin`](#dsb-directory) directory.
* `...PARAMETERS` are parameters that are passed to the script or executable on invocation.

The `dsb` utility checks for a file with the corresponding name
in the [`.dsb/bin`](#dsb-directory) directory if the first parameter of the `dsb` command
doesn't match any of the built-in subcommands.
If such a file exists, one of the following actions is performed:

* If the file has the `execute` permission, it is run as an OS command.

* In the absence of the `execute` permission the Bash source file is implied.
Its execution follows the same rules as the execution of [Dsb scripts](#dsb-scripts).
All [Dsb functions](#functions-available-in-dsb-scripts) can be used.
The only differences are: a) no shebang string is required,
and b) the [`dsb_set_box`](#dsb_set_box) function has already been invoked
when executing the source file.

The Bash source file and OS command have access to [Dsb project variables](#dsb-project-variables).
The current working directory when running the Bash source file or OS command
is the same in which the `dsb` command is called.

Bash source file example:

    dsb_message -n "Subcommand name:           " ; echo "$DSB_SCRIPT_NAME"
    dsb_message -n "Subcommand parameters:     " ; echo "${@}"
    dsb_message -n "Current working directory: " ; echo "$PWD"
    dsb_message -n "Dsb root directory:        " ; echo "$DSB_ROOT"
    dsb_message -n ".dsb directory:            " ; echo "$DSB_BOX"
    dsb_message -n "DSB_PROJECT_ID:            " ; echo "$DSB_PROJECT_ID"
    dsb_message -n "COMPOSE_PROJECT_NAME:      " ; echo "$COMPOSE_PROJECT_NAME"
    dsb_message -n "COMPOSE_FILE:              " ; echo "$COMPOSE_FILE"

> See [`dsb_...message`](#dsb_message) functions.

Dsb scripts
-----------

Dsb scripts allow to invoke container commands on a host system in the same way
as native commands on containers. If you wish, you can even name them as native commands.
Also, you can use Dsb scripts to simplify frequently performed actions in containers.

Each Dsb script is a regular Bash script in which
[Dsb functions](#functions-available-in-dsb-scripts) and
[Dsb project variables](#dsb-project-variables) can be used.
You can place the Dsb script in any directory listed in the `PATH` environment variable.

The simplest Dsb script looks like this:

    #!/usr/bin/env dsb-script
    dsb_run_as_user "@SOMEALIAS" SOMECOMMAND "$@"

This script allows to execute `SOMECOMMAND` with arbitrary parameters
on a container whose service name is specified
by the [`DSB_SERVICE_SOMEALIAS`](#dsb_service_) variable
in the [`.dsbenv` file](#dsbenv-file).
The command is executed under container's account [`dsbuser`](#dsbuser-account),
whose file access rights are the same as the host user's ones.

In the script above:
* `#!/usr/bin/env dsb-script`  
The shebang string for calling the initializing Bash script `dsb-script`,
whose sole role is to load the Bash source file with supported
[Dsb functions](#functions-available-in-dsb-scripts)
and [variables](#dsb-project-variables).
* [`dsb_run_as_user`](#dsb_run_as_user)  
The Dsb function, that executes the specified command in the specified container
with the [`dsbuser`](#dsbuser-account) account rights.
* `@SOMEALIAS`  
The [service alias](#service-aliases), that designates the target container.
Instead of an alias, a particular service name can be given.
When working with [scaled services](#dsb-scale), you can specify a numeric
[container index](#container-indexes) after the service name or alias,
using the `#` character as a separator.
* `SOMECOMMAND`  
The name or full filepath of the container command.
* `"$@"`  
The Bash construct that represents all parameters passed into the script.

If you need to run any command as `root` or another container's account,
you can use the [`dsb_run_as_root`](#dsb_run_as_root)
or [`dsb_run_command`](#dsb_run_command) function
instead of the [`dsb_run_as_user`](#dsb_run_as_user) function.

By default, the Dsb functions are executed in the context of the Dsb project,
whose Dsb root directory contains the current working directory.
If you wish, you can explicitly specify a particular Dsb root directory.
See [`dsb_set_box`](#dsb_set_box) and [`dsb_set_single_box`](#dsb_set_single_box)
for details.

> **When writing Dsb scripts, do not declare your own variables with prefixes `DSB_` and `DSBLIB_`,
as well as your own functions with prefixes`dsb_` and `dsblib_`.
These names are reserved in Dsb for its own use.**

In most cases, this is all you need to know to create your own Dsb scripts.
See the [Reference](#reference) for more information.
See also examples in the [`dsbscripts`](dsbscripts) subdirectory of this git repository.

### Service aliases

Service names can be changed from project to project.
So, it is more convenient to use fixed service aliases in Dsb scripts
and bind them to specific service names in the [`.dsbenv`](#dsbenv-file) file.
The [`DSB_SERVICE_...`](#dsb_service_) variables are used for this purpose.

Each [`DSB_SERVICE_...`](#dsb_service_) variable corresponds to an alias string
derived from the variable name by stripping the `DSB_SERVICE_` prefix
and prepending the `@` character. The variable names  and `@...` aliases must be in upper case.

Example:

    DSB_SERVICE_PYTHON=py

In this example, the `DSB_SERVICE_PYTHON` variable corresponds to the `@PYTHON` alias
and binds it to the `py` service.

You can also define some default service for aliases that are not covered
by the `DSB_SERVICE_...` variables. `DSB_SERVICE` variable is used for this purpose.
In the absence of a `DSB_SERVICE` variable and a suitable `DSB_SERVICE_...` variable, Dsb attempts to use the service name derived from the alias by stripping
the first `@` character and then converting to lowercase.
For example, the default service for `@PYTHON` is `python`.

Service aliases can be used not only in Dsb scripts, but also
in the [`dsb`](#dsb-utility-subcommands) utility subcommands:

    dsb sh @PYTHON python -c 'print("Hello")'


Network access to the host system from containers
--------------------------------------------------

* When using Docker Engine, the host system is accessible from
the containers via domain names `dsbhost` and `dsbhost.localhost`.
These two domain names are added to the `/etc/hosts` files of the containers
when they are started. 
The configuration is performed by the same entrypoint script
that adds a [`dsbuser`](#dsbuser-account) account to the container.
The `awk` utility must be present on the container
(it's available on almost all Docker images).

* When using Docker Desktop,
the host system is accessible via
[`host.docker.internal`](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host).


* When using [Colima](https://github.com/abiosoft/colima),
the host system is accessible via
[`host.lima.internal`](https://github.com/lima-vm/lima/blob/master/docs/network.md#host-ip-19216852).

If a firewall is used on the Linux host system, you may need to configure it
to accept incoming connections from the containers. This is the case
when using Docker Engine.


Removing Dsb projects from the host system
------------------------------------------

To complete your work with a particular Dsb project, go to the Dsb root directory
of the project or any of its subdirectories and run the following commands:

    $ cd <Dsb_root_directory>
    $ dsb compose down -v

This will remove all Dsb project's containers, named volumes, and networks.

If the Docker images used in the Dsb project are no longer needed, they can also be removed:

    $ docker image rm $( dsb compose config --images )

Now you can remove the `.dsb` directory itself.

To remove all containers and networks of all the Dsb projects from a host system,
you can use the following command:

    $ dsb down --host

---


Reference
=========

* [The `dsb` utility subcommands](#dsb-utility-subcommands)
* [Dsb project variables](#dsb-project-variables)
* [Functions available in Dsb scripts](#functions-available-in-dsb-scripts)

`dsb` utility subcommands
-------------------------

The following subcommands are supported:

* [`dsb cid`](#dsb-cid)
* [`dsb compose`](#dsb-compose)
* [`dsb down`](#dsb-down)
* [`dsb init`](#dsb-init)
* [`dsb ip`](#dsb-ip)
* [`dsb logs`](#dsb-logs)
* [`dsb ps`](#dsb-ps)
* [`dsb restart`](#dsb-restart)
* [`dsb rm-vols`](#dsb-rm-vols)
* [`dsb root`](#dsb-root)
* [`dsb scale`](#dsb-scale)
* [`dsb sh`](#dsb-sh)
* [`dsb start`](#dsb-start)
* [`dsb stop`](#dsb-stop)
* [`dsb var`](#dsb-var)
* [`dsb vols`](#dsb-vols)
* [`dsb yaml`](#dsb-yaml)

See also [Custom subcommands.](#custom-subcommands)

Descriptions below use the following notation:
* `SERVICE_NAME` - Docker Compose service name.
* `SERVICE_NAME#INDEX` - Docker Compose service name with a numeric container index.
See [Container indexes.](#container-indexes)
* `IMAGE` - Docker image URL.

---

### `dsb cid`

    $ dsb cid SERVICE_NAME

> You can append [explicit container index](#container-indexes) to the service name (`SERVICE_NAME#INDEX`).

The subcommand prints to STDOUT the identifier of the corresponding Docker container.
This identifier can be further used as a parameter
in [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/) commands.

---

### `dsb compose`

    $ dsb compose ...PARAMETERS

Executing an arbitrary subcommand of the 
[Docker Compose CLI](https://docs.docker.com/compose/reference/)
in the context of the current Dsb project.

When Docker Compose CLI is invoked, the `.dsb/compose` directory is used as the current working directory.
Also, the following options are automatically added:
* `--project-directory` - the full path to the `.dsb/compose` directory.
* `--project-name` - the name of the Docker Compose project derived from the value
of the [`DSB_PROJECT_ID`](#dsb_project_id) variable.

The name of the Docker Compose project is also provided in the
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/environment-variables/envvars/#compose_project_name)
environment variable.

See also [`DSB_STANDALONE_SYNTAX`](#dsb_standalone_syntax) variable.

---

### `dsb down`

    $ dsb down [ ...SERVICE_NAMES ]
    $ dsb down --host

> You can append [explicit container indexes](#container-indexes) to the service names (`SERVICE_NAME#INDEX`).

If the `--host` option is specified, the subcommand removes all Dsb containers
and networks from the host system. Otherwise, the containers of a particular Dsb project
are removed:

* If no parameters are specified, the subcommand removes all project's containers
with the [`docker compose down`](https://docs.docker.com/compose/reference/down/) command.

* If the service name is specified without a container index,
the subcommand remove the service containers by executing the
[`docker compose stop`](https://docs.docker.com/engine/reference/commandline/compose_stop/)
and [`docker compose rm`](https://docs.docker.com/engine/reference/commandline/compose_rm/) commands.

* If [container indexes](#container-indexes) are specified in some parameters,
the subcommand removes those containers by executing the
[`docker container stop`](https://docs.docker.com/engine/reference/commandline/container_stop/)
and [`docker container rm`](https://docs.docker.com/engine/reference/commandline/container_rm/)
commands.

A project-specific shutdown timeout (in seconds) can be defined
by using the [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout) variable
in the [`.dsbenv`](#dsbenv-file) file.

Note that the `dsb down` subcommand does not remove Compose volumes.
You can use the [`dsb rm-vols`](#dsb-rm-vols)
or [`dsb compose down -v`](https://docs.docker.com/compose/reference/down/)
command for this purpose (the latter removes all project containers and volumes).

See also [`dsb stop`](#dsb-stop).

---

### `dsb help`

    $ dsb help

The subcommand just prints a brief summary of the supported `dsb` subcommands.
The same output can be displayed by running the `dsb` command without parameters.

---

### `dsb init`

    $ dsb init

The subcommand creates a `.dsb` subdirectory in the current working directory
and copies the Dsb project configuration template into it
(see `lib/init` in this git repository).

The [`DSB_PROJECT_ID`](#dsb_project_id) variable
in the [`.dsb/compose/.dsbenv`](#dsbenv-file) file is assigned an initial random value.
It is advisable to immediately change it to a more descriptive one.
See [`DSB_PROJECT_ID`](#dsb_project_id) for details.

---

### `dsb ip`

    $ dsb ip SERVICE_NAME

> You can append [explicit container index](#container-indexes) to the service name (`SERVICE_NAME#INDEX`).

The subcommand outputs the IP address of the corresponding Docker container to STDOUT.

---

### `dsb logs`

    $ dsb logs [ SERVICE_NAME ]

> You can append [explicit container index](#container-indexes) to the service name (`SERVICE_NAME#INDEX`).

The subcommand outputs log records for all services in the Dsb project
or for the specified service/container.

---

### `dsb ps`

    $ dsb ps [ SERVICE_NAME ]

> You can append [explicit container index](#container-indexes) to the service name (`SERVICE_NAME#INDEX`).

The subcommand outputs the current status of all containers in the Dsb project
or only the containers of the specified service.

---

### `dsb restart`

    $ dsb restart [ ...SERVICE_NAMES ]

> You can append [explicit container indexes](#container-indexes) to the service names (`SERVICE_NAME#INDEX`).

The subcommand restarts all Dsb project services or specified
services/containers:

* Services are restarted with the
[`docker compose restart`](https://docs.docker.com/engine/reference/commandline/compose_restart/) command.

* If [container indexes](#container-indexes) are specified in some parameters,
particular containers are restarted with the
[`docker container restart`](https://docs.docker.com/engine/reference/commandline/container_restart/) command.

A project-specific stop timeout (in seconds) can be defined
by using the [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout) variable
in the [`.dsbenv`](#dsbenv-file) file.

Note that the changes made to yaml files are not activated by this subcommand.
To activate the changes, use the [`dsb start`](#dsb-start) subcommand without parameters.

See also [`dsb stop`](#dsb-stop), [`dsb start`](#dsb-start).

---

### `dsb rm-vols`

    $ dsb rm-vols [ --host | ...COMPOSE_VOLUMES ]

If the `--host` option is specified, the subcommand removes all Compose volumes
for all Dsb projects on the host system.

If no parameters are specified, the subcommand removes all Compose volumes
of the current Dsb project.
Otherwise, the specified Compose volumes of the current Dsb project are removed.

If there are containers to which the volumes to be removed are bound, those containers are also removed.

Example:

    # Remove all volumes with dsbuser home directories
    $ dsb rm-vols $( dsb vols --quiet | grep dsbuser )

See also [`dsb vols`](#dsb-vols).

---

### `dsb root`

    $ dsb root SERVICE_NAME
    $ dsb root SERVICE_NAME COMMAND [ ...PARAMETERS ]
    $ dsb root SERVICE_NAME SHELL_COMMAND_LINE

> You can append [explicit container index](#container-indexes) to the service name (`SERVICE_NAME#INDEX`).

The subcommand behaves similar to [`dsb sh`](#dsb-sh), but executes container commands
under the `root` account.

Example:

    $ dsb root py cat /etc/shadow

See also [Executing commands in containers](#executing-commands-in-containers), [`dsb sh`](#dsb-sh).

---

### `dsb scale`

    $ dsb scale SERVICE_NAME REPLICAS

The subcommand scales the service by increasing or decreasing
the number of service containers up to the number specified by the `REPLICAS` parameter:

    $ dsb scale py 3
    docker compose --project-name dsb-dsbexample up -t 15 --detach --remove-orphans --scale py=3 py
    ✔ Container dsb-dsbexample-py-3  Started
    ✔ Container dsb-dsbexample-py-1  Started
    ✔ Container dsb-dsbexample-py-2  Started

Scaling is performed by the
[`docker compose up`](https://docs.docker.com/engine/reference/commandline/compose_up/)
command with the `--scale` option.
Keep in mind that all containers of the scaled service use the same instances
of the [named volumes](https://docs.docker.com/storage/volumes/#use-a-volume-with-docker-compose)
and [mounted directories](#mounted-directories).

When working with a scaled service, you can refer to different service containers
by appending the service name with the `#` character followed by the numeric container index:

    $ dsb sh py#1 cat /etc/hostname
    7e0f4f0a10b5
    $ dsb sh py#2 cat /etc/hostname
    1eabf5c7dedf
    $ dsb sh py#3 cat /etc/hostname
    7c4d4d85a33d

See also [Container indexes](#container-indexes).

---

### `dsb sh`

    $ dsb sh SERVICE_NAME
    $ dsb sh SERVICE_NAME COMMAND [ ...PARAMETERS ]
    $ dsb sh SERVICE_NAME SHELL_COMMAND_LINE

> You can append [explicit container index](#container-indexes) to the service name (`SERVICE_NAME#INDEX`).

The subcommand executes container commands with access rights
of the [`dsbuser`](#dsbuser-account) account.
This account is created in containers on startup
and has the same `UID` and `GID` values as the host user's ones.

Using the subcommand with the only `SERVICE_NAME` parameter
simply runs the shell of the corresponding container.
The shell program used is `bash` or `sh` depending on the availability of the program
in the container (`bash` has a higher priority).
If the host's current working directory is within the boundaries of some 
[mounted directory](#mounted-directories) of the service, it is also set
as [the current directory in the container](#mapping-the-working-directory).

Example:

    $ dsb sh py
    py:/dsbspace$   # container dsbuser's command line
    py:/dsbspace$ python src/hello.py
    Hello from Python!
    ...
    py:/dsbspace/src$ exit # Leaving the container (or Ctrl+D)
    $   # host user's command line

If there are additional parameters after the `SERVICE_NAME`, they specify
a single command or shell's command line to be executed in the container
without explicitly switching the shell interface:

* In case of several additional parameters, the first one is taken as the container's
executable name (or path) and the rest are taken as arguments for this executable.
If the parameters contain wildcard characters `*` and `?`, they are replaced
on the host's shell level before passing the command to the container.

* In case of a single additional parameter, it is interpreted just as a container's shell command line.
This command line is executed in `bash` or `sh` via the `-c` option.
It may contain one or more commands separated by the `;` character.
If it contains wildcards, they are replaced on the container's shell level.

[Mapping the host's current working directory](#mapping-the-working-directory)
is performed in the same way as when explicitly switching to the container's shell.
The full host system's file paths in the parameters
[can also be mapped to container's paths](#mapping-file-paths-in-parameters),
if such a mapping is possible. 

Single command example:

    $ # Go to the directory with the 'src' subdirectory
    $ cd ~/dsbexample
    $ dsb sh py python src/hello.py
    Hello from Python!
    $ cd src
    $ dsb sh py python3 hello.py
    Hello from Python!

Shell's command line example:

    $ cd ~/dsbexample
    $ dsb sh py "python src/hello.py ; cd src ; python3 hello.py"
    Hello from Python!
    Hello from Python!

For more details, see
[Executing commands in containers](#executing-commands-in-containers).

---

### `dsb start`

    $ dsb start [ ...SERVICE_NAMES ]

> You can append [explicit container indexes](#container-indexes) to the service names (`SERVICE_NAME#INDEX`).

The subcommand starts all Dsb project services or specified
services/containers:

* If no parameters are specified, the subcommand starts all project services with the
[`docker compose up --detach --remove-orphans`](https://docs.docker.com/engine/reference/commandline/compose_up/) command.
Such a subcommand can be used to quickly activate changes made to [yaml files](#yaml-files).

* If the name of an inactive service is specified (there are no service containers), the service is started with the
[`docker compose up --no-deps --detach SERVICE_NAME`](https://docs.docker.com/engine/reference/commandline/compose_up/)
command.

* If the name of an active service is specified (there are service containers with any status),
the service is started with the 
[`docker compose start SERVICE_NAME`](https://docs.docker.com/engine/reference/commandline/compose_start/) command.

* If [container indexes](#container-indexes) are specified in some parameters,
particular containers are started with the
[`docker container start`](https://docs.docker.com/engine/reference/commandline/container_start/)
 command.

See also [`dsb stop`](#dsb-stop), [`dsb down`](#dsb-down).

---

### `dsb stop`

    $ dsb stop [ ...SERVICE_NAMES ]

> You can append [explicit container indexes](#container-indexes) to the service names (`SERVICE_NAME#INDEX`).

The subcommand stops all Dsb project services or specified
services/containers without removing them:

* Services are stopped with the
[`docker compose stop`](https://docs.docker.com/engine/reference/commandline/compose_stop/) command.

* If [container indexes](#container-indexes) are specified in some parameters,
particular containers are stopped with the
[`docker container stop`](https://docs.docker.com/engine/reference/commandline/container_stop/) command.

A project-specific stop timeout (in seconds) can be defined
by using the [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout) variable
in the [`.dsbenv`](#dsbenv-file) file.

Stopped containers remain in the host system with `exited` status and can be restarted
with the [`dsb start`](#dsb-start) or [`dsb restart`](#dsb-restart) subcommand.

See also [`dsb down`](#dsb-down), [`dsb start`](#dsb-start).

---

### `dsb var`

    $ dsb var [ VARIABLE_NAME ]

When called without parameters, the subcommand outputs а list of all available
[Dsb project variables](#dsb-project-variables) (with prefixes `DSB_`, `DSBUSR_`, `COMPOSE_`, and `DOCKER_`)
and their values to STDOUT .

When called with a parameter, the subcommand outputs the value
of the specified variable to STDOUT.

---

### `dsb vols`

    $ dsb vols [ --quiet ]

The subcommand outputs the names of
[Compose volumes](https://docs.docker.com/compose/compose-file/05-services/#volumes)
of the Dsb project and the corresponding [Docker volumes](https://docs.docker.com/storage/volumes/)
to STDOUT.

If the `--quiet` option is specified, only Compose volume names are output to STDOUT.

---

### `dsb yaml`

    $ dsb yaml SERVICE [ IMAGE ] [ --sleep | --cmd  ] [ --initd ] [ --build ]

The subcommand generates an initial yaml template for a new service named `SERVICE`
based on the Docker image `IMAGE`. The `IMAGE` parameter can only be omitted if the `--build` option is present.

The template is placed in the `.dsb/compose/SERVICE.yaml` file.
It contains all the elements necessary to run the  subcommands [`dsb sh`](#dsb-sh), [`dsb root`](#dsb-root),
and [Dsb scripts](#dsb-scripts) in a service context. You can then customize the file by adding other necessary elements to it.
To make things easier, the template provides commented examples of some elements that can be used.

To start a new service, add the appropriate filename to the [`COMPOSE_FILE`](#compose_file) variable
in the [`.dsbenv`](#dsbenv-file) file and run the [`dsb start`](#dsb-start) subcommand.
The [`dsb start`](#dsb-start) subcommand can also be used to quickly activate recent changes to yaml files.

Example:

     $ dsb yaml py python:alpine


Resulting `.dsb/compose/py.yaml`:

```
services:
  py:
    image: 'python:alpine'
    user:  root
    networks:
      dsbnet:
    environment:
      DSB_SERVICE: py
    volumes:
      - $DSB_SPACE:/dsbspace
      - $DSB_UTILS:/dsbutils:ro
      - $DSB_SKEL:/dsbskel:ro
      - $DSB_BOX/home/py:/dsbhome
    #
    # ... commented-out helper elements ...
    #
    entrypoint:
      - sh
      - '-c'
      - |
        sh /dsbutils/adduser.sh "$DSB_UID_GID"
        exec sh /dsbutils/sleep.sh
```

Here:

* `$DSB_SPACE:/dsbspace`  
The [mounted directory of ​​Dsb project](#mounted-directories) (`$DSB_SPACE`),
which is mounted at the `/dsbspace` directory in a container;
* `$DSB_UTILS:/dsbutils:ro`  
Dsb helper scripts directory (`$DSB_UTILS`) mounted at the `/dsbutils`  directory in a container;
* `$DSB_SKEL:/dsbskel:ro` - include home directory template;
* `$DSB_BOX/home/SERVICE:/dsbhome` - connection of the host directory containing the user's home directory
[`dsbuser`](#dsbuser-account).
* [`entrypoint: ...`](https://docs.docker.com/compose/compose-file/05-services/#entrypoint) - small
bootstrap script containing user creation commands
[`dsbuser`](#dsbuser-account)
and then transferring control to the container's main process.

As [mounted directory](#mounted-directories) in template
the value of the variable [`DSB_SPACE`](#dsb_space) is used,
and the container directory `/dsbspace` as the mount point.
Both can be changed if desired. Variable value
[`DSB_SPACE`](#dsb_space) is the full path to the
[Dsb root directory](#terms) by default. Explicitly set a different value
possible in the file [`.dsbenv`](#dsbenv-file).

You can mount any number of arbitrary directories.
Mount points in containers can also be arbitrary.
The only fixed mount points are Dsb helper directories: `/dsbutils`, `/dsbhome`, `/dsbskel`.

> If there is a `.dsb/skel` directory containing a custom homepage template
user directory [`dsbuser`](#dsbuser-account), mount point
`$DSB_SKEL:/dsbskel:ro` is replaced by `$DSB_BOX/skel:/dsbskel:ro`.

The contents of the `entrypoint` script is formed depending on the options
of the `dsb yaml` subcommand. The first script command is always the command
to create a `dsbuser` account:

      - |
        sh /dsbutils/adduser.sh "$DSB_UID_GID"
        ...

The above example used the `--sleep` option by default,
so the main container process after creating `dsbuser`
put to sleep: `exec sh /dsbutils/sleep.sh`.
This option is designed to use a Docker image
just to execute [Dsb scripts](#dsb-scripts) and subcommands
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

Dsb project variables
---------------------

* [Dsb base variables](#dsb-base-variables)
* [Variables defined in `.dsbenv` file](#variables-defined-in-dsbenv-file)
* [Variables used in Dsb scripts](#variables-used-in-dsb-scripts)
* [Variables used in yaml files](#variables-used-in-yaml-files)

Note that host system's environment variables with prefixes `DSB_`, `DSBUSR_`, `COMPOSE_`, and `DOCKER_`
are reset at the beginning of execution of the [`dsb`](#dsb-utility) utility
and [Dsb scripts](#dsb-scripts) for security reasons.
You can only set variables with these prefixes in the [`.dsbenv`](#dsbenv-file) file.

### Dsb base variables

Dsb base variables are initialized immediately after finding the Dsb root directory
before executing the [`.dsbenv`](#dsbenv-file) file.

> When [Dsb scripts](#dsb-scripts) are executed, base variables are initialized
the first time the [`dsb_set_box`](#dsb_set_box) function is called,
either explicitly or implicitly.

The following variables are supported:

* `DSB_ROOT` - the full path to the Dsb root directory.
* `DSB_BOX`  - the full path to the [`.dsb`](#dsb-directory) directory.
* [`DSB_SPACE`](#dsb_space) - the default value is the same as the `DSB_ROOT` value.
* `DSB_UTILS` - the full path to the Dsb `lib/utils` subdirectory.
* `DSB_SKEL` - the full path to the [`dsbuser`](#dsbuser-account) home directory template.
* `DSB_UID` - the host user's `UID` value.
* `DSB_GID` - the host user's `GID` value.
* `DSB_UID_GID` - the host user's `UID:GID` string.

These variables are mainly intended for use in [yaml files](#yaml-files),
but can be explicitly used in [`.dsbenv`](#dsbenv-file) files and [Dsb scripts](#dsb-scripts).
All the variables except the [`DSB_SPACE`](#dsb_space) are readonly.

The `DSB_UID`, `DSB_GID`, and `DSB_UID_GID` variables are used in [yaml files](#yaml-files)
to pass host user's `UID` and `GID` to containers.

The other base variables allow to create [yaml files](#yaml-files)
without explicit references to specific directories on the host system:

* The `DSB_ROOT` variable contains the full path to the [Dsb root directory](#dsb-project-structure).
It allows to reference arbitrary subdirectories and files within the Dsb root directory,
mainly to reference [mounted directories](#mounted-directories).

* The `DSB_BOX` variable contains the full path to the [`.dsb`](#dsb-directory) directory
of the Dsb project. It allows to reference service configuration files
in the `.dsb/config` subdirectory, reference the `.dsb/home` and `.dsb/logs` subdirectories, etc.

* The [`DSB_SPACE`](#dsb_space) variable is used in yaml templates generated
by the [`dsb yaml`](#dsb-yaml) subcommand. It specifies the shared [mounted directory](#mounted-directories)
for the Dsb project services, bound to the `/dsbspace` mount point.
The variable is provided just for convenience as generic way to specify
a shared [mounted directory](#mounted-directories). It's not used anywhere else.
The corresponding line of the [yaml file](#yaml-files) is optional and can be removed.  
The default variable value is the same as the `DSB_ROOT` value.
For security reasons, it is not recommended to bind-mount the Dsb root directory itself in containers.
So, it is reasonable to change the default value to some subdirectory path. 
This can be done in the [`.dsbenv`](#dsbenv-file) file.

* The `DSB_UTILS` variable contains the full path to the directory
containing Dsb helper scripts (see `lib/utils` in this git repository).
These scripts are used for container initialization
in the [`entrypoint`](https://docs.docker.com/compose/compose-file/05-services/#entrypoint)
items of the [yaml templates](#dsb-yaml).

* The `DSB_SKEL` variable contains the full path to the home directory "skeleton"
for [`dsbuser`](#dsbuser-account) accounts, created in containers when they are started
(see `lib/skel` in this git repository).
By default, the [`dsb yaml`](#dsb-yaml) subcommand uses this variable as the host system's directory path,
bind-mounted to the `/dsbskel` in containers.  
If you need to use a custom version of the home "skeleton" for your Dsb project,
place it in the `.dsb/skel` subdirectory. In this case, when creating [yaml files](#yaml-files),
the [`dsb yaml`](#dsb-yaml) subcommand will bind-mount this subdirectory to the container's `/dsbskel`
(`$DSB_BOX/skel:/dsbskel:ro`).

See also [yaml files](#yaml-files), [`dsb yaml`](#dsb-yaml), [`dsbuser` account](#dsbuser-account).


### Variables defined in `.dsbenv` file

The following сonfiguration variables are supported:

* [`COMPOSE_FILE`](#compose_file)
* [`COMPOSE_...`, `DOCKER_...`](#compose_-docker_)
* [`DSB_ARGS_MAPPING`](#dsb_args_mapping)
* [`DSB_HOME_VOLUMES`](#dsb_home_volumes)
* [`DSB_PROD_MODE`](#dsb_prod_mode)
* [`DSB_PROJECT_ID`](#dsb_project_id)
* [`DSB_SERVICE_...`](#dsb_service_)
* [`DSB_SHUTDOWN_TIMEOUT`](#dsb_shutdown_timeout)
* [`DSB_SPACE`](#dsb_space)
* [`DSB_STANDALONE_SYNTAX`](#dsb_standalone_syntax)
* [`DSB_UMASK_ROOT`](#dsb_umask_root)
* [`DSB_UMASK_SH`](#dsb_umask_sh)
* [`DSBUSR_...`](#dsbusr_)

The [`DSB_PROJECT_ID`](#dsb_project_id) and [`COMPOSE_FILE`](#compose_file) variables are mandatory.
The [`DSB_PROJECT_ID`](#dsb_project_id) is used as part of the Docker Compose project name,
that is passed to Compose CLI utility with the
[`--project-name`](https://docs.docker.com/compose/reference/#use--p-to-specify-a-project-name) option.

All variables with the prefixes `DSB_`, `DSBUSR_`, `COMPOSE_`, `DOCKER_`
are automatically exported and are available in [yaml files](#yaml-files)
and in external commands invoked by the [`dsb`](#dsb-utility) utility and [Dsb scripts](#dsb-scripts).
Note that you can only set these variables in the `.dsbenv` file.
Host system’s environment variables with these prefixes are reset at the beginning of execution
of the [`dsb`](#dsb-utility) utility and [Dsb scripts](#dsb-scripts) for security reasons.

Using other variables is also allowed in the `.dsbenv` file, but these variables are not automatically exported.
So you must either export them explicitly or use them only in the context of [Dsb scripts](#dsb-scripts).
For project-specific purposes it is preferable to use arbitrary variables with the [`DSBUSR_`](#dsbusr_) prefix.

> **Do not use variables with the prefix `DSBLIB_`. These variables are reserved in Dsb for internal use.**

---

#### `COMPOSE_FILE`

This Docker Compose variable must always be present in the [`.dsbenv` file](#dsbenv-file).
It contains the list of enabled [yaml files](#yaml-files) of the Dsb project.

Filenames in the list are separated by colons:

     COMPOSE_FILE="globals.yaml:py.yaml"

The [`global.yaml` file](#globalsyaml-file) must always be present.
It is created by the [`dsb init`](#dsb-init) subcommand and contains
[Compose network settings](https://docs.docker.com/compose/compose-file/06-networks/)
of the Dsb project.

See also
[Yaml files](#yaml-files),
[Compose environment variables: COMPOSE_FILE](https://docs.docker.com/compose/environment-variables/envvars/#compose_file)

---

#### `COMPOSE_...`, `DOCKER_...`

You can place Docker Compose and Docker environment variables
in the [`.dsbenv`](#dsbenv-file) file.

Note that the
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/reference/envvars/#compose_project_name)
variable is set automatically by the Dsb based on the value
of the [`DSB_PROJECT_ID`](#dsb_project_id) variable.
You should never explicitly assign a value to the `COMPOSE_PROJECT_NAME` variable in Dsb.

See also [`COMPOSE_FILE`](#compose_file),
[Compose environment variables](https://docs.docker.com/compose/environment-variables/envvars/),
[Docker environment variables](https://docs.docker.com/engine/reference/commandline/cli/#environment-variables).

---

#### `DSB_ARGS_MAPPING`

The variable specifies the Dsb project's services for which
the [`Mapping file paths in parameters`](#mapping-file-paths-in-parameters)
option is enabled.

Service names in the variable value are separated by colons:

    DSB_ARGS_MAPPING="py:php:mysql"

The asterisk is used to enable the option for all Dsb project's services:

    DSB_ARGS_MAPPING="*"

The option affects the behavior of the following subcommands and functions:
[`dsb root`](#dsb-root),
[`dsb sh`](#dsb-sh),
[`dsb_run_as_root`](#dsb_run_as_root),
[`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_command`](#dsb_run_command),
[`dsb_resolve_files`](#dsb_resolve_files)

---

#### `DSB_HOME_VOLUMES`

The [`dsb yaml`](#dsb-init) subcommand supports two options to persist home directories of the [`dsbuser`](#dsbuser-account) accounts:
[_bind mounts_](https://docs.docker.com/storage/bind-mounts/)
and [_named volumes_](https://docs.docker.com/storage/volumes/#use-a-volume-with-docker-compose).

The `true` value of the `DSB_HOME_VOLUMES` variable forces
the [`dsb yaml`](#dsb-init) subcommand to use _named volumes_:


    DSB_HOME_VOLUMES=true

Example:

    services:
      py:
        ...
        volumes:
          - dsbuser-py:/dsbhome
        ...
    volumes:
      dsbuser-py:

If the `DSB_HOME_VOLUMES` is set to `false`, the [`dsb yaml`](#dsb-init) subcommand
uses _bind mounts_:

    DSB_HOME_VOLUMES=false

In this mode, the home directories are persisted as `.dsb/home` subdirectories
with names matching the names of the corresponding services:

    services:
      py:
        ...
        volumes:
          - $DSB_BOX/home/py:/dsbhome

Default variable value: `false`

Note that [`dsb init`](#dsb-init) subcommand automatically adds `DSB_HOME_VOLUMES=true`
to the [`.dsbenv` file](#dsbenv-file) on macOS.

---

#### `DSB_PROD_MODE`

The `true` value of this variable enables `production mode` of the
[`dsb`](#dsb-utility-subcommands) utility:

     DSB_PROD_MODE=true

In production mode the [`dsb start`](#dsb-start) and [`dsb restart`](#dsb-restart) subcommands
do not change the access permissions of files and subdirectories
in the [`.dsb` directory](#dsb-directory).

Default variable value: `false`

---

#### `DSB_PROJECT_ID`

The variable specifies a unique ID of the Dsb project on the host system.
This ID is used as part of the Docker Compose project name, that is automatically assigned to
[`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/environment-variables/envvars/#compose_project_name)
variable and passed to [Compose CLI utility](https://docs.docker.com/compose/reference/)
as the `--project-name` option.

The variable value must only contain Latin letters A-Z, a-z, symbols "_", "-" and digits 0-9:

    DSB_PROJECT_ID=SamplePythonProject_1

When generating a Compose project name, the value of the variable is converted
to lower case and the prefix `dsb-` is added to it. 
Thus, different Dsb projects must have different lowercase values
of the `DSB_PROJECT_ID` variables on the same host system. 

When you run the [`dsb init`](#dsb-init) subcommand,
the `DSB_PROJECT_ID` variable is set to an initial random value.
It is advisable to immediately change it to a more descriptive one.
If you later decide to change the value of the variable, you must first remove
all the project's containers and named volumes:

    $ dsb compose down -v

See also [FAQ: How do I run multiple copies of a Compose file on the same host?](https://docs.docker.com/compose/faq/#how-do-i-run-multiple-copies-of-a-compose-file-on-the-same-host)

---

#### `DSB_SERVICE_...`

Variables prefixed with `DSB_SERVICE_` define the mapping of fixed
[service aliases](#service-aliases) to specific service names.
This mapping is used when executing [Dsb scripts](#dsb-scripts)
containing the corresponding service aliases.

The names of the `DSB_SERVICE_...` variables must be in upper case.
Each such variable corresponds to an alias string obtained from
the variable name by dropping the `DSB_SERVICE_` prefix and then
adding the `@` character to the beginning. 

Example:

    DSB_SERVICE_PYTHON=py

Here the `@PYTHON` alias is mapped to the `py` service.

The `DSB_SERVICE` variable, if defined, associates the specified service with all aliases
not covered by the `DSB_SERVICE_...` variables.

See also [Service aliases](#service-aliases).

---

#### `DSB_SHUTDOWN_TIMEOUT`

The variable specifies the timeout in seconds for stopping or shutting down containers:

    DSB_SHUTDOWN_TIMEOUT=15

The value of the variable is used as the `-t` option
when invoking the Docker and Compose CLI utilities.

Default variable value: `15`

---

#### `DSB_SPACE`

The variable is used in [yaml files](#yaml-files) generated by the [`dsb yaml`](#dsb-yaml)
subcommand and specifies the shared [mounted directory](#mounted-directories)
for the Dsb project services:

```
volumes:
  - $DSB_SPACE:/dsbspace
```

Using the `DSB_SPACE` variable and the `/dsbspace` mount point is optional.
It simply provides a generic way to specify a shared [mounted directory](#mounted-directories)
in Dsb. You can remove or change this `volumes` item.

The default value of `DSB_SPACE` variable is the same as the value of 
[`DSB_ROOT`](#dsb-base-variables) variable,
which specifies the full path to the Dsb root directory.
This default value can be explicitly changed in the [`.dsbenv`](#dsbenv-file) file
to a more appropriate value:

    DSB_SPACE="$DSB_ROOT/src"

> For security reasons, it is not recommended to bind-mount the Dsb root directory itself in containers.

See also [Mounted directories](#mounted-directories), [Dsb project structure](#dsb-project-structure).

---

#### `DSB_STANDALONE_SYNTAX`

The `true` value of the variable enables standalone syntax
[`docker-compose ...`](https://docs.docker.com/compose/install/standalone/)
to invoke Docker Compose CLI.

The `false` value of the variable enables default plugin syntax
[`docker compose ...`](https://docs.docker.com/compose/migrate/#what-are-the-differences-between-compose-v1-and-compose-v2).

> The standalone syntax is somewhat faster to invoke Docker Compose CLI.

If the `docker-compose` executable is not available on the host system,
the `dsb` utility always tries to fallback to plugin syntax.

Note that the [`dsb init`](#dsb-init) subcommand automatically adds:

    DSB_STANDALONE_SYNTAX=true

to the [`.dsbenv`](#dsbenv-file) file if the `docker-compose` executable is available on the host system.

Default variable value: `false`

---

#### `DSB_UMASK_ROOT`

The variable specifies a fixed value for the `file creation mode mask (umask)`
when executing the [`dsb root`](#dsb-root) subcommand.

Example:

    DSB_UMASK_ROOT="0022"

By default, the current host system's `umask` value is used.

At the service-specific level, the `umask` value can be explicitly defined
using the `DSB_UMASK_ROOT` environment variable in the corresponding
[yaml file](#yaml-files):

```
environment:
  DSB_UMASK_ROOT="0027"
  ...
```

(the `umask` value must be quoted in this case)

---

#### `DSB_UMASK_SH`

The variable specifies a fixed value for the `file creation mode mask (umask)`
when executing the [`dsb sh`](#dsb-sh) subcommand.

Example:

    DSB_UMASK_SH="0022"

By default, the current host system's `umask` value is used.

At the service-specific level, the `umask` value can be explicitly defined
using the `DSB_UMASK_SH` environment variable in the corresponding
[yaml file](#yaml-files):

```
environment:
  DSB_UMASK_SH="0027"
  ...
```

(the `umask` value must be quoted in this case)

---

#### `DSBUSR_...`

Variables with the `DSBUSR_` prefix can be used in an arbitrary way.
When these variables are defined in the [`.dsbenv`](#dsbenv-file) file, 
they are automatically exported and are available in [yaml files](#yaml-files),
[Dsb scripts](#dsb-scripts),
and in OS commands executed by the `dsb` utility and [Dsb scripts](#dsb-scripts).

Note that you can only set `DSBUSR_...` variables in the [`.dsbenv`](#dsbenv-file) file.
Host system’s environment variables with the `DSBUSR_` prefix are reset
at the beginning of execution of the `dsb` utility and [Dsb scripts](#dsb-scripts).

---

### Variables used in Dsb scripts

The following variables are available at the initial moment of Dsb script execution:

* `DSB_SCRIPT_NAME` - the Dsb script name.
* `DSB_SCRIPT_PATH` - the full Dsb script path.
* `DSB_WORKDIR` - the full path to the current working directory
from which the script is launched.

[Dsb base variables](#dsb-base-variables) and 
[variables defined in the `.dsbenv` file ](#variables-defined-in-dsbenv-file)
are made available to the Dsb script after explicitly or implicitly calling the 
[`dsb_set_box`](#dsb_set_box) function.

> The following functions always invoke `dsb_set_box` internally at the beginning of their execution:
[`dsb_docker_compose`](#dsb_docker_compose),
[`dsb_get_container_id`](#dsb_get_container_id),
[`dsb_run_as_root`](#dsb_run_as_root),
[`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_command`](#dsb_run_command).
The [`dsb_set_single_box`](#dsb_set_single_box) function invokes `dsb_set_box` 
if only one Dsb project's containers are currently running on the host system.

Some [Dsb functions](#functions-available-in-dsb-scripts) return output data
in the variables prefixed with `DSB_OUT_...`.
The values of this variables may be destroyed by subsequent calls to Dsb functions.
So, you should store the values in some local variables for further use.

> **Do not declare or use the variables with the prefix `DSBLIB_`.
These variables are reserved in Dsb for internal use.**

#### Variables used in yaml files

In [yaml files](#yaml-files) you can use all [Dsb base variables](#dsb-base-variables)
as well as arbitrary custom variables with the [`DSBUSR_`](#dsbusr_) prefix
defined in the [`.dsbenv`](#dsbenv-file) file.
You can also use other custom variables defined in the [`.dsbenv`](#dsbenv-file) file,
but these variables are not automatically exported. So you must export them explicitly
in the `.dsbenv` file.

Using variables from the [Compose `.env` file](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file)
is also possible, but this file  (`.dsb/compose/.env`) is redundant in Dsb.

See also [Dsb base variables](#dsb-base-variables),
[`DSB_SPACE`](#dsb_space), [`DSBUSR_...` variables](#dsbusr_), [`dsb yaml`](#dsb-yaml).


Functions available in Dsb scripts
-----------------------------------

The following Dsb functions are available:

* [`dsb_docker_compose`](#dsb_docker_compose)
* [`dsb_exec`](#dsb_exec)
* [`dsb_get_container_id`](#dsb_get_container_id)
* [`dsb_map_env`](#dsb_map_env)
* [`dsb_resolve_files`](#dsb_resolve_files)
* [`dsb_run_as_root`](#dsb_run_as_root)
* [`dsb_run_as_user`](#dsb_run_as_user)
* [`dsb_run_command`](#dsb_run_command)
* [`dsb_run_dsb`](#dsb_run_dsb)
* [`dsb_set_box`](#dsb_set_box)
* [`dsb_set_single_box`](#dsb_set_single_box)
* [`dsb_message`, `dsb_green_message`, `dsb_yellow_message`, `dsb_red_message`](#dsb_message)

To create simple Dsb scripts, just use one of the
[`dsb_run_as_user`](#dsb_run_as_user) or
[`dsb_run_as_root`](#dsb_run_as_root) functions.

Example:

    #!/usr/bin/env dsb-script
    dsb_run_as_user "@PYTHON" python "$@"

See also
[Dsb scripts](#dsb-scripts),
[Service aliases](#service-aliases),
[Custom subcommands](#custom-subcommands).

---

### `dsb_docker_compose`

    dsb_docker_compose ...<COMPOSE_PARAMETERS>

The function runs the Docker Compose CLI command in the context of the current Dsb project.

When running the Compose CLI command, the current working directory is `.dsb/compose`.
The following options are added to the command automatically:

* `--project-name` - Compose project name, which is formed based on the value
of the [`DSB_PROJECT_ID`](#dsb_project_id) variable.
* `--project-directory` - the full path to the `.dsb/compose` directory.

The Compose CLI command has access to all the [Dsb project variables](#dsb-project-variables),
in particular the [`COMPOSE_PROJECT_NAME`](https://docs.docker.com/compose/environment-variables/envvars/#compose_project_name)
variable containing the name of the corresponding Compose project.

Note that host system's environment variables with  prefixes `COMPOSE_` and `DOCKER_`
are reset at the beginning of the Dsb script execution.
You should define them explicitly in the [`.dsbenv` file](#dsbenv-file).

Example:

    #!/usr/bin/env dsb-script
    MYSERVICES="$( dsb_docker_compose config --services )"
    for NAME in $MYSERVICES ; do
        echo "$NAME"
    done

---

### `dsb_exec`

    dsb_exec COMMAND [ ...COMMAND_ARGS ]

The helper function that executes a given OS command or Bash function
and checks its exit/return code. If the code is non-zero, the corresponding diagnostic message
is output to STDERR and the script is terminated.

---

### `dsb_get_container_id`

    dsb_get_container_id ( SERVICE_NAME | @SERVICE_ALIAS ) [ --anystatus ]

> You can append [explicit container index](#container-indexes)
to the `SERVICE_NAME` or [`@SERVICE_ALIAS`](#service-aliases).

The function allows to get the ID of a specific container,
which can then be used to execute
[`docker container ...`](https://docs.docker.com/engine/reference/commandline/container/)
subcommands.

The first parameter of the function specifies the target container.
The value of the parameter can be defined as a service name
or as a [service alias](#service-aliases) prefixed with the `@` character.
If a service alias is used, the particular service name is determined based on the values
of the [`DSB_SERVICE_...`](#dsb_service_) variables in the [`.dsbenv`](#dsbenv-file) file.

The following output variables are set on successful execution of the function:

* `DSB_OUT_CONTAINER_ID` - the Docker ID of the corresponding container
* `DSB_OUT_CONTAINER_STATUS` - the status of the corresponding container
* `DSB_OUT_CONTAINER_SERVICE` - the name of the service to which the container belongs
* `DSB_OUT_CONTAINER_INDEX` - [container index](#container-indexes)

Note that the values of the above variables may be changed as a result of subsequent calls
to the `dsb_run_as_root`, `dsb_run_as_user`, and `dsb_run_command` functions.

If the function is called without the `--anystatus` option, the function only succeeds
if there is a corresponding container with a `running` status.

If the `--anystatus` option is used, the function succeeds
(returns exit code `0`) if there is a corresponding container with any status
(`running`, `exited`, `paused`, etc.).
If there is no container for the specified service name, the function returns exit code `1`.

The output of the successful function call for a particular service is always cached by the Dsb script,
and subsequent function calls without the `--anystatus` option just use this cached output.
Calling the function with the `--anystatus` option always rechecks
the current status of the container.

Example:

    #!/usr/bin/env dsb-script
    if [ -n "$1" ]; then
      dsb_get_container_id "$1" --anystatus
      docker container inspect --format "{{json .Config}}" "$DSB_OUT_CONTAINER_ID" | jq .
    else
      dsb_yellow_message 'The service name argument is required'
    fi

---

### `dsb_map_env`

     dsb_map_env [ VARNAME1 VARNAME2 ... ]

The function specifies the list of Bash variables that should be exported to the container
for the time of execution [`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_as_root`](#dsb_run_as_root), and  [`dsb_run_command`](#dsb_run_command)
functions.

Each call to the `dsb_map_env` function invalidates the list
specified by the previous function call.

Example:

     #!/usr/bin/env dsb-script
     dsb_map_env MYHOSTVAR
     MYHOSTVAR="Host variable value"
     dsb_run_as_user "@PYTHON" python -c "import os ; print(os.environ['MYHOSTVAR'])"

---

### `dsb_resolve_files`

    dsb_resolve_files [ EXT1 EXT2 ... ]

The function specifies the list of file name extensions for those file path parameters
whose relative form must first be converted to absolute form
and then mapped to the corresponding file path in the container.
Such a conversion occurs when executing the functions
[`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_as_root`](#dsb_run_as_root),
and [`dsb_run_command`](#dsb_run_command), if the
[`Mapping file paths in parameters`](#mapping-file-paths-in-parameters)
option is enabled for the corresponding service.
See [`DSB_ARGS_MAPPING`](#dsb_args_mapping) variable.

Each call to the `dsb_resolve_files` function invalidates the list
specified by the previous function call.

The relative filepath conversion option can be useful if for some reason we need to run
Dsb scripts in a working directory that is not bind-mounted to the corresponding container,
but the file itself is.

Example:

    #!/usr/bin/env dsb-script
    dsb_resolve_files php
    dsb_run_as_user "@PHP" php "$@"

See also [Mapping file paths in parameters](#mapping-file-paths-in-parameters).

---

### `dsb_run_as_root`

     dsb_run_as_root ( SERVICE_NAME | @SERVICE_ALIAS ) COMMAND [ ...COMMAND_ARGS ]

> You can append [explicit container index](#container-indexes)
to the `SERVICE_NAME` or [`@SERVICE_ALIAS`](#service-aliases).

The function executes the specified command in the container with the `root` access rights.
The first parameter specifies the target container.
The following parameters specify the command and its arguments.

This function is similar to the [`dsb_run_as_user`](#dsb_run_as_user) function
with the only difference being that container's `root` account is used.

See also  [`dsb_map_env`](#dsb_map_env), [`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_command`](#dsb_run_command), [`dsb root`](#dsb-root).

---

### `dsb_run_as_user`

    dsb_run_as_user ( SERVICE_NAME | @SERVICE_ALIAS ) COMMAND [ ...COMMAND_ARGS ]

> You can append [explicit container index](#container-indexes)
to the `SERVICE_NAME` or [`@SERVICE_ALIAS`](#service-aliases).

The function executes the specified command in the specified container
with access rights of the [`dsbuser`](#dsbuser-account) account.
The first parameter specifies the target container.
The following parameters specify the command and its arguments.

The target container can be defined as a service name or
as a [service alias](#service-aliases) prefixed with the `@` character.
If a service alias is used, the particular service name is determined based on the values
of the [`DSB_SERVICE_...`](#dsb_service_) variables in the [`.dsbenv`](#dsbenv-file) file.

When executing command in the container, the current host system's working directory
[is mapped to the container working directory](#mapping-the-working-directory),
if such mapping is possible.
Host system's file paths in the parameters can also be mapped to container's file paths,
if the [`Mapping file paths in parameters`](#mapping-file-paths-in-parameters)
option is enabled for the corresponding service.
See [`DSB_ARGS_MAPPING`](#dsb_args_mapping) variable,
[`dsb_resolve_files`](#dsb_resolve_files) function.

If the [`dsb_map_env`](#dsb_map_env) function was called in the Dsb script earlier,
the corresponding Bash variables are exported to the container for the time of command execution.

See also [`dsb_run_as_root`](#dsb_run_as_root), [`dsb_run_command`](#dsb_run_command),
[`dsb sh`](#dsb-sh).

---

### `dsb_run_command`

    dsb_run_command ( SERVICE_NAME | @SERVICE_ALIAS ) USERNAME COMMAND [ ...COMMAND_ARGS ]

> You can append [explicit container index](#container-indexes)
to the `SERVICE_NAME` or [`@SERVICE_ALIAS`](#service-aliases).

The function executes the specified command in the specified container
with access rights of the container's `USERNAME` account.
The first parameter specifies the target container.
The second parameter specifies the container's account.
The following parameters specify the command and its arguments.

This function is similar to the [`dsb_run_as_user`](#dsb_run_as_user)
and [`dsb_run_as_root`](#dsb_run_as_root) functions with the difference
that container's account is explicitly specified here.
The value of the `USERNAME` parameter can be specified as `login` or `UID:GID` string.

See also  [`dsb_map_env`](#dsb_map_env), [`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_as_root`](#dsb_run_as_root).

---

### `dsb_run_dsb`

    dsb_run_dsb SUBCOMMAND [ ...PARAMETERS ]

The function executes the [`dsb` utility subcommand](#dsb-utility-subcommands)
in the context of the current Dsb project.
Calling this function is used as the final step in executing the `dsb` utility itself.

The main difference between using this function and calling the `dsb` utility directly
is that you can first call the [`dsb_set_box`](#dsb_set_box) function with the `--dir` option.
Then all subsequent calls to the `dsb_run_dsb` function will apply
to the selected Dsb root directory regardless of the current working directory.
The given function behavior can be used to create a clone of the `dsb` utility
that is hardwired to a specific Dsb project.

For example, let's initialize some Dsb project:

    $ cd MY_DEFAULT_DSB_ROOT_DIRECTORY
    $ dsb init

and store the following script named `mydsb` in some local bin directory:

    #!/usr/bin/env dsb-script
    dsb_set_box --dir MY_DEFAULT_DSB_ROOT_DIRECTORY
    dsb_run_dsb "$@"

Now the `mydsb sh` and `mydsb root` subcommands can be run in any directory on the host system.
__This eliminates the binding of the project's__ [mounted directories](#mounted-directories)
__to the__ [Dsb root directory](#dsb-project-structure)__.__
Similarly, you can prepare a set of all necessary [Dsb scripts](#dsb-scripts)
for the project.

See also [`dsb_set_box`](#dsb_set_box).

---

### `dsb_set_box`

    dsb_set_box [ --check ] [ --dir STARTDIR ]

The function searches for the enclosing [Dsb root directory](#dsb-project-structure),
initializes [Dsb base variables](#dsb-base-variables),
and then executes the corresponding [`.dsbenv`](#dsbenv-file) file.

An explicit call to `dsb_set_box` must precede all other Dsb function calls.
This is because the other Dsb functions may invoke `dsb_set_box` internally
with no options by default.

If the `--dir` option is not specified, the Dsb root directory is searched starting
from  the current working directory at the moment the script is launched.
If the `--dir` option is specified, the search starts from the `STARTDIR` directory.
The latter use case allows Dsb scripts to be associated with specific Dsb projects
on the host system. Such scripts can be launched from any working directory
on the host system.

If the `--check` option is not specified and the enclosing Dsb root directory
is not found the Dsb script is terminated immediately.
If the `--check` option is specified, the function returns exit code `0`
on success and exit code `1` on failure.

The following functions always invoke `dsb_set_box` internally at the beginning of their execution:
[`dsb_docker_compose`](#dsb_docker_compose),
[`dsb_get_container_id`](#dsb_get_container_id),
[`dsb_run_as_root`](#dsb_run_as_root),
[`dsb_run_as_user`](#dsb_run_as_user),
[`dsb_run_command`](#dsb_run_command).
The [`dsb_set_single_box`](#dsb_set_single_box) function invokes `dsb_set_box` 
if only one Dsb project's containers are currently running on the host system.

__Another call to the `dsb_set_box` function after its successful completion is simply ignored.__
If you need to perform actions with several Dsb projects in one Dsb script,
you should use separate [subshell blocks](https://tldp.org/LDP/abs/html/subshells.html)
to call `dsb_set_box` function with appropriate `--dir` option values.

See also [`dsb_set_single_box`](#dsb_set_single_box).

---

### `dsb_set_single_box`

    dsb_set_single_box [ --check ]

The function may be used if containers of only one Dsb project are running
on the host system at any given time. Dsb scripts that call it can be run
from any working directory on the host system.

In the Dsb script, the `dsb_set_single_box` call must precede all other Dsb function calls.
The function locates the corresponding
Dsb root directory and then invokes [`dsb_set_box`](#dsb_set_box)
with the `--dir` option:

    dsb_set_box --dir <Dsb_root_directory>


Example:

    #!/usr/bin/env dsb-script
    dsb_set_single_box
    dsb_resolve_files js
    dsb_run_as_user "@NODE" node "$@"

If the `dsb_set_single_box` function is called without options and fails, it causes
the Dsb script to terminate immediately.
This happens when there are no running containers on the host system or when there are
containers belonging to several Dsb projects.
If the function is called with the `--check` option, it simply returns exit code `1` 
on failure, and the Dsb script can handle the failure:

    #!/usr/bin/env dsb-script
    if ! dsb_set_single_box --check ; then
        dsb_set_box  # use the enclosing Dsb root directory
    fi
    ...

See also [`dsb_set_box`](#dsb_set_box).

---

### `dsb_...message`

    dsb_message MESSAGE
    dsb_green_message MESSAGE
    dsb_red_message MESSAGE
    dsb_yellow_message MESSAGE

The functions are used to output color messages:

* The `dsb_message` and `dsb_green_message` functions output messages to STDOUT.
* The `dsb_red_message` and `dsb_yellow_message` functions output messages to STDERR.

Color mode is used only when outputting to the terminal.

You can use the `-n` option to suppress trailing newline:

    dsb_message -n "Dsb root directory: "
    echo "$DSB_ROOT"

---

Appendices
==========

## Configure MTU value

Docker Engine has a known issue when the default network interface has the MTU < 1500.
In this case, you need to adjust the MTU value for the Docker daemon
in the `/etc/docker/daemon.json`.

Example:

    {
        "mtu": 1450
    }

After adjusting the `mtu` parameter it is necessary to restart the Docker daemon
or reboot the host system.

Dsb uses the Docker daemon's MTU when initializing a new Dsb project.
The [`dsb init`](#dsb-init) subcommand place the MTU settings in the
`.dsb/compose/globals.yaml` file. When using ready-made Dsb configurations,
you should check this settings and adjust it if necessary.
