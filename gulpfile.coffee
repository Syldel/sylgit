gulp = require 'gulp'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'

sources =
  coffee: '*.coffee'

destinations =
  js: '.'

gulp.task 'coffee', ->
  gulp.src(sources.coffee)
  .pipe(coffee({ bare: true }))
  .pipe(gulp.dest(destinations.js))

gulp.task 'lint', ->
  gulp.src(sources.coffee)
  .pipe(coffeelint())
  .pipe(coffeelint.reporter())

gulp.task 'coffeeBuild', ['lint', 'coffee']

gulp.task 'watch', ['coffeeBuild'], ->
  gulp.watch '*.coffee', ['coffeeBuild']

gulp.task 'default', ['watch']