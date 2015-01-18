var gulp       = require('gulp'),
    gp         = require('gulp-load-plugins')({lazy: false}),
    coffee     = require('gulp-coffee'),
    uglify     = require('gulp-uglify'),
    filter     = require('gulp-filter'),
    bowerFiles = require('main-bower-files'),
    concat     = require('gulp-concat'),
    browserify = require('browserify'),
    sourcemaps = require('gulp-sourcemaps'),
    gutil      = require('gulp-util'),
    watch      = require('gulp-watch'),
    buffer     = require('vinyl-buffer'),
    source     = require('vinyl-source-stream');

gulp.task('ext-js', function() {
  gulp.src(bowerFiles())
    .pipe(filter("**/*.js"))
    .pipe(sourcemaps.init())
    .pipe(concat('vendor.js'))
    .pipe(uglify()).on('error', gutil.log)
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('dist'))
});

gulp.task('ext-css', function() {
  gulp.src(bowerFiles())
    .pipe(filter("**/*.css"))
    .pipe(concat('vendor.css'))
    .pipe(gulp.dest('dist'))
});

gulp.task('coffee', function() {
  bundler = browserify({
    entries: ["./lib/script.coffee"],
    debug: true,
    extensions: [".coffee", ".js"]
  })
  bundler
    .transform('coffeeify')
    .bundle()
    .pipe(source('app.js'))
    .pipe(buffer())
    .pipe(sourcemaps.init({loadMaps: true}))
    .pipe(uglify()).on('error', gutil.log)
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('dist'))
});

gulp.task('watch', function() {
  gulp.watch("bower_components/**/*.js", ['ext-js']);

  gulp.watch("bower_components/**/*.css", ['css'] );

  gulp.watch("lib/**/*.coffee", ['coffee'] );

});

gulp.task('default',
  ['ext-js', 'coffee', 'ext-css', 'watch']
);
