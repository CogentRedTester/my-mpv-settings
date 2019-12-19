#downloads the latest version of osc.lua that was committed before the latest shinchiro build
#then appends the updateOptions function to the file

function extractDateGit($string) {
    $string = $string.substring(0, 10)
    return [datetime]::ParseExact($string, 'yyyy-MM-dd', $null)
}

function extractDateShin($string) {
    $string = $string.substring(5, 11)
    Write-Host $string
    return [datetime]::ParseExact($string, 'dd MMM yyyy', $null)
}

Write-Host "Updating latest version of osc.lua" -ForegroundColor Blue

Write-Host "Fetching latest rss feed for Shinchiro builds from: https://sourceforge.net/projects/mpv-player-windows/rss?path=/64bit" -ForegroundColor Green
$shinBuilds = [xml](New-Object System.Net.WebClient).DownloadString("https://sourceforge.net/projects/mpv-player-windows/rss?path=/64bit")
$shinBuilds = $shinBuilds.rss.channel.item

#fetching commits from github and converting them into a powershell object
Write-Host "Fetching commits for osc.lua from: https://api.github.com/repos/mpv-player/mpv/commits?path=player/lua/osc.lua"
$oscCommits = invoke-webrequest -uri "https://api.github.com/repos/mpv-player/mpv/commits?path=player/lua/osc.lua"
$oscCommits = ($oscCommits.Content | ConvertFrom-Json)

#grabs the date of the latest commits and shin builds
$oscdate = extractDateGit($oscCommits[0].commit.committer.date)
$latestShin = extractDateShin($shinBuilds[0].pubDate)
$commit = "master"

#moves back through the commits until one is found that predates the latest shin build
for ($i = 1; $oscdate -gt $latestShin; $i++) {
    if ($i-eq 1) {
        Write-Host ('latest osc.lua is newer that the current compiled mpv build, looking for previous version') -ForegroundColor Blue
    }
    $commit = $oscCommits[$i].sha
    $oscDate = extractDateGit($oscCommits[$i].commit.committer.date)
}


$download_file = (Get-Location).Path + "\portable_config\scripts\osc.lua"

Write-Host "Downloading osc.lua from https://raw.githubusercontent.com/mpv-player/mpv/$commit/player/lua/osc.lua" -ForegroundColor Green
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mpv-player/mpv/$commit/player/lua/osc.lua" -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile $download_file

$new_text = "

--automatically generated function to update options
function update_opts()
    opt.read_options(user_opts, 'osc')
    visibility_mode(user_opts.visibility, true)
    request_init()
end

mp.register_script_message('update-osc-options', update_opts)"

Write-Host "Inserting function into osc.lua" -ForegroundColor Blue
$new_text | Add-Content $download_file

Write-Host "osc.lua updated" -ForegroundColor Magenta