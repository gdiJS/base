copy /b constants* c~
copy /b prototype* p~
copy /b obj* o~
copy /b native* n~
copy /b mod* m~
copy /b c~+p~+o~+n~+m~ packed.js
del *~
copy packed.js minifier\packed.js
del packed.js
cd minifier
AjaxMinifier.exe packed.js -o engine.js
copy engine.js ..\..\..\..\engine.js
del engine.js
pause