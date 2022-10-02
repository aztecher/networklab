# DDlog sample

This program is the [tutorial of DDlog](https://github.com/vmware/differential-datalog/blob/master/doc/tutorial/tutorial.md) and this repository expected to be executed within docker container.

If you haven't checked the README of our docker sandbox, please see the [ddlog/sandbox/README.md](../sandbox/README.md) first.

## Prerequisites

Please see the [ddlog/sandbox/README.md](../sandbox/README.md) and build your own docker container that contains the tools for compiling/executing your DDlog program.


## Getting Started

You can see the result of the execution of the [tutorial of DDlog](https://github.com/vmware/differential-datalog/blob/master/doc/tutorial/tutorial.md) using `run_with_docker.sh`.

```bash
$ ./run_with_docker.sh <CONTAINER_NAME>

ex.
$ ./run_with_docker.sh aztecher/ddlog:v0.0.1
..
(省略)
...
Phrases:
Phrases{.phrase = "Goodbye, Ruby Tuesday"}
Phrases{.phrase = "Goodbye, World"}
Phrases{.phrase = "Hello, Ruby Tuesday"}
Phrases{.phrase = "Hello, World"}
Phrases{.phrase = "Help me, Obi-Wan Kenobi"}
Phrases{.phrase = "Help me, father"}
Phrases{.phrase = "I am your Obi-Wan Kenobi"}
Phrases{.phrase = "I am your father"}
+ rm -rf playpen_ddlog
```

This program is like 'Hello, World', so there is no deep meaning.  
It's the easiest program to compile and run a DDlog program in docker container and see what results you get without dirtying your host.
