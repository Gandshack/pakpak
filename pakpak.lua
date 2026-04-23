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
    print("sync - Synchronize the local package list with the remote registry.")
    print("install <package> - Install a package from the registry.")
    print("update <package> - Update an installed package to the latest version.")
    print("remove <package> - Remove an installed package.")
    print("list - List all available packages in the registry.")
    print("help - Show this help message.")
    
end

local args = {...}
if #args < 1 then
    show_help()
    return
end

local command = args[1]
if command == "list" then
    list_packages()
else
    print("Unknown command: " .. command)
    print("Use 'pakpak help' for a list of available commands.")
end

if command == "help" then
    show_help()
end
