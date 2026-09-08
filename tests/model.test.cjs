const { test } = require('node:test')
const assert = require('node:assert/strict')
const map = require('../MapModel.js')
const model = require('../Model.js')

test('map clicks round-trip city coordinates at different sizes', () => {
  for (const [width, height] of [[560, 330], [300, 330], [900, 600]]) {
    for (const city of map.cities) {
      const point = map.project(city.latitude, city.longitude, width, height)
      const location = map.unproject(point.x, point.y, width, height)
      assert.ok(Math.abs(location.latitude - city.latitude) < 0.00001)
      assert.ok(Math.abs(location.longitude - city.longitude) < 0.00001)
      assert.ok(model.inCoverage(location.latitude, location.longitude))
    }
  }
})

test('clicks outside map bounds cannot create a location', () => {
  assert.equal(map.unproject(0, 0, 560, 330), null)
  assert.equal(map.unproject(560, 330, 560, 330), null)
  assert.equal(map.unproject(10, 10, 0, 0), null)
})

test('saved selection rejects corrupt and out-of-coverage coordinates', () => {
  for (const text of ['', '{', 'null', '{}', '{"mode":"selected"}',
    '{"mode":"selected","location":{"latitude":90,"longitude":5}}',
    '{"mode":"selected","location":{"latitude":"bad","longitude":5}}']) {
    assert.equal(model.parseSelection(text), null)
  }
  const saved = {mode: 'selected', location: map.cities[0], settingsKey: '["","",""]'}
  const parsed = model.parseSelection(JSON.stringify(saved))
  assert.equal(parsed.location.name, 'Bruges')
  assert.equal(parsed.settingsKey, saved.settingsKey)
})

test('manual choice survives automatic lookup and automatic mode ignores old coordinate overrides', () => {
  const selected = map.cities[0], automatic = map.cities[1], configured = map.cities[2]
  assert.equal(model.forecastLocation({mode:'selected', location:selected}, configured, automatic), selected)
  assert.equal(model.forecastLocation({mode:'automatic'}, configured, automatic), automatic)
  assert.equal(model.forecastLocation(null, configured, automatic), configured)
  assert.equal(model.forecastLocation(null, null, automatic), automatic)
  assert.equal(model.forecastLocation({mode:'automatic'}, configured, null), null)
})

test('forecast request keys depend on coordinates rather than names', () => {
  assert.equal(model.locationKey({...map.cities[0], name:'Renamed'}), model.locationKey(map.cities[0]))
  assert.notEqual(model.locationKey(map.cities[0]), model.locationKey(map.cities[1]))
  assert.notEqual(model.locationKey(null), model.locationKey(map.cities[0]))
})
