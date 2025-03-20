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

    if not files then
        print("No files listed for package: " .. appName)
        return
    end

    if fs.exists(installPath) then
        fs.delete(installPath)
    end

    createDirectory(installPath)
    installDirectory(repo, path, installPath, files)

    -- Create a shell alias for easier execution without .lua extension
    local mainFile = installPath .. "/" .. files[1]
    shell.setAlias(appName, mainFile)
    print("Alias created: " .. appName .. " -> " .. mainFile)
end

local args = {...}
if #args < 2 or args[1] ~= "install" then
    print("Usage: pakpak install [appname]")
    return
end

local appName = args[2]
local packageList = fetchPackageList()
if not packageList then
    print("Failed to fetch package list")
    return
end

-- Debug output to verify JSON parsing
print(textutils.serialize(packageList))

local packageInfo = packageList[appName]
if not packageInfo then
    print("Package not found: " .. appName)
    return
end

-- Check files explicitly
if not packageInfo.files then
    print("No files listed for package: " .. appName)
    return
end

installPackage(appName, packageInfo)
