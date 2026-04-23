local function fetch_from_github(repo, path)
    local url = "https://raw.githubusercontent.com/" .. repo .. "/master/" .. path

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
    local content = fetch_from_github(repo, path)
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
    return url  -- returns "User/repo"
end

local function install_package(name)
    local data = fetch_package_list()
    if not data then return end
    
    local pkg = data.packages[name]
    if not pkg then
        print("Package not found: " .. name)
        return
    end

    local repo = to_raw_url(pkg.url)
    local manifest_content = fetch_from_github(repo, "pakpak.json")
    if not manifest_content then return end
    
    local manifest = textutils.unserializeJSON(manifest_content)
    
    for _, file in ipairs(manifest.files) do
        local content = fetch_from_github(repo, file)
        local install_path = fs.combine(manifest.installPath, fs.getName(file))
        local f = fs.open(install_path, "w")
        f.write(content)
        f.close()
        print("Installed " .. file .. " to " .. install_path)
    end

    print("Done! Installed " .. name)
end

local function remove_package(name)
    local data = fetch_package_list()
    if not data then return end

    local pkg = data.packages[name]
    if not pkg then
        print("Package not found: " .. name)
        return
    end

    local repo = to_raw_url(pkg.url)
    local manifest_content = fetch_from_github(repo, "pakpak.json")
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

local function update_package(name)
    remove_package(name)
    install_package(name)
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
    print("Usage: pakpak <command> <package>")
    print(" ")
    print("Commands:")
    print(" ")
    print("install <package> - Install a package from the registry.")
    print(" ")
    print("update <package> - Update an installed package to the latest version.")
    print(" ")
    print("remove <package> - Remove an installed package.")
    print(" ")
    print("list - List all available packages in the registry.")
    print(" ")
    print("help - Show this help message.")
    
end

local args = {...}
if #args < 1 then
    show_help()
    return
end

local command = args[1]
local package_name = args[2]

if command == "list" then
    list_packages()
elseif command == "install" then
    if not package_name then
        print("Please specify a package to install.")
        return
    end
    install_package(package_name)
elseif command == "remove" then
    if not package_name then
        print("Please specify a package to remove.")
        return
    end
    remove_package(package_name)
elseif command == "update" then
    if not package_name then
        print("Please specify a package to update.")
        return
    end
    update_package(package_name)    
elseif command == "help" then
    show_help()
else
    print("Unknown command: " .. command)
    print("Use 'pakpak help' for a list of available commands.")
end
