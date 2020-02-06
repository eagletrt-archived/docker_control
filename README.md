# Cross-compiling template

## Intro

This project is a template for quickly setting up a CMake+Docker-based cross-compiling environment for all the target systems supported by [Dockcross](https://github.com/dockcross/dockcross).

Dockcross is a powerful set of tools that greatly simplifies the task of cross-compiling for (many) embedded devices. If your project needs many external libraries, though, you still have to cross-compile those libraries, since Dockcross images come with the bare minimum for C/C++ compiling (i.e. the standard libraries).

This template aims at helping to **overcome this problem**.

The approach here is to cross-compile the dependencies within the docker image via proper Dockerfiles, so that you can build **tailored Dockcross images** that also contain your **cross-compiled dependencies**.

Furthermore, this template also provides a **basic scaffold for a multiplatform C/C++ project** plus the ability of generating a base Dockerfile for mipsel, ARMv6, ARMv7 and ARMv7a that provides the following cross-compiled libraries:

* ncurses (6.1)
* readline (8.0)
* openssl (1.0.1e)
* libmosquitto (1.5.1)
* ZeroMQ (4.3.2)
* lua (5.3.5)
* libYAML (0.2.2)
* binn ([serialization library](https://github.com/liteserver/binn))
* mruby (2.0.1) - this is disabled by default, set `ENABLE_MRUBY` in CMake if you need it
* OpenBLAS (0.3.6) - this is disabled by default, set `ENABLE_OPENBLAS` in CMake if you need it

The project is based on CMake and has template targets for building static and shared libraries plus an executable. It also **uses Git tags for managing number versioning in-code**.

### Prerequisites

* [Docker CE on Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/) or [Docker Desktop on Mac/Win](https://www.docker.com/products/docker-desktop); note that this has been tested on Mac and Linux and *not on Windows* (but it should work there with no/minimal changes)
* [Visual Studio Code](https://code.visualstudio.com/download) (suggested), or another good programmer editor
* CMake and a C/C++ compiler (gcc or clang)

### Tested platforms

At the moment the template contains the following tested dockerfiles:

* `mipsel`: tested on Onion Omega2
* `armv6`: tested on Raspberry Pi
* `armv7`: tested on Variscite DART-6UL armv7 SOM
* `armv7a`: tested on BeagleBone Black
* `arm64`: tested on nvidia PX2

The following sections assume to cross-compile for the armv7 platform. For other platforms, just replace the `./armv7` command with your need.

### Typical workflow

Once the Docker containers are properly set up (see later), the typical workflow is the following:

```bash
# mount the remote system target install directory:
$ sshfs user@targethost.local:/workdir products
# configure for local and cross compiling:
$ cmake -Bbuild -H. -DCMAKE_BUILD_TYPE=Debug
$ ./armv7 cmake -Bxbuild -H. -DCMAKE_BUILD_TYPE=Debug
# edit your source and compile/test it locally,
# (built products go in products_host dir):
$ make install
# build and install for target system
# (built products go in products dir):
$ ./armv7 make install
# open an ssh shell to the target system and test your executable
# (you will find it in /workdir/bin/)
# Correct bugs and repeat the last step until you are satisfied.
# Version your code and update version info:
$ git commit -am "commit message"
$ git tag -am "version comment" 0.1.0
$ ./armv7 cmake -Bxbuild -H. -DCMAKE_BUILD_TYPE=Release
$ ./armv7 make package
# (optional) copy the installer to /workdir on the target system
$ cp xbuild/myproject-Release-0.1.0-0-g0c05e15-Linux.sh products/
```

## Instructions

### Step 0: Create your own repo

If you are reading this on Github, just click on the green button named "Use this template" on the top of this page, create your repo and clone it.

Otherwise, just [follow this link](https://github.com/pbosetti/xtemplate/generate).

Once you are done **remember to add a git tag to the repo**: `git tag --am " " 0.0.1`. This is needed for enabling the CMake to automatically version-number your code. If you do not add a version number, **CMake will not work!**

### Step 1: Configure for local, and generate base Dockerfile

First of all you need to CMake configure the project for native compiling. This generated the Dockerfile for creating the Docker container according to the target platform that you select with the `TARGET_NAME` CMake variable. Allowed values for this variable are: `mipsel`, `armv6`, `armv7`, `armv7a`.

The Dockerfile is generated on the basis of the `Dockerfile.in` template file.

To select the target platform you can either pass it to the command line:

```bash
$ cmake -Bbuild -H. -DTARGET_NAME=armv7
```

or invoke the interactive `ccmake` and select the proper value (note the double 'c' in `ccmake`):

```bash
$ ccmake -Bbuild -H.
```

in the interactive environment, type `c`, then move down the list and repeatedly type `Enter` until the proper target is selected, then type again `c` and then `g`.

### Step 2: Customize and build your Dockcross image

Take as example the `Dockerfile` generated in Step 1: there are several steps showing how different libraries are cross compiled within the image. If the provided libraries are not enough, just add your own. My suggestion is to start with the provided image, build it with:

```bash
$ docker build -t armv7 -f arm7.Dockerfile .
$ docker run --rm armv7 > armv7 && chmod a+x armv7
```

then open a shell with `./armv7 bash`. Within this shell try to download, configure and cross compile the library you need, following the library instructiond on cross-compiling (this often needs to pass some options to the `configure` script or to the CMake command).
Once you figured out how to cross-compile the library you need, just add an additional `RUN` section at the end of the dockerfile.

When you are done, **remember to uncomment the latter lines** in the original `Dockerfile`, removing unnecessary intermediate build directories to save disk space in the resulting docker image.

From now on, you can prepend the `./armv7` command to build instructions.

**Note** that every time that you run CMake for native target it will regenerate the `Dockerfile` on the basis of `Dockerfile.in`, so if you want to make your additions permanent, consider adding them to `Dockerfile.in` rather than to the generated `Dockerfile`.

### Step 3: Configure your project

For configuring the project, the usual CMake command must be prepended with the magic command `./armv7` (or whichever is the name of your cross-build image):

```bash
# from within your project root directory
$ ./armv7 cmake -Bxbuild -H. -DCMAKE_BUILD_TYPE=Debug
```

while if you want to configure for your current (host) platform:

```bash
$ cmake -Bbuild -H. -DCMAKE_BUILD_TYPE=Debug
```

**IMPORTANT NOTE**: the Dockecross images mount the current working directory within the container, so that in order to access files in your project root you *must* invoke CMake from the project root. If you are tempred to do `cd xbuild; ./armv7 cmake ..` you will loose access to the project root and something probably will not work.

### Step 4: Build the project

For building, use the make command:

```bash
# from within your project root directory
$ ./armv7 make -Cxbuild
```

while if you want to build for your current (host) platform:

```bash
$ make -Cbuild
```

**IMPORTANT NOTE**: as per the note above, please invoke `./armv7 make` from the project root using the `-C` flag.

### Step 5: Installing the built binaries

You can now copy the binaries to the target platform according to your preferred procedure. I am here suggesting the one I find more effective and quick, though.

You have to set-up your target system by installing the `sshfs` package. This service allows you to mount a folder in the remote (target) system onto a folder of your development machine:

```bash
# from within your project root directory
$ sshfs user@target.ip:/path/to/prefix ./products
```

This command mounts the prefix directory on the target system onto the `products` subdir of your project directory. Since the Dockerfile install target is configured to install binaries into `products`, if you do

```bash
$ ./armv7 make -Cxbuild install
```

this installs the built stuff into `products/bin`, `products/lib`, `products/include`. In turn, since `products` mounts the prefix dir of the target system, the command `./armv7 make -Cxbuild install` compiles **and** copies the build results into the destination system in one single line. If you set `/usr/local` as prefix dir, your compiled stuff will end in `/usr/local/bin` etc.

**NOTE**: As an added value of this approach, within your editor you will have the possibility to remotely open and edit directly all the files in the mounted directory. This comes very handy for changing ASCII files that are part of the project, e.g. configuration files, data files, etc.

### Step 6: Create the installer

Using CPack, the provided CMake template can easily create an installer for the linux environment:

```bash
$ ./armv7 make -Cxbuild package
```

The resulting installer is in the `xbuild` folder, with a name with this scheme: `xtemplate-Release-0.0.1-1-g0c05e15-Linux.sh`, which reads like this: `<name>-<build type>-<version>-<patch>-<git hash>-<platform>.sh`. The patch number is the number of commits past the given version tag.

If the git hash is followed by `§` then the originating git is in a dirty state, i.e., there are pending changes to be committed.

**NOTE**: the proper versioning information is collected by the CMake command, **not** by make. Consequently, in order to have updated and correct version numbering in the installer name and in the `defines.h` **remember to re-run cmake** before calling `make package` and after each commit.

## Visual Studio Code integration

This template also provides 4 *tasks* for Visual Studio Code. If you enter `tasks` in the command palette you will find:

1. `clean xbuild`: removes the content of the `xbuild` folder
2. `cross-configure`: performs the CMake configuration
3. `cross-compile`: performs the actual compilation
4. `install`: install the compilation results into `products`

On Mac, tasks can be quickly invoked with `cmd-shift-B`, on Linux/Windows with `ctrl-shift-B`.
You can customize the tasks by editing the `.vscode/tasks.json` file.

## License

MIT License. See `LICENSE` file.
