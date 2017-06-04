# Tmux copycat

[![Build Status](https://travis-ci.org/tmux-plugins/tmux-copycat.png?branch=master)](https://travis-ci.org/tmux-plugins/tmux-copycat)

This plugin enables:

- regex searches
- search result highlighting
- predefined searches

Predefined searches are plugin killer feature. It speeds the workflow and
reduces mouse usage with Tmux.

It works even better when paired with
[tmux yank](https://github.com/tmux-plugins/tmux-yank).

Tested and working on Linux, OSX and Cygwin.

**Note:** new version 2.0 uses extended regexes! Regex character escaping with
backslashes `\ ` isn't required anymore.

### Screencast

[![screencast screenshot](/video/screencast_img.png)](https://vimeo.com/101867689)

#### Search

- `prefix + /` - regex search (strings work too)

Example search entries:

- `foo` - searches for string `foo`
- `[0-9]+` - regex search for numbers

Grep is used for searching.<br/>
Searches are case insensitive.<br/>

#### Predefined searches

- `prefix + ctrl-f` - simple *f*ile search
- `prefix + ctrl-g` - jumping over *g*it status files (best used after `git status` command)
- `prefix + alt-h` - jumping over SHA-1 hashes (best used after `git log` command)
- `prefix + ctrl-u` - *u*rl search (http, ftp and git urls)
- `prefix + ctrl-d` - number search (mnemonic d, as digit)
- `prefix + alt-i` - *i*p address search

These start "copycat mode" and jump to first match.

#### "Copycat mode" bindings

These are enabled when you search with copycat:

- `n` - jumps to the next match
- `N` - jumps to the previous match

To copy a highlighted match:

- `Enter` - if you're using Tmux `vi` mode
- `ctrl-w` or `alt-w` - if you're using Tmux `emacs` mode

Copying a highlighted match will take you "out" of copycat mode. Paste with
`prefix + ]` (this is Tmux default paste).

Copying highlighted matches can be enhanced with
[tmux yank](https://github.com/tmux-plugins/tmux-yank).

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'tmux-plugins/tmux-copycat'

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

Optional (but recommended) install `gawk` via your package manager of choice
for better UTF-8 character support.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/tmux-plugins/tmux-copycat ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/copycat.tmux

Reload TMUX environment with: `$ tmux source-file ~/.tmux.conf`. You should now
be able to use the plugin.

Optional (but recommended) install `gawk` via your package manager of choice
for better UTF-8 character support.

### Limitations

This plugin has some known limitations. Please read about it
[here](docs/limitations.md).

### Docs

- Most of the behavior of tmux-copycat can be customized via tmux options.
  [Check out the full options list](docs/customizations.md).
- To speed up the workflow you can define new bindings in `.tmux.conf` for
  searches you use often, more info [here](docs/defining_new_stored_searches.md)

### Other goodies

`tmux-copycat` works great with:

- [tmux-yank](https://github.com/tmux-plugins/tmux-yank) - enables copying
  highlighted text to system clipboard
- [tmux-open](https://github.com/tmux-plugins/tmux-open) - a plugin for quickly
  opening a highlighted file or a url
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - automatic
  restoring and continuous saving of tmux env

You might want to follow [@brunosutic](https://twitter.com/brunosutic) on
twitter if you want to hear about new tmux plugins or feature updates.

### Test suite

This plugin has a pretty extensive integration test suite that runs on
[travis](https://travis-ci.org/tmux-plugins/tmux-copycat).

When run locally, it depends on `vagrant`. Run it with:

    # within project top directory
    $ ./run-tests

By default tests run in 2 vagrant VMs: ubuntu and centos.

### Contributions and new features

Bug fixes and contributions are welcome.

Feel free to suggest new features, via github issues.

If you have a bigger idea you'd like to work on, please get in touch, also via
github issues.

### License

[MIT](LICENSE.md)
