// The first insert into the text editor must happen at the beggining index
// The default tag will not get applied if this doesn't happen

// The tag is an id which represents a style

package hxrtflib;

import hxrtflib.Util;


typedef Pos = {
  var row:Int;
  var col:Int;
}


typedef Change = Map<String, String>;
typedef StyleId = Int;
typedef Style = Map<String, String>;
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
}


class Hxrtflib {
  static var styles : Map<StyleId, Style> = new Map();
  var overide_style = -1;

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
                        create_style) {
    _is_selected = is_selected;
    _first_selected_index = first_selected_index;
    _char_at_index = char_at_index;
    _tag_at_index = tag_at_index;
    _tag_add = tag_add;
    _last_col = last_col;
    _ignore_key = ignore_key;
    _insert_cursor_get = insert_cursor_get;
    _create_style = create_style;
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
  dynamic function _create_style(tag, style) { return null; }

  public function insert_char(event, row, col) {
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
      var tag = _tag_at_index(row, col - 1);
      tag_replace(tag, row, col);
    }
  }


  public function insert_when_cursor_at_start(row) {
    var tag : Int;
    var char_at_right = _char_at_index(row, Globals.START_COL+1);
    // Data exists after the cursour, so take that setting
    if (char_at_right != "\n" && char_at_right != "") {
      tag = _tag_at_index(row, Globals.START_COL + 1);
    }
    else if (row == Globals.START_ROW) {
      var col = _last_col(row);
      // Empty editor
      if (col == Globals.START_COL) {
        tag = Globals.DEFAULT_TAG;
      }
      else {
        tag = _tag_at_index(row, _last_col(row));
      }
    }
    // Get tag from the previous line
    else {
      tag = _tag_at_index(row - 1, _last_col(row));
    }
    tag_replace(tag, row, Globals.START_COL);
  }


  public function insert_when_selected(row:Int, col:Int) {
    var sel_pos:Pos = _first_selected_index(row, col);
    var tag = _tag_at_index(sel_pos.row, sel_pos.col);
    tag_replace(tag, sel_pos.row, sel_pos.col);
  }


  function tag_replace(tag:Int, row, col) {
    if (overide_style == -1) {
      _tag_add(tag, row, col);
    }
    // Use the overide tag
    else {
      tag  = override_tag_get();
      _tag_add(tag, row, col);
      override_style_reset();
    }
  }


  function  override_style_reset() {
    overide_style = -1;
  }


  function override_style_set(style) {
    overide_style = style;
  }


  function override_tag_get() {
    return overide_style;
  }


  public function style_change(change) {
    var cursor:Pos = _insert_cursor_get();
    if (_is_selected(cursor.row, cursor.col)) {
      // style_with_selection(change, cursor);
    }
    else {
      style_no_selection(change, cursor);
    }
  }


  function style_no_selection(change, cursor) {
    if (is_word_extremity(cursor.row, cursor.col)) {
      // style_word_extremity(change, cursor.row, cursor.col);
    }
    else {
      style_word(change, cursor.row, cursor.col);
    }
  }

  function style_with_selection(change, cursor) {
    // apply style to selection
  }


  function style_word(change, row, col) {
    var word_start = word_start_get(row, col);
    var word_end = word_end_get(row, col);

    // apply style to every char based on its index
    var style_id;
    for (i in word_start...word_end) {
      style_id = style_from_change(change, row, i);
      tag_replace(style_id, row,  i);
    }
  }


  function style_word_extremity(change, row, col) {
    // the next keypress should have a new style
    var style_id = style_from_change(change, row, col);
    override_style_set(style_id);
  }


  function style_from_change(change, row, col) : StyleId {
    // given a requested change return the new/existing style
    var se:StyleExists = style_exists(change, row, col);
    if (se.exists)
    {
      return se.style_id;
    }
    else {
      return style_new(se.style);
    }
  }


  public function style_exists(change:Change, row, col) : StyleExists {
    // Returns a style to be used or created
    var tag = _tag_at_index(row, col);
    var style_at_cursor:Style = styles.get(tag);
    var remove:Bool;
    var change_type = change.keys().next();
    var change_value = change.get(change_type);
    if (style_at_cursor == null) {
      remove = false;
    }
    else if (change_value == style_at_cursor.get(change_type)) {
      remove = true;
    }
    else {
      remove = false;
    }

    // Copy the style at the cursor
    var required_style = new Style();
    for (key in style_at_cursor.keys()) {
      var value = style_at_cursor.get(key);
      required_style.set(key, value);
    }

    // Build the required style
    if (remove) {
      required_style.remove(change_type);
    }
    else {
      // var se = {exists:false, style_id:-1, style:new Style()};
      // return se;
      required_style.set(change_type, change_value);
    }

    // Check if the style already exists
    var se = {exists:false, style_id:-1, style:new Style()};
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


  public function style_new(style) : StyleId {
    var style_id = style_id_make();
    _create_style(style_id, style);
    styles[style_id] = style;
    return style_id;
  }


  // public style_modify(style_id, change) {
    // styles[style_id].set(
  // }


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
    var char_next = _char_at_index(row, col+1);
    if (char_next != ' ' && char_next != '\n') {
      return false;
    }
    return true;
  }
}
