# Sylgit Tools

This script allows to "rebase" in an easier way.

### Good to know :

Since `Git 2.6` you can use the autostash option to automatically stash and pop your uncommitted changes. (`--autostash`)

##### pull.rebase and rebase.autoStash git config

Instead of invoking this option manually, you can also set this for your repository with git config:

```
$ git config pull.rebase true
$ git config rebase.autoStash true
```

Or you can set this globally for every Git repository:

```
$ git config --global pull.rebase true
$ git config --global rebase.autoStash true
```

The --autostash option only works with --rebase, so it makes sense to set these two together.

### How to use

##### Command arguments :

--log (branch), --merge branch or --rebase (branch), --push

Or :

 -l (branch)  ,  -m branch     or  -r (branch)     ,  -p

To rebase "master" branch and push showing logs

```
sylgit -r master -p -l
```

To merge "master" branch and push showing logs

```
sylgit -m master -p -l
```

To rebase current branch and show logs

```
sylgit -r -l
```

### Requirements

You need to have node and git (> 2.6)

Very important : Set your language environment to english!
For example, in .zshrc, enable `export LANG=en_US.UTF-8`

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
