/**
 * Created by berthelot on 05/11/14.
 */
'use strict';

module.exports = function (grunt) {
    grunt.config.merge({
        karma: {
            unit: {
                configFile: './test/karma.conf.js',
                autoWatch: false,
                singleRun: true
            }
        }
    });
};