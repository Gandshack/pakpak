local function fetchFileFromGitHub(repo, path)
    local url = "https://raw.githubusercontent.com/" .. repo .. "/master/" .. path
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        return content
    end
    return nil
end

local function fetchPackageList()
    local repo = "Gandshack/pakpak-packages"
    local path = "packages.json"
    local content = fetchFileFromGitHub(repo, path)
    if content then
        return textutils.unserializeJSON(content)
    end
    return nil
end

local function createDirectory(path)
    if not fs.exists(path) then
        fs.makeDir(path)
        return true
    end
    return false
end

local function installFile(repo, path, installPath)
    local parentDir = fs.getDir(installPath)
    if not fs.exists(parentDir) then
        fs.makeDir(parentDir)
    end

    local content = fetchFileFromGitHub(repo, path)
    if content then
        local file = fs.open(installPath, "w")
        if file then
            file.write(content)
            file.close()
            print("Installed " .. path .. " to " .. installPath)
            return true
        end
    end
    print("Failed to fetch " .. path)
    return false
end

local function installDirectory(repo, path, installPath, files)
    createDirectory(installPath)

    for _, file in ipairs(files) do
        local filePath
        if path == "" then
            filePath = file
        else
            filePath = path .. "/" .. file
        end
        local fileInstallPath = fs.combine(installPath, file)
        installFile(repo, filePath, fileInstallPath)
    end
end

local function installPackage(appName, packageInfo)
    local repo = packageInfo.repo
    local path = packageInfo.path
    local installPath = packageInfo.installPath
    local files = packageInfo.files

    print("--------------------")
    print("Installing package: " .. appName)

    if not files then
        print("No files listed for package: " .. appName)
        return
    end

    if fs.exists(installPath) then
        print("Package already installed: " .. appName)
        print("Removing existing package: " .. installPath)
        fs.delete(installPath)
    end

    createDirectory(installPath)
    print("Created directory: " .. installPath)
    installDirectory(repo, path, installPath, files)
    print("Package installed: " .. appName)

    local mainFile = installPath .. "/" .. files[1]
    shell.setAlias(appName, mainFile)
    print("Alias created: " .. appName .. " -> " .. mainFile)
    print("--------------------")
end

local function uninstallPackage(appName, packageInfo)
    local installPath = packageInfo.installPath

    print("--------------------")
    print("Uninstalling package: " .. appName)

    if not fs.exists(installPath) then
        print("Package not installed: " .. appName)
        return
    end

    print("Removing package: " .. installPath)
    fs.delete(installPath)
    print("Package uninstalled: " .. appName)

    shell.clearAlias(appName)
    print("Alias removed: " .. appName)
    print("--------------------")
end

local function updatePackage(appName, packageInfo)
    print("--------------------")
    print("Updating package: " .. appName)

    if not fs.exists(packageInfo.installPath) then
        print("Package not installed: " .. appName)
        print("Use 'pakpak install " .. appName .. "' to install it")
        return
    end

    -- Uninstall the old version
    uninstallPackage(appName, packageInfo)
    -- Install the new version
    installPackage(appName, packageInfo)
    
    print("Update completed for: " .. appName)
    print("--------------------")
end

local args = {...}
if #args < 2 then
    print("PakPak - Package Manager")
    print("Usage:")
    print("  pakpak install <AppName>")
    print("  pakpak uninstall <AppName>")
    print("  pakpak update <AppName>")
    return
end

local command = args[1]
local appName = args[2]
local packageList = fetchPackageList()

if not packageList then
    print("Failed to fetch package list")
    return
end

local packageInfo = packageList[appName]
if not packageInfo then
    print("Package not found: " .. appName)
    return
end

if command == "install" then
    if not packageInfo.files then
        print("No files listed for package: " .. appName)
        return
    end
    installPackage(appName, packageInfo)
elseif command == "uninstall" then
    uninstallPackage(appName, packageInfo)
elseif command == "update" then
    updatePackage(appName, packageInfo)
else
    print("Unknown command. Use 'install', 'uninstall', or 'update'")
end
