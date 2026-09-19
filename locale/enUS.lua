local ADDON_NAME, addon = ...

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)
if not L then return end

L.Test = "Test"
L.Save = "Save"
L.Load = "Load"
L.SaveOutfit = "Please provide a name to save the current outfit."
L.NoSave = "Outfit not saved."
L.YesSave = "Outfit has been saved."
L.ErrorSave = "Error saving outfit. [%s]"
L.InvalidName = "Invalid outfit name!"
L.Alert = "Alert"
L.LoadSet = "Load Wardrobe Set"
L.NoLoad = "Could not load item set.  Server did not respond to all items."
