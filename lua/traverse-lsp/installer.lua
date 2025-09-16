local M = {}

-- Platform detection - returns the exact filename suffix used in releases
local function get_platform_suffix()
    local os_name = vim.loop.os_uname().sysname:lower()
    local arch = vim.loop.os_uname().machine:lower()

    local platform_map = {
        -- macOS
        ["darwin-x86_64"] = "x86_64-apple-darwin",
        ["darwin-arm64"] = "aarch64-apple-darwin",
        ["darwin-aarch64"] = "aarch64-apple-darwin",

        -- Linux
        ["linux-x86_64"] = "x86_64-unknown-linux-gnu",
        ["linux-aarch64"] = "aarch64-unknown-linux-gnu",
        ["linux-arm64"] = "aarch64-unknown-linux-gnu",

        -- Windows
        ["windows_nt-x86_64"] = "x86_64-pc-windows-msvc",
        ["windows_nt-aarch64"] = "aarch64-pc-windows-msvc",
    }

    local key = string.format("%s-%s", os_name, arch)
    return platform_map[key]
end

-- Installation paths
function M.get_install_dir()
    return vim.fn.stdpath("data") .. "/traverse-lsp"
end

function M.get_binary_path()
    local dir = M.get_install_dir()
    local is_windows = vim.loop.os_uname().sysname:lower():find("windows")
    return dir .. "/traverse-lsp" .. (is_windows and ".exe" or "")
end

-- Check if installed
function M.is_installed()
    return vim.fn.executable(M.get_binary_path()) == 1
end

-- Download and install binary
function M.download()
    local platform_suffix = get_platform_suffix()
    if not platform_suffix then
        local msg =
            string.format("Unsupported platform: %s %s", vim.loop.os_uname().sysname, vim.loop.os_uname().machine)
        vim.notify(msg, vim.log.levels.ERROR)
        return false
    end

    local install_dir = M.get_install_dir()
    vim.fn.mkdir(install_dir, "p")

    vim.notify("Fetching latest traverse-lsp release...", vim.log.levels.INFO)

    -- Get latest release info
    local release_url = "https://api.github.com/repos/calltrace/traverse-lsp/releases/latest"
    local curl_cmd = string.format('curl -sL "%s"', release_url)
    local release_info = vim.fn.system(curl_cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to fetch release information", vim.log.levels.ERROR)
        return false
    end

    -- Parse JSON response
    local ok, release = pcall(vim.json.decode, release_info)
    if not ok or not release.assets then
        vim.notify("Failed to parse release information", vim.log.levels.ERROR)
        return false
    end

    -- Find matching asset - binaries are named like: traverse-lsp-x86_64-apple-darwin
    local is_windows = platform_suffix:find("windows")
    local asset_name = string.format("traverse-lsp-%s%s", platform_suffix, is_windows and ".exe" or "")
    local download_url = nil

    for _, asset in ipairs(release.assets) do
        if asset.name == asset_name then
            download_url = asset.browser_download_url
            break
        end
    end

    if not download_url then
        local msg = string.format("No binary available for: %s\nAvailable assets:\n", asset_name)
        for _, asset in ipairs(release.assets) do
            msg = msg .. "  - " .. asset.name .. "\n"
        end
        vim.notify(msg, vim.log.levels.ERROR)
        return false
    end

    -- Download binary directly (no archive extraction needed)
    vim.notify(string.format("Downloading traverse-lsp %s...", release.tag_name or "latest"), vim.log.levels.INFO)

    local binary_path = M.get_binary_path()
    local download_cmd

    if is_windows then
        -- Windows: download exe directly
        download_cmd =
            string.format('powershell -Command "Invoke-WebRequest -Uri %s -OutFile %s"', download_url, binary_path)
    else
        -- Unix: download binary directly
        download_cmd = string.format('curl -L "%s" -o "%s"', download_url, binary_path)
    end

    local result = vim.fn.system(download_cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("Download failed: " .. (result or "Unknown error"), vim.log.levels.ERROR)
        return false
    end

    -- Make executable (Unix only)
    if not is_windows then
        vim.fn.system("chmod +x " .. binary_path)
    end

    -- Verify installation
    if M.is_installed() then
        -- Try to get version, but don't fail if it doesn't work
        local version_cmd = M.get_binary_path() .. " --version 2>/dev/null"
        local version_ok, version_output = pcall(vim.fn.system, version_cmd)
        if version_ok and vim.v.shell_error == 0 and version_output and not version_output:match("disconnected") then
            local version = vim.trim(version_output)
            vim.notify(
                string.format(
                    "✓ traverse-lsp installed successfully!\nLocation: %s\nVersion: %s",
                    M.get_binary_path(),
                    version
                ),
                vim.log.levels.INFO
            )
        else
            vim.notify(
                string.format("✓ traverse-lsp installed successfully!\nLocation: %s", M.get_binary_path()),
                vim.log.levels.INFO
            )
        end
        return true
    else
        vim.notify("Installation completed but binary not found", vim.log.levels.ERROR)
        return false
    end
end

-- Update existing installation
function M.update()
    if not M.is_installed() then
        vim.notify("traverse-lsp not installed. Run :TraverseInstall first", vim.log.levels.WARN)
        return false
    end

    -- Get current version (if possible)
    local version_cmd = M.get_binary_path() .. " --version 2>/dev/null"
    local current_version = "unknown"
    local ok, version_output = pcall(vim.fn.system, version_cmd)
    if ok and vim.v.shell_error == 0 and version_output and not version_output:match("disconnected") then
        current_version = vim.trim(version_output)
    end

    if current_version ~= "unknown" then
        vim.notify("Current version: " .. current_version, vim.log.levels.INFO)
    end

    -- Remove old binary
    vim.fn.delete(M.get_binary_path())

    -- Download new version
    if M.download() then
        vim.notify("Update completed successfully!", vim.log.levels.INFO)
        return true
    else
        vim.notify("Update failed", vim.log.levels.ERROR)
        return false
    end
end

-- Uninstall
function M.uninstall()
    local install_dir = M.get_install_dir()
    if vim.fn.isdirectory(install_dir) == 1 then
        vim.fn.delete(install_dir, "rf")
        vim.notify("traverse-lsp uninstalled", vim.log.levels.INFO)
        return true
    else
        vim.notify("traverse-lsp not installed", vim.log.levels.WARN)
        return false
    end
end

return M
