# projectsetup

## Description

Automates building a project and its dependencies based on a recipe file.

## Notes

Progress is marked using `xxx.DONE_xxx` files in the build dir. Remove specific
progress files to redo those steps.

There is experimental support for building inside `virtualenvwrapper` using the
`--self-contained` (or `-s`) option. This causes it to work in (and install
everything into) a self-contained directory. The virtualenv will have the same
name as the projectname.

Recipe files are searched for in the present directory (pwd) using the name
of this script + "_" + the projectname + ".txt", e.g.:
`projectsetup_myproject.txt`

For now this script has to run under a bourne shell, not POSIX sh, to use
virtualenvwrapper correctly. Nevertheless this script has been written to be
POSIX shell-friendly. It was inspired by, and was initially based on:
* [Brubeck's installation instructions](http://brubeck.io/installing.html)
* [An Isolated Install howto blogpost](http://emptysquare.net/blog/how-to-do-an-isolated-install-of-brubeck/)

## Documentation

Until documentation is improved, see the included example recipes and read
the script itself to derive the recipe structure.

## Downloading

Get it from [its Github page](https://github.com/rowanthorpe/projectsetup/)

## Installation

Trivially easy. See the included `INSTALL` file.

## Copyright

### (c) Copyright 2013 Rowan Thorpe

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [the GNU licenses page](http://www.gnu.org/licenses/).
