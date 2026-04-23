# pakpak

A lightweight package manager for ComputerCraft, making it easy to install, update, and manage Lua programs and libraries on your ComputerCraft computers.

## Features

- 📦 Install packages from a central registry
- 🔄 Update installed packages to the latest version
- 🗑️ Remove packages cleanly
- 📋 List all available packages
- 🚀 Simple command-line interface

## Installation

Follow these steps to install pakpak on your ComputerCraft computer:

1. **Download pakpak:**

```lua
wget https://raw.githubusercontent.com/Gandshack/pakpak/master/pakpak.lua pakpak.lua
```

2. **Move it to the `/bin` directory:**

```lua
mv pakpak.lua /bin/pakpak
```

3. **Download the startup script to the root directory:**

```lua
wget https://raw.githubusercontent.com/Gandshack/pakpak/master/startup.lua startup.lua
```

This will configure your shell path to include `/bin`.

4. **Reboot your computer:**

```lua
reboot
```

After rebooting, you can use pakpak from anywhere!

## Usage

### Basic Commands

```
pakpak <command> <package>
```

### Install a Package

```lua
pakpak install <package-name>
```

### Update a Package

```lua
pakpak update <package-name>
```

This will remove the old version and install the latest version.

### Remove a Package

```lua
pakpak remove <package-name>
```

### List Available Packages

```lua
pakpak list
```

This displays all packages available in the registry with their descriptions and versions.

### Get Help

```lua
pakpak help
```

## How It Works

pakpak fetches package information from the [pakpak_registry](https://github.com/Gandshack/pakpak_registry) repository on GitHub. Each package in the registry points to a GitHub repository that contains:

1. A `pakpak.json` manifest file
2. The actual program files

When you install a package, pakpak:
1. Fetches the package metadata from the registry
2. Downloads the `pakpak.json` manifest from the package's repository
3. Downloads all files listed in the manifest
4. Installs them to the specified location

## Publishing Your Package

To make your package available through pakpak:

1. **Create a `pakpak.json` file** in your GitHub repository:

```json
{
  "name": "your-package-name",
  "description": "A brief description of your package",
  "version": "1.0.0",
  "installPath": "/path/to/install",
  "files": [
    "file1.lua",
    "file2.lua"
  ]
}
```

2. **Submit your package** to the [pakpak_registry](https://github.com/Gandshack/pakpak_registry) repository by adding an entry to `list.json`:

```json
{
  "packages": {
    "your-package-name": {
      "url": "https://github.com/yourusername/your-repo.git",
      "description": "A brief description",
      "version": "1.0.0"
    }
  }
}
```

## Requirements

- ComputerCraft (CC:Tweaked recommended)
- HTTP API must be enabled in your ComputerCraft configuration

## Example pakpak.json

```json
{
  "name": "pakpak",
  "description": "A computercraft package manager",
  "version": "0.0.1",
  "installPath": "/bin",
  "files": [
    "pakpak.lua"
  ]
}
```

## License

This project is open source and available for use in your ComputerCraft projects.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests on GitHub.

## Links

- [pakpak Repository](https://github.com/Gandshack/pakpak)
- [Package Registry](https://github.com/Gandshack/pakpak_registry)
