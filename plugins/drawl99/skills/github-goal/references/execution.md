# Ejecución: sub-agentes y contexto de la sesión

La sesión que corre `github-goal` es un **orquestador**: decide, pregunta,
comenta en las issues, abre PRs. El trabajo pesado (leer mucho código, escribir,
correr suites largas, revisar) lo hacen sub-agentes con contexto propio, que
devuelven un resumen corto. Así una corrida en automático puede encadenar
varias issues sin llenar el contexto ni forzar compactaciones.

Todo se ejecuta en el checkout del repo elegido (Paso 1.1 de `SKILL.md`): la
sesión principal y cada sub-agente usan `git -C <ruta>`, `gh ... -R <owner/repo>`
y `cd <ruta> && ...` en cada comando, y los sub-agentes reciben esa ruta.

## Qué hace la sesión principal, y qué no

**Sí, directamente:**

- Llamadas a GitHub sobre issues (leer, comentar, asignar, crear issues
  derivadas, cerrar tras un merge verificado).
- Estado de git y GitHub (`git status`, ramas, `gh pr create`, `gh pr checks`).
- Leer de 1 a 3 archivos chicos para decidir o verificar algo puntual.
- Preguntar al usuario y presentar las decisiones.

**No, nunca en la sesión principal:**

- Explorar el código a fondo (4 archivos o más).
- Escribir o editar código de producción o tests.
- Correr suites de tests o builds largos: sus logs son lo que más llena el
  contexto.
- Pegar diffs completos, logs o archivos enteros en el chat.

## Ruta SDD completa: gentle-ai

El SDD es el de **gentle-ai**: sus skills `sdd-*`, sus agentes `sdd-*` y su
dispatcher (`gentle-ai sdd-status` / `gentle-ai sdd-continue`). Cada fase ya
corre en su propio sub-agente, así que el contexto queda protegido por diseño.

1. Lee el flujo de orquestación de gentle-ai de tu host antes de la primera
   fase (dónde está en cada host: [hosts.md](hosts.md)).
2. **Preflight de sesión de SDD sin preguntar:** gentle-ai pide cuatro valores
   (ritmo, almacén de artefactos, estrategia de PRs, presupuesto de revisión).
   Tómalos de `sdd` en la config del repo (ver
   [config.md](config.md)) y preséntalos como el bloque de preflight ya decidido.
   El ritmo es siempre `auto` dentro de `github-goal`. Si falta algún valor en la
   config, pregúntalo **una sola vez por corrida**, no por issue.
3. Arranca con el equivalente de `/sdd-new <change>` (nombre del cambio en
   kebab-case, derivado del título) y sigue fase por fase con el dispatcher
   hasta `verify`. El nombre del cambio va en la descripción del PR.
4. El archivo (`sdd-archive`) va después del merge, según
   [archive.md](archive.md).
5. Si gentle-ai pide consentimiento de revisión, preséntalo tal cual al usuario
   y ejecuta la respuesta que elija; nunca respondas por él.

## Ruta directa: sub-agentes

Un sub-agente por etapa, en orden. Cada uno recibe lo necesario para trabajar
sin leer la conversación, y devuelve un reporte corto.

| Etapa | Sub-agente | Recibe | Devuelve |
|---|---|---|---|
| Implementación | uno solo que escribe (`general-purpose` en Claude Code; equivalentes en [hosts.md](hosts.md)) | la issue completa, el plan, la ruta del checkout y la rama (ya creada; que no cambie de rama ni commitee), las convenciones del repo (`CLAUDE.md`), los comandos de `verify` que aplican, TDD estricto si el repo lo exige | archivos tocados, evidencia del test en rojo antes del cambio y en verde después, resultado de la suite, lo que no pudo verificar |
| Revisión | `/code-review` en Claude Code; en otros hosts, un sub-agente de revisión de solo lectura | el diff de la rama | hallazgos, del más grave al menos grave |
| Correcciones de la revisión | el mismo sub-agente de implementación si sigue disponible, o uno nuevo con el reporte anterior | solo los hallazgos de esta issue | lo mismo que la implementación |

- **Un solo sub-agente escribe a la vez.** Nunca dos escribiendo en paralelo
  sobre la misma rama.
- **El plan lo escribe la sesión principal** (3 a 6 líneas, en el comentario de
  la issue) a partir de la issue y de una lectura puntual. Si entender el cambio
  exige leer 4 archivos o más, pídele el mapa a un sub-agente de exploración de
  solo lectura antes de escribir el plan.
- **Pide reportes cortos:** hechos verificables (archivos, conteos de tests,
  líneas clave de error), no el log completo. Si un reporte afirma algo
  importante, compruébalo con una lectura puntual o un comando corto antes de
  darlo por cierto.
- Commit, push, PR y comentarios en las issues los hace la sesión principal.

## Entre issues, en modo automático

- Al cerrar cada issue, deja el estado donde sobreviva: el PR (con qué se
  verificó y qué no) y un comentario final en la issue. Si Engram está
  disponible, un resumen corto de la issue.
- En la conversación, cierra cada issue con **un párrafo corto** (issue, PR,
  estado del CI, issues derivadas) y no vuelvas sobre sus detalles.
- La siguiente issue arranca de GitHub y del repo, no de lo que quedó en el
  contexto de la anterior.
