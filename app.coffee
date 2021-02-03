colors = require 'colors'
cmd = require 'cmd-executor'
gitP = cmd.git
commandLineArgs = require 'command-line-args'

module.exports = class App

  currentBranch: undefined
  targetBranch: undefined
  needToStashPop: yes
  options: undefined

  constructor: ->
    console.log 'process.cwd():'.cyan, process.cwd()
    console.log 'This script will stash/unstash your current work'.blue
    console.log 'options:'.yellow, '--log, --merge branch or --rebase branch, --push', '(-l, -m branch or -r branch, -p)'

    optionDefinitions = [
      { name: 'log', alias: 'l', type: Boolean }
      { name: 'merge', alias: 'm', type: String }
      { name: 'rebase', alias: 'r', type: String }
      { name: 'push', alias: 'p', type: Boolean }
    ]

    @options = commandLineArgs optionDefinitions
    console.log '@options:', @options

    @init()


  init: ->
    if @options.log
      log = await @logInfos()
      console.log log
    else
      if not @options.merge and not @options.rebase
        console.log 'please precise "merge" or "rebase" action with "-m branch / -r branch" or "--merge branch / --rebase branch"'.red
        return

      if @options.merge and @options.rebase
        console.log 'please choose "merge" or "rebase" action (not both)'.red
        return

      if @options.merge
        @targetBranch = @options.merge

      if @options.rebase
        @targetBranch = @options.rebase


      @currentBranch = await @initGit()
      if @currentBranch
        if @currentBranch is 'master'
          console.log ' You already are in "master" branch'.red
        else
          if @currentBranch is @targetBranch
            console.log (' You already are in "' + @targetBranch + '" branch').red
          else
            @gitStash()

      else
        console.log ' current branch no found!'.red


  logInfos: ->
    console.log ('\ngit log').blue
    try
      log = await gitP.log '--graph', '--oneline', '-n', '18'
    catch err
      console.log 'error:'.red, err
      throw err

    log


  initGit: ->
    console.log ('\ngit status').blue
    try
      s = await gitP.status '--show-stash'
    catch err
      console.log 'error:'.red, err
      throw err

    console.log ' Git status:'.green, s

    regEx = new RegExp /On branch ([\w\/-]*)\n/g
    matchBranch = regEx.exec s

    currentBranch = matchBranch[1]
    console.log '\nCurrent Branch :'.green, currentBranch

    @modifiedOrUntrackedFound = no

    regEx = new RegExp /[^.]*modified:[ ]*([\w\-.\/]*)\n/g
    while (matchModified = regEx.exec s) isnt null
      @modifiedOrUntrackedFound = yes

    regEx = new RegExp /[^.]*Untracked files:\n/g
    matchUntracked = regEx.exec s
    if matchUntracked
      @modifiedOrUntrackedFound = yes

    currentBranch


  gitStash: ->

    if @modifiedOrUntrackedFound
      console.log '\ngit stash push --include-untracked'.blue

      try
        d = await gitP.stash 'push', '--include-untracked'
      catch err
        console.log 'error:'.red, err
        throw err

      console.log ' Stash OK => '.green, d

      if d is 'No local changes to save'
        @needToStashPop = no

      @gitCheckout()
    else
      @needToStashPop = no
      @gitCheckout()


  gitCheckout: ->
    console.log ('\ngit checkout ' + @targetBranch).blue
    try
      d = await gitP.checkout @targetBranch
    catch err
      console.log 'error:'.red, err
      @gitStashPop()
      throw err
    console.log ' Checkout OK'.green

    console.log ('\ngit pull').blue
    try
      p = await gitP.pull()
    catch err
      console.log 'error:'.red, err
      throw err
    console.log ' Pull OK => '.green, p

    console.log ('\ngit checkout ' + @currentBranch).blue
    try
      c = await gitP.checkout @currentBranch
    catch err
      console.log 'error:'.red, err
      throw err
    console.log ' Checkout OK'.green

    log = await @logInfos()
    console.log log

    @gitMergeOrRebase()


  gitMergeOrRebase: ->

    if @options.merge
      console.log ('\ngit merge ' + @targetBranch).blue
      try
        m = await gitP.merge @targetBranch
      catch err
        console.log 'error:'.red, err
        throw err
      console.log ' Merge OK => '.green, m

    if @options.rebase
      console.log ('\ngit rebase ' + @targetBranch).blue
      try
        r = await gitP.rebase @targetBranch
      catch err
        console.log 'error:'.red, err
        if err.code is 128
          console.log '1. Resolve conflicts\n2. `git rebase --continue`\n3. `git push --force-with-lease`\n4. `git stash pop`'.yellow
        throw err
      console.log ' Rebase OK => '.green, r

    try
      await @gitStashPop()
    catch err
      throw err

    @gitPush()


  gitStashPop: ->

    if @needToStashPop
      console.log '\ngit stash pop'.blue
      try
        p = await gitP.stash 'pop'
      catch err
        console.log 'error:'.red, err
        throw err
      console.log ' Stash Pop OK => '.green, p
    else
      console.log '\nDon\'t need to "stash pop"'.yellow


  gitPush: ->

    if @options.push
      try
        if @options.merge
          console.log '\ngit push'.blue
          p = await gitP.push()

        if @options.rebase
          console.log '\ngit push --force-with-lease'.blue
          p = await gitP.push '--force-with-lease'

      catch err
        console.log 'error:'.red, err

        regEx = new RegExp /git push --set-upstream origin/g
        if regEx.exec err
          console.log 'no upstream branch error'.cyan
          try
            console.log ('\ngit push --set-upstream origin ' + @currentBranch).blue
            p2 = await gitP.push '--set-upstream origin ' + @currentBranch
          catch err
            console.log 'error:'.red, err
            throw err
          console.log ' Push OK => '.green, p2

        throw err

      console.log ' Push OK => '.green, p
    else
      console.log '\nNo Push action'.yellow
      console.log '(Use "-p" or "--push" to push)'.yellow

app = new App()
