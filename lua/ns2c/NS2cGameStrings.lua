// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\NS2cGameStrings.lua
// - Dragon

Script.Load("lua/dkjson.lua")

local kClassicLocaleTable = { }
local localeFiles = { }

local function BuildClassicLocaleTable()

    Shared.GetMatchingFileNames("lang/*.json", false, localeFiles )

    if #localeFiles > 0 then
        for i = 1, #localeFiles do
            local fileName = localeFiles[i]
            local localeName = string.gsub(string.gsub(fileName, "lang/", ""), ".json", "")
            Shared.Message("Loading Classic Locale " .. fileName)
            local openedFile = GetFileExists(fileName) and io.open(fileName, "r")
            if openedFile then
                local parsedFile, _, errStr = json.decode(openedFile:read("*all"))
                if errStr then
                    Shared.Message("Error while opening " .. fileName .. ": " .. errStr)
                end
                io.close(openedFile)
                kClassicLocaleTable[localeName] = parsedFile
            end
            
        end
    end
    
end

BuildClassicLocaleTable()

local oldLocaleResolveString = Locale.ResolveString
function Locale.ResolveString(s)
    //determine users locale
    local locale = Locale.GetLocale()
    //check if we replace/add this string
    local modString = kClassicLocaleTable["enUS"][s]
    if modString then
        //classic adds or replaces this string
        //return locale specific string
        if kClassicLocaleTable[locale] then
            return kClassicLocaleTable[locale][s]
        end
        return modString 
    else
        return oldLocaleResolveString(s)
    end
end