# TIA-V17

Reusable Codex skill and SCL templates for Siemens TIA Portal V17 bag pulse dust collector work through Openness.

## Included

- `skills/tia-openness-bag-pulse/`
  - reusable Codex skill
  - Openness workflow guidance
  - default IO map
  - generated object naming rules
- `templates/bag-pulse-dust-collector/`
  - `FB_BagPulseDustCollector.scl`
  - `BagPulseDustCollector_OpennessImport.scl`
  - `Main_Call_BagPulseDustCollector.scl`

## Install On Another Computer

Copy `skills/tia-openness-bag-pulse` into your Codex skills directory:

- Windows default: `C:\Users\<your-user>\.codex\skills\`

After that, the skill can be invoked by name:

```text
Use $tia-openness-bag-pulse to connect to the open TIA Portal project, create bag pulse dust collector blocks, and close the IO loop.
```

## Template Files

Use the files in `templates/bag-pulse-dust-collector/` when you want to import the ready-made SCL sources directly into a TIA project:

- `FB_BagPulseDustCollector.scl`: core reusable FB
- `BagPulseDustCollector_OpennessImport.scl`: combined import source for FB, DBs, and IO wrapper
- `Main_Call_BagPulseDustCollector.scl`: minimal caller for `Main` or `OB1`

## Notes

- The skill assumes Windows, PowerShell, TIA Portal already open, and TIA Openness installed.
- Default logic targets a 4-bag dust collector and keeps pulse timing parameters adjustable.
- Default IO addresses are documented inside `skills/tia-openness-bag-pulse/references/default-io-map.md`.
