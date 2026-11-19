# Builds the GitHub Pages site in docs/ from lore/ and characters/.
#
#   powershell -ExecutionPolicy Bypass -File tools\build.ps1
#
# Everything in docs/ except _config.yml is deleted and regenerated.
# The build stops before writing anything if a spoiler check fails.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$docs   = Join-Path $root 'docs'
$tiers  = @('common', 'proficient', 'expert')
$utf8   = New-Object System.Text.UTF8Encoding $false
$nl     = "`n"

# --- spoiler rules (see CLAUDE.md) ---------------------------------------
# Banned on every generated page, hidden pages included.
$banned = 'manshoon|golorr|kolat|zord|vault|devil|asmodeus|fireball|soulmonger|acererak|\bomu\b|ras nsi|trickster gods'
# Allowed only on hidden secret pages (docs/s/).
$secret = 'chult|nyanzaru|laeral[^.\n]*\b(wasting|afflicted|cursed|dying|ill)\b'
# Public pages must not tie Laeral's absence to the curse (same line).
$laeralCurse = '(laeral|open lord)[^\n]*(curse|wasting)|(curse|wasting)[^\n]*(laeral|open lord)'

function Read-Utf8([string]$path) {
    ([IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)) -replace "`r`n", "`n"
}

# Lore links point at pages that are no longer published: keep the text only.
function Remove-LoreLinks([string]$text) {
    $text -replace '\[([^\]]+)\]\([^)\s]+\.html(#[^)]*)?\)', '$1'
}

$moduleCache = @{}
function Get-LoreModule([string]$name) {
    if ($moduleCache.ContainsKey($name)) { return $moduleCache[$name] }
    $path = Join-Path $root "lore\$name.md"
    if (-not (Test-Path $path)) { throw "Unknown lore module '$name' (expected $path)" }
    $sections = @{}
    $current = $null
    $buf = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Read-Utf8 $path) -split $nl) {
        if ($line -match '^## (.+?)\s*$') {
            if ($current) { $sections[$current] = ($buf -join $nl).Trim() }
            $current = $Matches[1].Trim().ToLower()
            if ($tiers -notcontains $current) {
                throw "lore\$name.md: unexpected section '## $($Matches[1])'. Use only Common, Proficient, Expert."
            }
            $buf.Clear()
        } elseif ($current) {
            $buf.Add($line)
        }
    }
    if ($current) { $sections[$current] = ($buf -join $nl).Trim() }
    $moduleCache[$name] = $sections
    return $sections
}

# Tiers stack: expert = common + proficient + expert.
function Get-LoreText([string]$name, [string]$tier) {
    $idx = [array]::IndexOf($tiers, $tier.ToLower())
    if ($idx -lt 0) { throw "Bad tier '$tier' for module '$name'. Use common, proficient or expert." }
    $m = Get-LoreModule $name
    $parts = @()
    for ($i = 0; $i -le $idx; $i++) {
        $t = $m[$tiers[$i]]
        if ($t) { $parts += $t }
    }
    Remove-LoreLinks ($parts -join ($nl + $nl))
}

function Get-Secret([string]$id) {
    $path = Join-Path $root "lore\secrets\$id.md"
    if (-not (Test-Path $path)) { throw "Unknown secret '$id' (expected $path)" }
    $text = (Read-Utf8 $path).Trim()
    if ($text -notmatch '^# (.+)') { throw "lore\secrets\$id.md must start with '# Title'" }
    $title = $Matches[1].Trim()
    $body = ($text -replace '^# .+\n', '').Trim()
    @{ Title = $title; Body = $body }
}

function Format-Bullets($items) {
    (@($items) | ForEach-Object { "- $_" }) -join $nl
}

function Format-FrontMatter([System.Collections.IDictionary]$fm) {
    $lines = @('---')
    foreach ($k in $fm.Keys) {
        $v = $fm[$k]
        if ($v -is [string]) { $v = '"' + ($v -replace '"', '\"') + '"' }
        elseif ($v -is [bool]) { $v = "$v".ToLower() }
        $lines += "${k}: $v"
    }
    $lines += '---'
    $lines -join $nl
}

# --- build pages in memory -----------------------------------------------
$pages = [ordered]@{}   # relative path -> content
$chars = @()

$charFiles = Get-ChildItem (Join-Path $root 'characters') -Filter '*.json' | Where-Object { $_.Name -notlike '_*' }
foreach ($f in $charFiles) {
    $c = (Read-Utf8 $f.FullName) | ConvertFrom-Json
    foreach ($req in 'name', 'slug', 'tagline', 'intro', 'sections') {
        if (-not $c.$req) { throw "$($f.Name): missing '$req'" }
    }
    $chars += $c

    $fm = [ordered]@{ title = $c.name; nav_order = [int]$c.order }
    $out = @(
        (Format-FrontMatter $fm), '',
        "# $($c.name)", '{: .no_toc }', "*$($c.tagline)*", '',
        $c.intro, '',
        '- TOC', '{:toc}', '',
        '## What every resident knows', '',
        (Get-LoreText 'baseline' 'common'), ''
    )
    foreach ($s in $c.sections) {
        if (-not $s.heading -or -not $s.because) { throw "$($f.Name): every section needs 'heading' and 'because'" }
        $out += "## $($s.heading)"
        $out += "*Because: $($s.because)*"
        $out += ''
        if ($s.lead) { $out += $s.lead; $out += '' }
        foreach ($ref in $s.lore) {
            $out += (Get-LoreText $ref.module $ref.tier)
            $out += ''
        }
        if ($s.extra) { $out += (Format-Bullets $s.extra); $out += '' }
    }
    foreach ($l in $c.lists) {
        $out += "## $($l.heading)"
        $out += (Format-Bullets $l.items)
        $out += ''
    }
    if ($c.story) {
        $out += '## Your story'
        $out += (Format-Bullets $c.story)
        $out += ''
    }
    $pages["$($c.slug).md"] = ($out -join $nl)

    # Hidden secret page
    $secrets = @($c.secrets | Where-Object { $_ })
    if ($secrets.Count -gt 0) {
        if (-not $c.secretPage) {
            $suggest = ($c.slug -split '-')[0] + '-' + [guid]::NewGuid().ToString('N').Substring(0, 16)
            throw "$($f.Name): has secrets but no 'secretPage'. Add e.g. ""secretPage"": ""$suggest"""
        }
        $first = ($c.name -split ' ')[0]
        $fm = [ordered]@{ title = "For $first Only"; nav_exclude = $true; search_exclude = $true; sitemap = $false }
        $out = @(
            (Format-FrontMatter $fm), '',
            "# For $first only", '{: .no_toc }', '',
            "*This page is just for you. It isn't linked from anywhere on the site. Share what's here with the party in play if you choose, not by passing on the link.*", ''
        )
        foreach ($sec in $secrets) {
            $s = Get-Secret $sec.id
            $out += "## $($s.Title)"
            if ($sec.because) { $out += "*Because: $($sec.because)*" }
            $out += ''
            # Character extras go at the module's <!-- extras --> marker, or at the end.
            $extra = ''
            if ($sec.extra) { $extra = Format-Bullets $sec.extra }
            if ($s.Body -match '<!-- extras -->') {
                $body = $s.Body -replace '<!-- extras -->', $extra
                $out += (($body -replace '\n{3,}', ($nl + $nl)).Trim())
            } else {
                $out += $s.Body
                if ($extra) { $out += ''; $out += $extra }
            }
            $out += ''
        }
        $pages["s/$($c.secretPage).md"] = ($out -join $nl)
    }
}

# Home page
$chars = @($chars | Sort-Object { [int]$_.order })
$rows = @($chars | ForEach-Object { "| [$($_.name)]($($_.slug).html) | $($_.tagline) |" })
$indexLines = @(
    (Format-FrontMatter ([ordered]@{ title = 'Home'; nav_order = 1 })), '',
    '# Waterdeep: What You Know', '',
    'Welcome to Waterdeep, the City of Splendors. Each character has one page holding what they know about the city when the campaign begins: what every resident knows, plus what their skills, background and ancestry have taught them.', '',
    'Everything here is what people *believe*. Rumors can be wrong, and the city has secrets.', '',
    '## Characters',
    '| Character | |',
    '|---|---|'
) + $rows + @('', '*More characters are on their way.*', '')
$pages['index.md'] = ($indexLines -join $nl)

# --- checks (nothing is written if any fail) -----------------------------
$errors = @()
$warnFlags = 0
foreach ($p in $pages.Keys) {
    $text = $pages[$p]
    $isSecret = $p.StartsWith('s/')
    foreach ($m in [regex]::Matches($text, $banned, 'IgnoreCase')) { $errors += "${p}: banned spoiler '$($m.Value)'" }
    if (-not $isSecret) {
        foreach ($m in [regex]::Matches($text, $secret, 'IgnoreCase')) { $errors += "${p}: secret-tier text '$($m.Value)' on a public page" }
        foreach ($m in [regex]::Matches($text, $laeralCurse, 'IgnoreCase')) { $errors += "${p}: ties Laeral to the curse: '$($m.Value)'" }
        if ($text -match '\]\((\.\./)?s/') { $errors += "${p}: links to a hidden page" }
        $warnFlags += ([regex]::Matches($text, [string][char]0x26A0)).Count
    }
}
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "FAIL $_" -ForegroundColor Red }
    throw "Build stopped: $($errors.Count) check(s) failed. docs/ was not changed."
}

# --- write ---------------------------------------------------------------
Get-ChildItem $docs -Force | Where-Object { $_.Name -ne '_config.yml' } | Remove-Item -Recurse -Force
foreach ($p in $pages.Keys) {
    $dest = Join-Path $docs ($p -replace '/', '\')
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    [IO.File]::WriteAllText($dest, $pages[$p] + $nl, $utf8)
    Write-Host "wrote docs/$p"
}
Write-Host "OK: $($chars.Count) character page(s), $(@($pages.Keys | Where-Object { $_.StartsWith('s/') }).Count) hidden page(s)."
if ($warnFlags -gt 0) { Write-Host "Note: $warnFlags verify flag(s) still on public pages. Resolve before sharing links." -ForegroundColor Yellow }
