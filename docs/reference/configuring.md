# Configuring
`symconf` operates on a central directory that houses all of the config files you may wish
to apply. The default location for this directory is your `$XDG_CONFIG_HOME` (e.g.,
`~/.config/symconf/`), but it can be any location on your system so long as it's specified
(see more in Usage). 

`symconf` expects you to create two top-level components in your config directory: an
`apps/` directory and an `app_registry.toml` file.

## Apps directory
An `apps/` directory should be created in your config home, with a subdirectory
`apps/<app-name>/` for each app with config files that you'd like to be visible to
`symconf`. Note that simply populating an app's config folder here will do nothing on its
own; the app must also have been registered (discussed in item #2) in order for these
files to be used when `symconf` is invoked. (This just means you can populate your `apps/`
folder safely without expecting any default behavior. More often than not you'll be
expected to tell `symconf` exactly where your config files should end up, meaning you know
exactly what it's doing.)

### User config 
Inside your app-specific subdirectory, your managed config files should be placed in a
`user/` subdirectory (distinguishing them from those generated by templates; see more
in Themes). Your config files themselves are then expected to follow a specific naming
scheme:

```sh
<palette>-<scheme>.<config-name>
```

This ties your config file to a particular theme setting as needed, and `symconf` will
apply it if it matches the theme setting you provide when invoked. The specific values are
as follows:

- `scheme`: can be `light`, `dark`, or `none`. Indicates whether the config file should
  be applied specifically when requesting a light or dark mode. Use `none` to indicate
  that the config file does not have settings specific to a light/dark mode.
- `palette`: a "palette name" of your choosing, or `none`. The palette name you use
  here may refer specifically to a color palette used by the config file, but can be
  used generally to indicate any particular group of config settings (e.g., fonts,
  transparency, etc). Use `none` to indicate that the file does not correspond to any
  particular style group.
- `config-name`: the _name_ of the config file. This should correspond to _same path
  name_ that is expected by the app. For example, if your app expects a config file at
  `a/b/c/d.conf`, "`d.conf`" is the path name.

When invoking `symconf` with specific scheme and palette settings (see more in Usage),
appropriate config files can be matched based on how you've named your files.

For example, suppose I want to set up a simple light/dark mode switch for the `kitty`
terminal emulator. The following tree demonstrates a valid setup:

```sh
<config-home>
└── apps/
    └── kitty/
        └── user/
            ├── none-light.kitty.conf
            └── none-dark.kitty.conf
```

where `none-light.kitty.conf` may set a light background and `none-dark.kitty.conf` a dark
one. `none` is used for the `<palette>` part of the name to indicate the configuration does
not pertain to any specific palette and can be matched even if one is not provided. With
an appropriate `app_regsitry.toml` file (see below), invoking 

```sh
symconf --theme=light --apps=kitty
```

would symlink `$XDG_CONFIG_HOME/symconf/apps/kitty/user/none-light.kitty.conf` to
`~/.config/kitty/kitty.conf`.

### Templatized config
Note the potential inconvenience in needing to manage two separate config files in the
above example, very likely with all but one line of difference. Templating enables
populating config template files dynamically with theme-specific variables of your
choosing.


### Reload scripts
After symlinking a new set of config files, it is often necessary to reload the system or
relevant apps in order for the new config settings to apply. Within an app's subdirectory,
a `call/` folder can be created to hold scripts that should apply based on certain schemes
or palettes (matching them in the same way as config files). For example,

```sh
<config-home>
└── apps/
    └── kitty/
        └── call/
            └── none-none.sh
```

`none-none.sh` might simply contain `kill -s USR1 $(pgrep kitty)`, which is a way to tell
all running `kitty` instances to reload their config settings. Again, following the naming
scheme for config files, a script named `none-none.sh` will apply under any scheme or
palette specification. Thus, in our light/dark mode switch example, invoking `symconf
--theme=light --apps=kitty` would:

1. Search and match the config name `none-light.kitty.conf` and symlink it to
   `~/.config/kitty/kitty.conf`.
2. Search and match `none-none.sh` and execute it, applying the new light mode settings to
   all running `kitty` instances.


## App registry
An `app_registry.toml` file, used to specify the target locations for app-specific
config files. To "register" an app, you simply need to add the following text block to
the `app_registry.toml` file:

```toml
[app.<app-name>]
# DEFINE *ONE* OF THE FOLLOWING
config_dir = "<path-to-app-config-folder>"
# OR 
config_map = {
    "<conf-pathname-1>" = "<path-to-exact-config-file>"
    "<conf-pathname-2>" = "<path-to-exact-config-file>"
    # ...
}
```

(Note that text in angle brackets refers to values that should be replaced.) This tells
`symconf` how it should handle each app's config files. The `<app-name>` (e.g.,
`kitty`) should correspond to a subdirectory under `apps/` (e.g., `apps/kitty/`) that
holds your config files for that app. As shown, you then need to supply either of the
following options:

- `config_dir`: specifies a single directory where all of the app's matching config
  files should be symlinked. In the `kitty` example, this might be `~/.config/kitty`.
  This is the simplest and most common option provided most apps expect all of their
  config files to be in a single directory.
- `config_map`: a dictionary mapping config file _path names_ to the _exact paths_ that
  should be created during the symlink process. This is typically needed when an app
  has many config files that need to be set in several disparate locations across your
  system. In the `kitty` example, although not necessary (and in general you should
  prefer to set `config_dir` when applicable), we could have the following
  `config_map`:

  ```toml
  [app.kitty]
  config_map = {
      "kitty.conf": "~/.config/kitty/kitty.conf"
  }
  ```

  This tells `symconf` to symlink the exact location `~/.config/kitty/kitty.conf` to
  the matching `kitty.conf` under the `apps/kitty` directory.

## Directory structure
In total, the structure of your base config directory can look as follows:

```sh
~/.config/symconf/
├── app_registry.toml
└── apps/
    └── <app>/
        ├── user/                      # user managed
        │   └── none-none.<config-name>
        ├── generated/                 # automatically populated
        │   └── none-none.<config-name>
        ├── templates/                 # config templates
        │   └── none-none.template
        └── call/                      # reload scripts
            └── none-none.sh
```

## Misc remarks

### Multiple config files with same path name