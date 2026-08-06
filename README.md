# Caelestia Greeter

A modern, fluid Material 3 frontend for **[greetd](https://git.sr.ht/~kennylevinsen/greetd)**, crafted with **[Quickshell](https://quickshell.outfoxxed.me/)** and Qt6 to seamlessly match Caelestia's **[shell](https://github.com/caelestia-dots/shell)**.

---

## Dependencies

- **[Quickshell](https://quickshell.outfoxxed.me/)** >= 0.3.0
- **[greetd](https://git.sr.ht/~kennylevinsen/greetd)**
- **[cage](https://github.com/nicowillis/cage)** (recommended lightweight kiosk Wayland compositor)
- **[wlr-randr](https://sr.ht/~emersion/wlr-randr/)** (only needed when using the monitor options)
- **Qt 6.6+** (Core, Qml, Quick, Quick3D)
- **CMake >= 3.19** and **Ninja**

---

## Building & Installation

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
- The `Caelestia.Greeter` QML plugin to `/usr/lib/qt6/qml/Caelestia/Greeter/`
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

If not already created by your package manager:

```sh
# Create system user for greetd
sudo useradd -r -M -s /usr/bin/nologin -d /var/cache/caelestia-greeter greeter
sudo usermod -aG video,input greeter

# Setup state cache directory for persistent settings & session memory
sudo mkdir -p /var/cache/caelestia-greeter
sudo chown -R greeter:greeter /var/cache/caelestia-greeter
sudo chmod 755 /var/cache/caelestia-greeter
```

> [!NOTE]
> Greeter UI preferences (avatar shape, 12/24h clock, idle lava lamp animation, and last-used session per user) are automatically saved to `/var/cache/caelestia-greeter/greeter.json`. Color schemes, flavours, and dark/light modes are fetched dynamically from the `caelestia scheme` CLI and system scheme state.

### 2. Setting User Profile Pictures (Avatars)

For user profile pictures (pfps) to work properly with greetd, the user needs to set their profile picture using the `--set-pfp` flag:

```sh
# Set profile picture for the current user
caelestia-greeter --set-pfp /path/to/avatar.png

# Or using sudo (it will automatically identify your user from SUDO_USER)
sudo caelestia-greeter --set-pfp ~/Pictures/avatar.png
```

> [!NOTE]
> Because greetd runs under the restricted system `greeter` user, it cannot access files inside personal home directories (such as `~/.face`). Using `--set-pfp` copies the selected image into the shared avatar store (`/var/cache/caelestia-greeter/avatars/<username>`) with the correct read permissions so the greeter can display it.

### 3. Configure `/etc/greetd/config.toml`

You can run `caelestia-greeter` inside either **Cage** (lightweight kiosk compositor) or **Hyprland**.

#### Quick Setup via `--kiosk`

You can automatically generate the greetd configuration files using the `-k` / `--kiosk` flag:

```sh
# Automatic setup for Cage:
sudo caelestia-greeter -k cage

# Or automatic setup for Hyprland:
sudo caelestia-greeter -k hyprland
```

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

-- Start the greeter on init
hl.on("hyprland.start", function()
  hl.exec_cmd("caelestia-greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)
```

### 4. Multi-Monitor Configuration

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
`--toggle`, `--mode WxH[@RATE]`, `--custom-mode`, `--preferred`,
`--pos X,Y`, `--left-of`, `--right-of`, `--above`, `--below`,
`--transform`, `--scale`, `--adaptive-sync`.

The options are applied to the running compositor via the
`wlr-output-management` protocol before quickshell starts; all other
arguments are passed through to quickshell. Run `caelestia-greeter --help`
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
caelestia-greeter --output DP-1 --mode 1920x1080@280.00Hz --pos 1920,333 --scale 1 --output DP-2 --mode 1920x1080@143.98Hz --pos 0,333 --scale 1
```

Disabled monitors become `--off`, `preferred`/`auto` modes map to
`--preferred`, and Hyprland `transform` numbers (0-7) map to wlr-randr
transform names (e.g. `3` → `270`). Copy the printed flags into the
`command` string of `/etc/greetd/config.toml` as shown above.

### 5. Enable and Start greetd

```sh
# Disable existing display manager (e.g. sddm/gdm/lightdm) if active
sudo systemctl disable sddm.service || true

# Enable and start greetd
sudo systemctl enable greetd.service
sudo systemctl start greetd.service
```

---

## Testing & Local Development

You can test and iterate on the greeter locally without logging out:

```sh
# Build plugin
cmake -B build -G Ninja
cmake --build build

# Launch quickshell with local build plugin path
QML2_IMPORT_PATH=./build/qml quickshell -p .
```

When ran outside greetd, authentication is safely simulated in test mode.
