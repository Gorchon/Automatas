# Guía Completa: Analizador Léxico para Triton GPU Kernel

## TC3002B — Actividad 3.1

---

# PARTE 1: CONCEPTOS FUNDAMENTALES

Todo lo que necesitas entender antes de tocar una sola línea de código.

---

## 1. Alfabeto (Σ)

Un **alfabeto** es un conjunto finito y no vacío de símbolos. Es la "materia prima" de la que están hechas las cadenas.

**Ejemplos:**
- Alfabeto binario: `Σ = {0, 1}`
- Alfabeto latino: `Σ = {a, b, c, ..., z}`
- Alfabeto de Triton: `Σ = {a-z, A-Z, 0-9, +, -, *, /, =, <, >, !, %, (, ), [, ], {, }, ,, :, ., @, ~, &, |, ^, _, ", ', #, \n, espacio, tab}`

**¿Por qué importa?** Porque cualquier carácter que NO esté en tu alfabeto es un **error léxico**. Si alguien escribe `$` en código Triton, tu scanner debe rechazarlo.

---

## 2. Cadena (Palabra)

Una **cadena** es una secuencia finita de símbolos tomados de un alfabeto.

- `"def"` → cadena de longitud 3
- `"42"` → cadena de longitud 2
- `""` → cadena vacía, se denota **ε** (épsilon), longitud 0

**Operaciones con cadenas:**
- **Concatenación:** `"ab" · "cd" = "abcd"`
- **Longitud:** `|"hola"| = 4`, `|ε| = 0`
- **Potencia:** `"ab"² = "abab"`, `"a"⁰ = ε`

---

## 3. Lenguaje

Un **lenguaje** es un conjunto (posiblemente infinito) de cadenas sobre un alfabeto.

**Ejemplos:**
- L₁ = `{if}` → lenguaje con una sola cadena (la keyword `if`)
- L₂ = `{0, 1, 2, ..., 99, 100, ...}` → lenguaje de todos los enteros (infinito)
- L₃ = `{x, y, foo, _temp, myVar, ...}` → lenguaje de todos los identificadores válidos (infinito)

**¿Por qué importa?** Cada tipo de token define un lenguaje. Tu scanner tiene que decidir si un fragmento de texto pertenece al lenguaje de identificadores, al de números, al de keywords, etc.

---

## 4. Expresiones Regulares (Regex)

Una expresión regular es una **notación compacta** para describir un lenguaje regular. En lugar de listar todas las cadenas posibles (que pueden ser infinitas), escribes un patrón.

### 4.1 Operaciones fundamentales

| Operación | Símbolo | Significado | Ejemplo | Cadenas que acepta |
|-----------|---------|-------------|---------|-------------------|
| **Literal** | `a` | Exactamente ese carácter | `a` | `"a"` |
| **Concatenación** | `ab` | `a` seguida de `b` | `ab` | `"ab"` |
| **Unión (OR)** | `a\|b` | `a` o `b` | `a\|b` | `"a"`, `"b"` |
| **Kleene Star** | `a*` | Cero o más repeticiones de `a` | `a*` | `""`, `"a"`, `"aa"`, `"aaa"`, ... |
| **Kleene Plus** | `a+` | Una o más repeticiones de `a` | `a+` | `"a"`, `"aa"`, `"aaa"`, ... |
| **Opcional** | `a?` | Cero o una vez `a` | `a?` | `""`, `"a"` |
| **Clase de caracteres** | `[abc]` | Cualquiera de los listados | `[abc]` | `"a"`, `"b"`, `"c"` |
| **Rango** | `[a-z]` | Cualquier carácter en el rango | `[0-9]` | `"0"`, `"1"`, ..., `"9"` |
| **Negación** | `[^a]` | Cualquier carácter EXCEPTO `a` | `[^0-9]` | todo menos dígitos |
| **Punto** | `.` | Cualquier carácter (excepto `\n`) | `.` | `"a"`, `"1"`, `"+"`, ... |

### 4.2 Precedencia de operadores (de mayor a menor)

1. `()` — Agrupación
2. `*`, `+`, `?` — Repetición
3. Concatenación (implícita)
4. `|` — Unión

Ejemplo: `ab|cd` se interpreta como `(ab)|(cd)`, NO como `a(b|c)d`.

### 4.3 Expresiones regulares de tu proyecto

**Identificador (NAME):**
```
[a-zA-Z_][a-zA-Z0-9_]*
```
Desglose:
- `[a-zA-Z_]` → el primer carácter DEBE ser letra o guión bajo
- `[a-zA-Z0-9_]*` → los siguientes (cero o más) pueden ser letras, dígitos o guión bajo
- Acepta: `x`, `foo`, `_temp`, `myVar2` 
- Rechaza: `2bad` (inicia con dígito), `my-var` (tiene guión)

**Número (NUMBER):**
```
[0-9]+(\.[0-9]+)?
```
Desglose:
- `[0-9]+` → uno o más dígitos (parte entera obligatoria)
- `(\.[0-9]+)?` → opcionalmente, un punto seguido de uno o más dígitos
- Acepta: `0`, `42`, `3.14`, `100.0`
- Rechaza: `.5` (no tiene parte entera), `3.` (nada después del punto)

**Cadena (STRING):**
```
"([^"\\\n]|\\.)*"
```
Desglose:
- `"` → comilla de apertura
- `(...)* ` → cero o más de lo siguiente:
  - `[^"\\\n]` → cualquier carácter excepto `"`, `\` y `\n`
  - `|\\.` → O un `\` seguido de cualquier carácter (escape)
- `"` → comilla de cierre
- Acepta: `"hola"`, `"con \"comillas\""`, `"línea1"`
- Rechaza: `"sin cierre` (falta la `"` final → error)

**Comentario:**
```
#[^\n]*
```
- `#` → inicia con #
- `[^\n]*` → cero o más caracteres que no sean salto de línea
- Se consume sin generar token

**Keyword (ejemplo: `def`):**
```
"def"
```
- Cadena literal exacta entre comillas en flex
- En flex, las comillas hacen que se tome como texto literal

---

## 5. Autómata Finito Determinista (AFD / DFA)

Un AFD es una **máquina abstracta** que lee una cadena símbolo por símbolo y decide si la acepta o rechaza.

### 5.1 Definición formal

Un AFD es una 5-tupla: **M = (Q, Σ, δ, q₀, F)**

| Elemento | Nombre | Qué es |
|----------|--------|--------|
| **Q** | Estados | Conjunto finito de estados posibles |
| **Σ** | Alfabeto | Conjunto finito de símbolos de entrada |
| **δ** | Función de transición | `δ: Q × Σ → Q` — dado un estado y un símbolo, da exactamente UN estado siguiente |
| **q₀** | Estado inicial | El estado donde empieza la máquina (q₀ ∈ Q) |
| **F** | Estados de aceptación | Subconjunto de Q. Si terminas aquí, la cadena es aceptada (F ⊆ Q) |

### 5.2 Características del AFD (por qué es "determinista")

- Para cada combinación (estado, símbolo) existe **exactamente UNA** transición
- **No hay ambigüedad**: siempre sabes a qué estado ir
- **No hay transiciones ε**: no puedes cambiar de estado sin leer un símbolo

### 5.3 Cómo funciona

```
1. Empiezas en q₀
2. Lees el siguiente símbolo de la entrada
3. Consultas δ(estado_actual, símbolo) → obtienes el nuevo estado
4. Repites hasta que se acabe la entrada
5. Si estás en un estado ∈ F → ACEPTA
   Si no → RECHAZA
```

### 5.4 Ejemplo completo — AFD para números enteros `[0-9]+`

**Definición formal:**
- Q = {q₀, q₁}
- Σ = {0, 1, 2, ..., 9, todo lo demás}
- q₀ = q₀
- F = {q₁}
- δ:

| Estado | dígito | otro |
|--------|--------|------|
| q₀ | q₁ | error |
| q₁ | q₁ | (termina, acepta) |

**Diagrama:**
```
                dígito        dígito
  inicio ──► ( q₀ ) ────► (( q₁ )) ─┐
                                ▲     │
                                └─────┘
  
  ( )  = estado normal
  (( )) = estado de aceptación (doble círculo)
  ──►  = estado inicial
```

**Traza para "42":**
| Paso | Estado | Símbolo | δ(estado, símbolo) | Nuevo estado |
|------|--------|---------|-------------------|--------------|
| 1 | q₀ | '4' | δ(q₀, dígito) | q₁ |
| 2 | q₁ | '2' | δ(q₁, dígito) | q₁ |
| fin | q₁ | — | q₁ ∈ F | **ACEPTA** ✓ |

**Traza para "" (vacía):**
| Paso | Estado | Símbolo | Resultado |
|------|--------|---------|-----------|
| fin | q₀ | — | q₀ ∉ F → **RECHAZA** ✗ |

---

## 6. Autómata Finito No Determinista (AFN / NFA)

Un AFN es como un AFD pero **más flexible** (y por eso más fácil de construir).

### 6.1 Diferencias con el AFD

| Aspecto | AFD | AFN |
|---------|-----|-----|
| Transiciones por (estado, símbolo) | Exactamente 1 | 0, 1 o muchas |
| Transiciones ε | No permitidas | Permitidas |
| Aceptación | Estar en estado final | Al menos UN camino llega a estado final |
| Eficiencia de ejecución | Rápida (una sola ruta) | Lenta (explorar múltiples rutas) |
| Facilidad de construcción | Más difícil | Más fácil |

### 6.2 Transiciones épsilon (ε)

Una transición ε permite cambiar de estado **sin consumir ningún símbolo** de la entrada. Es como un "atajo" gratuito.

```
  (q₀) ──ε──► (q₁) ──a──► ((q₂))
  
  Estando en q₀, puedes "saltar" a q₁ sin leer nada.
```

### 6.3 ¿Por qué existen los AFN?

Porque es **mucho más fácil** convertir una expresión regular a AFN que directamente a AFD. El proceso es:

```
  Expresión Regular ──fácil──► AFN ──algoritmo──► AFD ──optimizar──► AFD mínimo
                                                   │
                                        Flex hace todo esto
                                        automáticamente por ti
```

### 6.4 Equivalencia AFN ↔ AFD (Teorema fundamental)

**Para todo AFN existe un AFD equivalente que reconoce exactamente el mismo lenguaje.**

La conversión se hace con la **construcción de subconjuntos**: cada estado del nuevo AFD es un *conjunto* de estados del AFN original. Si el AFN tiene n estados, el AFD puede tener hasta 2ⁿ estados (en la práctica, muchos menos).

**¿Qué significa esto para ti?** Que puedes pensar en términos de AFN (más intuitivo) sabiendo que siempre se puede convertir a AFD (más eficiente). Flex hace esta conversión internamente.

---

## 7. Tabla de Transición

Es la función δ escrita como **tabla**. Es exactamente la misma información que el diagrama de estados, pero en formato que se puede implementar como un arreglo 2D en código.

**Ejemplo — AFD para identificadores:**

| Estado | `[a-zA-Z_]` | `[0-9]` | otro |
|--------|-------------|---------|------|
| → q₀ | q₁ | error | error |
| \*q₁ | q₁ | q₁ | acepta |

- `→` = estado inicial
- `*` = estado de aceptación
- Cada celda = `δ(estado, clase_de_símbolo)`

**¿Por qué importa?** El scanner ejecuta esencialmente este loop:

```
estado = q₀
para cada carácter c:
    estado = tabla[estado][tipo(c)]
    if estado == error: reportar error
if estado ∈ F: aceptar token
```

---

## 8. Tokens

Un **token** es la unidad mínima que produce el scanner. Es una "palabra" del lenguaje de programación ya clasificada.

### 8.1 Componentes de un token

| Componente | Qué es | Ejemplo |
|------------|--------|---------|
| **Tipo (Token ID)** | Categoría | `NAME`, `NUMBER`, `IF`, `PLUS` |
| **Lexema** | Texto original del código | `"compute"`, `"42"`, `"if"`, `"+"` |
| **Línea** | Dónde apareció | `1`, `5`, `23` |

### 8.2 Ejemplo

Para el código:
```python
def foo(x):
    return x + 1
```

El scanner produce:
```
(DEF,     "def",    línea 1)
(NAME,    "foo",    línea 1)
(LPAREN,  "(",      línea 1)
(NAME,    "x",      línea 1)
(RPAREN,  ")",      línea 1)
(COLON,   ":",      línea 1)
(NEWLINE, "\n",     línea 1)
(RETURN,  "return", línea 2)
(NAME,    "x",      línea 2)
(PLUS,    "+",      línea 2)
(NUMBER,  "1",      línea 2)
(NEWLINE, "\n",     línea 2)
```

---

## 9. Token IDs

Cada tipo de token recibe un **número entero único**. Se agrupan por categoría para mantener orden:

| Rango | Categoría |
|-------|-----------|
| 100–117 | Keywords (18 keywords) |
| 200–202 | Identificadores y literales |
| 300–317 | Operadores (18 operadores) |
| 400–416 | Delimitadores (17 delimitadores) |
| 500–502 | Indentación |
| 999 | Error |

---

## 10. Tabla de Símbolos

Es una estructura de datos que registra **información sobre los identificadores y literales** encontrados durante el análisis léxico. Será usada por las fases posteriores del compilador (sintaxis, semántica).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| token | string | Tipo: NAME, NUMBER, STRING |
| identificador | string | El lexema |
| valor | string | Valor asociado (o `---`) |
| error | string | Mensaje de error (o `---`) |

**Ejemplo para `x = 10; msg = "hola"`:**

| Token | Identificador | Valor | Error |
|-------|---------------|-------|-------|
| NAME | x | --- | --- |
| NUMBER | (literal) | 10 | --- |
| NAME | msg | --- | --- |
| STRING | (literal) | "hola" | --- |

**Ejemplo con errores:**

| Token | Identificador | Valor | Error |
|-------|---------------|-------|-------|
| NAME | 2bad | --- | Identificador inválido: inicia con dígito |
| STRING | (literal) | "hola | Cadena no terminada |
| (desconocido) | $ | --- | Carácter inválido |

---

## 11. Lex/Flex

### 11.1 ¿Qué es?

**Flex** (Fast Lexical Analyzer Generator) es una herramienta que:
1. Tú escribes un archivo `.l` con expresiones regulares y acciones
2. Flex genera código C/C++ que implementa un AFD optimizado
3. Tú compilas ese código y tienes un scanner ejecutable

### 11.2 Estructura del archivo .l

```
%{
  /* SECCIÓN 1: DEFINICIONES */
  /* Código C/C++ copiado directamente al archivo generado */
  /* #includes, variables globales, funciones auxiliares */
%}

/* Definiciones de patrones reutilizables */
DIGIT    [0-9]
LETTER   [a-zA-Z_]

%%
  /* SECCIÓN 2: REGLAS */
  /* patrón    { acción en C/C++ } */

"if"        { return TOK_IF; }
{DIGIT}+    { return TOK_NUMBER; }
.           { printf("Error"); }

%%
  /* SECCIÓN 3: CÓDIGO DE USUARIO */
  /* Funciones auxiliares, main() */

int main() {
    yylex();  /* ejecutar el scanner */
    return 0;
}
```

### 11.3 Reglas de prioridad de Flex

**Regla 1 — Longest Match (coincidencia más larga):**
Flex siempre elige la regla que consume **más caracteres**.
- Input: `==`
- Regla `"="` coincide con 1 carácter
- Regla `"=="` coincide con 2 caracteres
- Flex elige `"=="` ✓

**Regla 2 — First Match (primera regla):**
Si dos reglas coinciden con la **misma longitud**, Flex elige la que aparece **primero** en el archivo.
- Input: `if`
- Regla `"if"` (keyword) coincide con 2 caracteres
- Regla `[a-zA-Z_]+` (identificador) coincide con 2 caracteres
- Si `"if"` está primero → se clasifica como keyword ✓
- Si `[a-zA-Z_]+` está primero → se clasificaría como NAME ✗

**Por eso las keywords DEBEN ir ANTES que la regla de identificadores.**

### 11.4 Variables especiales de Flex

| Variable | Qué contiene |
|----------|-------------|
| `yytext` | El lexema que acaba de coincidir (string) |
| `yyleng` | Longitud del lexema |
| `yyin` | Archivo de entrada (por defecto `stdin`) |
| `yylex()` | Función que ejecuta el scanner |

### 11.5 Compilación

```bash
# 1. Flex genera código C++ a partir del .l
flex -o lex.yy.cpp scanner.l

# 2. Compilar con g++
g++ -std=c++17 -o scanner lex.yy.cpp -ll

# 3. Ejecutar
./scanner archivo_de_prueba.triton
```

---

## 12. Errores Léxicos

El scanner debe detectar y reportar tres tipos de errores:

| Error | Ejemplo | Causa | Cómo detectarlo |
|-------|---------|-------|-----------------|
| **Carácter inválido** | `$` | No pertenece al alfabeto de Triton | La regla `.` al final del archivo flex |
| **Cadena no terminada** | `"hola` | Falta la comilla de cierre | Regla especial: `\"[^\"\n]*$` |
| **Identificador inválido** | `2bad` | Empieza con dígito | El scanner lee `2` como NUMBER, luego `bad` como NAME (son tokens separados) |

Cada error debe incluir: (1) tipo de error, (2) el texto problemático, (3) número de línea.

---

## 13. Jerarquía de Chomsky (contexto teórico)

| Tipo | Nombre | Reconocido por | Ejemplo |
|------|--------|---------------|---------|
| **3** | **Regular** | **Autómata Finito (AFD/AFN)** | **← AQUÍ ESTÁS TÚ** |
| 2 | Libre de contexto | Autómata de pila | Sintaxis (siguiente fase) |
| 1 | Sensible al contexto | Autómata linealmente acotado | — |
| 0 | Recursivamente enumerable | Máquina de Turing | — |

El análisis léxico opera en el **Tipo 3** (lenguajes regulares). Las expresiones regulares y los autómatas finitos son equivalentes y suficientes para esta fase.

---
---

# PARTE 2: LA ACTIVIDAD PASO A PASO

Todo lo que debes entregar, sacado directamente del PPTX del profesor.

---

## Información General

- **Materia:** TC3002B — Computer Science Advanced Applications Development
- **Módulo 3:** Compilers — Step I: Lexical Analysis Phase
- **Lenguaje objetivo:** Triton GPU Kernel (DSL tipo Python de OpenAI)
- **Fecha de entrega:** 30 de abril de 2026
- **Modalidad:** Individual
- **Formato de entrega:** ZIP con código fuente de ambos analizadores léxicos
- **Medio:** Canvas

---

## Evaluación General

| Componente | Peso |
|-----------|------|
| **Software** (el scanner funciona) | **50%** |
| **Reporte escrito** (documento formal) | **50%** |
| **Examen oral** | Multiplicador × 100% (puede bajar tu nota a 0) |

---

## ENTREGABLE 1: SOFTWARE (50%)

### Qué debe hacer el scanner

1. **Reconocer todos los tokens** del lenguaje Triton aprobados por el profesor
2. **Imprimir la secuencia de tokens** en orden de aparición
3. **Construir e imprimir la tabla de símbolos** para NAME, NUMBER y STRING
4. **Detectar e imprimir errores léxicos** con mensajes descriptivos y número de línea

### Restricciones ESTRICTAS

- ✅ DEBE implementarse con **lex/flex**
- ❌ NO usar librerías de expresiones regulares (regex libraries) del lenguaje
- ❌ NO usar el módulo `ast` de Python
- ❌ NO usar código open-source o de internet
- ✅ SÍ puedes usar código de prácticas de clase o ejercicios del curso
- ⚠️ SÍ puedes consultar AI, pero DEBES entender cada línea de código y poder responder preguntas sobre ella

### Rúbrica del Software

| Aspecto | 100 puntos | 0 puntos | Peso |
|---------|-----------|----------|------|
| **Cumple requerimientos** | Corre, reconoce todos los tokens, detecta errores, imprime lista de tokens y tabla de símbolos | No corre, no identifica todos los tokens, usa regex APIs, o no usa lex | **80%** |
| **Comentarios en código** | Todo el código extraordinariamente documentado, cada función descrita | Sin comentarios | **5%** |
| **Trazabilidad** | Cada requerimiento funcional se mapea a código específico | Pobre trazabilidad | **5%** |
| **Testing** | Pasa todos los casos de prueba del profesor | No pasa los tests | **10%** |

### Los 57 tokens a reconocer (del Lexer.xlsx)

**18 Keywords:**
`def`, `return`, `if`, `else`, `elif`, `for`, `while`, `in`, `is`, `and`, `or`, `not`, `True`, `False`, `None`, `pass`, `break`, `continue`

**3 Identificadores/Literales:**
`NAME` (identificadores), `NUMBER` (números), `STRING` (cadenas)

**18 Operadores:**
`+`, `-`, `*`, `/`, `//`, `%`, `**`, `<`, `>`, `<=`, `>=`, `==`, `!=`, `=`, `+=`, `-=`, `*=`, `/=`

**17 Delimitadores:**
`(`, `)`, `[`, `]`, `{`, `}`, `,`, `:`, `.`, `@`, `->`, `~`, `&`, `|`, `^`, `<<`, `>>`

**3 Indentación:**
`NEWLINE`, `INDENT`, `DEDENT`

### Tokens que necesitan autómata (del Lexer.xlsx)

Según la columna "Tipo esperado" del Excel:

| Token | Necesita |
|-------|----------|
| NAME (identificadores) | Autómata + tabla de transición |
| NUMBER (números) | Autómata + tabla de transición |
| STRING (cadenas) | Autómata + tabla de transición |
| if, else, elif | Autómata combinado + tabla de transición |
| while | Autómata + tabla de transición |
| +, -, *, /, //, %, ** | Autómata para expresiones aritméticas + tabla de transición |
| El resto de keywords y delimitadores | Solo REGEX |

---

## ENTREGABLE 2: REPORTE ESCRITO (50%)

### Estructura obligatoria del reporte

El reporte debe seguir el estándar **IEEE-830** y contener estas secciones:

---

### Sección 1: Introducción (Peso: 2%)

#### 1.1 Resumen
Descripción breve del contenido del reporte.

#### 1.2 Notación
Debes explicar:
- Qué son las máquinas de estado finito (AFD)
- Qué son las expresiones regulares
- Qué son las tablas de transición
- Qué modelo se usó para el análisis y diseño (y justificación)
- Justificación de la herramienta (por qué lex/flex)
- Justificación del lenguaje de programación (C++ con flex)

---

### Sección 2: Análisis (Peso: 20%)

Esta sección responde al **QUÉ** (qué debe hacer el scanner, no cómo).

Debe incluir:

1. **Descripción informal de los componentes léxicos**
   - Lista de todas las categorías de tokens con descripción en español
   
2. **Especificación formal con expresiones regulares**
   - La regex para CADA tipo de token
   - Con explicación de por qué esa regex es correcta

3. **Descripción y justificación de tokens y sus IDs**
   - Tabla con todos los Token IDs asignados
   
4. **Descripción y justificación de mensajes de error**
   - Cada tipo de error, su mensaje, y un ejemplo

5. **Narrativa coherente**
   - Todo debe estar conectado con texto explicativo, no solo tablas sueltas

---

### Sección 3: Diseño (Peso: 20%)

Esta sección responde al **CÓMO** (el blueprint de la implementación).

Debe incluir:

1. **Descripción informal del diseño**
2. **Los autómatas (DFA) del lenguaje** — diagramas de estados
3. **La tabla de transición más eficiente**
4. **Lista de Token IDs**
5. **Gestión de la tabla de símbolos** — algoritmo + estructura de datos
6. **Trazabilidad al modelo de análisis** — cada requerimiento del análisis debe tener su correspondencia en el diseño
7. **Narrativa coherente**

**Nota del profesor:** El "acid test" del diseño es: si le das tu documento a otro programador que no te conoce, ¿puede implementar el scanner sin preguntarte nada?

---

### Sección 4: Implementación con lex (Peso: 40%)

Debe incluir:

1. **Printout completo del archivo .l**
2. **Explicación de la Sección de Definiciones** — cada #include, variable, patrón
3. **Explicación de la Sección de Reglas** — cada regla y su acción
4. **Explicación de la Sección de Código de Usuario** — cada función
5. **Todo en narrativa coherente** — no solo código pegado
6. **Trazable al análisis y diseño** — debe ser evidente cómo el código implementa el diseño

---

### Sección 5: Verificación y Validación (Peso: 3%)

Debe incluir:

1. **Descripción informal del modelo de pruebas**
2. **Diseño de casos de prueba** — qué pruebas, por qué esas pruebas
3. **Justificación** — por qué cada test case cubre un aspecto importante
4. **Archivos de prueba propios** con resultados esperados
5. **Snapshots de la salida del scanner** para cada test
6. **Tu implementación DEBE pasar tus tests Y los del profesor**

---

### Sección 6: Plan de Trabajo
Cronograma de las actividades realizadas.

---

### Sección 7: Referencias
Formato **IEEE Reference Style** obligatorio.

Ejemplo de libro:
> Alfred V. Aho, Monica S. Lam, Ravi Sethi, and Jeffrey D. Ullman, *Compilers: Principles, Techniques, and Tools*, 2nd edition (Pearson/Addison-Wesley, 2007), 109–189.

Ejemplo de internet:
> OpenAI, *Triton Language and Compiler Documentation*, accessed April 2026; available from https://triton-lang.org/; Internet.

Ejemplo de clase:
> S. Hinojosa, Class Lecture, Topic: "Lexical Analysis." TC3002B, School of Engineering and Science, ITESM, Guadalajara, Jal., April, 2026.

---

### Rúbrica del Reporte

| Aspecto | 100 puntos | 0 puntos | Peso |
|---------|-----------|----------|------|
| Aspectos generales (tiene todas las secciones) | Completo | Incompleto | 2% |
| Formato y presentación | Profesional, figuras numeradas, refs en texto | Incompleto | 3% |
| Ortografía | 0 errores | Cualquier error | 10% |
| Introducción | Bien desarrollada con resumen y notación | No existe | 2% |
| **Análisis** | Especificación completa, regex, tokens, errores, narrativa | Ambiguo/incorrecto | **20%** |
| **Diseño** | Autómatas, tabla transición, Token IDs, tabla símbolos, trazable | Ambiguo/incorrecto | **20%** |
| **Implementación** | Código completo, explicado, trazable | No funciona | **40%** |
| Testing | Casos de prueba con justificación | No existe | 3% |

---

## ENTREGABLE 3: EXAMEN ORAL (Multiplicador)

| Aspecto | 100 puntos | 0 puntos | Peso |
|---------|-----------|----------|------|
| **Preguntas sobre el software** | Conocimiento completo del código, funcionalidad, archivos | Cheating | **60%** |
| **Modificaciones en vivo** | Puede modificar el código al vuelo según pida el profesor | Cheating | **30%** |
| **Preguntas sobre el proceso** | Puede responder sobre requerimientos, análisis, diseño, implementación | Cheating | **10%** |

**ADVERTENCIA:** Si se detecta plagio → **calificación FINAL del módulo = 0** + reporte de integridad académica (AIF).

---

## Checklist Final

Antes de entregar, verifica:

- [ ] El scanner **compila y corre** sin errores ni warnings
- [ ] Reconoce las **18 keywords** correctamente (no como NAME)
- [ ] Reconoce **identificadores** (NAME) — letras, dígitos, _
- [ ] Reconoce **números** — enteros y flotantes
- [ ] Reconoce **cadenas** — comillas dobles, con escapes
- [ ] Reconoce los **18 operadores** — incluyendo los de 2 caracteres antes que los de 1
- [ ] Reconoce los **17 delimitadores** — incluyendo `->`, `<<`, `>>`
- [ ] Detecta **cadenas no terminadas** con mensaje de error y línea
- [ ] Detecta **caracteres inválidos** con mensaje de error y línea
- [ ] Imprime la **secuencia completa de tokens** con ID, lexema y línea
- [ ] Imprime la **tabla de símbolos** con token, identificador, valor y error
- [ ] Los **comentarios** (`#...`) se consumen sin generar token
- [ ] Los **espacios y tabs** se consumen sin generar token
- [ ] El código tiene **comentarios exhaustivos**
- [ ] El reporte tiene **todas las secciones** del PPTX
- [ ] Las **figuras y tablas** están numeradas y referenciadas en el texto
- [ ] Las **referencias** usan formato IEEE
- [ ] **0 errores de ortografía** en el reporte
- [ ] Puedes **explicar cada línea** de tu código en el examen oral
- [ ] Puedes **modificar el código en vivo** si el profesor lo pide
