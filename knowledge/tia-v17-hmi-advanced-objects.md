# TIA V17 HMI Advanced Objects Knowledge

This knowledge entry was created from live Openness testing on `2026-05-13`.

## Test Target

- Project: `VIP-TEST-3-弹框`
- Project path: `H:\程序优化\S4-弹窗\A1-HMI弹框-scl\VIP-TEST-3-弹框.ap17`
- HMI target: `HMI_RT_1`
- Device class visible in TIA: `TP1200 Comfort`

## Verified Counts Before Loop

- Cycles: `19`
- Text lists: `1`
- Graphic lists: `0`
- VB scripts: `2`
- HMI tag tables: `2`

## Verified Closed Loops

- `Codex_Cycle_3s`: imported into `hmi.Cycles`, exported, read back, compiled.
- `Codex_TextList_Status`: imported into `hmi.TextLists`, exported, read back, compiled.
- `Codex_GraphicList_Empty`: imported into `hmi.GraphicLists`, exported, read back, compiled.
- `Codex_VBFunction_Loop`: imported/exported through `hmi.VBScriptFolder.VBScripts`.
- `Codex_VBS_Loop_Tags`: imported/exported through `hmi.TagFolder.TagTables`.

## Compile Result

```text
CompileState=Success
Compiling finished (errors: 0; warnings: 0)
```

## Boundary

Data records, alarm records, and scheduled tasks are visible in the TIA project tree, but were not exposed as direct `HmiTarget` collections in this V17 Openness object model. Treat them as GUI-configurable unless a project-specific Siemens XML sample or API surface is discovered.

Evidence files:

- `knowledge/export_snapshot.txt`
- `knowledge/import_export_loop.txt`
- `skills/tia-openness-bag-pulse/references/hmi-advanced-objects.md`
