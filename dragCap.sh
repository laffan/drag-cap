#!/bin/bash

# dragCap
# -----------
# A script for dragging and capturing.

browser="Google Chrome" # Browser you'd like to use. Must match app name exactly.

# Start position of your cursor (upper left) for each tile
initialX=45
initialY=253

# Size of each tile
tileWidth=1200
tileHeight=1000

# Size of grid
columns=4
rows=4

# Various timing options. (current setup works well)
screenshotDelay=1
dragDelay=2
dragCommandDelay=1000
dragEase=1000

# Options
stitchOnComplete=1  # Stitch togethe tiles after completion (requires imageMagik)
outputDir=~/Desktop/tiles # Save location of tiles

# Check if the "Tiles" folder exists on the Desktop; if not, create it
if [ ! -d "$outputDir" ]; then
  mkdir "$outputDir"
fi

# Empty the output folder on init 
rm -f "${outputDir}"/* 

# Focus on browser before starting the capture process
osascript -e "tell application \"System Events\" to tell process \"$browser\" to set frontmost to true"

# Drag direction flag; 1 for normal, -1 for reverse
captureDirection=1

# cliclick drag function
# Usage: cliclickDrag startX startY dragX dragY
cliclickDrag() {
  local startX=$1
  local startY=$2
  local endX=$3
  local endY=$4

  if [ $captureDirection -eq 1 ]; then
    cliclick -m verbose "m:${startX},${startY}"
    cliclick -m verbose -e $dragEase "dd:${startX},${startY}" "w:${dragCommandDelay} "dm:${endX},${endY}" "w:${dragCommandDelay} "du:${endX},${endY}"
  else
    cliclick -m verbose "m:${endX},${endY}"
    cliclick -m verbose -e $dragEase "dd:${endX},${endY}" "w:${dragCommandDelay} "dm:${startX},${startY}" "w:${dragCommandDelay} "du:${startX},${startY}"
  fi

  sleep $dragDelay

}
captureCount=1
# Loop through the grid
for ((i = 1; i <= rows; i++)); do
  for ((j = 1; j <= columns; j++)); do
    # Capture the current tile
    if [ $captureDirection -eq 1 ]; then
      columnLabel=${j}
    else
      columnLabel=$(($columns - $j + 1))
    fi
    echo -e "\033[41m 📸 Capturing Tile $(($captureCount)) of $(($rows * $columns)) \033[m"
    screencapture -R"${initialX},${initialY},${tileWidth},${tileHeight}" "${outputDir}/tile_${i}_${columnLabel}.png"
    sleep $screenshotDelay
    captureCount=$((captureCount  + 1))

    # Drag to the next tile if not the last column
    if [ $j -ne $columns ]; then
      echo "Column $j | Row $i"
      cliclickDrag $(($initialX + $tileWidth)) $initialY $initialX $initialY
    fi
  done

  if [ $i -ne $rows ]; then
    # Pull up a row
    sleep $dragDelay
    cliclick -m verbose "m:${initialX},$(($initialY + $tileHeight))"
    cliclick -m verbose -e $dragEase "dd:${initialX},$(($initialY + $tileHeight))" "w:${dragCommandDelay} "dm:${initialX},${initialY}" "w:${dragCommandDelay} "du:${initialX},${initialY}"
    sleep $dragDelay
    # change direction
    echo "*NEW ROW | Changing direction*"
    captureDirection=$((captureDirection * -1))
  fi
done

# Stich the images together (if stitchOnComplete is set to 1)

if [ $stitchOnComplete -eq 1 ]; then

  echo "..."
  echo -e "\033[41m 🧩 Combining Tiles \033[m"

  montage "${outputDir}/tile_*.png" -tile ${columns}x${rows} -geometry +0+0 "${outputDir}/combined.png"

  # Execute the montage command
  eval $montageCmd

fi
