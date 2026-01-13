-- ============================================================
--
-- STAINS RANGE SCRIPT
--
-- ============================================================

RANGEQUAL = RANGEQUAL or {}

RANGEQUAL._zoneCache = RANGEQUAL._zoneCache or {}  -- cache: zoneName -> shape
RANGEQUAL._spawnPts = RANGEQUAL._spawnPts or {}  -- cache: spawned group name -> {x,z}
local rq_ensureMenusForGroup  -- forward declaration (menus)
----------------------------------------------------------------
-- CONFIG (HUMAN-EDITABLE)
----------------------------------------------------------------
RANGEQUAL.cfg = {
  globals = {
    foulZoneName        = "FOUL_LINE",
    fireZoneName        = "FIRE_ZONE",
	cleanupZoneName     = "RANGE_CLEANUP",
    welcomeSound        = "WELCOME.ogg",
    rangeHotSound       = "RANGE_HOT.ogg",
    rangeClearSound     = "RANGE_CLEAR.ogg",
	hoverMaxKt          = 5,     -- max GS for HOVER tasks
    moveMinKt           = 20,    -- min GS for MOVE tasks
    welcomeTickSec      = 1.0,  -- seconds; poll for first entry/spawn in FIRE_ZONE
    rangeClearDelaySec  = 6.0,  -- seconds; delay after shooter end-state before broadcasting RANGE_CLEAR
    rangeHotThrottleSec = 2.0,  -- seconds; per-group throttle for RANGE_HOT spam
    armingDelaySec      = 10,
    gunEndPadBufferSec  = 3.0,  -- Additional buffer after calculated flight time for impact detection
    successHoldSec      = 2.5,  -- seconds; delay after first terminal effect to bundle multi-kills/messages
    tickSec             = 0.2,
    menuRefreshSec      = 5,
    logOutTextSec       = 6,   -- seconds; generic debug text duration (if enabled)
    reportOutTextSec    = 20,  -- seconds; range report / status duration
    loadedOutTextSec    = 10,  -- seconds; mission start banner duration
    cleanupDelaySec    = 1.5,  -- seconds; delay before cleanup/zone wipe
    cleanupBoxHeightM   = 2000, -- meters; vertical extent for BOX volume in polygon cleanup zones
    cleanupJunkPassesSec = {0, 10, 30}, -- seconds; run removeJunk multiple times to catch delayed wreck conversion
  },

  ----------------------------------------------------------------
  -- TIME CURVES
  -- NOTE: points are assigned if terminal effect achieved; else 0
  ----------------------------------------------------------------
  curves = {

    HF_SELF = {
      [1] = { {15,100},{17,95},{18,90},{19,85},{20,80},{21,75},{22,70},{24,50},{25,30} },
      [2] = { {19,100},{20,95},{22,90},{23,85},{24,80},{26,75},{27,70},{30,50},{31,30} },
      [3] = { {23,100},{25,95},{26,90},{28,85},{30,80},{31,75},{33,70},{36,50},{38,30} },
      [4] = { {28,100},{30,95},{32,90},{34,85},{36,80},{38,75},{40,70},{44,50},{46,30} },
      [5] = { {34,100},{36,95},{38,90},{41,85},{43,80},{46,75},{48,70},{53,50},{55,30} },
      [6] = { {39,100},{42,95},{45,90},{48,85},{50,80},{53,75},{56,70},{62,50},{64,30} },
      [7] = { {46,100},{50,95},{53,90},{56,85},{59,80},{63,75},{66,70},{73,50},{76,30} },
    },

    HF_REMOTE = {
      {40,100},{42,98},{44,96},{46,94},{48,92},{50,90},{52,88},{54,86},{56,84},{58,82},
      {60,80},{62,78},{64,76},{66,74},{68,72},{70,70},{76,50},{80,30},
    },

    GUN_STD = {
      {30,100},{32,98},{34,96},{36,94},{38,92},{40,90},{42,88},{44,86},{46,84},{48,82},
      {50,80},{52,78},{54,76},{56,74},{58,72},{60,70},{70,50},{80,30},
    },

    ROCKET_STD = {
      -- 4 PAIRS (8 rockets allowed)
      [4] = {
        [1] = { {43,100},{46,95},{49,90},{52,85},{55,80},{58,75},{61,70},{67,50},{70,30} },
        [2] = { {53,100},{56,95},{60,90},{64,85},{68,80},{71,75},{75,70},{83,50},{86,30} },
        [3] = { {65,100},{70,95},{74,90},{79,85},{84,80},{88,75},{93,70},{102,50},{107,30} },
        [4] = { {78,100},{83,95},{89,90},{94,85},{100,80},{105,75},{111,70},{122,50},{128,30} },
        [5] = { {96,100},{103,95},{110,90},{116,85},{123,80},{130,75},{137,70},{151,50},{158,30} },
        [6] = { {120,100},{128,95},{137,90},{145,85},{154,80},{162,75},{171,70},{188,50},{197,30} },
        [7] = { {138,100},{148,95},{158,90},{167,85},{177,80},{187,75},{197,70},{217,50},{227,30} },
      },
      -- 3 PAIRS (6 rockets allowed)
      [3] = {
        [1] = { {33,100},{35,95},{38,90},{40,85},{42,80},{45,75},{47,70},{52,50},{54,30} },
        [2] = { {41,100},{44,95},{46,90},{49,85},{52,80},{55,75},{58,70},{64,50},{67,30} },
        [3] = { {50,100},{54,95},{58,90},{61,85},{65,80},{68,75},{72,70},{79,50},{83,30} },
        [4] = { {60,100},{65,95},{69,90},{73,85},{77,80},{82,75},{86,70},{95,50},{99,30} },
        [5] = { {74,100},{80,95},{85,90},{90,85},{95,80},{101,75},{106,70},{117,50},{122,30} },
        [6] = { {92,100},{99,95},{106,90},{112,85},{119,80},{125,75},{132,70},{145,50},{152,30} },
        [7] = { {106,100},{114,95},{122,90},{129,85},{137,80},{144,75},{152,70},{167,50},{175,30} },
      },
      -- 2 PAIRS (4 rockets allowed)
      [2] = {
        [1] = { {23,100},{25,95},{26,90},{28,85},{30,80},{31,75},{33,70},{36,50},{38,30} },
        [2] = { {29,100},{31,95},{33,90},{35,85},{37,80},{39,75},{41,70},{45,50},{47,30} },
        [3] = { {36,100},{38,95},{41,90},{43,85},{46,80},{48,75},{51,70},{56,50},{59,30} },
        [4] = { {43,100},{46,95},{49,90},{52,85},{55,80},{58,75},{61,70},{67,50},{70,30} },
        [5] = { {53,100},{56,95},{60,90},{64,85},{68,80},{71,75},{75,70},{83,50},{86,30} },
        [6] = { {65,100},{70,95},{74,90},{79,85},{84,80},{88,75},{93,70},{102,50},{107,30} },
        [7] = { {75,100},{80,95},{86,90},{91,85},{96,80},{102,75},{107,70},{118,50},{123,30} },
      },
      -- 1 PAIR (2 rockets allowed)
      [1] = {
        [1] = { {13,100},{14,95},{15,90},{16,85},{17,80},{18,75},{19,70},{21,50},{22,30} },
        [2] = { {17,100},{18,95},{19,90},{20,85},{22,80},{23,75},{24,70},{26,50},{28,30} },
        [3] = { {21,100},{23,95},{24,90},{26,85},{27,80},{29,75},{30,70},{33,50},{35,30} },
        [4] = { {25,100},{27,95},{29,90},{31,85},{32,80},{34,75},{36,70},{40,50},{41,30} },
        [5] = { {31,100},{33,95},{35,90},{37,85},{40,80},{42,75},{44,70},{48,50},{51,30} },
        [6] = { {38,100},{41,95},{43,90},{46,85},{49,80},{51,75},{54,70},{59,50},{62,30} },
        [7] = { {43,100},{47,95},{50,90},{53,85},{56,80},{59,75},{62,70},{68,50},{71,30} },
      },
  },

    -- APKWS (laser-guided rockets - range-banded like HF_SELF for future tuning)
    APKWS_STD = {
      [1] = { {15,100},{17,95},{18,90},{19,85},{20,80},{21,75},{22,70},{24,50},{25,30} },
      [2] = { {19,100},{20,95},{22,90},{23,85},{24,80},{26,75},{27,70},{30,50},{31,30} },
      [3] = { {23,100},{25,95},{26,90},{28,85},{30,80},{31,75},{33,70},{36,50},{38,30} },
      [4] = { {28,100},{30,95},{32,90},{34,85},{36,80},{38,75},{40,70},{44,50},{46,30} },
      [5] = { {34,100},{36,95},{38,90},{41,85},{43,80},{46,75},{48,70},{53,50},{55,30} },
      [6] = { {39,100},{42,95},{45,90},{48,85},{50,80},{53,75},{56,70},{62,50},{64,30} },
      [7] = { {46,100},{50,95},{53,90},{56,85},{59,80},{63,75},{66,70},{73,50},{76,30} },
    },

    -- STINGER (copy of HF_REMOTE for future tuning)
    STINGER_STD = {
      {40,100},{42,98},{44,96},{46,94},{48,92},{50,90},{52,88},{54,86},{56,84},{58,82},
      {60,80},{62,78},{64,76},{66,74},{68,72},{70,70},{76,50},{80,30},
    },
  },

  ----------------------------------------------------------------
  -- AIRCRAFT CONFIGURATIONS
  -- targetTemplate can be either a unit-group name OR a static-group name
  ----------------------------------------------------------------
  ah64 = {
    gunVelocity = 805,  -- M230 30mm chain gun muzzle velocity in m/s
    tasks = {
      [1] = { id=1,  type="GUN30MM",   targetTemplate="AH64_T01_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=30 }, scoringCurve="GUN_STD", motion="HOVER" },
      [2] = { id=2,  type="ROCKETS",   targetTemplate="AH64_T02_TARGET", teaCorners=true, requiredInZoneImpacts=2, allowed={ rockets=6 }, rocketCurve="ROCKET_STD", motion="HOVER" },
      [3] = { id=3,  type="GUN30MM",   targetTemplate="AH64_T03_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=30 }, scoringCurve="GUN_STD", motion="HOVER" },
      [4] = { id=4,  type="HF_SELF",   targetTemplate="AH64_T04_TARGET", allowed={ hellfires=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="HF_SELF", motion="HOVER" },
      [5] = { id=5,  type="ROCKETS",   targetTemplate="AH64_T05_TARGET", teaCorners=true, requiredInZoneImpacts=2, allowed={ rockets=6 }, rocketCurve="ROCKET_STD", motion="HOVER" },
      [6] = { id=6,  type="HF_SELF",   targetTemplate="AH64_T06_TARGET", allowed={ hellfires=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="HF_SELF", motion="HOVER" },
      [7] = { id=7,  type="HF_REMOTE", targetTemplate="AH64_T07_TARGET", jtacTemplate="AH64_T07_JTAC", laserCode=1688, allowed={ hellfires=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="HF_REMOTE", motion="HOVER" },
      [8] = { id=8,  type="GUN30MM",   targetTemplate="AH64_T08_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=40 }, scoringCurve="GUN_STD", motion="HOVER" },
      [9] = { id=9,  type="GUN30MM",   targetTemplate="AH64_T09_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=30 }, scoringCurve="GUN_STD", motion="MOVE" },
      [10]= { id=10, type="ROCKETS",   targetTemplate="AH64_T10_TARGET", teaCorners=true, requiredInZoneImpacts=2, allowed={ rockets=8 }, rocketCurve="ROCKET_STD", motion="HOVER" },
    }
  },

  oh58 = {
    gunVelocity = 887,  -- .50 cal machine gun muzzle velocity in m/s (2910 ft/s)
    m4Velocity = 900,   -- M4 rifle muzzle velocity in m/s (5.56mm NATO)
    tasks = {
      [1] = { id=1,  type="HF_SELF",   targetTemplate="OH58_T01_TARGET", allowed={ hellfires=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="HF_SELF", motion="HOVER" },
      [2] = { id=2,  type="HF_REMOTE", targetTemplate="OH58_T02_TARGET", jtacTemplate="OH58_T02_JTAC", laserCode=1688, allowed={ hellfires=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="HF_REMOTE", motion="HOVER" },
      [3] = { id=3,  type="GUN50CAL",  targetTemplate="OH58_T03_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=100 }, scoringCurve="GUN_STD", motion="MOVE" },
      [4] = { id=4,  type="GUN50CAL",  targetTemplate="OH58_T04_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=100 }, scoringCurve="GUN_STD", motion="MOVE" },
      [5] = { id=5,  type="ROCKETS",   targetTemplate="OH58_T05_TARGET", teaCorners=true, requiredInZoneImpacts=2, allowed={ rockets=6 }, rocketCurve="ROCKET_STD", motion="MOVE" },
      [6] = { id=6,  type="ROCKETS",   targetTemplate="OH58_T06_TARGET", teaCorners=true, requiredInZoneImpacts=2, allowed={ rockets=8 }, rocketCurve="ROCKET_STD", motion="MOVE" },
      [7] = { id=7,  type="GUNM4",     targetTemplate="OH58_T07_TARGET", terminalEffect="DAMAGE_ANY", allowed={ gunRounds=999 }, scoringCurve="GUN_STD", motion="HOVER" },
      [8] = { id=8,  type="APKWS",     targetTemplate="OH58_T08_TARGET", allowed={ apkws=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="APKWS_STD", motion="HOVER" },
      [9] = { id=9,  type="APKWS",     targetTemplate="OH58_T09_TARGET", allowed={ apkws=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="APKWS_STD", motion="HOVER" },
      [10]= { id=10, type="STINGER",   targetTemplate="OH58_T10_AIR_TARGET", allowed={ stingers=1 }, terminalEffect="DAMAGE_ANY", scoringCurve="STINGER_STD", motion="HOVER" },
    }
  }
}

----------------------------------------------------------------
-- INTERNALS
----------------------------------------------------------------
RANGEQUAL._markId = RANGEQUAL._markId or 1000

RANGEQUAL._state = RANGEQUAL._state or {
  perUnit   = {},
  score     = {},
  menus     = {},
  marksByUnit = {},
  welcomeHeard = {}, -- unitName -> true (WELCOME played once per mission)
  qualStartTime = {}, -- unitName -> time of first WELCOME
  perfectElapsed = {}, -- unitName -> seconds (WELCOME -> 1000)
  rangeHotLast = {}, -- groupId -> last played time (throttle)
  handler   = nil,
  started   = false,
  rangeLock = { busy = false, ownerUnitName = nil, taskId = nil },
}

local function rq_getRunFromInitiator(initiator)
  if not initiator then return nil end

  -- Primary: unit-name mapping (perUnit stores runs directly)
  if initiator.getName and RANGEQUAL._state and RANGEQUAL._state.perUnit then
    local uname = initiator:getName()
    if uname and RANGEQUAL._state.perUnit[uname] then
      return RANGEQUAL._state.perUnit[uname]
    end
  end

  -- Fallback: match by groupId against known active runs
  if initiator.getGroup and RANGEQUAL._state and RANGEQUAL._state.perUnit then
    local g = initiator:getGroup()
    if g and g.getID then
      local gid = g:getID()
      for _, r in pairs(RANGEQUAL._state.perUnit) do
        if r and r.groupId == gid then return r end
      end
    end
  end

  return nil
end



local function rq_findActiveRunByInitiator(initiator)
  if not initiator then return nil end
  if initiator.getName and RANGEQUAL._state and RANGEQUAL._state.perUnit then
    local uname = initiator:getName()
    return (uname and RANGEQUAL._state.perUnit[uname]) or nil
  end
  return nil
end

local function rq_now() return timer.getTime() end
local function rq_roundSec(t) return math.floor((t or 0) + 0.5) end

-- Logging (silent by default). Set RQ_LOG_LEVEL > 0 to enable.
local RQ_LOG_LEVEL = 0 -- 0=off, 1=error, 2=warn, 3=info, 4=debug (set to 4 for cleanup testing)
local function rq_log(level, msg)
  if level <= (RQ_LOG_LEVEL or 0) then
    trigger.action.outText("[RQ] " .. tostring(msg), 6)
  end
end


-- F10 impact markers (per-unit). Cleared whenever that unit starts a new task.
local function rq_clearUnitMarks(ownerUnitName)
  if not ownerUnitName then return end
  RANGEQUAL._state.marksByUnit = RANGEQUAL._state.marksByUnit or {}
  local lst = RANGEQUAL._state.marksByUnit[ownerUnitName]
  if not lst then return end
  for _, mid in ipairs(lst) do
    pcall(function() trigger.action.removeMark(mid) end)
  end
  RANGEQUAL._state.marksByUnit[ownerUnitName] = nil
end

-- Wipe all persistent state for a unit slot when the unit ceases to exist.

-- Track how many players are currently occupying a given unit (supports multi-crew).
local function rq_getOcc(unitName)
  RANGEQUAL._state.occupancy = RANGEQUAL._state.occupancy or {}
  return RANGEQUAL._state.occupancy[unitName] or 0
end

local function rq_setOcc(unitName, val)
  RANGEQUAL._state.occupancy = RANGEQUAL._state.occupancy or {}
  if val and val > 0 then
    RANGEQUAL._state.occupancy[unitName] = val
  else
    RANGEQUAL._state.occupancy[unitName] = nil
  end
end

local function rq_wipeUnitSlate(unitName, reason)
  if not unitName or not RANGEQUAL._state then return end

  -- Clear lock if held by this unit
  if RANGEQUAL._state.rangeLock and RANGEQUAL._state.rangeLock.ownerUnitName == unitName then
    RANGEQUAL._state.rangeLock.busy = false
    RANGEQUAL._state.rangeLock.ownerUnitName = nil
    RANGEQUAL._state.rangeLock.taskId = nil
  end

  -- Clear run + scoring
  if RANGEQUAL._state.perUnit then RANGEQUAL._state.perUnit[unitName] = nil end
  if RANGEQUAL._state.score then RANGEQUAL._state.score[unitName] = nil end

  -- Clear markers + WELCOME/timing
  rq_clearUnitMarks(unitName)
  if RANGEQUAL._state.welcomeHeard then RANGEQUAL._state.welcomeHeard[unitName] = nil end
  if RANGEQUAL._state.qualStartTime then RANGEQUAL._state.qualStartTime[unitName] = nil end
  if RANGEQUAL._state.perfectElapsed then RANGEQUAL._state.perfectElapsed[unitName] = nil end

  rq_log(3, string.format("Slate wiped for %s (%s)", tostring(unitName), tostring(reason or "unit_gone")))
  rq_setOcc(unitName, 0)
end


local function rq_nextMarkId()
  RANGEQUAL._markId = (RANGEQUAL._markId or 1000) + 1
  if RANGEQUAL._markId > 999999 then RANGEQUAL._markId = 1001 end
  return RANGEQUAL._markId
end

local function rq_getShooterNameForRun(run)
  if not run then return "UNKNOWN" end
  local u = Unit.getByName(run.ownerUnitName or "")
  if u and u:isExist() and u.getPlayerName then
    local pn = u:getPlayerName()
    if pn and pn ~= "" then return pn end
  end
  return run.ownerUnitName or "UNKNOWN"
end

local function rq_markRocketImpact(run, impactPoint, isHit)
  if not run or not impactPoint then return end
  local owner = run.ownerUnitName
  if not owner then return end
  RANGEQUAL._state.marksByUnit = RANGEQUAL._state.marksByUnit or {}
  local lst = RANGEQUAL._state.marksByUnit[owner]
  if not lst then lst = {}; RANGEQUAL._state.marksByUnit[owner] = lst end

  local shooter = rq_getShooterNameForRun(run)
  local label = isHit and "HIT" or "MISS"
  local txt = string.format("%s - %s", shooter, label)

  local mid = rq_nextMarkId()
  local yy = impactPoint.y
  if not yy or yy == 0 then yy = land.getHeight({x=impactPoint.x, y=impactPoint.z}) end
  trigger.action.markToAll(mid, txt, {x=impactPoint.x, y=yy, z=impactPoint.z}, true)
  lst[#lst+1] = mid
end

local function rq_getGroundSpeedKt(unit)
  if not unit or not unit:isExist() or not unit.getVelocity then return 0 end
  local v = unit:getVelocity() or {x=0,y=0,z=0}
  local gs_ms = math.sqrt((v.x or 0)^2 + (v.z or 0)^2)
  return gs_ms * 1.9438444924406 -- m/s to knots
end

local function rq_motionOk(task, unit)
  local req = (task and task.motion) or "HOVER"
  local gs  = rq_getGroundSpeedKt(unit)

  local g = RANGEQUAL.cfg and RANGEQUAL.cfg.globals or {}
  local hoverMax = g.hoverMaxKt or 5
  local moveMin  = g.moveMinKt  or 5

  if req == "MOVE" then
    return gs >= moveMin
  else
    return gs < hoverMax
  end
end

-- Extract aircraft type prefix for template names (e.g., "AH-64D" -> "AH64")
local function rq_getAircraftPrefix(unit)
  if not unit or not unit.getTypeName then return nil end
  local typeName = unit:getTypeName()
  if not typeName then return nil end

  -- Remove hyphens and extract prefix (e.g., "AH-64D" -> "AH64", "OH-58D" -> "OH58")
  local prefix = typeName:gsub("%-", ""):match("^([A-Z]+%d+)")
  return prefix
end



-- ------------------------------------------------------------
-- AUTO RANGE BANDS (release moment; closest target)
-- Bands (meters): 0-2000, 2001-3000, 3001-4000, 4001-5000,
--                 5001-6000, 6001-7000, 7001+
-- Used for ROCKETS and autonomous Hellfire (HF_SELF).
-- ------------------------------------------------------------
local function rq_rangeBand7_m(range_m)
  local r = range_m or 0
  if r <= 2000 then return 1 end
  if r <= 3000 then return 2 end
  if r <= 4000 then return 3 end
  if r <= 5000 then return 4 end
  if r <= 6000 then return 5 end
  if r <= 7000 then return 6 end
  return 7
end

local function rq_dist2D(a, b)
  local dx = (a.x or 0) - (b.x or 0)
  local dz = (a.z or 0) - (b.z or 0)
  return math.sqrt(dx*dx + dz*dz)
end

local function rq_targetPointFromRec(rec)
  if not rec or not rec.name then return nil end
  if rec.kind == "unit" then
    local u = Unit.getByName(rec.name)
    if u and u:isExist() and u.getPoint then return u:getPoint() end
  elseif rec.kind == "static" then
    local s = StaticObject.getByName(rec.name)
    if s and s:isExist() and s.getPoint then return s:getPoint() end
  end
  return nil
end

local function rq_computeAutoBandOnce(run, shooterUnit)
  if not run or run.autoBandComputed then return end
  if not shooterUnit or not shooterUnit:isExist() or not shooterUnit.getPoint then
    run.autoBandComputed = true
    return
  end

  -- Only for ROCKETS, HF_SELF (autonomous Hellfire), and APKWS
  local t = run.task and run.task.type
  if t ~= "ROCKETS" and t ~= "HF_SELF" and t ~= "APKWS" then
    run.autoBandComputed = true
    return
  end

  local shooterPt = shooterUnit:getPoint()
  if not shooterPt then
    run.autoBandComputed = true
    return
  end
  local bestD, bestName

  for _, rec in ipairs(run.targets or {}) do
    local pt = rq_targetPointFromRec(rec)
    if pt then
      local d = rq_dist2D(shooterPt, pt)
      if (not bestD) or (d < bestD) then
        bestD = d
        bestName = rec.name
      end
    end
  end

  if bestD then
    local band = rq_rangeBand7_m(bestD)
    run.autoRangeM = bestD
    run.autoBand = band
    run.autoBandTarget = bestName
    if t == "ROCKETS" then
      run.rocketRangeBandAuto = band
    elseif t == "HF_SELF" then
      run.hfRangeBandAuto = band
    elseif t == "APKWS" then
      run.apkwsRangeBandAuto = band
    end
    rq_log(4, string.format("AutoBand: task %s band %d (%.0fm) closest %s", tostring(run.taskId), band, bestD, tostring(bestName)))
  end

  run.autoBandComputed = true
end


local function rq_msgToGroup(groupId, msg, sec)
  trigger.action.outTextForGroup(groupId, msg, sec or 10)
end


local function rq_playSound(groupId, sound)
  if groupId and sound then
    trigger.action.outSoundForGroup(groupId, sound)
  end
end


-- ------------------------------------------------------------
-- PLAYER GROUP HELPERS (for broadcast + WELCOME)
-- ------------------------------------------------------------
-- Forward declarations (used before definition later in file)
local rq_inZone

local function rq_forEachPlayerGroup(fn)
  for _, side in ipairs({coalition.side.BLUE, coalition.side.RED}) do
    for _, cat in ipairs({Group.Category.HELICOPTER, Group.Category.AIRPLANE}) do
      local groups = coalition.getGroups(side, cat) or {}
      for _, g in ipairs(groups) do
        if g and g:isExist() then
          -- Consider it "player group" if at least one unit has a player name.
          local units = g:getUnits() or {}
          local hasPlayer = false
          for i=1,#units do
            local u = units[i]
            if u and u:isExist() and u.getPlayerName then
              local pn = u:getPlayerName()
              if pn and pn ~= "" then hasPlayer = true; break end
            end
          end
          if hasPlayer then fn(g) end
        end
      end
    end
  end
end

local function rq_playSoundToAllPlayers(sound)
  if not sound then return end
  rq_forEachPlayerGroup(function(g)
    pcall(function() trigger.action.outSoundForGroup(g:getID(), sound) end)
  end)
end

local function rq_welcomeTick()
  local gcfg = (RANGEQUAL.cfg and RANGEQUAL.cfg.globals) or {}
  local fireZoneName = gcfg.fireZoneName or "FIRE_ZONE"
  local welcomeSound = gcfg.welcomeSound or "WELCOME.ogg"

  rq_forEachPlayerGroup(function(g)
    local units = g:getUnits() or {}
    local u = units[1]
    if not u or not u:isExist() then return end
    local uname = u:getName()
    if not uname then return end

    if not RANGEQUAL._state.welcomeHeard[uname] then
      if rq_inZone(u, fireZoneName) then
        RANGEQUAL._state.welcomeHeard[uname] = true
        RANGEQUAL._state.qualStartTime[uname] = rq_now()

        rq_playSound(g:getID(), welcomeSound)
      end
    end
  end)

  return rq_now() + (gcfg.welcomeTickSec or 1.0)
end



-- ------------------------------------------------------------
-- OUTCOME SOUNDS (match reason strings -> .ogg filenames)
-- NOTE: filenames are case-sensitive and must exist in the .miz.
-- ------------------------------------------------------------
local RQ_OUTCOME_SOUNDS = {
  HOLD              = "HOLD.ogg",
  CLEARED           = "CLEARED.ogg",

  EARLY_FIRE        = "EARLY_FIRE.ogg",
  FOUL_LINE         = "FOUL_LINE.ogg",
  FIRE_ZONE         = "FIRE_ZONE.ogg",
  MOTION_VIOLATION  = "MOTION_VIOLATION.ogg",
  WRONG_WEAPON      = "WRONG_WEAPON.ogg",

  OVERCOUNT_HF      = "OVERCOUNT_HF.ogg",
  OVERCOUNT_RKT     = "OVERCOUNT_RKT.ogg",
  OVERCOUNT_GUN     = "OVERCOUNT_GUN.ogg",

  NO_EFFECT         = "NO_EFFECT.ogg",
  EFFECT            = "EFFECT.ogg",
  IDLE_TIMEOUT      = "IDLE_TIMEOUT.ogg",
}

-- ===========================================================
-- Dynamic laser code generation (valid ranges for Apache)
-- ===========================================================
-- 1111-1788
-- 2111-2888
-- 4111-4288
-- 4311-4488
-- 4511-4688
-- 4711-4888
-- 5111-5288
-- 5311-5488
-- 5511-5688
-- 5711-5888
--
-- Sound sequence (to shooter group):
--   LASING_ON.ogg + W.ogg + X.ogg + Y.ogg + Z.ogg + LASER_OUTRO.ogg
--
local RQ_LASER_RANGES = {
  {1111,1788},
  {2111,2888},
  {4111,4288},
  {4311,4488},
  {4511,4688},
  {4711,4888},
  {5111,5288},
  {5311,5488},
  {5511,5688},
  {5711,5888},
}

-- Generate a random laser code uniformly across all valid codes in the ranges above.
local function rq_generateLaserCode()
  local total = 0
  for _, r in ipairs(RQ_LASER_RANGES) do
    total = total + (r[2] - r[1] + 1)
  end
  local pick = math.random(total)
  for _, r in ipairs(RQ_LASER_RANGES) do
    local n = (r[2] - r[1] + 1)
    if pick <= n then
      return r[1] + (pick - 1)
    end
    pick = pick - n
  end
  -- Fallback (should never happen)
  return 1688
end

-- Play laser code audio sequence to the given group.
local function rq_playLaserCodeAudio(groupId, code)
  local digits = tostring(code or "")
  if #digits ~= 4 then return end

  -- Timing assumptions:
  -- - Digit sound files are ~0.8s each.
  -- - Add small safety gaps to avoid overlap due to engine scheduling jitter.
  local DIGIT_LEN   = 0.80
  local DIGIT_GAP   = 0.00  -- safety gap between digit clips
  local DIGIT_STEP  = DIGIT_LEN + DIGIT_GAP
  local OUTRO_GAP   = 0.00  -- safety gap after last digit before outro

  rq_playSound(groupId, "LASING_ON.ogg")

  -- Start digits after LASING_ON. This offset was tuned by the mission owner.
  local digitStart = timer.getTime() + 1.54

  -- Schedule 4 digits: W X Y Z
  for i = 1, 4 do
    local d = digits:sub(i,i)
    local t = digitStart + ((i - 1) * DIGIT_STEP)
    timer.scheduleFunction(function()
      rq_playSound(groupId, d .. ".ogg")
      return nil
    end, nil, t)
  end

  -- Schedule outro after the last digit finishes (plus a safety gap)
  local outroTime = digitStart + (4 * DIGIT_STEP) + OUTRO_GAP
  timer.scheduleFunction(function()
    rq_playSound(groupId, "LASER_OUTRO.ogg")
    return nil
  end, nil, outroTime)
end

-- Shallow copy helper (so we can safely customize per-run task fields like laserCode)
local function rq_shallowCopy(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k,v in pairs(t) do
    if type(v) == "table" then
      -- one-level deep copy for common nested tables (allowed, etc.)
      local vv = {}
      for kk, vv0 in pairs(v) do vv[kk] = vv0 end
      o[k] = vv
    else
      o[k] = v
    end
  end
  return o
end


local function rq_playOutcomeSound(groupId, reason)
  if not groupId or not reason then return end
  local sound = RQ_OUTCOME_SOUNDS[reason]
  if sound then
    trigger.action.outSoundForGroup(groupId, sound)
  end
end


----------------------------------------------------------------
-- ZONE HELPERS (circle + polygon via env.mission)
----------------------------------------------------------------
local function rq_getMissionZoneRaw(name)
  if not env or not env.mission or not env.mission.triggers or not env.mission.triggers.zones then return nil end
  for _, z in pairs(env.mission.triggers.zones) do
    if z.name == name then return z end
  end
  return nil
end

local function rq_getZoneShape(name)
  if not name then return nil end
  RANGEQUAL._zoneCache = RANGEQUAL._zoneCache or {}
  local cached = RANGEQUAL._zoneCache[name]
  if cached ~= nil then return cached end

  local shape = nil

  -- Prefer mission polygon data if available (works for polygon + circle zones)
  local z = rq_getMissionZoneRaw(name)
  if z then
    -- Polygon: 'verticies' (ME misspelling) or 'points'
    local verts = nil
    if z.verticies and type(z.verticies) == "table" and #z.verticies >= 3 then
      verts = z.verticies
    elseif z.points and type(z.points) == "table" and #z.points >= 3 then
      verts = z.points
    end

    if verts then
      local pts = {}
      for i=1,#verts do
        local v = verts[i]
        if v and v.x and (v.y or v.z) then
          pts[#pts+1] = { x = v.x, z = v.z or v.y }
        end
      end
      if #pts >= 3 then
        shape = { kind = "poly", pts = pts }
      end
    end

    -- Circle (only if no poly parsed)
    if not shape and z.radius and z.radius > 0 and z.x and z.y then
      shape = { kind = "circle", cx = z.x, cz = z.y, r = z.radius }
    end
  end

  -- Fallback: circle-only API
  if not shape then
    local tz = trigger.misc.getZone(name)
    if tz and tz.point and tz.radius then
      shape = { kind = "circle", cx = tz.point.x, cz = tz.point.z, r = tz.radius }
    end
  end

  -- Cache result (including nil? We avoid caching nil so a later script reload can still resolve.)
  if shape then
    RANGEQUAL._zoneCache[name] = shape
  end
  return shape
end

local function rq_pointInPoly(p, polyPts)
  if not polyPts or #polyPts < 3 then return false end
  local inside = false
  local j = #polyPts
  for i=1,#polyPts do
    local xi, zi = polyPts[i].x, polyPts[i].z
    local xj, zj = polyPts[j].x, polyPts[j].z
    local denom = (zj - zi)
    if denom == 0 then denom = 1e-9 end
    local intersect = ((zi > p.z) ~= (zj > p.z)) and (p.x < (xj - xi) * (p.z - zi) / denom + xi)
    if intersect then inside = not inside end
    j = i
  end
  return inside
end

rq_inZone = function(unit, zoneName)
  if not unit or not unit:isExist() then return false end
  local shape = rq_getZoneShape(zoneName)
  if not shape then return false end

  local pt = unit:getPoint()
  if not pt then return false end
  local p2 = { x = pt.x, z = pt.z }

  if shape.kind == "circle" then
    local dx, dz = p2.x - shape.cx, p2.z - shape.cz
    return (dx*dx + dz*dz) <= (shape.r * shape.r)
  end
  return rq_pointInPoly(p2, shape.pts)
end

local function rq_getZoneVertices(zoneName)
  -- Robust extraction for ME polygon/quad-point zones.
  -- Some missions store vertices under different keys; we attempt known keys, then scan any table field.
  local z = rq_getMissionZoneRaw(zoneName)

  local function convert(list)
    if type(list) ~= "table" then return nil end
    local pts = {}

    if list[1] ~= nil then
      for i=1,#list do
        local v = list[i]
        if v and v.x and (v.y or v.z) then
          pts[#pts+1] = { x = v.x, z = v.z or v.y }
        end
      end
    else
      local keys = {}
      for k,_ in pairs(list) do
        if type(k) == "number" then keys[#keys+1] = k end
      end
      table.sort(keys)
      for _,k in ipairs(keys) do
        local v = list[k]
        if v and v.x and (v.y or v.z) then
          pts[#pts+1] = { x = v.x, z = v.z or v.y }
        end
      end
    end

    return (#pts >= 3) and pts or nil
  end

  if z then
    local pts =
      convert(z.vertices) or convert(z.verticies) or convert(z.points) or convert(z.verts) or convert(z.poly)

    if not pts then
      -- Generic scan: find ANY table field that looks like a vertex list
      for _, v in pairs(z) do
        local guess = convert(v)
        if guess then
          pts = guess
          break
        end
      end
    end

    return pts
  end

  -- Fallback: if our derived shape is poly, return it
  local shape = rq_getZoneShape(zoneName)
  if shape and shape.kind == "poly" then return shape.pts end
  return nil
end

local function rq_debugZone(zoneName, groupId, unit)
  local shape = rq_getZoneShape(zoneName)
  if not shape then
    rq_msgToGroup(groupId, "Zone '"..zoneName.."' not found or unsupported.", 10)
    return
  end

  local pt = unit:getPoint()
  if not pt then
    rq_msgToGroup(groupId, "Unable to get unit position.", 10)
    return
  end
  local inside = rq_inZone(unit, zoneName)

  if shape.kind == "circle" then
    rq_msgToGroup(groupId,
      string.format("Zone %s = CIRCLE cx=%.1f cz=%.1f r=%.1f | unit x=%.1f z=%.1f | inside=%s",
        zoneName, shape.cx, shape.cz, shape.r, pt.x, pt.z, tostring(inside)), 12)
  else
    local lines = {
      string.format("Zone %s = POLY (%d pts) | unit x=%.1f z=%.1f | inside=%s",
        zoneName, #shape.pts, pt.x, pt.z, tostring(inside))
    }
    for i=1,#shape.pts do
      lines[#lines+1] = string.format("P%d x=%.1f z=%.1f", i, shape.pts[i].x, shape.pts[i].z)
    end
    rq_msgToGroup(groupId, table.concat(lines, " | "), 15)
  end
end

----------------------------------------------------------------
-- TEMPLATE LOOKUP + SPAWN (GROUPS + STATIC GROUPS)
----------------------------------------------------------------
local function rq_deepCopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k,v in pairs(t) do r[k] = rq_deepCopy(v) end
  return r
end

local function rq_findUnitGroupTemplate(groupName)
  if not env or not env.mission or not env.mission.coalition then return nil end
  for _, coal in pairs(env.mission.coalition) do
    if coal.country then
      for _, ctry in pairs(coal.country) do
        -- airplanes
        if ctry and ctry.id and ctry.plane and ctry.plane.group then
          for _, g in pairs(ctry.plane.group) do
            if g.name == groupName then return {countryId=ctry.id, category=Group.Category.AIRPLANE, group=g} end
          end
        end
        -- helicopters
        if ctry and ctry.id and ctry.helicopter and ctry.helicopter.group then
          for _, g in pairs(ctry.helicopter.group) do
            if g.name == groupName then return {countryId=ctry.id, category=Group.Category.HELICOPTER, group=g} end
          end
        end
        -- vehicles (ground)
        if ctry and ctry.id and ctry.vehicle and ctry.vehicle.group then
          for _, g in pairs(ctry.vehicle.group) do
            if g.name == groupName then return {countryId=ctry.id, category=Group.Category.GROUND, group=g} end
          end
        end
        -- ships
        if ctry and ctry.id and ctry.ship and ctry.ship.group then
          for _, g in pairs(ctry.ship.group) do
            if g.name == groupName then return {countryId=ctry.id, category=Group.Category.SHIP, group=g} end
          end
        end
      end
    end
  end
  return nil
end

local function rq_findStaticGroupTemplate(staticGroupName)
  if not env or not env.mission or not env.mission.coalition then return nil end
  for _, coal in pairs(env.mission.coalition) do
    if coal.country then
      for _, ctry in pairs(coal.country) do
        if ctry and ctry.id and ctry.static and ctry.static.group then
          for _, sg in pairs(ctry.static.group) do
            if sg and sg.name == staticGroupName and sg.units and #sg.units > 0 then
              return {countryId=ctry.id, staticGroup=sg}
            end
          end
        end
      end
    end
  end
  return nil
end

local function rq_spawnGroupFromTemplate(templateName, suffix)
  local tpl = rq_findUnitGroupTemplate(templateName)
  if not tpl then return nil end

  local g = rq_deepCopy(tpl.group)

  -- Force immediate activation/visibility
  g.lateActivation = nil
  g.uncontrolled = nil
  g.hiddenOnPlanner = nil
  g.hiddenOnMFD = nil
  g.hiddenOnMissionPlanner = nil

  -- IMPORTANT: clear IDs so DCS assigns fresh ones (prevents silent spawn failures)
  g.groupId = nil
  g.groupId_ = nil
  g.hidden = nil

  g.lateActivation = false
  g.uncontrolled = false
  g.name = templateName .. (suffix or ("_SPAWN_" .. math.floor(rq_now()*1000)))

  if g.units then
    for i=1,#g.units do
      g.units[i].name = g.name .. "_U" .. i
      g.units[i].unitId = nil
      g.units[i].unitId_ = nil
      g.units[i].groupId = nil
      g.units[i].skill = g.units[i].skill or "Average"
      g.units[i].hidden = nil
    end
  -- Cache spawn anchor point (works even if DCS later reports group has no units)
  if g.units and g.units[1] and g.units[1].x and g.units[1].y then
    RANGEQUAL._spawnPts[g.name] = { x = g.units[1].x, z = g.units[1].y }
  end

  end

  local added = coalition.addGroup(tpl.countryId, tpl.category, g)
  if not added then
    return nil
  end

  local spawnedName = g.name

  -- Verify the group exists after a short delay (helps diagnose MP weirdness)
  timer.scheduleFunction(function()
    local gg = Group.getByName(spawnedName)
    if not gg or not gg:isExist() then
      return
    end
    local u = (gg:getUnits() or {})[1]
    if u and u:isExist() then
      local p = u:getPoint()
      if not p then return end
      -- Visual + text mark (debug)
      local h = land.getHeight({x=p.x, y=p.z})

    else
    end
  end, nil, rq_now() + 0.1)
  return spawnedName
end

local function rq_spawnStaticUnit(countryId, u)
  return coalition.addStaticObject(countryId, u)
end

local function rq_spawnStaticGroupFromTemplate(templateName, suffix)
  local tpl = rq_findStaticGroupTemplate(templateName)
  if not tpl then return nil end

  local sg = rq_deepCopy(tpl.staticGroup)
  local baseName = templateName .. (suffix or ("_SPAWN_" .. math.floor(rq_now()*1000)))

  local spawnedNames = {}

  for i=1,#(sg.units or {}) do
    local u = sg.units[i]
    if u then
      local newU = rq_deepCopy(u)
      newU.name = baseName .. "_S" .. i
      -- DCS static object uses x/y for map plane (y == z)
      -- Preserve original placement
      local ok = rq_spawnStaticUnit(tpl.countryId, newU)
      if ok then
        spawnedNames[#spawnedNames+1] = newU.name
      else
      end
    end
  end

  if #spawnedNames == 0 then
    return nil
  end
  return spawnedNames
end

local function rq_destroyGroupByName(name)
  if not name then return end
  local g = Group.getByName(name)
  if g and g:isExist() then
    rq_log(4, "DestroyGroup: " .. tostring(name))
    pcall(function() g:destroy() end)
    timer.scheduleFunction(function()
      local gg = Group.getByName(name)
      if gg and gg:isExist() then
        rq_log(2, "DestroyGroup WARN still exists: " .. tostring(name))
      else
        rq_log(4, "DestroyGroup OK: " .. tostring(name))
      end
      return nil
    end, nil, timer.getTime() + 0.1)
    return
  end

  -- Fallback: sometimes callers pass a UNIT name; if so, destroy its group
  local u = Unit.getByName(name)
  if u and u:isExist() then
    rq_log(4, "DestroyGroup fallback via Unit: " .. tostring(name))
    local ug = u:getGroup()
    if ug and ug:isExist() then pcall(function() ug:destroy() end) end
  end
end

local function rq_destroyStaticByName(name)
  if not name then return end
  local s = StaticObject.getByName(name)
  if s and s:isExist() then s:destroy() end
end

----------------------------------------------------------------
-- AMMO HELPERS (guns)
----------------------------------------------------------------
local function rq_getGunAmmo(unit)
  if not unit or not unit:isExist() then return 0 end
  local ammo = unit:getAmmo()
  if not ammo then return 0 end
  local total = 0
  for _, a in ipairs(ammo) do
    if a.desc and a.desc.category == Weapon.Category.SHELL and a.count then
      total = total + a.count
    end
  end
  return total
end

----------------------------------------------------------------
-- SCORING HELPERS
----------------------------------------------------------------
local function rq_lookupCurveLinear(curve, t)
  for _, row in ipairs(curve or {}) do
    if row and row[1] and row[2] then
      local maxT, pts = row[1], row[2]
      if t <= maxT then return pts end
    end
  end
  return 0
end

local function rq_getZeroCutoffFromCurve(curve)
  if not curve or #curve == 0 then return 0 end
  local lastRow = curve[#curve]
  if not lastRow or not lastRow[1] then return 0 end
  return lastRow[1]
end

local function rq_ceilDiv(a,b)
  if b == 0 then return 0 end
  return math.floor((a + b - 1) / b)
end

--------------------------------------------------------------------
-- ZONE CLEANUP (RANGE_CLEANUP)
--
-- IMPORTANT:
-- We do NOT destroy live units/statics by searching the zone.
-- Live objects are destroyed deterministically using the per-run lists
-- (run.spawnedGroups / run.spawnedStatics) in rq_cleanup(run).
--
-- Here we only remove junk (wreckage/craters/debris) via world.removeJunk().
-- This prevents the "cleanup overlap" problem where a new task spawns
-- targets inside the cleanup zone before the prior run's delayed cleanup fires.
--
-- Supports circle trigger zones AND polygon/quad trigger zones.
----------------------------------------------------------------
local RQ_CLEANUP_ZONE_NAME = "RANGE_CLEANUP"


-- Build a DCS search volume that matches our trigger zone.
-- Circle -> SPHERE, Polygon/Quad -> BOX (AABB in X/Z with configurable height).
local function rq_makeCleanupVolume(zoneName)
  local shape = rq_getZoneShape(zoneName)
  if not shape then return nil, nil, "Zone not found or unsupported: " .. tostring(zoneName) end

  if shape.kind == "circle" then
    local hy = 0
    if land and land.getHeight then
      hy = land.getHeight({ x = shape.cx, y = shape.cz })
    end
    local vol = {
      id = world.VolumeType.SPHERE,
      params = { point = { x = shape.cx, y = hy, z = shape.cz }, radius = shape.r }
    }
    return vol, shape, nil
  end

  -- Polygon/quad: use an axis-aligned bounding box in x/z
  local pts = shape.pts or rq_getZoneVertices(zoneName)
  if not pts or #pts < 3 then
    return nil, shape, "Polygon zone has no vertices: " .. tostring(zoneName)
  end

  local minX, maxX =  1e9, -1e9
  local minZ, maxZ =  1e9, -1e9
  for i=1,#pts do
    local p = pts[i]
    if p and p.x and p.z then
      if p.x < minX then minX = p.x end
      if p.x > maxX then maxX = p.x end
      if p.z < minZ then minZ = p.z end
      if p.z > maxZ then maxZ = p.z end
    end
  end

  local h = (RANGEQUAL.cfg and RANGEQUAL.cfg.globals and RANGEQUAL.cfg.globals.cleanupBoxHeightM) or 2000

  local vol = {
    id = world.VolumeType.BOX,
    params = {
      min = { x = minX, y = 0, z = minZ },
      max = { x = maxX, y = h, z = maxZ },
    }
  }
  return vol, shape, nil
end

-- Destroy Units + Statics in zone, then remove junk in the same volume.
-- Returns a summary table (best-effort; DCS APIs don't always report counts reliably).
local function rq_cleanupZoneJunkOnly(zoneName)
  if not (world and world.removeJunk and world.VolumeType) then
    rq_log(1, "Cleanup: world.removeJunk unavailable.")
    return { ok=false, err="removeJunk unavailable" }
  end

  local vol, shape, err = rq_makeCleanupVolume(zoneName)
  if not vol then
    rq_log(2, "Cleanup: " .. tostring(err))
    return { ok=false, err=err }
  end

  local passes = (RANGEQUAL.cfg and RANGEQUAL.cfg.globals and RANGEQUAL.cfg.globals.cleanupJunkPassesSec) or {0, 10, 30}
  local summary = {
    ok = true,
    zone = zoneName,
    volType = (vol.id == world.VolumeType.SPHERE) and "SPHERE" or "BOX",
    junkRemoved = {},
  }

  local function doJunkPass(delaySec)
    local ok, removed = pcall(function() return world.removeJunk(vol) end)
    summary.junkRemoved[#summary.junkRemoved+1] = { t = delaySec, ok = ok, removed = removed }
    if ok then
      rq_log(4, string.format("Cleanup: removeJunk pass t=+%ss removed=%s", tostring(delaySec), tostring(removed)))
    else
      rq_log(2, "Cleanup: removeJunk failed on pass t=+" .. tostring(delaySec))
    end
  end

  for _, d in ipairs(passes) do
    local delay = tonumber(d) or 0
    if delay <= 0 then
      doJunkPass(0)
    else
      timer.scheduleFunction(function()
        doJunkPass(delay)
        return nil
      end, nil, rq_now() + delay)
    end
  end

  rq_log(3, string.format("CleanupJunk(%s): vol=%s (junk passes=%d)",
    tostring(zoneName), summary.volType, #passes))

  return summary
end


-- Safety-net: destroy UNIT groups inside cleanup zone whose group name starts with prefix (e.g. "T05_TEA_").
-- This avoids "special TEA logic" while still being deterministic and safe.
local function rq_wipeNamedGroupsInCleanupZone(prefix)
  -- Safety-net: destroy UNIT groups and STATIC objects inside cleanup zone that match a name prefix.
  -- Used only to catch orphaned TEA markers from prior runs/builds.
  if not prefix then return end
  local cfg = (RANGEQUAL and RANGEQUAL.cfg) or {}
  local g   = cfg.globals or {}
  local zoneName = g.cleanupZoneName or "RANGE_CLEANUP"

  local vol = nil
  if rq_makeCleanupVolume then
    vol = select(1, rq_makeCleanupVolume(zoneName))
  end
  if not vol then
    rq_log(2, "Cleanup: cannot build cleanup volume for " .. tostring(zoneName))
    return
  end

  -- UNIT groups
  local seen = {}
  world.searchObjects(Object.Category.UNIT, vol, function(obj)
    local u = obj
    if u and u:isExist() then
      local g = u:getGroup()
      if g and g:isExist() then
        local gn = g:getName()
        if gn and (gn:sub(1, #prefix) == prefix) and not seen[gn] then
          seen[gn] = true
          rq_log(3, "Cleanup: zone wipe group " .. gn)
          pcall(function() g:destroy() end)
        end
      end
    end
    return true
  end)

  -- STATIC objects
  world.searchObjects(Object.Category.STATIC, vol, function(obj)
    local s = obj
    if s and s:isExist() then
      local sn = s:getName()
      if sn and (sn:sub(1, #prefix) == prefix) then
        rq_log(3, "Cleanup: zone wipe static " .. sn)
        pcall(function() s:destroy() end)
      end
    end
    return true
  end)
end



local function rq_cleanup(run)
  if not run then return end
  if run._cleaned then return end
  run._cleaned = true

  -- Destroy all spawned unit groups (targets, JTAC, etc.)
  if run.spawnedGroups then
    for _, gname in ipairs(run.spawnedGroups) do rq_destroyGroupByName(gname) end
  end

  -- Destroy JTAC group (HF_REMOTE tasks)
  if run.spawnedJTAC then
    rq_destroyGroupByName(run.spawnedJTAC)
  end

  -- Safety-net: wipe any TEA groups in cleanup zone for this taskId
  if run.taskId then
    rq_wipeNamedGroupsInCleanupZone(string.format("T%02d_TEA_MARK_", run.taskId))
  end

  -- Destroy spawned static objects (if this task used a static-group template)
  if run.spawnedStatics then
    for _, sname in ipairs(run.spawnedStatics) do rq_destroyStaticByName(sname) end
  end

  -- stop JTAC laser spot (inline to avoid forward-declare issues)
  if run.laser and run.laser.spot and Spot and Spot.destroy then
    Spot.destroy(run.laser.spot)
  end
  run.laser = nil
end

local function rq_cleanupLater(run)
  if not run then return end
  if run._cleanupScheduled then return end
  run._cleanupScheduled = true
  local delay = (RANGEQUAL.cfg and RANGEQUAL.cfg.globals and RANGEQUAL.cfg.globals.cleanupDelaySec) or 0.5
  timer.scheduleFunction(function()
    rq_cleanup(run)
    local res = rq_cleanupZoneJunkOnly(RQ_CLEANUP_ZONE_NAME)
    if not (res and res.ok) then rq_log(2, "Zone cleanup failed for "..tostring(RQ_CLEANUP_ZONE_NAME) .. " : " .. tostring(res and res.err)) end
    return nil
  end, nil, rq_now() + delay)
end

local function rq_recordScore(ownerUnitName, taskId, points, elapsed, reason)
  local s = RANGEQUAL._state.score[ownerUnitName]
  if not s then
    s = { bestByTask = {}, last = nil }
    RANGEQUAL._state.score[ownerUnitName] = s
  end
  local best = s.bestByTask[taskId]
  if (best == nil) or (points > best) then
    s.bestByTask[taskId] = points
  end
  s.last = { taskId=taskId, points=points, elapsed=elapsed, reason=reason }
end

----------------------------------------------------------------
-- STATUS + SCORE CODE (per aircraft / per group)
----------------------------------------------------------------

local function rq_totalScoreForUnit(ownerUnitName)
  local s = RANGEQUAL._state.score[ownerUnitName]
  if not s or not s.bestByTask then return 0 end
  local total = 0
  for i = 1, 10 do
    local v = s.bestByTask[i]
    if v and v > 0 then total = total + v end
  end
  return total
end

-- Check if at least 7 of 10 tasks have non-zero scores
local function rq_sevenTasksComplete(ownerUnitName)
  local s = RANGEQUAL._state.score[ownerUnitName]
  if not s or not s.bestByTask then 
    return false
  end
  
  local completedTasks = 0
  for taskId = 1, 10 do
    local score = s.bestByTask[taskId]
    if score and score > 0 then
      completedTasks = completedTasks + 1
    end
  end
  
  return completedTasks >= 7
end

-- Check if player qualifies: total score >= 700 AND at least 7 of 10 tasks have non-zero scores
-- Also determine tier: DISTINGUISHED (900+), SUPERIOR (800-899), QUALIFIED (700-799)
local function rq_checkQualification(ownerUnitName)
  local s = RANGEQUAL._state.score[ownerUnitName]
  if not s or not s.bestByTask then 
    return false, "UNQUALIFIED", "No scores recorded"
  end
  
  -- Check total score
  local total = rq_totalScoreForUnit(ownerUnitName)
  if total < 700 then
    return false, "UNQUALIFIED", string.format("Total score %d is below 700", total)
  end
  
  -- Count completed tasks (non-zero scores)
  local completedTasks = 0
  local incompleteTasks = {}
  for taskId = 1, 10 do
    local score = s.bestByTask[taskId]
    if score and score > 0 then
      completedTasks = completedTasks + 1
    else
      table.insert(incompleteTasks, taskId)
    end
  end
  
  -- Check that at least 7 tasks are complete
  if completedTasks < 7 then
    local taskList = table.concat(incompleteTasks, ", ")
    return false, "UNQUALIFIED", string.format("Only %d of 10 tasks complete (need 7). Incomplete: %s", completedTasks, taskList)
  end
  
  -- Determine tier based on Army FM 1-140 standards
  local tier
  if total >= 900 then
    tier = "DISTINGUISHED"
  elseif total >= 800 then
    tier = "SUPERIOR"
  else
    tier = "QUALIFIED"
  end
  
  return true, tier, nil
end

-- 8-letter SCORE CODE (A-Z only): 6 letters encode (score 0-1000 + timeSec 0-10800 + sevenTasksComplete flag), plus 2-letter checksum.
-- Layout: AAAAAAA + CC (no spaces)
-- Not intended to be secure; designed to be typo-resistant.
local RQ_SCORECODE = {
  BASE = 26,
  TMAX = 10800,          -- 3 hours
  MOD6 = 26^6,           -- 308,915,776
  OFFSET5 = 26^5,        -- 11,881,376 (used to reduce leading A)
  A = 3571,              -- obfuscation multiplier (coprime with MOD6)
  B = 12345,             -- obfuscation offset
  CHECK_P = 7919,        -- checksum multiplier
  CHECK_K = 421,         -- checksum salt
}

local function rq_toBase26(n, len)
  local chars = {}
  for i = 1, len do
    local r = n % 26
    chars[len - i + 1] = string.char(65 + r) -- A=0..Z=25
    n = math.floor(n / 26)
  end
  return table.concat(chars)
end

local function rq_makeScoreCode(total, timeSec, sevenTasksComplete)
  local score = tonumber(total) or 0
  if score < 0 then score = 0 end
  if score > 1000 then score = 1000 end

  local t = tonumber(timeSec) or 0
  if t < 0 then t = 0 end
  if t > RQ_SCORECODE.TMAX then t = RQ_SCORECODE.TMAX end

  -- Encode sevenTasksComplete flag (1 if true, 0 if false)
  local flag = sevenTasksComplete and 1 or 0

  -- Pack score + time + flag into a single payload integer
  -- payload = (score * (TMAX + 1) + time) * 2 + flag
  local payload = (score * (RQ_SCORECODE.TMAX + 1) + t) * 2 + flag

  -- Obfuscate (reversible permutation): obf = (payload*A + B) mod 26^6
  local obf = (payload * RQ_SCORECODE.A + RQ_SCORECODE.B) % RQ_SCORECODE.MOD6

  -- Shift by 26^5 so the first letter is rarely A (about 1/26 chance of wrap).
  local obfShift = (obf + RQ_SCORECODE.OFFSET5) % RQ_SCORECODE.MOD6

  local dataPart = rq_toBase26(obfShift, 6)

  -- 2-letter checksum over obf
  local chk = (obfShift * RQ_SCORECODE.CHECK_P + RQ_SCORECODE.CHECK_K) % (26^2)
  local chkPart = rq_toBase26(chk, 2)

  return dataPart .. chkPart
end
function rq_showStatusForUnit(ownerUnitName)
  local s = RANGEQUAL._state.score[ownerUnitName]
  local lines = {}
  lines[#lines+1] = "---RANGE REPORT---"

  local total = 0
  for taskId = 1, 10 do
    local v = s and s.bestByTask and s.bestByTask[taskId] or nil
    if v == nil then
      lines[#lines+1] = string.format("Task %d: -", taskId)
    else
      lines[#lines+1] = string.format("Task %d: %d", taskId, v)
      if v > 0 then total = total + v end
    end
  end

  -- Time for score code:
-- If perfect achieved: time to perfect (WELCOME/spawn-on-range start -> perfect)
-- Else: time from start -> moment report requested.
local startT = RANGEQUAL._state.qualStartTime and RANGEQUAL._state.qualStartTime[ownerUnitName] or nil
local pe = RANGEQUAL._state.perfectElapsed and RANGEQUAL._state.perfectElapsed[ownerUnitName] or nil
local timeSec = 0
if pe then
  timeSec = math.floor((pe or 0) + 0.5)
elseif startT then
  timeSec = math.floor((rq_now() - startT) + 0.5)
else
  timeSec = 0
end

-- Check if at least 7 tasks are complete (non-zero scores)
local sevenTasksComplete = rq_sevenTasksComplete(ownerUnitName)

local code = rq_makeScoreCode(total, timeSec, sevenTasksComplete)
  lines[#lines+1] = string.format("TOTAL: %d", total)
  lines[#lines+1] = string.format("SCORE CODE: %s", code)
  
  -- Add qualification status with tier
  local qualified, tier, reason = rq_checkQualification(ownerUnitName)
  if qualified then
    lines[#lines+1] = string.format("STATUS: %s", tier)
  else
    lines[#lines+1] = string.format("STATUS: %s", tier)
    if reason then
      lines[#lines+1] = "REASON: " .. reason
    end
  end


  local pe = RANGEQUAL._state.perfectElapsed and RANGEQUAL._state.perfectElapsed[ownerUnitName] or nil
  if pe then
    local sec = math.floor((pe or 0) + 0.5)
    local mm = math.floor(sec / 60)
    local ss = sec % 60
    lines[#lines+1] = string.format("TIME TO PERFECT SCORE: %02d:%02d", mm, ss)
  end

  -- Option A: 1 unit per group; show to group to ensure visibility
  local unit = Unit.getByName(ownerUnitName)
  if unit and unit:isExist() then
    local g = unit:getGroup()
    if g and g:isExist() then
      rq_msgToGroup(g:getID(), table.concat(lines, "\n"), 15)
      return
    end
  end
  trigger.action.outText(table.concat(lines, "\n"), (RANGEQUAL.cfg.globals and RANGEQUAL.cfg.globals.reportOutTextSec) or 15)
end

----------------------------------------------------------------
-- JTAC LASER (Spot.createLaser)
----------------------------------------------------------------

local function rq_laserAvailable()
  return Spot and Spot.createLaser and Spot.setPoint and Spot.destroy
end

local function rq_laserStart(run, jtacUnitName, targetUnitName, code)
  if not rq_laserAvailable() then
    return false
  end

  local jtac = Unit.getByName(jtacUnitName)
  local tgt  = Unit.getByName(targetUnitName)
  if not jtac or not jtac:isExist() or not tgt or not tgt:isExist() then
    return false
  end

  local targetPoint = tgt:getPoint()
  if not targetPoint then
    return false
  end
  local localRef = { x = 0, y = 1, z = 0 } -- 1m above JTAC (per Hoggit example)

  -- Hoggit signature:
  --   Spot.createLaser(Object Source, Vec3 localRef, Vec3 pointTarget, number laseCode)
  local spot = Spot.createLaser(jtac, localRef, targetPoint, code or 1688)
  if not spot then
    return false
  end

  run.laser = {
    spot = spot,
    jtacUnitName = jtacUnitName,
    targetUnitName = targetUnitName,
    code = code or 1688,
  }
  return true
end

local function rq_laserUpdate(run)
  if not (run and run.laser and run.laser.spot) then return end
  if not rq_laserAvailable() then return end

  local tgt = Unit.getByName(run.laser.targetUnitName)
  if not tgt or not tgt:isExist() then return end

  local p = tgt:getPoint()
  if not p then return end
  Spot.setPoint(run.laser.spot, { x=p.x, y=p.y, z=p.z })
end

local function rq_laserStop(run)
  if not (run and run.laser and run.laser.spot) then return end
  if rq_laserAvailable() then
    Spot.destroy(run.laser.spot)
  end
  run.laser = nil
end


----------------------------------------------------------------
-- TEA CORNERS (per-task corner vehicle templates)
-- For rocket tasks, you will place 4 late-activated VEHICLE groups per task:
--   T05_TEA_P1 .. T05_TEA_P4 (same for other rocket tasks)
-- Group name and unit name may be identical (OK).
--
-- We CLONE these templates so tasks can be repeated.
----------------------------------------------------------------

-- Some mission-build workflows (like yours) load the TEA corner objects from a template
-- when the task is activated, and the objects are best referenced by UNIT NAME.
-- Support both:
--   A) Unit names exist already:  T05_TEA_P1 .. T05_TEA_P4
--   B) Group templates exist:     groups named T05_TEA_P1 .. T05_TEA_P4 that we clone
--
local function rq_getTEACornerZonePoints(taskId)
  local pts = {}
  for i=1,4 do
    local zname = string.format("T%02d_TEA_ZONE%d", taskId, i)
    local z = trigger.misc.getZone(zname)
    if z and z.point then
      pts[#pts+1] = { x = z.point.x, z = z.point.z, name = zname }
    else
      rq_log(2, "TEA: missing corner zone " .. zname)
    end
  end
  if #pts >= 4 then return pts end
  return nil
end


-- Cache for TEA static template info (type/country/heading)
RANGEQUAL._teaTemplate = RANGEQUAL._teaTemplate or nil

local function rq_getTEAStaticTemplate()
  if RANGEQUAL._teaTemplate then return RANGEQUAL._teaTemplate end
  local tpl = StaticObject and StaticObject.getByName and StaticObject.getByName("TEA_TEMPLATE") or nil
  if not tpl or not tpl:isExist() then
    rq_log(2, "TEA: Static template TEA_TEMPLATE not found (expected a mission-placed static).")
    return nil
  end

  local desc = tpl:getDesc() or {}
  local typeName = desc.typeName or desc.type or desc.displayName
  local countryId = nil
  if tpl.getCountry then countryId = tpl:getCountry() end

  local heading = 0
  if tpl.getPosition then
    local pos = tpl:getPosition()
    if pos and pos.x and pos.x.z and pos.x.x then
      -- heading around y-axis from x-axis vector
      heading = math.atan2(pos.x.z, pos.x.x)
    end
  end

  RANGEQUAL._teaTemplate = { typeName = typeName, countryId = countryId, heading = heading }
  rq_log(4, string.format("TEA: cached template type=%s country=%s heading=%.3f",
    tostring(typeName), tostring(countryId), heading))
  return RANGEQUAL._teaTemplate
end

local function rq_spawnTEAStaticMarksForTask(run, taskId, cornerPts)
  if not run or not taskId then return nil end
  local tpl = rq_getTEAStaticTemplate()
  if not tpl or not tpl.typeName or not tpl.countryId then
    rq_log(2, "TEA: cannot spawn marks (template missing typeName or countryId).")
    return nil
  end

  cornerPts = cornerPts or rq_getTEACornerZonePoints(taskId)
  if not cornerPts then
    rq_log(2, "TEA: cannot spawn marks (missing corner zones for task " .. tostring(taskId) .. ").")
    return nil
  end

  run.spawnedStatics = run.spawnedStatics or {}
  local spawned = {}

  local runKey = tostring(run.runId or math.floor(rq_now()*1000))
  for i=1,4 do
    local p = cornerPts[i]
    if p then
      local sname = string.format("T%02d_TEA_MARK_%s_%d", taskId, runKey, i)
      local sdata = {
        name = sname,
        type = tpl.typeName,
        x = p.x,
        y = p.z, -- DCS static uses x/y where y is world Z
        heading = tpl.heading or 0,
        dead = false,
      }
      local ok, obj = pcall(function() return coalition.addStaticObject(tpl.countryId, sdata) end)
      if ok and obj then
        spawned[#spawned+1] = sname
        run.spawnedStatics[#run.spawnedStatics+1] = sname
        rq_log(4, "TEA: spawned static mark " .. sname .. " at (" .. math.floor(p.x) .. "," .. math.floor(p.z) .. ")")
      else
        rq_log(2, "TEA: FAILED to spawn static mark " .. sname)
      end
    end
  end

  return spawned
end

local function rq_buildTEAPolyFromCorners(cornerGroupNames)
  if not cornerGroupNames or #cornerGroupNames < 4 then return nil end
  local pts = {}

  for i=1,#cornerGroupNames do
    local gname = cornerGroupNames[i]
    local gotPt = false

    -- Preferred: first unit in the spawned group
    local g = Group.getByName(gname)
    if g and g:isExist() then
      local units = g:getUnits() or {}
      local u = units[1]
      if u and u:isExist() then
        local p = u:getPoint()
        if p then
          pts[#pts+1] = { x = p.x, z = p.z }
          gotPt = true
        end
      end
    end

    -- Fallback: we rename units on spawn to <group>_U1, so look that up directly.
    if not gotPt then
      local uname = gname .. "_U1"
      local u2 = Unit.getByName(uname)
      if u2 and u2:isExist() then
        local p = u2:getPoint()
        if p then
          pts[#pts+1] = { x = p.x, z = p.z }
          gotPt = true
        end
      end
    end

    -- Fallback: use cached spawn anchor point (works even if group reports zero units)
    if not gotPt and RANGEQUAL._spawnPts and RANGEQUAL._spawnPts[gname] then
      local p = RANGEQUAL._spawnPts[gname]
      pts[#pts+1] = { x = p.x, z = p.z }
      gotPt = true
    end

    -- Fallback: if these markers are statics, they won't show up as Units.
    if not gotPt then
      local s = StaticObject.getByName(gname) or StaticObject.getByName(gname .. "_U1")
      if s and s:isExist() then
        local p = s:getPoint()
        if p then
          pts[#pts+1] = { x = p.x, z = p.z }
          gotPt = true
        end
      end
    end
  end

  if #pts < 4 then return nil end
  return rq_sortPolyPts(pts)
end


-- Sort any set of points into a simple polygon loop (angle around centroid).
-- Works well for rectangles and convex quads.
function rq_sortPolyPts(pts)
  if not pts or #pts < 3 then return pts end
  local cx, cz = 0, 0
  for i=1,#pts do cx = cx + pts[i].x; cz = cz + pts[i].z end
  cx = cx / #pts; cz = cz / #pts
  table.sort(pts, function(a,b)
    local aa = math.atan2(a.z - cz, a.x - cx)
    local bb = math.atan2(b.z - cz, b.x - cx)
    return aa < bb
  end)
  return pts
end

local function rq_buildTEAPolyForTask(run, taskId)
  -- Rocket tasks use TEA corner trigger zones (Txx_TEA_ZONE1..4) to define the polygon.
  -- Visual corner markers are spawned as statics cloned from TEA_TEMPLATE only while the task is active.
  if not run then return nil end

  local cornerPts = rq_getTEACornerZonePoints(taskId)
  if not cornerPts then return nil end

  -- Spawn visual markers (statics) for this active run/task
  rq_spawnTEAStaticMarksForTask(run, taskId, cornerPts)

  -- Build polygon points (x,z)
  local poly = {}
  for i=1,4 do
    local p = cornerPts[i]
    if p then poly[#poly+1] = { x = p.x, z = p.z } end
  end
  if #poly < 4 then return nil end

  -- Order corners into a consistent winding so polygon tests behave
  return rq_sortPolyPts(poly)
end

----------------------------------------------------------------
-- WEAPON TYPE HELPERS


local function rq_getHellfireRemaining(unit)
  if not unit or not unit.getAmmo then return nil end
  local ammo = unit:getAmmo() or {}
  local count = 0
  for _, a in ipairs(ammo) do
    if a and a.desc and a.desc.category == Weapon.Category.MISSILE then
      local dn = ((a.desc.displayName or a.desc.typeName or ""):lower())
      if dn:find("agm") or dn:find("hellfire") or dn:find("114") then
        count = count + (a.count or 0)
      end
    end
  end
  return count
end

local function rq_getAPKWSRemaining(unit)
  if not unit or not unit.getAmmo then return nil end
  local ammo = unit:getAmmo() or {}
  local count = 0
  for _, a in ipairs(ammo) do
    if a and a.desc then
      local dn = ((a.desc.displayName or a.desc.typeName or ""):lower())
      if dn:find("apkws") or dn:find("advanced precision") then
        count = count + (a.count or 0)
      elseif a.desc.category == Weapon.Category.ROCKET and dn:find("guided") then
        count = count + (a.count or 0)
      end
    end
  end
  return count
end

local function rq_getStingerRemaining(unit)
  if not unit or not unit.getAmmo then return nil end
  local ammo = unit:getAmmo() or {}
  local count = 0
  for _, a in ipairs(ammo) do
    if a and a.desc and a.desc.category == Weapon.Category.MISSILE then
      local dn = ((a.desc.displayName or a.desc.typeName or ""):lower())
      if dn:find("stinger") or dn:find("fim-92") or dn:find("fim92") or dn:find("atas") then
        count = count + (a.count or 0)
      end
    end
  end
  return count
end

----------------------------------------------------------------
local function rq_weaponIsRocket(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  if desc.category == Weapon.Category.ROCKET then return true end
  if desc.displayName and string.find(string.lower(desc.displayName), "rocket", 1, true) then return true end
  return false
end

local function rq_weaponIsHellfire(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  if desc.category ~= Weapon.Category.MISSILE then return false end

  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- Be permissive: DCS often labels Hellfires as AGM-114 variants without the word "hellfire".
  if dn:find("hellfire", 1, true) then return true end
  if dn:find("agm", 1, true) and dn:find("114", 1, true) then return true end
  if dn:find("114", 1, true) then return true end

  return false
end


-- Countermeasures / non-qualifying shots we ignore for "wrong weapon" fouls.
local function rq_weaponIsCountermeasure(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- Common names across modules: flare/chaff/decoy
  if dn:find("flare", 1, true) or dn:find("chaff", 1, true) or dn:find("decoy", 1, true) then return true end
  return false
end

local function rq_weaponIsGunShell(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  return desc.category == Weapon.Category.SHELL
end

-- Specific gun type detection for different aircraft
local function rq_weaponIsGun30mm(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  if desc.category ~= Weapon.Category.SHELL then return false end
  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- M230 30mm chain gun
  if dn:find("m230", 1, true) or dn:find("30mm", 1, true) or dn:find("30 mm", 1, true) then return true end
  return false
end

local function rq_weaponIsGun50cal(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  if desc.category ~= Weapon.Category.SHELL then return false end
  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- .50 cal machine gun
  if dn:find("50 cal", 1, true) or dn:find(".50", 1, true) or dn:find("m2", 1, true) then return true end
  if dn:find("12.7", 1, true) or dn:find("12.7mm", 1, true) then return true end
  return false
end

local function rq_weaponIsGunM4(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  if desc.category ~= Weapon.Category.SHELL then return false end
  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- M4 rifle (5.56mm)
  if dn:find("m4", 1, true) or dn:find("5.56", 1, true) then return true end
  if dn:find("rifle", 1, true) then return true end
  return false
end

local function rq_weaponIsAPKWS(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- APKWS (Advanced Precision Kill Weapon System) - laser-guided rocket
  if dn:find("apkws", 1, true) then return true end
  if dn:find("advanced precision", 1, true) then return true end
  -- Some missions may label as guided rocket
  if desc.category == Weapon.Category.ROCKET and dn:find("guided", 1, true) then return true end
  return false
end

local function rq_weaponIsStinger(weapon)
  if not weapon or not weapon:isExist() then return false end
  local desc = weapon:getDesc()
  if not desc then return false end
  if desc.category ~= Weapon.Category.MISSILE then return false end
  local dn = ((desc.displayName or desc.typeName or ""):lower())
  -- Stinger air-to-air missile (FIM-92)
  if dn:find("stinger", 1, true) then return true end
  if dn:find("fim-92", 1, true) or dn:find("fim92", 1, true) then return true end
  if dn:find("atas", 1, true) then return true end  -- Air-To-Air Stinger
  return false
end

-- Returns true if this release is allowed for the current task.
-- Note: gun tasks are primarily enforced via S_EVENT_SHOOTING_START (no weapon object).
local function rq_isAllowedWeaponForTask(task, weapon)
  if not task then return false end

  -- Ignore countermeasures entirely (do not foul).
  if rq_weaponIsCountermeasure(weapon) then return true end

  local tt = task.type
  if tt == "ROCKETS" then
    -- APKWS must be checked first before generic rockets
    return rq_weaponIsRocket(weapon) and not rq_weaponIsAPKWS(weapon)
  elseif tt == "APKWS" then
    return rq_weaponIsAPKWS(weapon)
  elseif tt == "HF_SELF" or tt == "HF_REMOTE" then
    return rq_weaponIsHellfire(weapon)
  elseif tt == "STINGER" then
    return rq_weaponIsStinger(weapon)
  elseif tt == "GUN30MM" then
    return rq_weaponIsGun30mm(weapon)
  elseif tt == "GUN50CAL" then
    return rq_weaponIsGun50cal(weapon)
  elseif tt == "GUNM4" then
    return rq_weaponIsGunM4(weapon)
  elseif tt == "GUN" then
    -- Legacy gun type - allow any gun shell
    return rq_weaponIsGunShell(weapon)
  end
  return false
end

----------------------------------------------------------------
-- ROCKET IMPACT TRACKING (TEA)
----------------------------------------------------------------
local function rq_tickWeaponTracking(run)
  if not run or not run.weaponTrack then return end
  if run.state ~= "HOT" then return end
  if run.task.type ~= "ROCKETS" then return end
  if run.effectAchieved then return end

  local remaining = {}
  local teaVerts = run.teaPoly
  if not teaVerts or #teaVerts < 3 then return end

  for i=1,#run.weaponTrack do
    local wrec = run.weaponTrack[i]
    local w = wrec.weapon

    if w and w:isExist() then
      local p = w:getPoint()
      if p then
        wrec.last = { x=p.x, z=p.z }
        remaining[#remaining+1] = wrec
      end
    else
      if wrec.last then
        local inside = rq_pointInPoly({x=wrec.last.x, z=wrec.last.z}, teaVerts)
        if inside then
          rq_markRocketImpact(run, {x=wrec.last.x, y=0, z=wrec.last.z}, true)
        else
          rq_markRocketImpact(run, {x=wrec.last.x, y=0, z=wrec.last.z}, false)
        end
        if inside then
          run.teaHits = run.teaHits + 1
          -- Rocket tasks: "qualification" (meeting required impacts) locks the time,
          -- but the run continues until allowed rockets are expended, idle timeout, or a perfect run.
          local req = (run.task.requiredInZoneImpacts or 2)
          if (not run.qualified) and run.teaHits >= req then
            run.qualified = true
            run.qualifyTime = rq_now()
            rq_log(3, string.format("Rocket qualified: hits=%d req=%d t=%.1fs", run.teaHits, req, (run.qualifyTime - (run.t0 or run.qualifyTime))))
          end
        end
      end
    end
  end

  run.weaponTrack = remaining
end


----------------------------------------------------------------
-- HELLFIRE IMPACT/MISS TRACKING
-- We track Hellfire weapon objects similarly to rockets so we can
-- end the run as NO_EFFECT once all allowed missiles have resolved.
----------------------------------------------------------------
local function rq_tickHellfireTracking(run)
  if not run or not run.hfTrack then return end
  if run.state ~= "HOT" then return end
  if not (run.task.type == "HF_SELF" or run.task.type == "HF_REMOTE") then return end
  if run.effectAchieved then
    -- Don't bother tracking misses once we already have success pending.
    run.hfTrack = {}
    return
  end

  local remaining = {}
  for i=1,#run.hfTrack do
    local wrec = run.hfTrack[i]
    local w = wrec.weapon
    if w and w:isExist() then
      local p = w:getPoint()
      if p then
        wrec.last = { x=p.x, z=p.z }
        remaining[#remaining+1] = wrec
      end
    else
      -- Weapon disappeared (impact or despawn). If no effect happened, count as a miss.
      run.hfMisses = (run.hfMisses or 0) + 1
    end
  end
  run.hfTrack = remaining
end

----------------------------------------------------------------
-- MAX WAIT (0-point cutoff) per task
----------------------------------------------------------------
local function rq_computeMaxWaitSec(run)
  if not run or not run.task then return 0 end
  local taskType = run.task.type

  if taskType == "HF_SELF" then
    local band = run.hfRangeBandAuto or 7
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.HF_SELF[band] or {})
  elseif taskType == "HF_REMOTE" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.HF_REMOTE or {})
  elseif taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL" or taskType == "GUNM4" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.GUN_STD or {})
  elseif taskType == "APKWS" then
    local band = run.apkwsRangeBandAuto or 7
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.APKWS_STD[band] or {})
  elseif taskType == "STINGER" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.STINGER_STD or {})
  elseif taskType == "ROCKETS" then
    local allowedRockets = run.task.allowed and run.task.allowed.rockets or 0
    local scoringPairs = rq_ceilDiv(allowedRockets, 2)
    local band = run.rocketRangeBandAuto or 7
    local tbl = RANGEQUAL.cfg.curves[run.task.rocketCurve]
    local curve = tbl and tbl[scoringPairs] and tbl[scoringPairs][band] or {}
    return rq_getZeroCutoffFromCurve(curve)
  end
  return 0
end

-- Dynamic timeout based on initial range band (calculated at task selection)
local function rq_computeDynamicTimeout(run)
  if not run or not run.task then return 120 end  -- Fallback to old default
  local band = run.timeoutRangeBand or 7
  local taskType = run.task.type

  if taskType == "HF_SELF" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.HF_SELF[band] or {})
  elseif taskType == "HF_REMOTE" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.HF_REMOTE or {})
  elseif taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL" or taskType == "GUNM4" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.GUN_STD or {})
  elseif taskType == "APKWS" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.APKWS_STD[band] or {})
  elseif taskType == "STINGER" then
    return rq_getZeroCutoffFromCurve(RANGEQUAL.cfg.curves.STINGER_STD or {})
  elseif taskType == "ROCKETS" then
    local allowedRockets = run.task.allowed and run.task.allowed.rockets or 0
    local scoringPairs = rq_ceilDiv(allowedRockets, 2)
    local tbl = RANGEQUAL.cfg.curves[run.task.rocketCurve]
    local curve = tbl and tbl[scoringPairs] and tbl[scoringPairs][band] or {}
    return rq_getZeroCutoffFromCurve(curve)
  end
  return 120  -- Fallback
end

-- Dynamic gun end pad based on bullet flight time to target
local function rq_computeGunEndPad(run)
  if not run or not run.task then
    return 15  -- Fallback to old default for non-gun tasks
  end

  local taskType = run.task.type
  local isGunTask = (taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL" or taskType == "GUNM4")
  if not isGunTask then
    return 15  -- Fallback for non-gun tasks
  end

  local rangeM = run.timeoutRangeM or 7000  -- Use range calculated at task selection
  local gcfg = RANGEQUAL.cfg and RANGEQUAL.cfg.globals or {}
  local buffer = gcfg.gunEndPadBufferSec or 2.0  -- seconds

  -- Get aircraft-specific gun velocity
  local ownerUnit = Unit.getByName(run.ownerUnitName)
  local bulletVel = 805  -- Default fallback
  if ownerUnit and ownerUnit:isExist() then
    local aircraftConfig = rq_getAircraftConfig(ownerUnit)
    if taskType == "GUNM4" and aircraftConfig.m4Velocity then
      bulletVel = aircraftConfig.m4Velocity
    elseif aircraftConfig.gunVelocity then
      bulletVel = aircraftConfig.gunVelocity
    end
  end

  if bulletVel == 0 then
    return 15  -- Fallback to default if bullet velocity is zero
  end

  local flightTime = rangeM / bulletVel
  local totalPad = flightTime + buffer

  return totalPad
end

local function rq_scoreFromTables(run, elapsedSec)
  local taskType = run.task.type

  if taskType == "HF_SELF" then
    local band = run.hfRangeBandAuto or 7
    return rq_lookupCurveLinear(RANGEQUAL.cfg.curves.HF_SELF[band] or {}, elapsedSec)
  elseif taskType == "HF_REMOTE" then
    return rq_lookupCurveLinear(RANGEQUAL.cfg.curves.HF_REMOTE or {}, elapsedSec)
  elseif taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL" or taskType == "GUNM4" then
    return rq_lookupCurveLinear(RANGEQUAL.cfg.curves.GUN_STD or {}, elapsedSec)
  elseif taskType == "APKWS" then
    local band = run.apkwsRangeBandAuto or 7
    return rq_lookupCurveLinear(RANGEQUAL.cfg.curves.APKWS_STD[band] or {}, elapsedSec)
  elseif taskType == "STINGER" then
    return rq_lookupCurveLinear(RANGEQUAL.cfg.curves.STINGER_STD or {}, elapsedSec)
  elseif taskType == "ROCKETS" then
    local allowedRockets = run.task.allowed and run.task.allowed.rockets or 0
    local scoringPairs = rq_ceilDiv(allowedRockets, 2)
    local band = run.rocketRangeBandAuto or 7
    local tbl = RANGEQUAL.cfg.curves[run.task.rocketCurve]
    local curve = tbl and tbl[scoringPairs] and tbl[scoringPairs][band] or {}
    return rq_lookupCurveLinear(curve, elapsedSec)
  end
  return 0
end

----------------------------------------------------------------
-- END RUN
----------------------------------------------------------------

----------------------------------------------------------------
-- END RUN (immediate + delayed)
----------------------------------------------------------------
local function rq_endRunNow(run, reason, elapsedOverride)
  if not run then return end
  if run.state ~= "HOT" and run.state ~= "ARMING" and run.state ~= "ENDING" then return end

  local unit = Unit.getByName(run.ownerUnitName)
  local elapsed = elapsedOverride
  if elapsed == nil then
    elapsed = 0
    if run.t0 then elapsed = rq_now() - run.t0 end
  end

  local points = 0

  if reason == "EFFECT" then
    points = rq_scoreFromTables(run, elapsed)

    -- Check ammo count for gun tasks (except GUNM4 which has unlimited ammo)
    local taskType = run.task.type
    local isGunTask = (taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL")
    if isGunTask and unit and unit:isExist() then
      local ammoEnd = rq_getGunAmmo(unit)
      local spent = (run.gunAmmoStart or ammoEnd) - ammoEnd
      local allowed = run.task.allowed and run.task.allowed.gunRounds or 0
      if spent > allowed then
        points = 0
        reason = "OVERCOUNT_GUN"
      end
    end
  else
    points = 0
  end

  rq_recordScore(run.ownerUnitName, run.taskId, points, elapsed, reason)

  -- Record "time to perfect score" (wall time from first WELCOME to first 1000 total).
  do
    local owner = run.ownerUnitName
    local st = RANGEQUAL._state
    if owner and st and st.qualStartTime and st.qualStartTime[owner] and st.perfectElapsed and (st.perfectElapsed[owner] == nil) then
      local totalNow = rq_totalScoreForUnit(owner)
      if totalNow == 1000 then
        st.perfectElapsed[owner] = rq_now() - st.qualStartTime[owner]
      end
    end
  end


  -- If this was a scored EFFECT run, append the computed release range (auto-band weapons only).
  local reasonOut = reason
  if reasonOut == "EFFECT" and run.autoRangeM then
    reasonOut = string.format("EFFECT %.0fm", run.autoRangeM)
  end

  -- Rocket tasks: show TEA hits vs allowed rockets in result line.
  local pointsExtra = ""
  if run.task and run.task.type == "ROCKETS" then
    local allowedRockets = run.task.allowed and run.task.allowed.rockets or 0
    if allowedRockets > 0 then
      local hits = run.teaHits or 0
      if hits > allowedRockets then hits = allowedRockets end
      pointsExtra = string.format(" (%d/%d)", hits, allowedRockets)
    end
  end

  rq_msgToGroup(run.groupId,
    string.format("TASK %d RESULT: %d points%s | Time: %ds | Reason: %s",
      run.taskId, points, pointsExtra, rq_roundSec(elapsed), reasonOut),
    12)

  rq_playOutcomeSound(run.groupId, reason)

  -- Release range lock
  local lock = RANGEQUAL._state.rangeLock
  local wasOwner = (lock and lock.ownerUnitName == run.ownerUnitName) and true or false
  if wasOwner then
    lock.busy = false
    lock.ownerUnitName = nil
    lock.taskId = nil

    -- Broadcast RANGE_CLEAR to all players (including shooter) after a short delay,
    -- so it doesn't overlap the shooter's end-state message/sound.
    local gcfg = (RANGEQUAL.cfg and RANGEQUAL.cfg.globals) or {}
    local clearSnd = gcfg.rangeClearSound or "RANGE_CLEAR.ogg"
    local clearDelay = (gcfg.rangeClearDelaySec or 5.0)
    timer.scheduleFunction(function()
      rq_playSoundToAllPlayers(clearSnd)
      return nil
    end, nil, rq_now() + clearDelay)
  end

  rq_cleanupLater(run)
  -- Rebuild menu so task labels update immediately
  local u = Unit.getByName(run.ownerUnitName)
  if u and u:isExist() then
    local gg = u:getGroup()
    if gg and gg:isExist() then
      rq_ensureMenusForGroup(gg)
    end
  end

  RANGEQUAL._state.perUnit[run.ownerUnitName] = nil
end

-- Delay end-of-run messaging/cleanup without inflating scored time.
local function rq_requestEndRun(run, reason, delaySec, elapsedRef)
  if not run then return end
  if run.state ~= "HOT" then
    -- for anything not HOT (e.g., early fire during ARMING), end immediately
    rq_endRunNow(run, reason, elapsedRef)
    return
  end

  local d = delaySec or 0
  if d <= 0 then
    rq_endRunNow(run, reason, elapsedRef)
    return
  end

  -- Enter a pending state to block further processing.
  run.state = "ENDING"
  run.endReason = reason
  run.elapsedOverride = elapsedRef
  run.endAt = rq_now() + d
end

----------------------------------------------------------------
-- START TASK (ARMING -> HOT after delay)
----------------------------------------------------------------
local function rq_abortRunNoScore(run)
  if not run then return end

  -- Release range lock
  local lock = RANGEQUAL._state.rangeLock
  if lock and lock.ownerUnitName == run.ownerUnitName then
    lock.busy = false
    lock.ownerUnitName = nil
    lock.taskId = nil
  end

  rq_cleanupLater(run)

  -- Rebuild menu so labels can update (e.g., score added / lock released)
  local u = Unit.getByName(run.ownerUnitName)
  if u and u:isExist() then
    local gg = u:getGroup()
    if gg and gg:isExist() then
      rq_ensureMenusForGroup(gg)
    end
  end

  RANGEQUAL._state.perUnit[run.ownerUnitName] = nil
end

local function rq_snapshotTargets(run)
  -- Snapshot target UNIT life at CLEARED HOT (expand groups into their member units).
  run.targetLife = {}
  run.targetUnits = {}

  local function snapUnit(u)
    if not u or not (u.isExist and u:isExist()) or not u.getName then return end
    local uname = u:getName()
    if not uname then return end
    run.targetLife[uname] = { kind="unit", life0 = u:getLife() or 0 }
    run.targetUnits[#run.targetUnits+1] = uname
  end

  for _, rec in ipairs(run.targets or {}) do
    if rec.kind == "unit" then
      snapUnit(Unit.getByName(rec.name))
    elseif rec.kind == "group" then
      local g = Group.getByName(rec.name)
      if g and g.isExist and g:isExist() then
        for _, u in ipairs(g:getUnits() or {}) do snapUnit(u) end
      end
    elseif rec.kind == "static" then
      -- Keep statics in case we use them later
      local s = StaticObject.getByName(rec.name)
      if s and s.isExist and s:isExist() and s.getLife then
        run.targetLife[rec.name] = { kind="static", life0 = s:getLife() }
      else
        run.targetLife[rec.name] = { kind="static", life0 = 0 }
      end
    end
  end
end


local function rq_targetsDamagedOrDead(run)
  if not run or not run.targetLife then return false end

  -- Check expanded unit list first (most common for our targets)
  for _, uname in ipairs(run.targetUnits or {}) do
    local base = run.targetLife[uname]
    local u = Unit.getByName(uname)
    if not u or not (u.isExist and u:isExist()) then
      return true
    end
    local now = u:getLife() or 0
    if base and now < (base.life0 or now) then return true end
  end

  -- Statics (if any)
  for name, info in pairs(run.targetLife) do
    if info.kind == "static" then
      local s = StaticObject.getByName(name)
      if not s or not s:isExist() then return true end
      if s.getLife then
        local now = s:getLife() or 0
        if now < (info.life0 or now) then return true end
      end
    end
  end

  return false
end


local function rq_spawnTargetsFromTemplate(run, templateName, aircraftPrefix)
  run.targets = {}
  run.spawnedGroups = {}
  run.spawnedStatics = {}

  -- If aircraft prefix is provided, try prefixed template first (e.g., "AH64_T01_TARGET")
  local prefixedName = nil
  if aircraftPrefix then
    prefixedName = aircraftPrefix .. "_" .. templateName
  end

  -- Try unit-group template (prefixed first if available, then fallback to original)
  for _, tname in ipairs({prefixedName, templateName}) do
    if tname then
      local gname = rq_spawnGroupFromTemplate(tname)
      if gname then
        run.spawnedGroups[#run.spawnedGroups+1] = gname
        local g = Group.getByName(gname)
        if g and g:isExist() then
          for _, u in ipairs(g:getUnits() or {}) do
            if u and u:isExist() then
              run.targets[#run.targets+1] = {kind="unit", name=u:getName()}
            end
          end
        end
        return true
      end
    end
  end

  -- Otherwise try static-group template (prefixed first if available, then fallback to original)
  for _, tname in ipairs({prefixedName, templateName}) do
    if tname then
      local snames = rq_spawnStaticGroupFromTemplate(tname)
      if snames and type(snames) == "table" then
        for _, sname in ipairs(snames) do
          run.spawnedStatics[#run.spawnedStatics+1] = sname
          run.targets[#run.targets+1] = {kind="static", name=sname}
        end
        return true
      end
    end
  end

  return false
end

local function rq_startTaskForUnit(ownerUnitName, taskId)
  local unit = Unit.getByName(ownerUnitName)
  if not unit or not unit:isExist() then return end
  local group = unit:getGroup()
  if not group or not group:isExist() then return end

  -- Get aircraft-specific task table
  local aircraftConfig = rq_getAircraftConfig(unit)
  local task = rq_shallowCopy(aircraftConfig.tasks[taskId])
  if not task then return end

  -- Range lock: only one aircraft can run (ARMING/HOT) at a time
  local lock = RANGEQUAL._state.rangeLock
  if lock and lock.busy and lock.ownerUnitName ~= ownerUnitName then
    rq_msgToGroup(group:getID(),
      string.format("Range is currently HOT with %s (Task %s). Stand by.",
        tostring(lock.ownerUnitName), tostring(lock.taskId)),
      8)

    -- RANGE_HOT is only heard by the would-be shooter (this group), throttled to prevent spam.
    local gcfg = (RANGEQUAL.cfg and RANGEQUAL.cfg.globals) or {}
    local hotSnd = gcfg.rangeHotSound or "RANGE_HOT.ogg"
    local thr = gcfg.rangeHotThrottleSec or 2.0
    local last = RANGEQUAL._state.rangeHotLast[group:getID()] or 0
    if (rq_now() - last) >= thr then
      RANGEQUAL._state.rangeHotLast[group:getID()] = rq_now()
      rq_playSound(group:getID(), hotSnd)
    end

    return
  end


  rq_clearUnitMarks(ownerUnitName)

  local existing = RANGEQUAL._state.perUnit[ownerUnitName]
  if existing then rq_abortRunNoScore(existing) end

  -- Acquire range lock
  local lock = RANGEQUAL._state.rangeLock
  if lock then
    lock.busy = true
    lock.ownerUnitName = ownerUnitName
    lock.taskId = taskId
  end

  local run = {
    -- Unique per-run id; used for unique spawned group naming (prevents silent spawn/collision issues)
    runId          = math.floor(rq_now() * 1000),
    preAmmoHF = rq_getHellfireRemaining(unit),
    ownerUnitName  = ownerUnitName,
    groupId        = group:getID(),
    taskId         = taskId,
    task           = task,

    state          = "ARMING",
    selectTime     = rq_now(),
    t0             = nil,
    lastActivityTime = nil,

    spawnedGroups  = {},
    spawnedStatics = {},
    spawnedJTAC    = nil,
    spawnedCorners = {},

    rocketsFired   = 0,
    hellfiresFired = 0,
    teaHits        = 0,
    qualified      = false,
    qualifyTime     = nil,

    gunAmmoStart   = (task.type == "GUN" or task.type == "GUN30MM" or task.type == "GUN50CAL" or task.type == "GUNM4") and rq_getGunAmmo(unit) or nil,

    targetLife     = {},
    weaponTrack    = {},
    hfTrack        = {},
    hfMisses       = 0,

    effectAchieved = false,
  }

  -- Assign dynamic laser code for remote lasing tasks (per-run)
  if run.task and run.task.type == "HF_REMOTE" then
    run.task.laserCode = rq_generateLaserCode()
  end

  -- Get aircraft type prefix for template naming (e.g., "AH64" for Apache, "OH58" for Kiowa)
  local aircraftPrefix = rq_getAircraftPrefix(unit)

  local ok = rq_spawnTargetsFromTemplate(run, task.targetTemplate, aircraftPrefix)
  if not ok then
    rq_msgToGroup(run.groupId, "Template not found (group or static-group): " .. tostring(task.targetTemplate), 10)
    return
  end

  rq_snapshotTargets(run)

  -- Spawn JTAC for remote HF
  if task.type == "HF_REMOTE" and task.jtacTemplate and run.spawnedGroups and run.spawnedGroups[1] then
    local targetGroupName = run.spawnedGroups[1] -- remote HF target must be a UNIT GROUP
    -- Try prefixed JTAC template first, fallback to original
    local jtacName = nil
    if aircraftPrefix then
      jtacName = rq_spawnGroupFromTemplate(aircraftPrefix .. "_" .. task.jtacTemplate)
    end
    if not jtacName then
      jtacName = rq_spawnGroupFromTemplate(task.jtacTemplate)
    end
    run.spawnedJTAC = jtacName
    if jtacName then end
  elseif task.type == "HF_REMOTE" and not (run.spawnedGroups and run.spawnedGroups[1]) then
    rq_msgToGroup(run.groupId, "Task requires UNIT GROUP target (for JTAC lasing). Use a vehicle group template for "..tostring(task.targetTemplate), 12)
  end

  -- TEA corners for rockets
  if task.type == "ROCKETS" and task.teaCorners then
    run.teaPoly = rq_buildTEAPolyForTask(run, taskId)
    if run.teaPoly then
    else
    end
  end

  -- Calculate initial range to target for dynamic timeout (separate from scoring range band)
  local taskType = task.type
  local needsRangeCalc = (taskType == "HF_SELF" or taskType == "HF_REMOTE" or taskType == "ROCKETS" or
                          taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL" or taskType == "GUNM4" or
                          taskType == "APKWS" or taskType == "STINGER")
  if needsRangeCalc then
    local shooterPt = unit:getPoint()
    if shooterPt then
      local bestD = nil
      for _, rec in ipairs(run.targets or {}) do
        local pt = rq_targetPointFromRec(rec)
        if pt then
          local d = rq_dist2D(shooterPt, pt)
          if (not bestD) or (d < bestD) then
            bestD = d
          end
        end
      end
      if bestD then
        run.timeoutRangeBand = rq_rangeBand7_m(bestD)
        run.timeoutRangeM = bestD
      else
        run.timeoutRangeBand = 7  -- Default to max band if no targets found
      end
    else
      run.timeoutRangeBand = 7
    end
  else
    run.timeoutRangeBand = 7
  end

  RANGEQUAL._state.perUnit[ownerUnitName] = run

  rq_msgToGroup(run.groupId,
    string.format("TASK %d selected. Hold %d seconds for clearance.",
      taskId, RANGEQUAL.cfg.globals.armingDelaySec),
    8)
	
	rq_playSound(run.groupId, "HOLD.ogg")

  -- For remote Hellfire tasks, show the laser code immediately on task selection (not at CLEARED HOT).
  if run.task and run.task.type == "HF_REMOTE" then
    rq_msgToGroup(run.groupId, string.format("JTAC LASER CODE: %d", run.task.laserCode or 1688), 30)
  end


  -- For remote lasing tasks, announce the randomized laser code 1s after HOLD.
  if run.task and run.task.type == "HF_REMOTE" then
    local code = run.task.laserCode
    timer.scheduleFunction(function()
      -- Ensure the run is still the active run for this unit and hasn't been aborted.
      local r = RANGEQUAL._state.perUnit[run.ownerUnitName]
      if r and r.runId == run.runId and (r.state == "ARMING" or r.state == "HOT") then
        rq_playLaserCodeAudio(run.groupId, code)
      end
      return nil
    end, nil, timer.getTime() + 2.5)
  end


  timer.scheduleFunction(function()
    local r = RANGEQUAL._state.perUnit[ownerUnitName]
    if not r or r.state ~= "ARMING" then return end

    r.state = "HOT"
    r.t0 = rq_now()
    r.lastActivityTime = r.t0
    rq_snapshotTargets(r)
    -- Start scripted JTAC laser for remote Hellfire tasks
    if r.task.type == "HF_REMOTE" and r.spawnedJTAC then
      local jtacUnitName = r.spawnedJTAC .. "_U1"
      local targetUnitName = nil
      if r.targets then
        for _, t in ipairs(r.targets) do
          if t.kind == "unit" then
            targetUnitName = t.name
            break
          end
        end
      end
      if targetUnitName then
        rq_laserStart(r, jtacUnitName, targetUnitName, r.task.laserCode or 1688)
      else
        rq_msgToGroup(r.groupId, "Task requires a UNIT target for JTAC lasing (no unit targets found).", 10)
      end
    end
    local msg = string.format("CLEARED HOT - TASK %d", r.taskId)
    rq_msgToGroup(r.groupId, msg, 20)
	rq_playSound(r.groupId, "CLEARED.ogg")
  end, nil, rq_now() + RANGEQUAL.cfg.globals.armingDelaySec)
end

----------------------------------------------------------------
-- MAIN TICK
----------------------------------------------------------------
local function rq_tick()
  local now = rq_now()

  for ownerUnitName, run in pairs(RANGEQUAL._state.perUnit) do
    local unit = Unit.getByName(ownerUnitName)

    if (not unit) or (not unit:isExist()) then
      rq_cleanup(run)
      RANGEQUAL._state.perUnit[ownerUnitName] = nil
    else
      local ended = false

      -- Pending end (SUCCESS_PENDING equivalent): allow brief delay to bundle explosions/multi-kills without inflating scored time
      if run.state == "ENDING" then
        if run.endAt and now >= run.endAt then
          rq_endRunNow(run, run.endReason or "EFFECT", run.elapsedOverride)
        end
        ended = true
      end

      -- FOUL line check (ARMING or HOT)
      if run.state == "ARMING" or run.state == "HOT" then
        if rq_inZone(unit, RANGEQUAL.cfg.globals.foulZoneName) then
          rq_endRunNow(run, "FOUL_LINE")
          ended = true
        end
      end
      -- Idle timeout (no qualifying weapon activity) - now dynamic based on scoring curves
      if (not ended) and run.state == "HOT" then
        local idleSec = rq_computeDynamicTimeout(run)
        local last = run.lastActivityTime or run.t0 or now
        if idleSec > 0 and (now - last) >= idleSec then
          rq_endRunNow(run, "IDLE_TIMEOUT", (run.task and run.task.type=="ROCKETS" and run.qualified and run.qualifyTime and ((run.qualifyTime - (run.t0 or run.qualifyTime)))) or nil)
          ended = true
        end
      end

      -- Terminal effect for guns/HF: any life decrease on ANY target object
      if (not ended) and run.state == "HOT" then
        local tt = run.task.type
        -- Check for hit-based terminal effect tasks
        local isHitTask = (tt == "HF_SELF" or tt == "HF_REMOTE" or tt == "GUN" or
                          tt == "GUN30MM" or tt == "GUN50CAL" or tt == "GUNM4" or
                          tt == "APKWS" or tt == "STINGER")
        if isHitTask and (not run.effectAchieved) then
          for name, rec in pairs(run.targetLife or {}) do
            if rec.kind == "unit" then
              local tu = Unit.getByName(name)
              -- NOTE: In DCS, a unit can disappear immediately on death (especially with missiles),
              -- so relying only on life decrease can miss valid kills.
              if (not tu) or (not tu.isExist) or (not tu:isExist()) then
                run.effectAchieved = true
                rq_requestEndRun(run, "EFFECT", RANGEQUAL.cfg.globals.successHoldSec, (rq_now() - (run.t0 or rq_now())))
                ended = true
                break
              else
                local lifeNow = tu.getLife and tu:getLife() or 0
                if (lifeNow <= 0) or (lifeNow < rec.life0) then
                  run.effectAchieved = true
                  rq_requestEndRun(run, "EFFECT", RANGEQUAL.cfg.globals.successHoldSec, (rq_now() - (run.t0 or rq_now())))
                  ended = true
                  break
                end
              end
            elseif rec.kind == "static" then
              local ts = StaticObject.getByName(name)
              if ts and ts:isExist() and ts.getLife then
                if ts:getLife() < rec.life0 then
                  run.effectAchieved = true
                  rq_requestEndRun(run, "EFFECT", RANGEQUAL.cfg.globals.successHoldSec, (rq_now() - (run.t0 or rq_now())))
                  ended = true
                  break
                end
              end
            end
          end
        end
      end


      -- Failure by expenditure (no hard time limit)
      if (not ended) and run.state == "HOT" and (not run.effectAchieved) then
        local tt = run.task.type

        if tt == "GUN" then
          local allowed = run.task.allowed and run.task.allowed.gunRounds or 0
          if allowed > 0 and unit and unit:isExist() then
            local ammoNow = rq_getGunAmmo(unit)
            local spent = (run.gunAmmoStart or ammoNow) - ammoNow

            -- When allotted rounds are spent, do NOT end immediately.
            -- Give impacts time to register (last burst), and also detect over-pulls.
            if spent >= allowed then
              if not run.gunPendingEndAt then
                run.gunPendingEndAt = rq_now() + rq_computeGunEndPad(run)
              end
              if spent > allowed then
                run.gunOverPulled = true
              end

              if rq_now() >= run.gunPendingEndAt then
                if run.gunOverPulled then
                  rq_endRunNow(run, "OVERCOUNT_GUN")
                else
                  rq_endRunNow(run, "NO_EFFECT")
                end
                ended = true
              end
            end
          end

        elseif tt == "HF_SELF" or tt == "HF_REMOTE" then
          rq_tickHellfireTracking(run)
          if tt == "HF_REMOTE" then
            rq_laserUpdate(run)
          end
          local allowed = run.task.allowed and run.task.allowed.hellfires or 0
          if allowed > 0 and run.hellfiresFired >= allowed and (run.hfTrack and #run.hfTrack == 0) then
            rq_endRunNow(run, "NO_EFFECT")
            ended = true
          end
        end
      end

      -- Rockets: TEA impacts
      if (not ended) and run.state == "HOT" then
        if run.task.type == "ROCKETS" then
          rq_tickWeaponTracking(run)

          local allowed = run.task.allowed and run.task.allowed.rockets or 0
          local now2 = rq_now()
          local t0 = run.t0 or now2
          local qualElapsed = (run.qualified and run.qualifyTime) and (run.qualifyTime - t0) or nil

          -- Perfect run: all allowed impacts landed inside TEA -> end early (but keep time based on qualification moment)
          if (not ended) and allowed > 0 and run.teaHits >= allowed then
            rq_requestEndRun(run, "EFFECT", RANGEQUAL.cfg.globals.successHoldSec, qualElapsed)
            ended = true

          -- If we've fired all allowed rockets and all tracked rockets have resolved, end now.
          elseif (not ended) and allowed > 0 and run.rocketsFired >= allowed and run.weaponTrack and (#run.weaponTrack == 0) then
            if run.qualified then
              rq_requestEndRun(run, "EFFECT", RANGEQUAL.cfg.globals.successHoldSec, qualElapsed)
            else
              rq_endRunNow(run, "NO_EFFECT")
            end
            ended = true
          end
        end
      end
    end
  end

  return now + RANGEQUAL.cfg.globals.tickSec
end

----------------------------------------------------------------
-- EVENT HANDLER
----------------------------------------------------------------
local function rq_onShot(run, initiator, weapon)
  if not rq_inZone(initiator, RANGEQUAL.cfg.globals.fireZoneName) then
    rq_endRunNow(run, "FIRE_ZONE")
    return
  end

  -- Motion requirement is evaluated ONLY at the moment of weapon release.
  -- HOVER: <5 kt, MOVE: >=5 kt
  if not rq_motionOk(run.task, initiator) then
    rq_endRunNow(run, "MOTION_VIOLATION")
    return
  end

  -- Auto range band (ROCKETS + HF_SELF only), frozen on first qualifying release.
  rq_computeAutoBandOnce(run, initiator)

  -- Wrong-weapon foul (after CLEARED HOT). Pre-cleared-hot foul is handled in the main event handler.
  if not rq_isAllowedWeaponForTask(run.task, weapon) then
    rq_endRunNow(run, "WRONG_WEAPON")
    return
  end

  local t = run.task.type

  if t == "HF_SELF" or t == "HF_REMOTE" then
    if rq_weaponIsHellfire(weapon) then
      run.hellfiresFired = run.hellfiresFired + 1
      local allowed = run.task.allowed and run.task.allowed.hellfires or 0
      if run.hellfiresFired > allowed then
        rq_endRunNow(run, "OVERCOUNT_HF")
        return
      end
      run.hfTrack[#run.hfTrack+1] = { weapon=weapon, last=nil }
    end
  elseif t == "APKWS" then
    if rq_weaponIsAPKWS(weapon) then
      run.apkwsFired = (run.apkwsFired or 0) + 1
      local allowed = run.task.allowed and run.task.allowed.apkws or 0
      if run.apkwsFired > allowed then
        rq_endRunNow(run, "OVERCOUNT_APKWS")
        return
      end
    end
  elseif t == "STINGER" then
    if rq_weaponIsStinger(weapon) then
      run.stingersFired = (run.stingersFired or 0) + 1
      local allowed = run.task.allowed and run.task.allowed.stingers or 0
      if run.stingersFired > allowed then
        rq_endRunNow(run, "OVERCOUNT_STINGER")
        return
      end
    end
  elseif t == "ROCKETS" then
    if rq_weaponIsRocket(weapon) then
      run.rocketsFired = run.rocketsFired + 1
      local allowed = run.task.allowed and run.task.allowed.rockets or 0
      if run.rocketsFired > allowed then
        rq_endRunNow(run, "OVERCOUNT_RKT")
        return
      end
      run.weaponTrack[#run.weaponTrack+1] = { weapon=weapon, last=nil }
    end
  elseif t == "GUN" or t == "GUN30MM" or t == "GUN50CAL" or t == "GUNM4" then
    -- enforced at scoring moment via ammo delta (except GUNM4 which has unlimited)
  end
end

RANGEQUAL._state.handler = RANGEQUAL._state.handler or {}
function RANGEQUAL._state.handler:onEvent(event)
  if not event then return end

  local id = event.id
  

  -- Maintain occupancy counts so multi-crew seats (e.g., CPG hopping out) don't wipe the whole slot.
  if id == world.event.S_EVENT_PLAYER_ENTER_UNIT or id == world.event.S_EVENT_PLAYER_LEAVE_UNIT then
    local u = event.initiator
    if u and u.getName then
      local uname = u:getName()
      local occ = rq_getOcc(uname)

      if id == world.event.S_EVENT_PLAYER_ENTER_UNIT then
        rq_setOcc(uname, occ + 1)
      else
        rq_setOcc(uname, occ - 1)
        -- Only wipe slate when the last player leaves the unit.
        if rq_getOcc(uname) == 0 then
          rq_wipeUnitSlate(uname, id)
        end
      end
    end
    return
  end

  -- If a unit ceases to exist, wipe the slate for that slot so scores don't persist.
  if id == world.event.S_EVENT_DEAD
     or id == world.event.S_EVENT_CRASH
     or id == world.event.S_EVENT_UNIT_LOST then
    local u = event.initiator
    if u and u.getName then
      rq_wipeUnitSlate(u:getName(), id)
    end
    return
  end


if id ~= world.event.S_EVENT_SHOT and id ~= world.event.S_EVENT_SHOOTING_START then return end
  if not event.initiator or not event.initiator.getName then return end

  local initiatorName = event.initiator:getName()
  local run = RANGEQUAL._state.perUnit[initiatorName]
  if not run then return end
  if run.state ~= "ARMING" and run.state ~= "HOT" then return end

  -- Any firing before CLEARED HOT (during ARMING) is a foul
  if run.state == "ARMING" then
    rq_endRunNow(run, "EARLY_FIRE")
    return
  end

  -- HOT: record activity (used for idle timeout)
  run.lastActivityTime = rq_now()

  -- HOT state: enforce weapon limits / fire zone rules
  if id == world.event.S_EVENT_SHOT then
    rq_onShot(run, event.initiator, event.weapon)

  elseif id == world.event.S_EVENT_SHOOTING_START then
    -- Guns: no weapon object; still enforce FIRE_ZONE for gun tasks
    if not rq_inZone(event.initiator, RANGEQUAL.cfg.globals.fireZoneName) then
      rq_endRunNow(run, "FIRE_ZONE")
      return
    end

    -- Motion requirement is evaluated ONLY at the moment of weapon release.
    if not rq_motionOk(run.task, event.initiator) then
      rq_endRunNow(run, "MOTION_VIOLATION")
      return
    end

    -- If we're in a non-gun task and the player starts shooting (guns), it's a wrong-weapon foul.
    local taskType = run.task and run.task.type
    local isGunTask = (taskType == "GUN" or taskType == "GUN30MM" or taskType == "GUN50CAL" or taskType == "GUNM4")
    if run.task and not isGunTask then
      rq_endRunNow(run, "WRONG_WEAPON")
      return
    end
    -- Ammo overcount is enforced at scoring time via ammo delta.
  end
end


----------------------------------------------------------------
-- AIRCRAFT TYPE DETECTION
----------------------------------------------------------------
local function rq_getAircraftType(unit)
  if not unit or not unit:isExist() then return nil end
  local typeName = unit:getTypeName()
  if not typeName then return nil end

  local tn = typeName:lower()

  -- OH-58D Kiowa Warrior
  if tn:find("oh-58", 1, true) or tn:find("oh58", 1, true) or tn:find("kiowa", 1, true) then
    return "oh58"
  end

  -- AH-64D Apache
  if tn:find("ah-64", 1, true) or tn:find("ah64", 1, true) or tn:find("apache", 1, true) then
    return "ah64"
  end

  -- Default to AH-64 for backwards compatibility with existing missions
  return "ah64"
end

local function rq_getAircraftConfig(unit)
  local aircraftType = rq_getAircraftType(unit)
  if aircraftType == "oh58" then
    return RANGEQUAL.cfg.oh58
  else
    return RANGEQUAL.cfg.ah64
  end
end

----------------------------------------------------------------
-- MENUS (MP-safe: re-fetch live group by name inside callback)
----------------------------------------------------------------
rq_ensureMenusForGroup = function(group)
  if not group or not group:isExist() then return end
  local gid = group:getID()
  local gname = group:getName()

  -- If we already built menus for this group, do nothing.
  -- (Rebuilding menus repeatedly can exceed DCS menu limits and cause callbacks to mismatch labels.)
  local existing = RANGEQUAL._state.menus[gid]
  if existing then return end


  -- Root items under F10 -> Other:
  --   Select Task -> Task 1..10
  --   Range Report
  local selectMenu = missionCommands.addSubMenuForGroup(gid, "Select Task")

  -- Resolve "this aircraft" for Option A: 1 unit per group
  local function getOwnerUnitName()
    local liveGroup = Group.getByName(gname)
    if not liveGroup or not liveGroup:isExist() then return nil end
    local units = liveGroup:getUnits()
    if not units or #units == 0 or (not units[1]) or (not units[1]:isExist()) then return nil end
    return units[1]:getName()
  end

  local ownerName = getOwnerUnitName()
  local s = ownerName and RANGEQUAL._state.score[ownerName] or nil

  -- Get the first unit to determine aircraft type
  local firstUnit = group:getUnit(1)
  local aircraftConfig = firstUnit and rq_getAircraftConfig(firstUnit) or RANGEQUAL.cfg.ah64
  local tasks = aircraftConfig.tasks or {}

  -- Tasks 1..10 in strict order; label shows score only if >0
  for taskId = 1, 10 do
    if tasks[taskId] then
      local label = ("Task %d"):format(taskId)
      local best = s and s.bestByTask and s.bestByTask[taskId] or nil
      if best and best > 0 then
        label = ("Task %d - %d"):format(taskId, best)
      end

      local tid = taskId -- capture loop variable (Lua 5.1 closure safety)
      missionCommands.addCommandForGroup(gid, label, selectMenu, function()
        local liveOwner = getOwnerUnitName()
        if not liveOwner then
          rq_msgToGroup(gid, "Group not active yet (slot not occupied).", 6)
          return
        end
        rq_startTaskForUnit(liveOwner, tid)
      end)
    end
  end

  local reportItem = missionCommands.addCommandForGroup(gid, "Range Report", nil, function()
    local liveOwner = getOwnerUnitName()
    if not liveOwner then
      rq_msgToGroup(gid, "Group not active yet (slot not occupied).", 6)
      return
    end
    rq_showStatusForUnit(liveOwner)
  end)

  RANGEQUAL._state.menus[gid] = { select = selectMenu, report = reportItem, groupName = gname }
end

local function rq_bootstrapMenus()
  for _, side in ipairs({coalition.side.BLUE, coalition.side.RED}) do
    for _, cat in ipairs({Group.Category.HELICOPTER, Group.Category.AIRPLANE}) do
      local groups = coalition.getGroups(side, cat) or {}
      for _, g in ipairs(groups) do
        if g and g:isExist() then rq_ensureMenusForGroup(g) end
      end
    end
  end
end

local function rq_refreshMenus()
  rq_bootstrapMenus()
  return rq_now() + (RANGEQUAL.cfg.globals.menuRefreshSec or 5)
end

----------------------------------------------------------------
-- STARTUP
----------------------------------------------------------------
local function rq_start()
  if RANGEQUAL._state.started then return end
  RANGEQUAL._state.started = true

  world.addEventHandler(RANGEQUAL._state.handler)

  rq_bootstrapMenus()
  -- Periodically try to add menus for newly-spawned player groups (idempotent; does not rebuild existing menus)
  timer.scheduleFunction(rq_refreshMenus, nil, rq_now() + (RANGEQUAL.cfg.globals.menuRefreshSec or 5))
  -- WELCOME: play once per player when they first appear inside FIRE_ZONE (or enter it later)
  timer.scheduleFunction(rq_welcomeTick, nil, rq_now() + ((RANGEQUAL.cfg.globals and RANGEQUAL.cfg.globals.welcomeTickSec) or 1.0))

    timer.scheduleFunction(function() return rq_tick() end, nil, rq_now() + RANGEQUAL.cfg.globals.tickSec)

  trigger.action.outText("Stains Range Script Loaded", (RANGEQUAL.cfg.globals and RANGEQUAL.cfg.globals.loadedOutTextSec) or 10)
end

rq_start()