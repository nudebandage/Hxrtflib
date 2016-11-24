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
}

