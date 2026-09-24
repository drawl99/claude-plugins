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

| Etapa | Sub-agente | Modelo | Recibe | Devuelve |
|---|---|---|---|---|
| Plan (solo si entenderlo exige leer 4 archivos o más) | uno de solo lectura | `plan` (opus) | la issue completa, la ruta del checkout, la rama base, las convenciones del repo | el plan en 3 a 6 líneas y los archivos que toca, con la razón de cada decisión no obvia |
| Implementación | uno solo que escribe (`general-purpose` en Claude Code; equivalentes en [hosts.md](hosts.md)) | `implement` (sonnet) | la issue completa, el plan, la ruta del checkout y la rama (ya creada; que no cambie de rama ni commitee), las convenciones del repo (`CLAUDE.md`), los comandos de `verify` que aplican, TDD estricto si el repo lo exige | archivos tocados, evidencia del test en rojo antes del cambio y en verde después, resultado de la suite, lo que no pudo verificar |
| Revisión | `/code-review` en Claude Code; en otros hosts, un sub-agente de revisión de solo lectura | `review` (opus) solo en el sub-agente; `/code-review` usa el suyo | el diff de la rama | hallazgos, del más grave al menos grave |
| Correcciones de la revisión | el mismo sub-agente de implementación si sigue disponible, o uno nuevo con el reporte anterior | `fix` (sonnet) | solo los hallazgos de esta issue | lo mismo que la implementación |

- **Un solo sub-agente escribe a la vez.** Nunca dos escribiendo en paralelo
  sobre la misma rama.
- **El plan** (3 a 6 líneas, en el comentario de la issue) lo escribe la sesión
  principal si sale de la issue y de una lectura puntual. Si entender el cambio
  exige leer 4 archivos o más, lo escribe el sub-agente de plan, y la sesión
  principal lo revisa y lo publica.
- **Pide reportes cortos:** hechos verificables (archivos, conteos de tests,
  líneas clave de error), no el log completo. Si un reporte afirma algo
  importante, compruébalo con una lectura puntual o un comando corto antes de
  darlo por cierto.
- Commit, push, PR y comentarios en las issues los hace la sesión principal.

### Modelo por etapa

La regla es simple: **lo que exige razonar (planear, revisar) va con opus; lo
que ejecuta (escribir código, correr pruebas, corregir hallazgos concretos) va
con sonnet.** Los modelos de cada etapa salen de `models` en las preferencias
personales ([config.md](config.md)); sin esa clave, los de la tabla.

- En Claude Code, pásalo en el parámetro `model` de `Agent`. En otros hosts,
  si la herramienta de sub-agentes acepta un modelo por llamada, pásalo; si no,
  usa el del host y dilo una vez en el chequeo de requisitos (ver
  [hosts.md](hosts.md)).
- **Escalada:** si la implementación con sonnet termina con pruebas que no pasan
  y no sabe por qué (no por el entorno), el reintento va con el modelo de
  `plan`, con el reporte anterior. Una sola vez; si sigue fallando, detente y
  avisa. Escala también de entrada si la issue toca seguridad, dinero o
  concurrencia, aunque vaya directa: ahí un error de criterio es caro.
- Si no tienes acceso al modelo pedido (por ejemplo, sin opus), usa sonnet y
  sigue.
- Esto es **solo para la ruta directa**. En la ruta SDD, gentle-ai asigna el
  modelo de cada fase con su propia tabla: no la pises.
- `"inherit"` en una etapa usa el modelo de la sesión principal.

## Entre issues, en modo automático

- Al cerrar cada issue, deja el estado donde sobreviva: el PR (con qué se
  verificó y qué no) y un comentario final en la issue. Si Engram está
  disponible, un resumen corto de la issue.
- En la conversación, cierra cada issue con **un párrafo corto** (issue, PR,
  estado del CI, issues derivadas) y no vuelvas sobre sus detalles.
- La siguiente issue arranca de GitHub y del repo, no de lo que quedó en el
  contexto de la anterior.
