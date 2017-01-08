// The first insert into the text editor must happen at the beggining index
// The default tag will not get applied if this doesn't happen

// The tag is an id which represents a style

package hxrtflib;

import hxrtflib.Util;


typedef Pos = {
  var row:Int;
  var col:Int;
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


class Globals {
  static public var DEFAULT_TAG : Int = 0;
  static public var START_ROW : Int = 1;
  static public var START_COL : Int = 0;
  static public var NOTHING : Int = -1;
}


@:expose
class Hxrtflib {
  static var styles : Map<StyleId, Style> = new Map();
  var overide_style = Globals.NOTHING;
  static var consumers = new Array();

  public function new() {
    var map = new Style();
    styles.set(Globals.DEFAULT_TAG, map);
  }

  public function setup(is_selected,
                        first_selected_index,
                        char_at_index,
                        tag_at_index,
                        tag_add,
                        last_col,
                        ignore_key,
                        insert_cursor_get,
                        create_style,
                        modify_style,
                        sel_index_get) {
    _is_selected = is_selected;
    _first_selected_index = first_selected_index;
    _char_at_index = char_at_index;
    _tag_at_index = tag_at_index;
    _tag_add = tag_add;
    _last_col = last_col;
    _ignore_key = ignore_key;
    _insert_cursor_get = insert_cursor_get;
    _create_style = create_style;
    _modify_style = modify_style;
    _sel_index_get = sel_index_get;
  }

  dynamic function _is_selected(row, col) { return true; }
  dynamic function _first_selected_index(row, col) : Pos {
    var pos:Pos = {row:0, col:0};
    return pos;
  }
  dynamic function _char_at_index(row, col) { return ""; }
  dynamic function _tag_at_index(row, col) { return 0; }
  dynamic function _tag_add(tag, row, col) { return null; }
  dynamic function _last_col(row) { return 0; }
  dynamic function _ignore_key(event) { return false; }
  dynamic function _insert_cursor_get() : Pos {
    var pos:Pos = {row:0, col:0};
    return pos;
  }
  dynamic function _create_style(style_id) { return null; }
  dynamic function _modify_style(style_id, key, value) { return null; }
  dynamic function _sel_index_get(row, col) {
    var start:Pos = {row:0, col:0};
    var end:Pos = {row:0, col:0};
    var sel:Sel = {start:start, end:end};
    return sel;
  }

  // Adds a tag on insert, (the libraray must do the insert)
  public function on_char_insert(event, row, col) {
    // event, will be passed to ignored_key, use this
    // to decide if a char needs to be inserted
    if (_ignore_key(event)) {
      return;
    }
    else if (col == Globals.START_COL) {
      insert_when_cursor_at_start(row);
    }
    else if (_is_selected(row, col)) {
      insert_when_selected(row, col);
    }
    else {
      var tag = _tag_at_index(row, col-1);
      if (tag == Globals.NOTHING) {
        insert_when_no_tag(row, col);
      }
      else {
        tag_replace(tag, row, col);
      }
    }
  }


  public function on_mouse_click(row, col) {
    override_style_reset();
    consumer_run(row, col);
  }


  public function insert_when_cursor_at_start(row) {
    var tag : Int;
    var col = Globals.START_COL;
    var char_at_cur = _char_at_index(row, col);
    // Data exists after the cursor, so take that setting
    if (char_at_cur != "\n" && char_at_cur != "") {
      tag = _tag_at_index(row, col);
    }
    // Get tag from the previous line
    else {
      tag = _tag_at_index(row - 1, _last_col(row - 1));
    }

    if (tag == Globals.NOTHING) {
      insert_when_no_tag(row, col);
      return;
    }
    tag_replace(tag, row, Globals.START_COL);
  }

  // Allows us to insert charachters to arbitrary positions
  // And the tags will be applied properly
  function insert_when_no_tag(row, col) {
    var tag = Globals.DEFAULT_TAG;
    // Apply default tag to the inserted char
    tag_replace(tag, row, col);
    // Apply default tag to the NEXT char
    // This is important as amount of position a cursor can have
    // is charachters + 1;
    tag_replace(tag, row, col+1);
  }


  public function insert_when_selected(row:Int, col:Int) {
    var sel_pos:Pos = _first_selected_index(row, col);
    var tag = _tag_at_index(sel_pos.row, sel_pos.col);
    tag_replace(tag, sel_pos.row, sel_pos.col);
  }


  function tag_replace(tag:Int, row, col) {
    if (overide_style == Globals.NOTHING) {
      _tag_add(tag, row, col);
    }
    // Use the overide tag
    else {
      tag  = override_style_get();
      _tag_add(tag, row, col);
      override_style_reset();
    }
  }


  function override_style_reset() {
    overide_style = Globals.NOTHING;
  }


  function override_style_set(style) {
    overide_style = style;
  }


  public function override_style_get() {
    return overide_style;
  }


  public function style_change(change_key, change_value) {
    var cursor:Pos = _insert_cursor_get();
    if (_is_selected(cursor.row, cursor.col)) {
      style_with_selection(change_key, change_value, cursor);
    }
    else {
      style_no_selection(change_key, change_value, cursor);
    }
    consumer_run(cursor.row, cursor.col);
  }


  function style_no_selection(change_key, change_value, cursor) {
    if (is_word_extremity(cursor.row, cursor.col)) {
      style_word_extremity(change_key, change_value, cursor.row, cursor.col);
    }
    else {
      var left = word_start_get(cursor.row, cursor.col);
      var right = word_end_get(cursor.row, cursor.col);
      var start:Pos = {row: cursor.row, col: left};
      var end:Pos = {row: cursor.row, col: right};
      style_word_range(change_key, change_value, start, end);
    }
  }


  function style_with_selection(change_key, change_value, cursor) {
    var sel = _sel_index_get(cursor.row, cursor.col);
    style_word_range(change_key, change_value, sel.start, sel.end);
  }


  function style_word_range(change_key, change_value, start, end) {
    // apply style to every char based on its index
    // + 1 because we have to include the end index
    var _start_col, _end_col;
    for (r in start.row...end.row+1) {
      if (r == start.row) {
        _start_col = start.col;
      }
      else {
        _start_col = Globals.START_COL;
      }
      if (r == end.row) {
        _end_col = end.col;
      }
      else {
        _end_col = _last_col(r);
      }
      // + 1 because we have to include the end index
      for (c in _start_col..._end_col+1) {
        var style_id = style_from_change(change_key, change_value, r, c);
        tag_replace(style_id, r,  c);
      }
    }
  }


  function style_word_extremity(change_key, change_value, row, col) {
    // the next keypress should have a new style
    var style_id = style_from_change(change_key, change_value, row, col);
    override_style_set(style_id);
  }


  function style_from_change(change_key, change_value, row, col) : StyleId {
    // given a requested change return the new/existing style
    var se:StyleExists = style_exists(change_key, change_value, row, col);
    if (se.exists) {
      return se.style_id;
    }
    else {
      return style_new(se.style);
    }
  }


  public function style_exists(change_key, change_value, row, col) : StyleExists {
    // Returns a style to be used or created
    var style_id = _tag_at_index(row, col);
    var style_at_index:Style = styles.get(style_id);
    var remove:Bool;
    if (style_at_index == null) {
      remove = false;
    }
    else if (change_value == style_at_index.get(change_key)) {
      remove = true;
    }
    else {
      remove = false;
    }

    // Copy the style at the index
    var required_style = new Style();
    for (key in style_at_index.keys()) {
      var value = style_at_index.get(key);
      required_style.set(key, value);
    }

    // Build the required style
    if (remove) {
      required_style.remove(change_key);
    }
    else {
      required_style.set(change_key, change_value);
    }

    // Check if the style already exists
    var se = {exists:false, style_id:Globals.NOTHING, style:new Style()};
    se.exists = false;
    for (style_id in styles.keys()) {
      var style = styles.get(style_id);
      if (Util.mapSame(required_style, style)) {
        se.exists = true;
        se.style_id = style_id;
        break;
      }
    }
    if(!se.exists) {
      se.style = required_style;
    }
    return se;
  }


  public function style_new(style:Style) : StyleId {
    var style_id = style_id_make();
    _create_style(style_id);
    // Passing dict to targets doesn't map too cleanly, so...
    for (change_type in style.keys()) {
      var change_value = style.get(change_type);
      _modify_style(style_id, change_type, change_value);
    }
    styles[style_id] = style;
    return style_id;
  }


  public function style_id_make() : StyleId {
    return Util.unique_int([for (x in styles.keys()) x]);
  }


  public function word_start_get(row, col) {
    // row and col must be inside a word
    var i = col;
    while (true) {
      if (is_word_start(row, i)) {
        return i;
      }
      i--;
    }
  }


  public function word_end_get(row, col) {
    // row and col must be inside a word
    var i = col;
    while (true) {
      if (is_word_end(row, i)) {
        return i;
      }
      i++;
    }
  }


  public function is_word_extremity(row, col) : Bool {
    if (is_word_start(row, col)) {
      return true;
    }
    else if (is_word_end(row, col)) {
      return true;
    }
    return false;
  }


  function is_word_start(row, col) {
    if (col == Globals.START_COL) {
      return true;
    }
    // TODO indexs must become addable, +1/-1 for row and col
    var char_prev = _char_at_index(row, col-1);
    if (char_prev == ' ') {
      return true;
    }
    return false;
  }


  function is_word_end(row, col) {
    // TODO how to test for out of bounds... -1?
    // Need to specify this behvaior also for _char_at_index
    // TODO indexs must become addable, +1/-1 for row and col
    var char = _char_at_index(row, col);
    if (char != ' ' && char != '\n') {
      return false;
    }
    return true;
  }


  public function register_consumer(func) {
    consumers.push(func);
  }

  public function consumer_run(row, col) {
    // consumer functions must handle "reset"
    var style_id = _tag_at_index(row, col);
    var style = styles.get(style_id);
    for (func in consumers) {
      func("reset", "");
      for (style_type in style.keys()) {
        var value = style.get(style_type);
        func(style_type, value);
      }
    }
  }
}
