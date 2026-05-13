param(
    [string]$OutputRoot = ".\tia_hmi_knowledge",
    [string]$TemplateRoot,
    [switch]$SkipImport,
    [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"

if (-not $TemplateRoot) {
    $TemplateRoot = Join-Path (Split-Path -Parent $PSScriptRoot) "assets\hmi-advanced-templates"
}
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$TemplateRoot = [System.IO.Path]::GetFullPath($TemplateRoot)
$exportDir = Join-Path $OutputRoot "exports"
$logDir = Join-Path $OutputRoot "logs"
New-Item -ItemType Directory -Force -Path $exportDir, $logDir | Out-Null

$mainDll = "C:\Program Files\Siemens\Automation\Portal V17\PublicAPI\V17\Siemens.Engineering.dll"
$hmiDll = "C:\Program Files\Siemens\Automation\Portal V17\PublicAPI\V17\Siemens.Engineering.Hmi.dll"
[System.Reflection.Assembly]::LoadFrom($mainDll) | Out-Null
if (Test-Path -LiteralPath $hmiDll) { [System.Reflection.Assembly]::LoadFrom($hmiDll) | Out-Null }

function Get-SoftwareFromDeviceItem($item, [Type]$softwareContainerType) {
    $method = $item.GetType().GetMethods() | Where-Object { $_.Name -eq "GetService" -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 0 } | Select-Object -First 1
    if (-not $method) { return $null }
    $service = $method.MakeGenericMethod($softwareContainerType).Invoke($item, @())
    if ($service) { return $service.Software }
    return $null
}

function Walk-DeviceItems($items, [Type]$softwareContainerType) {
    foreach ($item in $items) {
        $software = Get-SoftwareFromDeviceItem $item $softwareContainerType
        if ($software) { $software }
        if ($item.DeviceItems.Count -gt 0) { Walk-DeviceItems $item.DeviceItems $softwareContainerType }
    }
}

function Export-Object($object, [string]$path, [string]$label, $log) {
    try {
        $object.Export([System.IO.FileInfo]$path, [Siemens.Engineering.ExportOptions]::WithDefaults)
        $log.Add("OK_EXPORT=$label|$path")
    } catch {
        $log.Add("FAIL_EXPORT=$label|$($_.Exception.Message)")
    }
}

function Import-Export-Object($collection, [string]$name, [string]$importPath, [string]$exportPath, [string]$label, $log) {
    try {
        $existing = $collection.Find($name)
        $action = if ($existing) { "OverrideExisting" } else { "CreateNew" }
        $collection.Import([System.IO.FileInfo]$importPath, [Siemens.Engineering.ImportOptions]::Override) | Out-Null
        $object = $collection.Find($name)
        if (-not $object) { throw "Imported object not found: $name" }
        $object.Export([System.IO.FileInfo]$exportPath, [Siemens.Engineering.ExportOptions]::WithDefaults)
        $log.Add("OK_LOOP=$label|$name|$action|$exportPath")
    } catch {
        $log.Add("FAIL_LOOP=$label|$name|$($_.Exception.Message)")
    }
}

$process = [Siemens.Engineering.TiaPortal]::GetProcesses() | Where-Object { $_.Mode.ToString() -eq "WithUserInterface" -and $_.ProjectPath } | Select-Object -First 1
if (-not $process) { throw "No open TIA Portal UI process with a project path was found." }

$log = New-Object System.Collections.Generic.List[string]
$tia = $process.Attach()
try {
    $project = $tia.Projects | Select-Object -First 1
    $softwareContainerType = [type]"Siemens.Engineering.HW.Features.SoftwareContainer"
    $software = foreach ($device in $project.Devices) { Walk-DeviceItems $device.DeviceItems $softwareContainerType }
    $hmi = $software | Where-Object { $_.GetType().FullName -eq "Siemens.Engineering.Hmi.HmiTarget" } | Select-Object -First 1
    if (-not $hmi) { throw "No HMI target was found." }

    $log.Add("ProjectName=$($project.Name)")
    $log.Add("ProjectPath=$($process.ProjectPath)")
    $log.Add("HmiTarget=$($hmi.Name)")
    $log.Add("CyclesCount=$($hmi.Cycles.Count)")
    $log.Add("TextListsCount=$($hmi.TextLists.Count)")
    $log.Add("GraphicListsCount=$($hmi.GraphicLists.Count)")
    $log.Add("VBScriptsCount=$($hmi.VBScriptFolder.VBScripts.Count)")
    $log.Add("TagTablesCount=$($hmi.TagFolder.TagTables.Count)")

    foreach ($cycle in $hmi.Cycles) { Export-Object $cycle (Join-Path $exportDir ("cycle_" + $cycle.Name + ".xml")) ("CYCLE|" + $cycle.Name) $log }
    foreach ($list in $hmi.TextLists) { Export-Object $list (Join-Path $exportDir ("textlist_" + $list.Name + ".xml")) ("TEXTLIST|" + $list.Name) $log }
    foreach ($list in $hmi.GraphicLists) { Export-Object $list (Join-Path $exportDir ("graphiclist_" + $list.Name + ".xml")) ("GRAPHICLIST|" + $list.Name) $log }
    foreach ($vb in $hmi.VBScriptFolder.VBScripts) { Export-Object $vb (Join-Path $exportDir ("vbscript_" + $vb.Name + ".xml")) ("VBS|" + $vb.Name) $log }

    if (-not $SkipImport) {
        Import-Export-Object $hmi.Cycles "Codex_Cycle_3s" (Join-Path $TemplateRoot "Codex_Cycle_3s.xml") (Join-Path $exportDir "Codex_Cycle_3s_export.xml") "CYCLE" $log
        Import-Export-Object $hmi.TextLists "Codex_TextList_Status" (Join-Path $TemplateRoot "Codex_TextList_Status.xml") (Join-Path $exportDir "Codex_TextList_Status_export.xml") "TEXTLIST" $log
        Import-Export-Object $hmi.GraphicLists "Codex_GraphicList_Empty" (Join-Path $TemplateRoot "Codex_GraphicList_Empty.xml") (Join-Path $exportDir "Codex_GraphicList_Empty_export.xml") "GRAPHICLIST" $log
        $hmi.TagFolder.TagTables.Import([System.IO.FileInfo](Join-Path $TemplateRoot "Codex_VBS_Tags.xml"), [Siemens.Engineering.ImportOptions]::Override) | Out-Null
        $hmi.VBScriptFolder.VBScripts.Import([System.IO.FileInfo](Join-Path $TemplateRoot "Codex_VBFunction_Loop.xml"), [Siemens.Engineering.ImportOptions]::Override) | Out-Null
        $log.Add("OK_LOOP=VBS|Codex_VBFunction_Loop|tags and script imported")
    }

    if (-not $SkipCompile) {
        $getService = $hmi.GetType().GetMethods() | Where-Object { $_.Name -eq "GetService" -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 0 } | Select-Object -First 1
        $compiler = $getService.MakeGenericMethod([Siemens.Engineering.Compiler.ICompilable]).Invoke($hmi, @())
        $result = $compiler.Compile()
        $log.Add("CompileState=$($result.State)")
        foreach ($message in $result.Messages) { $log.Add("CompileMessage=$($message.State)|$($message.Path)|$($message.Description)") }
    }

    $project.Save()
    $log.Add("ProjectSaved=True")
} finally {
    if ($tia) { $tia.Dispose() }
}

$logPath = Join-Path $logDir "hmi_advanced_loop.txt"
$log | Set-Content -Path $logPath -Encoding UTF8
$log
