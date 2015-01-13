var gulp       = require('gulp'),
    coffee     = require('gulp-coffee'),
    uglify     = require('gulp-uglify'),
    filter     = require('gulp-filter'),
    bowerFiles = require('main-bower-files'),
    concat     = require('gulp-concat'),
    sourcemaps = require('gulp-sourcemaps'),
    gutil      = require('gulp-util'),
    watch      = require('gulp-watch');

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
  gulp.src("lib/*.coffee")
    .pipe(sourcemaps.init())
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(concat('app.js'))
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
