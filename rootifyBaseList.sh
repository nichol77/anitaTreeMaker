#!/bin/bash
source ~/.bashrc

# ONLINE=1: pulls the most recently elog entries and make the baseLists automatically
# ONLINE=0: uses an old baseList found in OFFLINE_DIR
# Special option: ONLINE=2: If you want a specific old elog entry, specify here
ONLINE=1
OFFLINE_DIR="~/Downloads" # Set this only if you want to not use the most recent elog pull

if [ "$ONLINE" == 1 ]; then
    ## Automatically pull the latest update from the elog!
    echo "Determining newest entries..."
    curl https://www.phys.hawaii.edu/elog/anita_notes/703 > urlInText.html
    grep -oP '(?<="attribvalue"><a href=")[^.gz]*' urlInText.html > updatedBaseLists.html
    mapfile -t updateArray < updatedBaseLists.html
    anita3UpdatedName=${updateArray[0]}
    anita4UpdatedName=${updateArray[1]}

    ## Now that we have found the latest elog names, we can pull them
    echo "Pulling the newest spreadsheets from the elog"
    wget -q --show-progress  "https://www.phys.hawaii.edu/elog/anita_notes/${anita4UpdatedName}.tar.gz" ## A4
    wget -q --show-progress  "https://www.phys.hawaii.edu/elog/anita_notes/${anita3UpdatedName}.tar.gz" ## A3
    wget -q --show-progress  "https://www.phys.hawaii.edu/elog/anita_notes/100125_143642/all_base_locations_new.txt" ## A2

    ## Only use the below if you want to use a specific elog entry, the above should pull the latest automatically!
elif [ "$ONLINE" == 2 ]; then
    wget "https://www.phys.hawaii.edu/elog/anita_notes/170627_083355/base_data_unrestricted-A4.tar.gz" ## A4
    wget "https://www.phys.hawaii.edu/elog/anita_notes/170620_152306/base_data_unrestricted-A3.tar.gz" ## A3
    wget "https://www.phys.hawaii.edu/elog/anita_notes/100125_143642/all_base_locations_new.txt" ## A2
    
elif [ "ONLINE" == 0 ]; then
    echo "You are marked as offline..."
    echo "Finding an earlier pull of the elog in ~/Downloads. Working with old and limited data."
    cp "$OFFLINE_DIR/base_data_unrestricted-A4.tar.gz ./base_data_unrestricted-A4.tar.gz"
    cp "$OFFLINE_DIR/base_data_unrestricted-A3.tar.gz ./base_data_unrestricted-A3.tar.gz"

else
    echo "Tell the script if you're online..." 
    
fi

if [ -d "data" ]; then
    rm -rf ./data
fi

rm urlInText.html updatedBaseLists.html
mkdir ./data
mv *.tar.gz ./data
mv all_base_locations_new.txt ./data
cd ./data

echo "Extracting information..."
tar -zxf base_data_unrestricted-A4.tar.gz
tar -zxf base_data_unrestricted-A3.tar.gz

if [ ! -d "convertedFiles" ]; then
    mkdir convertedFiles/
fi

mv unrestricted-A4/* convertedFiles/
mv unrestricted-A3/* convertedFiles/
mv all_base_locations_new.txt convertedFiles/

cd ./convertedFiles

#### Sort out TXT FILE (anita2)

#sed -i 's/\./,/g' all_base_locations_new.txt;
sed -ri 's/\s+/,/g' all_base_locations_new.txt;
#sed -i 's/,_/_/g' all_base_locations_new.txt; 

#### Sort out SPREADSHEETS (anita3&4)

echo "Converting the individual spreadsheet 'sheets' into .csv files"
# converts spreadsheets into individual sheets
ssconvert -S base_list-unrestricted-A4.ods base_list-unrestricted-A4.csv
ssconvert -S base_list-unrestricted-A3.ods base_list-unrestricted-A3.csv

echo "Sorting out the files..."

for i in `seq 0 4`;
do
    # get rid of first 2 headers
    sed -i '1,2 d' base_list-unrestricted-A4.csv.$i
    sed -i '1,2 d' base_list-unrestricted-A3.csv.$i
    
    # in case there are any empty fields, replace them with -999
    sed -i 's/,\{2,\}/,-999,/g' base_list-unrestricted-A4.csv.$i
    sed -i 's/,\{2,\}/,-999,/g' base_list-unrestricted-A3.csv.$i

    # replaced exported quotes with nothing
    sed -i 's/"//g' base_list-unrestricted-A4.csv.$i
    sed -i 's/"//g' base_list-unrestricted-A3.csv.$i

    # replaced 'comma space' with nothing to fix issues such as "Henderson, Mount"
    sed -i 's/, //g' base_list-unrestricted-A4.csv.$i
    sed -i 's/, //g' base_list-unrestricted-A3.csv.$i

    # replace approximations (~) with nothing
    sed -i 's/~//g' base_list-unrestricted-A4.csv.$i
    sed -i 's/~//g' base_list-unrestricted-A3.csv.$i

done

# Move csvs to a folder and tar 'em up (made due to a request, probably obsolete)
if [ ! -d "baseListCSVs" ]; then
    mkdir baseListCSVs
fi

cp base_list-unrestricted-A3.csv.* base_list-unrestricted-A4.csv.* baseListCSVs
tar -zcf baseListCSVs.tar.gz baseListCSVs

echo "--------"

cd ../../

echo "Running rootfication scripts"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD
root -b -l <<EOF
     .! echo "Making ANITA-4 trees..."
   .X basesCampsRootifier.cxx
   .X antarcticTreatyRootifier.cxx
   .X fixedWingRootifier.cxx	
   .X awsRootifier.cxx
   .X basInstrumentsRootifier.cxx
   .! echo "--------"
   .! echo "Making ANITA-3 trees..." 
   .X basesCampsRootifierA3.cxx
   .X antarcticTreatyRootifierA3.cxx	
   .X fixedWingRootifierA3.cxx	
   .X awsRootifierA3.cxx
   .X basInstrumentsRootifierA3.cxx	
   .! echo "--------"
   .! echo "Making ANITA-2 tree..."	
   .X A2Rootifier.cxx
EOF

cp baseList.root baseListA4.root ## Make a copy of base list to suit naming convention

mv baseListA2.root baseListA3.root baseListA4.root  $BUILD_TOOL/components/anitaEventCorrelator/data  ## Send to build tool dir
rm baseList*.root

rm -rf  ./data

echo "Done!"
