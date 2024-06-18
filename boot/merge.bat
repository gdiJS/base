copy /b constants* c~
copy /b prototype* p~
copy /b obj* o~
copy /b native* n~
copy /b mod* m~
copy /b c~+p~+o~+n~+m~ engine.js
copy engine.js ..\..\..\engine.js
del *~
del engine.js
pause