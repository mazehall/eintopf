'use strict';

module.exports = function (grunt) {
    grunt.config.merge({
        jshint: {
            options: {
                jshintrc: '.jshintrc'
            },
            all: {
                src: [
                    'Gruntfile.js',
                    'src/{,*/}*.js',
                    'tasks/{,*/}*.js',
                    'test/{,*/}*.js'
                ]
            }
        }
    });
};