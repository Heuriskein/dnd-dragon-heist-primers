# Builds the GitHub Pages site in docs/ from lore/ and characters/.
#
#   powershell -ExecutionPolicy Bypass -File tools\build.ps1
#
# Everything in docs/ except _config.yml is deleted and regenerated.
# The build stops before writing anything if a spoiler check fails, or if
# docs/ was edited by hand since the last build (see .build-manifest.json).
# -Force overwrites hand edits; move them into lore/ or characters/ first.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).

param([switch]$Force)

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$docs   = Join-Path $root 'docs'
$tiers  = @('common', 'proficient', 'expert')
$utf8   = New-Object System.Text.UTF8Encoding $false
$nl     = "`n"

# --- spoiler rules (see CLAUDE.md) ---------------------------------------
# Banned on every generated page, secret sections included.
$banned = 'manshoon|golorr|kolat|zord|vault|devil|asmodeus|fireball|soulmonger|acererak|\bomu\b|ras nsi|trickster gods'
# Secret-tier text: allowed only inside the secret sections of characters who
# qualify (see mapping.md). Everything else on every page is checked for it.
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

# Rumor pool: lore/rumors.md, one "## <id>" section per rumor. "DM:" lines are stripped.
function Get-RumorPool {
    $pool = [ordered]@{}
    $script:rumorDrafts = @()
    $script:rumorAllowLaeralCurse = @()
    $current = $null
    $buf = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Read-Utf8 (Join-Path $root 'lore\rumors.md')) -split $nl) {
        if ($line -match '^## ([a-z0-9-]+)\s*$') {
            if ($current) { $pool[$current] = ($buf -join ' ').Trim() }
            $current = $Matches[1]
            if ($pool.Contains($current)) { throw "lore\rumors.md: duplicate rumor id '$current'" }
            $buf.Clear()
        } elseif ($line -match '^## ') {
            throw "lore\rumors.md: rumor ids must be lowercase-with-dashes: '$line'"
        } elseif ($current -and $line -match '^DM:') {
            if ($line -match '\bDRAFT\b') { $script:rumorDrafts += $current }
            # DM-approved exception: this rumor may tie Laeral to the curse.
            if ($line -match '\bALLOW-LAERAL-CURSE\b') { $script:rumorAllowLaeralCurse += $current }
        } elseif ($current -and $line.Trim()) {
            $buf.Add($line.Trim())
        }
    }
    if ($current) { $pool[$current] = ($buf -join ' ').Trim() }
    foreach ($id in @($pool.Keys)) { if (-not $pool[$id]) { throw "lore\rumors.md: rumor '$id' has no text" } }
    $pool
}

# 1 rumor for everyone, +1 with Investigation proficiency, +1 more with expertise.
function Get-RumorCount([string]$investigation) {
    switch ("$investigation".ToLower()) {
        ''           { 1 }
        'none'       { 1 }
        'proficient' { 2 }
        'expert'     { 3 }
        default      { throw "Bad 'investigation' value '$investigation'. Use none, proficient or expert." }
    }
}

# Deterministic draw: same pool ids + same character = same rumors, so unrelated
# rebuilds don't reshuffle. Adding or removing a rumor id redraws everyone.
# Rewording a rumor does not.
function Get-RumorDraw([string]$slug, [int]$count) {
    $ids = @($rumorPool.Keys | Sort-Object)
    if ($ids.Count -lt $count) { throw "$slug should hear $count rumor(s) but the pool only has $($ids.Count). Add rumors to lore\rumors.md." }
    $key = $slug + '|' + ($ids -join ',')
    $md5 = [Security.Cryptography.MD5]::Create()
    $seed = [BitConverter]::ToInt32($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($key)), 0)
    $rng = New-Object System.Random $seed
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($id in $ids) { $list.Add($id) }
    for ($i = $list.Count - 1; $i -gt 0; $i--) {
        $j = $rng.Next($i + 1)
        $t = $list[$i]; $list[$i] = $list[$j]; $list[$j] = $t
    }
    @($list.GetRange(0, $count))
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
$pageSecrets = [ordered]@{}   # page path -> rendered secret sections (exempt from secret checks)
$rumorPool = Get-RumorPool
$draftUse = @()

$charFiles = Get-ChildItem (Join-Path $root 'characters') -Filter '*.json' | Where-Object { $_.Name -notlike '_*' }
foreach ($f in $charFiles) {
    $c = (Read-Utf8 $f.FullName) | ConvertFrom-Json
    foreach ($req in 'name', 'slug', 'tagline', 'intro', 'sections') {
        if (-not $c.$req) { throw "$($f.Name): missing '$req'" }
    }
    $chars += $c

    # Unlisted: no index page, no sidebar entry, no search, so players don't wander into each other's pages.
    $fm = [ordered]@{ title = $c.name; nav_exclude = $true; search_exclude = $true; sitemap = $false }
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

    # Secret knowledge: woven in as ordinary sections, styled like every other
    # section, so nothing marks it as special. Only qualifying characters list
    # secrets (mapping.md -> "Secret knowledge").
    if ($c.PSObject.Properties.Name -contains 'secretPage') {
        throw "$($f.Name): remove 'secretPage'. Secrets are now sections on the character page."
    }
    $secretBlocks = @()
    foreach ($sec in @($c.secrets | Where-Object { $_ })) {
        if (-not $sec.because) { throw "$($f.Name): secret '$($sec.id)' needs 'because'" }
        $s = Get-Secret $sec.id
        $heading = if ($sec.heading) { $sec.heading } else { $s.Title }
        # Character extras go at the module's <!-- extras --> marker, or at the end.
        $extra = ''
        if ($sec.extra) { $extra = Format-Bullets $sec.extra }
        if ($s.Body -match '<!-- extras -->') {
            $body = (($s.Body -replace '<!-- extras -->', $extra) -replace '\n{3,}', ($nl + $nl)).Trim()
        } else {
            $body = $s.Body
            if ($extra) { $body += $nl + $nl + $extra }
        }
        $block = (@("## $heading", "*Because: $($sec.because)*", '', $body) -join $nl)
        $secretBlocks += $block
        $out += $block
        $out += ''
    }
    $pageSecrets["$($c.slug).md"] = $secretBlocks

    # Rumors: drawn by the build, seeded from the slug and the pool's ids.
    if ($c.PSObject.Properties.Name -contains 'rumors') {
        throw "$($f.Name): remove 'rumors'. Rumors are drawn by the build from lore\rumors.md."
    }
    $want = Get-RumorCount $c.investigation
    $have = Get-RumorDraw $c.slug $want
    $because = 'everyone hears something in a city this size'
    if ($want -ge 2) { $because += " $([char]0x00B7) Investigation " + $(if ($want -ge 3) { 'expertise' } else { 'proficiency' }) }
    $out += "## Rumors you've heard"
    $out += "*Because: $because*"
    $out += ''
    $out += (Format-Bullets @($have | ForEach-Object { $rumorPool[$_] }))
    $draftUse += @($have | Where-Object { $script:rumorDrafts -contains $_ } | ForEach-Object { "$($c.slug): $_" })
    $out += ''

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
}

# Home page: a welcome only. It must never list or link character pages;
# each player gets their own link (see roster.md).
$pages['index.md'] = (@(
    (Format-FrontMatter ([ordered]@{ title = 'Home'; nav_order = 1 })), '',
    '# Waterdeep: What You Know', '',
    'Welcome to Waterdeep, the City of Splendors. This site holds what your character knows about the city when the campaign begins: what every resident knows, plus what their skills, background and ancestry have taught them.', '',
    'Everything here is what people *believe*. Rumors can be wrong, and the city has secrets.', ''
) -join $nl)

# --- checks (nothing is written if any fail) -----------------------------
$errors = @()
$warnFlags = 0
foreach ($p in $pages.Keys) {
    $text = $pages[$p]
    foreach ($m in [regex]::Matches($text, $banned, 'IgnoreCase')) { $errors += "${p}: banned spoiler '$($m.Value)'" }
    # The character's own secret sections are exempt from the secret checks;
    # everything else on the page must be clean.
    $rest = $text
    if ($pageSecrets.Contains($p)) { foreach ($b in $pageSecrets[$p]) { $rest = $rest.Replace($b, '') } }
    foreach ($m in [regex]::Matches($rest, $secret, 'IgnoreCase')) { $errors += "${p}: secret-tier text '$($m.Value)' outside a secret section" }
    # Rumors the DM marked ALLOW-LAERAL-CURSE are exempt from this one check.
    foreach ($id in $script:rumorAllowLaeralCurse) { $rest = $rest.Replace($rumorPool[$id], '') }
    foreach ($m in [regex]::Matches($rest, $laeralCurse, 'IgnoreCase')) { $errors += "${p}: ties Laeral to the curse: '$($m.Value)'" }
    $warnFlags += ([regex]::Matches($text, [string][char]0x26A0)).Count
}
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "FAIL $_" -ForegroundColor Red }
    throw "Build stopped: $($errors.Count) check(s) failed. docs/ was not changed."
}

# --- hand-edit guard -----------------------------------------------------
# The manifest holds a hash of every file the last build wrote. Hashes ignore
# line endings, because git may convert LF/CRLF when it touches files.
$manifestPath = Join-Path $root '.build-manifest.json'
$sha = [Security.Cryptography.SHA256]::Create()
function Get-TextHash([string]$text) {
    $bytes = $utf8.GetBytes(($text -replace "`r`n", "`n"))
    -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
}
function Get-DocsFiles {
    Get-ChildItem $docs -Recurse -File -Force | Where-Object { $_.Name -ne '_config.yml' } | ForEach-Object {
        ($_.FullName.Substring($docs.Length + 1)) -replace '\\', '/'
    }
}
if (Test-Path $manifestPath) {
    $manifest = @{}
    ((Read-Utf8 $manifestPath) | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $manifest[$_.Name] = $_.Value }
    $handEdits = @()
    foreach ($rel in @(Get-DocsFiles)) {
        if (-not $manifest.ContainsKey($rel)) { $handEdits += "docs/$rel (not written by the build)"; continue }
        $now = Get-TextHash (Read-Utf8 (Join-Path $docs ($rel -replace '/', '\')))
        if ($now -ne $manifest[$rel]) { $handEdits += "docs/$rel (edited since the last build)" }
    }
    if ($handEdits.Count -gt 0) {
        $handEdits | ForEach-Object { Write-Host "HAND EDIT $_" -ForegroundColor Red }
        if (-not $Force) {
            throw "Build stopped: docs/ was edited by hand. Move the changes into lore/ or characters/ (see 'git diff docs/'), then rerun with -Force. docs/ was not changed."
        }
        Write-Host '-Force: overwriting hand edits.' -ForegroundColor Yellow
    }
} else {
    Write-Host 'No .build-manifest.json yet: skipping the hand-edit check this once.' -ForegroundColor Yellow
}

# --- write ---------------------------------------------------------------
Get-ChildItem $docs -Force | Where-Object { $_.Name -ne '_config.yml' } | Remove-Item -Recurse -Force
$newManifest = [ordered]@{}
foreach ($p in $pages.Keys) {
    $dest = Join-Path $docs ($p -replace '/', '\')
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $content = $pages[$p] + $nl
    [IO.File]::WriteAllText($dest, $content, $utf8)
    $newManifest[$p] = Get-TextHash $content
    Write-Host "wrote docs/$p"
}
[IO.File]::WriteAllText($manifestPath, ($newManifest | ConvertTo-Json) + $nl, $utf8)
Write-Host "OK: $($chars.Count) character page(s), $(@($pageSecrets.Values | ForEach-Object { $_ } | Where-Object { $_ }).Count) secret section(s)."
if ($warnFlags -gt 0) { Write-Host "Note: $warnFlags verify flag(s) still on public pages. Resolve before sharing links." -ForegroundColor Yellow }
if ($draftUse.Count -gt 0) {
    Write-Host "Note: $($draftUse.Count) DRAFT rumor(s) on pages. Approve them (remove DRAFT from the DM: line) before sharing links:" -ForegroundColor Yellow
    $draftUse | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}
