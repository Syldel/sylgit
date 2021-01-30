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

gulp.task 'coffeeBuild', gulp.series('lint', 'coffee')

gulp.task 'watchCoffee', ->
  gulp.watch '*.coffee', gulp.series('coffeeBuild')

gulp.task 'watch', gulp.series 'coffeeBuild', 'watchCoffee'

gulp.task 'default', gulp.series('watch')
