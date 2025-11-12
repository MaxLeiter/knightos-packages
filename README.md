# KnightOS Package Registry

An alternative package registry for KnightOS. This registry was created because the official `packages.knightos.org` is currently down. This registry provides the same API interface and serves pre-built packages from the KnightOS ecosystem.

## Available Packages

Currently hosting:

**Core packages:**

- `core/corelib` - Core KnightOS user and system interaction library
- `core/configlib` - Configuration management library
- `core/castle` - KnightOS program launcher (desktop environment)
- `core/init` - Init system
- `core/threadlist` - Task switcher application
- `core/settings` - System settings application
- `core/textview` - Text file viewer

**Extra packages:**

- `extra/fileman` - File manager application
- `extra/periodic` - Periodic table of elements application

## Usage with KnightOS SDK

### Setup

Set the custom repository URL as an environment variable:

```bash
export KNIGHTOS_REPOSITORY_URL=https://knightos-packages.vercel.app
```

Or add to your shell config (e.g., `~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`):

```bash
# Bash/Zsh
export KNIGHTOS_REPOSITORY_URL=https://knightos-packages.vercel.app

# Fish
set -x KNIGHTOS_REPOSITORY_URL https://knightos-packages.vercel.app
```

### Install Packages

Once configured, use the KnightOS SDK normally:

```bash
knightos install core/corelib
knightos install core/castle
```

## API Endpoints

The registry implements the same API as the official KnightOS package registry:

- `GET /api/v1/:repo/:name` - Returns package manifest as JSON
- `GET /:repo/:name/download` - Downloads the `.pkg` file

## Development

This is a Next.js 16 application built with TypeScript and Tailwind CSS.

### Prerequisites

- Node.js 18+
- pnpm

### Install Dependencies

```bash
pnpm install
```

### Run Development Server

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to view the registry.

### Build for Production

```bash
pnpm build
```

## Adding New Packages

To add new packages to the registry:

1. Build the package using the KnightOS SDK to create a `.pkg` file
2. Run the import script:

```bash
./scripts/import-packages.sh
```

This script:

- Reads `package.config` from each KnightOS package directory
- Generates `manifest.json` files
- Copies `.pkg` files to the appropriate location in `packages/`

## License

This registry implementation is MIT licensed. Individual packages retain their original licenses (see each package's manifest for details).

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Links

- [KnightOS Official Site](https://knightos.org/)
- [KnightOS GitHub](https://github.com/KnightOS)
- [KnightOS SDK](https://github.com/KnightOS/sdk)
