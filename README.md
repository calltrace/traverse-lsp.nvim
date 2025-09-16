# Traverse Plugin for NeoVim

Neovim 0.11+ plugin for traverse-lsp - Workspace-level analysis and diagram generation for Solidity projects.

> **Requirements:** Neovim 0.11+ only (no Rust toolchain needed!)

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
{ "calltrace/traverse-lsp.nvim" }
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

## License

MIT

## Contributing

Issues and PRs welcome at [calltrace/traverse-lsp.nvim](https://github.com/calltrace/traverse-lsp.nvim)
