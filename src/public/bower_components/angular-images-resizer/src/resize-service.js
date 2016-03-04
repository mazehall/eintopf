/**
 * Created by berthelot on 03/11/14.
 * Based on https://github.com/nicam/js-resize/blob/master/resize.js
 */
'use strict';

angular.module('images-resizer')
    .service('resizeService', ['$q', function($q) {

        var mainCanvas;
        var _this = this;

        var isCanvasSupported = !!(document.createElement('canvas').getContext && document.createElement('canvas').getContext('2d'));


        /**
         * Creates a new image object from the src attributes
         * @param src string src attribute of an img element
         * @returns promise
         */
        this.createImage = function (src) {
            var deferred = $q.defer();
            var img = new Image();

            img.onload = function() {
                deferred.resolve(img);
            };
            img.onabort = function() {
                deferred.reject('image was aborded');
            };
            img.onerror = function(err) {
                deferred.reject(err);
            };

            img.src = src;

            return deferred.promise;
        };

        this.resizeCanvas = function (cnv, width, height) {
            if(!width || !height) { return cnv; }

            var tmpCanvas = document.createElement('canvas');
            tmpCanvas.width = width;
            tmpCanvas.height = height;
            var cnx = tmpCanvas.getContext('2d');
            cnx.drawImage(cnv, 0, 0, tmpCanvas.width, tmpCanvas.height);
            return tmpCanvas;
        };

        /**
         * Resize an image with a given src attribute
         * @param src string src attribute of an img element
         * @param options json contain all options to resize an image (see all options available directly in th code below)
         * @param cb function callback of the function
         */
        this.resizeImage = function(src, options, cb) {
            //if no callback is specified or canvas is not supported
            if(!isCanvasSupported) {
                cb('Canvas is not supported on your browser', null);
                return;
            }
            if(!cb || !options || !src) {
                cb('Missing argument when calling resizeImage function', null);
                return;
            }

            options = {
                height: options.height ? options.height : options.width ? null: options.size ? null: 1024,
                width: options.width ? options.width : options.height ? null: options.size ? null: 1024,
                size: options.size ? options.size : 500,
                sizeScale: options.sizeScale ? options.sizeScale : 'ko',
                step: options.step ? options.step : 3,
                outputFormat: options.outputFormat ? options.outputFormat : 'image/jpeg'
            };

            _this.createImage(src).then(
                function(img) {
                    if (options.height || options.width) {
                        _this.createImage(src).then(
                            function (img) {
                                cb(null, _this.resizeImageWidthHeight(img, options.width, options.height , options.step, options.outputFormat));
                            },
                            function (err) {
                                cb(err, null);
                            }
                        );
                    }
                    else if (options.size) {
                        //conversion of the size in bytes
                        if (typeof options.sizeScale === 'string') {
                            switch (options.sizeScale.toLowerCase()) {
                                case 'ko':
                                    options.size *= 1024;
                                    break;
                                case 'mo':
                                    options.size *= 1024 * 1024;
                                    break;
                                case 'go':
                                    options.size *= 1024 * 1024 * 1024;
                                    break;
                            }
                        }
                        cb(null, _this.resizeImageBySize(img, options.size, options.outputFormat));
                    }
                },
                function(err) {
                    cb(err, null);
                });
        };

        /**
         * Resize image according to the width or the height or both
         * @param image DomImage html image to resize
         * @param width integer desired final image width
         * @param height integer desired final image height
         * @param step integer the number of step to finally have the image to the desired size
         * @param outputFormat string the format of the output file for exemple image/jpeg, image/png,...
         * @returns resized image
         */
        this.resizeImageWidthHeight = function(image, width, height, step, outputFormat) {
            if(!image) { return null; }
            if(!outputFormat) { outputFormat = 'image/jpeg'; }

            mainCanvas = document.createElement('canvas');

            //Check what width and height the resized image must to be !
            if(!width && ! height){
                width = image.width;
                height = image.height;
            }
            else if(!width && height) {
                width = (height / image.height) * image.width;
            }
            else if(width && !height){
                height = (width/ image.width) * image.height;
            }

            var pixelStepWidth = (image.width === width) || !step ? 0 : (image.width - width)/step;
            var pixelStepHeight = (image.height === height) || !step ? 0 : (image.height - height)/step;
            mainCanvas.width = image.width;
            mainCanvas.height = image.height;

            mainCanvas.getContext('2d').drawImage(image, 0, 0, mainCanvas.width , mainCanvas.height);
            for(var i=1; i<step; i++){
                var newWidth = image.width - (pixelStepWidth * i);
                var newHeight = image.height- (pixelStepHeight * i);
                mainCanvas = this.resizeCanvas(mainCanvas, newWidth, newHeight);
            }
            mainCanvas = this.resizeCanvas(mainCanvas, width, height);

            return mainCanvas.toDataURL(outputFormat);
        };

        /**
         * Resize image to the approximately absolute size in octet
         * @param image htmlImage the miage to resize
         * @param size number the final size in octet
         * @param outputFormat string the format of the output file for exemple image/jpeg, image/png,...
         * @returns resize image in base64
         */
        this.resizeImageBySize = function (image, size, outputFormat) {
            if(!image) { return null; }
            if(!outputFormat) { outputFormat = 'image/jpeg'; }

            mainCanvas = document.createElement('canvas');
            mainCanvas.width = image.width;
            mainCanvas.height = image.height;

            mainCanvas.getContext('2d').drawImage(image, 0, 0, mainCanvas.width, mainCanvas.height);
            var tmpResult = mainCanvas.toDataURL(outputFormat);
            var result = tmpResult;

            var sizeOfTheImage =  _this.calulateImageSize(tmpResult, outputFormat);
            var divideStrategy =  sizeOfTheImage / (size * 2) <= 1 ? 0.9 :  sizeOfTheImage / (size * 2.3);

            while (sizeOfTheImage > size) {
                var canvas = document.createElement('canvas');
                canvas.width = mainCanvas.width / divideStrategy;
                canvas.height = mainCanvas.height / divideStrategy;

                canvas.getContext('2d').drawImage(mainCanvas, 0, 0, canvas.width, canvas.height);
                tmpResult = mainCanvas.toDataURL(outputFormat);
                var sizeOfTheImageTmp = _this.calulateImageSize(tmpResult, outputFormat);

                if(sizeOfTheImageTmp/size < 0.5) {
                    divideStrategy =  sizeOfTheImage / (size * 2) <= 1 ? 0.9 :  sizeOfTheImage / (size * 2.3);
                }
                else {
                    mainCanvas = canvas;
                    result = tmpResult;
                    sizeOfTheImage = _this.calulateImageSize(tmpResult, outputFormat);
                }

                mainCanvas =  canvas;
            }
            return result;
        };

        /**
         * Return the size of the img by given the base64 img strings.
         * @param imgString String base64 image
         * @param outputFormat string the format of the output file for exemple image/jpeg, image/png,...
         * @returns number size of the img
         */
        this.calulateImageSize = function(imgString, outputFormat) {
            switch(outputFormat) {
                case 'image/jpeg':
                    outputFormat = 'image/jpg';
                    break;
                default :
                    outputFormat = 'image/jpg';
                    break;
            }
            return Math.round((imgString.length - ('data:'+ outputFormat +';base64,').length)* 3/4);
        };

    }]);