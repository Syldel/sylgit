colors = require 'colors'
prompt = require 'prompt'
fs = require 'fs'
q = require 'q'
cmd = require 'cmd-executor'
gitP = cmd.git
commandLineArgs = require 'command-line-args'

module.exports = class App

  currentBranch: undefined
  needToStashPop: yes
  options: undefined

  constructor: ->
    console.log 'process.cwd():'.cyan, process.cwd()
    console.log 'This script will stash/unstash your current work'.blue
    console.log 'options:'.yellow, '--branch dev --log --merge or --rebase --push', '(-b dev, -l, -m or -r -p)'

    optionDefinitions = [
      { name: 'branch', alias: 'b', type: String }
      { name: 'log', alias: 'l', type: Boolean }
      { name: 'merge', alias: 'm', type: Boolean }
      { name: 'rebase', alias: 'r', type: Boolean }
      { name: 'push', alias: 'p', type: Boolean }
    ]

    @options = commandLineArgs optionDefinitions
    console.log '@options:', @options

    if @options.log
      @logInfos()
    else
      if not @options.branch
        console.log 'please precise branch with "-b dev" or "--branch dev"'

      if not @options.merge and not @options.rebase
        console.log 'please precise merge or rebase action with "-m / -r" or "--merge / --rebase"'

      if @options.branch and (@options.merge or @options.rebase)
        @initGit().then () =>
          @gitStash()


  logInfos: ->
    console.log ('\ngit log').blue
    try
      log = await gitP.log '--graph', '--oneline', '-n', '18'
    catch err
      console.log 'error:'.red, err
      return

    console.log log
    return


  initGit: ->
    #console.log '\nInit Git'.cyan
    deferred = q.defer()

    console.log ('\ngit status').blue
    try
      s = await gitP.status '--show-stash'
    catch err
      console.log 'error:'.red, err
      deferred.reject err

    if not err
      console.log ' Git status:'.green, s

      if @currentBranch is 'master'
        console.log ' You already are in "master" branch'.red
      else
        if @currentBranch is @options.branch
          console.log (' You already are in "' + @options.branch + '" branch').red
        else

          regEx = new RegExp /On branch ([\w\/-]*)\n/g
          matchBranch = regEx.exec s

          @currentBranch = matchBranch[1]
          console.log '\nCurrent Branch :'.green, @currentBranch

          @modifiedOrUntrackedFound = no

          regEx = new RegExp /[^.]*modified:[ ]*([\w\-.]*)\n/g
          while (matchModified = regEx.exec s) isnt null
            @modifiedOrUntrackedFound = yes

          regEx = new RegExp /[^.]*Untracked files:\n/g
          matchUntracked = regEx.exec s
          if matchUntracked
            @modifiedOrUntrackedFound = yes

          deferred.resolve()

    deferred.promise


  gitStash: ->

    if @modifiedOrUntrackedFound
      console.log '\ngit stash push --include-untracked'.blue

      try
        d = await gitP.stash 'push', '--include-untracked'
      catch err
        console.log 'error:'.red, err
        return

      console.log ' Stash OK => '.green, d

      if d is 'No local changes to save'
        @needToStashPop = no

      @gitCheckout()
    else
      @needToStashPop = no
      @gitCheckout()


  gitCheckout: ->
    console.log ('\ngit checkout ' + @options.branch).blue
    try
      d = await gitP.checkout @options.branch
    catch err
      console.log 'error:'.red, err
      @gitStashPop()
      return
    console.log ' Checkout OK'.green

    console.log ('\ngit pull').blue
    try
      p = await gitP.pull()
    catch err
      console.log 'error:'.red, err
      return
    console.log ' Pull OK => '.green, p

    console.log ('\ngit checkout ' + @currentBranch).blue
    try
      c = await gitP.checkout @currentBranch
    catch err
      console.log 'error:'.red, err
      return
    console.log ' Checkout OK'.green

    await @logInfos()

    @gitMergeOrRebase()


  gitMergeOrRebase: ->

    if @options.merge
      console.log ('\ngit merge ' + @options.branch).blue
      try
        m = await gitP.merge @options.branch
      catch err
        console.log 'error:'.red, err
        return
      console.log ' Merge OK => '.green, m

    if @options.rebase
      console.log ('\ngit rebase ' + @options.branch).blue
      try
        r = await gitP.rebase @options.branch
      catch err
        console.log 'error:'.red, err
        return
      console.log ' Rebase OK => '.green, r

    @gitStashPop()


  gitStashPop: ->

    if @needToStashPop
      console.log '\ngit stash pop'.blue
      try
        p = await gitP.stash 'pop'
      catch err
        console.log 'error:'.red, err
        return
      console.log ' Stash Pop OK => '.green, p
    else
      console.log '\nDon\'t need to "stash pop"'.yellow


app = new App()
