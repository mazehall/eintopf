'use strict';

module.exports = function (grunt) {

    // Time how long tasks take. Can help when optimizing build times
    require('time-grunt')(grunt);

    // Load grunt tasks automatically
    require('load-grunt-tasks')(grunt);

    // Load tasks config and custom grunt tasks
    grunt.loadTasks('tasks/config');
    grunt.loadTasks('tasks');

    // By default, grunt will test then build the app
    grunt.registerTask('default', [
        'jshint',
        'test',
        'uglify:dist'
    ]);
};