#!/usr/bin/env lua
-- Plain Lua test runner for EsoChat (no busted dependency).

local function scriptRoot()
    local info = debug.getinfo(1, "S")
    local src = info and info.source or ""
    src = src:gsub("^@", "")
    local dir = src:match("^(.*)/") or "."
    return dir:match("^(.*)/tests$") or (dir .. "/..")
end

local ROOT = scriptRoot()
package.path = ROOT
    .. "/tests/?.lua;"
    .. ROOT
    .. "/tests/?/init.lua;"
    .. ROOT
    .. "/?.lua;"
    .. (package.path or "")

local suites = {}
local currentSuite = nil
local failures = {}
local passes = 0
local total = 0

local function fail(msg, level)
    level = (level or 1) + 1
    local info = debug.getinfo(level, "Sl")
    error({
        message = msg,
        file = info and info.short_src or "?",
        line = info and info.currentline or 0,
    }, 0)
end

function describe(name, fn)
    table.insert(suites, { name = name, fn = fn, cases = {} })
end

function it(name, fn)
    if not currentSuite then
        error("it() outside describe()", 2)
    end
    table.insert(currentSuite.cases, { name = name, fn = fn })
end

function assertEqual(actual, expected, msg)
    if actual ~= expected then
        fail(
            string.format(
                "%s\n  expected: %s\n  actual:   %s",
                msg or "assertEqual failed",
                tostring(expected),
                tostring(actual)
            ),
            2
        )
    end
end

function assertTrue(value, msg)
    if not value then
        fail(msg or "assertTrue failed", 2)
    end
end

function assertFalse(value, msg)
    if value then
        fail(msg or "assertFalse failed", 2)
    end
end

function assertNil(value, msg)
    if value ~= nil then
        fail(msg or ("expected nil, got " .. tostring(value)), 2)
    end
end

local function runSuite(suite)
    currentSuite = suite
    suite.cases = {}
    suite.fn()
    currentSuite = nil
    print("  " .. suite.name)
    for _, case in ipairs(suite.cases) do
        total = total + 1
        local ok, err = pcall(case.fn)
        if ok then
            passes = passes + 1
            print("    OK " .. case.name)
        else
            local msg = err
            if type(err) == "table" then
                msg = string.format("%s:%s: %s", tostring(err.file), tostring(err.line), tostring(err.message))
            end
            table.insert(failures, suite.name .. " / " .. case.name .. ": " .. tostring(msg))
            print("    FAIL " .. case.name)
        end
    end
end

require("mock.eso")
require("spec.display_spec")
require("spec.mentions_spec")
require("spec.filtering_spec")
require("spec.tabprofiles_spec")
require("spec.settingsio_spec")
require("spec.sounds_spec")
require("spec.tabfilters_spec")
require("spec.tabcreate_spec")
require("spec.tabunread_spec")
require("spec.grouptabsync_spec")
require("spec.notes_spec")
require("spec.inputenhance_spec")

print("EsoChat unit tests")
for _, suite in ipairs(suites) do
    runSuite(suite)
end

print(string.format("\n%d/%d passed", passes, total))
if #failures > 0 then
    print("Failures:")
    for _, f in ipairs(failures) do
        print("  - " .. f)
    end
    os.exit(1)
end
