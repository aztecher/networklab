# Differential-Datalog sandbox container

This folder containes the files that are used at the build time of docker container.
You can use docker container to execute/test programs located under the `ddlog/<FOLDER>`.

## Requirement

* docker

## Build docker image

First, you build the docker images in this repository.

```bash
$ cd ddlog/sandbox
$ docker build -t <YOUR REPOSITORY>/<NAME>:<TAG> .

ex. docker build -t aztecher/ddlog:v0.0.1 .
```

## Usage of the docker container and ddlog programs

After building the docker image and if you want to execute/test the program located under `ddlog/<FOLDER>` directory,
then move into the directory and run container with mount option.

```bash
$ cd ../<FOLDER>
$ docker run --rm -v `pwd`:/workspace -it <YOUR REPOSITORY>/<NAME>:<TAG> /bin/bash

ex1.
$ cd ../sample
$ docker run --rm -v `pwd`:/workspace -it aztecher/ddlog:v0.0.1 /bin/bash

ex2.
# If you want to set the hard-limit for memory, then use `-m` option.
# If you want to allow more cpus, then `--cpus` option.
$ docker run --rm -v `pwd`:/workspace -m 8g --cpus 8 -it aztecher/ddlog:v0.0.1 /bin/bash
```

This container includes the packages that are used in ddlog compilation/execution.
In order to set the PATH to make some binaries executable, please source `/etc/bash.bashrc` file.

```bash
# read the /etc/bash.bashrc to set the required PATH
root@1d2dd8ebde65:/workspace# source /etc/bash.bashrc

# After that, you can execute some commands that are required to build/execute the ddlog program.
root@1d2dd8ebde65:/workspace# which cargo
/root/.cargo/bin/cargo
root@1d2dd8ebde65:/workspace# which ddlog
/usr/local/ddlog/bin/ddlog
root@1d2dd8ebde65:/workspace# echo $DDLOG_HOME
/usr/local/ddlog
```

If the `run_with_docker.sh` file exists in the `ddlog/<FOLDER>`, you can automatically execute that programs and get its result.

```bash
$ cd ddlog/<FOLDER>/
$ ./run_with_docker.sh <CONTAINER_NAME>

ex1.
$ ./run_with_docker.sh aztecher/ddlog:v0.0.1

ex2.
# If you want to set memory hard-limit and available cpus, then please set bellow environmental variables
$ export CONTAINER_MEM=8g # set the memory hard-limit to 8G
$ export CONTAINER_CPUS=8 # set the available amount of CPUs is 8(core)
$ ./run_with_docker.sh aztecher/ddlog:v0.0.1
```
