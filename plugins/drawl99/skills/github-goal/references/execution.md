# Ejecución: gentle-ai implementa, github-goal orquesta GitHub

La sesión que corre `github-goal` orquesta el flujo de GitHub: decide qué issue
tomar, la reclama, crea la rama, abre el PR, espera el CI y, si corresponde,
mergea y archiva. **La ruta (directo o SDD) y la implementación son de
gentle-ai**: `github-goal` no decide la ruta, no planea ni implementa por su
cuenta y no elige modelos. Tampoco vuelve a decidir lo que gentle-ai ya
decidió.

El trabajo de cada issue se ejecuta en su worktree (`<worktree>`, ver
*Worktree por issue* en [concurrency.md](concurrency.md)); el clon principal
del Paso 1.1 solo se usa para `fetch` y comandos de `worktree`. La sesión
principal y cada sub-agente usan `git -C <worktree>`, `gh ... -R <owner/repo>`
y `cd <worktree> && ...` en cada comando, y los sub-agentes reciben esa ruta.

## Qué hace github-goal, y qué no

**Sí, directamente:**

- Llamadas a GitHub sobre issues (leer, comentar, asignar, crear issues
  derivadas, cerrar tras un merge verificado).
- Estado de git y GitHub (`git status`, ramas, push, `gh pr create`,
  `gh pr checks`, merge).
- Preguntar al usuario y presentar las decisiones.

**No, nunca:**

- Elegir entre directo y SDD, ni pedirle a `workflow-decision` que lo haga.
- Planear, escribir código o tests, o lanzar sus propios sub-agentes de plan,
  implementación, revisión o corrección: eso lo hace gentle-ai con su
  enrutamiento y sus disparadores de delegación.
- Pegar diffs completos, logs o archivos enteros en el chat.

## Entrega de la issue a gentle-ai (ODD)

Con la issue reclamada y la rama creada en su worktree, entrégale la issue al
orquestador de gentle-ai, que la trabaja con su protocolo por defecto, **ODD**
(Organic Driven Development, cargado desde `CLAUDE.md`/`AGENTS.md`): explora,
clasifica el trabajo como chico o sustancial, y si es sustancial crea
`odd/tasks/<feature>.md` y su espejo en Engram, e implementa tarea por tarea con
commits de unidad de trabajo en la rama de la issue.

El pedido lleva, en un solo bloque:

- **Autorización explícita:** implementar la issue en la rama `<rama>` del
  worktree `<worktree>`, con commits de unidad de trabajo en esa rama. Invocar
  `github-goal` sobre la issue es la autorización de cambio que ODD exige en su
  primer paso. Push, PR y merge los hace `github-goal`, no gentle-ai.
- **La issue:** número, título, descripción completa y criterios de aceptación
  (la checklist de la issue, si la hay), más los comentarios relevantes.
- **Verificación:** las entradas de `verify` que apliquen (o lo que declare
  `CLAUDE.md`/`AGENTS.md`), para que las corra al cerrar cada tarea.
- **TDD:** el modo que declara el repo (`CLAUDE.md`/`AGENTS.md` o su
  configuración de gentle-ai), con su fuente y su runner. Si el repo no lo
  declara, no lo inventes: dilo y deja que gentle-ai resuelva la ambigüedad.
- **Commits:** convencionales, con el número de la issue, en el idioma de
  `language.commits` y sin ninguna atribución a Claude ni a la IA: ni
  trailers `Co-Authored-By` de Claude o de un agente, ni "Generated with
  Claude Code" (ver *Restricciones* en `SKILL.md`). Revisa los commits de
  gentle-ai antes de abrir el PR; si alguno trae esa atribución, pídele que
  reescriba el mensaje antes del push.
- **Estrategia de entrega:** `github-goal` abre exactamente un PR por issue,
  con `Fixes #<n>`, así que ODD (o SDD) no lo parte en PRs encadenados. La
  estrategia que se le indica depende de `sizeException` (ver *Tamaño del PR*,
  abajo): `exception-ok` si está en `"accept"` y el modo es automático;
  `single-pr` en cualquier otro caso.

Mientras gentle-ai trabaja, `github-goal` no interviene: no corrige su ruta, no
salta sus preguntas de negocio y no reemplaza sus sub-agentes. Si gentle-ai se
detiene por una ambigüedad real de negocio, trátala como bloqueo (en
automático: comenta en la issue qué falta, sáltala y sigue con la siguiente; al
final repórtala). Cuando termina, pídele su reporte de cierre: ruta tomada y por
qué, commits, documento de la feature (si lo hay), comprobaciones que pasaron,
fallaron o no pudieron correr.

**Comenta la ruta en la issue** en dos o tres líneas
(`gh issue comment <n> -R <owner/repo> --body ...`): directo (chico o
sustancial, con el documento `odd/tasks/<feature>.md` si existe) o SDD (con el
nombre del cambio), y el porqué que dio gentle-ai. Lo mismo va en la
descripción del PR.

## Tamaño del PR: `size:exception`

El presupuesto de revisión de gentle-ai es de unas 400 líneas por PR. Como
`github-goal` abre un solo PR por issue, un trabajo más grande necesita
`size:exception`.

- **Automático, con `"sizeException": "accept"` en las preferencias
  personales:** es la aceptación explícita y por adelantado que el propio
  usuario configuró para `size:exception`, y solo vale en modo automático.
  Indícale a gentle-ai `delivery_strategy: exception-ok` para la issue, tanto
  en ODD como en SDD (para `sdd-tasks` y `sdd-apply`). Si el PR supera el
  presupuesto, agrégale el label `size:exception`
  (`gh pr edit <pr> -R <owner/repo> --add-label size:exception`; si el label no
  existe, créalo antes con `gh label create size:exception -R <owner/repo>`),
  y anota en la descripción del PR y en un comentario de la issue el tamaño
  aproximado (líneas agregadas más borradas) y por qué no se partió.
- **Sin esa clave** (o con cualquier otro valor, que cuenta como ausente), y
  siempre en modo una issue: `single-pr`. Si gentle-ai pide aceptar
  `size:exception`, preséntale la pregunta al usuario tal cual y espera: nunca
  la respondas tú.

## Preflight de SDD por adelantado (automático)

El preflight de sesión del SDD de gentle-ai solo vale si lo responde el
usuario, con la herramienta de preguntas del host, en la forma exacta de
gentle-ai: una sola llamada con las tres preguntas (ritmo, artefactos,
estrategia de PR), con sus marcadores `Gentle AI SDD preflight 1/3:`, `2/3:` y
`3/3:` y las etiquetas y el orden sin cambios. Un valor por defecto escrito por
el modelo nunca cuenta. La forma canónica está en *SDD Session Preflight* del
flujo SDD de gentle-ai de tu host ([hosts.md](hosts.md)): léela y síguela, no
la copies de memoria.

- **Modo automático:** hazlo **una vez por sesión**, apenas quedan fijos el
  alcance y el modo (Paso 2) y antes de reclamar la primera issue, para que la
  corrida no se detenga después. Si en esta sesión el preflight ya quedó
  establecido, no lo repitas. Indica cuál es la respuesta recomendada por la
  config **solo en la descripción** de la opción (por ejemplo, "Recomendada
  por la config de github-goal"), nunca en la etiqueta ni cambiando el orden:
  - ritmo: **Automatic**;
  - artefactos: según `sdd.artifactStore` de la config del repo (`engram` →
    **Engram**, `openspec` → **OpenSpec**, `hybrid` → **Both**; sin valor,
    **Engram**);
  - estrategia de PR: **Single PR**.

  En OpenCode y Pi, igual, con la herramienta de preguntas del host.
- **Modo una issue:** no lo adelantes; gentle-ai lo pide cuando corresponda.

La respuesta del usuario manda aunque no sea la recomendada. Con
`"sizeException": "accept"`, la estrategia que se le pasa a `sdd-tasks` y
`sdd-apply` sigue siendo `exception-ok` (ver *Tamaño del PR*); el preflight no
puede elegirla.

## Propuestas de SDD: aceptadas de antemano

Si gentle-ai propone SDD para la issue, **acéptala sin preguntar**, en los dos
modos: es la aceptación permanente del usuario para las issues que trabaja
`github-goal`. Después corre la cadena SDD de gentle-ai hasta `verify`:

1. Lee el flujo de orquestación SDD de gentle-ai de tu host antes de la primera
   fase (dónde está en cada host: [hosts.md](hosts.md)).
2. **Preflight de sesión:** en automático ya quedó hecho antes de la primera
   issue (ver *Preflight de SDD por adelantado*). En una issue, lo pide
   gentle-ai; no lo escribas tú ni lo des por respondido.
3. Arranca con el equivalente de `/gentle-sdd-new <change>` (nombre del cambio
   en kebab-case, derivado del título) y sigue fase por fase con el dispatcher
   nativo (`gentle-ai sdd-status` / `gentle-ai sdd-continue`) hasta `verify`,
   automático salvo ambigüedad real de negocio. La fase opcional
   `sdd-research` corre solo si gentle-ai la recomienda para una duda
   concreta. El nombre del cambio va en la descripción del PR.
4. Si el dispatcher pide autoridad de edición
   (`gentle-ai.sdd-integration.consent/*`), preséntala tal cual al usuario y
   espera: la aceptación de SDD no la cubre.
5. El archivo (`sdd-archive`) va después del merge, según
   [archive.md](archive.md).

## Revisión: RDD de gentle-ai o `/code-review`

Antes de la primera issue de la corrida, lee el modo efectivo con
`gentle-ai review mode status` (solo lectura) y muéstralo en el chequeo de
requisitos. Nunca lo cambies: el interruptor es del usuario.

- **RDD encendido:** la revisión es la nativa de gentle-ai (receipt-driven
  development), que revisa los commits de unidad de trabajo a medida que ODD
  los hace. **No corras además `/code-review`.** Antes de pushear y de abrir
  el PR, consulta
  `gentle-ai review status --cwd <worktree> --contract gentle-ai.review-integration/v2 --next-transition`
  y sigue solo la transición que devuelve (`execute` tal cual, `collect` con
  sus entradas exactas, `stop` detiene y reporta su `reason_code`). Nunca
  inventes ni completes comandos de revisión.
- **RDD apagado:** revisa como antes. Si existe `/code-review`, úsalo (corre
  aparte); en otros hosts, un sub-agente de revisión de solo lectura. Las
  correcciones se las pides a gentle-ai con los hallazgos de esta issue, no
  las hace la sesión principal.

En los dos casos, resuelve solo los hallazgos de esta issue; el resto va a una
issue nueva (ver *Issues que salen de una issue* en `SKILL.md`).

### Consentimiento de revisión

Cuando RDD devuelve el sobre de consentimiento
(`gentle-ai.review-integration.consent/*`, con las opciones `granted` y
`declined` y la `invocation` exacta de cada una):

- **Una issue:** preséntalo completo al usuario, sin resumir ni reordenar, como
  lo exige el contrato de gentle-ai, y espera su respuesta. Ejecuta solo la
  invocación de la opción que elija.
- **Automático, con `"reviewConsent": "granted"` en las preferencias
  personales:** ejecuta exactamente la invocación de la opción `granted`, sin
  cambiarle ningún token; nunca la de `declined`. Esa clave es la autorización
  explícita y permanente que el propio usuario configuró, y reemplaza el relevo
  al usuario **solo en modo automático**. Deja constancia en el comentario de
  la issue (y en el PR): consentimiento otorgado por la preferencia permanente
  del usuario, con el nivel de riesgo y los lentes que informó el sobre.
- **Automático, sin esa clave** (o con cualquier otro valor): igual que en una
  issue, preséntalo al usuario y espera.

Un recordatorio del hook de parada sobre un candidato sin revisar se trata
igual: consulta `gentle-ai review status ... --next-transition` y sigue la
transición que devuelve.

## Entre issues, en modo automático

- Al cerrar cada issue, deja el estado donde sobreviva: el PR (ruta, con qué se
  verificó y qué no) y un comentario final en la issue. Si Engram está
  disponible, un resumen corto de la issue.
- En la conversación, cierra cada issue con **un párrafo corto** (issue, ruta,
  PR, estado del CI, issues derivadas) y no vuelvas sobre sus detalles.
- La siguiente issue arranca de GitHub y del repo, no de lo que quedó en el
  contexto de la anterior.
