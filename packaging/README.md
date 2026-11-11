# AUR packaging

The three Arch User Repository packages for Airlock, one folder each, laid out
the way their AUR git repositories are (a `PKGBUILD`, its `.SRCINFO` and the
shared `astra-airlock.install` hook).

| Package | Builds from | Notes |
| --- | --- | --- |
| `astra-airlock` | the release tarball (`astra-airlock-<version>.tar.gz`) | Cargo build, `cargo test` in `check()` |
| `astra-airlock-git` | `main` on GitHub | version from `git describe` |
| `astra-airlock-bin` | the release binary (`astra-airlock-v<version>`) | x86_64 only; licence from the tag |

QML, fonts and shaders are compiled into the binary, so every package installs
just `/usr/bin/astra-airlock` and the licence. They conflict with each other;
`-git` and `-bin` provide `astra-airlock`.

`astra-airlock.install` runs on first install: it creates the `greeter` user
and `/var/cache/astra-airlock`, writes `/etc/pam.d/greetd` with GNOME Keyring
auto-unlock, deploys the Hyprland kiosk config (`astra-airlock -k hyprland`),
and tries to sync the Caelestia scheme and `~/.face`. Keep the three copies
identical.

## Releasing

1. Tag the release (`git tag v2.0.1 && git push origin v2.0.1`) and let the
   Release workflow upload the tarball and binary.
2. Point the stable and binary packages at it, refresh checksums and every
   `.SRCINFO`:

   ```bash
   packaging/update.sh 2.0.1
   ```

3. Copy each folder's files into its AUR clone
   (`ssh://aur@aur.archlinux.org/<package>.git`), commit and push.

To try a package locally: `cd packaging/astra-airlock-git && makepkg -si`.
