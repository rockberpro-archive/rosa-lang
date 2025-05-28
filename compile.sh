java -jar antlr-4.5.3.jar ROSA.g
javac -cp antlr-4.5.3.jar ROSA*.java
java -cp antlr-4.5.3.jar:. ROSAParser < input.txt > ROSATest.j
java -jar jasmin-2.4.jar ROSATest.j