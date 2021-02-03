# Sylgit Tools

This script will stash/unstash your current work

### How to use

##### Command arguments :

--log, --merge branch or --rebase branch, --push
Or :
-l, -m branch or -r branch, -p

To rebase "master" branch and push with --force-with-lease

```
sylgit -r master -p
```

To merge "master" branch and push

```
sylgit -m master -p
```

### Requirements

You need to have node

### Installation

Install required node packages

```
npm install
```

### Symlink

First, clone this repository.
To prepare symlink, go in the directory of this project and do :

```
npm link
```

(Maybe you will need sudo)

Now you can directly use "sylgit" command from the other projects

(If you work on the "bin" system, maybe you should unlink and link again)

### Build

```
npm run build
```

To generate the js file from the coffee file.

### watch

```
npm run watch
```
