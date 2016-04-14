/**
 * Created by berthelot on 05/11/14.
 */
'use strict';

module.exports = function (grunt) {
    grunt.config.merge({
        uglify: {
            options: {
                mangle: false
            },
            dist: {
                files: {
                    'angular-images-resizer.js': ['src/resize.js','src/{,*/}*.js']
                }
            }
        }
    });
};