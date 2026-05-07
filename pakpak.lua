local CONFIG_PATH = "/etc/pakpak_config.json"

local function load_config()
    if fs.exists(CONFIG_PATH) then
        local f = fs.open(CONFIG_PATH, "r")
        local content = f.readAll()
        f.close()
        local cfg = textutils.unserializeJSON(content)
        if cfg then return cfg end
    end
    return { use_dev = false }
end

local function save_config(cfg)
    local f = fs.open(CONFIG_PATH, "w")
    f.write(textutils.serializeJSON(cfg))
    f.close()
end

local function default_branch()
    local cfg = load_config()
    return cfg.use_dev and "dev" or "master"
end

local function fetch_from_github(repo, path, branch)
    branch = branch or default_branch()
    local url = "https://raw.githubusercontent.com/" .. repo .. "/" .. branch .. "/" .. path

    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        return content
    else
        error("Failed to fetch data from GitHub: " .. url)
        return nil
    end
end

local function fetch_package_list()
    local repo = "Gandshack/pakpak_registry"
    local path = "list.json"
    local content = fetch_from_github(repo, path, "master")
    if content then
        print("Package list fetched successfully.")
        return textutils.unserializeJSON(content)
    else
        error("Failed to fetch package list.")
        return nil
    end
end

local function to_raw_url(url)
    -- strip https://github.com/ and .git
    url = url:gsub("https://github.com/", "")
    url = url:gsub("%.git$", "")
    return url -- returns "User/repo"
end

local function install_package(name, branch)
    local data = fetch_package_list()
    if not data then return end

    local pkg = data.packages[name]
    if not pkg then
        print("Package not found: " .. name)
        return
    end

    local repo = to_raw_url(pkg.url)
    local manifest_content = fetch_from_github(repo, "pakpak.json", branch)
    if not manifest_content then return end

    local manifest = textutils.unserializeJSON(manifest_content)

    for _, file in ipairs(manifest.files) do
        local content = fetch_from_github(repo, file, branch)
        local install_path = fs.combine(manifest.installPath, fs.getName(file))
        local f = fs.open(install_path, "w")
        f.write(content)
        f.close()
        print("Installed " .. file .. " to " .. install_path)
    end

    print("Done! Installed " .. name)
end

local function remove_package(name, branch)
    local data = fetch_package_list()
    if not data then return end

    local pkg = data.packages[name]
    if not pkg then
        print("Package not found: " .. name)
        return
    end

    local repo = to_raw_url(pkg.url)
    local manifest_content = fetch_from_github(repo, "pakpak.json", branch)
    if not manifest_content then return end

    local manifest = textutils.unserializeJSON(manifest_content)

    for _, file in ipairs(manifest.files) do
        local install_path = fs.combine(manifest.installPath, fs.getName(file))
        if fs.exists(install_path) then
            fs.delete(install_path)
            print("Removed " .. install_path)
        end
    end

    print("Done! Removed " .. name)
end

local function update_package(name, branch)
    remove_package(name, branch)
    install_package(name, branch)
end

local function list_packages()
    local data = fetch_package_list()
    if data then
        print("Available packages:")
        for name, info in pairs(data.packages) do
            local line = "- " .. name
            if info.description then
                line = line .. ": " .. info.description
            end
            if info.version then
                line = line .. " (v" .. info.version .. ")"
            end
            print(line)
        end
    else
        print("No packages available.")
    end
end

local function show_help()
    print("Usage: pakpak <command> <package> [--dev]")
    print(" ")
    print("Commands:")
    print(" ")
    print("install <package> [--dev] - Install a package (--dev uses dev branch).")
    print(" ")
    print("update <package> [--dev]  - Update an installed package.")
    print(" ")
    print("remove <package>          - Remove an installed package.")
    print(" ")
    print("list                      - List all available packages.")
    print(" ")
    print("set-dev <true|false>      - Globally toggle dev branch as default.")
    print(" ")
    print("help                      - Show this help message.")
    print(" ")
    print("[DEV] test                - Test dev branch functionality.")
end

local args = { ... }
if #args < 1 then
    show_help()
    return
end

local command = args[1]
local package_name = args[2]

-- Detect --dev flag in any position after the command
local use_dev_flag = false
local filtered_args = {}
for i = 2, #args do
    if args[i] == "--dev" then
        use_dev_flag = true
    else
        table.insert(filtered_args, args[i])
    end
end
package_name = filtered_args[1]

local branch = use_dev_flag and "dev" or nil -- nil lets default_branch() decide

if command == "list" then
    list_packages()
elseif command == "install" then
    if not package_name then
        print("Please specify a package to install.")
        return
    end
    install_package(package_name, branch)
elseif command == "remove" then
    if not package_name then
        print("Please specify a package to remove.")
        return
    end
    remove_package(package_name, branch)
elseif command == "update" then
    if not package_name then
        print("Please specify a package to update.")
        return
    end
    update_package(package_name, branch)
elseif command == "set-dev" then
    local value = filtered_args[1]
    if value == "true" or value == "false" then
        local cfg = load_config()
        cfg.use_dev = (value == "true")
        save_config(cfg)
        print("Dev mode set to: " .. value)
    else
        print("Usage: pakpak set-dev <true|false>")
    end
elseif command == "test" then
    print("[DEV] pakpak dev branch is working!")
elseif command == "help" then
    show_help()
else
    print("Unknown command: " .. command)
    print("Use 'pakpak help' for a list of available commands.")
end
