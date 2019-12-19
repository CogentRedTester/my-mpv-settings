#this script is for automatically updating a copy of osc.lua from the mpv git repository
#it then appends some aditional code of mine to the script which allows for the layout to be changed at runtime

function extractDateGit($string) {
    $string = $string -replace "T"," " -replace "Z",""
    return [datetime]::ParseExact($string, 'yyyy-MM-dd HH:mm:ss', $null)
}

function extractDateShin($string) {
    $string = $string -replace " UT",""
    return [datetime]::ParseExact($string, 'ddd, dd MMM yyyy HH:mm:ss', $null)
}

Write-Host "Updating latest version of osc.lua" -ForegroundColor Cyan

Write-Host "Fetching latest rss feed for Shinchiro builds from: https://sourceforge.net/projects/mpv-player-windows/rss?path=/64bit" -ForegroundColor Green
$shinBuilds = [xml](New-Object System.Net.WebClient).DownloadString("https://sourceforge.net/projects/mpv-player-windows/rss?path=/64bit")
$shinBuilds = $shinBuilds.rss.channel.item

#fetching commits from github and converting them into a powershell object
Write-Host "Fetching commits for osc.lua from: https://api.github.com/repos/mpv-player/mpv/commits?path=player/lua/osc.lua" -ForegroundColor Green
$oscCommits = Invoke-Webrequest -uri "https://api.github.com/repos/mpv-player/mpv/commits?path=player/lua/osc.lua" -UseBasicParsing -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox
$oscCommits = ($oscCommits.Content | ConvertFrom-Json)

#grabs the date of the latest commits and shin builds
$oscDate = extractDateGit($oscCommits[0].commit.committer.date)
$latestShin = extractDateShin($shinBuilds[0].pubDate)
$commit = "master"

#moves back through the commits until one is found that predates the latest shin build
for ($i = 1; $oscDate -gt $latestShin; $i++) {
    if ($i-eq 1) {
        Write-Host ('latest osc.lua is newer that the current compiled mpv build, looking for previous version') -ForegroundColor Cyan
    }
    $commit = $oscCommits[$i].sha
    Write-Host $oscDate - 'too recent' -ForegroundColor Cyan
    $oscDate = extractDateGit($oscCommits[$i].commit.committer.date)
}

Write-Host "Using commit from" - $oscDate -ForegroundColor Green
$download_file = (Get-Location).Path + "\portable_config\scripts\osc.lua"

Write-Host "Downloading osc.lua from https://raw.githubusercontent.com/mpv-player/mpv/$commit/player/lua/osc.lua" -ForegroundColor Green
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mpv-player/mpv/$commit/player/lua/osc.lua" -UseBasicParsing -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile $download_file

$new_text = "

--automatically generated function to update options
function update_opts()
    opt.read_options(user_opts, 'osc')
    validate_user_opts()
    visibility_mode(user_opts.visibility, true)
    request_init()
end

mp.register_script_message('update-osc-options', update_opts)
mp.observe_property('options/script-opts', nil, update_opts)"

Write-Host "Inserting function into osc.lua" -ForegroundColor Cyan
$new_text | Add-Content $download_file

Write-Host "osc.lua updated" -ForegroundColor Magenta
