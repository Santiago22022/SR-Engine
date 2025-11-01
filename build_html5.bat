@echo off
echo Building SR Engine for HTML5 with optimizations...
echo.

REM Build the HTML5 version
haxelib run lime build html5 -release

echo.
echo HTML5 build completed! Check the export directory for the output.
echo To test the build, open export/release/html5/bin/index.html in a browser.
pause