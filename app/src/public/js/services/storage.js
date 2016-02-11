'use strict';

angular.module("eintopf.services.storage", [])
.factory("storage", [function () {

  var ioEvent = Kefir.pool();
  var streams = {};
  var storage = {};
  var factory = {

    /**
     * Returns the value of a specific key
     *
     * @param  {string} key
     * @return {factory}
     */
    get: function (key) {
      return storage[key] || null;
    },

    /**
     * Sets a key/value pair
     *
     * @param  {string} key
     * @param  {*} value
     * @return {factory}
     */
    set: function (key, value) {
      ioEvent.plug(Kefir.constant({name: key, value: value, type: "set"}));
      storage[key] = value;

      return this;
    },

    /**
     * Unset a given key
     *
     * @param  {string} key
     * @return {factory}
     */
    unset: function (key) {
      if (key && storage[key]) {
        delete(storage[key]);
        ioEvent.plug(Kefir.constant({name: key, type: "unset"}));
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
    add: function (key, value) {
      if (typeof storage[key] === "undefined") {
        storage[key] = [];
      }

      storage[key].push(value);
      ioEvent.plug(Kefir.constant({name: key, value: value, type: "add"}));

      return this;
    },

    /**
     * Notify subscribers of a given stream name
     *
     * @param  {string} name
     * @return {factory}
     */
    notify: function (name) {
      ioEvent.plug(Kefir.constant({name: name}));

      return this;
    },

    /**
     * Returns a Kefir stream
     *
     * @param  {string} [name=null]
     * @return {object}
     */
    stream: function (name) {
      var filter = name || ".";
      if (filter && streams[filter]) {
        return streams[filter];
      }

      streams[filter] = ioEvent
      .filter(function (store) {
        if (name && name === store.name || typeof name === "undefined") return true;
      })
      .map(function (store) {
        return factory.get(store.name);
      });

      return streams[filter];
    }
  };

  return factory;
}]);