# Caelestia Greeter

A modern, fluid Material 3 frontend for **[greetd](https://git.sr.ht/~kennylevinsen/greetd)**, crafted with **[Quickshell](https://quickshell.outfoxxed.me/)** and Qt6 to seamlessly match Caelestia's **[shell](https://github.com/caelestia-dots/shell)**.

---

## Screenshots
<img width="1920" height="1080" alt="Caelestia Greeter idle screen" src="https://github.com/user-attachments/assets/da58e7e2-d835-4dfe-8148-ba356efa8428" />
<img width="1920" height="1080" alt="Caelestia Greeter login screen" src="https://github.com/user-attachments/assets/f60e8994-931f-4ea1-8fef-b2fa32d041e3" />

---

## Dependencies

**Runtime:**
- **[greetd](https://git.sr.ht/~kennylevinsen/greetd)**
- **[Quickshell](https://quickshell.outfoxxed.me/)** >= 0.3.0
- **Qt 6.6+** (Core, DBus, Qml, Quick, Quick3D)
- **M3Shapes QML module** — Provided by [caelestia-shell](https://github.com/caelestia-dots/shell) (or `caelestia-shell-git`/`dim-caelestia-shell-git`)
- **A wayland compositor** — Example configurations are supplied for use with [Hyprland](https://github.com/hyprwm/hyprland) and [Cage](https://github.com/cage-kiosk/cage)

**Build:**
- **CMake** >= 3.19
- **Ninja**

**Optional:**
- **[caelestia-cli](https://github.com/caelestia-dots/cli)** (or `caelestia-cli-git` / `dim-caelestia-cli-git`) — Required to use `--sync` (provides the Caelestia scheme)
- **[wlr-randr](https://gitlab.freedesktop.org/emersion/wlr-randr)** — Only necessary if using the monitor flags

---

## Building & Installation

### Arch Linux (AUR)

Install one of the packages from the AUR using your preferred AUR helper:

- **[caelestia-greeter](https://aur.archlinux.org/packages/caelestia-greeter)** — stable release
- **[caelestia-greeter-git](https://aur.archlinux.org/packages/caelestia-greeter-git)** — latest development version

```sh
# With paru
paru -S caelestia-greeter

# Or the git version
paru -S caelestia-greeter-git
```

## If using a manual install or a fork of the Caelestia shell and or cli, you can create and install a fake package to satisfy the dependencies:
```sh
mkdir -p /tmp/dummy-caelestia && cd /tmp/dummy-caelestia
nano PKGBUILD
```

Paste in these contents:
```
pkgname=dummy-caelestia
pkgver=1.0.0
pkgrel=1
pkgdesc="Dummy metapackage to satisfy caelestia dependencies"
arch=('any')
provides=('caelestia-shell' 'caelestia-cli')
conflicts=('caelestia-shell' 'caelestia-cli')

package() {
    true
}
```

Then install the dummy package:
```sh
makepkg -si
```

### Manual Installation (CMake)

```sh
# Clone and enter directory
git clone https://github.com/dim-ghub/caelestia-greeter.git
cd caelestia-greeter

# Configure and compile C++ QML plugin
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Install QML module, configuration, and launcher
sudo cmake --install build
```

This installs:
- The `Caelestia.Greeter` QML plugin under the system Qt6 QML module directory (typically `/usr/lib/qt6/qml/Caelestia/Greeter/`)
- The launcher binary to `/usr/bin/caelestia-greeter`
- The shell configuration to `/etc/xdg/quickshell/caelestia-greeter/`

### Nix / NixOS Installation

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    caelestia-greeter.url = "github:dim-ghub/caelestia-greeter";
  };

  outputs = { self, nixpkgs, caelestia-greeter, ... }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        caelestia-greeter.nixosModules.default
        {
          services.greetd.caelestiaGreeter.enable = true;
          services.greetd.caelestiaGreeter.compositor = "cage";
        }
      ];
    };
  };
}
```

---

## Setting Up with greetd

### 1. Create the `greeter` User and Cache Directory

Most distributions create the greeter system user when installing greetd. If yours didn't, create it manually:

```sh
# Create the greeter user only if your greetd package did not provide one
getent passwd greeter >/dev/null || \
    sudo useradd -r -M -s /usr/bin/nologin -d /var/cache/caelestia-greeter greeter

# Add the user to groups required by the greeter
sudo usermod -aG video,input greeter

# Create the state/cache directory for persistent settings & session memory
sudo install -d -m 0755 -o greeter -g greeter /var/cache/caelestia-greeter
```

> [!NOTE]
> Greeter UI preferences (avatar shape, 12/24h clock, idle animations, color scheme, flavour, dark/light mode, and last-used session per user) are automatically saved to `/var/cache/caelestia-greeter/greeter.json`.

### 2. Setting User Profile Pictures (Avatars)

For user profile pictures (pfps) to work properly with greetd, the user needs to set their profile picture using the `--set-pfp` flag:

```sh
# Automatically identifies your user from SUDO_USER
sudo caelestia-greeter --set-pfp /path/to/avatar.png
```

> [!NOTE]
> Because greetd runs under the restricted system `greeter` user, it cannot access files inside personal home directories (such as `~/.face`). Using `--set-pfp` copies the selected image into the shared avatar store (`/var/cache/caelestia-greeter/avatars/<username>`) with the correct read permissions so the greeter can display it.

### 3. Configure `/etc/greetd/config.toml`

You can run `caelestia-greeter` inside either **Cage** (lightweight kiosk compositor) or **Hyprland**.

#### Quick Setup via `-k` / `--kiosk`

> [!CAUTION]
> `--kiosk` replaces existing greetd configuration files; make sure you back them up first if you have a customized setup.

The `caelestia-greeter` binary provides a `-k` / `--kiosk` command to automatically deploy the greetd configurations:

```sh
# Deploy Cage configuration to /etc/greetd/config.toml:
sudo caelestia-greeter -k cage

# Or deploy Hyprland configuration to /etc/greetd/config.toml and /etc/greetd/hyprland.lua:
sudo caelestia-greeter -k hyprland
```

- **`-k cage` / `--kiosk cage`**: Copies [`assets/greetd.toml.example`](assets/greetd.toml.example) directly into `/etc/greetd/config.toml` configured to launch `cage -s -- caelestia-greeter`.
- **`-k hyprland` / `--kiosk hyprland`**: Configures `/etc/greetd/config.toml` to launch `start-hyprland -- -c /etc/greetd/hyprland.lua` and copies the kiosk configuration [`assets/hyprland.lua.example`](assets/hyprland.lua.example) to `/etc/greetd/hyprland.lua`.

---

### 4. PAM Configuration & Keyring Auto-Unlock (GNOME Keyring)

> [!IMPORTANT]
> This example targets Arch Linux. On other distros, add `pam_gnome_keyring.so` to your existing greetd PAM configuration rather than replacing the entire file verbatim.

To ensure GNOME Keyring automatically unlocks when logging in through `greetd`, verify that `/etc/pam.d/greetd` includes `pam_gnome_keyring.so`:

```
# /etc/pam.d/greetd - PAM configuration for greetd
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so

account    include      system-local-login

password   include      system-local-login

session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start
```

An example configuration file is provided in [`assets/pam.d/greetd.example`](assets/pam.d/greetd.example).

> [!TIP]
> When installing via the AUR package (`caelestia-greeter` or `caelestia-greeter-git`), `/etc/pam.d/greetd` is automatically configured with GNOME Keyring auto-unlock entries during post-install.

---

#### Manual Configuration

##### Option A: Using Cage (Recommended)

In `/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "cage -s -- caelestia-greeter"
user = "greeter"
```

#### Option B: Using Hyprland

In `/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "start-hyprland -- -c /etc/greetd/hyprland.lua"
user = "greeter"
```

Create `/etc/greetd/hyprland.lua` (an example is provided in [`assets/hyprland.lua.example`](assets/hyprland.lua.example)):

```lua
-- Default monitor conf
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Default options
hl.config({
  animations = { enabled = false },
  decoration = {
    blur = { enabled = false },
    shadow = { enabled = false },
  },
  input = {
    kb_layout = "us", -- Change as needed
    numlock_by_default = false,
    repeat_delay = 250,
    repeat_rate = 35,
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      scroll_factor = 0.3,
    },
  },
  misc = {
    disable_autoreload = true,
    disable_hyprland_logo = true,
    force_default_wallpaper = 0,
  },
})

-- Cursors (ensure cursor theme is installed in /usr/share/icons)
local cursor_theme = "Bibata-Modern-Classic"
local cursor_size = "14"

hl.env("HYPRCURSOR_THEME", cursor_theme)
hl.env("HYPRCURSOR_SIZE", cursor_size)
hl.env("XCURSOR_THEME", cursor_theme)
hl.env("XCURSOR_SIZE", cursor_size)

-- Start the greeter on init
hl.on("hyprland.start", function()
  hl.exec_cmd("caelestia-greeter; hyprctl dispatch exit")
end)
```

#### Customizing `/etc/greetd/hyprland.lua`

When using Hyprland as the compositor, you can customize any aspect of the greeter environment in `/etc/greetd/hyprland.lua`:

> [!IMPORTANT]
> Because greetd runs under the system `greeter` user, custom cursor themes must be installed system-wide in `/usr/share/icons/` (e.g. `/usr/share/icons/Bibata-Modern-Classic`) with standard read permissions (`chmod -R 755`).

- **Cursor Theme & Size**:
  Set your cursor theme and size via the unified `cursor_theme` and `cursor_size` variables:
  ```lua
  local cursor_theme = "Bibata-Modern-Classic"
  local cursor_size = "14"

  hl.env("HYPRCURSOR_THEME", cursor_theme)
  hl.env("HYPRCURSOR_SIZE", cursor_size)
  hl.env("XCURSOR_THEME", cursor_theme)
  hl.env("XCURSOR_SIZE", cursor_size)
  ```
- **Keyboard Layout & Input**:
  Configure keyboard layout, variants, repeat rates, and touchpad behaviors:
  ```lua
  input = {
    kb_layout = "us,de",
    kb_options = "grp:alt_shift_toggle,caps:escape",
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
    },
  }
  ```
- **Monitors & Scaling**:
  Define explicit monitor modes and scaling factors:
  ```lua
  hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
  hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "2560x0", scale = 1 })
  ```

### 5. Multi-Monitor Configuration

By default the greeter is shown on every connected output. The launcher
passes monitor options through to `wlr-randr`, so you can pick which
output(s) the greeter appears on and how they are configured. Pass them
inside the `command` string of `/etc/greetd/config.toml`:

```toml
# Show only on DP-2 (all other outputs are disabled)
command = "cage -s -- caelestia-greeter --only DP-2"

# Explicit layout: DP-2 at 2560x1440@120 positioned at 0,0, others off
command = "cage -s -- caelestia-greeter --output DP-2 --mode 2560x1440@120 --pos 0,0 --output DP-1 --off --output DP-3 --off"
```

Supported options: `--only`, `--output NAME`, `--on`, `--off`,
`--toggle`, `--mode WxH[@RATE]`, `--custom-mode WxH[@RATE]`, `--preferred`,
`--pos X,Y`, `--left-of`, `--right-of`, `--above`, `--below`,
`--transform`, `--scale`, `--adaptive-sync`.

The options are applied to the running compositor via the
`wlr-output-management` protocol before Quickshell starts; all other
arguments are passed through to Quickshell. Run `caelestia-greeter --help`
for the full list.

#### Converting an Existing Hyprland Monitor Configuration

If you already have your monitor layout configured in Hyprland, you can
generate the matching flags instead of writing them by hand:

```sh
caelestia-greeter --convert ~/.config/caelestia/hyprland-gui.lua
```

This reads monitor definitions from a Hyprland config — either plain
`monitor = NAME, WxH@RATE, XxY, SCALE` lines or Lua `hl.monitor({ ... })`
blocks (as generated by HyprMod) — and prints the equivalent
`caelestia-greeter` flags:

```sh
caelestia-greeter --output DP-1 --custom-mode 1920x1080@280.00Hz --pos 1920,333 --scale 1 --output DP-2 --custom-mode 1920x1080@143.98Hz --pos 0,333 --scale 1
```

Disabled monitors become `--off`, `preferred`/`auto` modes map to
`--preferred`, and Hyprland `transform` numbers (0-7) map to wlr-randr
transform names (e.g. `3` → `270`). Copy the printed flags into the
`command` string of `/etc/greetd/config.toml` as shown above.

### 6. Syncing Active Desktop Scheme ("Dynamic" Scheme)

The `-s` / `--sync` flag copies your active desktop Caelestia scheme into the greeter:

```sh
sudo caelestia-greeter --sync
# or
sudo caelestia-greeter -s
```

It grabs the scheme currently applied by caelestia-cli — the active scheme name, flavour, mode, and generated colors — and writes it to `/var/cache/caelestia-greeter/schemes/dynamic/<user>/` as two files: `dark.json` and `light.json`.

Once synced, a **Dynamic** scheme option appears in the greeter's scheme modal **for your specific user**. Selecting it renders the greeter with the colors of your desktop scheme instead of a built-in one. When multiple users have synced schemes, the greeter automatically picks the matching dynamic scheme and crossfades between them as you switch users on the login screen. Re-run `--sync` whenever you change your desktop scheme to refresh it.

> [!NOTE]
> Because the command is run via `sudo`, it identifies your account from `SUDO_USER` and reads your scheme from your real home directory (`~/.config/caelestia` and `~/.cache/caelestia`). Run it with `sudo` so it targets your user rather than the restricted `greeter` user.

#### Running without a password (sudoers)

To let the sync run non-interactively (e.g. from a hook, see below) without prompting for a password, add a sudoers rule allowing only this command:

```sh
# Replace <your-username> with your actual user name
sudo tee /etc/sudoers.d/caelestia-greeter-sync << EOF
<your-username> ALL=(ALL) NOPASSWD: /usr/bin/caelestia-greeter -s, /usr/bin/caelestia-greeter --sync
EOF
sudo chmod 440 /etc/sudoers.d/caelestia-greeter-sync
```

This lets you run `caelestia-greeter --sync` (or `-s`) with `sudo` without a password, while every other invocation of `caelestia-greeter` still requires authentication. Verify it with the non-interactive form:

```sh
sudo -n caelestia-greeter --sync
```

Using `sudo -n` makes the command fail immediately instead of hanging when no rule is in place — exactly what a background hook wants.

#### Syncing automatically when the scheme or wallpaper changes

caelestia-cli runs a configurable `postHook` after applying a theme (`theme.postHook`) and after setting a wallpaper (`wallpaper.postHook`). Point both at the sync command in `~/.config/caelestia/cli.json`:

```json
{
    "theme": {
        "postHook": "sudo -n caelestia-greeter --sync"
    },
    "wallpaper": {
        "postHook": "sudo -n caelestia-greeter --sync"
    }
}
```

Now whenever you change your Caelestia scheme or your wallpaper, the greeter's **Dynamic** scheme for your user is refreshed automatically — no need to run the command manually.

> [!TIP]
> These hooks execute in your user's environment, so the sudoers rule above is required for `sudo -n` to succeed without a password prompt.

---

### 7. Enable greetd

```sh
# Replace "sddm.service" with your currently enabled display manager (e.g., sddm/gdm/lightdm)
sudo systemctl disable sddm.service

# Enable and start greetd
sudo systemctl enable --now greetd.service
```

---

## Testing & Local Development

You can test and iterate on the greeter locally without logging out:

```sh
# Build plugin
cmake -B build -G Ninja
cmake --build build

# Launch Quickshell with local build plugin path
QML2_IMPORT_PATH=./build/qml quickshell -p .
```

When run outside greetd, authentication is safely simulated in test mode.
