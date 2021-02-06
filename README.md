# Sylgit Tools

This script will stash/unstash your current work.

Good to know :

Since `Git 2.6` you can use the autostash option to automatically stash and pop your uncommitted changes. (`--autostash`)

### How to use

##### Command arguments :

--log (branch), --merge branch or --rebase (branch), --push

Or :

 -l (branch)  ,  -m branch     or  -r (branch)     ,  -p

To rebase "master" branch and push with --force-with-lease

```
sylgit -r master -p -l
```

To merge "master" branch and push

```
sylgit -m master -p -l
```

### Requirements

You need to have node and git (> 2.6)

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
