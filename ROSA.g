grammar ROSA;


/*---------------- COMPILER INTERNALS ----------------*/


@header
{
   import java.util.Map;
   import java.util.LinkedHashMap;
}


@members
{
   Map<String, Integer> memory = new LinkedHashMap<String, Integer>();
   Map<String, Integer> functions = new LinkedHashMap<String, Integer>();
   Map<String, String> functionBodies = new LinkedHashMap<String, String>();
   Integer counter = 1;
   Integer functionCounter = 1;
   boolean inFunction = false;

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
FUNCTION  : 'function' ;
RETURN    : 'return' ;
CALL      : 'call' ;
COMMA     : ',' ;


VAR     : 'a'..'z'+ ;
NUM     : '0'..'9' + ;
NL      : ('\r')? '\n' ;
SPACE   : (' '|'\t')+ { skip(); } ;
STRING  : '"' ('\\' . | ~('\\'|'"'))* '"' ;
DOUBLE  : ('0'..'9')+ '.' ('0'..'9')+ ;


/*---------------- PARSER RULES ----------------*/

program
   : (function_def)* main (function_def)*
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
   : FUNCTION VAR OPEN_P (parameter_list)? CLOSE_P NL? OPEN_C
       {
           String funcName = $VAR.text;
           if (!functions.containsKey(funcName)) {
               functions.put(funcName, functionCounter++);
               functionBodies.put(funcName, "");
           }
           inFunction = true;
       }
       (statement)*
       (return_statement)?
   CLOSE_C NL?
       {
           inFunction = false;
       }
   ;

parameter_list
   : VAR (COMMA VAR)*
   ;

return_statement
   : RETURN expression NL?
   ;

function_call returns [String valueType, String text]
   : CALL VAR OPEN_P (argument_list)? CLOSE_P
       {
           String funcName = $VAR.text;
           if (functions.containsKey(funcName)) {
               System.out.println("    invokestatic ROSATest/" + funcName + "()I");
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
   :  MAIN OPEN_P CLOSE_P NL? OPEN_C
           {
               System.out.println(".source ROSATest.j");
               System.out.println(".class  public ROSATest");
               System.out.println(".super  java/lang/Object\n");
               System.out.println(".method public <init>()V");
               System.out.println("    aload_0");
               System.out.println("    invokenonvirtual java/lang/Object/<init>()V");
               System.out.println("    return");
               System.out.println(".end method\n");
               System.out.println(".method public static main([Ljava/lang/String;)V");
               System.out.println(".limit stack 20");
               System.out.println(".limit locals 20");
           }
       ( statement )* CLOSE_C NL?
           {
               System.out.println("    return");
               System.out.println(".end method");
           }
   ;

statement
   : NL                  |
     assignment NL?      |
     statement_print NL? |
     statement_textcolor NL? |
     statement_if NL?    |
     statement_while NL? |
     function_call NL?
   ;

assignment
   :
       VAR ATTRIB ( expression )
       {
           if (!memory.containsKey($VAR.text)) memory.put($VAR.text, counter++);
           System.out.println("    istore " + memory.get($VAR.text));
       }
   ;

value returns [String valueType, String text]
   : STRING { $valueType = "STRING"; $text = $STRING.text; }
   | NUM    { $valueType = "INT";    $text = $NUM.text; }
   | DOUBLE { $valueType = "DOUBLE"; $text = $DOUBLE.text; }
   | function_call { $valueType = $function_call.valueType; $text = $function_call.text; }
   | VAR    {
                Integer v = memory.get($VAR.text);
                if (v != null) {
                    $valueType = "VAR";
                    $text = $VAR.text;
                } else {
                    System.err.println("undefined variable " + $VAR.text);
                    $valueType = "UNDEF";
                    $text = $VAR.text;
                }
            }
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
   : PRINT OPEN_P value CLOSE_P
        {
            System.out.println("    getstatic java/lang/System/out Ljava/io/PrintStream;");
            if ($value.valueType.equals("STRING")) {
                System.out.println("    ldc " + $value.text);
                System.out.println("    invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V");
            } else if ($value.valueType.equals("INT")) {
                System.out.println("    ldc " + $value.text);
                System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
            } else if ($value.valueType.equals("DOUBLE")) {
                System.out.println("    ldc2_w " + $value.text);
                System.out.println("    invokevirtual java/io/PrintStream/println(D)V");
            } else if ($value.valueType.equals("VAR")) {
                Integer v = memory.get($value.text);
                if (v != null) {
                    System.out.println("    iload " + v);
                    System.out.println("    invokevirtual java/io/PrintStream/println(I)V");
                } else {
                    System.err.println("undefined variable " + $value.text);
                }
            } else if ($value.valueType.equals("FUNCTION_CALL")) {
                // A função já foi chamada e o resultado está na pilha
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
           { System.out.println(($op.type == PLUS) ? "    iadd" : "    isub"); }
       )*
   ;

term
   :   factor ( op = ( TIMES | OVER ) factor
            { System.out.println(($op.type == TIMES) ? "    imul" : "    idiv"); }
       )*
   ;

factor
   :   NUM
            { System.out.println("    ldc " + $NUM.text); }
   |   VAR
            {
              Integer v = memory.get($VAR.text);
              if (v != null)  System.out.println("    iload " + v.intValue());
              else System.err.println("undefined variable " + $VAR.text);
            }
   |   STRING
            { System.out.println("    ldc " + $STRING.text); }
   |   DOUBLE
            { System.out.println("    ldc2_w " + $DOUBLE.text); }
   |   function_call
            // A chamada de função já gera o código bytecode necessário
   |   OPEN_P expression CLOSE_P
   ;