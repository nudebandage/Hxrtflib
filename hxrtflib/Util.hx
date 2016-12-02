
package hxrtflib;

import hxrtflib.Hxrtflib.Style;

/**
  deep copy of anything
  see: http://old.haxe.org/forum/thread/3395#nabble-td2119917
 **/

class Util {
  public static function deepCopy<T>( v:T ) : T
  {
    if (!Reflect.isObject(v)) // simple type
    {
      return v;
    }
    else if( Std.is( v, Array ) ) // array
    {
      var r = Type.createInstance(Type.getClass(v), []);
      untyped
      {
    for( ii in 0...v.length )
      r.push(deepCopy(v[ii]));
      }
      return r;
    }
    else if( Type.getClass(v) == null ) // anonymous object
    {
      var obj : Dynamic = {};
    for( ff in Reflect.fields(v) )
      Reflect.setField(obj, ff, deepCopy(Reflect.field(v, ff)));
      return obj;
    }
    else // class
    {
      var obj = Type.createEmptyInstance(Type.getClass(v));
    for( ff in Reflect.fields(v) )
      Reflect.setField(obj, ff, deepCopy(Reflect.field(v, ff)));
      return obj;
    }
    return null;
  }


  // Do two maps have the same keys and values?
  public static function mapSame(map1:Style, map2:Style) : Bool {
    var keys1 = new Set();
    var keys2 = new Set();
    // fill the sets
    for (key in map1.keys()) {
      var value = map1.get(key);
      keys1.add({key:key, value:value});
    }
    for (key in map2.keys()) {
      var value = map2.get(key);
      keys2.add({key:key, value:value});
    }

    var added = keys1.minus(keys2);
    var removed = keys2.minus(keys1);
    if (added == 0 && removed == 0) {
      return true;
    }
    return false;
  }


  public static function unique_int(values:Dynamic) : Int {
    // if a list looks like [3, 6]
    // if repeatedly called will return 1,2,4,5,7,8
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
