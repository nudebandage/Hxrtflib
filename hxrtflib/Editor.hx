
package hxrtflib;

import hxrtflib.Util;

typedef Row = Int;
typedef Col = Int;

typedef Pos = {
  var row:Row;
  var col:Col;
}

typedef Sel = {
  var end:Pos;
  var start:Pos;
}

typedef ChangeKey = String;
typedef ChangeValue = String;
typedef StyleId = Int;
typedef Style = Map<ChangeKey, ChangeValue>;
typedef Styles = Map<StyleId, Style>;


typedef StyleExists = {
  var exists:Bool;
  var style_id:StyleId;
  var style:Style;
}

typedef Event = String;

class Globals {
  static public var DEFAULT_TAG : Int = 0;
  static public var START_ROW : Int = 1;
  static public var START_COL : Int = 0;
  static public var NOTHING : Int = -1;
  static public var EOF = null; // FIXME, Breaks static languages - https://haxe.org/manual/types-nullability.html
}

interface EditorInterface {
  public var styles : Map<StyleId, Style>;
  public var override_style = Globals.NOTHING;

  public function is_selected(row:Row, col:Col):Bool;
  public function first_selected_index(row:Row, col:Col):Pos;
  public function char_at_index(row:Row, col:Col):String;
  public function tag_at_index(row:Row, col:Col):StyleId;
  public function tag_add(tag:StyleId, row:Row, col:Col):Void;
  public function last_col(row:Row):Col;
  public function ignore_key(event:Event):Bool;
  public function insert_cursor_get():Pos;
  public function create_style(style_id:StyleId):Void;
  public function modify_style(style_id:StyleId, key:ChangeKey, value:ChangeValue):Void;
  public function sel_index_get(row:Row, col:Col):Sel;
  public function move_key(event:Event):Bool;
}
