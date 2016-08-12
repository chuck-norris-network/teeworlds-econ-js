path             = require 'path'
gulp             = require 'gulp'
coffeelint       = require 'gulp-coffeelint'
excludeGitignore = require 'gulp-exclude-gitignore'
nsp              = require 'gulp-nsp'
coffee           = require 'gulp-coffee'
codo             = require 'gulp-codo'

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

gulp.task 'doc', () ->
  gulp.src './src/**/*.coffee', read: false
    .pipe codo(
      name: 'Teeworlds External Console'
      title: 'Teeworlds External Console documentation'
      readme: 'README.md'
      extra: 'LICENSE.md'
    )

gulp.task 'nsp', (done) ->
  nsp { package: path.resolve('./package.json') }, done

gulp.task 'default', ['static', 'nsp', 'build', 'doc']
