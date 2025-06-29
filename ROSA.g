grammar ROSA;


/*---------------- COMPILER INTERNALS ----------------*/


@header
{
   import java.util.Map;
   import java.util.LinkedHashMap;
   import java.util.ArrayList;
   import java.util.Scanner;
   import java.util.Locale;
}


@members
{
   Map<String, Integer> memory = new LinkedHashMap<String, Integer>();
   Map<String, String> variableTypes = new LinkedHashMap<String, String>(); // Para armazenar tipos das variáveis
   Map<String, Integer> functions = new LinkedHashMap<String, Integer>();
   Map<String, String> functionBodies = new LinkedHashMap<String, String>();
   Integer counter = 1;
   Integer functionCounter = 1;
   boolean inFunction = false;
   StringBuilder functionBodyBuilder = new StringBuilder();
   static Scanner scanner = new Scanner(System.in); // Scanner global para leitura

   public static void main(String[] args) throws Exception
   {
       ANTLRInputStream input = new ANTLRInputStream(System.in);
       ROSALexer lexer = new ROSALexer(input);
       CommonTokenStream tokens = new CommonTokenStream(lexer);
       ROSAParser parser = new ROSAParser(tokens);
       parser.program();
   }
}


/*---------------- LEXER RULES ----------------*/


PLUS      : '+' ;
MINUS     : '-' ;
TIMES     : '*' ;
OVER      : '/' ;
REMAINDER : '%' ;
OPEN_C    : '{' ;
CLOSE_C   : '}' ;
OPEN_P    : '(' ;
CLOSE_P   : ')' ;
ATTRIB    : '=' ;


MAIN      : 'main' ;
PRINT     : 'print' ;
TEXTCOLOR : 'textcolor';
FUNCTION  : 'procedure' ;
RETURN    : 'return' ;
CALL      : 'call' ;
COMMA     : ',' ;

// Adicionar tokens para tipos
INT_TYPE    : 'int' ;
DOUBLE_TYPE : 'double' ;
STRING_TYPE : 'string'  ;
ARRAY_TYPE  : 'array' ;

// Tokens para operações de arrays
ARRAY_PUSH   : 'array_push' ;
ARRAY_POP    : 'array_pop' ;
ARRAY_LENGTH : 'array_length' ;
ARRAY_GET    : 'array_get' ;
ARRAY_SET    : 'array_set' ;

// Tokens para operações de leitura
READ_INT    : 'read_int' ;
READ_STRING : 'read_string' ;
READ_DOUBLE : 'read_double' ;


VAR     : 'a'..'z'+ ;
NUM     : '0'..'9' + ;
NL      : ('\r')? '\n' { skip(); } ;
SPACE   : (' '|'\t')+ { skip(); } ;
STRING  : '"' ('\\' . | ~('\\'|'"'))* '"' ;
DOUBLE  : ('0'..'9')+ '.' ('0'..'9')+ ;


/*---------------- PARSER RULES ----------------*/

program
   : NL* (function_def NL*)* main NL* (function_def NL*)*
       {
           // Gera as funções no final
           for (String funcName : functions.keySet()) {
               System.out.println(".method public static " + funcName + "()I");
               System.out.println(".limit stack 20");
               System.out.println(".limit locals 20");
               System.out.println(functionBodies.get(funcName));
               System.out.println("    ldc 0");
               System.out.println("    ireturn");
               System.out.println(".end method\n");
           }
       }
   ;

function_def
   : FUNCTION VAR OPEN_P (parameter_list)? CLOSE_P NL* OPEN_C
       {
           String funcName = $VAR.text;
           if (!functions.containsKey(funcName)) {
               functions.put(funcName, functionCounter++);
               functionBodies.put(funcName, "");
           }
           inFunction = true;
           functionBodyBuilder = new StringBuilder();
       }
       NL* (statement NL*)*
       (return_statement NL*)?
   CLOSE_C
       {
           inFunction = false;
           // Armazena o corpo da função para gerar depois
           functionBodies.put($VAR.text, functionBodyBuilder.toString());
       }
   ;

parameter_list
   : VAR (COMMA VAR)*
   ;

return_statement
   : RETURN expression
       {
           if (inFunction) {
               functionBodyBuilder.append("    ireturn\n");
           }
       }
   ;

function_call returns [String valueType, String text]
   : CALL VAR OPEN_P (argument_list)? CLOSE_P
       {
           String funcName = $VAR.text;
           if (functions.containsKey(funcName) || inFunction) {
               if (inFunction) {
                   functionBodyBuilder.append("    invokestatic ROSATest/" + funcName + "()I\n");
               } else {
                   System.out.println("    invokestatic ROSATest/" + funcName + "()I");
               }
               $valueType = "FUNCTION_CALL";
               $text = funcName;
           } else {
               System.err.println("undefined function " + funcName);
               $valueType = "UNDEF";
               $text = funcName;
           }
       }
   ;

argument_list
   : expression (COMMA expression)*
   ;


main
   :  MAIN OPEN_P CLOSE_P NL* OPEN_C
           {
               System.out.println(".source ROSATest.j");
               System.out.println(".class  public ROSATest");
               System.out.println(".super  java/lang/Object\n");
               System.out.println(".field public static scanner Ljava/util/Scanner;\n");
               System.out.println(".method public <init>()V");
               System.out.println("    aload_0");
               System.out.println("    invokenonvirtual java/lang/Object/<init>()V");
               System.out.println("    return");
               System.out.println(".end method\n");
               System.out.println(".method static <clinit>()V");
               System.out.println(".limit stack 5");
               System.out.println(".limit locals 0");
               System.out.println("    new java/util/Scanner");
               System.out.println("    dup");
               System.out.println("    getstatic java/lang/System/in Ljava/io/InputStream;");
               System.out.println("    invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V");
               System.out.println("    dup");
               System.out.println("    getstatic java/util/Locale/US Ljava/util/Locale;");
               System.out.println("    invokevirtual java/util/Scanner/useLocale(Ljava/util/Locale;)Ljava/util/Scanner;");
               System.out.println("    pop");
               System.out.println("    putstatic ROSATest/scanner Ljava/util/Scanner;");
               System.out.println("    return");
               System.out.println(".end method\n");
               System.out.println(".method public static main([Ljava/lang/String;)V");
               System.out.println(".limit stack 20");
               System.out.println(".limit locals 20");
           }
       NL* ( statement NL* )* CLOSE_C
           {
               System.out.println("    return");
               System.out.println(".end method");
           }
   ;

statement
   : assignment           |
     typed_assignment     |
     statement_print      |
     statement_textcolor  |
     statement_if         |
     statement_while      |
     function_call        |
     array_push           |
     array_pop            |
     array_set            |
     array_get            |
     read_statement
   ;

assignment
   :
       VAR ATTRIB ( value )
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               // Detectar tipo baseado no value
               if ($value.valueType.equals("READ_DOUBLE") || $value.valueType.equals("DOUBLE") || $value.valueType.equals("DOUBLE_VAR")) {
                   variableTypes.put($VAR.text, "double");
                   memory.put($VAR.text, counter - 1);
                   counter++; // Double ocupa 2 slots
               } else if ($value.valueType.equals("READ_STRING") || $value.valueType.equals("STRING") || $value.valueType.equals("STRING_VAR")) {
                   variableTypes.put($VAR.text, "string");
               } else {
                   variableTypes.put($VAR.text, "int");
               }
           }
           
           String varType = variableTypes.get($VAR.text);
           if (inFunction) {
               if (varType.equals("double")) {
                   functionBodyBuilder.append("    dstore " + memory.get($VAR.text) + "\n");
               } else if (varType.equals("string")) {
                   functionBodyBuilder.append("    astore " + memory.get($VAR.text) + "\n");
               } else {
                   functionBodyBuilder.append("    istore " + memory.get($VAR.text) + "\n");
               }
           } else {
               if (varType.equals("double")) {
                   System.out.println("    dstore " + memory.get($VAR.text));
               } else if (varType.equals("string")) {
                   System.out.println("    astore " + memory.get($VAR.text));
               } else {
                   System.out.println("    istore " + memory.get($VAR.text));
               }
           }
       }
   | VAR ATTRIB ( expression )
       {
           if (!memory.containsKey($VAR.text)) memory.put($VAR.text, counter++);
           if (inFunction) {
               functionBodyBuilder.append("    istore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    istore " + memory.get($VAR.text));
           }
       }
   ;

typed_assignment
   : INT_TYPE VAR ATTRIB expression
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, "int");
           }
           if (inFunction) {
               functionBodyBuilder.append("    istore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    istore " + memory.get($VAR.text));
           }
       }
   | DOUBLE_TYPE VAR ATTRIB expression
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter);
               counter += 2; // Double ocupa 2 slots
               variableTypes.put($VAR.text, "double");
           }
           if (inFunction) {
               functionBodyBuilder.append("    dstore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    dstore " + memory.get($VAR.text));
           }
       }
   | STRING_TYPE VAR ATTRIB value
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, "string");
           }
           if (inFunction) {
               functionBodyBuilder.append("    astore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    astore " + memory.get($VAR.text));
           }
       }
   | ARRAY_TYPE VAR
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, "array");
           }
           // Criar novo ArrayList
           if (inFunction) {
               functionBodyBuilder.append("    new java/util/ArrayList\n");
               functionBodyBuilder.append("    dup\n");
               functionBodyBuilder.append("    invokespecial java/util/ArrayList/<init>()V\n");
               functionBodyBuilder.append("    astore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    new java/util/ArrayList");
               System.out.println("    dup");
               System.out.println("    invokespecial java/util/ArrayList/<init>()V");
               System.out.println("    astore " + memory.get($VAR.text));
           }
       }
   ;

value returns [String valueType, String text]
   : STRING { $valueType = "STRING"; $text = $STRING.text; }
   | NUM    { $valueType = "INT";    $text = $NUM.text; }
   | DOUBLE { $valueType = "DOUBLE"; $text = $DOUBLE.text; }
   | VAR    {
                Integer v = memory.get($VAR.text);
                if (v != null) {
                    String varType = variableTypes.get($VAR.text);
                    if (varType != null && varType.equals("double")) {
                        $valueType = "DOUBLE_VAR";
                    } else if (varType != null && varType.equals("string")) {
                        $valueType = "STRING_VAR";
                    } else {
                        $valueType = "VAR";
                    }
                    $text = $VAR.text;
                } else {
                    System.err.println("undefined variable " + $VAR.text);
                    $valueType = "UNDEF";
                    $text = $VAR.text;
                }
            }
   | function_call { $valueType = $function_call.valueType; $text = $function_call.text; }
   | read_int { $valueType = $read_int.valueType; $text = $read_int.text; }
   | read_double { $valueType = $read_double.valueType; $text = $read_double.text; }
   | read_string { $valueType = $read_string.valueType; $text = $read_string.text; }
   | array_get { $valueType = $array_get.valueType; $text = $array_get.text; }
   | array_length { $valueType = $array_length.valueType; $text = $array_length.text; }
   ;

statement_if
   : 'is' OPEN_P condition CLOSE_P OPEN_C
        {
            int label_true = counter++;
            int label_false = counter++;
            int label_end = counter++;

            System.out.println("    ; if condition");
            System.out.println("    if_icmpeq label_" + label_true);
            System.out.println("    goto label_" + label_false);
            System.out.println("label_" + label_true + ":");
        }
        ( statement )*
    CLOSE_C
        {
            System.out.println("    goto label_" + label_end);
            System.out.println("label_" + label_false + ":");
        }
    ( 'or' OPEN_P condition CLOSE_P OPEN_C
        {
            int label_true_else_if = counter++;
            int label_false_else_if = counter++;

            System.out.println("    ; else if condition");
            System.out.println("    if_icmpeq label_" + label_true_else_if);
            System.out.println("    goto label_" + label_false_else_if);
            System.out.println("label_" + label_true_else_if + ":");
        }
        ( statement )*
    CLOSE_C
        {
            System.out.println("    goto label_" + label_end);
            System.out.println("label_" + label_false_else_if + ":");
        }
    )*
    ( 'not' OPEN_C
        {
            System.out.println("    ; else block");
        }
        ( statement )*
        CLOSE_C
        {
            System.out.println("    ; end else block");
        }
    )?
        {
            System.out.println("label_" + label_end + ":"); // Rótulo para o fim do if-else
        }
   ;

statement_while
   : 'aslong' OPEN_P
        {
            int label_start = counter++;
            int label_end = counter++;
            System.out.println("label_" + label_start + ":");
        }
        condition CLOSE_P OPEN_C
        {
            System.out.println("    if_icmpge label_" + (counter - 1));
        }
        ( statement )*
    CLOSE_C
        {
            System.out.println("    goto label_" + (counter - 2));
            System.out.println("label_" + (counter - 1) + ":");
        }
   ;

statement_print
   : PRINT OPEN_P STRING CLOSE_P
        {
            System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
            System.out.println("    ldc " + $STRING.text);
            System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
        }
   | PRINT OPEN_P DOUBLE CLOSE_P
        {
            System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
            System.out.println("    ldc2_w " + $DOUBLE.text);
            System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
        }
   | PRINT OPEN_P value CLOSE_P
        {
            System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
            if ($value.valueType.equals("INT")) {
                System.out.println("    ldc " + $value.text);
                System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
            } else if ($value.valueType.equals("DOUBLE")) {
                System.out.println("    ldc2_w " + $value.text);
                System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
            } else if ($value.valueType.equals("VAR")) {
                Integer v = memory.get($value.text);
                if (v != null) {
                    String varType = variableTypes.get($value.text);
                    if (varType != null && varType.equals("double")) {
                        System.out.println("    dload " + v);
                        System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
                    } else if (varType != null && varType.equals("string")) {
                        System.out.println("    aload " + v);
                        System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
                    } else {
                        System.out.println("    iload " + v);
                        System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
                    }
                } else {
                    System.err.println("undefined variable " + $value.text);
                }
            } else if ($value.valueType.equals("STRING_VAR")) {
                Integer v = memory.get($value.text);
                if (v != null) {
                    System.out.println("    aload " + v);
                    System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
                } else {
                    System.err.println("undefined variable " + $value.text);
                }
            } else if ($value.valueType.equals("DOUBLE_VAR")) {
                Integer v = memory.get($value.text);
                if (v != null) {
                    System.out.println("    dload " + v);
                    System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
                } else {
                    System.err.println("undefined variable " + $value.text);
                }
            } else if ($value.valueType.equals("FUNCTION_CALL")) {
                // A função já foi chamada e o resultado está na pilha
                System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
            } else if ($value.valueType.equals("READ_INT")) {
                // A leitura já foi feita e o resultado está na pilha
                System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
            } else if ($value.valueType.equals("READ_DOUBLE")) {
                // A leitura já foi feita e o resultado está na pilha
                System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
            } else if ($value.valueType.equals("READ_STRING")) {
                // A leitura já foi feita e o resultado está na pilha
                System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
            } else if ($value.valueType.equals("ARRAY_LENGTH")) {
                // Gerar instruções para array.size()
                Integer v = memory.get($value.text);
                if (v != null) {
                    System.out.println("    aload " + v);
                    System.out.println("    invokevirtual java/util/ArrayList/size()I");
                    System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
                } else {
                    System.err.println("undefined variable " + $value.text);
                }
            }
        }
   | PRINT OPEN_P
        {
            System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
        }
        expression CLOSE_P
        {
            System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
        }
   ;

statement_textcolor
   : TEXTCOLOR OPEN_P NUM CLOSE_P
            {
                int color = Integer.parseInt($NUM.text);
                if (color >= 0 && color <= 16) {
                    System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
                    System.out.println("    ldc \"\\u001B[3" + color + "m\"");
                    System.out.println("    invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V");
                } else {
                    throw new IllegalArgumentException("Invalid color code: " + color);
                }
            }
   ;

condition
   : expression ( '==' | '!=' | '<' | '<=' | '>' | '>=' ) expression
        {
            switch ($text) {
                case "==": System.out.println("    if_icmpeq label_" + counter); break;
                case "!=": System.out.println("    if_icmpne label_" + counter); break;
                case "<":  System.out.println("    if_icmplt label_" + counter); break;
                case "<=": System.out.println("    if_icmple label_" + counter); break;
                case ">":  System.out.println("    if_icmpgt label_" + counter); break;
                case ">=": System.out.println("    if_icmpge label_" + counter); break;
            }
        }
   ;

expression
   :   term ( op = ( PLUS | MINUS ) term
           { 
               if (inFunction) {
                   functionBodyBuilder.append(($op.type == PLUS) ? "    iadd\n" : "    isub\n");
               } else {
                   System.out.println(($op.type == PLUS) ? "    iadd" : "    isub"); 
               }
           }
       )*
   ;

term
   :   factor ( op = ( TIMES | OVER ) factor
            { 
                if (inFunction) {
                    functionBodyBuilder.append(($op.type == TIMES) ? "    imul\n" : "    idiv\n");
                } else {
                    System.out.println(($op.type == TIMES) ? "    imul" : "    idiv"); 
                }
            }
       )*
   ;

factor
   :   NUM
            { 
                if (inFunction) {
                    functionBodyBuilder.append("    ldc " + $NUM.text + "\n");
                } else {
                    System.out.println("    ldc " + $NUM.text); 
                }
            }
   |   VAR
            {
                Integer v = memory.get($VAR.text);
                if (v != null) {
                    String varType = variableTypes.get($VAR.text);
                    if (varType != null) {
                        if (varType.equals("double")) {
                            if (inFunction) {
                                functionBodyBuilder.append("    dload " + v.intValue() + "\n");
                            } else {
                                System.out.println("    dload " + v.intValue());
                            }
                        } else if (varType.equals("string")) {
                            if (inFunction) {
                                functionBodyBuilder.append("    aload " + v.intValue() + "\n");
                            } else {
                                System.out.println("    aload " + v.intValue());
                            }
                        } else {
                            if (inFunction) {
                                functionBodyBuilder.append("    iload " + v.intValue() + "\n");
                            } else {
                                System.out.println("    iload " + v.intValue());
                            }
                        }
                    } else {
                        // Tipo não definido, assume int
                        if (inFunction) {
                            functionBodyBuilder.append("    iload " + v.intValue() + "\n");
                        } else {
                            System.out.println("    iload " + v.intValue());
                        }
                    }
                } else {
                    System.err.println("undefined variable " + $VAR.text);
                }
            }
   |   STRING
            { 
                if (inFunction) {
                    functionBodyBuilder.append("    ldc " + $STRING.text + "\n");
                } else {
                    System.out.println("    ldc " + $STRING.text); 
                }
            }
   |   DOUBLE
            { 
                if (inFunction) {
                    functionBodyBuilder.append("    ldc2_w " + $DOUBLE.text + "\n");
                } else {
                    System.out.println("    ldc2_w " + $DOUBLE.text); 
                }
            }
   |   read_int
   |   read_double
   |   read_string
   |   function_call
   |   array_get
   |   array_length
   ;

array_push
   : ARRAY_PUSH OPEN_P VAR COMMA
       {
           // Carrega o array primeiro
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("array")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
               } else {
                   System.out.println("    aload " + v);
               }
           } else {
               System.err.println("Variable " + $VAR.text + " is not an array or undefined");
           }
       }
       expression CLOSE_P
       {
           // Agora temos [array, value] na pilha - executar o add
           if (inFunction) {
               functionBodyBuilder.append("    invokestatic java/lang/Integer/valueOf(I)Ljava/lang/Integer;\n");
               functionBodyBuilder.append("    invokevirtual java/util/ArrayList/add(Ljava/lang/Object;)Z\n");
               functionBodyBuilder.append("    pop\n"); // remove o boolean retornado
           } else {
               System.out.println("    invokestatic java/lang/Integer/valueOf(I)Ljava/lang/Integer;");
               System.out.println("    invokevirtual java/util/ArrayList/add(Ljava/lang/Object;)Z");
               System.out.println("    pop"); // remove o boolean retornado
           }
       }
   ;

array_pop
   : ARRAY_POP OPEN_P VAR CLOSE_P
       {
           // arr.remove(arr.size()-1) - remove último elemento
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("array")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
                   functionBodyBuilder.append("    dup\n");
                   functionBodyBuilder.append("    invokevirtual java/util/ArrayList/size()I\n");
                   functionBodyBuilder.append("    iconst_1\n");
                   functionBodyBuilder.append("    isub\n");
                   functionBodyBuilder.append("    invokevirtual java/util/ArrayList/remove(I)Ljava/lang/Object;\n");
                   functionBodyBuilder.append("    pop\n"); // remove o objeto retornado
               } else {
                   System.out.println("    aload " + v);
                   System.out.println("    dup");
                   System.out.println("    invokevirtual java/util/ArrayList/size()I");
                   System.out.println("    iconst_1");
                   System.out.println("    isub");
                   System.out.println("    invokevirtual java/util/ArrayList/remove(I)Ljava/lang/Object;");
                   System.out.println("    pop"); // remove o objeto retornado
               }
           } else {
               System.err.println("Variable " + $VAR.text + " is not an array or undefined");
           }
       }
   ;

array_set
   : ARRAY_SET OPEN_P VAR COMMA
       {
           // Carrega o array primeiro
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("array")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
               } else {
                   System.out.println("    aload " + v);
               }
           } else {
               System.err.println("Variable " + $VAR.text + " is not an array or undefined");
           }
       }
       expression COMMA
       {
           // Agora carregamos o valor
       }
       expression CLOSE_P
       {
           // Agora temos [array, index, value] na pilha
           // Precisamos reorganizar para [array, index, Integer.valueOf(value)]
           if (inFunction) {
               functionBodyBuilder.append("    invokestatic java/lang/Integer/valueOf(I)Ljava/lang/Integer;\n");
               functionBodyBuilder.append("    invokevirtual java/util/ArrayList/set(ILjava/lang/Object;)Ljava/lang/Object;\n");
               functionBodyBuilder.append("    pop\n"); // remove o objeto anterior retornado
           } else {
               System.out.println("    invokestatic java/lang/Integer/valueOf(I)Ljava/lang/Integer;");
               System.out.println("    invokevirtual java/util/ArrayList/set(ILjava/lang/Object;)Ljava/lang/Object;");
               System.out.println("    pop"); // remove o objeto anterior retornado
           }
       }
   ;

array_get returns [String valueType, String text]
   : ARRAY_GET OPEN_P VAR COMMA
       {
           // Primeiro carregamos o array
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("array")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
               } else {
                   System.out.println("    aload " + v);
               }
           } else {
               System.err.println("Variable " + $VAR.text + " is not an array or undefined");
           }
       }
       expression CLOSE_P
       {
           // Agora temos array na posição 0 da pilha e index na posição 1
           // ArrayList.get(int) espera [array, index] na pilha
           if (inFunction) {
               functionBodyBuilder.append("    invokevirtual java/util/ArrayList/get(I)Ljava/lang/Object;\n");
               functionBodyBuilder.append("    checkcast java/lang/Integer\n");
               functionBodyBuilder.append("    invokevirtual java/lang/Integer/intValue()I\n");
           } else {
               System.out.println("    invokevirtual java/util/ArrayList/get(I)Ljava/lang/Object;");
               System.out.println("    checkcast java/lang/Integer");
               System.out.println("    invokevirtual java/lang/Integer/intValue()I");
           }
           $valueType = "ARRAY_GET";
           $text = $VAR.text;
       }
   ;

array_length returns [String valueType, String text]
    : ARRAY_LENGTH OPEN_P VAR CLOSE_P
       {
           // Carrega o array primeiro
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("array")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
               } else {
                   System.out.println("    aload " + v);
               }
           } else {
               System.err.println("Variable " + $VAR.text + " is not an array or undefined");
           }
       }
       {
           // Agora temos o array na pilha, vamos obter o tamanho
           if (inFunction) {
               functionBodyBuilder.append("    invokevirtual java/util/ArrayList/size()I\n");
           } else {
               System.out.println("    invokevirtual java/util/ArrayList/size()I");
           }
           $valueType = "ARRAY_LENGTH";
           $text = $VAR.text;
       }
    ;

read_statement
   : VAR ATTRIB READ_INT OPEN_P CLOSE_P
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, "int");
           }
           if (inFunction) {
               functionBodyBuilder.append("    getstatic ROSATest/scanner Ljava/util/Scanner;\n");
               functionBodyBuilder.append("    invokevirtual java/util/Scanner/nextInt()I\n");
               functionBodyBuilder.append("    istore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    getstatic ROSATest/scanner Ljava/util/Scanner;");
               System.out.println("    invokevirtual java/util/Scanner/nextInt()I");
               System.out.println("    istore " + memory.get($VAR.text));
           }
       }
   | VAR ATTRIB READ_DOUBLE OPEN_P CLOSE_P
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter);
               counter += 2; // Double ocupa 2 slots
               variableTypes.put($VAR.text, "double");
           }
           if (inFunction) {
               functionBodyBuilder.append("    getstatic ROSATest/scanner Ljava/util/Scanner;\n");
               functionBodyBuilder.append("    invokevirtual java/util/Scanner/nextDouble()D\n");
               functionBodyBuilder.append("    dstore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    getstatic ROSATest/scanner Ljava/util/Scanner;");
               System.out.println("    invokevirtual java/util/Scanner/nextDouble()D");
               System.out.println("    dstore " + memory.get($VAR.text));
           }
       }
   | VAR ATTRIB READ_STRING OPEN_P CLOSE_P
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, "string");
           }
           if (inFunction) {
               functionBodyBuilder.append("    getstatic ROSATest/scanner Ljava/util/Scanner;\n");
               functionBodyBuilder.append("    invokevirtual java/util/Scanner/next()Ljava/lang/String;\n");
               functionBodyBuilder.append("    astore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    getstatic ROSATest/scanner Ljava/util/Scanner;");
               System.out.println("    invokevirtual java/util/Scanner/next()Ljava/lang/String;");
               System.out.println("    astore " + memory.get($VAR.text));
           }
       }
   ;

read_int returns [String valueType, String text]
   :   READ_INT OPEN_P CLOSE_P
            {
                if (inFunction) {
                    functionBodyBuilder.append("    getstatic ROSATest/scanner Ljava/util/Scanner;\n");
                    functionBodyBuilder.append("    invokevirtual java/util/Scanner/nextInt()I\n");
                } else {
                    System.out.println("    getstatic ROSATest/scanner Ljava/util/Scanner;");
                    System.out.println("    invokevirtual java/util/Scanner/nextInt()I");
                }
                $valueType = "READ_INT";
                $text = "read_int()";
            }
    ;

read_double returns [String valueType, String text]
   :   READ_DOUBLE OPEN_P CLOSE_P
            {
                if (inFunction) {
                    functionBodyBuilder.append("    getstatic ROSATest/scanner Ljava/util/Scanner;\n");
                    functionBodyBuilder.append("    invokevirtual java/util/Scanner/nextDouble()D\n");
                } else {
                    System.out.println("    getstatic ROSATest/scanner Ljava/util/Scanner;");
                    System.out.println("    invokevirtual java/util/Scanner/nextDouble()D");
                }
                $valueType = "READ_DOUBLE";
                $text = "read_double()";
            }
    ;

read_string returns [String valueType, String text]
    : READ_STRING OPEN_P CLOSE_P
            {
                 if (inFunction) {
                      functionBodyBuilder.append("    getstatic ROSATest/scanner Ljava/util/Scanner;\n");
                      functionBodyBuilder.append("    invokevirtual java/util/Scanner/next()Ljava/lang/String;\n");
                 } else {
                      System.out.println("    getstatic ROSATest/scanner Ljava/util/Scanner;");
                      System.out.println("    invokevirtual java/util/Scanner/next()Ljava/lang/String;");
                 }
                 $valueType = "READ_STRING";
                 $text = "read_string()";
            }
    ;