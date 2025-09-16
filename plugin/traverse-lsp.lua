-- Auto-initialize traverse-lsp plugin
if vim.fn.has("nvim-0.11") == 0 then
    return
end

-- Only setup if not already initialized
if not _G.TraverseLspLoaded then
    _G.TraverseLspLoaded = true
    require("traverse-lsp").setup()
end
