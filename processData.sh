# simple script for rootifying selections of ANITA-4 data

#!/bin/sh

FIRSTRUN=1
LASTRUN=367

bold=$(tput bold)
normal=$(tput sgr0)

for ((n=${FIRSTRUN};n<=${LASTRUN};n++)); do
    
    if [ $n == ${FIRSTRUN} ]; then
	echo "${bold}Starting to processes the ANITA-4 data set..."
    fi    

    echo "${bold}Now on run $n${normal}"
    
    ./ANITA4rootifier.sh $n & # Full rootifier, now running in parallel!
    if [ $n > 41 ]; then
	./makeGpsEventTreeBothAdu5s $n &
    fi
    echo "${bold}Run $n complete! ${normal}"
    echo "<----------------------------------------->"

    if [ $n == ${LASTRUN} ]; then
	echo "${bold}ANITA-4 data processed"
    fi
    
done
