# Changelog

Cambios del plugin `drawl99`. Formato basado en
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones con
[SemVer](https://semver.org/lang/es/). Cada versión publicada tiene su tag
`drawl99--v<versión>`.

Para actualizar: `/plugin marketplace update drawl99` y después
`/plugin update drawl99@drawl99`, y reinicia Claude Code.

## [1.2.0] — 2026-09-24

### Agregado
- Ruta `auto` (`defaultRoute: "auto"` o "decide tú la ruta" al invocar): usa la
  ruta que recomienda `workflow-decision` sin preguntar y deja el porqué en la
  issue y en el PR. Una issue con ambigüedad de negocio se salta y se reporta.
- Argumentos en lenguaje natural:
  `/drawl99:github-goal automático milestone "v1.0", decide tú la ruta`. El
  milestone se resuelve contra los milestones abiertos del repo y fija el
  alcance sin preguntarlo; la corrida termina cuando a ese milestone no le
  quedan issues disponibles.
- Modelo por etapa en la ruta directa: opus para planear y revisar, sonnet para
  implementar y corregir. Configurable con `models` en las preferencias
  personales. La implementación escala a opus si falla sin causa clara o si la
  issue toca seguridad, dinero o concurrencia. La ruta SDD sigue con la tabla
  de gentle-ai.
- Sub-agente de plan (solo lectura) cuando entender el cambio exige leer 4
  archivos o más.

### Cambiado
- En automático, la política de ruta se fija **una vez** al arrancar, en vez
  de preguntar la ruta en cada issue, y se muestra el plan de la corrida en una
  línea.

## [1.1.0] — 2026-09-24

### Cambiado
- `github-goal` carga menos al invocarse: la elección de repo y checkout, el
  detalle de dependencias y sub-issues, y el ciclo de vida en GitHub (checks
  faltantes, cierre de la issue, estados) pasaron a `references/`
  (`repo-selection.md`, `dependencies.md`, `github-lifecycle.md`). Se leen solo
  cuando hacen falta. Los sub-pasos del Paso 1 se renumeraron (1.1 repo y
  checkout, 1.2 requisitos, 1.3 alcance, 1.4 rama base). Sin cambios de
  comportamiento.

## [1.0.0] — 2026-09-24

### Agregado
- Skill `/drawl99:github-goal`: la versión GitHub Issues del flujo linear-goal,
  para proyectos personales. La fuente de verdad son las issues de GitHub a
  través de `gh`; no necesita Linear ni ningún MCP.
  - Pregunta en qué repositorio trabajar, entre los propios y los de las
    organizaciones de la persona (con cada cuenta de `gh` si tiene varias), con
    el del directorio actual primero y sin asumirlo nunca. Usa un clon local de
    `workspaceDirs` o ofrece clonarlo, y corre cada comando en ese checkout.
  - Pregunta el alcance: un milestone, "Todas en orden" (milestones por fecha
    de entrega y las issues sin milestone según `unmilestoned`) o "Sin
    milestone".
  - Modos "una issue" (elegida de la lista, o pasada como argumento: `#123`,
    `123` u `owner/repo#123`) y "automático".
  - Orden por dependencias nativas de GitHub (`blocked_by`), dependencias
    escritas en la descripción (ofrece enlazarlas de forma nativa) y
    sub-issues (toma las sub-issues antes que el padre).
  - Selección configurable: asignadas a ti o sin asignar (`assignee`) y
    nombres de labels (`labels`); si el repo no tiene el label de lista, ese
    requisito se apaga para el repo.
  - Ramas enlazadas a la issue con `gh issue develop`, con nombre de
    `branchPattern`.
  - Cierre de issues cuando la rama base no es la rama por defecto: GitHub
    solo cierra con `Fixes #N` al mergear en la rama por defecto, así que la
    skill cierra la issue después de verificar el merge, o la próxima corrida
    lo ofrece.
  - Issues derivadas con asignado, milestone, labels y relación con la de
    origen; prioridad y estimado como labels si el repo los tiene, o en el
    cuerpo.
  - Chequeo de requisitos, configuración por repositorio
    (`.claude/github-goal.json`) y por persona
    (`~/.config/drawl99/github-goal.json`), retomar trabajo interrumpido,
    desbloqueo en repos con colaboradores, reglas de CI (un PR sin checks no
    es verde), archivo SDD después del merge, varias cuentas de `gh` sin
    cambiar la activa, y revisión humana obligatoria para `security`.
  - Ruta SDD con el SDD de **gentle-ai** y ruta directa con sub-agentes.
- Skill `/drawl99:workflow-decision`: recomienda SDD completo o flujo directo
  para una issue, con los motivos sacados de la issue.
- Evals en `plugins/drawl99/evals/`: 6 casos que fijan la ruta esperada y los
  motivos. Correr con
  `claude plugin eval plugins/drawl99 --runs 3 --trust-plugin`.
- Soporte para **OpenCode** (`scripts/install-opencode.sh`) y **Pi**
  (`package.json` en la raíz; `pi install git:git@github.com:drawl99/claude-plugins`).
