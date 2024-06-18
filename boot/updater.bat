copy update.js minifier\update.js
cd minifier
AjaxMinifier.exe update.js -o updater.js
copy updater.js ..\..\..\..\updater.js
del updater.js
pause