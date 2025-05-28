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
   Integer counter = 1;


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


VAR     : 'a'..'z'+ ;
NUM     : '0'..'9'+ ;
NL      : ('\r')? '\n' ;
SPACE   : (' '|'\t')+ { skip(); } ;
STRING  : '"' ('\\' . | ~('\\'|'"'))* '"' ;
DOUBLE  : ('0'..'9')+ '.' ('0'..'9')+ ;


/*---------------- PARSER RULES ----------------*/


program
   :  main
   ;


main
   :  MAIN OPEN_P CLOSE_P OPEN_C
           {
               System.out.println(".source ROSATest.j");
               System.out.println(".class  public ROSATest");
               System.out.println(".super  java/lang/Object\n");
               System.out.println(".method public <init>()V");
               System.out.println("    aload_0");
               System.out.println("    invokenonvirtual java/lang/Object/<init>()V");
               System.out.println("    return");
               System.out.println(".end method\n");
               System.out.println(".method public static main([Ljava/lang/String;)V\n");
           }
       ( statement )* CLOSE_C NL
           {
               System.out.println("    return");
               System.out.println(".limit stack 20");
               System.out.println(".limit locals 20");
               System.out.println(".end method");
           }
   ;


statement
   : NL                  |
     assignment          |
     statement_print     |
     statement_textcolor |
     statement_if
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
   : 'if' OPEN_P condition CLOSE_P OPEN_C
        {
            System.out.println("    goto label_true");
            System.out.println("label_true:");
        }
        ( statement )*
    CLOSE_C
        {
            System.out.println("    goto label_end");
            System.out.println("label_false:");
            System.out.println("    ; end if block");
        }
    ( 'else if' OPEN_P condition CLOSE_P OPEN_C
        {
            System.out.println("    ; else if condition");
        }
        ( statement )*
    CLOSE_C
        {
            System.out.println("    goto label_end");
            System.out.println("label_false:");
            System.out.println("    ; end else if block");
        }
    )*
    ( 'else' OPEN_C {
            System.out.println("    ; else block");
        }
        ( statement )*
        CLOSE_C
        {
            System.out.println("    ; end else block");
        }
    )?
        {
            System.out.println("label_end:");
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
                case "==": System.out.println("    if_icmpeq label_true"); break;
                case "!=": System.out.println("    if_icmpne label_true"); break;
                case "<":  System.out.println("    if_icmplt label_true"); break;
                case "<=": System.out.println("    if_icmple label_true"); break;
                case ">":  System.out.println("    if_icmpgt label_true"); break;
                case ">=": System.out.println("    if_icmpge label_true"); break;
            }
            System.out.println("    goto label_false"); 
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
   |   OPEN_P expression CLOSE_P
   ;