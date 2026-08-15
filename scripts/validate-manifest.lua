#!/usr/bin/env lua
-- EsoChat Manifest Validator
-- Enforces ESOUI Section 1 technical requirements (wiki + best practices).

local REQUIRED_FIELDS = {
    "Title",
    "Author",
    "Version",
    "AddOnVersion",
    "APIVersion",
}

local OPTIONAL_FIELDS = {
    "SavedVariables",
    "OptionalDependsOn",
    "DependsOn",
    "Description",
}

local DEV_ADDON_VERSION_PLACEHOLDERS = {
    ["@addon-build-version@"] = true,
    ["@project-version@"] = true,
}

local MAX_TITLE_LEN = 64
local MAX_LINE_BYTES = 301
local LICENSE_NEEDLE = "not created by, affiliated with"

local function trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

local function validate_manifest(filepath)
    local file = io.open(filepath, "rb")
    if not file then
        print("❌ Error: Cannot open manifest file: " .. filepath)
        os.exit(1)
    end

    local content = file:read("*all")
    file:close()

    local found_fields = {}
    local referenced_files = {}
    local errors = {}
    local warnings = {}
    local has_license = false

    -- UTF-8 BOM check
    if content:sub(1, 3) == "\239\187\191" then
        table.insert(errors, "Manifest has UTF-8 BOM; use UTF-8 without BOM")
        content = content:sub(4)
    end

    local line_num = 0
    for line in content:gmatch("[^\r\n]*") do
        line_num = line_num + 1
        if #line > MAX_LINE_BYTES then
            table.insert(errors, string.format(
                "Line %d is %d bytes (max %d); excess is silently ignored by ESO",
                line_num, #line, MAX_LINE_BYTES
            ))
        end

        local field, value = line:match("^##%s*([^:]+):%s*(.+)$")
        if field and value then
            field = trim(field)
            value = trim(value)
            found_fields[field] = value
            if field:lower():find("this add%-on is not created", 1, true)
                or value:lower():find(LICENSE_NEEDLE, 1, true)
                or line:lower():find(LICENSE_NEEDLE, 1, true) then
                has_license = true
            end
        elseif line:lower():find(LICENSE_NEEDLE, 1, true) then
            has_license = true
        end

        if not line:match("^##") and not line:match("^;") and not line:match("^#")
            and line:match("%S") then
            table.insert(referenced_files, trim(line))
        end
    end

    -- Licensing may be a ## comment line without a standard field name
    if not has_license and content:lower():find(LICENSE_NEEDLE, 1, true) then
        has_license = true
    end

    for _, field in ipairs(REQUIRED_FIELDS) do
        if not found_fields[field] then
            table.insert(errors, string.format("Missing required field: ## %s:", field))
        end
    end

    if found_fields.Title and #found_fields.Title > MAX_TITLE_LEN then
        table.insert(errors, string.format(
            "Title is %d characters (max %d)",
            #found_fields.Title, MAX_TITLE_LEN
        ))
    end

    if found_fields.Version then
        local version = found_fields.Version
        if version == "@project-version@" then
            print("   ℹ️  Using @project-version@ placeholder (Git-based versioning)")
        elseif not version:match("^%d+%.%d+%.%d+") then
            table.insert(warnings, string.format(
                "Version '%s' doesn't follow semantic versioning or @project-version@",
                version
            ))
        end
    end

    if found_fields.AddOnVersion then
        local aov = found_fields.AddOnVersion
        if DEV_ADDON_VERSION_PLACEHOLDERS[aov] then
            table.insert(warnings, string.format(
                "AddOnVersion is still placeholder '%s' (set integer via set-addon-version.sh at build)",
                aov
            ))
        elseif not aov:match("^%d+$") then
            table.insert(errors, string.format(
                "AddOnVersion must be a positive integer (ESO atoi); got '%s'",
                aov
            ))
        elseif tonumber(aov) < 1 then
            table.insert(errors, "AddOnVersion must be a positive integer (>= 1)")
        end
    end

    if found_fields.APIVersion then
        if not found_fields.APIVersion:match("^%d+") then
            table.insert(errors, "APIVersion is not a valid number")
        end
    end

    if not has_license then
        table.insert(errors, "Missing ZeniMax licensing disclosure ('not created by, affiliated with')")
    end

    for _, file_path in ipairs(referenced_files) do
        local handle = io.open(file_path, "r")
        if not handle then
            table.insert(errors, string.format("Referenced file not found: %s", file_path))
        else
            handle:close()
        end
        if not file_path:match("%.lua$") and not file_path:match("%.xml$") then
            table.insert(warnings, string.format(
                "Referenced file '%s' doesn't have .lua or .xml extension",
                file_path
            ))
        end
    end

    print("📋 Validating: " .. filepath)
    print("")

    if #errors > 0 then
        print("❌ ERRORS:")
        for _, err in ipairs(errors) do
            print("   " .. err)
        end
        print("")
        os.exit(1)
    end

    if #warnings > 0 then
        print("⚠️  WARNINGS:")
        for _, warn in ipairs(warnings) do
            print("   " .. warn)
        end
        print("")
    end

    print("✅ Manifest is valid!")
    print(string.format("Referenced files: %d", #referenced_files))
    os.exit(0)
end

if #arg < 1 then
    print("Usage: lua validate-manifest.lua <manifest.txt>")
    os.exit(1)
end

validate_manifest(arg[1])
