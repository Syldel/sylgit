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
    console.log 'options:'.yellow, '--log, --merge branch or --rebase branch or --rebase, --push'
    console.log '        '.yellow, ' -l  ,  -m branch     or  -r branch      or  -r     ,  -p'

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

      if @options.merge and @options.rebase
        console.log 'please choose "merge" or "rebase" action (not both)'.red
        return


      if @options.rebase is null

        try
          await @gitPull()
        catch err
          #console.log 'error:'.red, err
          throw err

      else
        if @options.merge or @options.rebase

          if @options.merge
            @targetBranch = @options.merge

          if @options.rebase
            @targetBranch = @options.rebase

          try
            await @gitFetch @remoteName + ' ' + @targetBranch
          catch err
            #console.log 'error:'.red, err
            throw err

          try
            if @options.merge
              await @gitMerge @targetBranch + ' --autostash'
            if @options.rebase
              await @gitRebase @targetBranch + ' --autostash'
          catch err
            #console.log 'error:'.red, err
            console.log '1. Resolve conflicts'
            if @options.merge
              console.log '2. `git push`'.yellow
            if @options.rebase
              console.log '2. `git rebase --continue`\n3. `git push --force-with-lease`'.yellow
            throw err

          ###
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
          ###


      console.log 'push?'
      if @options.push
        @gitPush()


  logInfos: ->
    console.log ('\ngit log').blue
    try
      log = await gitP.log '--graph', '--oneline', '-n', '18'
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


  ###
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
  ###

  ###
  gitCheckout: ->
    console.log ('\ngit checkout ' + @targetBranch).blue
    try
      d = await gitP.checkout @targetBranch
    catch err
      #console.log 'error:'.red, err
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

    if @options.push
      @gitPush()
    else
      console.log '\nNo Push action'.yellow
      console.log '(Use "-p" or "--push" to push)'.yellow
  ###

  ###
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
  ###

  gitPull: (pArgs = '--rebase --autostash') ->
    console.log '\ngit pull'.blue, String(pArgs).blue

    try
      p = await gitP.pull pArgs
    catch err
      #console.log 'error:'.red, err
      #console.log 'err.code:'.red, err.code
      throw err

    console.log ' Pull OK => '.green, p
    p


  gitFetch: (pArgs = '') ->
    console.log '\ngit fetch'.blue, String(pArgs).blue

    try
      f = await gitP.fetch pArgs
    catch err
      #console.log 'error:'.red, err
      #console.log 'err.code:'.red, err.code
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

      # Check --force-with-lease

      if c
        return c

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


app = new App()
