# Guía: Archivos .l (Flex/Lex)

## Todo lo que necesitas saber para entender y trabajar con el scanner

---

## 1. ¿Qué es un archivo .l?

Es un archivo de texto con instrucciones para **flex** (Fast Lexical Analyzer Generator). Flex es una herramienta que toma tus reglas y genera automáticamente un programa en C/C++ que funciona como scanner (analizador léxico).

```
triton_lexer.l    ──flex──►    lex.yy.cpp    ──g++──►    triton_lexer
(lo que tú                     (código C++               (programa
 escribes)                      generado por              ejecutable
                                flex, NO lo               que puedes
                                tocas)                    correr)
```

**Tú solo editas el `.l`.** Los otros dos archivos se generan con comandos.

---

## 2. ¿Por qué usamos flex?

Porque el profesor lo exige explícitamente. Pero más allá de eso, flex tiene ventajas reales:

| Sin flex (a mano) | Con flex |
|---|---|
| Escribir el AFD manualmente en C++ (cientos de líneas de switch/case) | Flex genera el AFD por ti a partir de regex |
| Implementar longest match manualmente | Flex lo hace automático |
| Implementar first match manualmente | Flex lo hace por orden de reglas |
| Manejar el buffer de entrada (leer chars, retroceder, etc.) | Flex lo maneja internamente |
| Resultado: ~500-1000 líneas de C++ | Resultado: ~350 líneas en el .l |

Internamente, flex hace esto cuando procesa tu archivo:

```
Tus regex ──► AFN (Thompson) ──► AFD (subconjuntos) ──► AFD mínimo (Hopcroft) ──► código C++
```

Toda la teoría de autómatas que vimos (AFD, AFN, tablas de transición) es lo que flex implementa por ti automáticamente.

---

## 3. Las 3 secciones del archivo .l

Un archivo `.l` tiene **exactamente 3 secciones** separadas por `%%`:

```
SECCIÓN 1: Definiciones
%%
SECCIÓN 2: Reglas
%%
SECCIÓN 3: Código de usuario
```

No puedes cambiar el orden ni omitir los `%%`. Los dos separadores `%%` son obligatorios.

---

## 4. SECCIÓN 1: Definiciones

Esta sección tiene dos partes:

### 4.1 Bloque de código C++ (`%{` ... `%}`)

Todo lo que pongas entre `%{` y `%}` se copia **textualmente** al archivo C++ generado. Aquí va tu código C++ normal:

```cpp
%{
#include <iostream>
#include <vector>
#include <string>

using namespace std;

// Tus enums, structs, variables globales, prototipos
enum TokenID {
    TOK_IF = 102,
    TOK_NAME = 200,
    // ...
};

struct TokenEntry {
    int id;
    string lexeme;
    int line;
};

vector<TokenEntry> token_list;
int line_num = 1;

void add_token(int id, const char *lexeme);
%}
```

**Reglas:**
- `%{` debe estar en la primera columna (sin espacios antes)
- `%}` también en la primera columna
- Todo lo de adentro es C++ estándar

### 4.2 Definiciones de patrones

Después del `%}` y antes del primer `%%`, puedes definir "macros" de regex que usarás en la sección de reglas:

```
DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
INTEGER    {DIGIT}+
FLOAT      {DIGIT}+"."{DIGIT}+
```

**¿Cómo funcionan?** Son atajos. Cuando escribas `{ID}` en una regla, flex lo reemplaza por la regex completa `[a-zA-Z_]([a-zA-Z_]|[0-9])*`. Sirven para no repetir patrones largos.

**Sintaxis:**
- `NOMBRE    patrón` (separados por espacio o tab)
- El nombre debe empezar en la primera columna (sin espacios antes)
- Se usan en las reglas con `{NOMBRE}`

### 4.3 Opciones de flex

También puedes agregar opciones de flex:

```
%option noyywrap
```

**`%option noyywrap`** — Le dice a flex que no necesite la función `yywrap()`. Sin esta opción, tendrías que definir esa función tú mismo. Con la opción, flex se encarga solo.

---

## 5. SECCIÓN 2: Reglas

Esta es la sección más importante. Cada línea tiene un **patrón** (regex) y una **acción** (código C++):

```
patrón    { acción en C++; }
```

### 5.1 Sintaxis básica

```cpp
%%
"if"        { add_token(TOK_IF, yytext);   return TOK_IF; }
[0-9]+      { add_token(TOK_NUMBER, yytext); return TOK_NUMBER; }
[ \t]+      { /* ignorar espacios */ }
.           { cerr << "Error: " << yytext; }
%%
```

**Reglas de formato:**
- El patrón debe empezar en la **primera columna** (sin espacios antes)
- Si quieres poner un comentario antes de una regla, ponle **un espacio** antes del `/*`:
  ```
   /* Este es un comentario válido en la sección de reglas */
  ```
  (nota el espacio antes de `/*`)
- La acción va entre `{ }` en la misma línea o en las líneas siguientes

### 5.2 Tipos de patrones

| Patrón | Significado | Ejemplo |
|--------|-------------|---------|
| `"texto"` | Cadena literal exacta (entre comillas) | `"if"` coincide solo con `if` |
| `[abc]` | Clase de caracteres: cualquiera de los listados | `[0-9]` coincide con un dígito |
| `[^abc]` | Negación: cualquier carácter EXCEPTO los listados | `[^\n]` todo excepto newline |
| `[a-z]` | Rango de caracteres | `[a-zA-Z]` cualquier letra |
| `.` | Cualquier carácter excepto `\n` | `.` coincide con `a`, `1`, `$`, etc. |
| `*` | Cero o más del elemento anterior | `[0-9]*` cero o más dígitos |
| `+` | Uno o más del elemento anterior | `[0-9]+` uno o más dígitos |
| `?` | Cero o uno del elemento anterior | `[0-9]?` un dígito opcional |
| `\n` | Salto de línea literal | `\n` coincide con newline |
| `$` | Fin de línea | `\"[^\"\n]*$` comilla sin cierre al final de línea |
| `{NOMBRE}` | Referencia a definición de la sección 1 | `{ID}` se expande a su regex |
| `(a|b)` | Agrupación con alternancia | `(ab|cd)` coincide con `ab` o `cd` |

### 5.3 Cadenas literales entre comillas

En flex, las comillas dobles tienen un significado especial: el texto entre comillas se toma **literalmente**, sin interpretar caracteres especiales de regex:

```
"**"     ← coincide con los dos caracteres **  (literal)
**       ← ¡ERROR! * es operador de regex (cero o más)
```

Por eso todas nuestras keywords y operadores están entre comillas:
```
"if"     ← la cadena literal if
"+"      ← el carácter literal +
"**"     ← los dos caracteres literales **
```

### 5.4 Variables especiales de flex

| Variable | Tipo | Qué contiene |
|----------|------|-------------|
| `yytext` | `char*` | El lexema que acaba de coincidir con el patrón |
| `yyleng` | `int` | Longitud de `yytext` |
| `yyin` | `FILE*` | Archivo de entrada (por defecto `stdin`) |
| `yylex()` | función | La función principal del scanner. Cada llamada busca el siguiente token |

**Ejemplo:** Si el input es `while` y la regla `"while"` coincide, entonces:
- `yytext` = `"while"`
- `yyleng` = `5`

### 5.5 Las dos reglas de prioridad de flex

Cuando flex lee el input, puede haber varias reglas que coincidan. ¿Cómo decide cuál usar?

**Regla 1 — Longest Match (coincidencia más larga):**

Flex siempre elige el patrón que consume **más caracteres**.

```
Input: "**"
Regla "*"    coincide con 1 carácter  → *
Regla "**"   coincide con 2 caracteres → **
Flex elige "**" porque es más largo ✓
```

**Regla 2 — First Match (primera regla):**

Si dos patrones coinciden con la **misma longitud**, flex elige el que aparece **primero** en el archivo.

```
Input: "if"
Regla "if"   (línea 10) coincide con 2 caracteres → if
Regla {ID}   (línea 30) coincide con 2 caracteres → if
Flex elige "if" porque aparece primero ✓
```

**¿Por qué importa?**
- Keywords DEBEN ir ANTES que `{ID}`, si no `if` se clasificaría como NAME
- Operadores de 2 chars DEBEN ir ANTES que los de 1 char, si no `**` se leería como dos `*`
- La regla `.` (catch-all) DEBE ir AL FINAL, si no capturaría todo

### 5.6 Acciones: ¿qué va dentro de `{ }`?

Cada acción es código C++ que se ejecuta cuando el patrón coincide:

```cpp
"if"  { add_token(TOK_IF, yytext); return TOK_IF; }
//      ↑ registra el token           ↑ le dice a flex que ya
//        en nuestra lista               encontró un token
```

- **`add_token(...)`** — nuestra función que guarda el token en el vector
- **`return TOK_IF`** — devuelve el valor al ciclo `while(yylex())` en main
- **Acción vacía `{ }`** — coincide pero no hace nada (para ignorar espacios y comentarios)

### 5.7 La regla catch-all `.`

```cpp
.  { cerr << "Error: " << yytext << endl; }
```

El punto `.` coincide con **cualquier carácter** que no haya sido capturado por ninguna regla anterior. Como está al final, solo se activa para caracteres que no pertenecen al lenguaje. Es nuestra red de seguridad para detectar errores.

---

## 6. SECCIÓN 3: Código de usuario

Todo lo que va después del segundo `%%` se copia textualmente al final del archivo C++ generado. Aquí van tus funciones y la función `main()`:

```cpp
%%

void add_token(int id, const char *lexeme) {
    // tu código
}

void print_tokens() {
    // tu código
}

int main(int argc, char *argv[]) {
    // abrir archivo
    yyin = f;
    
    // ejecutar el scanner hasta EOF
    while (yylex() != 0);
    
    // imprimir resultados
    print_tokens();
    print_symbol_table();
    
    return 0;
}
```

**`yylex()`** es la función que flex genera automáticamente a partir de tus reglas. Cada vez que la llamas:
1. Lee caracteres del input
2. Busca el patrón más largo que coincida
3. Ejecuta la acción correspondiente
4. Retorna el valor del `return` de la acción
5. Si llega a EOF, retorna `0`

---

## 7. Compilación y ejecución

### 7.1 Comandos

```bash
# Paso 1: flex genera código C++ a partir del .l
flex -o lex.yy.cpp triton_lexer.l

# Paso 2: g++ compila el C++ generado
g++ -std=c++17 -o triton_lexer lex.yy.cpp -ll

# Paso 3: ejecutar con un archivo de prueba
./triton_lexer archivo.triton
```

### 7.2 ¿Qué hace cada comando?

| Comando | Input | Output | Qué hace |
|---------|-------|--------|----------|
| `flex -o lex.yy.cpp triton_lexer.l` | `triton_lexer.l` | `lex.yy.cpp` | Convierte reglas flex a código C++ |
| `g++ -std=c++17 -o triton_lexer lex.yy.cpp -ll` | `lex.yy.cpp` | `triton_lexer` | Compila el C++ a ejecutable |
| `./triton_lexer archivo.triton` | `archivo.triton` | stdout/stderr | Ejecuta el scanner |

### 7.3 ¿Qué es `-ll`?

Es la flag que le dice a g++ que enlace con la biblioteca de flex (`libfl`). Contiene funciones auxiliares que flex necesita. Sin ella, g++ da errores de "undefined reference".

### 7.4 ¿Qué es `-std=c++17`?

Le dice a g++ que compile con el estándar C++17. Lo usamos porque nuestro código usa features de C++ moderno como `string`, `vector`, etc.

---

## 8. Errores comunes al trabajar con archivos .l

### 8.1 "Patrón no empieza en la primera columna"

```
  "if"  { ... }    ← ERROR: hay espacios antes del patrón
"if"    { ... }    ← CORRECTO: empieza en columna 1
```

### 8.2 Comentarios en la sección de reglas

```
/* esto da error */         ← ERROR: empieza en columna 1, flex lo confunde con patrón
 /* esto está bien */       ← CORRECTO: un espacio antes del /*
```

### 8.3 El orden de las reglas importa

```
{ID}     { return TOK_NAME; }
"if"     { return TOK_IF; }     ← PROBLEMA: "if" nunca se alcanza
                                   porque {ID} ya lo captura
```

Solución: poner `"if"` ANTES que `{ID}`.

### 8.4 Olvidar `%option noyywrap`

Sin esta opción, necesitas definir la función `yywrap()` tú mismo:
```cpp
int yywrap() { return 1; }
```
O simplemente agrega `%option noyywrap` y flex se encarga.

### 8.5 No poner `return` en las acciones

```cpp
"if"  { add_token(TOK_IF, yytext); }              ← Sin return: flex no para, sigue buscando
"if"  { add_token(TOK_IF, yytext); return TOK_IF; } ← Con return: flex retorna al ciclo while
```

Sin `return`, flex procesa el token pero inmediatamente busca el siguiente sin devolver el control a `main()`. Funciona, pero el ciclo `while(yylex())` no recibe el valor.

---

## 9. Estructura de nuestro archivo triton_lexer.l

```
triton_lexer.l (350 líneas)
│
├── SECCIÓN 1: Definiciones (líneas 1-100 aprox.)
│   ├── %{ ... %}
│   │   ├── #includes (iostream, vector, string, iomanip, cstring)
│   │   ├── enum TokenID (60 tokens, IDs 100-999)
│   │   ├── struct TokenEntry (id, lexeme, token_name, line)
│   │   ├── struct Symbol (token, identifier, value, error)
│   │   ├── vector<TokenEntry> token_list
│   │   ├── vector<Symbol> symbol_table
│   │   ├── int line_num = 1
│   │   └── prototipos de funciones
│   │
│   ├── %option noyywrap
│   │
│   └── Patrones flex
│       ├── DIGIT, LETTER, ID, INTEGER, FLOAT
│       ├── STRLIT, STRLIT2 (cadenas dobles y simples)
│       ├── COMMENT, WS
│
├── SECCIÓN 2: Reglas (líneas 100-200 aprox.)
│   ├── 1. Keywords (18 reglas)
│   ├── 2. Operadores 2 chars (10 reglas)
│   ├── 3. Delimitadores 2 chars (3 reglas: ->, <<, >>)
│   ├── 4. Operadores 1 char (8 reglas)
│   ├── 5. Delimitadores 1 char (14 reglas)
│   ├── 6. Identificadores ({ID})
│   ├── 7. Números ({FLOAT}, {INTEGER})
│   ├── 8. Cadenas ({STRLIT}, {STRLIT2})
│   ├── 9. Error cadena no terminada
│   ├── 10. Comentarios ({COMMENT}) → se ignoran
│   ├── 11. Newline (\n)
│   ├── 12. Espacios ({WS}) → se ignoran
│   └── 13. Catch-all (.) → errores
│
└── SECCIÓN 3: Código de usuario (líneas 200-350 aprox.)
    ├── token_id_to_name(id) → convierte 102 a "IF"
    ├── add_token(id, lexeme) → agrega a token_list
    ├── add_symbol(token, id, value, error) → agrega a symbol_table
    ├── print_tokens() → imprime la secuencia
    ├── print_symbol_table() → imprime la tabla
    └── main() → abre archivo, corre yylex(), imprime todo
```

---

## 10. Flujo de ejecución del scanner

Cuando corres `./triton_lexer archivo.triton`:

```
1. main() abre el archivo y lo asigna a yyin
2. main() entra al ciclo: while (yylex() != 0)
3. yylex() lee caracteres del archivo
4. yylex() busca el patrón más largo que coincida
5. yylex() ejecuta la acción { add_token(...); return ...; }
6. add_token() guarda el token en token_list
7. yylex() retorna el valor del return a main()
8. main() vuelve al paso 3 (siguiente iteración del while)
9. Cuando yylex() llega a EOF, retorna 0
10. El while termina
11. main() llama print_tokens() y print_symbol_table()
12. Se imprime todo en la terminal
13. main() cierra el archivo y termina
```
