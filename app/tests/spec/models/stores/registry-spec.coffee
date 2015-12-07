'use strict';

rewire = require "rewire"

model = null
samples =
  watcherId: 'recommendations:list'
  recommendationsList:
    public: [
      {"name": "Sample public_1", "description": "desc Sample public_1"}
      {"name": "Sample public_2", "description": "desc Sample public_2"}
    ],
    private: [
      {"name": "Sample private_11", "description": "desc Sample private_11"}
      {"name": "Sample private_22", "description": "desc Sample private_22"}
    ]
  recommendationsListEmpty: public: [], private: []


describe "updateRegistryInstallFlags", ->

  beforeEach ->
    model = rewire "../../../../models/stores/registry.coffee"
    model.__set__ 'watcherModel',
      get: jasmine.createSpy('watcherModel.get').andCallFake -> samples.recommendationsList
      set: jasmine.createSpy('watcherModel.set').andCallFake ->
    spyOn(model, 'mapRegistryData').andCallFake (val) -> val

  it "should call watcherModel.set with the correct data", ->
    model.updateRegistryInstallFlags()
    expect(model.__get__('watcherModel').set).toHaveBeenCalledWith(samples.watcherId, samples.recommendationsList)

  it 'should call watcherModel.get with recommendations:list', ->
    model.updateRegistryInstallFlags()
    expect(model.__get__('watcherModel').get).toHaveBeenCalledWith(samples.watcherId)

  it 'should call mapRegistryData 2 times', ->
    model.updateRegistryInstallFlags()
    expect(model.mapRegistryData.callCount).toBe(2)

  it 'should call mapRegistryData with public data', ->
    model.updateRegistryInstallFlags()
    expect(model.mapRegistryData).toHaveBeenCalledWith(samples.recommendationsList.public)

  it 'should call mapRegistryData with private data', ->
    model.updateRegistryInstallFlags()
    expect(model.mapRegistryData).toHaveBeenCalledWith(samples.recommendationsList.private)

  it 'should call watcherModel.set with empty public/private array when recommendationsList data is empty', ->
    model.__get__('watcherModel.get').andCallFake -> null

    model.updateRegistryInstallFlags()
    expect(model.__get__('watcherModel').set).toHaveBeenCalledWith(samples.watcherId, samples.recommendationsListEmpty)
