[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$Remote = "origin",
    [string]$Branch = "main",
    [string]$TaskName = "JAYJIAOlearning Semi-Monthly Wiki Maintenance",
    [string]$FallbackTaskName = "JAYJIAOlearning Semi-Monthly Wiki Maintenance Fallback",
    [int]$ScheduleHour = 18,
    [int]$ScheduleMinute = 30,
    [int]$FallbackDelayMinutes = 10,
    [int]$TaskRetryCount = 3,
    [int]$TaskRetryMinutes = 15,
    [string]$CodexPath = "$env:LOCALAPPDATA\Programs\OpenAI\Codex\bin\codex.exe",
    [switch]$ResetState,
    [switch]$KeepLegacyTasks,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Quote-TaskArgument {
    param([string]$Value)

    if ($Value -notmatch '[\s"]') { return $Value }
    return '"' + ($Value -replace '"', '\"') + '"'
}

function New-TaskArgumentString {
    param([string[]]$TaskArgs)
    return ($TaskArgs | ForEach-Object { Quote-TaskArgument $_ }) -join " "
}

function Escape-XmlText {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

function Get-LatestDueSlot {
    param([datetime]$Now = (Get-Date))

    $monthStart = [datetime]::new($Now.Year, $Now.Month, 1, $ScheduleHour, $ScheduleMinute, 0, $Now.Kind)
    $slots = @($monthStart.AddDays(14), $monthStart, $monthStart.AddMonths(-1).AddDays(14))
    return @($slots | Where-Object { $_ -le $Now } | Sort-Object -Descending)[0]
}

function New-TaskSettingsXml {
    return @"
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT4H</ExecutionTimeLimit>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <StartWhenAvailable>true</StartWhenAvailable>
    <IdleSettings>
      <Duration>PT10M</Duration>
      <WaitTimeout>PT1H</WaitTimeout>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <RestartOnFailure>
      <Interval>PT${TaskRetryMinutes}M</Interval>
      <Count>$TaskRetryCount</Count>
    </RestartOnFailure>
"@
}

function New-TaskXml {
    param(
        [string]$Description,
        [string]$TriggersXml,
        [string]$Command,
        [string]$Arguments,
        [string]$WorkingDirectory,
        [string]$UserSid
    )

    $descriptionXml = Escape-XmlText $Description
    $commandXml = Escape-XmlText $Command
    $argumentsXml = Escape-XmlText $Arguments
    $workingDirectoryXml = Escape-XmlText $WorkingDirectory
    $sidXml = Escape-XmlText $UserSid
    $settingsXml = New-TaskSettingsXml
    return @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>$descriptionXml</Description>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>$sidXml</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
$settingsXml  </Settings>
  <Triggers>
$TriggersXml  </Triggers>
  <Actions Context="Author">
    <Exec>
      <Command>$commandXml</Command>
      <Arguments>$argumentsXml</Arguments>
      <WorkingDirectory>$workingDirectoryXml</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
}

function Initialize-StateIfNeeded {
    param(
        [string]$StatePath,
        [string]$Repository
    )

    if ((Test-Path -LiteralPath $StatePath -PathType Leaf) -and -not $ResetState) {
        Write-Output "Preserved existing state: $StatePath"
        return
    }

    Push-Location -LiteralPath $Repository
    try {
        $head = (& git rev-parse HEAD 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to resolve repository HEAD: $($head -join ' ')"
        }
    } finally {
        Pop-Location
    }
    $headCommit = @($head)[0].ToString().Trim()
    $slot = Get-LatestDueSlot
    $state = [ordered]@{
        LastSuccessTime = (Get-Date).ToString("o")
        LastCompletedSlot = $slot.ToString("o")
        LastProcessedCommit = $headCommit
        DeferredSources = @()
        RepoRoot = $Repository
        Remote = $Remote
        Branch = $Branch
    }
    $json = $state | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($StatePath, $json, [System.Text.UTF8Encoding]::new($false))
    Write-Output ("Initialized state at HEAD {0} for slot {1}: {2}" -f $state.LastProcessedCommit, $slot.ToString("yyyy-MM-dd HH:mm"), $StatePath)
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
}

if ($ScheduleHour -lt 0 -or $ScheduleHour -gt 23) { throw "ScheduleHour must be between 0 and 23." }
if ($ScheduleMinute -lt 0 -or $ScheduleMinute -gt 59) { throw "ScheduleMinute must be between 0 and 59." }
if ($FallbackDelayMinutes -lt 0) { throw "FallbackDelayMinutes cannot be negative." }
if ($TaskRetryCount -lt 1) { throw "TaskRetryCount must be at least 1." }
if ($TaskRetryMinutes -lt 1) { throw "TaskRetryMinutes must be at least 1." }

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
$runner = Join-Path $repo "scripts\semimonthly_wiki_maintenance.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) { throw "Missing maintenance runner: $runner" }
if (-not (Test-Path -LiteralPath $CodexPath -PathType Leaf)) { throw "Missing Codex CLI: $CodexPath" }

$powerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$userSid = $identity.User.Value
$baseArgs = @(
    "-NoProfile",
    "-WindowStyle", "Hidden",
    "-ExecutionPolicy", "Bypass",
    "-File", $runner,
    "-RepoRoot", $repo,
    "-Remote", $Remote,
    "-Branch", $Branch,
    "-ScheduledHour", $ScheduleHour.ToString(),
    "-ScheduledMinute", $ScheduleMinute.ToString(),
    "-CodexPath", $CodexPath
)
$mainArguments = New-TaskArgumentString -TaskArgs $baseArgs
$fallbackArguments = New-TaskArgumentString -TaskArgs ($baseArgs + "-Fallback")

$now = Get-Date
$boundary = [datetime]::new($now.Year, $now.Month, 1, $ScheduleHour, $ScheduleMinute, 0, $now.Kind)
$startBoundary = $boundary.ToString("yyyy-MM-ddTHH:mm:sszzz")
$mainTriggers = @"
    <CalendarTrigger>
      <StartBoundary>$startBoundary</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByMonth>
        <DaysOfMonth>
          <Day>1</Day>
          <Day>15</Day>
        </DaysOfMonth>
        <Months>
          <January /><February /><March /><April /><May /><June />
          <July /><August /><September /><October /><November /><December />
        </Months>
      </ScheduleByMonth>
    </CalendarTrigger>
"@
$fallbackTriggers = @"
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$userSid</UserId>
      <Delay>PT${FallbackDelayMinutes}M</Delay>
    </LogonTrigger>
"@

$mainXml = New-TaskXml `
    -Description "Maintain and publish the Obsidian Wiki on the 1st and 15th of every month." `
    -TriggersXml $mainTriggers `
    -Command $powerShell `
    -Arguments $mainArguments `
    -WorkingDirectory $repo `
    -UserSid $userSid
$fallbackXml = New-TaskXml `
    -Description "Retry a missed or failed semimonthly Wiki run after the next user logon; the runner skips completed slots." `
    -TriggersXml $fallbackTriggers `
    -Command $powerShell `
    -Arguments $fallbackArguments `
    -WorkingDirectory $repo `
    -UserSid $userSid

$logDir = Join-Path $env:LOCALAPPDATA "JAYJIAOlearning"
$statePath = Join-Path $logDir "semimonthly-wiki-state.json"
$legacyTaskNames = @("JAYJIAOlearning Biweekly Wiki Prompt", "JAYJIAOlearning Biweekly Wiki Prompt Fallback")

if ($DryRun) {
    Write-Output "[dry-run] Would set repository core.longpaths=true."
    Write-Output "[dry-run] Would register: $TaskName"
    Write-Output "[dry-run] Calendar: every month on days 1 and 15 at $($boundary.ToString('HH:mm'))."
    Write-Output "[dry-run] Action: $powerShell $mainArguments"
    Write-Output "[dry-run] Would register: $FallbackTaskName"
    Write-Output "[dry-run] Fallback: current-user logon after startup, delayed $FallbackDelayMinutes minute(s)."
    Write-Output "[dry-run] Each failed task run is retried $TaskRetryCount time(s), every $TaskRetryMinutes minute(s)."
    Write-Output "[dry-run] Runner internally retries Codex and Git network operations."
    if (-not $KeepLegacyTasks) {
        Write-Output ("[dry-run] Would unregister legacy prompt-only tasks: {0}" -f ($legacyTaskNames -join ", "))
    }
    Write-Output "[dry-run] State file: $statePath"
    exit 0
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Push-Location -LiteralPath $repo
try {
    & git config core.longpaths true
    if ($LASTEXITCODE -ne 0) { throw "Unable to set repository core.longpaths=true." }
} finally {
    Pop-Location
}

Register-ScheduledTask -TaskName $TaskName -Xml $mainXml -Force | Out-Null
Register-ScheduledTask -TaskName $FallbackTaskName -Xml $fallbackXml -Force | Out-Null
Initialize-StateIfNeeded -StatePath $statePath -Repository $repo

if (-not $KeepLegacyTasks) {
    foreach ($legacyName in $legacyTaskNames) {
        $legacy = Get-ScheduledTask -TaskName $legacyName -ErrorAction SilentlyContinue
        if ($null -ne $legacy) {
            Unregister-ScheduledTask -TaskName $legacyName -Confirm:$false
            Write-Output "Unregistered legacy task: $legacyName"
        }
    }
}

Get-ScheduledTask -TaskName $TaskName, $FallbackTaskName |
    Select-Object TaskName, State |
    Sort-Object TaskName |
    Format-Table -AutoSize
