---
name: tia-openness-bag-pulse
description: Connect to an open Siemens TIA Portal project through Openness, create or update bag pulse dust collector logic in SCL, add PLC tag tables, wire default input/output mappings, compile the PLC software, and save the project. Use when the user asks to connect to TIA Portal, Openness, Siemens Portal, STEP 7, or a live PLC project to build or import a bag pulse dust collector program, especially when they want closed-loop IO mapping, reusable block generation, or a repeatable import workflow.
---

# TIA Openness Bag Pulse

Use this skill to turn a user request like "connect to TIA and build a bag pulse dust collector" into a repeatable Openness workflow.

Assume the work happens on Windows with PowerShell, an already-open TIA Portal session, and a CPU that supports SCL blocks. Prefer creating new blocks and tag tables over mutating unrelated existing logic.

## Workflow

1. Inspect the local Openness environment.
2. Attach to the open TIA Portal process.
3. Discover the target project, PLC software object, existing blocks, and existing tag tables.
4. Generate or update the SCL source files in the current workspace.
5. Import the source into TIA with Openness, creating blocks and DBs.
6. Create or update the PLC tag table for field IO and status words.
7. Compile the generated blocks, then compile the PLC software.
8. Save the project.
9. Report what was created, what addresses were used, and whether OB1/Main was changed.

## Quick Rules

- Prefer `C:\Program Files\Siemens\Automation\Portal V17\PublicAPI\V17\Siemens.Engineering.dll` when V17 is installed. If V17 is missing, search under `C:\Program Files\Siemens\Automation\Portal*` for `Siemens.Engineering.dll` and use the newest matching PublicAPI version.
- Use PowerShell and load the DLL with `Add-Type -Path`.
- Enumerate TIA processes with `[Siemens.Engineering.TiaPortal]::GetProcesses()`.
- Attach to an existing UI session instead of opening a new hidden TIA process when the user says Portal is already open.
- Find PLC software through `DeviceItem.GetService[SoftwareContainer]()` rather than assuming the PLC sits at a fixed device-item depth.
- Prefer adding new blocks with distinct names such as `FB_BagPulseDustCollector`, `DB_BagPulseDustCollector`, `DB_BagPulseDustCollector_IO`, and `FC_BagPulseDustCollector_IO`.
- Compile newly generated blocks first. Then compile the PLC software object to confirm the whole software tree is clean.
- Save the TIA project after a successful compile.

## Default Deliverable

Unless the user asks for a different structure, generate these objects:

- `FB_BagPulseDustCollector`: the reusable core SCL FB
- `DB_BagPulseDustCollector`: instance DB for the FB
- `DB_BagPulseDustCollector_IO`: parameter and status DB for HMI/operator tuning
- `FC_BagPulseDustCollector_IO`: IO wrapper that maps field signals to the FB and writes outputs/status back out
- `Main` or `OB1`: call the IO wrapper only when safe to do so

Keep the core behavior conservative:

- Default `BagCount := 4`
- Make `PulseTime`, `ValveInterval`, and `CyclePause` adjustable
- Support manual pulse and pressure-difference requests
- Support enabled-bag selection and optional per-bag pulse time

Read [references/default-io-map.md](./references/default-io-map.md) when the user does not provide an IO list and you need a ready-made closed loop.

## Safe Edit Policy For Main/OB1

- Inspect existing `Main`/`OB1` first.
- If OB1 is empty or effectively empty, replacing it with a simple SCL caller is acceptable.
- If OB1 contains real user logic, do not overwrite it silently.
- In a populated OB1, prefer one of these:
  - export the block first and preserve a backup in the workspace
  - add a single new FC/FB call if you can do it without disturbing existing logic
  - otherwise stop short of OB1 mutation and tell the user the generated caller block is ready to be inserted

Report explicitly whether `Main`/`OB1` was changed.

## PowerShell Pattern

Use short inspection commands first:

```powershell
Get-Process | Where-Object { $_.ProcessName -match 'Portal|Siemens|TIA' }
Get-ChildItem -Path 'C:\Program Files\Siemens' -Recurse -Filter Siemens.Engineering.dll -ErrorAction SilentlyContinue
```

When attaching through Openness, use a helper like this:

```powershell
$dll = 'C:\Program Files\Siemens\Automation\Portal V17\PublicAPI\V17\Siemens.Engineering.dll'
Add-Type -Path $dll
$process = [Siemens.Engineering.TiaPortal]::GetProcesses() | Select-Object -First 1
$tia = $process.Attach()
```

For PLC discovery, prefer a recursive walk over device items and a reflected generic `GetService` helper when PowerShell has trouble calling the generic method directly.

## Block Import Pattern

Generate source files in the current workspace, then import them through `ExternalSourceGroup`.

Recommended source files:

- `BagPulseDustCollector_OpennessImport.scl`: core FB, instance DB, IO DB, IO wrapper FC
- `Main_Call_BagPulseDustCollector.scl`: optional OB1/Main caller

Recommended sequence:

1. Create or find the external source.
2. Call `GenerateBlocksFromSource(KeepOnError)`.
3. Compile the generated blocks individually.
4. Compile the PLC software object.

If block export fails because blocks are inconsistent, compile first and retry export only if you actually need the export.

Read [references/generated-objects.md](./references/generated-objects.md) when you need the default block naming and responsibility split.

## Tag Table Pattern

Create a dedicated PLC tag table, for example `BagPulseDustCollector_IO`, and keep the IO mapping there. Avoid mixing these tags into the default system clock tag table.

Use the default map from [references/default-io-map.md](./references/default-io-map.md) unless the user supplies a plant-specific address list.

If the target project already uses those addresses, stop and ask for the actual IO allocation instead of guessing.

## Validation

After generation:

1. Compile `FB_BagPulseDustCollector`
2. Compile `DB_BagPulseDustCollector`
3. Compile `DB_BagPulseDustCollector_IO`
4. Compile `FC_BagPulseDustCollector_IO`
5. Compile the whole PLC software object
6. Save the project

In the final report, include:

- project name
- PLC software name
- blocks created or updated
- tag table created or updated
- whether `Main`/`OB1` changed
- compile result summary
- any assumptions, especially IO addresses

## What To Avoid

- Do not overwrite a populated `Main`/`OB1` without checking it first.
- Do not reuse `%M0` and `%M1` clock bytes for status words.
- Do not assume the project contains no existing bag pulse logic; inspect existing FB/FC/DB names first.
- Do not claim the work is complete until the PLC software compile passes.
