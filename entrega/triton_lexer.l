%{
/*=============================================================
 * Triton GPU Kernel - Analizador Lexico
 * TC3002B - Compiladores
 * 
 * Descripcion: Scanner para el lenguaje Triton GPU Kernel
 *              implementado con flex y compilado con g++.
 *
 * Estructura del archivo:
 *   Seccion 1 (%{ ... %})  - Definiciones de C++
 *   Seccion 2 (%% ... %%)  - Reglas (regex -> acciones)
 *   Seccion 3 (despues %%) - Codigo de usuario (funciones, main)
 *=============================================================*/

#include <iostream>
#include <string>
#include <vector>
#include <iomanip>
#include <cstring>

using namespace std;

/*-------------------------------------------------------------
 * Token IDs
 * Agrupados por categoria segun la especificacion:
 *   100-117: Keywords
 *   200-202: Identificadores y literales
 *   300-317: Operadores
 *   400-416: Delimitadores
 *   500-502: Indentacion
 *   999:     Error
 *-------------------------------------------------------------*/
enum TokenID {
    /* Keywords */
    TOK_DEF = 100, TOK_RETURN = 101, TOK_IF = 102, TOK_ELSE = 103,
    TOK_ELIF = 104, TOK_FOR = 105, TOK_WHILE = 106, TOK_IN = 107,
    TOK_IS = 108, TOK_AND = 109, TOK_OR = 110, TOK_NOT = 111,
    TOK_TRUE = 112, TOK_FALSE = 113, TOK_NONE = 114, TOK_PASS = 115,
    TOK_BREAK = 116, TOK_CONTINUE = 117,

    /* Identificadores y literales */
    TOK_NAME = 200, TOK_NUMBER = 201, TOK_STRING = 202,

    /* Operadores */
    TOK_PLUS = 300, TOK_MINUS = 301, TOK_TIMES = 302, TOK_DIVIDE = 303,
    TOK_FLOORDIV = 304, TOK_MOD = 305, TOK_POWER = 306,
    TOK_LT = 307, TOK_GT = 308, TOK_LE = 309, TOK_GE = 310,
    TOK_EQ = 311, TOK_NE = 312, TOK_ASSIGN = 313,
    TOK_PLUSEQ = 314, TOK_MINUSEQ = 315, TOK_TIMESEQ = 316, TOK_DIVEQ = 317,

    /* Delimitadores */
    TOK_LPAREN = 400, TOK_RPAREN = 401, TOK_LBRACKET = 402, TOK_RBRACKET = 403,
    TOK_LBRACE = 404, TOK_RBRACE = 405, TOK_COMMA = 406, TOK_COLON = 407,
    TOK_DOT = 408, TOK_AT = 409, TOK_ARROW = 410, TOK_TILDE = 411,
    TOK_AMPERSAND = 412, TOK_PIPE = 413, TOK_CARET = 414,
    TOK_LSHIFT = 415, TOK_RSHIFT = 416,

    /* Indentacion */
    TOK_NEWLINE = 500, TOK_INDENT = 501, TOK_DEDENT = 502,

    /* Error */
    TOK_ERROR = 999
};

/*-------------------------------------------------------------
 * Estructura para almacenar un token en la secuencia de salida.
 * Cada token tiene: ID numerico, lexema, nombre legible, linea.
 *-------------------------------------------------------------*/
struct TokenEntry {
    int    id;
    string lexeme;
    string token_name;
    int    line;
};

/*-------------------------------------------------------------
 * Estructura para almacenar una entrada en la tabla de simbolos.
 * Solo se registran: NAME, NUMBER, STRING y errores.
 *-------------------------------------------------------------*/
struct Symbol {
    string token;
    string identifier;
    string value;
    string error;
};

/*-------------------------------------------------------------
 * Variables globales
 *-------------------------------------------------------------*/
vector<TokenEntry> token_list;    /* Secuencia de tokens */
vector<Symbol>     symbol_table;  /* Tabla de simbolos */
int line_num = 1;                 /* Contador de linea actual */

/*-------------------------------------------------------------
 * Prototipos de funciones (definidas en la Seccion 3)
 *-------------------------------------------------------------*/
string token_id_to_name(int id);
void   add_token(int id, const char *lexeme);
void   add_symbol(const string &token, const string &identifier,
                  const string &value, const string &error);
void   print_tokens();
void   print_symbol_table();

%}

/*-------------------------------------------------------------
 * Opciones de flex
 *-------------------------------------------------------------*/
%option noyywrap

/*-------------------------------------------------------------
 * Definiciones de patrones reutilizables
 * Estas macros se expanden en la seccion de reglas con {NOMBRE}
 *-------------------------------------------------------------*/
DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
INTEGER    {DIGIT}+
FLOAT      {DIGIT}+"."{DIGIT}+
STRLIT     \"([^"\\\n]|\\.)*\"
STRLIT2    \'([^'\\\n]|\\.)*\'
COMMENT    #[^\n]*
WS         [ \t]+

%%
 /*=============================================================
  * SECCION 2: REGLAS
  * Cada linea: patron (regex)   { accion (codigo C++) }
  *
  * ORDEN IMPORTANTE:
  * 1. Keywords ANTES que identificadores (first match)
  * 2. Operadores de 2 chars ANTES que los de 1 (longest match)
  * 3. Flotantes ANTES que enteros (longest match)
  * 4. Regla catch-all "." al FINAL (errores)
  *=============================================================*/

 /* --- 1. KEYWORDS (18 palabras reservadas) --- */
 /* Van primero para que "if" se clasifique como TOK_IF */
 /* y no como TOK_NAME por la regla de first match.    */
"def"       { add_token(TOK_DEF, yytext);       return TOK_DEF; }
"return"    { add_token(TOK_RETURN, yytext);     return TOK_RETURN; }
"if"        { add_token(TOK_IF, yytext);         return TOK_IF; }
"else"      { add_token(TOK_ELSE, yytext);       return TOK_ELSE; }
"elif"      { add_token(TOK_ELIF, yytext);       return TOK_ELIF; }
"for"       { add_token(TOK_FOR, yytext);        return TOK_FOR; }
"while"     { add_token(TOK_WHILE, yytext);      return TOK_WHILE; }
"in"        { add_token(TOK_IN, yytext);         return TOK_IN; }
"is"        { add_token(TOK_IS, yytext);         return TOK_IS; }
"and"       { add_token(TOK_AND, yytext);        return TOK_AND; }
"or"        { add_token(TOK_OR, yytext);         return TOK_OR; }
"not"       { add_token(TOK_NOT, yytext);        return TOK_NOT; }
"True"      { add_token(TOK_TRUE, yytext);       return TOK_TRUE; }
"False"     { add_token(TOK_FALSE, yytext);      return TOK_FALSE; }
"None"      { add_token(TOK_NONE, yytext);       return TOK_NONE; }
"pass"      { add_token(TOK_PASS, yytext);       return TOK_PASS; }
"break"     { add_token(TOK_BREAK, yytext);      return TOK_BREAK; }
"continue"  { add_token(TOK_CONTINUE, yytext);   return TOK_CONTINUE; }

 /* --- 2. OPERADORES DE 2 CARACTERES --- */
 /* Van antes que los de 1 caracter para que flex   */
 /* prefiera "**" sobre "*" (regla de longest match) */
"**"        { add_token(TOK_POWER, yytext);      return TOK_POWER; }
"//"        { add_token(TOK_FLOORDIV, yytext);   return TOK_FLOORDIV; }
"<="        { add_token(TOK_LE, yytext);         return TOK_LE; }
">="        { add_token(TOK_GE, yytext);         return TOK_GE; }
"=="        { add_token(TOK_EQ, yytext);         return TOK_EQ; }
"!="        { add_token(TOK_NE, yytext);         return TOK_NE; }
"+="        { add_token(TOK_PLUSEQ, yytext);     return TOK_PLUSEQ; }
"-="        { add_token(TOK_MINUSEQ, yytext);    return TOK_MINUSEQ; }
"*="        { add_token(TOK_TIMESEQ, yytext);    return TOK_TIMESEQ; }
"/="        { add_token(TOK_DIVEQ, yytext);      return TOK_DIVEQ; }

 /* --- 3. DELIMITADORES DE 2 CARACTERES --- */
"->"        { add_token(TOK_ARROW, yytext);      return TOK_ARROW; }
"<<"        { add_token(TOK_LSHIFT, yytext);     return TOK_LSHIFT; }
">>"        { add_token(TOK_RSHIFT, yytext);     return TOK_RSHIFT; }

 /* --- 4. OPERADORES DE 1 CARACTER --- */
"+"         { add_token(TOK_PLUS, yytext);       return TOK_PLUS; }
"-"         { add_token(TOK_MINUS, yytext);      return TOK_MINUS; }
"*"         { add_token(TOK_TIMES, yytext);      return TOK_TIMES; }
"/"         { add_token(TOK_DIVIDE, yytext);     return TOK_DIVIDE; }
"%"         { add_token(TOK_MOD, yytext);        return TOK_MOD; }
"<"         { add_token(TOK_LT, yytext);         return TOK_LT; }
">"         { add_token(TOK_GT, yytext);         return TOK_GT; }
"="         { add_token(TOK_ASSIGN, yytext);     return TOK_ASSIGN; }

 /* --- 5. DELIMITADORES DE 1 CARACTER --- */
"("         { add_token(TOK_LPAREN, yytext);     return TOK_LPAREN; }
")"         { add_token(TOK_RPAREN, yytext);     return TOK_RPAREN; }
"["         { add_token(TOK_LBRACKET, yytext);   return TOK_LBRACKET; }
"]"         { add_token(TOK_RBRACKET, yytext);   return TOK_RBRACKET; }
"{"         { add_token(TOK_LBRACE, yytext);     return TOK_LBRACE; }
"}"         { add_token(TOK_RBRACE, yytext);     return TOK_RBRACE; }
","         { add_token(TOK_COMMA, yytext);      return TOK_COMMA; }
":"         { add_token(TOK_COLON, yytext);      return TOK_COLON; }
"."         { add_token(TOK_DOT, yytext);        return TOK_DOT; }
"@"         { add_token(TOK_AT, yytext);         return TOK_AT; }
"~"         { add_token(TOK_TILDE, yytext);      return TOK_TILDE; }
"&"         { add_token(TOK_AMPERSAND, yytext);  return TOK_AMPERSAND; }
"|"         { add_token(TOK_PIPE, yytext);       return TOK_PIPE; }
"^"         { add_token(TOK_CARET, yytext);      return TOK_CARET; }

 /* --- 6. IDENTIFICADORES --- */
 /* Despues de keywords para que estas tengan prioridad */
{ID}        {
                add_token(TOK_NAME, yytext);
                add_symbol("NAME", yytext, "---", "---");
                return TOK_NAME;
            }

 /* --- 7. LITERALES NUMERICOS --- */
 /* Flotante ANTES que entero para longest match */
{FLOAT}     {
                add_token(TOK_NUMBER, yytext);
                add_symbol("NUMBER", "(literal)", yytext, "---");
                return TOK_NUMBER;
            }

{INTEGER}   {
                add_token(TOK_NUMBER, yytext);
                add_symbol("NUMBER", "(literal)", yytext, "---");
                return TOK_NUMBER;
            }

 /* --- 8. LITERALES DE CADENA --- */
{STRLIT}    {
                add_token(TOK_STRING, yytext);
                add_symbol("STRING", "(literal)", yytext, "---");
                return TOK_STRING;
            }

{STRLIT2}   {
                add_token(TOK_STRING, yytext);
                add_symbol("STRING", "(literal)", yytext, "---");
                return TOK_STRING;
            }

 /* --- 9. CADENA NO TERMINADA (ERROR) --- */
 /* Comilla de apertura sin cierre antes del fin de linea */
\"[^\"\n]*$ {
                cerr << "Error lexico: cadena no terminada en linea "
                     << line_num << endl;
                add_symbol("STRING", "(literal)", yytext,
                    "Cadena no terminada: falta comilla de cierre");
                add_token(TOK_ERROR, yytext);
            }

\'[^\'\n]*$ {
                cerr << "Error lexico: cadena no terminada en linea "
                     << line_num << endl;
                add_symbol("STRING", "(literal)", yytext,
                    "Cadena no terminada: falta comilla de cierre");
                add_token(TOK_ERROR, yytext);
            }

 /* --- 10. COMENTARIOS (se consumen, no generan token) --- */
{COMMENT}   { /* Ignorar: consume desde # hasta fin de linea */ }

 /* --- 11. NUEVA LINEA --- */
\n          {
                line_num++;
                add_token(TOK_NEWLINE, "\\n");
            }

 /* --- 12. ESPACIOS EN BLANCO (se consumen, no generan token) --- */
{WS}        { /* Ignorar espacios y tabuladores */ }

 /* --- 13. CARACTER NO RECONOCIDO (ERROR) --- */
 /* Ultima regla: captura cualquier caracter que no coincidio */
 /* con ninguna regla anterior. Solo se activa para chars     */
 /* fuera del alfabeto de Triton (ej: $, ¿, etc.)             */
.           {
                cerr << "Error lexico: caracter invalido '"
                     << yytext << "' en linea " << line_num << endl;
                add_symbol("(desconocido)", yytext, "---",
                    "Caracter invalido/no reconocido");
                add_token(TOK_ERROR, yytext);
            }

%%
/*=============================================================
 * SECCION 3: CODIGO DE USUARIO
 * Funciones auxiliares y funcion main().
 *=============================================================*/

/*-------------------------------------------------------------
 * token_id_to_name: Convierte un Token ID numerico a su nombre
 * legible como string. Se usa para la impresion de la secuencia
 * de tokens.
 *
 * Parametro: id - el Token ID numerico (ej: 100)
 * Retorna: nombre del token como string (ej: "DEF")
 *-------------------------------------------------------------*/
string token_id_to_name(int id) {
    switch(id) {
        case TOK_DEF:       return "DEF";
        case TOK_RETURN:    return "RETURN";
        case TOK_IF:        return "IF";
        case TOK_ELSE:      return "ELSE";
        case TOK_ELIF:      return "ELIF";
        case TOK_FOR:       return "FOR";
        case TOK_WHILE:     return "WHILE";
        case TOK_IN:        return "IN";
        case TOK_IS:        return "IS";
        case TOK_AND:       return "AND";
        case TOK_OR:        return "OR";
        case TOK_NOT:       return "NOT";
        case TOK_TRUE:      return "TRUE";
        case TOK_FALSE:     return "FALSE";
        case TOK_NONE:      return "NONE";
        case TOK_PASS:      return "PASS";
        case TOK_BREAK:     return "BREAK";
        case TOK_CONTINUE:  return "CONTINUE";
        case TOK_NAME:      return "NAME";
        case TOK_NUMBER:    return "NUMBER";
        case TOK_STRING:    return "STRING";
        case TOK_PLUS:      return "PLUS";
        case TOK_MINUS:     return "MINUS";
        case TOK_TIMES:     return "TIMES";
        case TOK_DIVIDE:    return "DIVIDE";
        case TOK_FLOORDIV:  return "FLOORDIV";
        case TOK_MOD:       return "MOD";
        case TOK_POWER:     return "POWER";
        case TOK_LT:        return "LT";
        case TOK_GT:        return "GT";
        case TOK_LE:        return "LE";
        case TOK_GE:        return "GE";
        case TOK_EQ:        return "EQ";
        case TOK_NE:        return "NE";
        case TOK_ASSIGN:    return "ASSIGN";
        case TOK_PLUSEQ:    return "PLUSEQ";
        case TOK_MINUSEQ:   return "MINUSEQ";
        case TOK_TIMESEQ:   return "TIMESEQ";
        case TOK_DIVEQ:     return "DIVEQ";
        case TOK_LPAREN:    return "LPAREN";
        case TOK_RPAREN:    return "RPAREN";
        case TOK_LBRACKET:  return "LBRACKET";
        case TOK_RBRACKET:  return "RBRACKET";
        case TOK_LBRACE:    return "LBRACE";
        case TOK_RBRACE:    return "RBRACE";
        case TOK_COMMA:     return "COMMA";
        case TOK_COLON:     return "COLON";
        case TOK_DOT:       return "DOT";
        case TOK_AT:        return "AT";
        case TOK_ARROW:     return "ARROW";
        case TOK_TILDE:     return "TILDE";
        case TOK_AMPERSAND: return "AMPERSAND";
        case TOK_PIPE:      return "PIPE";
        case TOK_CARET:     return "CARET";
        case TOK_LSHIFT:    return "LSHIFT";
        case TOK_RSHIFT:    return "RSHIFT";
        case TOK_NEWLINE:   return "NEWLINE";
        case TOK_INDENT:    return "INDENT";
        case TOK_DEDENT:    return "DEDENT";
        case TOK_ERROR:     return "ERROR";
        default:            return "UNKNOWN";
    }
}

/*-------------------------------------------------------------
 * add_token: Registra un token en la secuencia de salida.
 *
 * Parametros:
 *   id     - Token ID numerico (ej: TOK_IF = 102)
 *   lexeme - texto del codigo fuente que coincidio (yytext)
 *
 * Corresponde al requerimiento: "Secuencia de tokens en el
 * orden en que aparecen en el archivo fuente."
 *-------------------------------------------------------------*/
void add_token(int id, const char *lexeme) {
    TokenEntry entry;
    entry.id         = id;
    entry.lexeme     = string(lexeme);
    entry.token_name = token_id_to_name(id);
    entry.line       = line_num;
    token_list.push_back(entry);
}

/*-------------------------------------------------------------
 * add_symbol: Registra una entrada en la tabla de simbolos.
 * Evita duplicados comparando token + identificador.
 *
 * Parametros:
 *   token      - tipo ("NAME", "NUMBER", "STRING", etc.)
 *   identifier - el lexema o "(literal)"
 *   value      - valor asociado o "---"
 *   error      - mensaje de error o "---"
 *
 * Corresponde al requerimiento: "Tabla de simbolos para
 * todos los tokens validos."
 *-------------------------------------------------------------*/
void add_symbol(const string &token, const string &identifier,
                const string &value, const string &error) {
    /* Busqueda lineal para evitar duplicados */
    for (size_t i = 0; i < symbol_table.size(); i++) {
        if (symbol_table[i].identifier == identifier &&
            symbol_table[i].token == token) {
            return;  /* Ya existe, no duplicar */
        }
    }
    Symbol sym;
    sym.token      = token;
    sym.identifier = identifier;
    sym.value      = value;
    sym.error      = error;
    symbol_table.push_back(sym);
}

/*-------------------------------------------------------------
 * print_tokens: Imprime la secuencia completa de tokens en
 * formato tabular a stdout.
 *
 * Formato: TokenID  Token  Lexema  Linea
 *-------------------------------------------------------------*/
void print_tokens() {
    cout << endl;
    cout << "=================================================================" << endl;
    cout << "                    SECUENCIA DE TOKENS                          " << endl;
    cout << "=================================================================" << endl;
    cout << left << setw(10) << "TokenID"
         << setw(15) << "Token"
         << setw(25) << "Lexema"
         << setw(8)  << "Linea" << endl;
    cout << "-----------------------------------------------------------------" << endl;

    for (size_t i = 0; i < token_list.size(); i++) {
        /* Reemplazar \n literal por texto visible \\n */
        string lex_display = token_list[i].lexeme;
        if (lex_display == "\n") lex_display = "\\n";

        cout << left << setw(10) << token_list[i].id
             << setw(15) << token_list[i].token_name
             << setw(25) << lex_display
             << setw(8)  << token_list[i].line << endl;
    }

    cout << "=================================================================" << endl;
    cout << "Total de tokens: " << token_list.size() << endl << endl;
}

/*-------------------------------------------------------------
 * print_symbol_table: Imprime la tabla de simbolos completa
 * en formato tabular a stdout.
 *
 * Formato: Token  Identificador  Valor  Error
 *-------------------------------------------------------------*/
void print_symbol_table() {
    cout << endl;
    cout << "=================================================================" << endl;
    cout << "                    TABLA DE SIMBOLOS                            " << endl;
    cout << "=================================================================" << endl;
    cout << left << setw(14) << "Token"
         << setw(22) << "Identificador"
         << setw(18) << "Valor"
         << setw(45) << "Error" << endl;
    cout << "-----------------------------------------------------------------" << endl;

    for (size_t i = 0; i < symbol_table.size(); i++) {
        cout << left << setw(14) << symbol_table[i].token
             << setw(22) << symbol_table[i].identifier
             << setw(18) << symbol_table[i].value
             << setw(45) << symbol_table[i].error << endl;
    }

    cout << "=================================================================" << endl;
    cout << "Total de simbolos: " << symbol_table.size() << endl << endl;
}

/*-------------------------------------------------------------
 * main: Punto de entrada del programa.
 *
 * Uso: ./triton_lexer <archivo_fuente>
 *
 * 1. Abre el archivo fuente y lo asigna a yyin
 * 2. Ejecuta yylex() en un ciclo hasta EOF
 * 3. Imprime la secuencia de tokens y la tabla de simbolos
 *-------------------------------------------------------------*/
int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) {
            cerr << "Error: No se pudo abrir el archivo '"
                 << argv[1] << "'" << endl;
            return 1;
        }
        yyin = f;
        cout << "Analizando archivo: " << argv[1] << endl;
    } else {
        cout << "Uso: " << argv[0] << " <archivo_fuente>" << endl;
        cout << "Leyendo de entrada estandar (Ctrl+D para terminar)..." << endl;
        yyin = stdin;
    }

    /* Ejecutar el scanner hasta EOF */
    while (yylex() != 0);

    /* Imprimir resultados */
    print_tokens();
    print_symbol_table();

    /* Cerrar archivo si se abrio uno */
    if (argc > 1) {
        fclose(yyin);
    }

    return 0;
}
