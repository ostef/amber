@echo off

jai source/build.jai -import_dir ../modules -- %*
rem jai source/build.jai -import_dir modules\ -import_dir c:\jai\modules\ -meta Meta/Build -debug
