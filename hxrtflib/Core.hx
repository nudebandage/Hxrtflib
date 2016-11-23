package hxrtflib;

class Globals {
  static public var DEFAULT_TAG : Int = 0;
  static public var START_ROW : Int = 1;
  static public var START_COL : Int = 0;
  static public var END_COL : Int = -1;
}


class Core {
  public function new() {
  }

  public function setup(is_selected,
                         char_at_index,
                         tag_at_index,
                         tag_add,
                         last_col,
                         ?ignore_char) {
    _is_selected = is_selected;
    _char_at_index = char_at_index;
    _tag_at_index = tag_at_index;
    _tag_add = tag_add;
    _last_col = last_col;
    _ignore_char = ignore_char;
  }

  dynamic function _is_selected(index, char) { return true; }
  dynamic function _char_at_index(index, char) { return ""; }
  dynamic function _tag_at_index(index, char) { return 0; }
  dynamic function _tag_add(current_tag, row, col) { return null; }
  dynamic function _last_col(row) { return 0; }
  dynamic function _ignore_char(index, char) { return true; }
  /*
  public function insert_char(row, col) : Bool {
    var index = _tag_at_index(row, col);
    if (_ingore_char(char)) {
      return false;
    }

    if (is_first_col(row, col)) {
      current_tag = insert_when_cursor_at_start();
    }
    if (_is_selected(index)) {
      current_tag = insert_when_selected();
    }
    tag_add(current_tag);
  }
  */

  public function insert_when_cursor_at_start(row) {
    var tag : Int;
    var char_at_right = _char_at_index(row, Globals.START_COL);
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

  function tag_replace(tag:Int, row, col) {
    _tag_add(tag, row, col);
  }
}

