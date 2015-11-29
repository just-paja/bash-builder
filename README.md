# bash-builder

Small tool that concatenates your scripts into one file. Nice if you need to run scripts on remote servers or create autorun script archive that self-extracts, but also is capable of reading getopt.

Files that are to be packed into the script are called inlines. It could be anything from configuration files, across all sorts of binaries or images to ascii art.

Works on Linux, theoretically could work on all UNIX platforms.

## Requirements

* Bash
* getopt
* file
* ssh
* tar

## Installation

Clone git repository link or point "bash-builder" executable in your `$PATH`.

## Usage

You can create your own bash script workspace by running `bash-builder -w`. It only creates `.bash-builder` file in your cwd. It then expects you to have all projects in `projects` directory. You can choose between global, local and project inlines.

### Example directory structure
```
repository
| .bash-builder
| projects
| | test
| | | inline
| | | | vars.sh
| | | scripts
| | | | run.sh
| | | pre-run.sh
| | | meta
| inline
| | logo.aa
| | config.yml
```

### Executable usage
```bash
bash-builder [-a|--all] [-c|--clean] [-h|--help] [-i|--ident] [-l|--list] [-o|--on]

 Utility capable of building all helper install scripts.

 -a|--all   Build all
 -c|--clean Run only clean, no build
 -h|--help  Show usage (this)
 -i|--ident Identity file path
 -l|--list  List all available
 -o|--on    Try to ssh to a machine and run the built script there
 -r|--run   Also run the script. Pass all arguments to it.

 Examples:
 ./build script -i test.pem -o user@machine
```
