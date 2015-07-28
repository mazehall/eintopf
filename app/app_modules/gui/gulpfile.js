var gulp = require('gulp');

var usemin = require('gulp-usemin');
var gutil = require('gulp-util');
var minifyCss = require('gulp-minify-css');
var minifyJs = require('gulp-uglify');
var less = require('gulp-less');
var rev = require('gulp-rev');


var emitter = require('events').EventEmitter;

var paths = {
    distRoot: 'public/dist',
    scripts: 'public/src/js/**/*.*',
    less: 'public/src/less/**/*.*',
    css: 'public/src/css/**/*.*',
    images: 'public/src/img/**/*.*',
    html: 'public/src/*.html',
    bower_fonts: 'public/src/bower_components/**/*.{ttf,woff,woff2,eof,svg}',
    fonts: 'public/src/fonts/**/*.{ttf,woff,eof,svg}'
};

/**
 * Handle index.html
 */
gulp.task('usemin', function () {
    return gulp.src(paths.html)
        .pipe(usemin({
            css: [minifyCss(), 'concat'],
            js: [minifyJs(), rev()],
            minJs: [minifyJs(), 'concat'],
            customCss: [minifyCss({keepSpecialComments: 0})],
            customLess: [less(), minifyCss()]
        }))
        .pipe(gulp.dest(paths.distRoot + '/'));
});

gulp.task('build', ['usemin']);

gulp.task('default', ['build']);

/**
 * fix memory leak
 */
emitter.defaultMaxListeners = 0;
