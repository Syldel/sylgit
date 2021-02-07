colors = require 'colors'
cmd = require 'cmd-executor'
gitP = cmd.git
commandLineArgs = require 'command-line-args'

module.exports = class App

  remoteName: 'origin'
  currentBranch: undefined
  targetBranch: undefined
  options: undefined

  constructor: ->
    #console.log 'process.cwd():'.cyan, process.cwd()
    console.log 'This script will stash/unstash your current work (--autostash)'.blue
    console.log 'options:'.yellow, '--log (branch), --merge branch or --rebase (branch), --push'
    console.log '        '.yellow, ' -l (branch)  ,  -m branch     or  -r (branch)     ,  -p'

    optionDefinitions = [
      { name: 'log', alias: 'l', type: String }
      { name: 'merge', alias: 'm', type: String }
      { name: 'rebase', alias: 'r', type: String }
      { name: 'push', alias: 'p', type: Boolean }
    ]

    @options = commandLineArgs optionDefinitions
    #console.log '@options:', @options

    @init()


  init: ->
    if @options.merge and @options.rebase
      console.log 'please choose "merge" or "rebase" action (not both)'.red
      return

    if @options.log isnt undefined
      log = await @logInfos @options.log
      console.log log

    if @options.rebase isnt undefined
      try
        await @gitPull()
      catch err
        #console.log 'error:'.red, err
        @checkConflicts err
        throw err

    if @options.merge or @options.rebase

      if @options.merge
        @targetBranch = @options.merge

      if @options.rebase
        @targetBranch = @options.rebase

      try
        # Example : `git fetch origin +seen:seen maint:tmp`
        # This updates (or creates, as necessary) branches seen and tmp in the local repository
        # The seen branch will be updated even if it does not fast-forward, because it is prefixed with a plus sign; tmp will not be.
        await @gitFetch @remoteName + ' +' + @targetBranch + ':' + @targetBranch
      catch err
        #console.log 'error:'.red, err
        throw err

      try
        if @options.merge
          await @gitMerge @targetBranch + ' --autostash'
        if @options.rebase
          await @gitRebase @targetBranch + ' --autostash'
      catch err
        @checkConflicts err
        #console.log 'error:'.red, err
        console.log '1. Resolve conflicts'.yellow
        if @options.merge
          console.log '2. `git push`'.yellow
        if @options.rebase
          console.log '2. `git rebase --continue`\n3. `git push (--force-with-lease)`'.yellow
        throw err


    if @options.push
      try
        await @gitPush()
      catch err
        throw err


    if @options.log isnt undefined and (@options.rebase isnt undefined or @options.merge)
      log = await @logInfos @options.log
      console.log log


  logInfos: (pArgs = '') ->
    console.log ('\ngit log').blue, String(if pArgs then pArgs else '').blue
    try
      log = await gitP.log pArgs, '--graph', '--oneline', '-n', '18', '--decorate'
    catch err
      #console.log 'error:'.red, err
      throw err

    log


  gitStatus: ->
    console.log ('\ngit status').blue

    if @currentBranch
      cBranch = @currentBranch
    else

      try
        s = await gitP.status '--show-stash'
      catch err
        #console.log 'error:'.red, err
        throw err

      console.log ' Git status:'.green, s

      regEx = new RegExp /On branch ([\w\/-]*)\n/g
      matchBranch = regEx.exec s

      cBranch = matchBranch[1]
      console.log '\nCurrent Branch :'.green, cBranch

      ###
      @modifiedOrUntrackedFound = no

      regEx = new RegExp /[^.]*modified:[ ]*([\w\-.\/]*)\n/g
      while (matchModified = regEx.exec s) isnt null
        @modifiedOrUntrackedFound = yes

      regEx = new RegExp /[^.]*Untracked files:\n/g
      matchUntracked = regEx.exec s
      if matchUntracked
        @modifiedOrUntrackedFound = yes
      ###

      @currentBranch = cBranch

    cBranch


  gitPull: (pArgs = '--rebase --autostash') ->
    console.log '\ngit pull'.blue, String(pArgs).blue

    try
      p = await gitP.pull pArgs
    catch err
      #console.log 'error:'.red, err
      throw err

    console.log ' Pull OK => '.green, p
    p


  gitFetch: (pArgs = '') ->
    console.log '\ngit fetch'.blue, String(pArgs).blue

    try
      f = await gitP.fetch pArgs
    catch err
      #console.log 'error:'.red, err
      throw err

    console.log ' Fetch OK => '.green, f
    f


  gitRebase: (pArgs = '') ->
    console.log '\ngit rebase'.blue, String(pArgs).blue

    try
      r = await gitP.rebase pArgs
    catch err
      #console.log 'error:'.red, err
      throw err

    console.log ' Rebase OK => '.green, r
    r


  gitMerge: (pArgs = '') ->
    console.log '\ngit merge'.blue, String(pArgs).blue

    try
      m = await gitP.merge pArgs
    catch err
      #console.log 'error:'.red, err
      throw err

    console.log ' Merge OK => '.green, m
    m


  gitPush: (pArgs = '') ->
    # Possible args:
    #  --force-with-lease
    #  --set-upstream origin branch

    console.log '\ngit push'.blue, String(pArgs).blue

    try
      p = await gitP.push pArgs
    catch err
      #console.log 'error:'.red, err
      try
        c = await @checkUpStream pArgs, err
      catch err
        throw err

      try
        b = await @checkBehindBranch pArgs, err
      catch err
        throw err

      try
        n = await @checkNewWork err
      catch err
        throw err

      if c or b or n
        return c or b or n

      throw err

    console.log ' Push OK => '.green, p
    p


  checkUpStream: (pArgs, pErr) ->
    regEx = new RegExp /git push --set-upstream/g
    if regEx.exec pErr
      console.log '=> no upstream branch error'.cyan

      if pArgs.indexOf '--set-upstream' is -1 and pArgs.indexOf '-u' is -1
        try
          # Get branch name
          b = await @gitStatus()
        catch err
          #console.log 'error:'.red, err
          throw err

        try
          p = await @gitPush '--set-upstream ' + @remoteName + ' ' + b
        catch err
          #console.log 'error:'.red, err
          throw err

    p


  checkBehindBranch: (pArgs, pErr) ->
    regEx = new RegExp /Updates were rejected because the tip of your current branch is behind/g
    if regEx.exec pErr
      console.log '=> your current branch is behind!'.cyan

      ###
      if @options.rebase and pArgs.indexOf '--force-with-lease' is -1
        try
          p = await @gitPush '--force-with-lease'
        catch err
          #console.log 'error:'.red, err
          throw err

        return p

      if not @options.rebase
        try
          b = await @gitPull '--rebase --autostash'
        catch err
          #console.log 'error:'.red, err
          throw err

        return b
      ###

      console.log '   `git pull --rebase --autostash`\nor `git push (--force-with-lease)`'.yellow
      return yes

    no


  checkNewWork: (pErr) ->
    regEx = new RegExp /Updates were rejected because the remote contains work that you do/g
    if regEx.exec pErr
      console.log '=> your current branch contains work that you do!'.cyan

      ###
      try
        b = await @gitPull '--rebase --autostash'
      catch err
        #console.log 'error:'.red, err
        throw err

      try
        p = await @gitPush()
      catch err
        #console.log 'error:'.red, err
        throw err
      ###

      console.log '   `git pull --rebase --autostash`\nor `git push (--force-with-lease)`'.yellow
      return yes

    no


  checkConflicts: (pErr) ->
    regEx = new RegExp /error: Failed to merge in the changes./g
    regEx2 = new RegExp /error: Pulling is not possible because you have unmerged files./g
    if regEx.exec(pErr) or regEx2.exec(pErr)
      console.log '=> You have to resolve conflicts!'.cyan

      return yes

    no


app = new App()
