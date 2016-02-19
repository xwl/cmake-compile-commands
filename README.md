cmake-compile-commands
======================

For a cmake project, compile\_commands.json contains exact command line
compile command for each source file in the project.  The package
analyses compile_commands.json and provides easy access to compiler
command, compile args, compile includes, etc.  Other tools like
[flycheck-cmake](https://github.com/xwl/flycheck-cmake) or [auto-complete-clang](https://github.com/xwl/auto-complete-clang) then can use this lib to support
cmake projects easily.

compile\_commands.json can be generated via below cmake command:

    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1

## Usage

Just need to add build directory containing compile_commands.json to `cmake-compile-commands-build-directories`:

```lisp
(setq cmake-compile-commands-build-directories '("/project/build"))
```
