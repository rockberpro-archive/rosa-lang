@echo off
REM This script compiles the ROSA grammar and generates the parser and lexer classes.
REM Ensure that the ANTLR jar file is in the same directory as this script.
REM Usage: Place your input in program.rosa and run this script.
REM Make sure you have the ANTLR jar file (antlr-4.5.3.jar) and Jasmin jar file (jasmin-2.4.jar) in the same directory.
REM The generated Java files will be compiled and the output will be in ROSATest.j
REM The Jasmin assembler will then convert the .j file to .class files.
REM Change the paths below if necessary to point to your ANTLR and Jasmin jar files.
java -jar antlr-4.5.3.jar ROSA.g
javac -cp antlr-4.5.3.jar ROSA*.java