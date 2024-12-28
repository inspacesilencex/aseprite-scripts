-- Path Animator Tool
-- Copyright (C) 2020-2022 Gaspar Capello

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

STRING_PATH_LAYER = "PATH"
STRING_RESULT_LAYER = "ResultLayer"
STRING_FUNCTION_LAYER = "TFUN"
STRING_ROTATION_LAYER = "RFUN"
STRING_SCALE_LAYER = "SFUN"
STRING_LOOKED_LAYER = "LOOKIT"
STRING_ROTAUX_LAYER = "RotAux"

STRING_INITIAL_SCALE = "Start_scale:_"
STRING_FINAL_SCALE = "Final_scale:_"

FUNC_LINEAL = "Lineal"
FUNC_BYLAYER = "By Layer"
FUNC_EASYIN = "Easy In"
FUNC_EASYOUT = "Easy Out"
FUNC_EASYINOUT = "Easy InOut"
FUNC_SINUSOIDAL = "Sinusoidal"
FUNC_PARABOLIC = "Parabolic"
FUNC_EASYOUTDAMPED = "Easy Out Damped"
FUNC_EASYOUTDAMPED2 = "Easy Out Damped2"

ROTATION_NONE = "None"
ROTATION_PATH = "Path track"
ROTATION_LOOKAT = "Look at"
ROTATION_BYLAYER = "By Layer"

SCALE_NONE = "None"
SCALE_LINEAL = "Lineal"
SCALE_BYLAYER = "By Layer"
SCALE_EASYIN = "Easy In"
SCALE_EASYOUT = "Easy Out"
SCALE_EASYINOUT = "Easy InOut"
SCALE_SINUSOIDAL = "Sinusoidal"
SCALE_PARABOLIC = "Parabolic"
SCALE_EASYOUTDAMPED = "Easy Out Damped"
SCALE_EASYOUTDAMPED2 = "Easy Out Damped2"

DEFAULT_STARTTIME_STRING = "Start_time_[seg]"
DEFAULT_DURATION_STRING = "Duration_[seg]"
DEFAULT_INITIALANGLE_STRING = "Start_angle_[degrees]"
DEFAULT_PATH_START_POS_STRING = "Start_path_pos_[%]"
DEFAULT_LOOP_PATH = false
DEFAULT_INITIAL_SCALE = 1.0
DEFAULT_FINAL_SCALE = 1.0
DEFAULT_MAKE_NEW_RESULT_LAYER = true

TFUNprefix = "Translation: "
ROTATIONprefix = "Rotation: "
SFUNprefix = "Scale: "
LOOP_PHASE = "Loop the path translation?"

-- K_PATH_TO_IMAGE_CONSTANT
-- Towards 0.0 (minimum in practice 0.2) angles ares more tangencial to the path curve, but low angle resolution is obtained.
-- In thr other hand, K_PATH_TO_IMAGE_CONSTANT towards 1.0, is like a wagon on a railways,
-- the middle axis of the image will be secant on two points on the path ccurves
K_PATH_TO_IMAGE_CONSTANT = 0.75

MASK_COLOR2 = 0x007f7f7f

function lineal(x)
  return x
end

function sinusoidal(x)
  return (1 - math.cos(2 * math.pi * x)) / 2
end

function parabolic(x)
  return -4 * (x - 1) * x
end

function easyOutDamped(x)
  local maxAmp = 1.29
  if x == 0 then
    return 0
  else
    if x >= 0.87 then
      return 0.775
    else
      return (2^(-10 * x) * math.sin((8 * x - 0.75) * 2) + 1) / maxAmp
    end
  end
end

function easyOutDamped2(x)
  local maxAmp = 1.125
  if x == 0 then
    return 0
  else
    if x >= 0.48 then
      return 0.8889
    else
      return (2^(-18 * x) * math.sin((8 * x - 0.75) * 2) + 1) / maxAmp
    end
  end
end

function easyInOut(x)
  if x < 0.5 then
    return 4 * x * x * x
  else
    return 1 - (-2 * x + 2)^3 / 2
  end
end

function easyIn(x)
  return x * x * x
end

function easyOut(x)
  return 1 - (1 - x)^3;
end

-- Curve by layer:
function makeCurveFromLayer(layer, isRotationCurve)
  local curve = {}
  if layer.cels[1] == nil then
    app.alert(string.format("No image on layer '%s'. Please draw a stroke on the first frame.", layer.name))
    return nil
  end
  local image = layer.cels[1].image
  local amp = image.height - 1
  local time = image.width - 1
  if image == nil or amp < 1 or time < 1  then
    app.alert(string.format("No image on layer '%s'. Image size should be a minimum of 2x2 pixels.", layer.name))
    return nil
  end
  local maskColor = image.spec.transparentColor
  local errorFlag = true
  -- first pixel column (x == 0) is not considered, first column is an axis to know which is the 0.0 (bottom) to 1.0 (top).
  -- when IS a ROTATION CURVE first pixel column (x == 0) is an axis to know which is the '-pi' (bottom) and 'pi' (top) angles.
  for x=1, time, 1 do
    for y=0, amp, 1 do
      if image:getPixel(x, y) ~= maskColor and
         image:getPixel(x, y) ~= MASK_COLOR2 then
        if isRotationCurve then
          table.insert(curve, (amp - 2*y) / amp * math.pi)
        else
          table.insert(curve, (amp - y) / amp)
        end
        errorFlag = false
        break
      end
    end
    if errorFlag then
      app.alert(string.format("The image curve on layer '%s' hasn't continuity on X", layer.name))
      return nil
    end
  end
  return curve
end

function byLayer(x, vectorCurve)
  local xToIndex = x * (#vectorCurve-1) + 1
  -- Interpolate position between two vectorCurve elements
  local index0 = math.floor(xToIndex)
  local index1 = index0 + 1
  if index1 > #vectorCurve then
    return vectorCurve[#vectorCurve]
  end
  local slope = vectorCurve[index1] - vectorCurve[index0]
  local xFromIndex0 = (xToIndex - math.floor(xToIndex))
  return vectorCurve[index0] + slope * xFromIndex0
end

function generateLayerIDString(pathLayerCollection, drawingLayerCollection)
    local resultLayerIdString = ""
    for i,layer in ipairs(pathLayerCollection) do
        if layer ~= startPathLayer then
            resultLayerIdString = resultLayerIdString .. layer.name .. "«"
        end
    end
    for i,layer in ipairs(drawingLayerCollection) do
      resultLayerIdString = resultLayerIdString .. layer.name .. "§"
    end
    return resultLayerIdString
end

function generateDrawingLayerIDString(drawingLayerCollection)
    local resultLayerIdString = ""
    for i,layer in ipairs(drawingLayerCollection) do
        resultLayerIdString = resultLayerIdString .. layer.name .. "§"
    end
    return resultLayerIdString
end

function selectOriginalLayers(selectedLayerStackIndices)
    if #selectedLayerStackIndices == 0 then
        return nil
    end
    local originalSelectedLayers = {}
    for i=1, #selectedLayerStackIndices, 1 do
        for j,layer in ipairs(app.activeSprite.layers) do
            if layer.stackIndex == selectedLayerStackIndices[i] then
                table.insert(originalSelectedLayers, layer)
            end
        end
    end
    app.range.layers = originalSelectedLayers
end

function readConfigurationFromLayer(layer)
    if layer == nil then
        return nil
    end
    local firstFoundedCel = nil
    local firstFrameNumberWithCel = layer.cels[1].frame.frameNumber
    for i=firstFrameNumberWithCel, firstFrameNumberWithCel + #layer.cels - 1, 1 do
        if layer:cel(i) ~= nil then
            firstFoundedCel = layer:cel(i)
            if firstFoundedCel == nil or firstFoundedCel.data == nil or firstFoundedCel.data == "" then
                return nil
            end
            return firstFoundedCel.data
        end
    end
    return nil
end

function findLayer(sprite, nameToFind)
    for i,layer in ipairs(sprite.layers) do
        if layer.name == nameToFind then
            return layer
        end
    end
    return nil
end

function extractDrawingLayersFromLayerConf(layerData)
    local layerSeriesString = layerData
    while true do
        if layerSeriesString:find("«") == nil then
            break
        end
        layerSeriesString = layerSeriesString:sub(layerSeriesString:find("«")+2, layerSeriesString:len())
    end
    local drawingLayersCollection = {}
    local safecounter = 200
    if layerSeriesString:find("§") == nil then
        return drawingLayersCollection
    end
    while true do
        local layerString = layerSeriesString:sub(1, layerSeriesString:find("§")-1)
        for i,layer in ipairs(app.activeSprite.layers) do
            if layer.name == layerString then
                table.insert(drawingLayersCollection, layer)
                break
            end
        end
        layerSeriesString = layerSeriesString:sub(layerSeriesString:find("§")+2, layerSeriesString:len())
        if layerSeriesString == nil or layerSeriesString == "" or safecounter <= 0 or layerSeriesString:find("§") == nil then
            break
        end
        safecounter = safecounter - 1
    end
    return drawingLayersCollection
end

function extractTranslationFunLayerFromLayerConf(layerData)
    if layerData:find("§y") == nil then
        return nil
    end
    local translationFunctionLayerNameString = layerData:sub(layerData:find("§y")+3, layerData:len())
    if translationFunctionLayerNameString == nil or translationFunctionLayerNameString == "" then
        app.alert("Error: no rotational layer function found.")
        return nil
    end
    translationFunctionLayerNameString = translationFunctionLayerNameString:sub(1, translationFunctionLayerNameString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == translationFunctionLayerNameString then
            return layer
        end
    end
    return nil
end

function extractRotFunLayerFromLayerConf(layerData)
    if layerData:find("§j") == nil then
        return nil
    end
    local rotFunctionLayerNameString = layerData:sub(layerData:find("§j")+3, layerData:len())
    if rotFunctionLayerNameString == nil or rotFunctionLayerNameString == "" then
        app.alert("Error: no rotational layer function found.")
        return nil
    end
    rotFunctionLayerNameString = rotFunctionLayerNameString:sub(1, rotFunctionLayerNameString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == rotFunctionLayerNameString then
            return layer
        end
    end
    return nil
end

function extractPathLayersFromLayerConf(layerData)
    if layerData:find("«") == nil then
        return {} -- we return an empty vector
    end
    local pathLayersNames = {}
    local layerDataString = layerData:sub(1, layerData:len())
    local safetyCounter = 200
    while safetyCounter > 0 do
        local pathName = layerDataString:sub(1, layerDataString:find("«")-1)
        table.insert(pathLayersNames, pathName)
        layerDataString = layerDataString:sub(layerDataString:find("«")+2, layerDataString:len())
        if layerDataString:find("«") == nil  then
            break
        end
        safetyCounter = safetyCounter - 1
    end
    if safetyCounter <= 0 then
        app.alert("Error: extractPathLayersFromLayerConf() function.")
        return nil
    end
    local layers = {}
    for i=1, #pathLayersNames, 1 do
        for j,layer in ipairs(app.activeSprite.layers) do
            if layer.name == pathLayersNames[i] then
                table.insert(layers, layer)
                break
            end
        end
    end
    return layers
end

function extractLookAtLayerFromLayerConf(confString)
    if confString:find("§o") == nil then
        return nil
    end
    local lookAtLayerString = confString:sub(confString:find("§o")+3, confString:len())
    if lookAtLayerString == nil or lookAtLayerString == "" then
        app.alert("Error: no LOOK AT LAYER was found")
        return nil
    end
    lookAtLayerString = lookAtLayerString:sub(1, lookAtLayerString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == lookAtLayerString then
            return layer
        end
    end
    return nil
end

function readConfigurationFromSelectedLayers(selectedLayers)
    local startPathLayer = nil -- whit white dot
    local lookAtLayer = nil
    local pathLayerCollection = {}
    local drawingLayerCollection = {}
    for i, layer in ipairs(selectedLayers) do
        if layer.name:find(STRING_PATH_LAYER) ~= nil  then
            table.insert(pathLayerCollection, layer)
        elseif layer.name:find(STRING_FUNCTION_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_RESULT_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_ROTAUX_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_ROTATION_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_LOOKED_LAYER) ~= nil then
            lookAtLayer = layer
        else
            if #layer.cels ~= 0 then
                table.insert(drawingLayerCollection, layer)
            end
        end
    end
    if #pathLayerCollection == 0 and lookAtLayer == nil then
        return nil
    end

    local resultLayerIdString = generateLayerIDString(pathLayerCollection , drawingLayerCollection)
    if resultLayerIdString == nil then
        return nil
    end
    local resultLayer = nil
    for i=#app.activeSprite.layers, 1, -1 do
        if app.activeSprite.layers[i].data == resultLayerIdString then
            resultLayer = app.activeSprite.layers[i]
            break
        end
    end
    if resultLayer == nil then
        return nil
    end
    return resultLayer.cels[1].data
end

function extractStatTimeFromConf(configurationString)
    if configurationString:find("§s") == nil then
        return DEFAULT_STARTTIME_STRING
    end
    local startTimeString = configurationString:sub(configurationString:find("§s")+3, configurationString:len())
    if startTimeString == nil or startTimeString == "" then
        return DEFAULT_STARTTIME_STRING
    else
        return startTimeString:sub(1, startTimeString:find("§")-1)
    end
end

function extractDurationFromConf(configurationString)
    if configurationString:find("§t") == nil then
        return DEFAULT_DURATION_STRING
    end
    local durationString = configurationString:sub(configurationString:find("§t")+3, configurationString:len())
    if durationString == nil or durationString == "" then
        return DEFAULT_DURATION_STRING
    else
        return durationString:sub(1, durationString:find("§")-1)
    end
end

function extractTranslationFunctionFromConf(configurationString)
    if configurationString:find("§f") == nil then
        return FUNC_LINEAL
    end
    local translationFunctionString = configurationString:sub(configurationString:find("§f")+3, configurationString:len())
    if translationFunctionString == nil or translationFunctionString == "" then
        return FUNC_LINEAL
    else
        return translationFunctionString:sub(1, translationFunctionString:find("§")-1)
    end
end

function extractRotationTypeFromConf(configurationString)
    if configurationString:find("§r") == nil then
        return ROTATION_NONE
    end
    local rotationTypeString = configurationString:sub(configurationString:find("§r")+3, configurationString:len())
    if rotationTypeString == nil or rotationTypeString == "" then
        return ROTATION_NONE
    else
        return rotationTypeString:sub(1, rotationTypeString:find("§")-1)
    end
end

function extractInitialAngleFromConf(configurationString)
    if configurationString:find("§a") == nil then
        return DEFAULT_INITIALANGLE_STRING
    end
    local initialAngleString = configurationString:sub(configurationString:find("§a")+3, configurationString:len())
    if initialAngleString == nil or initialAngleString == "" then
        return DEFAULT_INITIALANGLE_STRING
    else
        return initialAngleString:sub(1, initialAngleString:find("§")-1)
    end
end

function extractLoopPathFromConf(configurationString)
    if configurationString:find("§l") == nil then
        return DEFAULT_LOOP_PATH
    end
    local loopPath = configurationString:sub(configurationString:find("§l")+3, configurationString:len())
    if loopPath == nil or loopPath == "" then
        return DEFAULT_LOOP_PATH
    else
        if loopPath:sub(1, loopPath:find("§")-1) == "true" then
            return true
        else
            return false
        end
    end
end

function extractScaleFunctionFromConf(configurationString)
    if configurationString:find("§h") == nil then
        return SCALE_NONE
    end
    local scaleFunctionString = configurationString:sub(configurationString:find("§h")+3, configurationString:len())
    if scaleFunctionString == nil or scaleFunctionString == "" then
        return SCALE_NONE
    else
        return scaleFunctionString:sub(1, scaleFunctionString:find("§")-1)
    end
end

function extractScaleFunLayerFromConf(configurationString)
    if configurationString:find("§k") == nil then
        return nil
    end
    local scaleFunctionLayerNameString = configurationString:sub(configurationString:find("§k")+3, configurationString:len())
    if scaleFunctionLayerNameString == nil or scaleFunctionLayerNameString == "" then
        app.alert("Error: no scale layer function found.")
        return nil
    end
    scaleFunctionLayerNameString = scaleFunctionLayerNameString:sub(1, scaleFunctionLayerNameString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == scaleFunctionLayerNameString then
            return layer
        end
    end
    return nil
end

function extractInitialScaleFromConf(configurationString)
    if configurationString:find("§i") == nil then
        return DEFAULT_INITIAL_SCALE
    end
    local initialScale = configurationString:sub(configurationString:find("§i")+3, configurationString:len())
    if initialScale == nil or initialScale == "" then
        return DEFAULT_INITIAL_SCALE
    else
        local perCentScale = initialScale:sub(1, initialScale:find("§")-1)
        return perCentScale / 100.0
    end
end

function extractFinalScaleFromConf(configurationString)
    if configurationString:find("§c") == nil then
        return DEFAULT_FINAL_SCALE
    end
    local finalScale = configurationString:sub(configurationString:find("§c")+3, configurationString:len())
    if finalScale == nil or finalScale == "" then
        return DEFAULT_FINAL_SCALE
    else
        local perCentScale = finalScale:sub(1, finalScale:find("§")-1)
        return perCentScale / 100.0
    end
end

function extractStartPathPosFromConf(configurationString)
    if configurationString:find("§p") == nil then
        return DEFAULT_PATH_START_POS_STRING
    end
    local startPathPos = configurationString:sub(configurationString:find("§p")+3, configurationString:len())
    if startPathPos == nil or startPathPos == "" then
        return DEFAULT_PATH_START_POS_STRING
    else
        return startPathPos:sub(1, startPathPos:find("§")-1)
    end
end

function extractMakeNewResultLayerFromConf(configurationString)
    if configurationString:find("§n") == nil then
        return DEFAULT_MAKE_NEW_RESULT_LAYER
    end
    local makeNewResultLayer = configurationString:sub(configurationString:find("§n")+3, configurationString:len())
    if makeNewResultLayer == nil or makeNewResultLayer == "" then
        return DEFAULT_MAKE_NEW_RESULT_LAYER
    else
        if makeNewResultLayer:sub(1, makeNewResultLayer:find("§")-1) == "true" then
            return true
        else
            return false
        end
    end
end

EXPAND = 1

function Rotar(image2Rot, angle)
  -- angle is in radians
  local maskColor = image2Rot.spec.transparentColor
  local maxSize = math.floor(image2Rot.width * 1.416)
  if math.floor(image2Rot.height * 1.416) > maxSize then
    maxSize = math.floor(image2Rot.height * 1.416)
  end
  if maxSize%2 == 1 then
    maxSize = maxSize + 1
  end
  -- maxSize is a even number
  local centeredImage = Image(maxSize, maxSize, image2Rot.colorMode)
  -- center image2Rot in the new image 'centeredImage'
  local image2RotPosition = Point((centeredImage.width - image2Rot.width) / 2, (centeredImage.height - image2Rot.height) / 2)
  for y=image2RotPosition.y, image2RotPosition.y + image2Rot.height - 1, 1 do
    for x=image2RotPosition.x, image2RotPosition.x + image2Rot.width - 1, 1 do
      centeredImage:drawPixel(x, y, image2Rot:getPixel(x - image2RotPosition.x, y - image2RotPosition.y))
    end
  end

  local pivot = Point(centeredImage.width / 2 - 0.5 + (image2Rot.width % 2) * 0.5, centeredImage.height / 2 - 0.5 + (image2Rot.height % 2) * 0.5)
  local outputImg = Image(centeredImage.width, centeredImage.height, image2Rot.colorMode)

  if angle == 0 then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(x, y)
        -- local px = centeredImage:getPixel(x, y)
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi / 2 then
    -- print("angle == math.pi / 2")
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(centeredImage.width - 1 - y, x)
        -- if x >= centeredImage.width /2 -1 and x < centeredImage.width /2 and y == 5 then
        --   print(string.format("Px got from %d, %d  :  and draw on %d, %d  :  px = %x", centeredImage.width - 1 - y, x, x, y, px))
        -- end
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi * 3 / 2 then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(y, centeredImage.height - 1 - x)
        -- local px = centeredImage:getPixel(x, y)
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(centeredImage.width - 1 - x, centeredImage.height - 1 - y)
        outputImg:drawPixel(x, y, px)
      end
    end
  else
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local oposite = pivot.x - x
        local adyacent = pivot.y - y
        local hypo = math.sqrt(oposite^2 + adyacent^2)
        if hypo == 0.0 then
          local px = centeredImage:getPixel(x, y)
          outputImg:drawPixel(x, y, px)
        else
          local currentAngle = math.asin(oposite / hypo)
          local resultAngle
          local u
          local v
          if adyacent < 0 then
            resultAngle = currentAngle + angle
            v = - hypo * math.cos(resultAngle)
          else
            resultAngle = currentAngle - angle
            v = hypo * math.cos(resultAngle)
          end
          u = hypo * math.sin(resultAngle)
          if centeredImage.width / 2 - u >= 0 and
            centeredImage.height / 2 - v >= 0 and
            centeredImage.height / 2 - v < centeredImage.height and
            centeredImage.width / 2 - u < centeredImage.width then
            local px = centeredImage:getPixel(centeredImage.width / 2 - u, centeredImage.height / 2 - v)
            if px ~= maskColor then
              outputImg:drawPixel(x, y, px)
            end
          end
        end
      end
    end
  end
  return outputImg
end

function resizeImage(image, expandK)
  local currentSprite = app.activeSprite
  local newSpr = Sprite(image.width, image.height)
  local cel = newSpr.layers[1]:cel(1)
  cel.image = image:clone()
  app.activeSprite = newSpr
  app.command.SpriteSize{
    ui=false,
    scale=expandK,
    method="nearest"
  }
  app.activeSprite = currentSprite
  local resizedImage = newSpr.layers[1]:cel(1).image:clone()
  newSpr:close()
  return resizedImage
end

function makeRotationLayerReference(layer, image, deltaDegrees)
  -- clean the cels
  for i=1, #layer.cels, 1 do
    app.activeSprite:deleteCel(layer, i)
  end
  local expandedRefImg
  if EXPAND == 1 then
    expandedRefImg = image:clone()
  else
    expandedRefImg = resizeImage(image, EXPAND)
  end
  local k = 1
  local progressSprite = nil
  for i=0, 360-deltaDegrees, deltaDegrees do
    local expandedImage = Rotar(expandedRefImg, i * math.pi / 180)
    if EXPAND == 1 then
      app.activeSprite:newCel(layer, k, expandedImage, Point(0 , 0))
    else
      app.activeSprite:newCel(layer, k, resizeImage(expandedImage, 1.0 / EXPAND, Point(0, 0)))
    end
    k = k+1
  end
  app.activeCel = layer:cel(1)
  app.useTool { tool="pencil",
                color = Color{r=255, g=255, b=255, a=255},
                points = { Point(0, 0) }
              }
  app.useTool { tool="eraser",
                points = { Point(0, 0) }
              }
end

function extractCelRotated(rotauxLayer, angle, deltaAngleCount)
  if rotauxLayer == nil then
    app.alert(string.format("Internal error: no %s layer found as first argument of 'extractImageRotated()' function in 'rotation.lua'.", STRING_ROTAUX_LAYER))
    return nil
  end
  local deltaAngle = 2 * math.pi / deltaAngleCount
  local celIndex = 1 + (math.floor(angle / deltaAngle) % deltaAngleCount)
  if rotauxLayer:cel(celIndex) == nil then
    app.alert(string.format("Internal error: no cel index %d found in 'extractImageRotated()' function in 'rotation.lua'.", celIndex))
    return nil
  end
  return rotauxLayer:cel(celIndex)
end

function resizeImage(image, scaleFactor)
 local currentSprite = app.activeSprite
 local newSpr = Sprite(image.width, image.height)
 local cel = newSpr.layers[1]:cel(1)
 cel.image = image:clone()
 app.activeSprite = newSpr
 app.command.SpriteSize{
   ui=false,
   scale=scaleFactor,
   method="nearest"
 }
 app.activeSprite = currentSprite
 local resizedImage = newSpr.layers[1]:cel(1).image:clone()
 newSpr:close()
 return resizedImage
end

scaledCurve = nil
function applyScaleFunction(currentFrame, framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale)
  local currentFrameN = (currentFrame - 1) / (framesCountToFill - 1)
  local funcValue
  local deltaScale = finalScale - initialScale
  if scaleFunction == SCALE_SINUSOIDAL then
    funcValue = sinusoidal(currentFrameN)
  elseif scaleFunction == SCALE_PARABOLIC then
    funcValue = parabolic(currentFrameN)
  elseif scaleFunction == SCALE_EASYOUTDAMPED then
    funcValue = easyOutDamped(currentFrameN)
  elseif scaleFunction == SCALE_EASYOUTDAMPED2 then
    funcValue = easyOutDamped2(currentFrameN)
  elseif scaleFunction == SCALE_EASYINOUT then
    funcValue = easyInOut(currentFrameN)
  elseif scaleFunction == SCALE_EASYIN then
    funcValue = easyIn(currentFrameN)
  elseif scaleFunction == SCALE_EASYOUT then
    funcValue = easyOut(currentFrameN)
  elseif scaleFunction == SCALE_BYLAYER then
    if scaleFunLayer == nil then
      app.alert(string.format("Error: on function timeNToIndex(), in 'scale_ops.lua'. Neither selected layer contains '%s' in its name.", STRING_SCALE_LAYER))
      return nil
    end
    if scaledCurve == nil then
     scaledCurve = makeCurveFromLayer(scaleFunLayer, false)
    end
    funcValue = byLayer(currentFrameN, scaledCurve)
  else
    funcValue = lineal(currentFrameN)
  end
  return funcValue * deltaScale + initialScale
end

function makeScaleVector(framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale)
 local scaleVector = {}
 for i=1, framesCountToFill, 1 do
  table.insert(scaleVector, applyScaleFunction(i, framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale))
 end
 return scaleVector
end

explorationVector = { Point( 1, -1),
                      Point( 1,  0),
                      Point( 1,  1),
                      Point( 0,  1),
                      Point(-1,  1),
                      Point(-1,  0),
                      Point(-1, -1),
                      Point( 0, -1) }

-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================

function findWhiteDot(celToExplore, palette)
-- Encontrar el punto inicial (blanco)
  if celToExplore == nil then
    app.alert("Internal error: the input argument celToExplore is 'nil' on function findWhiteDot(), in path_finder.lua.")
    return nil
  end
  local imageToExplore = celToExplore.image
  local w = imageToExplore.width
  local h = imageToExplore.height
  local startPixel = nil

  local whiteColor = 0xFFFFFFFF
  if celToExplore.image.colorMode == ColorMode.GRAY then
    whiteColor = 0xFF
  elseif celToExplore.image.colorMode == ColorMode.INDEXED then
    for i=0, #palette - 1, 1 do
      if palette:getColor(i).rgbaPixel == whiteColor then
          whiteColor = i
        break
      end
    end
  end

  for y=0, h-1, 1 do
    for x=0, w-1, 1 do
        local px = imageToExplore:getPixel(x, y)
        if px == whiteColor then
          startPixel = Point(celToExplore.position.x + x, celToExplore.position.y + y)
          break
        end
    end
  end
  return startPixel
end
-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================
function isEnd(pathImage, x, y)
  local pxFounded = 0
  local maskColor = app.activeSprite.spec.transparentColor
  for i,point in ipairs(explorationVector) do
    if x + point.x >= 0 and
       y + point.y >= 0 and
       x + point.x < pathImage.width and
       y + point.y < pathImage.height  then
      if pathImage:getPixel(x + point.x, y + point.y) ~= maskColor and
         pathImage:getPixel(x + point.x, y + point.y) ~= MASK_COLOR2 then
        pxFounded = pxFounded + 1
      end
    end
  end
  -- If pxFounded == 0 implies we found an isolated pixel
  -- If pxFounded == 1 implies we found an stroke end
  if pxFounded <= 1 then
    return Point(x, y)
  end
  return nil
end
-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================
function findEndDots(celToExplore)
-- Encontrar el punto inicial (blanco)
  local maskColor = app.activeSprite.spec.transparentColor
  local endDots = {}
  local imageToExplore = celToExplore.image
  local w = imageToExplore.width
  local h = imageToExplore.height
  for y=0, h-1, 1 do
    for x=0, w-1, 1 do
      local point = nil
      if imageToExplore:getPixel(x, y) ~= maskColor and
         imageToExplore:getPixel(x, y) ~= MASK_COLOR2 then
        point = isEnd(imageToExplore, x, y)
        if point ~= nil then
          table.insert(endDots, point + celToExplore.position)
          if #endDots > 2 then
            return nil
          end
        end
      end
    end
  end
  if #endDots > 0 and #endDots <= 2 then
    return endDots
  else
    return nil
  end
end

function nextPathPoint(pathLayer, currentPoint, previousPoint)
  local maskColor = app.activeSprite.spec.transparentColor
  local pathImage = pathLayer.cels[1].image
  local imagePosition = pathLayer.cels[1].position
  currentPoint = currentPoint - imagePosition
  if previousPoint ~= nil then
    previousPoint = previousPoint - imagePosition
  end
  local pxFounded = 0
  local nextPoint = nil
  for i,point in ipairs(explorationVector) do
    if (currentPoint.x + point.x) >= 0 and
       (currentPoint.y + point.y) >= 0 and
       (currentPoint.x + point.x) < pathImage.width and
       (currentPoint.y + point.y) < pathImage.height then
      if previousPoint ~= nil then
        if previousPoint.x == (currentPoint.x + point.x) and
           previousPoint.y == (currentPoint.y + point.y) then
          -- do nothing
        else
          if pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= maskColor and
             pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= MASK_COLOR2 then
            return Point(currentPoint.x + point.x, currentPoint.y + point.y) + imagePosition
          end
        end
      else
        if pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= maskColor and
           pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= MASK_COLOR2 then
          return Point(currentPoint.x + point.x, currentPoint.y + point.y) + imagePosition
        end
      end
    end
  end
  return nil
end
-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================

function getPath(pathLayer, palette)
  local startPixel = findWhiteDot(pathLayer.cels[1], palette)
  if startPixel == nil then
    local endDots = findEndDots(pathLayer.cels[1])
    if endDots == nil then
      return nil
    end
    startPixel = endDots[1]
    if #endDots == 1 then
      return {startPixel}
    end
  end

  local image = pathLayer.cels[1].image
  local maxRepetitions = image.width * image.height
  local nextPoint = nil
  local previousPoint = nil
  local outputPath = { startPixel }
  local j = 1
  while true do
    nextPoint = nextPathPoint(pathLayer, outputPath[j], previousPoint)
    if nextPoint ~= nil then
      table.insert(outputPath, nextPoint)
      previousPoint = outputPath[j]
      j = j + 1
    else
      -- we reach the end of the path
      break
    end
    if j > maxRepetitions then
      break
    end
  end
  return outputPath
end

function distance(point1, point2)
  return math.sqrt((point1.x - point2.x)^2 + (point1.y - point2.y)^2)
end

function isPosibleConcatenatePaths(path1, path2)
-- returns 0 if the paths are no compatible to each other (all ends are too far to connect each other)
-- returns 1 if path1 can follow path2
-- returns 2 if path1 can follow reversed path2
-- returns 3 if reversed path1 can follow path2
-- returns 4 if reversed path1 can follow reversed path2
-- returns nil if any path is no valid
  if #path1 < 2 or #path2 < 2 then
    return nil
  end
  local path1End1 = path1[1]
  local path1End2 = path1[#path1]
  local path2End1 = path2[1]
  local path2End2 = path2[#path2]

  local d1 = distance(path1[1],      path2[1])      -- 
  local d2 = distance(path1[1],      path2[#path2]) -- 
  local d3 = distance(path1[#path1], path2[1])      --
  local d4 = distance(path1[#path1], path2[#path2]) --
  
  if d3 < 2 then
    return 1
  elseif d4 < 2 then
    return 2
  elseif d1 < 2 then
    return 3
  elseif d2 < 2 then
    return 4
  else
    return 0
  end
  
end

function concatenatePaths(path1, path2, concatType)
  local tempPath1 = {}
  if concatType == 2 then
    -- reversePath2 = true
    for i=#path2, 1, -1 do
      table.insert(path1, path2[i])
    end
    return path1
  elseif concatType == 3 then
    local tempPath1 = {}
    -- reversePath1 = true
    for i=#path1, 1, -1 do
      table.insert(tempPath1, path1[i])
    end
    for i=1, #path2, 1 do
      table.insert(tempPath1, path2[i])
    end
    return tempPath1
  elseif concatType == 4 then
    -- reversePath1 = true
    -- reversePath2 = true
    local tempPath1 = {}
    reversePath1 = true
    for i=#path1, 1, -1 do
      table.insert(tempPath1, path1[i])
    end
    for i=#path2, 1, -1 do
      table.insert(tempPath1, path2[i])
    end
    return tempPath1
  else
    if concatType ~= 1 then
      return nil
    end
    for i=1, #path2, 1 do
      table.insert(path1, path2[i])
    end
    return path1
  end
end

curve = nil
function timeNToIndex(timeN, timeVectorN, translationFunction, translationLayer)
  local funcValue
  if translationFunction == FUNC_SINUSOIDAL then
    funcValue = sinusoidal(timeN)
  elseif translationFunction == FUNC_PARABOLIC then
    funcValue = parabolic(timeN)
  elseif translationFunction == FUNC_EASYOUTDAMPED then
    funcValue = easyOutDamped(timeN)
  elseif translationFunction == FUNC_EASYOUTDAMPED2 then
    funcValue = easyOutDamped2(timeN)
  elseif translationFunction == FUNC_EASYINOUT then
    funcValue = easyInOut(timeN)
  elseif translationFunction == FUNC_EASYIN then
    funcValue = easyIn(timeN)
  elseif translationFunction == FUNC_EASYOUT then
    funcValue = easyOut(timeN)
  elseif translationFunction == FUNC_BYLAYER then
    if translationLayer == nil then
      app.alert(string.format("Error: on function timeNToIndex(), in 'path_finder.lua'. Neither selected layer contains '%s' in its name.", STRING_FUNCTION_LAYER))
      return nil
    end
    if curve == nil then
      curve = makeCurveFromLayer(translationLayer, false)
    end
    funcValue = byLayer(timeN, curve)
  else
    funcValue = lineal(timeN)
  end
  for i=1, #timeVectorN, 1 do
      if funcValue <= timeVectorN[i] then
        return i
      end
  end
end

function angleCalculation(point0, point1, codeRefNumber)
  if point0 == nil or point1 == nil then
    app.alert(string.format("Error: on angleCalculation() in 'path_finder.lua'. Error number: %d", codeRefNumber))
    return nil
  end
  local angle = nil
  local oposite = point1.x - point0.x
  local adyacent = point1.y - point0.y
  local hipo = math.sqrt(oposite^2 + adyacent^2)
  if hipo == 0 then
    angle = 0
  else
    if adyacent == 0 then
      if oposite > 0 then
        angle = 3 * math.pi / 2
      else
        angle = math.pi / 2
      end
    elseif adyacent > 0 then
      angle = math.pi + math.asin(oposite / hipo)
    else
      if oposite >= 0 then
        angle = 2 * math.pi - math.asin(oposite / hipo)
      else
        angle = -math.asin(oposite / hipo)
      end
    end
  end
  return angle
end

function conformPathTimedIndices(timeVectorN, frameCount, translationFun, translationLayer, C)
  local pathVectorIndices = {}
  for i=1, frameCount, 1 do
    local timeN = (i - 1.0) / (frameCount - 1.0)
    table.insert(pathVectorIndices, math.floor(timeNToIndex(timeN, timeVectorN, translationFun, translationLayer)) + C)
  end
  return pathVectorIndices
end

function makeRotationInstructionVector(pathVectorExtended, timeVectorN, framesCountToFill, rotationType, translationFun, translationLayer, rotFunLayer, lookAtLayer, C, startingFrame, initialAngle)  
  local outputRotationInstructionVector = {}
  local pathVectorIndices = conformPathTimedIndices(timeVectorN, framesCountToFill, translationFun, translationLayer, C)

  if rotationType == ROTATION_PATH then
    for i=1, #pathVectorIndices, 1 do
      table.insert(outputRotationInstructionVector, angleCalculation(pathVectorExtended[pathVectorIndices[i]-C], pathVectorExtended[pathVectorIndices[i]+C], 1) + initialAngle)
    end
  elseif rotationType == ROTATION_BYLAYER then
    if rotFunLayer == nil then
      app.alert(string.format("Error: no  layer which contains '%s' was selected. So 'BY LAYER' rotation type is not possible.", STRING_ROTATION_LAYER))
      return nil
    end
    if #rotFunLayer.cels == 0 or rotFunLayer.cels[1].image == nil then
      app.alert(string.format("Error: layer named '%s' doesn't contains an image.", rotFunLayer.name))
      return nil
    end
    -- Make angle according rotation function layer:
    local rotCurve = makeCurveFromLayer(rotFunLayer, true)
    for i=1, #pathVectorIndices, 1 do
      local timeFraction = (i - 1 ) / (#pathVectorIndices - 1)
      table.insert(outputRotationInstructionVector, rotCurve[math.floor(timeFraction * (#rotCurve - 1) + 1)] + initialAngle)
    end
  elseif rotationType == ROTATION_LOOKAT then
    if lookAtLayer == nil then
      app.alert(string.format("Error: no  layer named '%s' was selected. So 'LOOK AT' rotation type is not possible.", STRING_LOOKED_LAYER))
      return nil
    end
    if #lookAtLayer.cels == 0 or lookAtLayer.cels[1].image == nil then
      app.alert(string.format("Error: layer named '%s' doesn't contains an image. Please, at least, make an image first", lookAtLayer.name))
      return nil
    end
    if #lookAtLayer.cels == 1 then
      -- look all the time to an image on tahat unique cel
      local imageCenterPoint = Point(math.floor(lookAtLayer.cels[1].image.width / 2), math.floor(lookAtLayer.cels[1].image.height / 2))
      local pointToBeLookedAt = lookAtLayer.cels[1].position + imageCenterPoint
      for i=1, #pathVectorIndices, 1 do
        table.insert(outputRotationInstructionVector, angleCalculation(pathVectorExtended[pathVectorIndices[i]], pointToBeLookedAt, 2) + initialAngle)
      end
    elseif #lookAtLayer.cels > 1 then
      -- 'look at' angle es computed only on filled cels, otherwise angle is 0.
      for i=1, #pathVectorIndices, 1 do
        if lookAtLayer:cel(startingFrame - 1 + i) == nil then
          table.insert(outputRotationInstructionVector, initialAngle)
        else
          local imageCenterPoint = Point(math.floor(lookAtLayer:cel(startingFrame - 1 + i).image.width / 2), math.floor(lookAtLayer:cel(startingFrame - 1 + i).image.height / 2))
          local pointToBeLookedAt = lookAtLayer:cel(startingFrame - 1 + i).position + imageCenterPoint
          table.insert(outputRotationInstructionVector, angleCalculation(pathVectorExtended[pathVectorIndices[i]], pointToBeLookedAt, 3) + initialAngle)
        end
      end
    end

  end
  
  if outputRotationInstructionVector == nil or #outputRotationInstructionVector == 0 then
    app.alert("Something was wrong on 'makeRotationInstructionVector' function.")
    return nil
  end

  return outputRotationInstructionVector
end

function makePath(pathVectorExtended, timeVectorN, frameCount, translationFun, translationLayer, C)
  local outputCoordinatesVector = {}
  local pathVectorIndices = conformPathTimedIndices(timeVectorN, frameCount, translationFun, translationLayer, C)

  for i=1, #pathVectorIndices, 1 do
    table.insert(outputCoordinatesVector, pathVectorExtended[pathVectorIndices[i]])
  end

  if outputCoordinatesVector == nil or #outputCoordinatesVector == 0 then
    app.alert("Something is going wrong.")
    return nil
  end

  return outputCoordinatesVector
end

function areDifferentImages(image1, image2)
  if image1.width ~= image2.width or image1.height ~= image2.height then
    return true
  end
  for y=0, image1.height - 1, 1 do
    for x=0, image1.width - 1, 1 do
      if image1:getPixel(x, y) ~= image2:getPixel(x, y) then
        return true
      end
    end
  end
  return false
end

function orderDrawingLayerCollectionAccordingStackIndex(layers)
  local layersCopy = {}
  for i,layer in ipairs(layers) do
    table.insert(layersCopy, layer)
  end
  local orderedLayerVector = {}
  local layerWithGreaterStackIndex = nil
  local minStackIndexFound = 1000000
  for i=1, #layersCopy, 1 do
    local removeElement = 0
    for j=1, #layersCopy, 1 do
      if minStackIndexFound > layersCopy[j].stackIndex then
        minStackIndexFound = layersCopy[j].stackIndex
        layerWithGreaterStackIndex = layersCopy[j]
        removeElement = j
      end
    end
    table.insert(orderedLayerVector, layerWithGreaterStackIndex)
    if removeElement ~= 0 then
      table.remove(layersCopy, removeElement)
    end
    minStackIndexFound = 1000000
  end
  return orderedLayerVector
end


function animateIt(selectedLayers, startTime, aniDuration, translationFunction,
                   rotationType, initialAngle, startPathPos, loopPath,
                   scaleFunction, initialScale, finalScale, makeNewResultLayer,
                   palette)
  app.transaction(
    function()
      ------------------------------------------------------------------------------------------------------
      --1 Capture resultLayerCollection and rotationAuxLayerCollection from app.activeSprit
      ------------------------------------------------------------------------------------------------------
      local sprite = app.activeSprite

      if sprite == nil then
        app.alert("Error: You should open a sprite first.")
        return false
      end

      local resultLayerCollection = {}
      local rotationAuxLayerCollection = {}
      for i, layer in ipairs(sprite.layers) do
        if layer.name:find(STRING_ROTAUX_LAYER) ~= nil then
          table.insert(rotationAuxLayerCollection, layer)
        end
      end
      for i=#app.activeSprite.layers, 1, -1 do
        if app.activeSprite.layers[i].name:find(STRING_RESULT_LAYER) ~= nil then
          table.insert(resultLayerCollection, app.activeSprite.layers[i])
        end
      end
      -- print("1-DONE")
      ------------------------------------------------------------------------------------------------------
      --2 Make layer collections with selectedLayers
      ------------------------------------------------------------------------------------------------------
      local startPathLayer = nil -- with a white dot
      local pathLayerCollection = {}
      local pathCollection = {} -- layers with strokes without white dot
      local trasFunLayer = nil
      local rotFunLayer = nil
      local scaleFunLayer = nil
      local lookAtLayer = nil
      local drawingLayerCollection = {}
      local resultLayer = nil
      -- If oneResultLayerWasSelected == true means that this 'animateIt' function was used to re-animate a particular 'resultLayer'

      local oneResultLayerWasSelected = (#selectedLayers == 1 and selectedLayers[1].name:find(STRING_RESULT_LAYER) ~= nil)
      if oneResultLayerWasSelected then
        resultLayer = selectedLayers[1]
        -- ignore all configurations and use the ResultLayer configuration
        local confString = readConfigurationFromLayer(resultLayer)
        makeNewResultLayer = false
        if confString ~= nil then
          startTime = extractStatTimeFromConf(confString)
          aniDuration = extractDurationFromConf(confString)
          translationFunction = extractTranslationFunctionFromConf(confString)
          rotationType = extractRotationTypeFromConf(confString)
          initialAngle = extractInitialAngleFromConf(confString)
          startPathPos = extractStartPathPosFromConf(confString)
          loopPath = extractLoopPathFromConf(confString)
          scaleFunction = extractScaleFunctionFromConf(confString)
          initialScale = extractInitialScaleFromConf(confString)
          finalScale = extractFinalScaleFromConf(confString)
        end
        if rotationType == ROTATION_BYLAYER then
          rotFunLayer = extractRotFunLayerFromLayerConf(confString)
          if rotFunLayer == nil then
            app.alert(string.format("Rotational Function not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end
        drawingLayerCollection = extractDrawingLayersFromLayerConf(resultLayer.data)
        if #drawingLayerCollection == 0 then
          app.alert("Error: no drawing layers are found on ResultLayer configuration.")
          return false
        end
        if translationFunction == FUNC_BYLAYER then
          trasFunLayer = extractTranslationFunLayerFromLayerConf(confString)
          if trasFunLayer == nil then
            app.alert(string.format("Translation Function not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end
        if scaleFunction == SCALE_BYLAYER then
          scaleFunLayer = extractScaleFunLayerFromConf(confString)
          if scaleFunLayer == nil then
            app.alert(string.format("Scale Function not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end
        if rotationType == ROTATION_LOOKAT then
          lookAtLayer = extractLookAtLayerFromLayerConf(confString)
          if lookAtLayer == nil then
            app.alert(string.format("Look At Layer not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end

        pathLayerCollection = extractPathLayersFromLayerConf(resultLayer.data)
        if #pathLayerCollection == 0 then
          if rotationType ~= ROTATION_LOOKAT and rotationType ~= ROTATION_BYLAYER then
            app.alert(string.format("Path layer not found from configuration (config is in the custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        else
          if findWhiteDot(pathLayerCollection[1].cels[1], palette) ~= nil then
            startPathLayer = pathLayerCollection[1]
          end
        end
      else
        for i, layer in ipairs(selectedLayers) do
          if layer.name:find(STRING_PATH_LAYER) ~= nil  then
            if startPathLayer == nil then
              local startPoint = findWhiteDot(layer.cels[1], palette)
              if startPoint ~= nil then
                startPathLayer = layer
                table.insert(pathLayerCollection, 1, layer) -- startPathLayer is the first element
              else
                table.insert(pathLayerCollection, layer)
              end
            else
              table.insert(pathLayerCollection, layer)
            end
          elseif layer.name:find(STRING_FUNCTION_LAYER) ~= nil then
            trasFunLayer = layer
          elseif layer.name:find(STRING_RESULT_LAYER) ~= nil then
            -- do nothing
          elseif layer.name:find(STRING_ROTAUX_LAYER) ~= nil then
            -- do nothing
          elseif layer.name:find(STRING_ROTATION_LAYER) ~= nil then
            rotFunLayer = layer
          elseif layer.name:find(STRING_SCALE_LAYER) ~= nil then
            scaleFunLayer = layer
          elseif layer.name:find(STRING_LOOKED_LAYER) ~= nil then
            lookAtLayer = layer
          else
            if #layer.cels ~= 0 then
              table.insert(drawingLayerCollection, layer)
            end
          end
        end
      end

      -- Dummy calculation to convert strings to numbers:
      initialAngle = initialAngle * 2 / 2
      initialScale = initialScale * 2 / 2
      finalScale = finalScale * 2 / 2
      aniDuration = aniDuration * 2 / 2
      startTime = startTime * 2 / 2

      local generateStillPath = false -- when the user selects NO PATH layer, AND the user selects "Rotation: LookAt" or "Rotation: By Layer"
                                      -- we have to generate a "still path" to allow apply this 
      -- local temp = 0 -- temp = 0  -->  whitePointIsInStartPathLayer = true
      if startPathLayer == nil then
        if #pathLayerCollection == 0 then
          if rotationType == ROTATION_LOOKAT or rotationType == ROTATION_BYLAYER then
            -- Here, we have NO PATH, but we can generate a path to allow an object to still in the same position along the rotation animation,
            -- So we can generate the angles in rotation types: 'Look At' or 'By Layer' rotation Functions
            generateStillPath = true
          else
            app.alert(string.format("Error: no layer which name contains '%s' or '%s' string.", STRING_PATH_LAYER, STRING_LOOKED_LAYER))
            app.alert(string.format("Please, select a layer which name contains '%s' or '%s' string, and at least an image layer.", STRING_PATH_LAYER, STRING_LOOKED_LAYER))
            return false
          end
        end
      end
      
      for i=1, #pathLayerCollection, 1 do
        local path = getPath(pathLayerCollection[i], palette)
        if path == nil then
          app.alert(string.format("Error: Bad path in layer: '%s'. No end points were found on it.", pathLayerCollection[i].name))
          app.alert(string.format("A well-formed path is made from a 1-pixel-thick stroke, with Pixel Perfect mode ON. Optional: put a white point at the desired beginning."))
          return false
        end
        table.insert(pathCollection, path)
      end
      -- print("2-DONE")
      ------------------------------------------------------------------------------------------------------
      --3 Add needed aditional frames to the sprite
      ------------------------------------------------------------------------------------------------------
      local frameDuration = sprite.frames[1].duration
      local startFrame = startTime / frameDuration + 1
      local framesCountToFill = aniDuration / frameDuration
      local neededFrameCount = startFrame + framesCountToFill - 1
      for i=#sprite.frames, neededFrameCount - 1, 1 do
        sprite:newEmptyFrame()
      end
      -- print("3-DONE")
      ------------------------------------------------------------------------------------------------------
      --4 Make an ID string to identify which ResultLayer in the active sprite was used to make the current animation
      ------------------------------------------------------------------------------------------------------
      local loopPathString
      local makeNewResultLayerString
      if loopPath == true then
        loopPathString = "true"
      else
        loopPathString = "false"
      end
      if makeNewResultLayer == true then
        makeNewResultLayerString = "true"
      else
        makeNewResultLayerString = "false"
      end

      local resultLayerIdString = generateLayerIDString(pathLayerCollection , drawingLayerCollection)
      local drawingLayersIdString = generateDrawingLayerIDString(drawingLayerCollection)

      -- print("4-DONE")
      ------------------------------------------------------------------------------------------------------
      --5 Find among resultLayerCollection if the previous ID string matchs with some ResultLayer, if not, make a new one
      ------------------------------------------------------------------------------------------------------
      if not oneResultLayerWasSelected then
        for i,layer in ipairs(resultLayerCollection) do
          if layer.data == resultLayerIdString and not makeNewResultLayer then
            resultLayer = layer
            break
          end
        end
        if resultLayer == nil then
          resultLayer = sprite:newLayer()
          resultLayer.name = STRING_RESULT_LAYER
          sprite:newCel(resultLayer, startFrame)
          resultLayer.data = resultLayerIdString
        end
      end
      -- print("5-DONE")
      ------------------------------------------------------------------------------------------------------
      --6 Make a new configuration string according the current input options. An example of configuration string = §f1§t2.0§s0.0§r0§a90.0§ltrue§p50.0§yTFUN1§
      ------------------------------------------------------------------------------------------------------
      local initialScalePerCent = initialScale * 100.0
      local finalScalePerCent = finalScale * 100.0
      local confString  = "§f" .. translationFunction .. "§" ..
                          "s" .. startTime .. "§" ..
                          "t" .. aniDuration .."§" ..
                          "r" .. rotationType .. "§" ..
                          "a" .. initialAngle .. "§" ..
                          "l" .. loopPathString .. "§" ..
                          "p" .. startPathPos .. "§" ..
                          "h" .. scaleFunction .. "§" ..
                          "i" .. initialScalePerCent .. "§" ..
                          "c" .. finalScalePerCent .. "§" ..
                          "n" .. makeNewResultLayerString .. "§"
      
      if scaleFunLayer ~= nil then
        confString = confString .. "k" .. scaleFunLayer.name .. "§"
      end
      if trasFunLayer ~= nil then
        confString = confString .. "y" .. trasFunLayer.name .. "§"
      end
      if rotFunLayer ~= nil then
        confString = confString .. "j" .. rotFunLayer.name .. "§"
      end
      if lookAtLayer ~= nil then
        confString = confString .. "o" .. lookAtLayer.name .. "§"
      end
      -- At the end of the current function, it'll asign the config string to ResultLayer
      -- print("6-DONE")
      ------------------------------------------------------------------------------------------------------
      --7 Make a flatten image, which be moved along the path.
      ------------------------------------------------------------------------------------------------------
      local layersToMergeDown = {}
      drawingLayerCollection = orderDrawingLayerCollectionAccordingStackIndex(drawingLayerCollection)

      local FRAME_LIMIT = 99999999
      local minFrame = FRAME_LIMIT
      local maxFrame = 1
      for i=1, #drawingLayerCollection, 1 do
        table.insert(layersToMergeDown, sprite:newLayer())
        for j=1, #app.activeSprite.frames, 1 do
          if drawingLayerCollection[i]:cel(j) ~= nil and j < minFrame then
            minFrame = j
            break
          end
        end
        for j=#app.activeSprite.frames, 1, -1 do
          if drawingLayerCollection[i]:cel(j) ~= nil and j > maxFrame then
            maxFrame = j
            break
          end
        end
      end

      if minframe == FRAME_LIMIT then
        app.alert("Error: the selected layers are empty. Please Select a layer with images.")
        return false
      end
      
      for i=1, #drawingLayerCollection, 1 do
        for j=minFrame, maxFrame, 1 do
          if drawingLayerCollection[i]:cel(j) ~= nil then
            local position = drawingLayerCollection[i]:cel(j).position
            local image = drawingLayerCollection[i]:cel(j).image
            local frame = drawingLayerCollection[i]:cel(j).frame
            sprite:newCel(layersToMergeDown[i], frame, image, position)
          end
        end
      end
      for i=1, #drawingLayerCollection-1, 1 do
        app.command.MergeDownLayer()
      end
      local auxLayer = app.activeLayer
      local imageToMove = auxLayer:cel(minFrame).image:clone()
      local imageToMovePos = auxLayer:cel(minFrame).position
      if imageToMove == nil then
        sprite:deleteLayer(auxLayer)
        app.alert("Error: selected image layers do not make an image.")
        return false
      end
      
      -- print("7-DONE")
      ------------------------------------------------------------------------------------------------------
      --8 Make a concatenated path with all the path layers selected (if possible to concatenate), named 'weldedPath'.
      ------------------------------------------------------------------------------------------------------
      local startPath = nil
      if generateStillPath then
        local imageCenterPoint = imageToMovePos + Point(imageToMove.width / 2, imageToMove.height / 2)
        startPath = { imageCenterPoint, imageCenterPoint }
      else
        startPath = getPath(pathLayerCollection[1], palette)
      end
      if startPath == nil then
        app.alert(string.format("Error: bad path in layer: '%s'. No end points were found on it.", pathLayerCollection[1].name))
        app.alert(string.format("A well-formed path is made from a 1-pixel-thick stroke, with Pixel Perfect mode ON. Optional: put a white point at the desired beginning."))
        sprite:deleteLayer(auxLayer)
        return false
      end
      local weldedPath = startPath -- original weldedPath
      -- Starting Paths Collection: has a white dot (the starting dot)
      for i=2, #pathCollection, 1 do
        local concatType = isPosibleConcatenatePaths(weldedPath, pathCollection[i])
        if concatType == 0 or concatType == nil  then
          app.alert(string.format("Error: Bad path trayectory in layer: '%s'", pathCollection[i].name))
          sprite:deleteLayer(auxLayer)
          return false
        end
        weldedPath = concatenatePaths(weldedPath, pathCollection[i], concatType)
      end

      if weldedPath == nil then
        app.alert("Error: error on concatenatePaths(). It returned 'nil'.")
        sprite:deleteLayer(auxLayer)
        return false
      end
      if #weldedPath < 1 then
        app.alert("Error: no path were formed.")
        sprite:deleteLayer(auxLayer)
        return false
      end
      -- print("8-DONE")
      ------------------------------------------------------------------------------------------------------
      --9 Make time vector, which is the representation of the time taken to walk the 'weldedPath' at constant speed of 1px/seg.
      ------------------------------------------------------------------------------------------------------
      -- timeVector (is a direct function of space distance between adyacent pixels):
      local timeVector = { 0 }
      if generateStillPath then
        table.insert(timeVector, 1)
      else
        -- weldPath == 1 if the path is a single pixel, so we'll need to avoid division by zero in next calculations
        if #weldedPath == 1 then
          timeVector[1] = 0
        else
          for i=1, #weldedPath-1, 1 do
            local deltaT = math.sqrt(math.abs(weldedPath[i].x - weldedPath[i+1].x) + math.abs(weldedPath[i].y - weldedPath[i+1].y) )
            table.insert(timeVector, timeVector[i] + deltaT)
          end
        end
      end
      -- Get the index which matches with
      -- the start percentage (Start Path Pos %)  -------------
      --                                                       |  
      --                                                   pathStartIndex
      -- original    weldedPath:      beginning |-----------------^-----------------------------* end
      --
      --
      -- OPTION 1:
      -- re-arranged weldedPath:  new beginning ^-----------------------------*|----------------- new end    when CYCLIC
      --                                                                      ^ 
      --                                                                pathJumpIndex
      --
      -- OPTION 2:
      -- re-arranged weldedPath:  new beginning ^-----------------------------* end                          when NON CYCLIC
      -- in this case 'pathJumpIndex' will be equal to the end index of 'weldedPath'  (i.e. pathJumpIndex = #weldedPath)
      --
      local totalTravelTime = timeVector[#timeVector]
      local pathStartIndex = 1
      for i=1, #timeVector, 1 do
        if timeVector[i]/totalTravelTime >= startPathPos / 100.0 then
          pathStartIndex = i
          break
        end
      end
      if pathStartIndex < 1 or pathStartIndex > #timeVector then
        app.alert("Error: 'pathStartIndex' is < 1 or 'pathStartIndex' > timeVector elements count.")
        sprite:deleteLayer(auxLayer)
        return false
      end

      -- weldedPath re-arrange:
      local auxVector = {}
      -- cyclic path loop:
      for i=pathStartIndex, #weldedPath, 1 do
        table.insert(auxVector, weldedPath[i])
      end
      if loopPath and #weldedPath > 1 then
        -- Non cyclic path loop
        for i=1, pathStartIndex-1, 1 do
          table.insert(auxVector, weldedPath[i])
        end
      end
      weldedPath = auxVector -- modified welded path

      local pathJumpIndex = 0
      if loopPath and #weldedPath > 1 then
        pathJumpIndex = #weldedPath - pathStartIndex + 1 -- index which path jumps from a middle point of the path to the beginning
      else
        pathJumpIndex = #weldedPath
      end

      -- Recalculate timeVector, we need to do it again because if the path is cyclic (loopPath == true) the time increment is not linear on 'pathJumpIndex'
      timeVector = { 0 }
      local deltaT
      if generateStillPath or #weldedPath == 1 then
        table.insert(timeVector, 1)
        pathJumpIndex = 2
        -- Conditioning weldedPath to match data input in next functions
        if #weldedPath == 1 then
          weldedPath = { weldedPath[1], weldedPath[1] }
        end
      else
        for i=1, #weldedPath-1, 1 do
          if i == pathJumpIndex then
            deltaT = 1
          else
            deltaT = math.sqrt(math.abs(weldedPath[i].x - weldedPath[i+1].x) + math.abs(weldedPath[i].y - weldedPath[i+1].y) )
          end
          table.insert(timeVector, timeVector[i] + deltaT)
        end
      end

      -- Get the normalized time vector ( i.e. from 0.0 to 1.0 )
      local timeVectorN = {}
      totalTravelTime = timeVector[#timeVector]
      for i=1, #timeVector, 1 do
        table.insert(timeVectorN, timeVector[i]/totalTravelTime)
      end

      local pathTrackingConstant = math.max(5, math.floor(imageToMove.height * K_PATH_TO_IMAGE_CONSTANT) - math.floor(imageToMove.height * K_PATH_TO_IMAGE_CONSTANT)%2 + 1)
        -- C is the step count to calculate the tangent slope on the path in the element pathVector[pathVectorIndices[i]]
        -- The weldedPath will be extended at both vector ends C elements to simplify iterations on
        -- 'makeRotationInstructionVector()' and 'makePath()' functions.
      local C = (pathTrackingConstant-1) / 2
      local weldedPathExtended = {}
      if #weldedPath-C >= 1 then
        for i=#weldedPath-C, #weldedPath, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[i])
          else
            table.insert(weldedPathExtended, weldedPath[1])
          end
        end
        for i=1, #weldedPath, 1 do
          table.insert(weldedPathExtended, weldedPath[i])
        end
        for i=1, C, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[i])
          else
            table.insert(weldedPathExtended, weldedPath[#weldedPath])
          end
        end
      else
        -- Very short paths (fill the weldedPath ends with dummy points):
        for i=1, C, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[#weldedPath])
          else
            table.insert(weldedPathExtended, weldedPath[1])
          end
        end
        for i=1, #weldedPath, 1 do
          table.insert(weldedPathExtended, weldedPath[i])
        end
        for i=1, C, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[1])
          else
            table.insert(weldedPathExtended, weldedPath[#weldedPath])
          end
        end
      end
      -- print("9-DONE")
      ------------------------------------------------------------------------------------------------------
      --10 Make rotation instruction vector. To do it first we need to check if some RotAux Layer exists an represents the imageToMove
      ------------------------------------------------------------------------------------------------------
      local rotauxLayer = nil
      local rotationInstructionVector = nil
      local deltaAngleCount = nil
      if rotationType ~= ROTATION_NONE and #auxLayer.cels == 1 then
        -- Check if some RotAux layer represents the imageToMove (the flatten image did at step 7):
        local recalculateRotations = false
        -- print("10.1-DONE")
        for i,layer in ipairs(rotationAuxLayerCollection) do
          if layer.data == drawingLayersIdString then
            if layer:cel(1) == nil then
              recalculateRotations = true
              break
            end
            rotauxLayer = layer
            recalculateRotations = areDifferentImages(rotauxLayer:cel(1).image, imageToMove)
            break
          end
        end
        -- print("10.2-DONE")
        if rotauxLayer == nil then
          rotauxLayer = sprite:newLayer()
          rotauxLayer.name = STRING_ROTAUX_LAYER
          rotauxLayer.data = drawingLayersIdString
          sprite:newCel(rotauxLayer, 1, imageToMove, Point(0, 0))
        end
        -- print("10.5-DONE")
        local deltaAngle = 2.8125 / 2
        deltaAngleCount = math.floor(360 / deltaAngle)
        if deltaAngleCount > #sprite.frames then
          for i=#sprite.frames, deltaAngleCount-1, 1 do
            sprite:newEmptyFrame()
          end
        end
        -- makeRotationLayerReference(rotauxLayer, imageToMove, deltaAngle)
        -- If 'recalculateRotations' == true , recalculate 'RotAux' layer to make each rotated image.
        if recalculateRotations then
          -- Clear all cels of rotauxLayer
          for i=1, #rotauxLayer.cels, 1 do
            if rotauxLayer.cels[i] ~= nil then
              sprite:deleteCel(rotauxLayer, rotauxLayer.cels[i].frameNumber)
            end
          end
          -- Make only the first frame in rotauxLayer:
          sprite:cel(rotauxLayer, 1, imageToMove, Point(0, 0))
        end
        -- print("10.7-DONE")
        rotationInstructionVector = makeRotationInstructionVector(weldedPathExtended,
                                                                  timeVectorN,
                                                                  framesCountToFill,
                                                                  rotationType,
                                                                  translationFunction,
                                                                  trasFunLayer,
                                                                  rotFunLayer,
                                                                  lookAtLayer,
                                                                  C,
                                                                  startFrame,
                                                                  initialAngle * math.pi / 180)
        if rotationInstructionVector == nil then
          return false
        end
        -- print("10.8-DONE")
        local deltaAngleRad = deltaAngle * math.pi / 180
        for i=1, #rotationInstructionVector, 1 do
          local angleIndex = 1 + math.floor(rotationInstructionVector[i] / deltaAngleRad) % deltaAngleCount
          if rotauxLayer:cel(angleIndex) == nil then
            sprite:newCel(rotauxLayer, angleIndex, Rotar(imageToMove, (angleIndex - 1) * deltaAngleRad), Point(0, 0))
          end
        end
      elseif rotationType ~= ROTATION_NONE and #auxLayer.cels ~= 1 then
        rotationInstructionVector = makeRotationInstructionVector(weldedPathExtended,
                                                                  timeVectorN,
                                                                  framesCountToFill,
                                                                  rotationType,
                                                                  translationFunction,
                                                                  trasFunLayer,
                                                                  rotFunLayer,
                                                                  lookAtLayer,
                                                                  C,
                                                                  startFrame,
                                                                  initialAngle * math.pi / 180)
      end
      -- print("10-DONE")
      ------------------------------------------------------------------------------------------------------
      --11 Make the translation final coordinates
      ------------------------------------------------------------------------------------------------------
      local translationCoordinatesVector = makePath(weldedPathExtended, timeVectorN, framesCountToFill, translationFunction, trasFunLayer, C)
      -- print("11-DONE")
      ------------------------------------------------------------------------------------------------------
      --12 Make the scale vector
      ------------------------------------------------------------------------------------------------------
      local scaleVector = {}
      if initialScale ~= 1.0 or finalScale ~= 1.0 then
        scaleVector = makeScaleVector(framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale)
      end
      -- print("12-DONE")
      ------------------------------------------------------------------------------------------------------
      --13 Make ResultLayer to compose position + rotation of the imageToMove
      ------------------------------------------------------------------------------------------------------
      if #resultLayer.cels ~= 0 then
        for i=1, #resultLayer.cels, 1 do
          if resultLayer:cel(i) ~= nil then
            sprite:deleteCel(resultLayer, i)
          end
        end
      end

      if rotationType == ROTATION_NONE and initialAngle ~= 0 and #auxLayer.cels == 1 then
        imageToMove = Rotar(imageToMove, initialAngle * math.pi / 180)
      end
      local celWithRotatedImageAtDesiredAngle = nil
      local imageSelfCenter = Point((imageToMove.width - 0.5) / 2, (imageToMove.height - 0.5) / 2)
      local scaledImageToMove = nil
      for i=1, framesCountToFill, 1 do
        if rotationType ~= ROTATION_NONE and #auxLayer.cels == 1 then
          -- Rotation / No animation
          celWithRotatedImageAtDesiredAngle = extractCelRotated(rotauxLayer, rotationInstructionVector[i], deltaAngleCount)
          imageToMove = celWithRotatedImageAtDesiredAngle.image
          if #scaleVector ~= 0 then
            imageToMove = resizeImage(imageToMove, scaleVector[i])
          end
          imageSelfCenter = Point((imageToMove.width - 0.5) / 2, (imageToMove.height - 0.5) / 2)
          if imageToMove == nil then
            sprite:newCel(resultLayer, startFrame + i - 1)
          else
            sprite:newCel(resultLayer, startFrame + i - 1, imageToMove, translationCoordinatesVector[i] - imageSelfCenter)
          end
        elseif rotationType ~= ROTATION_NONE and #auxLayer.cels > 1 then
          -- Rotation / Animation
          local auxLayerFrameCorrespondence = minFrame + ((i - 1) % (#auxLayer.cels))
          if auxLayer:cel(auxLayerFrameCorrespondence) ~= nil then
            local auxLayerImage = auxLayer:cel(auxLayerFrameCorrespondence).image:clone()
            if #scaleVector ~= 0 then
              auxLayerImage = resizeImage(auxLayerImage, scaleVector[i])
            end
            auxLayerImage = Rotar(auxLayerImage, rotationInstructionVector[i])
            imageSelfCenter = Point(auxLayerImage.width / 2, auxLayerImage.height / 2)
            sprite:newCel(resultLayer, startFrame + i - 1, auxLayerImage, translationCoordinatesVector[i] - imageSelfCenter)
          end
        elseif rotationType == ROTATION_NONE and #auxLayer.cels > 1 then
          -- No Rotation / Animation
          local auxLayerFrameCorrespondence = minFrame + ((i - 1) % (#auxLayer.cels))
          if auxLayer:cel(auxLayerFrameCorrespondence) ~= nil then
            local auxLayerImage = auxLayer:cel(auxLayerFrameCorrespondence).image:clone()
            if #scaleVector ~= 0 then
              auxLayerImage = resizeImage(auxLayerImage, scaleVector[i])
            end
            imageSelfCenter = Point(auxLayerImage.width / 2, auxLayerImage.height / 2)
            sprite:newCel(resultLayer, startFrame + i - 1, auxLayerImage, translationCoordinatesVector[i] - imageSelfCenter)
          end
        elseif rotationType == ROTATION_NONE and #auxLayer.cels == 1 then
          -- No Rotation / No animation
          if #scaleVector ~= 0 then
            scaledImageToMove = resizeImage(imageToMove, scaleVector[i])
            imageSelfCenter = Point(scaledImageToMove.width / 2, scaledImageToMove.height / 2)
            sprite:newCel(resultLayer, startFrame + i - 1, scaledImageToMove, translationCoordinatesVector[i] - imageSelfCenter)
          elseif scaledImageToMove == nil then
            sprite:newCel(resultLayer, startFrame + i - 1, imageToMove, translationCoordinatesVector[i] - imageSelfCenter)
          end
        end
      end
      -- print("13-DONE")
      ------------------------------------------------------------------------------------------------------
      --14 Assign configuration string to the resultLayer
      ------------------------------------------------------------------------------------------------------
      resultLayer:cel(startFrame).data = confString
      -- print("14-DONE")
      sprite:deleteLayer(auxLayer)
      return true
    end
  )
end

function animateResultLayer(layer)
  animateIt({layer}, 0, 1, 0, 0, 0, 0, false, nil, 1, 1, false)
end


function reAnimateSelected(selectedLayers)
  local check = 0
  for i, layer in ipairs(selectedLayers) do
    if layer.name:find(STRING_RESULT_LAYER) ~= nil then
      check = check + 1
    end
  end

  if check ~= #selectedLayers then
    app.alert(string.format("Error: to apply 'Re-animate Selected Layers', you have to select ONLY layers which contains '%s' in its name.", STRING_RESULT_LAYER))
    return false
  end

  for i, layer in ipairs(selectedLayers) do
    animateResultLayer(layer)
  end
end

local sprite = app.activeSprite
if sprite == nil then
  app.alert("WARNING: You should open a sprite first.")
  return nil
end

local HELP = "?"
-- -==== UI Interfase ====---
-- ========================--

local dlgHelp = Dialog { title="Path Animator Help:" }
dlgHelp:label   {   text= "1st: make a Layer named: ".. STRING_PATH_LAYER .. "." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "2nd: active Pixel Perfect and draw some stroke on it."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "3th: paint one pixel stroke end to white (start pixel)."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "4th: draw some item in other layer."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "5th: select both layers and press 'Animate it'"
}
dlgHelp:separator()
dlgHelp:newrow()
dlgHelp:label   {   text= "Path layer must contain the string: " .. STRING_PATH_LAYER .. "." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "You can concatenate paths from several layers." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "One path layer have to contain a white pixel (start pixel)" 
}
dlgHelp:separator()
dlgHelp:label   {   text= "You can select a layer which name contains: ".. STRING_FUNCTION_LAYER .. "." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "It will used to determine the way to walk on the path when"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "translation is 'By Layer'."
}
dlgHelp:separator()
dlgHelp:label   {   text= "At least, one layer with an image has to be selected to make"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "this tool work."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "Many image layers can be selected, this tool can compose"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "all these layers in a new one named: " .. STRING_RESULT_LAYER .. ", which"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "will show the animation results."
}
dlgHelp:separator()
dlgHelp:label   {   text= "Duration and Start Time units are seconds (decimal dot"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "is permited)."
}
local defaultConfString = readConfigurationFromSelectedLayers(app.range.layers)

local startTime = DEFAULT_STARTTIME_STRING
local duration = DEFAULT_DURATION_STRING
local translationFun = TFUNprefix .. FUNC_LINEAL
local rotationType = ROTATIONprefix .. ROTATION_NONE
local initialAngle = DEFAULT_INITIALANGLE_STRING
local startPathPos = DEFAULT_PATH_START_POS_STRING
local loopPath = DEFAULT_LOOP_PATH
local scaleFun = SFUNprefix .. SCALE_NONE
local initialScale = DEFAULT_INITIAL_SCALE
local finalScale = DEFAULT_FINAL_SCALE
local makeNewResultLayer = DEFAULT_MAKE_NEW_RESULT_LAYER
local makeNewResultLayerEnabled = false
if defaultConfString ~= nil then
  startTime = extractStatTimeFromConf(defaultConfString)
  duration = extractDurationFromConf(defaultConfString)
  translationFun = TFUNprefix .. extractTranslationFunctionFromConf(defaultConfString)
  rotationType = ROTATIONprefix .. extractRotationTypeFromConf(defaultConfString)
  initialAngle = extractInitialAngleFromConf(defaultConfString)
  startPathPos = extractStartPathPosFromConf(defaultConfString)
  loopPath = extractLoopPathFromConf(defaultConfString)
  scaleFun = SFUNprefix .. extractScaleFunctionFromConf(defaultConfString)
  initialScale = extractInitialScaleFromConf(defaultConfString)
  finalScale = extractFinalScaleFromConf(defaultConfString)
  makeNewResultLayer = extractMakeNewResultLayerFromConf(defaultConfString)
  makeNewResultLayerEnabled = true
end

local initialScalePerCent = STRING_INITIAL_SCALE .. initialScale * 100.0 .. "_%"
local finalScalePerCent = STRING_FINAL_SCALE .. finalScale * 100.0 .. "_%"

local reAnimateIntention = true
for i,layer in ipairs(app.range.layers) do
  if layer.name:find(STRING_RESULT_LAYER) == nil then
    reAnimateIntention = false
    break
  end
end
-- startTime = "0"
-- duration = "10"
-- translationFun = TFUNprefix .. FUNC_LINEAL
-- rotationType = ROTATIONprefix .. ROTATION_PATH
-- initialAngle = "0"
local dlg1 = Dialog{ title="Path Animator Tool" }
if reAnimateIntention then
  
  dlg1:button  {  text = "Re-animate selected ResultLayers",
                  onclick =
                    function()
                      local tempLayer = app.range.layers[1]
                      reAnimateSelected(app.range.layers)
                      if tempLayer ~= nil then
                        app.activeLayer = tempLayer
                      end
                      app.activeFrame = 1
                      dlg1:close()
                    end
  }
  dlg1:newrow()
  dlg1:button  {  text = "Close",
                  onclick=
                    function()
                      dlg1:close()
                    end
  }
  dlg1:show    {   wait=true
  }
  return nil
end
-- Memorize original layers selected, before to run Path Animator Tool
local originalLayerStackIndices = {}
local celWithImageFound = false
local commandLayersFound = false
local justARotationLayerWasFound = true -- To indentify if just a layer named RFUN was found.
for i,layer in ipairs(app.range.layers) do
  table.insert(originalLayerStackIndices, layer.stackIndex)
  if layer.name:find(STRING_PATH_LAYER) == nil and
     layer.name:find(STRING_FUNCTION_LAYER) == nil and
     layer.name:find(STRING_RESULT_LAYER) == nil and
     layer.name:find(STRING_ROTATION_LAYER) == nil and
     layer.name:find(STRING_LOOKED_LAYER) == nil and
     layer.name:find(STRING_ROTAUX_LAYER) == nil and
     layer.name:find(STRING_SCALE_LAYER) == nil and
     #layer.cels >= 1 then
    celWithImageFound = true
  end
  if layer.name:find(STRING_ROTATION_LAYER) ~= nil then
    commandLayersFound = true
  end
  if layer.name:find(STRING_PATH_LAYER) ~= nil or
     layer.name:find(STRING_LOOKED_LAYER) ~= nil then
    commandLayersFound = true
    justARotationLayerWasFound = false
  end
end
if not commandLayersFound and not celWithImageFound then
  app.alert(string.format("Error: selected layers don't contain %s, %s or %s in their names. Even, selected layers are empty.", STRING_PATH_LAYER, STRING_LOOKED_LAYER, STRING_ROTATION_LAYER))
  return nil
elseif not commandLayersFound and celWithImageFound then
  app.alert(string.format("Error: selected layers don't contains %s, %s or %s in their names.", STRING_PATH_LAYER, STRING_LOOKED_LAYER, STRING_ROTATION_LAYER))
  return nil
elseif commandLayersFound and not celWithImageFound then
  app.alert("Error: one or more selected layers are empty. Please Select a layer with images.")
  return nil
end

local translationOptions = { TFUNprefix .. FUNC_LINEAL,
                             TFUNprefix .. FUNC_BYLAYER,
                             TFUNprefix .. FUNC_EASYIN,
                             TFUNprefix .. FUNC_EASYOUT,
                             TFUNprefix .. FUNC_EASYOUTDAMPED,
                             TFUNprefix .. FUNC_EASYOUTDAMPED2,
                             TFUNprefix .. FUNC_EASYINOUT,
                             TFUNprefix .. FUNC_SINUSOIDAL,
                             TFUNprefix .. FUNC_PARABOLIC }
local rotationOptions = { ROTATIONprefix .. ROTATION_NONE,
                          ROTATIONprefix .. ROTATION_PATH,
                          ROTATIONprefix .. ROTATION_LOOKAT,
                          ROTATIONprefix .. ROTATION_BYLAYER }

-- Forced options when just a RFUN  is selected:
if justARotationLayerWasFound then
  translationOptions = { TFUNprefix .. " NONE"}
  translationFun = TFUNprefix .. " NONE"
  rotationOptions = { ROTATIONprefix .. ROTATION_BYLAYER }
  rotationType = ROTATIONprefix .. ROTATION_BYLAYER
end

-- Dialogo:
local dlg = Dialog{ title="Path Animator Tool" }
dlg:button  {   text = HELP,
                onclick =
                function()
                  dlgHelp:show()
                end
}
dlg:number  {   id="startTime",
                text=startTime,
                decimals=3
}
dlg:number  {   id="aniDuration",
                text=duration,
                decimals=3
}
dlg:newrow()
-- Loop Path:
-- A path has a beginning (white point) and an end (the other path end).
-- A path can be thinked like a road from 0% to 100%.
-- In the other hand, a path can be thinked as a cycle which can be repeated many times
-- Some times, we need to cyclically travel a path with differents images in the same path, but with different cycle start points
-- For example: we need 3 images to cylically travel a circunference. Ok, so we need to check LOOP PATH and each image
-- congigured a PATH START % of 0% , 33.33% and 66.67%.
dlg:check  {  id="loopPath",
              text="Loop Path ?",
              selected=loopPath,
              enabled= not(justARotationLayerWasFound)
}
dlg:newrow()
dlg:number  {   id="startPathPos",
                text=startPathPos,
                decimals=3,
                enabled= not(justARotationLayerWasFound)
}
dlg:newrow()
dlg:combobox  { id = "translationFunction",
                option = translationFun,
                options = translationOptions,
                enabled = not(justARotationLayerWasFound)
}
dlg:newrow()

dlg:combobox  { id = "rotation",
                option = rotationType,
                options = rotationOptions,
                enabled = not(justARotationLayerWasFound)
}
dlg:newrow()
dlg:number  {   id = "initialAngle",
                text = initialAngle,
                decimals = 3
}
dlg:newrow()

dlg:combobox  { id="scaleFunction",
                option=scaleFun,
                options={ SFUNprefix .. SCALE_NONE,
                          SFUNprefix .. SCALE_LINEAL,
                          SFUNprefix .. SCALE_BYLAYER,
                          SFUNprefix .. SCALE_EASYIN,
                          SFUNprefix .. SCALE_EASYOUT,
                          SFUNprefix .. SCALE_EASYOUTDAMPED,
                          SFUNprefix .. SCALE_EASYOUTDAMPED2,
                          SFUNprefix .. SCALE_EASYINOUT,
                          SFUNprefix .. SCALE_SINUSOIDAL,
                          SFUNprefix .. SCALE_PARABOLIC }
}
dlg:newrow()
dlg:number  {   id="initialScale",
                text=initialScalePerCent,
                decimals=3
}
dlg:newrow()
dlg:number  {   id="finalScale",
                text=finalScalePerCent,
                decimals=3
}
dlg:newrow()
dlg:check  {  id="makeNewResultLayer",
              text="Make new ResultLayer",
              enabled=makeNewResultLayerEnabled,
              selected=makeNewResultLayer
}
dlg:newrow()
dlg:button  {   text = "Animate it",
                focus=true,
                onclick =
                  function()
                    -- Make animation!
                    local rotation = dlg.data.rotation:gsub(ROTATIONprefix, "")
                    local translationFunction = dlg.data.translationFunction:gsub(TFUNprefix, "")
                    local startTime = dlg.data.startTime
                    local duration = dlg.data.aniDuration
                    local initialAngle = dlg.data.initialAngle
                    local startPathPos = dlg.data.startPathPos
                    local loopPath = dlg.data.loopPath
                    local scaleFunction = dlg.data.scaleFunction:gsub(SFUNprefix, "")
                    local initialScaleInput = dlg.data.initialScale
                    local finalScaleInput = dlg.data.finalScale
                    local makeNewResultLayer = dlg.data.makeNewResultLayer
                    if duration == 0 then
                      duration = 2.0
                    end
                    if initialScaleInput ~= 0 then
                      initialScale = initialScaleInput / 100.0
                    end
                    if finalScaleInput ~= 0 then
                      finalScale = finalScaleInput / 100.0
                    end
                    local success = animateIt(app.range.layers,
                                              startTime,
                                              duration,
                                              translationFunction,
                                              rotation,
                                              initialAngle,
                                              startPathPos,
                                              loopPath,
                                              scaleFunction,
                                              initialScale,
                                              finalScale,
                                              makeNewResultLayer,
                                              sprite.palettes[1])
                    app.activeFrame = 1
                    dlg:close()
                  end
}
dlg:newrow()
dlg:button  {   text = "Close",
                onclick=
                    function()
                      dlg:close()
                    end
}
dlg:show    {   wait=true
}
selectOriginalLayers(originalLayerStackIndices)