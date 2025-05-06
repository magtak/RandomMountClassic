-- Keywords to detect mounts
local mountKeywords = {
  "Horn", "Warhorse", "Reins", "Kodo", "Raptor", "Steed", "Ram", "Tiger", "Charger", "Strider", "Mechanostrider", "Skeletal", "Deathcharger", "Qiraji"
}

local entropy = 0
local updateInterval = 5

-- Pick a random index using secure WoW API

local function getRandomIndex(max)
  if max < 1 then return 1 end

  entropy = entropy + (GetTime() % 1) + (GetFramerate() / 100) + (entropy % 0.91)

  -- Create a pseudo-random float, scaled by the number of mounts
  local raw = entropy * 997.37  -- large non-integer multiplier for entropy growth
  local index = (math.floor(raw) % max) + 1

  --print("Entropy RNG: max=" .. max .. ", picked index: " .. index)
  return index
end


-- Scan bags for mount names
local function pickRandomMount()
  local mounts = {}
  for bag = 0, 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local link = C_Container.GetContainerItemLink(bag, slot)
      if link then
        local name = link:match("%[(.-)%]")
        if name then
          for _, keyword in ipairs(mountKeywords) do
            if name:find(keyword) then
              table.insert(mounts, name)
              break
            end
          end
        end
      end
    end
  end

  if #mounts > 0 then
    local selected = mounts[getRandomIndex(#mounts)]
    --print("RandomMount: picked '" .. selected .. "'")
    return selected
  else
    --print("RandomMount: no mount items found in bags.")
    return nil
  end
end

-- Update or create the macro
local function updateMacro()
  if InCombatLockdown() then return end

  local mountName = pickRandomMount()
  local macroText

  if mountName then
    macroText = "#showtooltip Mount\n/dismount [mounted]\n/use " .. mountName

  else
    macroText = "#showtooltip\n/script print('No mount items found.')"
  end

  local index = GetMacroIndexByName("RandomMount")
  if index == 0 then
    CreateMacro("RandomMount", "INV_MISC_QUESTIONMARK", macroText, true)
  else
    EditMacro(index, "RandomMount", "INV_MISC_QUESTIONMARK", macroText)
  end
end

-- Frame + event registration
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", updateMacro)

-- Timer logic: run update every 10 seconds (if not in combat)
local elapsed = 0
f:SetScript("OnUpdate", function(self, delta)
  elapsed = elapsed + delta
  if elapsed >= updateInterval then
    updateMacro()
    elapsed = 0
  end
end)

SLASH_MOUNTINTERVAL1 = "/mountinterval"
SlashCmdList["MOUNTINTERVAL"] = function(msg)
  local seconds = tonumber(msg)
  if seconds and seconds > 0 then
    updateInterval = seconds
    print("RandomMount: update interval set to " .. seconds .. " seconds.")
  else
    print("Usage: /mountinterval <seconds>")
  end
end
