'use strict';

angular.module("eintopf.services.storage", []).factory("storage", ["socket", function(socket){

    var ioEvent = socket.io.connect("/eintopf.services.storage");
    var storage = {};
    var factory = {

        /**
         * Returns the value of a specific key
         *
         * @param  {string} key
         * @return {factory}
         */
        get: function(key)
        {
            return storage[key] || null;
        },

        /**
         * Sets a key/value pair
         *
         * @param  {string} key
         * @param  {*} value
         * @return {factory}
         */
        set: function(key, value)
        {
            ioEvent.emit("storage:updated", {name: key, value: value, type: "set"});
            storage[key] = value;

            return this;
        },

        /**
         * Unset a given key
         *
         * @param  {string} key
         * @return {factory}
         */
        unset: function(key)
        {
            if (key && storage[key]){
                delete(storage[key]);
                ioEvent.emit("storage:updated", {name: key, type: "unset"});
            }

            return this;
        },

        /**
         * Appends a new value of a specific key
         *
         * @param  {string} key
         * @param  {*} value
         * @return {factory}
         */
        add: function(key, value)
        {
            if (typeof storage[key] === "undefined"){
                storage[key] = [];
            }

            storage[key].push(value);
            ioEvent.emit("storage:updated", {name: key, value: value, type: "add"});

            return this;
        },

        /**
         * Returns a Kefir stream
         *
         * @param  {string} [name=null]
         * @return {object}
         */
        stream: function(name)
        {
            return Kefir.fromBinder(function(emitter){
                ioEvent.on("storage:updated", function(store){
                    if (name && name === store.name || typeof name === "undefined"){
                        emitter.emit(factory.get(store.name));
                    }
                });
            });
        }
    };

    return factory;
}]);