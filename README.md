# HxRtfLib
### Easily add saving/loading of nontextual information to text editors

- [Introduction](#introduction)
- [Features](#features)
- [Limitations](#limitations)
- [Installing](#installing)
- [Usage](#usage)

__Status = ALPHA i.e api may change/improve__


## <a id="introduction"></a>Introduction

Neovim, Tkinter/Gtk text widgets don't support saving and loading of metadata
related to text editing. While it's easy enough to add some bold and
make some font changes. Saving this info and loadig this information
is not include.

Hxrtflib allows arbitrary programming languages and text editors to easily
gain this capability.

### <a id="features"></a>Features

* Button indenting on Selection/Cursor Moved
* Arbitrary styles i.e Bold, Italic, fonts etc
* Styling behavior moddeled on libre office


### <a id="limitations"></a>Limitations

* No right to left language support
* Customization of Styling behavior


## <a id="installing"></a>Installing

TODO

```zsh
```


## <a id="usage"></a>Usage

The rtflib outputs from haxe can be found in this project. I only plan to test
python and lua. It is probably that the other haxe targets work but they will
only be added if/when they are tested (Pull requests anybody ?).

Here are the steps required.

TODO

1. Check that the hxrtflib library exists for your target langauge
    1.1 Generating the output Library
2. Check if the Texteditor has been wrapped in your language
    2.1 Wrapping the editor
    2.2 Using the editor
