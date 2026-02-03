exclude_files = {
    ".luacheckrc",
}

-- https://luacheck.readthedocs.io/en/stable/warnings.html

ignore = {
    "212/_.*",  -- Unused argument starting with _
    "213/_.*",  -- Unused loop variable starting with _
    "631",      -- line too long
}

globals = {
    "ComboStriker",
    "ComboStrikerOverlayMixin",
}

read_globals = {
    "ActionBarButtonEventsFrame",
    "C_UnitAuras",
    "CreateFrame",
    "GetActionInfo",
    "IsPlayerSpell",
    "UnitClass",
}
