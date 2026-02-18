/* ============================================================
   Section 1 — User Code
   Everything here is copied verbatim to the TOP of Yylex.java
   ============================================================ */
import java.util.*;

/* ============================================================
   Section 2 — Options and Macro Definitions
   ============================================================ */
%%

%class      Yylex          /* generated class will be named Yylex     */
%type       Token          /* yylex() returns a Token object           */
%unicode                   /* full unicode support                     */
%line                      /* enables yyline variable (0-indexed)      */
%column                    /* enables yycolumn variable (0-indexed)    */

%{
    private SymbolTable symbolTable = new SymbolTable();
    private ErrorHandler errors     = new ErrorHandler();
    private Map<TokenType, Integer> tokenCounts = new LinkedHashMap<>();
    private int commentsRemoved = 0;

    private static final Set<String> KEYWORDS = new HashSet<>(Arrays.asList(
        "start","finish","loop","condition","declare",
        "output","input","function","return","break","continue","else"
    ));

    private Token makeToken(TokenType type) {
        Token t = new Token(type, yytext(), yyline + 1, yycolumn + 1);
        tokenCounts.merge(type, 1, Integer::sum);
        if (type == TokenType.IDENTIFIER) {
            symbolTable.addOrUpdate(yytext(), yyline + 1, yycolumn + 1);
        }
        return t;
    }

    public void printStatistics() {
        System.out.println("\n===== JFLEX STATISTICS =====");
        System.out.println("Comments removed : " + commentsRemoved);
        System.out.println("\nTokens per type:");
        tokenCounts.forEach((type, count) ->
            System.out.printf("  %-25s : %d%n", type, count));
    }

    public SymbolTable getSymbolTable() { return symbolTable; }
    public ErrorHandler getErrors()     { return errors;      }

    // ── ADD THIS main() ──────────────────────────────────────────
    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.out.println("Usage: java Yylex <source_file.lang>");
            return;
        }

        java.io.FileReader fileReader = new java.io.FileReader(args[0]);
        Yylex scanner = new Yylex(fileReader);

        java.util.List<Token> tokens = new java.util.ArrayList<>();
        int totalLines = 1;

        Token t;
        while ((t = scanner.yylex()) != null) {
            if (t.getLine() > totalLines) totalLines = t.getLine();
            if (t.getType() == TokenType.SINGLE_LINE_COMMENT ||
                t.getType() == TokenType.MULTI_LINE_COMMENT) {
                continue;
            }
            tokens.add(t);
        }

        System.out.println("===== JFLEX TOKEN LIST =====");
        for (Token tok : tokens) System.out.println(tok);

        System.out.println("\n===== JFLEX STATISTICS =====");
        System.out.println("Total tokens    : " + tokens.size());
        System.out.println("Lines processed : " + totalLines);
        scanner.printStatistics();
        scanner.getSymbolTable().print();
        scanner.getErrors().printAll();
    }
%}

/* ── Macro definitions ────────────────────────────────────────────────
   These are named shortcuts for regex patterns.
   Use them in Section 3 as {MACRO_NAME}
   ──────────────────────────────────────────────────────────────────── */

DIGIT        = [0-9]
UPPER        = [A-Z]
LOWER        = [a-z]
ALPHANUM     = [a-z0-9_]
SIGN         = [+\-]
WHITESPACE   = [ \t\r\n]+

/* Integer:  [+-]?[0-9]+  */
INTEGER      = {SIGN}?{DIGIT}+

/* Float:    [+-]?[0-9]+\.[0-9]{1,6}([eE][+-]?[0-9]+)?  */
FLOAT        = {SIGN}?{DIGIT}+\.{DIGIT}{1,6}([eE]{SIGN}?{DIGIT}+)?

/* Identifier:  [A-Z][a-z0-9_]{0,30}  — max 31 chars total */
IDENTIFIER   = {UPPER}{ALPHANUM}{0,30}

/* String literal  "(regular char | escape)*"  */
STR_CHAR     = [^\"\\\n]
STR_ESC      = \\[\"\\ntr]
STRING       = \"({STR_CHAR}|{STR_ESC})*\"

/* Char literal  '(regular char | escape)'  */
CHR_CHAR     = [^'\\\n]
CHR_ESC      = \\['\\ntr]
CHAR         = \'({CHR_CHAR}|{CHR_ESC})\'

/* Comments */
SL_COMMENT   = "##"[^\n]*
ML_COMMENT   = "#*"([^*]|\*+[^*#])*\*+"#"

/* Operators */
ARITH_MULTI  = "**"
ARITH_SINGLE = [+\-*/%]
REL_MULTI    = "=="|"!="|"<="|">="
REL_SINGLE   = [<>]
LOGICAL_MULTI = "&&"|"||"
ASSIGN_MULTI = "+="|"-="|"*="|"/="
INC_DEC      = "++"|"--"

/* ============================================================
   Section 3 — Lexical Rules
   Format:  PATTERN   { action }
   Rules are tried TOP TO BOTTOM — ORDER MATTERS
   ============================================================ */
%%

/* ── 1. Multi-line comment ──────────────────────────────── */
{ML_COMMENT}    {
                    commentsRemoved++;
                    return new Token(TokenType.MULTI_LINE_COMMENT,
                                     yytext(), yyline+1, yycolumn+1);
                }

/* ── 2. Single-line comment ─────────────────────────────── */
{SL_COMMENT}    {
                    commentsRemoved++;
                    return new Token(TokenType.SINGLE_LINE_COMMENT,
                                     yytext(), yyline+1, yycolumn+1);
                }

/* ── 3. Multi-char operators (BEFORE single-char) ───────── */
{ARITH_MULTI}   { return makeToken(TokenType.ARITHMETIC_OP); }
{REL_MULTI}     { return makeToken(TokenType.RELATIONAL_OP); }
{LOGICAL_MULTI} { return makeToken(TokenType.LOGICAL_OP);    }
{ASSIGN_MULTI}  { return makeToken(TokenType.ASSIGNMENT_OP); }
{INC_DEC}       { return makeToken(TokenType.INC_DEC_OP);    }

/* ── 4. Keywords and boolean (BEFORE identifiers) ───────── */
"start"|"finish"|"loop"|"condition"|"declare"|
"output"|"input"|"function"|"return"|"break"|
"continue"|"else"                               { return makeToken(TokenType.KEYWORD); }

"true"|"false"                                  { return makeToken(TokenType.BOOLEAN_LITERAL); }

/* ── 5. Identifier ──────────────────────────────────────── */
{IDENTIFIER}    { return makeToken(TokenType.IDENTIFIER); }

/* ── 6. Floating-point (BEFORE integer) ─────────────────── */
{FLOAT}         { return makeToken(TokenType.FLOAT_LITERAL); }

/* ── 7. Integer ─────────────────────────────────────────── */
{INTEGER}       { return makeToken(TokenType.INTEGER_LITERAL); }

/* ── 8. String and char literals ────────────────────────── */
{STRING}        { return makeToken(TokenType.STRING_LITERAL); }
{CHAR}          { return makeToken(TokenType.CHAR_LITERAL);   }

/* ── 9. Single-char operators ───────────────────────────── */
{ARITH_SINGLE}  { return makeToken(TokenType.ARITHMETIC_OP); }
{REL_SINGLE}    { return makeToken(TokenType.RELATIONAL_OP); }
"!"             { return makeToken(TokenType.LOGICAL_OP);    }
"="             { return makeToken(TokenType.ASSIGNMENT_OP); }

/* ── 10. Punctuators ────────────────────────────────────── */
[(){}\[\],;:]   { return makeToken(TokenType.PUNCTUATOR); }

/* ── 11. Whitespace — skip but JFlex tracks line/col ─────── */
{WHITESPACE}    { /* skip */ }

/* ── 12. Anything else is an error ──────────────────────── */
[^]             {
                    errors.invalidCharacter(yyline+1, yycolumn+1, yytext().charAt(0));
                    return makeToken(TokenType.ERROR);
                }