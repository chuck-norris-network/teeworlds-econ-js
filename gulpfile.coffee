path             = require 'path'
gulp             = require 'gulp'
coffeelint       = require 'gulp-coffeelint'
excludeGitignore = require 'gulp-exclude-gitignore'
nsp              = require 'gulp-nsp'
coffee           = require 'gulp-coffee'

gulp.task 'static', () ->
  gulp.src '**/*.coffee'
    .pipe excludeGitignore()
    .pipe coffeelint()
    .pipe coffeelint.reporter()
    .pipe coffeelint.reporter('fail')

gulp.task 'build', () ->
  gulp.src './src/**/*.coffee'
    .pipe coffee({ bare: true })
    .pipe gulp.dest('./lib')

gulp.task 'nsp', (done) ->
  nsp { package: path.resolve('./package.json') }, done

gulp.task 'prepublish', ['static', 'nsp', 'build']
gulp.task 'default', ['static', 'build']
