
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

  public function _hx_is_selected(row:Row, col:Col):Bool;
  public function _hx_first_selected_index(row:Row, col:Col):Pos;
  public function _hx_char_at_index(row:Row, col:Col):String;
  public function _hx_tag_at_index(row:Row, col:Col):StyleId;
  public function _hx_tag_add(tag:StyleId, row:Row, col:Col):Void;
  public function _hx_last_col(row:Row):Col;
  public function _hx_ignore_key(event:Event):Bool;
  public function _hx_insert_cursor_get():Pos;
  public function _hx_create_style(style_id:StyleId):Void;
  public function _hx_modify_style(style_id:StyleId, key:ChangeKey, value:ChangeValue):Void;
  public function _hx_sel_index_get(row:Row, col:Col):Sel;
  public function _hx_move_key(event:Event):Bool;
}

@:expose
class BaseEditor {
  public var styles : Map<StyleId, Style>;
  public var override_style = Globals.NOTHING;
}
