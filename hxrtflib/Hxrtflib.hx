// The first insert into the text editor must happen at the beggining index
// The default tag will not get applied if this doesn't happen

package hxrtflib;

typedef Pos = {
  var row:Int;
  var col:Int;
}


class Globals {
  static public var DEFAULT_TAG : Int = 1;
  static public var START_ROW : Int = 1;
  static public var START_COL : Int = 0;
}


class Hxrtflib {
  public function new() {
  }

  public function setup(is_selected,
                        first_selected_index,
                        char_at_index,
                        tag_at_index,
                        tag_add,
                        last_col,
                        ignore_key) {
    _is_selected = is_selected;
    _first_selected_index = first_selected_index;
    _char_at_index = char_at_index;
    _tag_at_index = tag_at_index;
    _tag_add = tag_add;
    _last_col = last_col;
    _ignore_key = ignore_key;
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
    _tag_add(tag, row, col);
  }


  // public function style_toggle(name, args, kwargs) {
    // var pos:Pos = _char_at_index(
    // if (_is_selected()) {
      // change_style_selected(name, args, kwargs);
    // }
    // else {
      // change_style_not_selected(name, args, kwargs);
    // }
  // }


  // public function change_style_selected(name, args, kwargs) {
    // if (is_word_extremity) {
    // }
  // }

  public function is_word_extremity(row, col) {
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

