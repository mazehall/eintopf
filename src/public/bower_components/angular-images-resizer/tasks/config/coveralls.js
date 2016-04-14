/**
 * Created by berthelot on 05/11/14.
 */
'use strict';

module.exports = function (grunt) {
    grunt.config.merge({
        coveralls: {
            options: {
                src: 'test/results/ouh.info',
                force: false
            },
            target: {
                // Target-specific LCOV coverage file
                src: 'test/**/*.info'
            }
        }
    });
};