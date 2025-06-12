java -jar antlr-4.5.3.jar ROSA.g
javac -cp antlr-4.5.3.jar ROSA*.java
type input.txt | java -cp antlr-4.5.3.jar;. ROSAParser > ROSATest.j
java -jar jasmin-2.4.jar ROSATest.j