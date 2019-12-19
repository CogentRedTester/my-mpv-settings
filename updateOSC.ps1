$download_file = (Get-Location).Path + "\scripts\osc.lua"

Write-Host "Downloading osc.lua from https://raw.githubusercontent.com/mpv-player/mpv/master/player/lua/osc.lua" -ForegroundColor Green
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mpv-player/mpv/master/player/lua/osc.lua" -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile $download_file

$new_text = "

--automatically generated function to update options
function update_opts()
    opt.read_options(user_opts, 'osc')
    visibility_mode(user_opts.visibility, true)
    request_init()
end

mp.register_script_message('update-osc-options', update_opts)"

$new_text | Add-Content $download_file