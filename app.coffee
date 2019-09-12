colors = require 'colors'
prompt = require 'prompt'
fs = require 'fs'
q = require 'q'
gitP = require 'simple-git/promise'
commandLineArgs = require 'command-line-args'
shell = require 'shelljs'

module.exports = class App

  currentBranch: undefined
  targetBranch: undefined
  gitStatus: undefined
  needToStashPop: yes

  constructor: ->
    console.log 'process.cwd():'.cyan, process.cwd()

    optionDefinitions = [
      { name: 'log', alias: 'l', type: Boolean }
    ]

    options = commandLineArgs optionDefinitions
    console.log 'options:', options

    @initGit().then () =>
      if options.log
        gitP().raw ['--no-pager', 'log', '--graph', '--oneline', '-n', '18']
        .then (log) ->
          console.log 'log:', log
      else
        @gitStash()


  initGit: ->
    console.log '\nInit Git'.cyan
    deferred = q.defer()
    gitP().cwd process.cwd()

    console.log ('\ngit status').blue
    gitP().status().then (s) =>
      console.log ' Git status:'.green, s
      @gitStatus = s
      @currentBranch = s.current
      console.log '\n Current Branch :'.green, @currentBranch
      deferred.resolve()

    , (err) ->
      console.log 'err:'.red, err
      deferred.reject err

    deferred.promise


  gitStash: ->

    if @gitStatus.files.length > 0

      console.log '\ngit stash push --include-untracked'.blue
      gitP().stash ['push', '--include-untracked']
      .then (d) =>
        console.log ' Stash OK => '.green, d

        if d is 'No local changes to save'
          @needToStashPop = no
        @gitCheckout()
    else
      @needToStashPop = no
      @gitCheckout()


  gitCheckout: ->

    @getClosestParentBranch().then (parentBranch) =>
      console.log 'Parent branch:'.green, parentBranch

      console.log '\nWhich branch do you want to merge ?'.magenta

      promptSchema =
        properties:
          branch:
            pattern: /^[a-zA-Z0-9\/\\\-_.:]+$/
            message: 'Branch must be only letters, numbers and/or dashes, dots'
            required: true
            default: parentBranch

      prompt.get promptSchema, (err, result) =>
        if err
          console.log 'error:'.red, err
        else
          branch = result.branch
          console.log ' branch:', (branch).cyan
          @targetBranch = branch

          console.log ('\ngit checkout ' + branch).blue
          gitP().checkout branch
          .then (d) =>
            console.log ' Checkout OK'.green

            console.log ('\ngit pull').blue
            gitP().pull()
            .then (p) =>
              console.log ' Pull OK => '.green, p

              console.log ('\ngit checkout ' + @currentBranch).blue
              gitP().checkout @currentBranch
              .then (c) =>
                console.log ' Checkout OK'.green

                gitP().raw ['--no-pager', 'log', '--graph', '--oneline', '-n', '12']
                .then (log) =>
                  console.log 'log:', log

                  @gitMerge()


  getClosestParentBranch: ->
    deferred = q.defer()

    #git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'

    #gitP().raw ['show-branch']
    #.then (sb) =>
    #  console.log 'sb', sb

    child = shell.exec("git show-branch | grep '*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1", {async: true})
       # | sed 's#[.]*\[\(.*\)\][.]*#\1#'")
       # | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//\'")

    child.stdout.on 'data', (data) ->
      #console.log 'data:', data
      found = data.match /[.]*\[(.*)\][.]*/
      #console.log 'found:', found[1]
      branch = found[1]
      if branch
        branch = branch.replace /[\^~].*/, ''

      deferred.resolve branch

    deferred.promise


  gitMerge: ->

    console.log ('\nAre you sure you want to merge ' + @targetBranch + ' in ' + @currentBranch + ' ?').magenta

    promptSchema =
      properties:
        merge:
          pattern: /^[a-zA-Z]+$/
          message: 'Answer y/n or yes/no'
          required: true
          default: 'no'

    prompt.get promptSchema, (err, result) =>
      if err
        console.log 'error:'.red, err
      else
        mergeOk = result.merge
        console.log ' mergeOk:', (mergeOk).cyan

        if mergeOk is 'yes' or mergeOk is 'y'

          console.log ('\ngit merge ' + @targetBranch).blue
          gitP().merge [@targetBranch]
          .then (m) =>
            console.log ' Merge OK => '.green, m

            @gitStashPop()

        else
          console.log 'You don\t want to merge'

          @gitStashPop()


  gitStashPop: ->

    if @needToStashPop
      console.log '\ngit stash pop'.blue
      gitP().stash ['pop']
      .then (p) ->
        console.log ' Pop OK => '.green, p
    else
      console.log '\nDon\'t need to "stash pop"'.yellow


app = new App()
