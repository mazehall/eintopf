var gulp = require('gulp');
var gulpGulp = require('gulp-gulp');

gulp.task('build', function () {
    return gulp.src('app/app_modules/*//gulpfile.js')
        .pipe(gulpGulp());
});

gulp.task('default', ['build']);
