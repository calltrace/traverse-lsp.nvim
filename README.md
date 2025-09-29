# Traverse Plugin for Neovim

[![Test](https://github.com/calltrace/traverse-lsp.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/calltrace/traverse-lsp.nvim/actions/workflows/test.yml)
[![Latest Release](https://img.shields.io/github/v/release/calltrace/traverse-lsp.nvim?label=release)](https://github.com/calltrace/traverse-lsp.nvim/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Neovim 0.11+ plugin for traverse-lsp - Workspace-level analysis and diagram generation for Solidity projects.

> **Requirements:** Neovim 0.11+ only

## Features

- **Zero Configuration** - Works out-of-the-box with auto-install and auto-start
- **Automatic Binary Management** - Downloads pre-built binaries, no compilation required
- **Workspace-Level Analysis** - Operates on entire projects, not individual files
- **Call Graph Generation** - DOT format (GraphViz compatible)
- **Sequence Diagrams** - Mermaid format
- **Storage Analysis** - Markdown format
- **Organized Output** - All diagrams saved in structured `traverse-output/` directory

## Installation

### Using lazy.nvim (Recommended)

**Quick Install** - Zero configuration:

```lua
-- Inside ~/.config/nvim/init.lua with other plugins:
{ "calltrace/traverse-lsp.nvim" }

-- Inside ~/.config/nvim/lua/plugins/traverse-lsp.lua:
return { "calltrace/traverse-lsp.nvim" }
```

**Full Setup** - With keybindings and optimizations:

```lua
{
  "calltrace/traverse-lsp.nvim",
  ft = "solidity",
  keys = {
    { "<leader>tg", "<cmd>TraverseCallGraph<cr>", desc = "Call Graph" },
    { "<leader>ts", "<cmd>TraverseSequenceDiagram<cr>", desc = "Sequence Diagram" },
    { "<leader>ta", "<cmd>TraverseAnalyzeStorage<cr>", desc = "Storage Analysis" },
    { "<leader>tt", "<cmd>TraverseGenerateAll<cr>", desc = "Generate All Diagrams" },
  },
}
```

**Advanced Setup** - With all options:

```lua
{
  "calltrace/traverse-lsp.nvim",
  ft = "solidity",
  build = ":TraverseUpdate",  -- Update binary on plugin update
  opts = {
    auto_start = true,     -- default: true
    auto_install = true,   -- default: true
    no_chunk = false,      -- Disable mermaid chunking (default: false - chunking enabled)
  },
  keys = {
    { "<leader>tg", "<cmd>TraverseCallGraph<cr>", desc = "Call Graph" },
    { "<leader>ts", "<cmd>TraverseSequenceDiagram<cr>", desc = "Sequence Diagram" },
    { "<leader>ta", "<cmd>TraverseAnalyzeStorage<cr>", desc = "Storage Analysis" },
    { "<leader>tt", "<cmd>TraverseGenerateAll<cr>", desc = "Generate All Diagrams" },
    { "<leader>tS", "<cmd>TraverseStatus<cr>", desc = "Server Status" },
  },
}
```

### Using packer.nvim

```lua
use {
    "calltrace/traverse-lsp.nvim",
    run = ":TraverseInstall",
    config = function()
        require("traverse-lsp").setup()
    end,
}
```

## Quick Start

Just install the plugin and start generating diagrams immediately:

```vim
:TraverseCallGraph        " Generate call graph
:TraverseSequenceDiagram  " Generate sequence diagram
:TraverseAnalyzeStorage   " Analyze storage layout
:TraverseGenerateAll      " Generate all diagrams at once
```

**That's it!** No setup required. The plugin automatically:
✓ Downloads the binary on first use
✓ Starts the LSP server
✓ Creates organized output in `traverse-output/`

## Commands

### Binary Management

- `:TraverseInstall` - Download and install the traverse-lsp binary
- `:TraverseUpdate` - Update to the latest version
- `:TraverseUninstall` - Remove the installed binary

### Server Control

- `:TraverseStart [dir]` - Start server for workspace (default: current directory)
- `:TraverseStop` - Stop the running server
- `:TraverseStatus` - Check server status

### Analysis Commands

- `:TraverseCallGraph` - Generate call graph (saves to `traverse-output/call-graphs/*.dot`)
- `:TraverseSequenceDiagram` - Generate sequence diagram (saves to `traverse-output/sequence-diagrams/*.mmd`)
- `:TraverseGenerateAll` - Generate all diagram types
- `:TraverseAnalyzeStorage` - Analyze storage layout (saves to `traverse-output/storage-reports/*.md`)

All output files are organized in the `traverse-output/` directory with timestamped filenames.

## Configuration

```lua
require("traverse-lsp").setup({
    -- Auto-download binary if not found
    auto_install = true,

    -- Auto-start server when opening Solidity files
    auto_start = false,

    -- Custom binary path (optional, auto-detected by default)
    cmd = { "/custom/path/to/traverse-lsp" },
})
```

## Binary Installation Methods

The plugin automatically installs and finds the binary in this order:

1. **Auto-installer** (default) - Automatically downloaded on first use to `~/.local/share/nvim/traverse-lsp/`
2. **Mason** - If installed via `:MasonInstall traverse-lsp`
3. **Homebrew** - If installed via `brew install traverse-lsp`
4. **System PATH** - If manually installed

> Note: Binary installation is automatic by default. Manual installation is only needed if you disable `auto_install`.

### Manual Installation (Optional)

> Note: Manual installation is only needed if you disable `auto_install` in the configuration.

If you prefer to manage the binary yourself:

1. Download from [releases](https://github.com/calltrace/traverse-lsp/releases)
2. The downloads are raw binaries, not archives - just make them executable:
   ```bash
   chmod +x traverse-lsp-<platform>
   mv traverse-lsp-<platform> /usr/local/bin/traverse-lsp
   ```
3. Or configure a custom path in setup:
   ```lua
   require("traverse-lsp").setup({
       auto_install = false,  -- Disable auto-install
       cmd = { "/path/to/traverse-lsp" }
   })
   ```

### Supported Platforms

- Linux x64 (`linux-x64`)
- Linux ARM64 (`linux-arm64`)
- macOS Intel (`darwin-x64`)
- macOS Apple Silicon (`darwin-arm64`)
- Windows x64 (`windows-x64`)

## Diagram Generation Examples

### Generate Call Graph

```vim
:TraverseCallGraph
" Output: traverse-output/call-graphs/call-graph-2025-09-16.dot

" Convert to PNG
:!dot -Tpng traverse-output/call-graphs/*.dot -o graph.png
:!open graph.png
```

### Generate Sequence Diagram

```vim
:TraverseSequenceDiagram
" Output: traverse-output/sequence-diagrams/sequence-2025-09-16.mmd

" View in Mermaid Live Editor (auto-opens browser)
" Choose 'Yes' when prompted to open in browser
```

### Analyze Storage Layout

```vim
:TraverseAnalyzeStorage
" Output: traverse-output/storage-reports/storage-2025-09-16.md
" Optionally opens in a new buffer for immediate viewing
```

### Generate Everything at Once

```vim
:TraverseGenerateAll
" Creates all diagrams in their respective directories
```

## Mermaid Chunking for Large Diagrams

When generating sequence diagrams for large projects, the plugin automatically splits them into manageable chunks. This feature is especially useful for complex contracts with many interactions.

### How Chunking Works

- Large diagrams are automatically split into multiple files
- Each chunk maintains proper Mermaid syntax and can be rendered independently
- An index file provides navigation between chunks
- Metadata file contains chunk boundaries and statistics

### Configuration

To disable chunking and generate a single large file:

```lua
require("traverse-lsp").setup({
  no_chunk = true,  -- Disable chunking (default: false - chunking enabled)
})
```

### Output Structure

When chunking is enabled (default) for large diagrams:

```
project/
└── traverse-output/
    └── sequence-diagrams/
        ├── sequence-2025-09-29.mmd  -- Main diagram (first chunk)
        └── chunks/                   -- Chunked output
            ├── index.mmd            -- Navigation index
            ├── chunk_001.mmd        -- First chunk
            ├── chunk_002.mmd        -- Second chunk
            ├── chunk_003.mmd        -- Third chunk
            ├── ...
            └── metadata.json        -- Chunk metadata
```

When chunking is disabled (`no_chunk = true`):

```
project/
└── traverse-output/
    └── sequence-diagrams/
        └── sequence-2025-09-29.mmd  -- Single large file (no chunks)
```

## Viewing Generated Diagrams

### DOT Files (Call Graphs)

```bash
# Convert to PNG
dot -Tpng call_graph.dot -o call_graph.png

# Convert to SVG
dot -Tsvg call_graph.dot -o call_graph.svg

# View directly (macOS)
dot -Tpng call_graph.dot | open -f -a Preview
```

### Mermaid Files (Sequence Diagrams)

```bash
# Using mermaid-cli
npm install -g @mermaid-js/mermaid-cli
mmdc -i sequence.mmd -o sequence.png

# For chunked diagrams, process each chunk:
for chunk in traverse-output/sequence-diagrams/chunks/chunk_*.mmd; do
  mmdc -i "$chunk" -o "${chunk%.mmd}.png"
done

# Or paste content to https://mermaid.live
```

## Troubleshooting

### Check Installation

```vim
:checkhealth traverse-lsp
```

This will show:

- Neovim version compatibility
- Binary installation status
- Server running state
- Installation method used

### Common Issues

**Binary not found:**

```vim
:TraverseInstall
```

**Server won't start:**

- Check you're in a Solidity project directory
- Verify binary is executable: `:checkhealth traverse-lsp`

**Can't generate diagrams:**

- Ensure server is running: `:TraverseStatus`
- Check for Solidity files in workspace

## Development

### Setting Up Development Environment

1. **Clone the repository:**

   ```bash
   git clone https://github.com/calltrace/traverse-lsp.nvim.git
   cd traverse-lsp.nvim
   ```

2. **Install development symlink:**

   ```bash
   make install-dev
   # Creates symlink at ~/.local/share/nvim/site/pack/traverse/start/traverse-lsp.nvim
   ```

3. **Configure Lazy.nvim for development:**

   Create `~/.config/nvim/lua/plugins/traverse-lsp.lua`:

   ```lua
   return {
     dir = "~/path/to/traverse-lsp.nvim",  -- Your local clone path
     name = "traverse-lsp",
     lazy = false,
   }
   ```

### Development Commands

**Using Make:**

```bash
make help           # Show all available commands
make syntax-check   # Check Lua syntax
make lint           # Run luacheck
make format         # Format with stylua
make test           # Run health check
make install-dev    # Create development symlink
make uninstall-dev  # Remove development symlink
```

**Using NPM (alternative):**

```bash
npm run help        # Show all available commands
npm run syntax-check # Check Lua syntax
npm run lint        # Run luacheck
npm run format      # Format with stylua
npm run test        # Run health check
npm run install-dev # Create development symlink
npm run uninstall-dev # Remove development symlink
```

> **Note:** NPM support is provided for convenience. All npm scripts delegate to the Makefile targets.

### Testing Changes

1. **Local testing with symlink:**

   ```bash
   make install-dev
   nvim
   :TraverseStatus
   ```

2. **Testing as a user would install it:**

   ```lua
   -- In ~/.config/nvim/lua/plugins/traverse-lsp.lua
   return { "calltrace/traverse-lsp.nvim" }
   ```

3. **Running tests:**
   ```bash
   make test          # Health check
   make lint          # Code quality
   make syntax-check  # Syntax validation
   ```

### Contributing Process

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/traverse-lsp.nvim.git
   cd traverse-lsp.nvim
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make changes and test:**
   ```bash
   make lint
   make syntax-check
   make test
   ```
5. **Commit and push to your fork:**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-feature-name
   ```
6. **Create a Pull Request** on GitHub from your fork to the main repository

### Contributing Guidelines

- Follow existing code style (use `make format`)
- Ensure `make lint` passes
- Test with `make syntax-check`
- Update README for new features
- Keep zero-configuration philosophy

## License

MIT

## Contributing

Issues and PRs welcome at [calltrace/traverse-lsp.nvim](https://github.com/calltrace/traverse-lsp.nvim)
