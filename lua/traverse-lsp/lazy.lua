-- Optimal Lazy.nvim configuration for traverse-lsp.nvim
-- Copy this to your Lazy plugins configuration

return {
    "calltrace/traverse-lsp.nvim",

    -- Load when Solidity files are opened or commands are called
    ft = "solidity",
    cmd = {
        "TraverseInstall",
        "TraverseStart",
        "TraverseStop",
        "TraverseStatus",
        "TraverseCallGraph",
        "TraverseSequenceDiagram",
        "TraverseGenerateAll",
        "TraverseAnalyzeStorage",
    },

    -- Auto-install/update binary when plugin is installed/updated
    build = function()
        local installer = require("traverse-lsp.installer")
        if not installer.is_installed() then
            vim.notify("traverse-lsp: Installing binary...", vim.log.levels.INFO)
            installer.download()
        else
            -- Update on plugin update
            vim.notify("traverse-lsp: Checking for binary updates...", vim.log.levels.INFO)
            installer.update()
        end
    end,

    -- Default configuration
    opts = {
        auto_start = true, -- Start server automatically
        auto_install = true, -- Install binary if missing
        -- Add any custom configuration here
    },

    -- Initialize the plugin
    config = function(_, opts)
        require("traverse-lsp").setup(opts)
    end,

    -- Recommended keybindings
    keys = {
        { "<leader>tg", "<cmd>TraverseCallGraph<cr>", desc = "Traverse: Call Graph" },
        { "<leader>ts", "<cmd>TraverseSequenceDiagram<cr>", desc = "Traverse: Sequence Diagram" },
        { "<leader>ta", "<cmd>TraverseAnalyzeStorage<cr>", desc = "Traverse: Analyze Storage" },
        { "<leader>tt", "<cmd>TraverseGenerateAll<cr>", desc = "Traverse: Generate All" },
        { "<leader>tS", "<cmd>TraverseStatus<cr>", desc = "Traverse: Status" },
    },

    -- Optional dependencies for enhanced experience
    dependencies = {
        -- "nvim-telescope/telescope.nvim",  -- For browsing output files
        -- "folke/which-key.nvim",           -- For keybinding hints
    },
}
