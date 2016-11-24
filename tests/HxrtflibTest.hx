import hxrtflib.Hxrtflib;


typedef Cell = {
  var text : String;
  var selected : Bool;
  var tag : Int;
}


// Dummy implementations of text editor
class Editor {
  public var cells : Map<String, Cell> = new Map();
  var max_rows = 10;
  var max_cols = 10;

  public function new() {
  }
  public dynamic function is_selected(row, col) : Bool {
    var key = index_to_key(row, col);
    if (cells.get(key).selected) {
      return true;
    }
    return false;
  }

  public dynamic function first_selected_index(row, col) {
    // The inital index MUST be selected
    // fails if the first selece is on a new row and the first column..
    var exit = false;
    while (row >= Globals.START_ROW && !exit) {
      while (col >= Globals.START_COL) {
        if (!sel_at_index(row, col)) {
          col += 1;
          exit = true;
          break;
        }
        col--;
      }
    row--;
    col = parse_end_col(row);
    }
    return {row:row, col:col};

  }

  public dynamic function sel_at_index(row, col) : Bool {
    var key = index_to_key(row, col);
    return cells.get(key).selected;
  }

  public dynamic function char_at_index(row, col) : String {
    var key = index_to_key(row, col);
    return cells.get(key).text;
  }

  public dynamic function tag_at_index(row:Int, col:Int) : Int {
    var key = index_to_key(row, col);
    return cells.get(key).tag;
  }

  public dynamic function tag_add(tag, row, col) : Void {
    var key = index_to_key(row, col);
    var cell = cells.get(key);
    cell.tag = tag;
    cells.set(key, cell);
  }

  public dynamic function last_col(row : Int) {
    return parse_end_col(row);
  }

  public dynamic function ignore_key(event) {
    if (event == 'space') {
      return true;
    }
    return false;
  }

  public function fill(?char:String="", ?selected:Bool=false, ?tag:Int=-1) {
    // Fill the text editor with the char
    var cell:Cell;
    var key:String;
    for (i in 0...max_rows) {
      for (j in 0...max_cols) {
        key = index_to_key(i, j);
        cell = {text:char, selected:selected, tag:tag};
        cells.set(key, cell);
      }
    }
  }

  public function index_to_key(row:Int, col:Int) : String {
    return (row + "." + col);
  }

  function parse_end_col(row) : Int {
    // find the end of the last line
    var col = Globals.START_COL;
    var char;
    var key;
    var j = max_cols - 1;
    while (j >= 0) {
      key = index_to_key(row, j);

      char = cells.get(key).text;
      if (char != "") {
        col = j;
        break;
      }
      j--;
   }
  return col;
  }

  public function set_cell(row, col, ?char="", ?selected:Bool=false, ?tag:Int=-1) {
    var key = index_to_key(row, col);
    var cell = cells.get(key);
    cell.text = char;
    cell.selected = selected;
    cell.tag = tag;
    cells.set(key, cell);
  }
}

class HxrtflibTester extends haxe.unit.TestCase {
  var editor : Editor;
  var core : Hxrtflib;

  override public function setup() {
    editor = new Editor();
    editor.fill("");
    core = new Hxrtflib();
    core.setup(editor.is_selected,
               editor.first_selected_index,
               editor.char_at_index,
               editor.tag_at_index,
               editor.tag_add,
               editor.last_col,
               editor.ignore_key);
  }
}


class TestWhenCursorAtStart extends HxrtflibTester {
  public function test_insert_blank_editor() {
    var row = Globals.START_ROW;
    core.insert_when_cursor_at_start(row);
    var result = editor.tag_at_index(row, Globals.START_COL);
    assertEquals(Globals.DEFAULT_TAG, result);
  }

  public function test_second_row_when_nothing_at_right() {
    // tag from the previous row should be used when on a new line
    var row = 2;
    var col = Globals.START_COL;
    var tag = 2;
    editor.set_cell(row - 1, col, "a", tag);
    core.insert_when_cursor_at_start(row);
    var result = editor.tag_at_index(row, Globals.START_COL);
    assertEquals(tag, result);
  }

  public function test_second_row_when_char_at_right() {
    // tag to the right should be used
    var row = 2;
    var col = Globals.START_COL;
    var tag = 2;
    editor.set_cell(row, col + 1, "a", tag);
    core.insert_when_cursor_at_start(row);
    var result = editor.tag_at_index(row, col);
    assertEquals(tag, result);
  }
}


class TestInsertWhenSelected extends HxrtflibTester {
  public function test_first_tag_of_selection_is_taken() {
    var row = 2;
    var sel_start_col = 3;
    var tag = 2;
    // select all cells and apply default tag
    editor.fill("a", true, Globals.DEFAULT_TAG);
    // remove a selection and apply a different tag to start of selection
    editor.set_cell(row, sel_start_col - 1, false, Globals.DEFAULT_TAG);
    editor.set_cell(row, sel_start_col, true, tag);

    var insert_col = sel_start_col + 2;
    core.insert_when_selected(row, insert_col);
    var result = editor.tag_at_index(row, sel_start_col);
    assertEquals(tag, result);
  }
}

class TestInsertChar extends HxrtflibTester {
  // public function test_ignored_chars() {
  // }
  // public function test_insert_when_cursor_at_start() {
  // }
  // public function test_insert_when_selected() {
  // }
  public function test_insert_normal() {
    var row = Globals.DEFAULT_TAG;
    var tag = 2;
    var insert_col = 2;
    editor.set_cell(row, insert_col-1, tag);
    core.insert_char("a", row, insert_col);
    var result = editor.tag_at_index(row, insert_col);
    assertEquals(tag, result);
  }
}


class HxrtflibTest {
  static function main(){
    var r = new haxe.unit.TestRunner();
    r.add(new TestWhenCursorAtStart());
    r.add(new TestInsertWhenSelected());
    r.add(new TestInsertChar());
    r.run();
  }
}
