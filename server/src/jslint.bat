@echo off
cd ..\..\lib\jslint
for %%f in (..\..\server\src\html\script\*.js) do call run-jslint.bat %%f
