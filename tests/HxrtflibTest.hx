import hxrtflib.Hxrtflib;
import hxrtflib.Util;

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
  var cursor:Pos = {row:0, col:0};

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

  public dynamic function cell_at_index(row, col) {
    var key = index_to_key(row, col);
    return cells.get(key);
  }

  public dynamic function sel_at_index(row, col) : Bool {
    return cell_at_index(row,col).selected;
  }

  public dynamic function char_at_index(row, col) : String {
    return cell_at_index(row,col).text;
  }

  public dynamic function tag_at_index(row, col) : Int {
    return cell_at_index(row,col).tag;
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

  public dynamic function insert_cursor_get() {
    return cursor;
  }

  public dynamic function create_style(style_id) {
  }

  public dynamic function modify_style(style_id, key, value) {
  }

  public dynamic function sel_index_get(row, col) {
    // limited to same row;
    var left, right;
    right = col;
    for (c in col...last_col(row)+1) {
      if (sel_at_index(row, c)) {
        right = c;
      }
      else {
        break;
      }
    }
    left = Globals.START_COL;
    for (c in Globals.START_COL...col+1) {
      if (!sel_at_index(row, c)) {
        left = c-1;
        break;
      }
    }
    var start, end;
    start = {row:row, col:left};
    end = {row:row, col:right};
    return {start:start, end:end};
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

  public function set_cell(row, col, ?char="", ?tag:Int=-1, ?selected:Bool=false) {
    var key = index_to_key(row, col);
    var cell = cells.get(key);
    cell.text = char;
    cell.selected = selected;
    cell.tag = tag;
    cells.set(key, cell);
  }

  public function set_cell_range(row, col, amount, ?char="", ?tag:Int=-1, ?selected:Bool=false) {
    for (i in col...col+amount+1) {
      set_cell(row, i, char, tag, selected);
    }
  }

  public function set_cursor(row, col) {
    cursor.row = row;
    cursor.col = col;
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
               editor.ignore_key,
               editor.insert_cursor_get,
               editor.create_style,
               editor.modify_style,
               editor.sel_index_get);
  }
}

class TestRandom extends HxrtflibTester {
  public function test_default_tag_is_added_to_map() {
    assertEquals(core.styles.exists(Globals.DEFAULT_TAG), true);
  }
}


class TestWhenCursorAtStart extends HxrtflibTester {
  public function test_insert_blank_editor() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    core.insert_when_cursor_at_start(row);

    var result = editor.tag_at_index(row, col);
    assertEquals(Globals.DEFAULT_TAG, result);

    var result = editor.tag_at_index(row, col+1);
    assertEquals(Globals.NOTHING, result);

    // test that it only happens if a tag doesn't exist
    var tag = 1;
    editor.set_cell(row, col, "b", tag);
    core.insert_when_cursor_at_start(row);
    var result = editor.tag_at_index(row, col);
    assertEquals(tag, result);
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

    editor.set_cell(row, col, "a", tag);
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
    editor.set_cell(row, sel_start_col - 1, Globals.DEFAULT_TAG, false);
    editor.set_cell(row, sel_start_col, tag, true);

    var insert_col = sel_start_col + 2;
    core.insert_when_selected(row, insert_col);
    var result = editor.tag_at_index(row, sel_start_col);
    assertEquals(tag, result);
  }
}


class TestInsertChar extends HxrtflibTester {
  // public function test_ignored_chars() {
  // }
  // public function test_insert_normal() {
    // var row = Globals.START_ROW;
    // var tag = 2;
    // var insert_col = 2;
    // editor.set_cell(row, insert_col-1, tag);
    // core.on_char_insert("a", row, insert_col);
    // var result = editor.tag_at_index(row, insert_col);
    // assertEquals(tag, result);
  // }

  public function test_override_style_applied() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;

    var tag = Globals.DEFAULT_TAG;
    var word_length = 3;

    editor.set_cell_range(row, col, word_length, "a", tag);
    editor.set_cell(row, col+word_length+1, " ", tag);

    var change_key = "weight";
    var change_value = "bold";
    var insert_col = col+word_length + 1;
    editor.set_cursor(row, insert_col);

    // Override style is applied on char insert
    core.style_change(change_key, change_value);
    var override_style = core.override_style_get();
    core.on_char_insert("b", row, insert_col);
    var result = editor.tag_at_index(row, insert_col);
    assertEquals(override_style, result);

    // Override style is removed on second char insert
    var insert_col2 = insert_col + 1;
    editor.set_cursor(row, insert_col2);

    core.style_change(change_key, change_value);
    var override_style = core.override_style_get();
    assertEquals(Globals.DEFAULT_TAG, override_style);
    core.on_char_insert("c", row, insert_col2);
    var result = editor.tag_at_index(row, insert_col2);
    assertEquals(tag, result);
  }
}


class TestWordExtremity extends HxrtflibTester {
  public function test_start_col() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    var result = core.is_word_extremity(row, col);
    assertEquals(true, result);
  }

  public function test_eol() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    editor.set_cell(row, col, "a");
    editor.set_cell(row, col+1, "b");
    editor.set_cell(row, col+2, "\n");
    var result = core.is_word_extremity(row, col);
    assertEquals(true, result);
    var result = core.is_word_extremity(row, col+1);
    assertEquals(false, result);
    var result = core.is_word_extremity(row, col+2);
    assertEquals(true, result);
  }

  public function test_start_middle_and_end() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    editor.set_cell(row, col, " ");
    editor.set_cell(row, col+1, "a");
    editor.set_cell(row, col+2, "b");
    editor.set_cell(row, col+3, "c");
    editor.set_cell(row, col+4, " ");
    var result = core.is_word_extremity(row, col+1);
    assertEquals(true, result);

    var result = core.is_word_extremity(row, col+2);
    assertEquals(false, result);

    var result = core.is_word_extremity(row, col+3);
    assertEquals(false, result);

    var result = core.is_word_extremity(row, col+4);
    assertEquals(true, result);
  }

}


class TestWordStart extends HxrtflibTester {
  public function test_start_col() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    var word_length = 4;
    editor.set_cell_range(row, col, word_length, "a");

    var result = core.word_start_get(row, col);
    assertEquals(col, result);

    var result = core.word_start_get(row, col+1);
    assertEquals(col, result);

    editor.set_cell(row, col, " ");
    var result = core.word_start_get(row, col+1);
    assertEquals(col+1, result);
  }

  public function test_middle() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    var word_length = 3;
    editor.set_cell(row, col, " ");
    editor.set_cell_range(row, col+1, word_length, "a");

    var insert_col = col + 3;
    var result = core.word_start_get(row, insert_col);
    assertEquals(col + 1, result);
  }
}


class TestWordEnd extends HxrtflibTester {
  public function test_eol() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    editor.set_cell(row, col, "a");
    editor.set_cell(row, col+1, "b");
    editor.set_cell(row, col+2, "c");
    editor.set_cell(row, col+3, "\n");

    var result = core.word_end_get(row, col);
    assertEquals(col+3, result);

    var result = core.word_end_get(row, col+1);
    assertEquals(col+3, result);
  }

  public function test_middle() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    var word_length = 3;
    editor.set_cell_range(row, col, word_length, "a");
    editor.set_cell(row, col+word_length+1, " ");

    var insert_col = col + 1;
    var result = core.word_end_get(row, insert_col);
    assertEquals(col+word_length+1, result);

    insert_col = col+word_length;
    var result = core.word_end_get(row, insert_col);
    assertEquals(col+word_length+1, result);
  }
}


class TestChangeStyleNoSelect extends HxrtflibTester {
  public function test_change_style_from_middle_of_word() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;

    var tag = Globals.DEFAULT_TAG;
    var word_length = 3;

    editor.set_cell_range(row, col, word_length, "a", tag);
    editor.set_cell(row, col+word_length+1, " ", tag);

    var change_key = "weight";
    var change_value = "bold";
    var cursor_col = col+word_length-1;
    editor.set_cursor(row, cursor_col);

    for (i in col...col+word_length) {
      var result = editor.tag_at_index(row, i);
      assertEquals(tag, result);
    }

    // Bold the entire word
    var new_tag = Util.unique_int([tag]);
    core.style_change(change_key, change_value);
    for (i in col...col+word_length) {
      var result = editor.tag_at_index(row, i);
      assertEquals(new_tag, result);
    }
    // Unbold the entire word
    core.style_change(change_key, change_value);
     for (i in col...col+word_length) {
      var result = editor.tag_at_index(row, i);
      assertEquals(tag, result);
    }
    // Make sure the tag is reused
    core.style_change(change_key, change_value);
    for (i in col...col+word_length) {
      var result = editor.tag_at_index(row, i);
      assertEquals(new_tag, result);
    }
  }

  public function test_start_and_end_of_word() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;

    var tag = Globals.DEFAULT_TAG;
    var word_length = 3;

    editor.set_cell_range(row, col, word_length, "a", tag);
    editor.set_cell(row, col+word_length+1, " ", tag);

    var change_key = "weight";
    var change_value = "bold";
    var start = col;
    var end = col + word_length + 1;

    editor.set_cursor(row, start);
    core.style_change(change_key, change_value);

    // make sure no style applied yet
    var tag_at_index = editor.tag_at_index(row, start);
    assertEquals(tag, tag_at_index);
    // make sure the override style was set
    var override_style = core.override_style_get();
    assertEquals(Util.unique_int([tag]), override_style);

    // Change Style Can be toggled off
    core.style_change(change_key, change_value);
    // make sure the override style was unset
    var override_style = core.override_style_get();
    assertEquals(Globals.NOTHING, override_style);

    // Check end of the word
    editor.set_cursor(row, end);
    core.style_change(change_key, change_value);

    // make sure no style applied yet
    var tag_at_index = editor.tag_at_index(row, end);
    assertEquals(tag, tag_at_index);
    // make sure the override style was set
    var new_tag = Util.unique_int([tag]);
    var override_style = core.override_style_get();
    assertEquals(new_tag, override_style);

    // Change Style Can be toggled off
    core.style_change(change_key, change_value);
    // make sure the override style was unset
    var override_style = core.override_style_get();
    assertEquals(Globals.NOTHING, override_style);
  }
}


class TestChangeStyleWithSelection extends HxrtflibTester {
  public function test_style_with_selection() {
    var row = Globals.START_ROW;
    var col = Globals.START_COL;

    var tag = Globals.DEFAULT_TAG;
    var word_length = 5;

    // Put some text with default tag
    editor.set_cell_range(row, col, word_length, "a", tag, false);
    editor.set_cell(row, col+word_length+1, " ", tag, false);

    // Select some of the text
    var sel_start = col + 1;
    var sel_end = col + word_length - 1;
    var sel_len = sel_start - sel_end;
    editor.set_cell_range(row, sel_start, sel_len, "a", tag, true);

    var change_key = "weight";
    var change_value = "bold";
    editor.set_cursor(row, sel_start);
    core.style_change(change_key, change_value);
    // make sure style applied to start
    var new_tag = Util.unique_int([tag]);
    var result = editor.tag_at_index(row, sel_start);
    assertEquals(new_tag, result);

    // make sure style applied to end
    var result = editor.tag_at_index(row, sel_end);
    assertEquals(new_tag, result);

    // make sure end points + 1 not styled
    // var result = editor.tag_at_index(row, sel_start - 1);
    // assertEquals(tag, result);
    // var result = editor.tag_at_index(row, sel_end + 1);
    // assertEquals(tag, result);
  }
}


// These tests are a bit pointless, might have to refactor ignore_keys
class TestOverride extends HxrtflibTester {
  public function test_override_used_on_insert() {
    var tag = Globals.DEFAULT_TAG;
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    editor.set_cell(row, col, "a", tag);

    // This sets our override style
    var change_key = "weight";
    var change_value = "bold";
    editor.set_cursor(row, col);
    core.style_change(change_key, change_value);
    // Override should have been applied
    core.on_char_insert('a', row, col+1);

    var new_tag = Util.unique_int([tag]);
    var result = editor.tag_at_index(row, col+1);
    assertEquals(new_tag, result);
  }

  public function test_override_canceled_on_some_events() {
    var tag = Globals.DEFAULT_TAG;
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    editor.set_cell(row, col, "a", tag);

    // This sets our override style
    var change_key = "weight";
    var change_value = "bold";
    editor.set_cursor(row, col);
    core.style_change(change_key, change_value);
    core.on_char_insert('space', row, col+1);

    var result = editor.tag_at_index(row, col+1);
    assertEquals(-1, result);
  }

  public function test_override_canceled_on_mouse() {
    var tag = Globals.DEFAULT_TAG;
    var row = Globals.START_ROW;
    var col = Globals.START_COL;
    editor.set_cell(row, col, "a", tag);

    // This sets our override style
    var change_key = "weight";
    var change_value = "bold";
    editor.set_cursor(row, col);
    core.style_change(change_key, change_value);
    core.on_mouse_click(row, col);

    var result = core.override_style_get();
    assertEquals(-1, result);
  }
}


class TestConsumer extends HxrtflibTester {
  public function test_middle_of_word() {
    var tag = Globals.DEFAULT_TAG;
    var row = Globals.START_ROW;
    var col = Globals.START_COL;

    var test_values = new Array();
    var test = function(k, v) {
      test_values.insert(0, {k: k, v:v});
    }
    core.register_consumer(test);

    // Insert a bold word, the space at the end is not bolded
    var word_length = 3;
    editor.set_cell_range(row, col, word_length, "a", tag);
    editor.set_cell(row, col+word_length + 1, " ", tag);
    var cursor_col = col + word_length - 1;
    editor.set_cursor(row, cursor_col);
    var change_key = "weight";
    var change_value = "bold";

    // Test it bolds
    core.style_change(change_key, change_value);
    assertEquals("reset", test_values.pop().k);
    var change = test_values.pop();
    assertEquals(change_key, change.k);
    assertEquals(change_value, change.v);
    assertEquals(null, test_values.pop());

    // Test it unbolds
    core.style_change(change_key, change_value);
    assertEquals("reset", test_values.pop().k);
    assertEquals(null, test_values.pop());

  }

  public function test_mouse_triggers_consumer() {
    var tag = Globals.DEFAULT_TAG;
    var row = Globals.START_ROW;
    var col = Globals.START_COL;

    var test_values = new Map();
    var test = function(a, b) {
      test_values.set(a, b);
    }
    core.register_consumer(test);

    editor.set_cell(row, col, "a", tag);
    core.on_mouse_click(row, col);

    // check the clear signal got sent
    assertEquals("reset", test_values.keys().next());
  }
}


class TestMapSame extends haxe.unit.TestCase {
  function test_works() {
    var map1 = new Map();
    map1.set("1", "1");
    var map2 = new Map();
    map2.set("2", "2");
    var result = Util.mapSame(map1, map2);
    assertEquals(false, result);
    map2.remove("2");
    map2.set("1", "1");
    var result = Util.mapSame(map1, map2);
    assertEquals(true, result);
  }
}


class HxrtflibTest {
  static function main(){
    var r = new haxe.unit.TestRunner();
    r.add(new TestRandom());
    r.add(new TestWhenCursorAtStart());
    r.add(new TestInsertWhenSelected());
    r.add(new TestInsertChar());
    r.add(new TestWordExtremity());
    r.add(new TestWordStart());
    r.add(new TestWordEnd());
    r.add(new TestMapSame());
    r.add(new TestChangeStyleNoSelect());
    r.add(new TestChangeStyleWithSelection());
    r.add(new TestOverride());
    r.add(new TestConsumer());
    r.run();
  }
}
