# Analizador Léxico — Triton GPU Kernel

## TC3002B — Actividad 3.1

Scanner para el lenguaje Triton GPU Kernel implementado con **flex** y **C++**.

### Estructura del repo

```
Automatas/
├── entrega/                         ← LO QUE SE ENTREGA (ZIP de esta carpeta)
│   ├── triton_lexer.l               ← Código fuente del scanner (archivo flex)
│   ├── reporte.md                   ← Reporte completo del proyecto
│   └── tests/                       ← Archivos de prueba .triton
│       ├── test1_basic.triton       ← Variables, números, cadenas
│       ├── test2_errors.triton      ← Cadena no terminada, carácter inválido
│       ├── test3_keywords.triton    ← Las 18 keywords
│       ├── test4_operators.triton   ← Todos los operadores y delimitadores
│       └── test5_triton_kernel.triton ← Kernel real de Triton
│
├── KnowledgeBase/                   ← GUÍAS DE REFERENCIA (no se entrega)
│   ├── guia_completa_actividad.md   ← Conceptos + actividad desglosada
│   └── guia_archivos_flex.md        ← Cómo funcionan los archivos .l
│
└── Recursos/                        ← Archivos del profesor
```

---

### Cómo compilar y ejecutar

#### Requisitos

- **flex** (generador de analizadores léxicos)
- **g++** (compilador de C++)

#### macOS

```bash
# Instalar flex y g++ (si no los tienes)
xcode-select --install          # incluye g++
brew install flex               # si no tienes flex

# Compilar
cd entrega/
flex -o lex.yy.cpp triton_lexer.l
g++ -std=c++17 -o triton_lexer lex.yy.cpp -ll

# Ejecutar
./triton_lexer tests/test1_basic.triton
```

#### Windows (con WSL o MinGW)

**Opción 1 — WSL (recomendado):**
```bash
# En WSL (Ubuntu)
sudo apt update && sudo apt install flex g++ -y

cd entrega/
flex -o lex.yy.cpp triton_lexer.l
g++ -std=c++17 -o triton_lexer lex.yy.cpp -lfl

./triton_lexer tests/test1_basic.triton
```

**Opción 2 — MinGW/MSYS2:**
```bash
# Instalar desde https://www.msys2.org/
pacman -S flex gcc

cd entrega/
flex -o lex.yy.cpp triton_lexer.l
g++ -std=c++17 -o triton_lexer.exe lex.yy.cpp -lfl

./triton_lexer.exe tests/test1_basic.triton
```

#### Linux

```bash
sudo apt install flex g++ -y    # Debian/Ubuntu
# o: sudo dnf install flex gcc-c++ -y  # Fedora

cd entrega/
flex -o lex.yy.cpp triton_lexer.l
g++ -std=c++17 -o triton_lexer lex.yy.cpp -lfl

./triton_lexer tests/test1_basic.triton
```

> **Nota:** En macOS se usa `-ll`, en Linux/WSL se usa `-lfl`. Si uno no funciona, prueba el otro.

---

### Tests disponibles

```bash
./triton_lexer tests/test1_basic.triton          # Tokens básicos
./triton_lexer tests/test2_errors.triton         # Detección de errores
./triton_lexer tests/test3_keywords.triton       # 18 keywords
./triton_lexer tests/test4_operators.triton      # Operadores y delimitadores
./triton_lexer tests/test5_triton_kernel.triton  # Kernel real de Triton
```

---

### Estado del proyecto

- [x] Sección 1 — Introducción (resumen + notación)
- [x] Sección 2 — Análisis (tokens, regex, errores)
- [x] Sección 3 — Diseño (AFDs, tablas de transición, tabla de símbolos)
- [x] Sección 4 — Implementación (printout completo + explicación)
- [x] Sección 5 — Testing (5 casos con resultados)
- [x] Sección 6 — Plan de trabajo
- [x] Sección 7 — Referencias IEEE
- [x] Código `.l` — Compila y pasa todos los tests
- [x] Revisión ortográfica

### Entrega

- **Fecha:** 30 de abril de 2026
- **Formato:** ZIP con la carpeta `entrega/`
- **Medio:** Canvas
