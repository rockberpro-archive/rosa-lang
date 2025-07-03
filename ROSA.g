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
   Map<String, Integer> memory = new LinkedHashMap<String, Integer>(); // Para armazenar parâmetros e variáveis
   Map<String, String> variableTypes = new LinkedHashMap<String, String>(); // Para armazenar tipos das variáveis
   Map<String, String> arrayElementTypes = new LinkedHashMap<String, String>(); // Para armazenar tipos dos elementos dos arrays
   Map<String, Integer> functions = new LinkedHashMap<String, Integer>(); // Para armazenar funções
   Map<String, String> functionBodies = new LinkedHashMap<String, String>(); // Para armazenar corpos das funções
   Map<String, ArrayList<String>> functionParameters = new LinkedHashMap<String, ArrayList<String>>(); // Para armazenar parâmetros das funções
   Map<String, ArrayList<String>> functionParameterTypes = new LinkedHashMap<String, ArrayList<String>>(); // Para armazenar tipos dos parâmetros
   Integer counter = 1; // Contador para slots de memória
   Integer functionCounter = 1; // Contador para funções
   boolean inFunction = false; // Indica se estamos dentro de uma função
   StringBuilder functionBodyBuilder = new StringBuilder(); // Para construir o corpo da função
   String currentFunctionName = ""; // Nome da função atual
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
DOT       : '.' ;
OPEN_C    : '{' ;
CLOSE_C   : '}' ;
OPEN_P    : '(' ;
CLOSE_P   : ')' ;
ATTRIB    : '=' ;


MAIN      : 'main' ;
PRINT     : 'print' ;
TEXTCOLOR : 'textcolor';
BEEP      : 'beep' ;
FUNCTION  : 'procedure' ;
RETURN    : 'return' ;
CALL      : 'call' ;
COMMA     : ',' ;
GOTO      : 'goto' ;
LABEL     : 'label' ;
COLON     : ':' ;

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

// Tokens para operações de string
CHARAT      : 'charat' ;
LENGTH      : 'length' ;
COMPARE     : 'compare' ;

// Tokens para valores booleanos
TRUE        : 'true' ;
FALSE       : 'false' ;
BOOLEAN_TYPE : 'boolean' ;

VAR     : 'a'..'z'+ ;
NUM     : '0'..'9' + ;
NL      : ('\r')? '\n' { skip(); } ;
SPACE   : (' '|'\t')+ { skip(); } ;
STRING  : '"' ('\\' . | ~('\\'|'"'))* '"' ;
DOUBLE  : ('0'..'9')+ '.' ('0'..'9')+ ;


/*---------------- PARSER RULES ----------------*/

statement
   : assignment           |
     typed_assignment     |
     statement_print      |
     statement_textcolor  |
     statement_beep       |
     statement_if         |
     statement_while      |
     statement_goto       |
     statement_label      |
     function_call        |
     array_push           |
     array_pop            |
     array_set            |
     array_get            |
     read_statement
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

program
   : NL* (function_def NL*)* main NL* (function_def NL*)*
       {
           // Gera as funções no final
           for (String funcName : functions.keySet()) {
               // Construir assinatura da função
               StringBuilder signature = new StringBuilder();
               signature.append(".method public static ").append(funcName).append("(");
               
               if (functionParameterTypes.containsKey(funcName)) {
                   ArrayList<String> paramTypes = functionParameterTypes.get(funcName);
                   for (String paramType : paramTypes) {
                       if (paramType.equals("int")) {
                           signature.append("I");
                       } else if (paramType.equals("double")) {
                           signature.append("D");
                       } else if (paramType.equals("string")) {
                           signature.append("Ljava/lang/String;");
                       } else if (paramType.equals("array")) {
                           signature.append("Ljava/util/ArrayList;");
                       } else if (paramType.equals("boolean")) {
                           signature.append("Z");
                       }
                   }
               }
               signature.append(")I");
               
               System.out.println(signature.toString());
               System.out.println(".limit stack 20");
               System.out.println(".limit locals 20");
               
               // Gerar código para armazenar parâmetros nas variáveis locais
               if (functionParameters.containsKey(funcName)) {
                   ArrayList<String> params = functionParameters.get(funcName);
                   ArrayList<String> paramTypes = functionParameterTypes.get(funcName);
                   for (int i = 0; i < params.size(); i++) {
                       String paramName = params.get(i);
                       String paramType = paramTypes.get(i);
                       Integer slot = memory.get(paramName);
                       if (slot != null) {
                           if (paramType.equals("int")) {
                               System.out.println("    iload " + i);
                               System.out.println("    istore " + slot);
                           } else if (paramType.equals("double")) {
                               System.out.println("    dload " + i);
                               System.out.println("    dstore " + slot);
                           } else if (paramType.equals("string")) {
                               System.out.println("    aload " + i);
                               System.out.println("    astore " + slot);
                           } else if (paramType.equals("array")) {
                               System.out.println("    aload " + i);
                               System.out.println("    astore " + slot);
                           } else if (paramType.equals("boolean")) {
                               System.out.println("    iload " + i);
                               System.out.println("    istore " + slot);
                           }
                       }
                   }
               }
               
               System.out.println(functionBodies.get(funcName));
               System.out.println("    ldc 0");
               System.out.println("    ireturn");
               System.out.println(".end method\n");
           }
       }
   ;

condition returns [String operator]
   : expression op = ( '==' | '!=' | '<' | '<=' | '>' | '>=' ) expression
        {
            $operator = $op.text;
        }
   ;

expression
   :   concat_expr ( op = ( PLUS | MINUS ) concat_expr
           { 
               if (inFunction) {
                   functionBodyBuilder.append(($op.type == PLUS) ? "    iadd\n" : "    isub\n");
               } else {
                   System.out.println(($op.type == PLUS) ? "    iadd" : "    isub"); 
               }
           }
       )*
   ;

concat_expr
   :   term ( DOT term
           {
               // String concatenation: stack starts as [left_operand, right_operand]
               // We want to call left_operand.concat(String.valueOf(right_operand))
               if (inFunction) {
                   functionBodyBuilder.append("    invokestatic java/lang/String/valueOf(I)Ljava/lang/String;\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/String/concat(Ljava/lang/String;)Ljava/lang/String;\n");
               } else {
                   System.out.println("    invokestatic java/lang/String/valueOf(I)Ljava/lang/String;");
                   System.out.println("    invokevirtual java/lang/String/concat(Ljava/lang/String;)Ljava/lang/String;");
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
                        } else if (varType.equals("array")) {
                            if (inFunction) {
                                functionBodyBuilder.append("    aload " + v.intValue() + "\n");
                            } else {
                                System.out.println("    aload " + v.intValue());
                            }
                        } else if (varType.equals("boolean")) {
                            if (inFunction) {
                                functionBodyBuilder.append("    iload " + v.intValue() + "\n");
                            } else {
                                System.out.println("    iload " + v.intValue());
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
   |   charat
   |   length
   |   compare
   |   TRUE
            { 
                if (inFunction) {
                    functionBodyBuilder.append("    iconst_1\n");
                } else {
                    System.out.println("    iconst_1"); 
                }
            }
   |   FALSE
            { 
                if (inFunction) {
                    functionBodyBuilder.append("    iconst_0\n");
                } else {
                    System.out.println("    iconst_0"); 
                }
            }
   ;

function_def
   : FUNCTION VAR 
       {
           String funcName = $VAR.text;
           currentFunctionName = funcName;
           if (!functions.containsKey(funcName)) {
               functions.put(funcName, functionCounter++);
               functionBodies.put(funcName, "");
           }
           inFunction = true;
           functionBodyBuilder = new StringBuilder();
       }
       OPEN_P (parameter_list)? CLOSE_P NL* OPEN_C
       NL* (statement NL*)*
       (return_statement NL*)?
   CLOSE_C
       {
           inFunction = false;
           // Armazena o corpo da função para gerar depois
           functionBodies.put(currentFunctionName, functionBodyBuilder.toString());
           currentFunctionName = "";
       }
   ;

parameter_list
   : typed_parameter (COMMA typed_parameter)*
   ;

typed_parameter
   : type_spec VAR
       {
           if (!functionParameters.containsKey(currentFunctionName)) {
               functionParameters.put(currentFunctionName, new ArrayList<String>());
               functionParameterTypes.put(currentFunctionName, new ArrayList<String>());
           }
           functionParameters.get(currentFunctionName).add($VAR.text);
           
           String paramType = $type_spec.typeValue;
           functionParameterTypes.get(currentFunctionName).add(paramType);
           
           // Adicionar parâmetro à memória local da função
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, paramType);
               if (paramType.equals("double")) {
                   counter++; // Double ocupa 2 slots
               }
           }
       }
   ;

type_spec returns [String typeValue]
   : INT_TYPE    { $typeValue = "int"; }
   | DOUBLE_TYPE { $typeValue = "double"; }
   | STRING_TYPE { $typeValue = "string"; }
   | ARRAY_TYPE  { $typeValue = "array"; }
   | BOOLEAN_TYPE { $typeValue = "boolean"; }
   ;

return_statement
   : RETURN expression
       {
           if (inFunction) {
               functionBodyBuilder.append("    ireturn\n");
           } else {
               System.out.println("    ireturn");
           }
       }
   ;

function_call returns [String valueType, String text]
   : CALL VAR OPEN_P (argument_list)? CLOSE_P
       {
           String funcName = $VAR.text;
           if (functions.containsKey(funcName) || inFunction) {
               // Construir assinatura da função com parâmetros
               StringBuilder signature = new StringBuilder();
               signature.append("    invokestatic ROSATest/").append(funcName).append("(");
               
               if (functionParameterTypes.containsKey(funcName)) {
                   ArrayList<String> paramTypes = functionParameterTypes.get(funcName);
                   for (String paramType : paramTypes) {
                       if (paramType.equals("int")) {
                           signature.append("I");
                       } else if (paramType.equals("double")) {
                           signature.append("D");
                       } else if (paramType.equals("string")) {
                           signature.append("Ljava/lang/String;");
                       } else if (paramType.equals("array")) {
                           signature.append("Ljava/util/ArrayList;");
                       } else if (paramType.equals("boolean")) {
                           signature.append("Z");
                       }
                   }
               }
               signature.append(")I");
               
               if (inFunction) {
                   functionBodyBuilder.append(signature.toString()).append("\n");
               } else {
                   System.out.println(signature.toString());
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
               } else if ($value.valueType.equals("BOOLEAN") || $value.valueType.equals("BOOLEAN_VAR")) {
                   variableTypes.put($VAR.text, "boolean");
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
   | BOOLEAN_TYPE VAR ATTRIB value
       {
           if (!memory.containsKey($VAR.text)) {
               memory.put($VAR.text, counter++);
               variableTypes.put($VAR.text, "boolean");
           }
           if (inFunction) {
               functionBodyBuilder.append("    istore " + memory.get($VAR.text) + "\n");
           } else {
               System.out.println("    istore " + memory.get($VAR.text));
           }
       }
   ;

value returns [String valueType, String text]
   : simple_value ( DOT simple_value
           {
               // String concatenation: stack starts as [left_operand, right_operand]
               // We want to call left_operand.concat(String.valueOf(right_operand))
               if (inFunction) {
                   functionBodyBuilder.append("    invokestatic java/lang/String/valueOf(I)Ljava/lang/String;\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/String/concat(Ljava/lang/String;)Ljava/lang/String;\n");
               } else {
                   System.out.println("    invokestatic java/lang/String/valueOf(I)Ljava/lang/String;");
                   System.out.println("    invokevirtual java/lang/String/concat(Ljava/lang/String;)Ljava/lang/String;");
               }
               $valueType = "STRING";
           }
       )*
       {
           if ($valueType == null) {
               $valueType = $simple_value.valueType;
               $text = $simple_value.text;
           }
       }
   ;

simple_value returns [String valueType, String text]
   : STRING { 
                if (inFunction) {
                    functionBodyBuilder.append("    ldc " + $STRING.text + "\n");
                } else {
                    System.out.println("    ldc " + $STRING.text);
                }
                $valueType = "STRING"; $text = $STRING.text; 
            }
   | NUM    { 
                if (inFunction) {
                    functionBodyBuilder.append("    ldc " + $NUM.text + "\n");
                } else {
                    System.out.println("    ldc " + $NUM.text);
                }
                $valueType = "INT";    $text = $NUM.text; 
            }
   | DOUBLE { 
                if (inFunction) {
                    functionBodyBuilder.append("    ldc2_w " + $DOUBLE.text + "\n");
                } else {
                    System.out.println("    ldc2_w " + $DOUBLE.text);
                }
                $valueType = "DOUBLE"; $text = $DOUBLE.text; 
            }
   | VAR    {
                Integer v = memory.get($VAR.text);
                if (v != null) {
                    String varType = variableTypes.get($VAR.text);
                    if (varType != null && varType.equals("double")) {
                        if (inFunction) {
                            functionBodyBuilder.append("    dload " + v + "\n");
                        } else {
                            System.out.println("    dload " + v);
                        }
                        $valueType = "DOUBLE_VAR";
                    } else if (varType != null && varType.equals("string")) {
                        if (inFunction) {
                            functionBodyBuilder.append("    aload " + v + "\n");
                        } else {
                            System.out.println("    aload " + v);
                        }
                        $valueType = "STRING_VAR";
                    } else if (varType != null && varType.equals("boolean")) {
                        if (inFunction) {
                            functionBodyBuilder.append("    iload " + v + "\n");
                        } else {
                            System.out.println("    iload " + v);
                        }
                        $valueType = "BOOLEAN_VAR";
                    } else {
                        if (inFunction) {
                            functionBodyBuilder.append("    iload " + v + "\n");
                        } else {
                            System.out.println("    iload " + v);
                        }
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
   | charat { $valueType = $charat.valueType; $text = $charat.text; }
   | length { $valueType = $length.valueType; $text = $length.text; }
   | compare { $valueType = $compare.valueType; $text = $compare.text; }
   | TRUE { 
                if (inFunction) {
                    functionBodyBuilder.append("    iconst_1\n");
                } else {
                    System.out.println("    iconst_1");
                }
                $valueType = "BOOLEAN"; $text = "true"; 
            }
   | FALSE { 
                if (inFunction) {
                    functionBodyBuilder.append("    iconst_0\n");
                } else {
                    System.out.println("    iconst_0");
                }
                $valueType = "BOOLEAN"; $text = "false"; 
            }
   ;

statement_if
   : 'is' OPEN_P condition CLOSE_P OPEN_C
        {
            int label_true = counter++;
            int label_false = counter++;
            int label_end = counter++;

            // Gera a instrução de comparação baseada no operador
            String operator = $condition.operator;
            String jumpInstr = "";
            
            if (operator.equals("==")) {
                jumpInstr = "if_icmpne";
            } else if (operator.equals("!=")) {
                jumpInstr = "if_icmpeq";
            } else if (operator.equals("<")) {
                jumpInstr = "if_icmpge";
            } else if (operator.equals("<=")) {
                jumpInstr = "if_icmpgt";
            } else if (operator.equals(">")) {
                jumpInstr = "if_icmple";
            } else if (operator.equals(">=")) {
                jumpInstr = "if_icmplt";
            }

            if (inFunction) {
                functionBodyBuilder.append("    ; if condition\n");
                functionBodyBuilder.append("    " + jumpInstr + " label_" + label_false + "\n");
                functionBodyBuilder.append("label_" + label_true + ":\n");
            } else {
                System.out.println("    ; if condition");
                System.out.println("    " + jumpInstr + " label_" + label_false);
                System.out.println("label_" + label_true + ":");
            }
        }
        ( statement )*
    CLOSE_C
        {
            if (inFunction) {
                functionBodyBuilder.append("    goto label_" + label_end + "\n");
                functionBodyBuilder.append("label_" + label_false + ":\n");
            } else {
                System.out.println("    goto label_" + label_end);
                System.out.println("label_" + label_false + ":");
            }
        }
    ( 'or' OPEN_P condition CLOSE_P OPEN_C
        {
            int label_true_else_if = counter++;
            int label_false_else_if = counter++;

            // Gera a instrução de comparação baseada no operador para else if
            String elseIfOperator = $condition.operator;
            String elseIfJumpInstr = "";
            
            if (elseIfOperator.equals("==")) {
                elseIfJumpInstr = "if_icmpne";
            } else if (elseIfOperator.equals("!=")) {
                elseIfJumpInstr = "if_icmpeq";
            } else if (elseIfOperator.equals("<")) {
                elseIfJumpInstr = "if_icmpge";
            } else if (elseIfOperator.equals("<=")) {
                elseIfJumpInstr = "if_icmpgt";
            } else if (elseIfOperator.equals(">")) {
                elseIfJumpInstr = "if_icmple";
            } else if (elseIfOperator.equals(">=")) {
                elseIfJumpInstr = "if_icmplt";
            }

            if (inFunction) {
                functionBodyBuilder.append("    ; else if condition\n");
                functionBodyBuilder.append("    " + elseIfJumpInstr + " label_" + label_false_else_if + "\n");
                functionBodyBuilder.append("label_" + label_true_else_if + ":\n");
            } else {
                System.out.println("    ; else if condition");
                System.out.println("    " + elseIfJumpInstr + " label_" + label_false_else_if);
                System.out.println("label_" + label_true_else_if + ":");
            }
        }
        ( statement )*
    CLOSE_C
        {
            if (inFunction) {
                functionBodyBuilder.append("    goto label_" + label_end + "\n");
                functionBodyBuilder.append("label_" + label_false_else_if + ":\n");
            } else {
                System.out.println("    goto label_" + label_end);
                System.out.println("label_" + label_false_else_if + ":");
            }
        }
    )*
    ( 'not' OPEN_C
        {
            if (inFunction) {
                functionBodyBuilder.append("    ; else block\n");
            } else {
                System.out.println("    ; else block");
            }
        }
        ( statement )*
        CLOSE_C
        {
            if (inFunction) {
                functionBodyBuilder.append("    ; end else block\n");
            } else {
                System.out.println("    ; end else block");
            }
        }
    )?
        {
            if (inFunction) {
                functionBodyBuilder.append("label_" + label_end + ":\n"); // Rótulo para o fim do if-else
            } else {
                System.out.println("label_" + label_end + ":"); // Rótulo para o fim do if-else
            }
        }
   ;

statement_while
   : 'aslong' OPEN_P
        {
            int label_start = counter++;
            int label_end = counter++;
            if (inFunction) {
                functionBodyBuilder.append("label_" + label_start + ":\n");
            } else {
                System.out.println("label_" + label_start + ":");
            }
        }
        expression op = ( '==' | '!=' | '<' | '<=' | '>' | '>=' ) expression CLOSE_P OPEN_C
        {
            // Gera a instrução de comparação baseada no operador
            String operator = $op.text;
            if (operator.equals("<=")) {
                if (inFunction) {
                    functionBodyBuilder.append("    if_icmpgt label_" + label_end + "\n");
                } else {
                    System.out.println("    if_icmpgt label_" + label_end);
                }
            } else if (operator.equals(">=")) {
                if (inFunction) {
                    functionBodyBuilder.append("    if_icmplt label_" + label_end + "\n");
                } else {
                    System.out.println("    if_icmplt label_" + label_end);
                }
            } else if (operator.equals("<")) {
                if (inFunction) {
                    functionBodyBuilder.append("    if_icmpge label_" + label_end + "\n");
                } else {
                    System.out.println("    if_icmpge label_" + label_end);
                }
            } else if (operator.equals(">")) {
                if (inFunction) {
                    functionBodyBuilder.append("    if_icmple label_" + label_end + "\n");
                } else {
                    System.out.println("    if_icmple label_" + label_end);
                }
            } else if (operator.equals("==")) {
                if (inFunction) {
                    functionBodyBuilder.append("    if_icmpne label_" + label_end + "\n");
                } else {
                    System.out.println("    if_icmpne label_" + label_end);
                }
            } else if (operator.equals("!=")) {
                if (inFunction) {
                    functionBodyBuilder.append("    if_icmpeq label_" + label_end + "\n");
                } else {
                    System.out.println("    if_icmpeq label_" + label_end);
                }
            }
        }
        ( statement )*
    CLOSE_C
        {
            if (inFunction) {
                functionBodyBuilder.append("    goto label_" + label_start + "\n");
                functionBodyBuilder.append("label_" + label_end + ":\n");
            } else {
                System.out.println("    goto label_" + label_start);
                System.out.println("label_" + label_end + ":");
            }
        }
   ;

statement_print
   : PRINT OPEN_P STRING CLOSE_P
        {
            if (inFunction) {
                functionBodyBuilder.append("    getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                functionBodyBuilder.append("    ldc " + $STRING.text + "\n");
                functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
            } else {
                System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
                System.out.println("    ldc " + $STRING.text);
                System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
            }
        }
   | PRINT OPEN_P DOUBLE CLOSE_P
        {
            System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
            System.out.println("    ldc2_w " + $DOUBLE.text);
            System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
        }
   | PRINT OPEN_P value CLOSE_P
        {
            if (inFunction) {
                if ($value.valueType.equals("DOUBLE_VAR") || $value.valueType.equals("DOUBLE")) {
                    // Para doubles, não usar getstatic antes, fazer depois
                    functionBodyBuilder.append("    getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                    functionBodyBuilder.append("    dup_x2\n");  // duplica PrintStream abaixo do double
                    functionBodyBuilder.append("    pop\n");    // remove PrintStream do topo
                    functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(D)V\n");
                } else {
                    functionBodyBuilder.append("    getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                    functionBodyBuilder.append("    swap\n"); // value já está na pilha, então swap para colocar PrintStream por baixo
                    if ($value.valueType.equals("VAR") || $value.valueType.equals("INT")) {
                        functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(I)V\n");
                    } else if ($value.valueType.equals("STRING_VAR") || $value.valueType.equals("STRING")) {
                        functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                    } else if ($value.valueType.equals("BOOLEAN") || $value.valueType.equals("BOOLEAN_VAR")) {
                        functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(Z)V\n");
                    } else if ($value.valueType.equals("ARRAY_LENGTH") || $value.valueType.equals("ARRAY_GET")) {
                        functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(I)V\n");
                    } else if ($value.valueType.equals("ARRAY_GET_STRING")) {
                        functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                    } else if ($value.valueType.equals("ARRAY_GET_DOUBLE")) {
                        functionBodyBuilder.append("    dup_x2\n");  // duplica PrintStream abaixo do double
                        functionBodyBuilder.append("    pop\n");    // remove PrintStream do topo
                        functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(D)V\n");
                    }
                }
            } else {
                if ($value.valueType.equals("DOUBLE_VAR") || $value.valueType.equals("DOUBLE")) {
                    // Para doubles, não usar getstatic antes, fazer depois
                    System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
                    System.out.println("    dup_x2");  // duplica PrintStream abaixo do double
                    System.out.println("    pop");     // remove PrintStream do topo
                    System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
                } else {
                    System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
                    System.out.println("    swap"); // value já está na pilha, então swap para colocar PrintStream por baixo
                    if ($value.valueType.equals("VAR") || $value.valueType.equals("INT")) {
                        System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
                    } else if ($value.valueType.equals("STRING_VAR") || $value.valueType.equals("STRING")) {
                        System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
                    } else if ($value.valueType.equals("BOOLEAN") || $value.valueType.equals("BOOLEAN_VAR")) {
                        System.out.println("    invokevirtual java/io/PrintStream/println(Z)V");
                    } else if ($value.valueType.equals("ARRAY_LENGTH") || $value.valueType.equals("ARRAY_GET")) {
                        System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
                    } else if ($value.valueType.equals("ARRAY_GET_STRING")) {
                        System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
                    } else if ($value.valueType.equals("ARRAY_GET_DOUBLE")) {
                        System.out.println("    dup_x2");  // duplica PrintStream abaixo do double
                        System.out.println("    pop");     // remove PrintStream do topo
                        System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
                    }
                }
            }
        }
   | PRINT OPEN_P
        {
            if (inFunction) {
                functionBodyBuilder.append("    getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            } else {
                System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
            }
        }
        expression CLOSE_P
        {
            if (inFunction) {
                functionBodyBuilder.append("    invokevirtual java/io/PrintStream/println(I)V\n");
            } else {
                System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
            }
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

statement_beep
   : BEEP OPEN_P CLOSE_P
            {
                if (inFunction) {
                    functionBodyBuilder.append("    invokestatic java/awt/Toolkit/getDefaultToolkit()Ljava/awt/Toolkit;\n");
                    functionBodyBuilder.append("    invokevirtual java/awt/Toolkit/beep()V\n");
                } else {
                    System.out.println("    invokestatic java/awt/Toolkit/getDefaultToolkit()Ljava/awt/Toolkit;");
                    System.out.println("    invokevirtual java/awt/Toolkit/beep()V");
                }
            }
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
       value CLOSE_P
       {
           // Agora temos [array, value] na pilha - executar o add
           // Verificar o tipo do valor e tratá-lo adequadamente
           String valueType = $value.valueType;
           
           // Rastrear o tipo dos elementos do array (baseado no primeiro elemento adicionado)
           if (!arrayElementTypes.containsKey($VAR.text)) {
               if (valueType.equals("STRING") || valueType.equals("STRING_VAR")) {
                   arrayElementTypes.put($VAR.text, "string");
               } else if (valueType.equals("DOUBLE") || valueType.equals("DOUBLE_VAR")) {
                   arrayElementTypes.put($VAR.text, "double");
               } else {
                   arrayElementTypes.put($VAR.text, "int");
               }
           }
           
           if (valueType.equals("STRING") || valueType.equals("STRING_VAR")) {
               // Para strings, não precisa converter, já está como objeto
               if (inFunction) {
                   functionBodyBuilder.append("    invokevirtual java/util/ArrayList/add(Ljava/lang/Object;)Z\n");
                   functionBodyBuilder.append("    pop\n"); // remove o boolean retornado
               } else {
                   System.out.println("    invokevirtual java/util/ArrayList/add(Ljava/lang/Object;)Z");
                   System.out.println("    pop"); // remove o boolean retornado
               }
           } else if (valueType.equals("DOUBLE") || valueType.equals("DOUBLE_VAR")) {
               // Para doubles, converter para Double
               if (inFunction) {
                   functionBodyBuilder.append("    invokestatic java/lang/Double/valueOf(D)Ljava/lang/Double;\n");
                   functionBodyBuilder.append("    invokevirtual java/util/ArrayList/add(Ljava/lang/Object;)Z\n");
                   functionBodyBuilder.append("    pop\n"); // remove o boolean retornado
               } else {
                   System.out.println("    invokestatic java/lang/Double/valueOf(D)Ljava/lang/Double;");
                   System.out.println("    invokevirtual java/util/ArrayList/add(Ljava/lang/Object;)Z");
                   System.out.println("    pop"); // remove o boolean retornado
               }
           } else {
               // Para inteiros, converter para Integer
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
           
           // Determinar o tipo dos elementos do array
           String elementType = arrayElementTypes.get($VAR.text);
           if (elementType == null) {
               elementType = "int"; // Tipo padrão se não foi detectado
           }
           
           if (inFunction) {
               functionBodyBuilder.append("    invokevirtual java/util/ArrayList/get(I)Ljava/lang/Object;\n");
               if (elementType.equals("string")) {
                   functionBodyBuilder.append("    checkcast java/lang/String\n");
               } else if (elementType.equals("double")) {
                   functionBodyBuilder.append("    checkcast java/lang/Double\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/Double/doubleValue()D\n");
               } else {
                   functionBodyBuilder.append("    checkcast java/lang/Integer\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/Integer/intValue()I\n");
               }
           } else {
               System.out.println("    invokevirtual java/util/ArrayList/get(I)Ljava/lang/Object;");
               if (elementType.equals("string")) {
                   System.out.println("    checkcast java/lang/String");
               } else if (elementType.equals("double")) {
                   System.out.println("    checkcast java/lang/Double");
                   System.out.println("    invokevirtual java/lang/Double/doubleValue()D");
               } else {
                   System.out.println("    checkcast java/lang/Integer");
                   System.out.println("    invokevirtual java/lang/Integer/intValue()I");
               }
           }
           
           // Definir o tipo de retorno baseado no tipo dos elementos
           if (elementType.equals("string")) {
               $valueType = "ARRAY_GET_STRING";
           } else if (elementType.equals("double")) {
               $valueType = "ARRAY_GET_DOUBLE";
           } else {
               $valueType = "ARRAY_GET";
           }
           $text = $VAR.text;
       }
   ;

array_length returns [String valueType, String text]
    : ARRAY_LENGTH OPEN_P VAR CLOSE_P
       {
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("array")) {
               // Sempre gera o código - será coordenado pela regra de print quando necessário
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
                   functionBodyBuilder.append("    invokevirtual java/util/ArrayList/size()I\n");
               } else {
                   System.out.println("    aload " + v);
                   System.out.println("    invokevirtual java/util/ArrayList/size()I");
               }
               $valueType = "ARRAY_LENGTH";
               $text = $VAR.text;
           } else {
               System.err.println("Variable " + $VAR.text + " is not an array or undefined");
               $valueType = "UNDEF";
               $text = $VAR.text;
           }       }
   ;

charat returns [String valueType, String text]
   : CHARAT OPEN_P VAR COMMA
       {
           // Primeiro carregamos a string
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("string")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
               } else {
                   System.out.println("    aload " + v);
               }
           } else {
               System.err.println("Variable " + $VAR.text + " is not a string or undefined");
           }
       }
       expression CLOSE_P
       {
           // Agora temos string na posição 0 da pilha e index na posição 1
           // String.charAt(int) espera [string, index] na pilha
           
           if (inFunction) {
               functionBodyBuilder.append("    invokevirtual java/lang/String/charAt(I)C\n");
               // Converter char para string para compatibilidade
               functionBodyBuilder.append("    invokestatic java/lang/String/valueOf(C)Ljava/lang/String;\n");
           } else {
               System.out.println("    invokevirtual java/lang/String/charAt(I)C");
               // Converter char para string para compatibilidade
               System.out.println("    invokestatic java/lang/String/valueOf(C)Ljava/lang/String;");
           }
           
           $valueType = "STRING";
           $text = $VAR.text + ".charAt()";
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

statement_goto
   : GOTO VAR
       {
           String labelName = $VAR.text;
           if (inFunction) {
               functionBodyBuilder.append("    goto " + labelName + "\n");
           } else {
               System.out.println("    goto " + labelName);
           }
       }
   ;

statement_label
   : LABEL VAR COLON
       {
           String labelName = $VAR.text;
           if (inFunction) {
               functionBodyBuilder.append(labelName + ":\n");
           } else {
               System.out.println(labelName + ":");
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

length returns [String valueType, String text]
   : LENGTH OPEN_P VAR CLOSE_P
       {
           // Primeiro carregamos a string variável
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("string")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/String/length()I\n");
               } else {
                   System.out.println("    aload " + v);
                   System.out.println("    invokevirtual java/lang/String/length()I");
               }
               $valueType = "INT";
               $text = $VAR.text + ".length()";
           } else {
               System.err.println("Variable " + $VAR.text + " is not a string or undefined");
               $valueType = "UNDEF";
               $text = $VAR.text;
           }
       }
   | LENGTH OPEN_P STRING CLOSE_P
       {
           // Para string literal
           if (inFunction) {
               functionBodyBuilder.append("    ldc " + $STRING.text + "\n");
               functionBodyBuilder.append("    invokevirtual java/lang/String/length()I\n");
           } else {
               System.out.println("    ldc " + $STRING.text);
               System.out.println("    invokevirtual java/lang/String/length()I");
           }
           $valueType = "INT";
           $text = $STRING.text + ".length()";
       }
   ;

compare returns [String valueType, String text]
   : COMPARE OPEN_P var1=VAR COMMA var2=VAR CLOSE_P
       {
           // Comparar duas variáveis string
           Integer v1 = memory.get($var1.text);
           Integer v2 = memory.get($var2.text);
           if (v1 != null && variableTypes.get($var1.text).equals("string") &&
               v2 != null && variableTypes.get($var2.text).equals("string")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v1 + "\n");
                   functionBodyBuilder.append("    aload " + v2 + "\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z\n");
               } else {
                   System.out.println("    aload " + v1);
                   System.out.println("    aload " + v2);
                   System.out.println("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z");
               }
               $valueType = "BOOLEAN";
               $text = $var1.text + ".equals(" + $var2.text + ")";
           } else {
               System.err.println("One or both variables are not strings or undefined");
               $valueType = "UNDEF";
               $text = "compare()";
           }
       }
   | COMPARE OPEN_P VAR COMMA STRING CLOSE_P
       {
           // Comparar variável string com string literal
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("string")) {
               if (inFunction) {
                   functionBodyBuilder.append("    aload " + v + "\n");
                   functionBodyBuilder.append("    ldc " + $STRING.text + "\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z\n");
               } else {
                   System.out.println("    aload " + v);
                   System.out.println("    ldc " + $STRING.text);
                   System.out.println("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z");
               }
               $valueType = "BOOLEAN";
               $text = $VAR.text + ".equals(" + $STRING.text + ")";
           } else {
               System.err.println("Variable " + $VAR.text + " is not a string or undefined");
               $valueType = "UNDEF";
               $text = "compare()";
           }
       }
   | COMPARE OPEN_P STRING COMMA VAR CLOSE_P
       {
           // Comparar string literal com variável string
           Integer v = memory.get($VAR.text);
           if (v != null && variableTypes.get($VAR.text).equals("string")) {
               if (inFunction) {
                   functionBodyBuilder.append("    ldc " + $STRING.text + "\n");
                   functionBodyBuilder.append("    aload " + v + "\n");
                   functionBodyBuilder.append("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z\n");
               } else {
                   System.out.println("    ldc " + $STRING.text);
                   System.out.println("    aload " + v);
                   System.out.println("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z");
               }
               $valueType = "BOOLEAN";
               $text = $STRING.text + ".equals(" + $VAR.text + ")";
           } else {
               System.err.println("Variable " + $VAR.text + " is not a string or undefined");
               $valueType = "UNDEF";
               $text = "compare()";
           }
       }
   | COMPARE OPEN_P str1=STRING COMMA str2=STRING CLOSE_P
       {
           // Comparar duas strings literais
           if (inFunction) {
               functionBodyBuilder.append("    ldc " + $str1.text + "\n");
               functionBodyBuilder.append("    ldc " + $str2.text + "\n");
               functionBodyBuilder.append("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z\n");
           } else {
               System.out.println("    ldc " + $str1.text);
               System.out.println("    ldc " + $str2.text);
               System.out.println("    invokevirtual java/lang/String/equals(Ljava/lang/Object;)Z");
           }
           $valueType = "BOOLEAN";
           $text = $str1.text + ".equals(" + $str2.text + ")";
       }
   ;