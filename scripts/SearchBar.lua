local function HasTileset(layers)
    for _, layer in ipairs(layers) do
        if layer.isGroup and HasTileset(layer.layers) then return true end
        if layer.isTilemap then return true end
    end
end

local function EnableForSprite() return app.activeSprite ~= nil end
local function EnableForImage() return app.activeCel ~= nil end
local function EnableForSelection()
    local sprite = app.activeSprite
    if sprite == nil then return false end

    return not sprite.selection.isEmpty
end
local function EnableForTileset()
    local sprite = app.activeSprite
    if sprite == nil then return false end

    return HasTileset(sprite.layers)
end


-- List of all the commands
local commands = {
    
    {   command = "About", 
        name = "About", 
        path = "Help > About"
    }, 
    
    {
        command = "AdvancedMode",
        name = "Advanced Mode",
        path = "View > AdvancedMode"
    }, {
        command = "AutocropSprite",
        name = "Trim Sprite",
        path = "Sprite > Trim",
        onenable = EnableForSprite
    }, {
        command = "BackgroundFromLayer",
        name = "Convert Layer to Background",
        path = "Layer > Convert To > Background",
        onenable = EnableForSprite
    }, {
        command = "BrightnessContrast",
        name = "Brightness/Contrast",
        path = "Edit > Adjustments > Brightness/Contrast",
        onenable = EnableForImage
    }, {
        command = "CanvasSize",
        name = "Canvas Size",
        path = "Sprite > Canvas Size",
        onenable = EnableForSprite
    }, {
        command = "CelProperties",
        name = "Cel Properties",
        path = "Frame > Cel Properties",
        onenable = EnableForImage
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to RGB",
        path = "Sprite > Color Mode > RGB",
        parameters = {format = "rgb"},
        onenable = EnableForSprite
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Grayscale",
        path = "Sprite > Color Mode > Grayscale",
        parameters = {format = "gray"},
        onenable = EnableForSprite
    }, {
        command = "ChangePixelFormat",
        name = "Set Color Mode to Indexed",
        path = "Sprite > Color Mode > Indexed",
        parameters = {format = "indexed"},
        onenable = EnableForSprite
    }, {
        command = "CloseFile",
        name = "Close File",
        path = "File > Close File",
        onenable = EnableForSprite
    }, {
        command = "CloseAllFiles",
        name = "Close All Files",
        path = "File > Close All Files"
    }, {
        command = "ColorCurve",
        name = "Color Curve",
        path = "Edit > Adjustments > Color Curve",
        onenable = EnableForImage
    }, {
        command = "ColorQuantization",
        name = "New Palette from Sprite",
        path = "Palette > New Palette from Sprite",
        onenable = EnableForSprite
    }, {
        command = "ConvolutionMatrix",
        name = "Convolution Matrix",
        path = "Edit > FX > Convolution Matrix",
        onenable = EnableForImage
    }, {
        command = "CropSprite",
        name = "Crop",
        path = "Edit > Crop",
        onenable = EnableForSelection
    }, {
        command = "Despeckle",
        name = "Despeckle (Median Filter)",
        path = "Edit > FX > Despeckle (Median Filter)",
        onenable = EnableForImage
    }, {
        command = "DeveloperConsole",
        name = "Developer Console",
        path = "Developer Console"
    }, {
        command = "DuplicateLayer",
        name = "Duplicate Layer",
        path = "Layer > Duplicate",
        onenable = EnableForSprite
    }, {
        command = "DuplicateSprite",
        name = "Duplicate Sprite",
        path = "Sprite > Duplicate",
        onenable = EnableForSprite
    }, {
        command = "DuplicateView",
        name = "Duplicate View",
        path = "View > Duplicate View"
    }, {command = "Exit", name = "Exit", path = "File > Exit"}, {
        command = "ExportSpriteSheet",
        name = "Export Sprite Sheet",
        path = "File > Export > Export Sprite Sheet",
        onenable = EnableForSprite
    }, {
        command = "ExportTileset",
        name = "Export Tileset",
        path = "File > Export > Export Tileset",
        onenable = EnableForTileset
    }, {
        command = "FitScreen",
        name = "Fit Screen",
        path = "Zoom > Fit Screen",
        onenable = EnableForSprite
    }, {
        command = "FrameProperties",
        name = "Frame Properties",
        path = "Frame > Frame Properties",
        onenable = EnableForSprite
    }, {
        command = "FullscreenPreview",
        name = "Full Screen Preview",
        path = "View > Full Screen Preview",
        onenable = EnableForSprite
    }, {
        command = "GridSettings",
        name = "Grid Settings",
        path = "View > Grid > Grid Settings"
    }, {
        command = "HueSaturation",
        name = "Hue/Saturation",
        path = "Edit > Adjustments > Hue/Saturation",
        onenable = EnableForImage
    }, {
        command = "ImportSpriteSheet",
        name = "Import Sprite Sheet",
        path = "File > Import > Import Sprite Sheet"
    }, {
        command = "InvertColor",
        name = "Invert Color",
        path = "Edit > Invert",
        onenable = EnableForImage
    }, {
        command = "InvertMask",
        name = "Inverse Selection",
        path = "Select > Inverse",
        onenable = EnableForImage
    }, {
        command = "KeyboardShortcuts",
        name = "Keyboard Shortcuts",
        path = "Edit > Keyboard Shortcuts"
    }, {
        command = "LayerFromBackground",
        name = "Layer from Background",
        path = "Layer > Convert To > Layer",
        onenable = EnableForSprite
    }, {
        command = "LayerProperties",
        name = "Layer Properties",
        path = "Layer > Properties",
        onenable = EnableForSprite
    }, {
        command = "LoadMask",
        name = "Load from MSK file",
        path = "Select > Load from MSK file",
        onenable = EnableForSprite
    }, {
        command = "MaskByColor",
        name = "Select Color Range",
        path = "Select > Color Range",
        onenable = EnableForSprite
    }, {command = "MaskContent", name = "Transform", path = "Edit > Transform"},
    {
        command = "ModifySelection",
        name = "Border Selection",
        path = "Select > Modify > Border",
        parameters = {modifier = "border"},
        onenable = EnableForSelection
    }, {
        command = "ModifySelection",
        name = "Expand Selection",
        path = "Select > Modify > Expand",
        parameters = {modifier = "expand"},
        onenable = EnableForSelection
    }, {
        command = "ModifySelection",
        name = "Contract Selection",
        path = "Select > Modify > Contract",
        parameters = {modifier = "contract"},
        onenable = EnableForSelection
    }, {command = "NewFile", name = "New File", path = "File > New"}, {
        command = "NewFrameTag",
        name = "New Tag",
        path = "Frame > Tags > New Tag",
        onenable = EnableForSprite
    }, {
        command = "NewFrame",
        name = "New Frame",
        path = "Frame > New Frame",
        onenable = EnableForSprite
    }, {
        command = "NewLayer",
        name = "New Layer",
        path = "Layer > New > New Layer",
        onenable = EnableForSprite
    }, {
        command = "NewSpriteFromSelection",
        name = "New Sprite from Selection",
        path = "Edit > New Sprite from Selection",
        onenable = EnableForSelection
    }, {command = "OpenFile", name = "Open File", path = "File > Open"}, {
        command = "OpenScriptFolder",
        name = "Open Script Folder",
        path = "File > Scripts > Open Script Folder"
    }, {command = "Options", name = "Preferences", path = "Edit > Preferences"},
    {
        command = "Outline",
        name = "Outline",
        path = "Edit > FX > Outline",
        onenable = EnableForImage
    }, {
        command = "PasteText",
        name = "Insert Text",
        path = "Edit > Insert Text",
        onenable = EnableForImage
    }, {
        command = "RepeatLastExport",
        name = "Repeat Last Export",
        path = "File > Export > Repeat Last Export",
        onenable = EnableForSprite
    }, {
        command = "ReplaceColor",
        name = "Replace Color",
        path = "Edit > Replace Color",
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate Canvas 180",
        path = "Sprite > Rotate Canvas > 180",
        parameters = {angle = "180"},
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CW",
        path = "Sprite > Rotate Canvas > 90 CW",
        parameters = {angle = "90"},
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate Canvas 90 CCW",
        path = "Sprite > Rotate Canvas > 90 CCW",
        parameters = {angle = "-90"},
        onenable = EnableForSprite
    }, {
        command = "Rotate",
        name = "Rotate 180",
        path = "Edit > Rotate > 180",
        parameters = {target = "mask", angle = "180"},
        onenable = EnableForImage
    }, {
        command = "Rotate",
        name = "Rotate 90 CW",
        path = "Edit > Rotate > 90 CW",
        parameters = {target = "mask", angle = "90"},
        onenable = EnableForImage
    }, {
        command = "Rotate",
        name = "Rotate 90 CCW",
        path = "Edit > Rotate > 90 CCW",
        parameters = {target = "mask", angle = "-90"},
        onenable = EnableForImage
    }, {
        command = "SaveFile",
        name = "Save File",
        path = "File > Save",
        onenable = EnableForSprite
    }, {
        command = "SaveFileAs",
        name = "Save File As",
        path = "File > Save As",
        onenable = EnableForSprite
    }, {
        command = "SaveFileCopyAs",
        name = "Export File",
        path = "File > Export > Export As",
        onenable = EnableForSprite
    }, {
        command = "SaveMask",
        name = "Save to MSK file",
        path = "Select > Save to MSK file",
        onenable = EnableForSprite
    }, {
        command = "SelectionAsGrid",
        name = "Selection as Grid",
        path = "View > Grid > Selection as Grid",
        onenable = EnableForSelection
    }, {
        command = "ShowAutoGuides",
        name = "Show Auto Guides",
        path = "View > Show > Auto Guides"
    }, {command = "ShowExtras", name = "Show Extras", path = "View > Extras"},
    {command = "ShowGrid", name = "Show Grid", path = "View > Show > Grid"}, {
        command = "ShowLayerEdges",
        name = "Show Layer Edges",
        path = "View > Show > Layer Edges"
    }, {
        command = "ShowOnionSkin",
        name = "Show Onion Skin",
        path = "View > Show Onion Skin",
        onenable = EnableForSprite
    }, {
        command = "ShowPixelGrid",
        name = "Show Pixel Grid",
        path = "View > Show > Pixel Grid"
    }, {
        command = "ShowSelectionEdges",
        name = "Show Selection Edges",
        path = "View > Show > Selection Edges"
    },
    {
        command = "ShowSlices",
        name = "Show Slices",
        path = "View > Show > Slices"
    }, {
        command = "SnapToGrid",
        name = "Snap to Grid",
        path = "View > Grid > Snap to Grid"
    }, {
        command = "SpriteProperties",
        name = "Sprite Properties",
        path = "Sprite > Properties",
        onenable = EnableForSprite
    }, {
        command = "SpriteSize",
        name = "Sprite Size",
        path = "Sprite > Sprite Size",
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in None Axes",
        path = "View > Tiled Mode > None",
        parameters = {axis = "none"},
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in Both Axes",
        path = "View > Tiled Mode > Tile in Both Axes",
        parameters = {axis = "both"},
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in X Axis",
        path = "View > Tiled Mode > Tile in X Axis",
        parameters = {axis = "x"},
        onenable = EnableForSprite
    }, {
        command = "TiledMode",
        name = "View Tiled in Y Axis",
        path = "View > Tiled Mode > Tile in Y Axis",
        parameters = {axis = "y"},
        onenable = EnableForSprite
    }, {
        command = "ToggleTimelineThumbnails",
        name = "Toggle Timeline Thumbnails",
        path = "Timeline > Toggle Thumbnails",
        onenable = EnableForSprite
    },
    {
        command = "UndoHistory",
        name = "Undo History",
        path = "Edit > Undo History"
    }
    --
    -- Skipped, requires parameters
    -- { command = "AddColor", name ="" },
    -- {command = "ChangeBrush", name = ""},
    -- {command = "ChangeColor", name = ""},
    -- {command = "Launch", name = ""},
    -- {command = "LayerOpacity", name = ""},
    --
    -- Skipped, requires context
    -- {command = "Cancel", name = ""},
    -- {command = "CelOpacity", name = ""},
    -- {command = "ContiguousFill", name = ""},
    -- {command = "DiscardBrush", name = "Discard Brush"},
    -- {command = "FlattenLayers", name = ""},
    -- {command = "FrameTagProperties", name = ""},
    -- {command = "LayerLock", name = ""},
    -- {command = "LayerVisibility", name = ""},
    -- {command = "LinkCels", name = ""},
    -- {command = "MergeDownLayer", name = ""},
    -- {command = "SetLoopSection", name = ""},
    --
    -- Skipped, already can be achieved with a single key
    -- {command = "ClearCel", name = ""},
    -- {command = "Clear", name = ""},
    -- {command = "DeselectMask", name = ""},
    -- {command = "Fill", name = ""},
    -- {command = "GotoFirstFrameInTag", name = ""},
    -- {command = "GotoFirstFrame", name = ""}, {command = "GotoFrame", name = ""},
    -- {command = "GotoLastFrameInTag", name = ""},
    -- {command = "GotoLastFrame", name = ""},
    -- {command = "GotoNextFrameWithSameTag", name = ""},
    -- {command = "GotoNextFrame", name = ""},
    -- {command = "GotoNextLayer", name = ""},
    -- {command = "GotoNextTab", name = ""},
    -- {command = "GotoPreviousFrameWithSameTag", name = ""},
    -- {command = "GotoPreviousFrame", name = ""},
    -- {command = "GotoPreviousLayer", name = ""},
    -- {command = "GotoPreviousTab", name = ""},
    --
    -- Skipped, already can be achieved with a keyboard shortcut
    -- {command = "CopyCel", name = ""},
    -- {command = "CopyColors", name = ""},
    -- {command = "CopyMerged", name = ""},
    -- {command = "Copy", name = ""},
    -- {command = "Cut", name = ""},
    -- {command = "Flip", name = ""},
    -- {command = "MaskAll", name = ""},
    --
    -- Skipped, tool
    -- {command = "Eyedropper", name = "Eyedropper"},
    --
    -- Skipped
    -- {command = "Home", name = ""},
    -- {command = "LoadPalette", name = ""},
    -- {command = "MoveCel", name = ""}, 
    -- {command = "MoveColors", name = ""},
    -- {command = "MoveMask", name = ""},
    -- {command = "NewBrush", name = ""},
    -- {command = "OpenBrowser", name = "Open Browser"},
    -- {command = "OpenGroup", name = ""},
    -- {command = "OpenInFolder", name = ""},
    -- {command = "OpenWithApp", name = ""},
    -- {command = "PaletteEditor", name = ""},
    -- {command = "PaletteSize", name = ""},
    -- {command = "Paste", name = ""},
    -- {command = "PixelPerfectMode", name = ""},
    -- {command = "PlayAnimation", name = ""},
    -- {command = "PlayPreviewAnimation", name = ""},
    -- {command = "Redo", name = ""},
    -- {command = "Refresh", name = ""},
    -- {command = "RemoveFrameTag", name = ""},
    -- {command = "RemoveFrame", name = ""},
    -- {command = "RemoveLayer", name = ""},
    -- {command = "RemoveSlice", name = ""},
    -- {command = "RunScript", name = ""}, 
    -- {command = "SavePalette", name = "Save Palette"},
    -- {command = "ScrollCenter", name = "Scroll Center"},
    -- {command = "Scroll", name = ""},
    -- {command = "SelectTile", name = ""},
    -- {command = "ReselectMask", name = ""},
    -- {command = "ReverseFrames", name = ""},
    -- {command = "SetColorSelector", name = ""},
    -- {command = "SetInkType", name = ""},
    -- {command = "SetPaletteEntrySize", name = ""},
    -- {command = "SetPalette", name = ""},
    -- {command = "SetSameInk", name = ""},
    -- {command = "ShowBrushPreview", name = "Show Brush Preview"}, -- Skipped, a preferences option
    -- {command = "SliceProperties", name = "Slice Properties"},
    -- {command = "Stroke", name = ""},
    -- {command = "SwitchColors", name = ""},
    -- {command = "SymmetryMode", name = ""},
    -- {command = "Timeline", name = ""},
    -- {command = "TogglePreview", name = ""},
    -- {command = "Undo", name = ""},
    -- {command = "UnlinkCelcommand", name = ""}
}


local SCRIPTS_DIRECTORY = app.fs.joinPath(app.fs.userConfigPath, "scripts")

local function StartsWith(s, prefix) return s:sub(1, prefix:len()) == prefix end
local function RemoveSpaces(s) return (s:gsub(" ", "")) end

local RunScriptPageSize = 6

local function CreateFileStructure(directory, prefix, structure)
    structure = structure or {}
    prefix = prefix or ""

    for _, filename in ipairs(app.fs.listFiles(directory)) do
        local fullFilename = app.fs.joinPath(directory, filename)

        if app.fs.isDirectory(fullFilename) then
            table.insert(structure, {
                filename = filename,
                filepath = fullFilename,
                children = CreateFileStructure(fullFilename,
                                               prefix .. filename .. " > ", {})
            })
        elseif app.fs.isFile(fullFilename) and app.fs.fileExtension(filename) ==
            "lua" then
            local title = app.fs.fileTitle(filename)
            table.insert(structure, {
                filename = filename,
                name = title,
                path = "File > Scripts > " .. prefix .. title,
                filepath = fullFilename
            })
        end
    end

    return structure
end

local function SearchScriptsRecursively(fileStructure, searchText, pattern,
                                        prefix, exactMatches, prefixMatches,
                                        fuzzyMatches)
    for _, fileEntry in ipairs(fileStructure) do
        if fileEntry.children then
            SearchScriptsRecursively(fileEntry.children, searchText, pattern,
                                     prefix .. fileEntry.filename .. " > ",
                                     exactMatches, prefixMatches, fuzzyMatches)
        else
            local name = fileEntry.filename:lower()

            if name == searchText then
                table.insert(exactMatches, fileEntry)
            elseif StartsWith(name, searchText) then
                table.insert(prefixMatches, fileEntry)
            elseif name:match(pattern) then
                table.insert(fuzzyMatches, fileEntry)
            end
        end
    end
end

local function CopyToResults(matches, results, showDisabled)
    for _, match in ipairs(matches) do
        match.enabled = true
        if match.onenable ~= nil then match.enabled = match.onenable() end

        if showDisabled or match.enabled then
            table.insert(results, match)
        end
    end
end

local function SearchScripts(searchText, fileStructure)
    local exactMatches, prefixMatches, fuzzyMatches, results = {}, {}, {}, {}

    -- Use lowercase for case-insensitive search
    searchText = searchText:lower()

    local pattern = ""
    for i = 1, #searchText do
        pattern = pattern .. searchText:sub(i, i) .. ".*"
    end

    SearchScriptsRecursively(fileStructure, searchText, pattern, "",
                             exactMatches, prefixMatches, fuzzyMatches)

    table.sort(exactMatches, function(a, b) return a.filename < b.filename end)
    table.sort(prefixMatches, function(a, b) return a.filename < b.filename end)
    table.sort(fuzzyMatches, function(a, b) return a.filename < b.filename end)

    CopyToResults(exactMatches, results)
    CopyToResults(prefixMatches, results)
    CopyToResults(fuzzyMatches, results)

    return results
end

local function SearchCommands(searchText, showDisabled)
    local exactMatches, prefixMatches, fuzzyMatches, results = {}, {}, {}, {}

    -- Use lowercase for case-insensitive search
    searchText = searchText:lower()

    local pattern = ""
    for i = 1, #searchText do
        pattern = pattern .. searchText:sub(i, i) .. ".*"
    end

    for _, command in ipairs(commands) do
        local name = command.name:lower()
        local path = command.path:lower()

        if name == searchText then
            table.insert(exactMatches, command)
        elseif path == searchText then
            table.insert(exactMatches, command)
        elseif StartsWith(name, searchText) then
            table.insert(prefixMatches, command)
        elseif StartsWith(path, searchText) then
            table.insert(prefixMatches, command)
        elseif name:match(pattern) then
            table.insert(fuzzyMatches, command)
        elseif path:match(pattern) then
            table.insert(fuzzyMatches, command)
        end
    end

    CopyToResults(exactMatches, results, showDisabled)
    CopyToResults(prefixMatches, results, showDisabled)
    CopyToResults(fuzzyMatches, results, showDisabled)

    return results
end

local function RunScriptDialog(options)
    local search = ""
    local dialog
    dialog = Dialog {
        title = options.title,
        onclose = function()
            if options.onclose then options.onclose(dialog.data) end
        end
    }
    local results = {}
    local currentPage = 1

    local fileStructure = CreateFileStructure(SCRIPTS_DIRECTORY)

    local function RefreshWidgets()
        local numberOfPages = math.max(math.ceil(#results / RunScriptPageSize),
                                       1)
        currentPage = math.min(currentPage or 1, numberOfPages)

        local skip = (currentPage - 1) * RunScriptPageSize
        local resultsOnPage = math.min(RunScriptPageSize, #results - skip)

        dialog:modify{
            id = "resultsSeparator",
            visible = #dialog.data.search > 0
        }
        dialog:modify{
            id = "noResults",
            visible = #dialog.data.search > 0 and resultsOnPage == 0
        }

        for i = 1, resultsOnPage do
            local result = results[skip + i]

            local name = result.name
            if dialog.data.showPaths then name = result.path end

            dialog:modify{
                id = "result-" .. tostring(i),
                visible = true,
                text = name,
                enabled = result.enabled
            }
        end

        if resultsOnPage < RunScriptPageSize then
            for i = resultsOnPage + 1, RunScriptPageSize do
                dialog:modify{id = "result-" .. tostring(i), visible = false}
            end
        end

        dialog --
        :modify{
            id = "prev-page",
            visible = currentPage > 1,
            enabled = numberOfPages > 1 and currentPage > 1
        } --
        :modify{
            id = "next-page",
            visible = currentPage < numberOfPages,
            enabled = numberOfPages > 1 and currentPage < numberOfPages
        }
    end

    local function SearchAll()
        search = RemoveSpaces(dialog.data.search)
        results = {}
        if #search > 0 then
            if dialog.data.searchCommands then
                for _, command in ipairs(
                                      SearchCommands(search,
                                                     dialog.data.showDisabled)) do
                    table.insert(results, command)
                end
            end

            if dialog.data.searchScripts then
                for _, script in ipairs(SearchScripts(search, fileStructure)) do
                    table.insert(results, script)
                end
            end
        end

        RefreshWidgets()
    end

    dialog --
    :label{text = "Search a command or script :"} --
    :entry{id = "search", text = search, onchange = function() SearchAll() end} --
    :separator{id = "resultsSeparator", text = "Results:"} --
    :label{id = "noResults", text = "No results"} --
    :button{
        id = "prev-page",
        text = "...",
        visible = false,
        enabled = false,
        onclick = function()
            currentPage = currentPage - 1
            RefreshWidgets()
            dialog:modify{
                id = "result-" .. tostring(RunScriptPageSize),
                focus = true
            }
        end
    } --
    :newrow()

    for i = 1, RunScriptPageSize do
        dialog --
        :button{
            id = "result-" .. tostring(i),
            visible = false,
            onclick = function()
                local skip = (currentPage - 1) * RunScriptPageSize
                local result = results[i + skip]

                -- Close the dialog first to avoid having it left open if the scripts opens it's own dialog with option `wait=true`
                dialog:close()

                if result.command then
                    app.command[result.command](result.parameters)
                else
                    -- Execute the selected script
                    dofile(result.filepath)
                end

                if options.onrun then
                    options.onrun(result, dialog.data)
                end
            end
        } --
        :newrow()
    end

    dialog --
    :button{
        id = "next-page",
        text = "...",
        visible = false,
        enabled = false,
        onclick = function()
            currentPage = currentPage + 1
            RefreshWidgets()
            dialog:modify{id = "result-1", focus = true}
        end
    } --
    :separator{text = "Sources:"} --
    :check{
        id = "searchCommands",
        text = "Commands",
        selected = options.searchCommands,
        onclick = function() SearchAll() end
    } --
    :check{
        id = "searchScripts",
        text = "Scripts",
        selected = options.searchScripts,
        onclick = function() SearchAll() end
    } --
    :separator{text = "Options:"} -- 
    :check{
        id = "showPaths",
        text = "Show paths",
        selected = options.showPaths,
        onclick = function() SearchAll() end
    } --
    :check{
        id = "showDisabled",
        text = "Show disabled",
        selected = options.showDisabled,
        onclick = function() SearchAll() end
    } --
    :button{text = "Cancel"}

    -- Open and close to initialize the dialog bounds
    dialog:show{wait = false}
    dialog:modify{id = "resultsSeparator", visible = false}
    dialog:modify{id = "noResults", visible = false}
    dialog:close()

    local defaultWidth = 780

    -- Set an initial width of the dialog
    local newBounds = dialog.bounds
    newBounds.x = newBounds.x - math.abs(newBounds.width - defaultWidth) / 2
    newBounds.width = defaultWidth
    dialog.bounds = newBounds

    return dialog
end


local dialog = RunScriptDialog {
                title = "Search and Run",
                searchCommands = true,
                searchScripts = true,
                showPaths = true,
                showDisabled = false,
        
            }

dialog:show()

