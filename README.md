# Caelestia Greeter

A modern, fluid Material 3 frontend for **[greetd](https://git.sr.ht/~kennylevinsen/greetd)**, crafted with **[Quickshell](https://quickshell.outfoxxed.me/)** and Qt6 to seamlessly match Caelestia's **[shell](https://github.com/caelestia-dots/shell)**.

---

## Dependencies

- **[Quickshell](https://quickshell.outfoxxed.me/)** >= 0.3.0
- **[greetd](https://git.sr.ht/~kennylevinsen/greetd)**
- **[cage](https://github.com/nicowillis/cage)** (recommended lightweight kiosk Wayland compositor)
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

# Setup state cache directory for session persistence
sudo mkdir -p /var/cache/caelestia-greeter
sudo chown -R greeter:greeter /var/cache/caelestia-greeter
sudo chmod 755 /var/cache/caelestia-greeter
```

### 2. Configure `/etc/greetd/config.toml`

Edit `/etc/greetd/config.toml` with the following configuration:

```toml
[terminal]
vt = 1

[default_session]
command = "cage -s -- caelestia-greeter"
user = "greeter"
```

### 3. Enable and Start greetd

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
