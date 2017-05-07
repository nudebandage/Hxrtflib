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
related to text editing. While it's easy enough to get a bit of bold, italic,
 color action; saving and loading this formatting is not possible :(

Hxrtflib allows arbitrary programming languages and text editors to easily
gain this capability in ~200 LOC.

### <a id="features"></a>Features

* Button indenting on Selection/Cursor Moved
* Arbitrary styles i.e Bold, Italic, fonts etc
* Styling behavior moddeled on libre office


### <a id="limitations"></a>Current Limitations

* No right to left language support
* Customization of Styling behavior (only behaves like libre open office)
* Saving and Loading isn't yet implemented


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
1.
```clojure
(if (not (hxrtflib `output/lang`))
  ((check `python.hxml`)
   (create `lang.hxml`))
(haxe `lang.hxml)
```

2. Making the actuall Library in the language is a matter
of inheriting a base class and implementing a couple of functions. Check the tkpyhxrtflib demo (the functions you need begin with `_hx_`). Everything is still under flux so take it easy aye.
