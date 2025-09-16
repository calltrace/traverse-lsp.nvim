local M = {}

-- Get the main module for checking state
local function get_traverse_lsp()
    return require("traverse-lsp")
end

-- Find binary in common locations (duplicated from main module for isolation)
local function find_binary()
    local installer = require("traverse-lsp.installer")
    local paths = {
        installer.get_binary_path(),
        vim.fn.stdpath("data") .. "/mason/bin/traverse-lsp",
        "/opt/homebrew/bin/traverse-lsp",
        "/usr/local/bin/traverse-lsp",
        "traverse-lsp",
    }

    for _, path in ipairs(paths) do
        if vim.fn.executable(path) == 1 then
            return path
        end
    end

    return nil
end

function M.check()
    vim.health.start("traverse-lsp.nvim")

    -- Version check
    local nvim_version = vim.version()
    if nvim_version.major == 0 and nvim_version.minor >= 11 then
        vim.health.ok(string.format("Neovim %d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch))
    else
        vim.health.error("Neovim 0.11+ required")
    end

    -- Binary check
    local installer = require("traverse-lsp.installer")
    local binary = find_binary()

    if binary then
        vim.health.ok(string.format("Binary found: %s", binary))

        -- Check version
        local version_cmd = binary .. " --version 2>/dev/null"
        local ok, version_output = pcall(vim.fn.system, version_cmd)
        if ok and vim.v.shell_error == 0 and version_output and not version_output:match("disconnected") then
            vim.health.info("Version: " .. vim.trim(version_output))
        end

        -- Check installation source
        if binary == installer.get_binary_path() then
            vim.health.info("Installed via: TraverseInstall")
        elseif binary:find("mason") then
            vim.health.info("Installed via: Mason")
        elseif binary:find("homebrew") then
            vim.health.info("Installed via: Homebrew")
        else
            vim.health.info("Installed via: System PATH")
        end
    else
        vim.health.error("traverse-lsp binary not found", {
            "Run: :TraverseInstall",
            "Or install via Mason: :MasonInstall traverse-lsp",
            "Or download from: https://github.com/calltrace/traverse-lsp/releases",
        })
    end

    -- Status check - get state from main module
    local traverse_lsp = get_traverse_lsp()
    local status = traverse_lsp.get_client_status and traverse_lsp.get_client_status()

    if status and status.client then
        vim.health.ok(string.format("Server running (workspace: %s)", status.root_dir or "unknown"))
    elseif status and status.client_id then
        vim.health.warn("Server client error - restart with :TraverseStart")
    else
        vim.health.info("Server not running (run :TraverseStart)")
    end
end

return M
