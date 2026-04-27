# Analizador Léxico — Triton GPU Kernel

## TC3002B — Actividad 3.1

Scanner para el lenguaje Triton GPU Kernel implementado con **flex** y **C++**.

### Estructura del repo

```
Automatas/
├── entrega/                    ← LO QUE SE ENTREGA (ZIP de esta carpeta)
│   ├── triton_lexer.l          ← Código fuente del scanner (archivo flex)
│   ├── reporte.md              ← Reporte del proyecto
│   └── tests/                  ← Archivos de prueba .triton
│
├── KnowledgeBase/              ← GUÍAS DE REFERENCIA (no se entrega)
│   ├── guia_completa_actividad.md   ← Conceptos + actividad desglosada
│   └── guia_archivos_flex.md        ← Cómo funcionan los archivos .l
│
└── Recursos/                   ← Archivos del profesor
```

### Cómo compilar y ejecutar

```bash
cd entrega/

# 1. Generar código C++ desde flex
flex -o lex.yy.cpp triton_lexer.l

# 2. Compilar
g++ -std=c++17 -o triton_lexer lex.yy.cpp -ll

# 3. Ejecutar c on un archivo de prueba
./triton_lexer tests/test1_basic.triton
```

### Estado actual

- [x] Sección 1 — Introducción (resumen + notación)
- [x] Sección 2 — Análisis (tokens, regex, errores)
- [x] Sección 3 — Diseño (AFDs, tablas de transición, tabla de símbolos)
- [x] Código `.l` — Compila y funciona
- [ ] Sección 4 — Implementación (explicar el código en el reporte)
- [ ] Sección 5 — Testing (crear tests, correrlos, documentar resultados)
- [ ] Sección 6 — Plan de trabajo

### Lo que falta (ver sección "Tareas pendientes" abajo)

**Persona A:** Sección 4 del reporte — explicar el archivo `.l` línea por línea
**Persona B:** Sección 5 del reporte — crear tests, correrlos, pegar resultados
**Persona C:** Sección 6 + revisión ortográfica + formato final

### Entrega

- **Fecha:** 30 de abril de 2026
- **Formato:** ZIP con la carpeta `entrega/`
- **Medio:** Canvas
