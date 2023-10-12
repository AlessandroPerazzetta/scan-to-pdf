#!/bin/bash
# set -x
# set -v
# **************************** SCAN TO PDF ****************************
# Scan multiple pages and merge to a PDF
#
# Requirements:
#       - scanimage (for scanning in batch mode)
#       - tesseract-ocr (for OCR to PDF)
#           ° tesseract-ocr-eng
#           ° tesseract-ocr-{lang} any other language for the doc
#       - pdfunite (for merging scanned pages into PDF)
#
# Notes:
#       Use scanimage -L to get a list of devices.
#           e.g. device `epson2:net:192.168.1.3' is a Epson PID flatbed scanner
#       set SCANNER with epson2:net:192.168.1.3
#
#       If scanimage return this error:
#           scanimage: sane_start: Invalid argument
#       try to install sane-airscan (https://github.com/alexpevzner/sane-airscan)
#       to enable eSCL backend and get new devices:
#           device `escl:https://192.168.1.3:443' is a ESCL EPSON ET-2850 Series SSL flatbed scanner
#           device `escl:http://192.168.1.3:443' is a ESCL EPSON ET-2850 Series flatbed scanner
#           device `epson2:net:192.168.1.3' is a Epson PID flatbed scanner
#           device `airscan:e0:EPSON ET-2850 Series' is a eSCL EPSON ET-2850 Series ip=192.168.1.3
#
# Usage:
#       scan.sh filename pages output dpi brightness color|gray

SCRIPT_NAME=`basename "$0" .sh` #Directory to store temporary files
BASEDIR=$(pwd)

FILENAME=scan_file      #Agrument 1,filename
PAGES=0                 #Argument 2, number of pages
OUTDIR=/tmp

# SCANNER=airscan:e0:EPSON  #EPSON ET-2850 eSCL scanner
SCANNER="airscan:e0:EPSON ET-2850 Series"   #EPSON ET-2850 eSCL scanner

DPI=300
BRIGHTNESS=40   #Brightness to remove paper look
MODE=color

TESS_LANG=eng  #Language that Tesseract uses for OCR

# Show program usage
function show_usage {
    echo -e "\nUsage: \t $0 filename pages output dpi brightness color|gray"
}

# Check dependencies
function check_dependencies {
    deps=("scanimage" "pdfunite" "tesseract")
    missingdeps=""
    missingdepsinstall=""

    OS=$(uname -s | tr A-Z a-z)
    case $OS in
    linux)
        source /etc/os-release
        case $ID_LIKE in
        debian|ubuntu|mint)
            missingdepsinstall="sudo apt install"
            ;;

        fedora|rhel|centos)
            missingdepsinstall="sudo yum install"
            ;;
        arch)
            missingdepsinstall="yay -S"
            ;;
        *)
            echo -n "unsupported linux package manager"
            ;;
        esac
    ;;

    darwin)
        missingdepsinstall="brew install"
    ;;

    *)
        echo -n "unsupported OS"
        ;;
    esac

    for dep in "${deps[@]}"; do
        if ! type $(echo "$dep" | cut -d\| -f1) &> /dev/null; then
            missingdeps=$(echo "$missingdeps$(echo "$dep" | cut -d\| -f1), ")
            missingdepsinstall=$(echo "$missingdepsinstall $(echo "$dep" | cut -d\| -f2)")
        fi
    done
    if [ -n "$missingdeps" ]; then
        echo "[ERROR] Missing dependencies! ($(echo "$missingdeps" | xargs | sed 's/.$//'))"
        echo "        You can install them using this command:"
        echo "        ----------------------------------------"
        echo "        $missingdepsinstall"
        echo "        ----------------------------------------"
        exit 1
    fi
}

# Create Temporary directory
function create_tmp_dir {
    TMP_DIR=${OUTDIR}/${SCRIPT_NAME}-tmp

    if [ -d ${TMP_DIR} ]  #Check if it exists a directory already
    then
            echo "[ERROR] The directory ${TMP_DIR} exists, removing."
            rm -rf "${TMP_DIR}"
            # exit 2
    fi
    mkdir -p ${TMP_DIR}  #Make and go to temp dir
    cd ${TMP_DIR}
}

# Convert all pages tiff to pdf
function convert_tiff_to_pdf {
    # Cycle all tif files in TMP_DIR and convert into PDF
    for file in *.tif
    do
        tesseract $file  ${file%.tif} -l ${TESS_LANG} pdf
    done    
}

# Merge all pdf into one
function merge_pages {
    # Merging pages
    if [ "$PAGES" = "1" ]
    then
        # If there's only one page, copy the PDF to filename PDF
        cp out1.pdf ../${FILENAME}.pdf
    else
        # If there are more pages, merge the pages into one PDF
        for file in *.pdf
        do
                pdfuniteargs+=${file} 
                pdfuniteargs+=" "
        done
        pdfunite $pdfuniteargs ../${FILENAME}.pdf
    fi
    
    echo "[INFO] ${FILENAME}.pdf done."
    rm *
    cd ${BASEDIR}
    echo "[INFO] Removing TMP_DIR: ${TMP_DIR}"
    rm -rf "${TMP_DIR}"
}

# Check arguments
if [ $# -eq 0 ]
then
    echo "[ERROR] No arguments supplied"
    show_usage >&2; exit 1
fi
if [ "$1" ]
then
    FILENAME=$1
fi

if [ "$2" ]
then
    re='^[0-9]+$'  #Check if second argument is a number
    if ! [[ ${2} =~ $re ]] ; then
        show_usage >&2; exit 1
    fi
    PAGES=$2
fi

if [ "$3" ]
then
    OUTDIR=$3
fi

if [ "$4" ]
then
    re='^[0-9]+$'  #Check if second argument is a number
    if ! [[ ${4} =~ $re ]] ; then
        show_usage >&2; exit 1
    fi
    DPI=$4
fi

if [ "$5" ]
then
    re='^[0-9]+$'  #Check if second argument is a number
    if ! [[ ${5} =~ $re ]] ; then
        show_usage >&2; exit 1
    fi
    BRIGHTNESS=$5
fi

if [ "$6" ]
then
    if ! [[ ${6} == "color" || ${6} == "gray" ]] ; then
        show_usage >&2; exit 1
    fi
    MODE=$6
fi

# Check if dependencies are satisfied
check_dependencies

# Create temporary dir where scans are saved and manipulated
create_tmp_dir

# Scan pages in batch mode
echo "[INFO] Starts Scanimage..."
echo -e "Using ${SCANNER} format: tiff, mode: ${MODE}, resolution: ${DPI}, brightness: ${BRIGHTNESS} for ${PAGES} pages\n"
scan_options=("--device-name=${SCANNER}" "--format=tiff" "--mode=${MODE}" "--resolution=${DPI}" "--progres" "--brightness=${BRIGHTNESS}" "--batch-start=1" "--batch-count=${PAGES}" "--batch-prompt")
scanimage "${scan_options[@]}"

# Convert tif files into pdf
echo "[INFO] Starts Tesseract OCR..."
convert_tiff_to_pdf

# Merge all pdf into one
echo "[INFO] Merging pages..."
merge_pages