# HMI Popup Simulation 800x800

Use this reference when creating a TP1200 popup simulation screen for the `HMI popup` FB pattern used in project `VIP-TEST-3-弹框`.

## Verified Project Snapshot

- Date: 2026-05-13
- Project: `VIP-TEST-3-弹框`
- Project path: `H:\程序优化\S4-弹窗\A1-HMI弹框-scl\VIP-TEST-3-弹框.ap17`
- HMI target: `HMI_RT_1`
- PLC pattern observed:
  - `HMI弹窗 [FB1]`
  - `DB_Components [DB2]`
  - `DB_ActivePopup [DB1]`
  - `Startup [OB100]`
  - `Main [OB1]`

## Important Boundaries Learned

- A normal TP1200 screen cannot be imported as `800 x 800`; TIA reports: `The screen size does not match the device`.
- Use `Hmi.Screen.ScreenPopup` and import into `hmi.ScreenPopupFolder.ScreenPopups` for an `800 x 800` popup.
- Do not import a mixed internal HMI tag table containing `Real` or `WString` until a known-good exported template for those exact data types exists.
- The verified stable route is: create Int-only HMI tags, bind IOFields, add button `SetTag` events, export the popup, then compile the HMI target.

## Verified Objects

Generated and verified popup screens:

- `Codex_Popup_Sim_800x800`: visual-only popup, `800 x 800`, 6 buttons, 31 text fields, 0 IOFields
- `Codex_Popup_Sim_800x800_IO1`: one IOField `IO_Input_CompID`, bound to `Sim_SelectedCompID`
- `Codex_Popup_Sim_800x800_IO2`: 6 buttons, 21 text fields, 10 IOFields, 6 events, 34 `SetTag` entries

Verified HMI tag table:

- `Codex_Popup_Sim_Int_Tags`
  - `Sim_SelectedCompID`
  - `Sim_ClickPulse`
  - `Sim_DoubleClickTime_ms`
  - `Sim_Switch1`
  - `Sim_RealValue1_Int`
  - `Sim_Visible`
  - `Sim_ActiveID`
  - `Sim_Confirmed`
  - `Sim_ConfirmPulse`
  - `Sim_CancelPulse`

`Sim_RealValue1_Int` is an integer placeholder for simulation only. Bind the real PLC `RealValue[1]` as a proper Real tag later after a Real tag template has been exported from the target project.

## Scripts

Run from the repo skill folder or pass absolute paths:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\import-popup-sim-int-tagset.ps1" -OutputRoot "C:\Users\QF100\Documents\New project\tia_popup_touch_sim"
```

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\create-popup-sim-visual-screen.ps1" -OutputRoot "C:\Users\QF100\Documents\New project\tia_popup_touch_sim" -ScreenName "Codex_Popup_Sim_800x800_IO2" -BindIntSet
```

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\compile-current-hmi-target.ps1" -OutputRoot "C:\Users\QF100\Documents\New project\tia_popup_touch_sim"
```

## Verified Compile Result

```text
ProjectName=VIP-TEST-3-弹框
HmiTarget=HMI_RT_1
CompileState=Success
Compiling finished (errors: 0; warnings: 0)
ProjectSaved=True
```

## Button Simulation

The `IO2` popup uses button `Click` events with `SetTag` functions:

- `Btn_Valve01_Trigger`: selected component `1`, click pulse `1`, visible `1`, active ID `1`
- `Btn_Heater01_Trigger`: selected component `2`, click pulse `1`, visible `1`, active ID `2`
- `Btn_Fan01_Trigger`: selected component `3`, click pulse `1`, visible `1`, active ID `3`
- `Btn_Reset_ClickPulse`: resets click and button pulses
- `Btn_Confirm`: sets confirm pulse, sets confirmed, hides popup, resets click
- `Btn_Cancel`: sets cancel pulse, clears confirmed, hides popup, resets click

## PLC Mapping Reminder

The simulated HMI tags are internal tags. For live PLC binding, map these UI concepts to the PLC data model:

- Inputs or trigger-side values:
  - `DB_Components.Valve01.ClickTrig`
  - `DB_Components.Heater01.ClickTrig`
  - `DB_Components.Fan01.ClickTrig`
  - `DB_Components.*.Switch[1]`
  - `DB_Components.*.RealValue[1]`
- Outputs or popup status:
  - `DB_ActivePopup.*.Visible`
  - `DB_ActivePopup.*.ActiveID`
  - `DB_ActivePopup.*.Confirmed`
  - `DB_ActivePopup.*.ConfirmBtn`
  - `DB_ActivePopup.*.CancelBtn`

## Evidence Files

Workspace evidence from the verified run:

- `tia_popup_touch_sim\exports\Codex_Popup_Sim_Int_Tags_full_int_export.xml`
- `tia_popup_touch_sim\exports\Codex_Popup_Sim_800x800_IO2_visual_export.xml`
- `tia_popup_touch_sim\logs\hmi_compile_loop.txt`
