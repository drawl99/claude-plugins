---
name: github-goal
description: Trabaja issues de GitHub de un repositorio elegido por el usuario, una elegida o todas en automático en orden de milestones y dependencias. Verifica requisitos, pregunta el repositorio, el alcance y el modo al arrancar y, por cada issue, recomienda si usar SDD completo o flujo directo antes de implementar.
argument-hint: "[#123 | owner/repo#123]"
disable-model-invocation: true
---

# github-goal

Resuelve issues de GitHub de un repositorio: **una sola**, elegida por el
usuario, o **todas en automático** (goal), una a la vez y en orden de
milestones y dependencias. Solo se detiene en las preguntas que se indican aquí
y ante bloqueos reales.

**Solo arranca si el usuario la invocó** con el comando o la nombró. Si llegaste
aquí porque la inferiste de la conversación, no empieces: pregunta si quiere
correrla. (OpenCode ignora `disable-model-invocation`; esta regla lo cubre.)

**Host:** los nombres de herramientas son los de Claude Code. En OpenCode y Pi
usa los equivalentes de [references/hosts.md](references/hosts.md) (preguntas,
sub-agentes, revisión, SDD de gentle-ai). GitHub se usa con `gh` en todos los
hosts: no hace falta ningún MCP.

Se adapta a cada repositorio y a cada persona con dos archivos opcionales:
`.claude/github-goal.json` en el repo y, en el home,
`~/.config/drawl99/github-goal.json` (o `~/.claude/github-goal.json`).
Su formato, sus valores por defecto y la precedencia están en
[references/config.md](references/config.md). Léelo antes del Paso 1.

## Argumentos

- Sin argumento: se pregunta el repositorio, el alcance y el modo.
- `#123` o `123`: la issue 123 del repositorio del directorio actual, si es un
  repo de GitHub; si no lo es, se pregunta el repositorio y la issue es la 123
  de ese. No se preguntan el alcance ni el modo.
- `owner/repo#123` (o la URL de la issue): esa issue de ese repositorio. No se
  preguntan el repositorio, el alcance ni el modo.

## Paso 0: chequeo de requisitos generales

Antes de preguntar nada, verifica lo que no depende del repositorio y muestra
una tabla con el resultado de cada punto (✅ / ⚠️ / ❌ y una línea de detalle):

| Requisito | Cómo se verifica | Si falla |
|---|---|---|
| `gh` autenticado | `gh auth status` muestra al menos una cuenta logueada en github.com | ❌ detente y sugiere `gh auth login` |
| Cuentas de GitHub | las cuentas de `gh auth status` y las de `githubAccounts` en las preferencias | si `githubAccounts` nombra una cuenta que no está logueada, ⚠️ y sigue con las demás |
| Preferencias personales | `~/.config/drawl99/github-goal.json` o `~/.claude/github-goal.json` existe y sus valores son válidos | ⚠️ se usan los valores por defecto (informa cuáles) |
| SDD de gentle-ai | `gentle-ai --version` responde y las skills y agentes `sdd-*` están disponibles | ⚠️ solo flujo directo; sugiere instalar gentle-ai |
| Engram | las herramientas `mem_*` están disponibles | ⚠️ las decisiones quedan solo en GitHub (issue y PR) |
| Preguntas y sub-agentes del host | existen la herramienta de preguntas y la de sub-agentes del host ([references/hosts.md](references/hosts.md)) | ⚠️ sin preguntas nativas, pregunta en texto y se detiene; sin sub-agentes, la ruta directa corre en la sesión principal y la llena más rápido |

Con algún ❌ no sigas. Con solo ⚠️, sigue y tenlos en cuenta.

**Cuenta de GitHub.** Cada repositorio se trabaja con la cuenta que lo ve (se
resuelve en el Paso 1). Si esa cuenta no es la activa, **todas** las llamadas a
`gh` de la corrida van con `GH_TOKEN=$(gh auth token -u <cuenta>)`, y los `git
push` y `git pull` usan a `gh` como credencial
(`git -c credential.helper= -c "credential.helper=!gh auth git-credential" ...`,
que respeta `GH_TOKEN`). Nunca cambies la cuenta activa (`gh auth switch`): es
global y rompe los otros repos de la persona.

## Paso 1: repo, alcance y rama base

### 1.1 Repositorio

Si el argumento ya fija el repositorio (ver *Argumentos*), úsalo y salta al 1.2.
Si no, **pregunta siempre**: nunca asumas un repositorio, tampoco el del
directorio actual.

1. **Candidatos**, con `gh`:
   - los repos propios: `gh repo list --limit 100 --json nameWithOwner,hasIssuesEnabled,pushedAt,isArchived`;
   - los de cada organización a la que pertenece la persona:
     `gh api user/orgs --paginate -q '.[].login'` y, por cada una,
     `gh repo list <org> --limit 100 --json nameWithOwner,hasIssuesEnabled,pushedAt,isArchived`.

   Descarta los archivados y los que tienen las issues deshabilitadas.
2. **Varias cuentas:** si `githubAccounts` declara cuentas o `gh auth status`
   muestra más de una, lista con cada cuenta relevante
   (`GH_TOKEN=$(gh auth token -u <cuenta>)`) y recuerda qué cuenta ve cada
   repo. Si varias ven el mismo, gana la de `githubAccounts` (la clave más
   específica); si no hay, la activa. Todas las llamadas posteriores sobre el
   repo elegido usan esa cuenta.
3. **Barato:** no cuentes issues de cien repos uno por uno. Ordena por
   `pushedAt` (más reciente primero) y comprueba solo los que vas a mostrar,
   hasta llenar las opciones: si tiene al menos una issue abierta
   (`gh issue list -R <owner/repo> --state open --limit 1 --json number`) y,
   para la etiqueta, `gh api repos/<owner>/<repo> -q .open_issues_count`
   (incluye PRs: muéstralo como "aprox.").
4. **Pregunta en una sola pregunta** (`AskUserQuestion`):
   - primera opción, el repo del directorio actual si es un repo de GitHub
     (`git remote get-url origin`), marcado "(este directorio)";
   - después, los pusheados más recientemente que tienen issues abiertas, con
     la etiqueta `owner/repo`, marcados como personal u organización
     (`owner/repo · personal`, `owner/repo · org <org>`) y con las issues
     abiertas aprox.;
   - el resto, con "Other" escribiendo `owner/repo`. Verifica que exista, que
     lo vea alguna cuenta y que tenga issues habilitadas.

   No toques ninguna issue antes de la respuesta.

### 1.2 Checkout local

El trabajo necesita un clon local del repositorio elegido.

1. Si el directorio actual es ese repo (su `origin` apunta a `owner/repo`, por
   https o ssh), úsalo.
2. Si no, busca un clon existente en `workspaceDirs` de las preferencias (por
   defecto `["~/Desktop", "~/code", "~/projects", "~/dev"]`): directorios con
   `.git` hasta unos pocos niveles de profundidad cuyo
   `git -C <dir> remote get-url origin` apunte a `owner/repo`. Si encuentras
   uno, pregunta si usarlo (una pregunta; si hay varios, uno por opción).
3. Si no hay ninguno, ofrece clonarlo en `<primera entrada de workspaceDirs>/<repo>`
   o en una ruta que escriba el usuario, con la cuenta que ve el repo:
   `GH_TOKEN=$(gh auth token -u <cuenta>) gh repo clone <owner/repo> <ruta>`.
   Si la ruta ya existe y no es ese repo, pide otra.

Una vez elegido, **todos** los comandos de git, `gh` y pruebas de la corrida se
ejecutan en ese checkout: `git -C <ruta> ...`, `gh ... -R <owner/repo>` (o
`cd <ruta> && gh ...`), `cd <ruta> && <comando de verify>`, en cada comando.
Nunca asumas que el directorio de la sesión cambió. Los sub-agentes reciben la
ruta del checkout y la misma regla.

### 1.3 Requisitos del repositorio

Con el repo y el checkout elegidos, completa el chequeo con otra tabla, igual
que en el Paso 0:

| Requisito | Cómo se verifica | Si falla |
|---|---|---|
| `gh` ve el repositorio | con la cuenta resuelta en el 1.1: `gh repo view <owner/repo> --json nameWithOwner,defaultBranchRef,hasIssuesEnabled` | si falla, prueba las otras cuentas de `gh auth status`. Si una lo ve, úsala y sugiere guardarla en `githubAccounts` (⚠️). Si ninguna lo ve, ❌ detente y sugiere `gh auth login` |
| Issues habilitadas | `hasIssuesEnabled` es `true` | ❌ detente |
| Checkout | el `origin` del checkout apunta al repo elegido | ❌ detente |
| Árbol limpio | `git -C <ruta> status --porcelain` vacío | si hay cambios y la rama actual es la de una issue tuya reclamada (enlazada con `gh issue develop --list <n>` o con el nombre de `branchPattern`), es trabajo para retomar (⚠️, ver Paso 1b). Si no, ❌ detente: no mezcles trabajo ajeno con una issue |
| Config del repo | `.claude/github-goal.json` existe en el checkout y es JSON válido | ⚠️ se usan los valores por defecto y se pregunta lo que falte; si existe pero es inválido, ❌ detente y muestra el error |
| Label de lista | existe un label con el nombre exacto de `labels.ready` (`gh label list -R <owner/repo> --search <nombre> --json name`, comparando el nombre exacto) | ⚠️ el requisito del label de lista queda apagado para este repo: dilo y ofrece crearlo (`gh label create`), nunca sin permiso |
| Comandos de verificación | los de `verify` en la config, o los que declare `CLAUDE.md`/`AGENTS.md` | ⚠️ se preguntarán al tomar la primera issue |
| Herramientas de verificación | los ejecutables que usan esos comandos existen (`mvnw`, `pnpm`, `docker` si hay Testcontainers…) | ⚠️ avisa qué falta: esas pruebas no van a poder correr localmente |

Con algún ❌ no sigas. Si la config del repo no existe, ofrece crearla ahora con
lo que ya se sabe (ver [references/config.md](references/config.md)).

### 1.4 Alcance

Si el argumento fija la issue, el alcance es esa issue: no preguntes. Léela con
`gh issue view <n> -R <owner/repo> --json number,title,state,body,labels,assignees,milestone,comments,url`
y `gh api repos/<owner>/<repo>/issues/<n>` (trae `issue_dependencies_summary`
y `sub_issues_summary`).

Si no:

1. Lista los milestones abiertos:
   `gh api "repos/<owner>/<repo>/milestones?state=open&per_page=100"` (título,
   `due_on`, `open_issues`, número, descripción), en el orden de trabajo (ver
   *Orden de trabajo*). Averigua si hay issues abiertas sin milestone
   (`gh issue list -R <owner/repo> --state open --search "no:milestone" --limit 1 --json number`).
2. Pregunta **el alcance en una sola pregunta** (`AskUserQuestion`):
   - "Todas en orden": milestones en orden de trabajo y las issues sin
     milestone según `unmilestoned`;
   - cada milestone abierto, con título, fecha de entrega y cuántas issues
     abiertas tiene;
   - "Sin milestone", si hay issues abiertas sin milestone.

   Si no caben todas las opciones, los milestones que falten se eligen con
   "Other" escribiendo el título. **No asumas un alcance por defecto** y no
   toques ninguna issue antes de la respuesta.

### 1.5 Rama base

1. La rama base es `baseBranch` de la config del repo; si no está, la rama por
   defecto del repositorio (`defaultBranchRef` del 1.3).
2. Si la rama base no es la rama por defecto, recuérdalo al usuario: los PRs
   contra ella no cierran la issue solos (ver *Cierre de la issue*).
3. Toda rama nueva sale de la rama base actualizada. Primero
   `git -C <ruta> checkout <base> -q && git -C <ruta> pull --ff-only -q`, y
   después se crea con `gh issue develop` (ver *Flujo por issue*). Nunca desde
   donde quedaste parado. Todo PR va contra la rama base.

## Paso 1b: retomar trabajo pendiente

Antes de elegir issues nuevas, busca trabajo que quedó a medias en el
repositorio elegido: issues tuyas reclamadas y abiertas (con su rama, sus
cambios sin commitear o en un stash, su PR y sus checks), PRs ya mergeados en
una rama base que no es la por defecto cuya issue sigue abierta, y archivos SDD
pendientes. Si encuentras algo, ofrece retomarlo en una sola pregunta; en modo
automático, retomar va primero. Qué buscar, desde dónde sigue cada estado y lo
que nunca se hace al retomar: [references/resume.md](references/resume.md).

## Paso 2: modo

Hay dos modos:

- **Una issue:** resuelve una sola issue, elegida por el usuario, y termina.
- **Automático (goal):** toma una issue tras otra en orden de trabajo hasta
  agotar las disponibles del alcance o llegar a `maxIssues`.

Cómo se decide:

1. Si se invocó con una issue como argumento (`#123`, `123` u
   `owner/repo#123`), es **una issue**, y es esa: no se pregunta el modo.
2. Si no, usa `defaultMode` de las preferencias personales. Con `"ask"` (el
   valor por defecto), pregunta con `AskUserQuestion`: "Una issue" o
   "Automático".
3. En **una issue** sin argumento, calcula las issues disponibles del alcance
   con las reglas de *Orden de trabajo* y *Selección* y ofrécelas en una
   pregunta, en orden de trabajo: las primeras como opciones (`#número` y
   título; las que no tienen milestone, marcadas "sin milestone"), el resto con
   "Other" escribiendo el número. Con el alcance "Todas en orden", la lista
   incluye las issues sin milestone aunque `unmilestoned` sea `"skip"` (al
   final). Si no hay ninguna disponible, di por qué (bloqueadas, sin el label
   de lista, `needs-spec`, asignadas a otra persona, padres con sub-issues
   abiertas) y termina.
4. Una issue elegida o pasada por argumento tiene que cumplir las mismas reglas
   de *Selección*. Si no las cumple, di cuál falla y termina: elegirla a mano no
   saltea `needs-spec`, `blocking`, los bloqueantes abiertos, las sub-issues
   abiertas ni la asignación.

## Paso 3: base sana

Verifica que el último commit de la rama base tenga sus checks en verde
(`gh run list -R <owner/repo> --branch <base>`, o los checks del último PR
mergeado si los workflows no corren sobre esa rama). Hay tres resultados
posibles:

- **Verde:** sigue.
- **Rojo por causa ajena:** detente y avisa. No se arranca ninguna issue sobre
  una base rota.
- **Sin resultados** (no corrió ningún check sobre ese commit, ni en su PR):
  el estado de la base es **desconocido**, y eso no es verde. Dilo, con el PR o
  commit que quedó sin verificar. Puedes seguir, pero el primer PR de la
  corrida hace de verificación de la base: con `stopAt: "merge"`, no mergees
  nada hasta que ese PR tenga sus checks en verde, y si fallan por algo que no
  tocaste, trátalo como base roja.

## Orden de trabajo

- **Milestones:** los abiertos, por `due_on` ascendente; los que no tienen
  fecha van después, por número. Agota un milestone antes de pasar al
  siguiente.
- **Issues sin milestone:** son un grupo aparte, según `unmilestoned` de la
  config del repo: `"last"` (por defecto) al final, `"first"` antes del primer
  milestone, `"skip"` no entran en "Todas en orden" (se pueden elegir igual con
  el alcance "Sin milestone" o por argumento).
- Un milestone cuya descripción dice que todavía no tiene issues listas, o que
  no debe convertirse en issues, no se toca: si llegas ahí, terminaste.
- Lista las issues de cada grupo con
  `gh api --paginate "repos/<owner>/<repo>/issues?state=open&milestone=<número|none>&per_page=100"`
  y descarta los elementos que tienen `pull_request` (ese endpoint también
  devuelve PRs). Cada issue trae `issue_dependencies_summary` y
  `sub_issues_summary`.
- **Dentro del grupo manda el grafo de dependencias**, no el listado; a igual
  disponibilidad, la de número más bajo primero. Una issue está disponible solo
  si **todos** sus bloqueantes están cerrados. Si `total_blocked_by` es mayor
  que 0, lee los bloqueantes con
  `gh api repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by` (un arreglo
  de issues) y mira el `state` de cada una.
- **Dependencias escritas pero no enlazadas.** Si la descripción declara
  dependencias ("Depends on #12", "Blocked by #12", "Depende de #12",
  "Bloqueada por #12", con o sin dos puntos, también `owner/repo#12` o la URL
  de otra issue) que no están en `blocked_by`, trátalas como bloqueantes igual:
  si la referida está abierta, la issue no está disponible. Reporta cada
  dependencia faltante y ofrece enlazarla de forma nativa en una sola pregunta
  al final de la selección, nunca sin permiso:
  `gh api -X POST repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by -F issue_id=<id>`,
  donde `<id>` es el `id` numérico de la bloqueante (no su número):
  `gh api repos/<owner>/<repo>/issues/<bloqueante> -q .id` (en su propio repo
  si es de otro). Si el enlace falla, déjala como texto y dilo. Sin el enlace,
  *Desbloqueo* no la ve.
- **Sub-issues.** Una issue con sub-issues abiertas
  (`sub_issues_summary.total` mayor que `sub_issues_summary.completed`) es un
  padre: no la tomes mientras tenga sub-issues abiertas; toma las sub-issues
  (`gh api repos/<owner>/<repo>/issues/<n>/sub_issues`), que cumplen *Selección*
  por su cuenta. Cuando se cierran todas, el padre vuelve a ser candidato; si
  solo agrupaba a sus sub-issues y no le queda trabajo propio, dilo y ofrece
  cerrarlo, nunca sin permiso.

## Selección (una issue a la vez)

Los nombres de labels son los de `labels` en la config del repo (por defecto
`agent-ready`, `needs-spec`, `blocking`, `security`). Toma una issue solo si
cumple todo:

- Está en el alcance elegido y abierta.
- No es un padre con sub-issues abiertas.
- Todos sus bloqueantes (nativos y escritos) cerrados.
- Tiene el label `labels.ready`, si el repo tiene ese label (Paso 1.3). Si no
  lo tiene, este requisito está apagado para el repo.
- No está asignada a otra persona. Con `assignee: "me-or-unassigned"` (por
  defecto), asignada a ti (`@me`) o sin asignar; con `"me"`, solo asignada a
  ti. Asignada a otra persona, salvo la excepción de *Desbloqueo*, abajo.
- No tiene `labels.needsSpec` ni `labels.blocking`.
- Nadie la empezó: sin comentario de reclamo de otra persona, sin rama enlazada
  de otra persona (`gh issue develop --list <n> -R <owner/repo>`), sin PR
  abierto que la referencie (`gh pr list -R <owner/repo> --search "#<n>" --state open`).
  Si el reclamo, la rama o el PR son tuyos, es trabajo para retomar (Paso 1b).
  Compruébalo como mínimo para la issue que vas a tomar, justo antes del
  reclamo.

No las tomes, y avisa en su lugar:

- `blocking`: son congelamientos de contrato entre personas, trabajo humano. Si
  es lo único disponible, detente.
- `needs-spec`: falta información; no se delega.
- Sin el label de lista (si el repo lo tiene): no está lista para un agente.
- Asignadas a otra persona (o sin asignar, con `assignee: "me"`), salvo la
  excepción de *Desbloqueo*.

### Desbloqueo

Si no tienes ninguna issue propia disponible porque una ajena te frena y nadie
la empezó, puedes ofrecer tomarla: **siempre preguntando**, verificando justo
antes que siga sin empezar, reasignándola y avisando con una mención a quien la
tenía. Condiciones, orden y pasos exactos en
[references/unblock.md](references/unblock.md). Con `takeBlockingIssues: "never"`
no se ofrece.

**Si no queda ninguna disponible porque a tus issues les falta el label de
lista**, no termines solo con "no hay nada": di cuáles están cerca de estar
listas (criterios de aceptación concretos, sin preguntas de negocio abiertas,
sin bloqueantes) y qué le falta a cada una. Agregar el label es decisión del
usuario: puedes ofrecerlo, nunca hacerlo solo.

En modo **automático**: si `confirmEachIssue` es `true`, antes de reclamar cada
issue pregunta si tomarla o saltarla. Si no queda ninguna disponible en un
grupo (milestone o sin milestone), pasa al siguiente. Si no queda ninguna en
ningún grupo del alcance, o se alcanzó `maxIssues`, termina y reporta qué quedó
y por qué.

En modo **una issue**, la issue ya está elegida (Paso 2): `confirmEachIssue` y
`maxIssues` no aplican.

## Flujo por issue

1. **Reclamo.** Si la issue está sin asignar, asígnatela:
   `gh issue edit <n> -R <owner/repo> --add-assignee @me`. Comenta en la issue:
   "Tomando esta issue para trabajar en ella ahora"
   (`gh issue comment <n> -R <owner/repo> --body ...`). No agregues labels de
   estado (ver *Estados en GitHub*).
2. **Decisión de flujo.** Lee la issue completa y el código que toca, y
   recomienda SDD completo o flujo directo con la skill `workflow-decision` de
   este plugin ([../workflow-decision/SKILL.md](../workflow-decision/SKILL.md)). Con
   `defaultRoute: "ask"` (el valor por defecto) pregunta con `AskUserQuestion`,
   con la recomendada primero. Con `"direct"` o `"sdd"`, usa esa ruta salvo que
   la recomendación sea la otra con señales fuertes: en ese caso pregunta igual.
3. **Rama.** Desde la rama base actualizada (Paso 1.5), créala enlazada a la
   issue:
   `gh issue develop <n> -R <owner/repo> --base <base> --name <rama> --checkout`
   (en el checkout). El nombre sale de `branchPattern` (por defecto
   `{type}/{number}-{slug}`):
   - `{type}`: `fix`, `feat`, `chore` o `docs`. Manda un prefijo convencional
     en el título (`fix:`, `feat(api):`); si no hay, los labels (`bug` → `fix`,
     `enhancement` o `feature` → `feat`, `documentation` → `docs`); si tampoco,
     `fix` para un bug, `feat` para comportamiento nuevo y `chore` para el
     resto.
   - `{number}`: el número de la issue.
   - `{slug}`: el título en minúsculas, sin tildes ni caracteres fuera de ASCII,
     con guiones en lugar de espacios y símbolos, sin guiones repetidos ni en
     los extremos, cortado en un guion para que no pase de unos 50 caracteres.

   Si la issue ya tiene una rama enlazada tuya, es trabajo para retomar (Paso
   1b): no crees otra.
4. **Implementación**, según la ruta elegida. En las dos, la sesión principal
   orquesta y el trabajo pesado lo hacen sub-agentes, para no llenar el
   contexto: ver [references/execution.md](references/execution.md).
   - **SDD completo:** el SDD de **gentle-ai** (sus skills y agentes `sdd-*` y
     su dispatcher), de `sdd-new` a `verify`, automático salvo ambigüedad real
     de negocio. Su preflight de sesión se completa con `sdd` de la config del
     repo, sin preguntar en cada issue.
   - **Directo:** la sesión principal deja el plan en 3 a 6 líneas en un
     comentario de la issue; un sub-agente implementa con TDD y verifica, y
     devuelve un reporte corto.
   - En ambos casos sigue las convenciones del repositorio (`CLAUDE.md`,
     `AGENTS.md`): TDD, cobertura y estilo. Si Engram está disponible, guarda
     las decisiones y los descubrimientos a medida que aparecen.
5. **Verificación local.** Que el sub-agente corra todas las entradas de
   `verify` cuyos `paths` toque el cambio, y reporte solo el resultado. Si no
   hay config, usa lo que declare `CLAUDE.md`; si tampoco, pregunta una vez y
   ofrece guardarlo en la config del repo. Una prueba que no pudo correr por el
   entorno (por ejemplo, una imagen de contenedor que no arranca en esta
   máquina) no cuenta como pasada: dilo en el PR.
6. **Revisión de código.** Si existe `/code-review`, úsalo (corre aparte). Las
   correcciones las hace un sub-agente, no la sesión principal. Resuelve solo los
   hallazgos de esta issue; el resto va a una issue nueva (ver *Issues que salen
   de una issue*). Si aparece un prompt de consentimiento de revisión,
   preséntalo tal cual al usuario.
7. **PR.** Ábrelo **directamente contra la rama base**; no lo retargetees
   después: `gh pr create -R <owner/repo> --base <base> --head <rama>`. Uno solo
   por issue, en el idioma de `language.pullRequests`, con `Fixes #<n>` en la
   **descripción** (GitHub no lee las palabras clave de los comentarios). La
   descripción dice qué ruta se usó y por qué, y qué se verificó localmente y
   qué no. Si la rama base no es la rama por defecto, agrega que la issue se
   cierra a mano después del merge.
8. **CI y merge.** Espera los `requiredChecks` (o todos los checks, si no hay
   config). Si fallan por tu cambio, corrígelo; si fallan por causa ajena,
   detente y avisa.
   - **Que los checks existan.** Si a los pocos minutos de abrir el PR no
     arrancó ningún check, no es verde: averigua por qué antes de seguir. Lo
     más común es que el PR tenga conflictos (`gh pr view --json mergeable`
     da `CONFLICTING`), y GitHub no corre workflows de `pull_request` en ese
     caso. Rebasea sobre la rama base y pushea. Si hubo que cambiarle la base
     al PR, el cambio de base no dispara los workflows: pushea de nuevo (por
     ejemplo, tras rebasear) para que corran.
   - Nunca des por aprobado un PR sin checks, ni lo mergees así.
   - `stopAt: "pr"` (por defecto): con CI en verde, la issue termina acá. Si la
     rama base no es la rama por defecto, dilo en el reporte: la issue va a
     quedar abierta después del merge y hay que cerrarla (la próxima corrida lo
     ofrece, ver [references/resume.md](references/resume.md)). En modo
     automático, pasa a la siguiente solo si sus bloqueantes no dependen de
     este PR.
   - `stopAt: "merge"`: con CI en verde, mergea (`gh pr merge`, con el método
     que use el repo). Nunca mergees en rojo. Después, *Cierre de la issue*.
   - Una issue con `labels.security` nunca se mergea sin revisión humana, sea
     cual sea `stopAt`.
9. **Cierre.** Con flujo directo no hay nada que archivar. Con SDD, el cambio se
   archiva **después del merge**, nunca antes. Dónde va el commit (push directo o
   PR de archivo, según la protección de la rama base) y qué pasa con
   `stopAt: "pr"`: ver [references/archive.md](references/archive.md).
10. En modo **una issue**, termina y reporta. En modo **automático**, cierra la
    issue con un párrafo corto y vuelve a *Selección* sin arrastrar sus
    detalles (ver *Entre issues* en
    [references/execution.md](references/execution.md)).

## Cierre de la issue

Las palabras clave de cierre (`Fixes #<n>`) **solo cierran la issue cuando el PR
se mergea en la rama por defecto del repositorio**.

- **Base = rama por defecto:** `Fixes #<n>` la cierra al mergear. Después del
  merge, confirma que quedó cerrada (`gh issue view <n> --json state`); si
  sigue abierta, ciérrala como en el caso siguiente.
- **Base = otra rama** (una rama de integración): después del merge la cierras
  tú, y solo después de verificar que el PR está mergeado
  (`gh pr view <pr> -R <owner/repo> --json state,baseRefName` da `MERGED`):
  `gh issue close <n> -R <owner/repo> --comment "Resuelta en #<pr>, mergeado en <base>."`
- Con `stopAt: "pr"` el merge no ocurre en la corrida: repórtalo, y la próxima
  corrida detecta "PR mergeado en una base que no es la por defecto, issue
  abierta" y ofrece cerrarla (ver [references/resume.md](references/resume.md)).

## Issues que salen de una issue

Cualquier issue nueva que nazca del trabajo (hallazgos fuera de alcance, deuda
técnica, bugs descubiertos): busca antes de crear, créala con **todos** los
campos en el mismo `gh issue create` (asignado, milestone, labels, prioridad,
estimado, relación con la de origen) y sin afirmar hechos de código que no
leíste. Reglas y criterios completos en
[references/followups.md](references/followups.md).

## Estados en GitHub

Una issue en GitHub solo está abierta o cerrada: no hay In Progress ni In
Review. **Nunca inventes labels para estados.** Que una issue está en curso se
deduce del comentario de reclamo, de la rama enlazada y del PR abierto que la
referencia. Lo único que cambias en una issue es:

- asignártela al reclamarla, si estaba sin asignar;
- comentar;
- en *Desbloqueo*, y con permiso del usuario, reasignarla;
- cerrarla después de verificar el merge (ver *Cierre de la issue*), o cuando
  el usuario lo acepta al retomar;
- con permiso del usuario: enlazar dependencias nativas, agregar el label de
  lista, crear labels.

## Restricciones

- No menciones a Claude ni a la IA en commits, PRs, comentarios ni specs, salvo
  que las convenciones del repositorio digan otra cosa.
- Commits convencionales con el número de la issue, en el idioma de
  `language.commits`: `fix(web): short description (#123)`.
- Ante una ambigüedad de negocio, un CI roto por causa ajena o cualquier
  bloqueo real, detente y avisa.
