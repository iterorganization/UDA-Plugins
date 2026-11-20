# AGENTS.md

Guidance for AI coding assistants working in this repository.

## What this is

ITER-specific server-side plugins for UDA (Universal Data Access, core repo:
https://github.com/ukaea/uda). Each plugin is a shared library loaded by a UDA
server. Most plugins serve IMAS data access requests, either from IMAS data
files or by mapping experimental machine data (JET, TCV, AUG, WEST, HL-2A,
MAST) into IDS structures. Plugins are C/C++17 and depend on an installed UDA
(>= 2.3.1.35, found through `cmake/Modules/FindUDA.cmake` / pkg-config).

The actively maintained plugin is `source/imas` (the IMAS Access Layer 5 UDA
backend). Plugins marked "For AL 4" in `README.md` (`imas_forward`,
`imas_mapping`, `imas_partial`, `imas_remote`, `imas_uda`) are legacy.

## Build

```bash
cmake -Bbuild -H. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$UDA_HOME
# build only some plugins (semicolon-separated directory names under source/):
cmake -Bbuild -H. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$UDA_HOME -DBUILD_PLUGINS="imas"
make -C build -j2
make -C build install
make -C build clang-format     # format sources registered with the clang-format target
```

- Plugins whose dependencies are not found are skipped with a CMake *warning*,
  not an error. Check the configure output to confirm the plugin you changed was
  actually built.
- `source/imas` builds without IMAS-Core in "mapping only" mode (`-DNO_IMAS`,
  guards around `al_lowlevel.h` calls). There is no dedicated option: it is
  selected automatically when `al-core` is not found via pkg-config, and can be
  forced with `-DCMAKE_DISABLE_FIND_PACKAGE_IMAS=TRUE`. In that mode only
  `open`/`get`/`close` on `mapping=<MACHINE>` URIs work; local IMAS entries and
  `getOccurrences`, `beginArraystructAction`, `listFilledPaths` raise an error.
  Keep both modes compiling.
- `-DIMAS_MAPPINGS_FILE=<path>` sets the machine mapping table exported as
  `UDA_IMAS_MAPPINGS_FILE` in the installed `etc/plugins.d/imas.cfg`; default is
  `<prefix>/etc/imas/mappings.txt`, installed from `source/imas/mappings.txt`.
- `-DENABLE_AUTHORISATION=ON` compiles the IMAS plugin's authorisation check
  (`-DUDA_AUTHORISATION`, uses `UDA_AUTHORISATION_URL` and libcurl).
- `scripts/cmake-*.sh` are site-specific configure examples; `scripts/iter-ci-*.sh`
  is the (old) ITER Bamboo CI flow: setup-env → config → build → install.
- After install, `build/scripts/activate-plugins.sh` registers each built plugin
  with the UDA server via `$UDA_HOME/bin/install_plugin`.

## Tests

There is no unit-test suite for `source/imas`. Some legacy plugins
(`exp2imas`, `imas_mapping`, `imas_partial`, `tcvm`) have Catch-based
integration tests under `<plugin>/tests/`, built through the `BUILD_TEST` macro
in `cmake/testing.cmake`. Each test produces two executables: `<name>` (client
library, needs a running UDA server) and `fat_<name>` (fat client, runs plugins
in-process using the *installed* plugins and config; selected for `ctest` with
`-DFAT_TESTS=ON`). They need access to real machine data, so they generally
cannot run outside the original sites. Run one by executing its binary from
the build tree (only `imas_partial` calls `enable_testing()`, so `ctest` does
not see the other plugins' tests).

## Architecture

- **Plugin registration** – every plugin's `CMakeLists.txt` calls the
  `uda_plugin(...)` macro from `cmake/plugins.cmake` (NAME, LIBNAME,
  ENTRY_FUNC, SOURCES, EXTRA_* deps, optional CONFIG_FILE). The macro builds the
  shared library, defines `PLUGIN_NAME`/`PLUGIN_VERSION`, links with
  `-Wl,-z,defs` (all symbols must resolve), and writes the UDA plugin registry
  line into `udaPlugins_<NAME>.conf` and the aggregate `build/udaPlugins.conf`.
  `CONFIG_FILE foo.cfg` configures `<plugin>/foo.cfg.in` into
  `etc/plugins.d/` (environment exported to the server). Add a new plugin by
  creating `source/<name>/` with such a CMakeLists and adding it to the default
  `BUILD_PLUGINS` list in `source/CMakeLists.txt`.
- **Entry point** – UDA calls the entry function (e.g. `imasPlugin`) with an
  `IDAM_PLUGIN_INTERFACE*`. The plugin dispatches on the requested function name
  (see `handle_request` in `source/imas/imas_plugin.cpp`), reads arguments from
  the request name/value list, and returns data by filling
  `plugin_interface->data_block`. Standard functions every plugin implements:
  `help`, `version`, `builddate`, `defaultmethod`, `maxinterfaceversion`, plus
  `init`/`reset` housekeeping.
- **IMAS plugin flow** (`source/imas`) – `open` parses an IMAS URI
  (`uri_parser.h`) and either opens a local IMAS-Core entry or, when the URI
  carries `mapping=<machine>`, sets up a mapped entry. `get` reads one IDS path:
  local entries go through the AL low-level API; mapped entries are turned into
  a `<PLUGIN>::get(mapping=..., path=..., rank=..., shape=..., datatype=...)`
  request sent to another UDA plugin (`callPlugin` in-process if the host is
  localhost/this host, otherwise a UDA client call to the remote server). The
  machine → (IDS, host, port, plugin) table is the 5-column file named by the
  environment variable `UDA_IMAS_MAPPINGS_FILE` (example: `mappings.txt`, parsed
  in `machine_mapping.h`). Results are returned serialised with Cap'n Proto.
- **IMAS plugin help** – `help` returns `source/imas/help.md`, read at runtime
  from the *source directory* (`__FILE__`). `help.md` is generated from the
  structured `Name:` / `Function:` / `Arguments:` / `Returns:` doc comments in
  `imas_plugin.cpp`: after changing a function or its arguments, update the
  comment and regenerate with
  `python3 source/imas/comments2help.py source/imas/imas_plugin.cpp > source/imas/help.md`.
- **exp2imas** – generic mapping engine driven by XML mapping files in
  `source/exp2imas/mappings/<MACHINE>/<IDS>/<shot>/` (directory name is the
  first shot the mapping applies to; `0` = default), reading data from MDSplus,
  optionally over SSH.

## Conventions

- C++17. Formatting per `.clang-format` (LLVM base, 4-space indent, 120
  columns, left pointer alignment); `.clang-tidy` is present for static analysis.
- `catch.hpp` is vendored (single-header Catch); don't edit it.
