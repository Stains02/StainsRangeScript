# Stains Range Script

A DCS World mission script for attack helicopter range qualification training. Provides automated range control, target management, and performance scoring for Apache (AH-64D) and Kiowa (OH-58D) weapon systems.

## Features

Try the example mission!

Requirements:
- Nevada terrain
- OH-58D and/or AH-64D modules
- [476 vFG - Air Weapons Range Objects](https://www.476vfightergroup.com/downloads.php?do=download&downloadid=482)

## Features

- **Automated Range Control**: "RANGE HOT" / "RANGE CLEAR" announcements with single-shooter lockout
- **Dynamic Target Spawning**: Targets spawn per task and despawn automatically after completion
- **Multiple Task Types**: Hellfires (self/remote), rockets, guns, APKWS, and Stinger
- **Performance Scoring**: Time-based scoring with distance-adjusted curves (30-100 points)
- **Safety Enforcement**: Foul line, fire zone, motion requirements, and ammo limits
- **Rocket Impact Tracking**: Visual F10 map markers for rocket hits/misses with TEA (Target Engagement Area) qualification
- **Dynamic Laser Codes**: Auto-generated JTAC laser codes for remote Hellfire tasks
- **Audio Callouts**: Optional voice announcements for range state and laser codes
- **Multi-crew Support**: Handles pilot/CPG seat switching without resetting runs

## Supported Aircraft

- **AH-64D Apache**: Hellfires, rockets, 30mm gun
- **OH-58D Kiowa**: Hellfires, APKWS, rockets, .50 cal, M4 rifle, Stinger

## Mission Setup Requirements - See example MIZ file!

### 1. Required Trigger Zones

Create these trigger zones in the DCS Mission Editor:

- **`FIRE_ZONE`**: Area where weapons may be fired
- **`FOUL_LINE`**: Area players must not cross (instant foul if entered)
- **`RANGE_CLEANUP`**: Area for automatic debris cleanup after tasks

### 2. Target Templates

For each task, create a **late-activated** group template. Here are the defaults (as seen in the example MIZ):

#### Apache Tasks
- `AH64_T01_TARGET` - Hellfire self-lase target (task 1)
- `AH64_T02_TARGET` - Rocket target (task 2)
- `AH64_T03_TARGET` - 30mm gun target (task 3)
- `AH64_T04_TARGET` - Hellfire self-lase target (task 4)
- `AH64_T05_TARGET` - Rocket target (task 5)
- `AH64_T06_TARGET` - Hellfire self-lase target (task 6)
- `AH64_T07_TARGET` - Remote Hellfire target (task 7)
- `AH64_T08_TARGET` - 30mm gun target (task 8)
- `AH64_T09_TARGET` - 30mm gun target (task 9)
- `AH64_T10_TARGET` - Rocket target (task 10)

#### Kiowa Tasks
- `OH58_T01_TARGET` - Hellfire self-lase target (task 1)
- `OH58_T02_TARGET` - Remote Hellfire target (task 2)
- `OH58_T03_TARGET` - .50 cal target (task 3)
- `OH58_T04_TARGET` - .50 cal target (task 4)
- `OH58_T05_TARGET` - Rocket target (task 5)
- `OH58_T06_TARGET` - Rocket target (task 6)
- `OH58_T07_TARGET` - M4 rifle target (task 7)
- `OH58_T08_TARGET` - APKWS target (task 8)
- `OH58_T09_TARGET` - APKWS target (task 9)
- `OH58_T10_TARGET` - Stinger air target (task 10)

**Note**: Target templates must be late activated **unit groups** not **statics**.

### 3. JTAC Templates (Remote Hellfire Tasks Only)

For remote Hellfire tasks, create late-activated **unit groups**:

- `AH64_T07_JTAC` - JTAC for Apache task 7
- `OH58_T02_JTAC` - JTAC for Kiowa task 2

The JTAC will spawn automatically and provide laser designation with a randomly generated laser code (announced via text and optional audio).

### 4. TEA Zones (Rocket Tasks Only)

For rocket tasks, create **4 small trigger zones** defining the Target Engagement Area corners:

#### Apache Rocket Tasks
- Task 2: `AH64_T02_TEA_ZONE1`, `AH64_T02_TEA_ZONE2`, `AH64_T02_TEA_ZONE3`, `AH64_T02_TEA_ZONE4`
- Task 5: `AH64_T05_TEA_ZONE1`, `AH64_T05_TEA_ZONE2`, `AH64_T05_TEA_ZONE3`, `AH64_T05_TEA_ZONE4`
- Task 10: `AH64_T10_TEA_ZONE1`, `AH64_T10_TEA_ZONE2`, `AH64_T10_TEA_ZONE3`, `AH64_T10_TEA_ZONE4`

#### Kiowa Rocket Tasks
- Task 5: `OH58_T05_TEA_ZONE1`, `OH58_T05_TEA_ZONE2`, `OH58_T05_TEA_ZONE3`, `OH58_T05_TEA_ZONE4`
- Task 6: `OH58_T06_TEA_ZONE1`, `OH58_T06_TEA_ZONE2`, `OH58_T06_TEA_ZONE3`, `OH58_T06_TEA_ZONE4`

The four zones mark the corners of the rectangular target area. The script automatically connects them into a polygon.

**Backward compatibility**: Unprefixed zone names (e.g., `T02_TEA_ZONE1`) are also supported if you're using a single aircraft type.

### 5. TEA Visual Markers (Rocket Tasks Only)

Create a **static object** named `TEA_TEMPLATE` (e.g., a cone or marker). The script will clone this static to visually mark the four TEA corners during active rocket tasks.

### 6. Script Integration

1. Create a **DO SCRIPT FILE** trigger at mission start with:
   ```lua
   dofile("path/to/rangequal.lua")
   ```
   
2. **(Optional)** Add audio files:
   - Create a trigger in the DCS Mission Editor
   --Triggers: once, no event
   --Conditions: flag 1 equals 10 (this doesn't matter, just have to put something here)
   --Actions: one action for each sound file. Use SOUND TO COUNTRY and pick a random country that doesn't appear in the mission.

## Usage

### Starting a Task

1. Enter the `FIRE_ZONE` in your aircraft
2. Open the **F10 Radio Menu** → **Range Control**
3. Select a task (e.g., "Task 1", "Task 2", etc.)
4. Message appears: **"TASK X selected. Hold X seconds for clearance."**
5. Targets spawn, JTAC starts lasing (if applicable)
6. After X seconds: **"CLEARED HOT - TASK X"**
7. Engage targets with the specified weapon system

### Task Rules

- **Fire Zone**: All weapon releases must occur from inside `FIRE_ZONE`
- **Foul Line**: Do not cross `FOUL_LINE` during active tasks
- **Motion Requirements**:
  - `HOVER` tasks: < 5 knots ground speed
  - `MOVE` tasks: ≥ 20 knots ground speed
- **Ammo Limits**: Do not exceed allowed rounds/missiles (see task configuration)
- **Weapon Type**: Only the specified weapon type is allowed per task

### Task Completion

**Success**: Achieve terminal effect (kill/damage target) within allowed ammo
- Rocket tasks require 2+ impacts inside TEA zone
- Range displays scored time and points (30-100 based on time and range)
- Brief delay before "RANGE CLEAR" to bundle multi-kills

**Failure**:
- Ammo expended without effect
- Idle timeout (no weapon activity)
- Rule violation (foul line, fire zone, wrong weapon, motion, ammo overcount)

### Rocket Task Scoring

Rocket tasks use TEA (Target Engagement Area) qualification:
1. Fire rockets at the target area
2. Impacts inside TEA are marked "HIT" on F10 map)
3. Impacts outside TEA are marked "MISS" on F10 map
4. **Qualification**: 2+ hits inside TEA (timer locks at this moment)
5. **Perfect Score**: All allowed rockets hit inside TEA (task ends early)
6. Continue firing until all allowed rockets expended or qualification achieved

## Task Types

### AH-64D Apache Tasks

| Task | Type | Weapon | Motion | Ammo | Notes |
|------|------|--------|--------|------|-------|
| 1 | HF_SELF | Hellfire (self-lase) | HOVER | 1 | Self-designation |
| 2 | ROCKETS | 2.75" rockets | HOVER | 6 | TEA qualification (2+ hits) |
| 3 | GUN30MM | M230 30mm | HOVER | 30 rounds | |
| 4 | HF_SELF | Hellfire (self-lase) | HOVER | 1 | Self-designation |
| 5 | ROCKETS | 2.75" rockets | HOVER | 6 | TEA qualification (2+ hits) |
| 6 | HF_SELF | Hellfire (self-lase) | HOVER | 1 | Self-designation |
| 7 | HF_REMOTE | Hellfire (JTAC) | HOVER | 1 | JTAC laser code provided |
| 8 | GUN30MM | M230 30mm | HOVER | 40 rounds | |
| 9 | GUN30MM | M230 30mm | MOVE | 30 rounds | ≥20kt ground speed |
| 10 | ROCKETS | 2.75" rockets | HOVER | 8 | TEA qualification (2+ hits) |

### OH-58D Kiowa Tasks

| Task | Type | Weapon | Motion | Ammo | Notes |
|------|------|--------|--------|------|-------|
| 1 | HF_SELF | Hellfire (self-lase) | HOVER | 1 | Self-designation |
| 2 | HF_REMOTE | Hellfire (JTAC) | HOVER | 1 | JTAC laser code provided |
| 3 | GUN50CAL | .50 cal MG | MOVE | 100 rounds | ≥20kt ground speed |
| 4 | GUN50CAL | .50 cal MG | MOVE | 100 rounds | ≥20kt ground speed |
| 5 | ROCKETS | 2.75" rockets | MOVE | 6 | TEA qualification (2+ hits) |
| 6 | ROCKETS | 2.75" rockets | MOVE | 8 | TEA qualification (2+ hits) |
| 7 | GUNM4 | M4 rifle | HOVER | 999 rounds | Door gunner |
| 8 | APKWS | APKWS (laser rocket) | HOVER | 1 | Laser-guided |
| 9 | APKWS | APKWS (laser rocket) | HOVER | 1 | Laser-guided |
| 10 | STINGER | FIM-92 Stinger | HOVER | 1 | Air-to-air |

## Configuration

Edit the `RANGEQUAL.cfg` table in `rangequal.lua` to customize:

### Global Settings
- **Zone names**: `foulZoneName`, `fireZoneName`, `cleanupZoneName`
- **Timing**: `armingDelaySec` (clearance delay), `successHoldSec` (multi-kill bundling)
- **Motion thresholds**: `hoverMaxKt`, `moveMinKt`
- **Audio files**: `welcomeSound`, `rangeHotSound`, `rangeClearSound`

### Scoring Curves
Modify time/points curves for each weapon system:
- `HF_SELF` - Self-lased Hellfire (7 range bands)
- `HF_REMOTE` - Remote lased Hellfire (single curve)
- `GUN_STD` - Gun tasks (single curve)
- `ROCKET_STD` - Rocket tasks (by rocket pair count and range band)
- `APKWS_STD` - APKWS tasks (7 range bands)
- `STINGER_STD` - Stinger tasks (single curve)

### Aircraft Tasks
Add/modify tasks in `RANGEQUAL.cfg.ah64.tasks` or `RANGEQUAL.cfg.oh58.tasks`:
```lua
[1] = {
  id=1,
  type="HF_SELF",
  targetTemplate="AH64_T01_TARGET",
  allowed={ hellfires=1 },
  terminalEffect="DAMAGE_ANY",
  scoringCurve="HF_SELF",
  motion="HOVER"
},
```

## Troubleshooting

### "Template not found" error
- Ensure target template group/static exists in mission
- Check group/static name matches `targetTemplate` exactly (case-sensitive)
- Verify group is set to **late activation**

### "TEA zones missing" error (rocket tasks)
- Create 4 trigger zones: `AH64_T##_TEA_ZONE1` through `AH64_T##_TEA_ZONE4` (or `OH58_` for Kiowa)
- Check zone names match task number exactly
- Ensure all 4 zones exist

### Rockets not counting
- Verify TEA zones are created correctly
- Check `TEA_TEMPLATE` static object exists
- Ensure rockets impact inside the TEA polygon defined by the 4 zones

### JTAC laser not working (remote Hellfire)
- Target template must be a **unit group** (not static)
- JTAC template must be a **unit group**
- Check JTAC and target group names match configuration

### No F10 menu
- Ensure script is loaded via DO SCRIPT FILE trigger at mission start
- Verify aircraft type is AH-64D or OH-58D

## License

See [LICENSE](LICENSE) file for details.
