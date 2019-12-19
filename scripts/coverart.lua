--this script automatically scans the directory of the currently open file for valid external cover art and automatically loads it into mpv player
--I can only confirm that this works on windows, I have not tested it on any other platform, however it should be simple to adapt by modifying lines 44 & 45

utils = require 'mp.utils'
msg = require 'mp.msg'
opt = require 'mp.options'

local o = {
    --list of names of valid cover art, must be separated by semicolon with no spaces
    --the script is not case specific
    filenames = "cover.jpg;cover.png;folder.jpg;folder.png;album.jpg;album.png",

    --ignore the filename and load all image files
    load_all = false,

    --valid image extensions, same rules as the filenames option applies
    imageExts = 'jpg;jpeg;png;bmp;gif'
}

--processes the option strings to ensure they work with the script
function processStrings()
    --sets everything to lowercase to avoid confusion
    o.filenames = string.lower(o.filenames)
    o.imageExts = string.lower(o.imageExts)

    --wraps the string in semicolons because the algorithm looks for a string bracketted by semicolons
    --if the string isn't wrapped then the first and last entries may not work
    o.imageExts = ";" .. o.imageExts .. ";"
    o.filenames = ";" .. o.filenames .. ";"
end

function checkForCoverart()
    --finds the local directory of the file

    local workingDirectory = mp.get_property('working-directory')
    msg.verbose('working-directory: ' .. workingDirectory)
    local filepath = mp.get_property('path')
    msg.verbose('filepath: ' .. filepath)

    --converts the string into a compatible path for mpv to parse
    --only confirmed to work in windows
    local path = utils.join_path(workingDirectory, filepath)
    msg.verbose('full path: ' .. path)
    path = path:gsub([[/.\]], [[/]])
    path = path:gsub([[\]], [[/]])
    msg.verbose('standardising characters, new path: ' .. path)

    --splits the directory and filename apart
    local directory, filename = utils.split_path(path)
    msg.verbose('directory: ' .. directory)
    msg.verbose('file: ' .. filename)

    --loads the files from the directory
    files = utils.readdir(directory, "files")

    --loops through the all the files in the directory to find if any are valid cover art
    msg.verbose('scanning files in ' .. directory)
    for i = 1, #files, 1 do
        msg.debug('found file: ' .. files[i])
        local file = string.lower(files[i])
        local fileext

        --extracts the file extension if load_all is enabled
        if o.load_all then
            local index = string.find(file, [[.[^.]*$]])
            msg.debug('index of final period: ' .. index)
            fileext = file:sub(index + 1)
            msg.debug('file extension: ' .. fileext)
        end

        --if the name matches one in the whitelist
        if (o.filenames:match(';' .. file .. ';') or (o.load_all and o.imageExts:match(";" .. fileext .. ";"))) then
            msg.verbose(file .. ' found in whitelist - adding as extra video track...')
            local path = utils.join_path(directory, file)

            --adds the new file to the playing list, 
            mp.commandv('video-add', path, "auto")

            --if there is no video track currently selected then it autoloads track #1
            msg.verbose('current video track: ' .. mp.get_property('vid'))
            if mp.get_property('vid') == "no" then
                msg.verbose('switching to track #1')
                mp.set_property_number('vid', 1)
            end
        end
    end
end

opt.read_options(o, 'coverart')
processStrings()

--runs automatically whenever a file is loaded
mp.register_event('file-loaded', checkForCoverart)

--to force an update during runtime
mp.register_script_message('load-coverart', checkForCoverart)