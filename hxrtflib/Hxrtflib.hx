// The first insert into the text editor must happen at the beggining index
// The default tag will not get applied if this doesn't happen

// The tag is an id which represents a style

// override_style is state used to determine if the next char
// being inserted should take the last chars style (default)
// or use some other style.

// Note:
// A word with 3 letters has 4 cursor positions. We consider
// cursor positions and pass them around the program.
// Word "abc" can be detcted when the cursor is at 1.0 and 1.4,
// but to read the tags or chars you need to use 1.0 to 1.3
// So we use _index, to refer to the "cursor" and _T_index to automaticlaly handle this conversion for us

package hxrtflib;

import hxrtflib.Util;
import hxrtflib.Assert;


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
  public var styles : Map<StyleId, Style> = new Map();
  var override_style = Globals.NOTHING;
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
    __tag_at_index = tag_at_index;
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
  dynamic function __tag_at_index(row, col) { return 0; }
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

  // if a text editor has 5 chars -> 12345
  // There are 6 possiblle cursor locations
  // The last position has no tag, so we read
  // from the previous one..
  function _tag_at_index(row, col) {
    var tag = __tag_at_index(row, col);
    if (tag == Globals.NOTHING) {
      // TODO read from previous row
      if (col != Globals.START_COL) {
        tag = __tag_at_index(row, col -1);
      }
    }
    return tag;
  }

  function _tag_at_T_index(row, col) {
    var tag;
    if (col != Globals.START_COL) {
      tag = __tag_at_index(row, col-1);
    }
    else {
      tag = __tag_at_index(row, col);
    }
    return tag;
  }

  // Adds a tag on insert, (the libraray must do the insert)
  public function on_char_insert(event, row, col) {
    // event, will be passed to ignored_key, use this
    // to decide if a char needs to be inserted
    if (_ignore_key(event)) {
      return;
    }

    var override_style = override_style_get();
    if (override_style != Globals.NOTHING) {
      tag_set_override(override_style, row, col);
      override_style_reset();
      return;
    }
    else if (col == Globals.START_COL) {
      insert_when_cursor_at_start(row);
    }
    else if (_is_selected(row, col)) {
      insert_when_selected(row, col);
    }
    else {
      var tag = _tag_at_T_index(row, col);
      // FIXME THIS STATE HSOULD NEVER BE REACHED.. - should be sset in  inset when cursor at start
      if (tag == Globals.NOTHING) {
        insert_when_no_tag(row, col);
      }
      else {
        tag_set(tag, row, col);
      }
    }
  }


  // Note, row and col must be of the final position, care of event loop
  public function on_mouse_click(row, col) {
    override_style_reset();
    consumer_run(row, col);
  }


  public function insert_when_cursor_at_start(row) {
    var col = Globals.START_COL;
    var char_at_cur = _char_at_index(row, col);
    var tag = _tag_at_index(row, col);

    if (char_at_cur == "\n"
        || char_at_cur == "") {
        if (row == Globals.START_ROW) {
          // First insert into empty editor
          if (tag == Globals.NOTHING) {
            insert_when_no_tag(row, col);
            return;
          }
          // Existing tag at 1.0
          tag_set(tag, row, Globals.START_COL);
        }
        // Get tag from the previous line
        else {
          tag = _tag_at_index(row - 1, _last_col(row - 1));
          tag_set(tag, row, Globals.START_COL);
        }
      }
  }


  // TODO look at how tags get read.. seems funky

  // Allows us to insert charachters to arbitrary positions
  // And the tags will be applied properly
  function insert_when_no_tag(row, col) {
    var tag = Globals.DEFAULT_TAG;
    // Apply default tag to the inserted char
    tag_set(tag, row, col);
    // Apply default tag to the NEXT char
    // This is important as amount of position a cursor can have
    // is charachters + 1;
    // tag_set(tag, row, col+1);
  }


  public function insert_when_selected(row:Int, col:Int) {
    var sel_pos:Pos = _first_selected_index(row, col);
    var tag = _tag_at_index(sel_pos.row, sel_pos.col);
    tag_set(tag, sel_pos.row, sel_pos.col);
  }


  function tag_set_override(tag:Int, row, col) {
    if (override_style_get() == Globals.NOTHING) {
      _tag_add(tag, row, col);
    }
    // Use the override tag
    else {
      _tag_add(override_style_get(), row, col);
      override_style_reset();
    }
  }

  // set the tag
  function tag_set(tag:Int, row, col) {
    Assert.assert(override_style_get() == Globals.NOTHING);
    _tag_add(tag, row, col);
  }


  function override_style_reset() {
    override_style = Globals.NOTHING;
  }


  function override_style_set(style) {
    override_style = style;
  }


  public function override_style_get() {
    return override_style;
  }


  // Apply a Style change to the current curosor position
  public function style_change(change_key, change_value) {
    var cursor:Pos = _insert_cursor_get();
    // Style some selection
    if (_is_selected(cursor.row, cursor.col)) {
      Assert.assert(override_style_get() == Globals.NOTHING);
      style_with_selection(change_key, change_value, cursor);
    }
    // Either apply style or set the override style
    else {
      style_no_selection(change_key, change_value, cursor);
    }
    consumer_run(cursor.row, cursor.col);
  }

  function style_no_selection(change_key, change_value, cursor) {
    var style_id;
    // Style when cursor at extremity
    if (is_word_extremity(cursor.row, cursor.col)) {
      style_id = style_from_change(change_key, change_value, cursor.row, cursor.col);

      // Set The override_style
      if (override_style_get() == Globals.NOTHING) {
        override_style_set(style_id);
      }
      // Reset the override_style
      else {
        override_style_reset();
      }

    }
    // Style when cursor in middle of a word
    else {
      // TODO delete this.. Any cursor move should invalidate the override_style - /rename override_style to extrimty_override
      override_style_reset();

      var left = word_start_get(cursor.row, cursor.col);
      var right = word_end_get(cursor.row, cursor.col);
      // FIXME this isn't true..
      var start:Pos = {row: cursor.row, col: left};
      // FIXME this isn't true
      var end:Pos = {row: cursor.row, col: right};
      style_word_range(change_key, change_value, start, end);
    }

  }

  // Style a word when it is selected
  function style_with_selection(change_key, change_value, cursor) {
    var sel = _sel_index_get(cursor.row, cursor.col);
    style_word_range_sel(change_key, change_value, sel.start, sel.end);
  }


  function style_word_range(change_key, change_value, start, end) : StyleId {
    // apply style to every char based on the style at cursor
    // + 1 because we have to include the end index
    var style_id;
    var cursor:Pos = _insert_cursor_get();
    style_id = style_from_change(change_key, change_value,
                                 cursor.row, cursor.col);

    // TODO extract a metod to iterate positions
    var _start_col, _end_col;
    for (r in start.row...end.row+1) {
      // Set the iteration indexes
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
        tag_set(style_id, r,  c);
      }
    }
    return style_id;
  }

  function style_word_range_sel(change_key, change_value, start, end) {
    // apply style to every char based on the style at cursor
    // + 1 because we have to include the end index
    var style_id;

    // TODO extract a metod to iterate positions
    var _start_col, _end_col;
    for (r in start.row...end.row+1) {
      // Set the iteration indexes
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
        style_id = style_from_change(change_key, change_value, r, c);
        tag_set(style_id, r,  c);
      }
    }
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
    // Detects weather a change will require a new style to be made
    // FIXME implicitly relies on override_style

    // The style we will add or remove our change from
    var base_style_id;
    if (override_style_get() != Globals.NOTHING) {
      base_style_id = override_style_get();
    }
    else {
      base_style_id = _tag_at_T_index(row, col);
      Assert.assert(base_style_id != Globals.NOTHING);
    }

    Assert.assert(styles.exists(base_style_id));
    var base_style:Style = styles.get(base_style_id);
    // remove or add the change to the position?
    var remove:Bool;
    // The map is empty
    if (base_style == null) {
      remove = false;
    }
    else if (change_value == base_style.get(change_key)) {
      remove = true;
    }
    else {
      remove = false;
    }

    var required_style = new Style();
    // Make a copy of the base style
    if (base_style != null) {
      for (key in base_style.keys()) {
        var value = base_style.get(key);
        required_style.set(key, value);
      }
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


  // Test if the cursor position encompasses a word
  // see module doc for more info
  public function word_start_get(row, col) {
    // row and col must be inside a word
    // TODO go up rows...
    var i = col;
    while (true) {
      if (is_word_start(row, i)) {
        return i;
      }
      i--;
    }
  }


  // Test if the cursor position encompasses a word
  // see module doc for more info
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


  // Test if the cursor position encompasses a word
  // see module doc for more info
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


  // Test if the cursor position encompasses a word
  // see module doc for more info
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


  // Register a function to recieve notifications
  // This is used so clients can update UI widgets when styles change
  // the string "reset" is sent before each change, Toggleable buttons should be set to "off" and non toggelable options left alone
  // The consumer function must have signature (key, value)
  public function register_consumer(func) {
    consumers.push(func);
  }

  public function consumer_run(row, col) {
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
