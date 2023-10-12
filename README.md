# Scan To PDF
Scan multiple pages and merge to a PDF

# Requirements:
- scanimage (for scanning in batch mode)
- tesseract-ocr (for OCR to PDF)

    ° tesseract-ocr-eng

    ° tesseract-ocr-{lang} any other language for the doc

- pdfunite (for merging scanned pages into PDF)

# Notes:
Use `scanimage -L` to get a list of devices.
    e.g. device `epson2:net:192.168.1.3' is a Epson PID flatbed scanner

set SCANNER with epson2:net:192.168.1.3

If scanimage return this error: `scanimage: sane_start: Invalid argument`

try to install sane-airscan (https://github.com/alexpevzner/sane-airscan) to enable eSCL backend and get new devices:

    device `escl:https://192.168.1.3:443' is a ESCL EPSON ET-2850 Series SSL flatbed scanner
    device `escl:http://192.168.1.3:443' is a ESCL EPSON ET-2850 Series flatbed scanner
    device `epson2:net:192.168.1.3' is a Epson PID flatbed scanner
    device `airscan:e0:EPSON ET-2850 Series' is a eSCL EPSON ET-2850 Series ip=192.168.1.3

# Usage:
`scan.sh pages dpi brightness color|gray output filename`

    - pages: number of pages to scan
    - dpi: resolution, values available (refer printer capabilities): 
            75
            150
            200
            300 (default)
            400
            600
    - brightness: -100 ... 100 percent (40 default)
    - color|gray: acquisition mode, color or gray
    - filename: file name of the final PDF
    - output: output directory where save temporary files and final PDF

## Example:
`./scan.sh 12 300 30 gray ./out eboook`