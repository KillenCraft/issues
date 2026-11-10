# Creates the KillenCraft/issues repo, its labels, and pushes the issue forms.
# Requires: git, GitHub CLI (gh) logged in with an account that can create repos in the KillenCraft org.
# Run from the folder containing this script:  pwsh ./setup.ps1

$ErrorActionPreference = 'Stop'
$Repo = 'KillenCraft/issues'
Set-Location $PSScriptRoot

gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Run "gh auth login" first.' }

gh api orgs/KillenCraft --silent 2>$null
if ($LASTEXITCODE -ne 0) {
    throw 'The KillenCraft organization does not exist or you are not a member. Create it at https://github.com/account/organizations/new (free plan), then rerun.'
}

if (-not (Test-Path .git)) {
    git init -b main | Out-Null
    git add .
    git commit -m 'Initial issue tracker: per-mod bug forms, feature form, labels' | Out-Null
}

gh repo view $Repo --json name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    gh repo create $Repo --public `
        --description 'Bug reports and feature requests for KillenCraft Minecraft mods' `
        --disable-wiki --source . --remote origin --push
} else {
    Write-Host "$Repo already exists; pushing."
    git remote get-url origin 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { git remote add origin "https://github.com/$Repo.git" }
    git push -u origin main
}

gh repo edit $Repo --enable-projects=false --enable-discussions=false | Out-Null

# Labels (Flexoki 600 colors). --force updates existing labels.
$labels = @(
    @('TrailWright',         '66800B', 'TrailWright mod'),
    @('Strength In Numbers', 'BC5215', 'Strength In Numbers mod'),
    @('Stope',               '5E409D', 'Stope library'),
    @('bug',                 'AF3029', 'Something is broken'),
    @('enhancement',         '205EA6', 'Feature request'),
    @('compat',              '24837B', 'Conflict or interaction with another mod'),
    @('fabric',              'DBD3B5', 'Happens only on Fabric'),
    @('forge',               'CECDC3', 'Happens only on Forge'),
    @('needs-triage',        'AD8301', 'Not yet reviewed'),
    @('confirmed',           '4385BE', 'Reproduced by the developer'),
    @('wontfix',             '6F6E69', 'Will not be changed'),
    @('duplicate',           '6F6E69', 'Already reported'),
    @('invalid',             '6F6E69', 'Not a bug or not enough information')
)
foreach ($l in $labels) {
    gh label create $l[0] --repo $Repo --color $l[1] --description $l[2] --force | Out-Null
}

# Remove GitHub defaults this tracker does not use.
foreach ($name in 'documentation', 'good first issue', 'help wanted', 'question') {
    gh label delete $name --repo $Repo --yes 2>$null | Out-Null
}

Write-Host "Done: https://github.com/$Repo/issues/new/choose"
