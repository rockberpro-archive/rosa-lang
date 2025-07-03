@echo off
type program.rosa | java -cp antlr-4.5.3.jar;. ROSAParser > ROSATest.j
java -jar jasmin-2.4.jar ROSATest.j