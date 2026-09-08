import QtQuick
import QtTest
import ".." as Rain
import "../MapModel.js" as MapModel

Item {
  width: 560; height: 330
  Rain.LocationMap {
    id: map
    anchors.fill: parent
    onLocationPicked: function(location) { selectedLocation = location }
  }
  SignalSpy { id: picks; target: map; signalName: "locationPicked" }
  TestCase {
    name: "LocationMap"
    when: windowShown
    function init() { picks.clear(); map.selectedLocation = null }
    function test_mapClick() {
      var point = MapModel.project(50.0, 5.8, map.width, map.height)
      var x = Math.round(point.x), y = Math.round(point.y)
      var expected = MapModel.unproject(x, y, map.width, map.height)
      mouseClick(map, x, y)
      compare(picks.count, 1)
      fuzzyCompare(map.selectedLocation.latitude, expected.latitude, 0.00001)
      fuzzyCompare(map.selectedLocation.longitude, expected.longitude, 0.00001)
    }
    function test_cityLabel() {
      var city = MapModel.cities[7] // Amsterdam
      var point = MapModel.project(city.latitude, city.longitude, map.width, map.height)
      mouseClick(map, point.x - 25, point.y - 12)
      compare(picks.count, 1)
      compare(map.selectedLocation.name, "Amsterdam")
      compare(map.selectedLocation.latitude, city.latitude)
    }
    function test_outsideBounds() {
      mouseClick(map, 2, 2)
      compare(picks.count, 0)
    }
    function test_keyboardNudge() {
      map.selectedLocation = {name:"Brussels", latitude:50.8503, longitude:4.3517}
      map.forceActiveFocus()
      keyClick(Qt.Key_Right)
      compare(picks.count, 1)
      fuzzyCompare(map.selectedLocation.longitude, 4.4017, 0.00001)
      fuzzyCompare(map.selectedLocation.latitude, 50.8503, 0.00001)
    }
  }
}
