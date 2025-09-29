local M = {}

assert(vim.fn.has("nvim-0.11") == 1, "traverse-lsp.nvim requires Neovim 0.11+")

local client_id = nil

-- Helper function to get output directory path following VSCode conventions
local function get_output_dir(diagram_type)
    local root = vim.lsp.get_client_by_id(client_id).config.root_dir or vim.fn.getcwd()
    local base_dir = root .. "/traverse-output"

    local type_dirs = {
        ["call-graph"] = "call-graphs",
        ["sequence"] = "sequence-diagrams",
        ["storage"] = "storage-reports",
        ["all"] = "diagrams",
    }

    return base_dir .. "/" .. (type_dirs[diagram_type] or "diagrams")
end

-- Helper function to save diagram following VSCode conventions
local function save_diagram(content, diagram_type, default_ext)
    if not content then
        vim.notify("No content to save", vim.log.levels.WARN)
        return
    end

    local timestamp = os.date("%Y-%m-%d", os.time())

    local ext = default_ext
    if type(content) == "string" then
        if content:match("digraph") or content:match("strict graph") then
            ext = ".dot"
        elseif
            content:match("sequenceDiagram")
            or content:match("graph TD")
            or content:match("graph LR")
            or content:match("flowchart")
        then
            ext = ".mmd"
        end
    end

    local output_dir = get_output_dir(diagram_type)
    vim.fn.mkdir(output_dir, "p")

    local base_name = diagram_type:gsub(" ", "-"):lower()
    local filename = string.format("%s/%s-%s%s", output_dir, base_name, timestamp, ext)

    local counter = 1
    local final_filename = filename
    while vim.fn.filereadable(final_filename) == 1 do
        final_filename = string.format("%s/%s-%s-%d%s", output_dir, base_name, timestamp, counter, ext)
        counter = counter + 1
    end

    local lines = type(content) == "string" and vim.split(content, "\n") or { vim.json.encode(content) }
    vim.fn.writefile(lines, final_filename)

    local relative_path = vim.fn.fnamemodify(final_filename, ":~:.")
    vim.notify("Saved to: " .. relative_path, vim.log.levels.INFO)

    local choice = vim.fn.confirm("Open the generated file?", "&Yes\n&No\n&Open in browser", 1)
    if choice == 1 then
        vim.cmd("edit " .. final_filename)
    elseif choice == 3 and ext == ".mmd" then
        local encoded = vim.fn.system("cat " .. final_filename .. " | base64 | tr -d '\\n'")
        local url = "https://mermaid.live/edit#base64:" .. encoded
        vim.fn.system("open '" .. url .. "'")
    end

    return final_filename
end

-- Find binary in common locations
local function find_binary()
    local paths = {
        require("traverse-lsp.installer").get_binary_path(),
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

-- Generate call graph in DOT format
function M.generate_call_graph()
    if not client_id then
        vim.notify("traverse-lsp not running. Run :TraverseStart first", vim.log.levels.WARN)
        return
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        vim.notify("LSP client not found. Run :TraverseStart to restart", vim.log.levels.ERROR)
        client_id = nil
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()

    local params = {
        command = "traverse.generateCallGraph.workspace",
        arguments = {
            {
                workspace_folder = client.config.root_dir or vim.fn.getcwd(),
                no_chunk = M._config and M._config.no_chunk,
            },
        },
    }

    vim.notify("Generating call graph for workspace: " .. params.arguments[1].workspace_folder, vim.log.levels.INFO)

    local request_success = client.request("workspace/executeCommand", params, function(err, result)
        if err then
            vim.notify("Failed to generate call graph: " .. vim.inspect(err), vim.log.levels.ERROR)
            return
        end

        if not result then
            vim.notify("Call graph generation returned empty result", vim.log.levels.WARN)
            return
        end

        if type(result) ~= "table" or not result.success then
            vim.notify("Call graph generation failed: " .. vim.inspect(result), vim.log.levels.ERROR)
            return
        end

        local dot_content = nil
        local mermaid_content = nil

        if result.data then
            dot_content = result.data.dot
            mermaid_content = result.data.mermaid
        elseif result.diagram then
            if result.diagram:match("digraph") or result.diagram:match("strict graph") then
                dot_content = result.diagram
            else
                mermaid_content = result.diagram
            end
        end

        if not dot_content and not mermaid_content then
            vim.notify("No diagram content received", vim.log.levels.WARN)
            return
        end

        if dot_content then
            save_diagram(dot_content, "call-graph", ".dot")
            vim.notify("Tip: Generate PNG with: dot -Tpng <file.dot> -o graph.png", vim.log.levels.INFO)
        elseif mermaid_content then
            save_diagram(mermaid_content, "call-graph", ".mmd")
        end
    end, bufnr)

    if not request_success then
        vim.notify("Failed to send request to LSP server", vim.log.levels.ERROR)
    end
end

-- Generate sequence diagram in Mermaid format
function M.generate_sequence_diagram()
    if not client_id then
        vim.notify("traverse-lsp not running. Run :TraverseStart first", vim.log.levels.WARN)
        return
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        vim.notify("LSP client not found. Run :TraverseStart to restart", vim.log.levels.ERROR)
        client_id = nil
        return
    end

    local params = {
        command = "traverse.generateSequenceDiagram.workspace",
        arguments = {
            {
                workspace_folder = client.config.root_dir or vim.fn.getcwd(),
                no_chunk = M._config and M._config.no_chunk or false,
            },
        },
    }

    client.request("workspace/executeCommand", params, function(err, result)
        if err then
            vim.notify("Failed to generate sequence diagram: " .. vim.inspect(err), vim.log.levels.ERROR)
            return
        end

        if type(result) ~= "table" or not result.success then
            vim.notify("Sequence diagram generation failed", vim.log.levels.ERROR)
            return
        end

        local content = result.diagram or (result.data and result.data.mermaid)
        if not content then
            vim.notify("No diagram content received", vim.log.levels.WARN)
            return
        end

        save_diagram(content, "sequence", ".mmd")
    end)
end

-- Generate all diagrams
function M.generate_all()
    if not client_id then
        vim.notify("traverse-lsp not running. Run :TraverseStart first", vim.log.levels.WARN)
        return
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        vim.notify("LSP client not found. Run :TraverseStart to restart", vim.log.levels.ERROR)
        client_id = nil
        return
    end

    local params = {
        command = "traverse.generateAll.workspace",
        arguments = {
            {
                workspace_folder = client.config.root_dir or vim.fn.getcwd(),
                no_chunk = M._config and M._config.no_chunk,
            },
        },
    }

    client.request("workspace/executeCommand", params, function(err, result)
        if err then
            vim.notify("Failed to generate diagrams: " .. vim.inspect(err), vim.log.levels.ERROR)
            return
        end

        if type(result) ~= "table" or not result.success then
            vim.notify("Diagram generation failed", vim.log.levels.ERROR)
            return
        end

        vim.notify("Generating all diagrams...", vim.log.levels.INFO)

        if result.data then
            if result.data.dot then
                save_diagram(result.data.dot, "all", ".dot")
            end
            if result.data.mermaid then
                save_diagram(result.data.mermaid, "all", ".mmd")
            end
        elseif result.diagram then
            save_diagram(result.diagram, "all", ".md")
        end

        vim.notify("All diagrams generated successfully", vim.log.levels.INFO)
    end)
end

-- Analyze storage layout
function M.analyze_storage()
    if not client_id then
        vim.notify("traverse-lsp not running. Run :TraverseStart first", vim.log.levels.WARN)
        return
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        vim.notify("LSP client not found. Run :TraverseStart to restart", vim.log.levels.ERROR)
        client_id = nil
        return
    end

    local params = {
        command = "traverse.analyzeStorage.workspace",
        arguments = {
            {
                workspace_folder = client.config.root_dir or vim.fn.getcwd(),
            },
        },
    }

    client.request("workspace/executeCommand", params, function(err, result)
        if err then
            vim.notify("Failed to analyze storage: " .. vim.inspect(err), vim.log.levels.ERROR)
            return
        end

        if type(result) ~= "table" or not result.success then
            vim.notify("Storage analysis failed", vim.log.levels.ERROR)
            return
        end

        local content = result.diagram or result.data
        if not content then
            vim.notify("No analysis content received", vim.log.levels.WARN)
            return
        end

        local filename = save_diagram(content, "storage", ".md")

        if filename then
            local choice = vim.fn.confirm("View storage analysis in buffer?", "&Yes\n&No", 1)
            if choice == 1 then
                vim.cmd("new")
                local buf = vim.api.nvim_get_current_buf()
                vim.bo[buf].filetype = "markdown"
                vim.bo[buf].modified = false
                vim.api.nvim_buf_set_name(buf, "StorageAnalysis.md")

                local text = type(content) == "string" and content or vim.json.encode(content)
                local lines = vim.split(text, "\n")
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                vim.bo[buf].modified = false
            end
        end
    end)
end

-- Start the LSP server for the workspace
function M.start(workspace_root)
    if client_id then
        local client = vim.lsp.get_client_by_id(client_id)
        if client then
            return
        else
            client_id = nil
        end
    end

    workspace_root = workspace_root or vim.fn.getcwd()

    local root_patterns = { "foundry.toml", "hardhat.config.js", "truffle-config.js", ".git" }
    local root = vim.fs.find(root_patterns, {
        upward = true,
        path = workspace_root,
        limit = 1,
    })[1]

    if root then
        workspace_root = vim.fs.dirname(root)
    end

    local config = M._config or {}
    local binary = config.cmd and config.cmd[1] or find_binary()
    if not binary then
        vim.notify("traverse-lsp binary not found! Run :TraverseInstall", vim.log.levels.ERROR)
        return
    end

    client_id = vim.lsp.start_client({
        name = "traverse_lsp",
        cmd = { binary },
        root_dir = workspace_root,
        workspace_folders = {
            {
                uri = vim.uri_from_fname(workspace_root),
                name = vim.fs.basename(workspace_root),
            },
        },
        capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
            executeCommandProvider = {
                commands = {
                    "traverse.generateCallGraph.workspace",
                    "traverse.generateSequenceDiagram.workspace",
                    "traverse.generateAll.workspace",
                    "traverse.analyzeStorage.workspace",
                },
            },
        }, config.capabilities or {}),
        settings = config.settings or {},
        init_options = config.init_options or {},
    })

    if client_id then
        vim.notify(string.format("traverse-lsp started for workspace: %s", workspace_root), vim.log.levels.INFO)
        local dummy_buf = vim.api.nvim_create_buf(false, true)
        vim.lsp.buf_attach_client(dummy_buf, client_id)
    else
        vim.notify("Failed to start traverse-lsp", vim.log.levels.ERROR)
    end
end

-- Stop the LSP server
function M.stop()
    if not client_id then
        vim.notify("traverse-lsp not running", vim.log.levels.INFO)
        return
    end

    vim.lsp.stop_client(client_id, true)
    client_id = nil
    vim.notify("traverse-lsp stopped", vim.log.levels.INFO)
end

-- Get status
function M.status()
    local installer = require("traverse-lsp.installer")
    local status_lines = {}
    if installer.is_installed() then
        table.insert(status_lines, "✓ Binary: " .. installer.get_binary_path())
    else
        table.insert(status_lines, "✗ Binary: Not installed (run :TraverseInstall)")
    end
    if not client_id then
        table.insert(status_lines, "✗ Server: Not running (run :TraverseStart)")
    else
        local client = vim.lsp.get_client_by_id(client_id)
        if client then
            local pid = "unknown"
            if client.pid then
                pid = tostring(client.pid)
            elseif client._pid then
                pid = tostring(client._pid)
            elseif client.rpc and client.rpc.pid then
                pid = tostring(client.rpc.pid)
            else
                local pgrep_output = vim.fn.system("pgrep -f traverse-lsp 2>/dev/null | head -1")
                if pgrep_output and pgrep_output ~= "" then
                    pid = vim.trim(pgrep_output)
                end
            end

            table.insert(status_lines, "✓ Server: Running (PID: " .. pid .. ")")
            table.insert(status_lines, "  Client ID: " .. client_id)
            table.insert(status_lines, "  Workspace: " .. (client.config.root_dir or "none"))
            table.insert(status_lines, "  Buffers attached: " .. #vim.lsp.get_buffers_by_client_id(client_id))
            if client.server_capabilities and client.server_capabilities.executeCommandProvider then
                table.insert(status_lines, "  Commands available: ✓")
            end
        else
            table.insert(status_lines, "✗ Server: Client error (restart with :TraverseStart)")
            client_id = nil
        end
    end

    return table.concat(status_lines, "\n")
end

-- Setup
function M.setup(opts)
    opts = opts or {}
    M._config = opts
    local config = vim.tbl_deep_extend("force", {
        auto_start = true, -- Auto-start server on plugin setup (default: true)
        auto_install = true, -- Auto-install binary if not found (default: true)
        debug = false, -- Enable debug logging (default: false)
        no_chunk = false, -- Disable chunking for mermaid diagrams (default: false - chunking enabled)
    }, opts)

    M._config = config
    if config.debug then
        vim.notify("traverse-lsp: Debug mode enabled", vim.log.levels.INFO)
    end

    local installer = require("traverse-lsp.installer")
    vim.api.nvim_create_user_command("TraverseInstall", function()
        installer.download()
    end, {
        desc = "Download and install traverse-lsp binary",
    })

    vim.api.nvim_create_user_command("TraverseUpdate", function()
        installer.update()
    end, {
        desc = "Update traverse-lsp binary",
    })

    vim.api.nvim_create_user_command("TraverseUninstall", function()
        installer.uninstall()
    end, {
        desc = "Uninstall traverse-lsp binary",
    })
    vim.api.nvim_create_user_command("TraverseStart", function(args)
        M.start(args.args ~= "" and args.args or nil)
    end, {
        nargs = "?",
        complete = "dir",
        desc = "Start traverse-lsp for workspace",
    })

    vim.api.nvim_create_user_command("TraverseStop", M.stop, {
        desc = "Stop traverse-lsp",
    })

    vim.api.nvim_create_user_command("TraverseStatus", function()
        print(M.status())
    end, {
        desc = "Show traverse-lsp status",
    })

    vim.api.nvim_create_user_command("TraverseCallGraph", M.generate_call_graph, {
        desc = "Generate call graph for workspace",
    })

    vim.api.nvim_create_user_command("TraverseSequenceDiagram", M.generate_sequence_diagram, {
        desc = "Generate sequence diagram for workspace",
    })

    vim.api.nvim_create_user_command("TraverseGenerateAll", M.generate_all, {
        desc = "Generate all diagrams for workspace",
    })

    vim.api.nvim_create_user_command("TraverseAnalyzeStorage", M.analyze_storage, {
        desc = "Analyze storage layout for workspace",
    })
    vim.defer_fn(function()
        if not installer.is_installed() then
            if config.auto_install then
                vim.notify("traverse-lsp: Installing binary...", vim.log.levels.INFO)
                installer.download()
                vim.defer_fn(function()
                    if installer.is_installed() and config.auto_start then
                        M.start()
                    end
                end, 3000) -- Give download time to complete
            else
                vim.notify("traverse-lsp binary not installed. Run :TraverseInstall", vim.log.levels.WARN)
            end
        elseif config.auto_start then
            M.start()
        end
    end, 100) -- Small delay to ensure Neovim is fully initialized
end

-- Health check delegate
function M.check()
    require("traverse-lsp.health").check()
end

-- Helper for health check to get client status
function M.get_client_status()
    if not client_id then
        return nil
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if client then
        return {
            client = client,
            client_id = client_id,
            root_dir = client.config.root_dir,
        }
    else
        return {
            client_id = client_id,
            error = true,
        }
    end
end

return M
