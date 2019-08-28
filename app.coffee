colors = require 'colors'
prompt = require 'prompt'
fs = require 'fs'
q = require 'q'
gitP = require 'simple-git/promise'

module.exports = class App

  currentBranch: undefined
  targetBranch: undefined
  needToStashPop: no

  constructor: ->
    console.log 'process.cwd():'.cyan, process.cwd()

    gitP().cwd process.cwd()

    gitP().status().then (s) =>
      console.log 'Git status:', s
      @currentBranch = s.current
      console.log '\nCurrent Branch :'.blue, @currentBranch
      @gitStash()
    , (err) ->
      console.log 'err:'.red, err


  gitStash: ->

    console.log '\nAre you OK to stash ?'.magenta
    prompt.start()

    promptSchema =
      properties:
        stash:
          pattern: /^[a-zA-Z]+$/
          message: 'Answer y/n or yes/no'
          required: true
          default: 'no'

    prompt.get promptSchema, (err, result) =>
      if err
        console.log "error:".red, err
      else
        stashOK = result.stash
        console.log ' stash:', (stashOK).cyan

        if stashOK is 'yes' or stashOK is 'y'

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

    console.log '\nWhich branch do you want to merge ?'.magenta

    promptSchema =
      properties:
        branch:
          pattern: /^[a-zA-Z0-9\/\\\-_.:]+$/
          message: 'Branch must be only letters, numbers and/or dashes, dots'
          required: true
          default: 'develop'

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
          console.log ' Checkout OK => '.green, d

          console.log ('\ngit pull').blue
          gitP().pull()
          .then (p) =>
            console.log ' Pull OK => '.green, p

            console.log ('\ngit checkout ' + @currentBranch).blue
            gitP().checkout @currentBranch
            .then (c) =>
              console.log ' Checkout OK => '.green, c

              @gitMerge()


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

            if @needToStashPop
              console.log '\ngit stash pop'.blue
              gitP().stash ['pop']
              .then (p) =>
                console.log ' Pop OK => '.green, p
            else
              console.log '\nDon\'t need to "stash pop"'.yellow


app = new App()
