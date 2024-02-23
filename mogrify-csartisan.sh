#! /usr/bin/env bash

file="$1"

STATUS="\033[1;32m"
WARN="\033[0;31m"
SUCCESS="\033[;32m"
SUB="\033[0;36m"
DONE="\033[0;32;5;30m"
RST="\033[0m"

# Warnings

# File arg does not exist
if [ ! -e "$file" ] && [ "$file" != "" ]; then
    echo ; echo -e "${WARN}File does not exist. Exiting...${RST}" ; echo
    exit 1
fi

# File is blank so it uses all PNGs in the current directory
if [[ "$file" == "" ]]; 
then
    # Sets subject to all PNGs
    file="*.png"

    # Checks if there are any PNGs in the current directory
    if [ ! -a $file ]; then
        echo ; echo -e "${WARN}No .png files availible. Exiting...${RST}" ; echo
        exit 1
    fi

    echo ; echo -e "${WARN}No file parameter detected,${RST} mogrifying all PNGs..." ; echo

fi 

# Displays all files being effected
for p in $file; do
    echo -e "${DONE}Loaded file:${RST} ${SUB}$p${RST}"
done ; echo

for p in $file; do
# Format image from png to jpg
mogrify -format jpg $p || exit 1
echo -e $"${STATUS}[1/4]${RST} ${SUB}$p${RST} converted to .jpg"
done ; echo

for p in $file; do
# Crop to 4:3 aspect ratio
mogrify -crop '4:3' -gravity center "${p/png/jpg}" | echo -e $"${STATUS}[2/4]${RST} ${SUB}${p/png/jpg}${RST} cropped to 4:3"
done ; echo

for p in $file; do
# Resize to 800x600
mogrify -resize '800x600!' "${p/png/jpg}" | echo -e $"${STATUS}[3/4]${RST} ${SUB}${p/png/jpg}${RST} scaled to 800x600px"
done ; echo

# OG SIZE
echo -e "${DONE}Original size:${RST}"
du -sh *.jpg ; echo

for p in $file; do

# Converts quality value from default (100) to 80
mogrify -quality 80 "${p/png/jpg}" | echo -e $"${STATUS}[4/4]${RST} ${SUB}${p/png/jpg}${RST} mogrified to 80% quality"
done ; echo

# NEW SIZE
echo -e "${DONE}Mogrified size:${RST}"
du -sh *.jpg ; echo

# DONE
echo -e "${DONE}All specified images have been formatted.${RST}"

echo

while true; do

# Either deletes or relocates old PNGs
read -p "$(echo -e "${WARN}Do you want to move all remaining .png files to trash?${RST} (Y/n) ")" yn

case $yn in 
    # Yes, delete all PNGs
	[yY] ) echo ;
        echo -e "${DONE}Moving all remaining .png files to trash...${RST}"; echo 
        for p in *.png; do
            trash $p
            echo -e "${WARN}Deleted file${RST} ${SUB}$p${RST}"
        done

        echo; echo -e "${DONE}All remaining PNGs have been moved to trash.${RST}"

		break;;
    
    # No, make a new directory and move them inside of it
	[nN] ) echo ;

        echo -e "${DONE}Moving remaining .png files to ${SUB}png/${RST}${DONE}...${RST}"; echo

        # Folder does not exist
        if [[ ! -d png/ ]]; then
            mkdir png
            echo -e "${DONE}Making directory${RST} ${SUB}png/${RST}${DONE}...${RST}" ; echo
        else
            echo -e "${WARN}Directory ${SUB}png/${RST} ${WARN}already found...${RST}" ; echo
        fi

        # Moves PNGs to png/
        for p in $file; do
            mv $p png
            echo -e "${SUCCESS}Moved${RST} ${SUB}$p${RST} ${SUCCESS}to${RST} ${SUB}png/${RST}"
        done

        echo -e "${DONE}All remaining PNGs have been relocated.${RST}"

        break;;

	* ) echo "invalid response"
        break;;
esac

done

echo ; exit