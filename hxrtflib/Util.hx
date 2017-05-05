
package hxrtflib;

import hxrtflib.Editor.Style;


class Util {
  // Do two maps have the same keys and values?
  public static function mapSame(map1:Style, map2:Style) : Bool {
    var keys1 = new Set();
    var keys2 = new Set();
    // fill the sets
    for (key in map1.keys()) {
      var value = map1.get(key);
      keys1.add(key + value);
    }
    for (key in map2.keys()) {
      var value = map2.get(key);
      keys2.add(key + value);
    }

    // var added = keys1.minus(keys2);
    // var removed = keys2.minus(keys1);
    // var intersect_keys = keys1.intersection(keys2);
    if (keys1.equals(keys2)) {
      return true;
    }
    return false;
  }


  // Takes a function that must return an iterator
  // if a list looks like [3, 6]
  // if repeatedly called will return 1,2,4,5,7,8
  public static function unique_int(values:Dynamic) : Int {
    var last = 0;
    while (true) {
      var matches = Lambda.filter(values, function(num) {return (num == last);});
      if (matches.length == 0) {
        break;
      }
      last++;
    }
    return last;
  }
}
