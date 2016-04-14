/**
 * Created by berthelot on 03/11/14.
 */
/* globals FileError: false; */
'use strict';

angular.module('images-resizer')
    .service('readLocalPicService', ['$q', function($q) {

        /**
         * Read file input and convert it into base64 file
         * @param input
         * @returns {*}
         */
        this.readFileInput = function(input) {
            var deferred = $q.defer();

            if (!input.files || !input.files[0]) {
                deferred.reject('No file selected');
            }
            else {
                if (!(window.File && window.FileReader && window.FileList && window.Blob)) {
                    deferred.reject('Your browser do not support reading file');
                }

                var reader = new FileReader();
                reader.onload = function (e) {
                    deferred.resolve(e.target.result);
                };
                reader.onabort = function(e) {
                    deferred.reject('Fail to convert file in base64img, aborded: '+ eventErrorDecoder(e));
                };
                reader.onerror = function(e) {
                    deferred.reject('Fail to convert file in base64img, error: '+ eventErrorDecoder(e));
                };

                reader.readAsDataURL(input.files[0]);
            }

            return deferred.promise;
        };

        /**
         * Decode Error of a file reader
         * @param event
         * @returns {*}
         */
        function eventErrorDecoder (event) {
            var errorMessage = null;

            switch(event.target.error.code) {
                case FileError.NOT_FOUND_ERR:
                    errorMessage = 'NOT_FOUND_ERR';
                    break;
                case FileError.SECURITY_ERR:
                    errorMessage = 'SECURITY_ERR';
                    break;
                case FileError.ABORT_ERR:
                    errorMessage = 'ABORT_ERR';
                    break;
                case FileError.NOT_READABLE_ERR:
                    errorMessage = 'NOT_READABLE_ERR';
                    break;
                case FileError.ENCODING_ERR:
                    errorMessage = 'ENCODING_ERR';
                    break;
                case FileError.NO_MODIFICATION_ALLOWED_ERR:
                    errorMessage = 'NO_MODIFICATION_ALLOWED_ERR';
                    break;
                case FileError.INVALID_STATE_ERR:
                    errorMessage = 'INVALID_STATE_ERR';
                    break;
                case FileError.SYNTAX_ERR:
                    errorMessage = 'SYNTAX_ERR';
                    break;
                case FileError.INVALID_MODIFICATION_ERR:
                    errorMessage = 'INVALID_MODIFICATION_ERR';
                    break;
                case FileError.QUOTA_EXCEEDED_ERR:
                    errorMessage = 'QUOTA_EXCEEDED_ERR';
                    break;
                case FileError.TYPE_MISMATCH_ERR:
                    errorMessage = 'TYPE_MISMATCH_ERR';
                    break;
                case FileError.PATH_EXISTS_ERR:
                    errorMessage = 'PATH_EXISTS_ERR';
                    break;
                default:
                    errorMessage = 'Unknown Error: ' + event.target.error.code;
                    break;
            }
            return errorMessage;
        }
    }]);