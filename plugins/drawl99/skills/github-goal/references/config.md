# Configuración de github-goal

Hay dos archivos, los dos opcionales y en JSON. Lo que no esté declarado se
pregunta al usuario, o toma el valor por defecto indicado aquí.

## Por repositorio: `.claude/github-goal.json`

Vive en la raíz del repositorio y se versiona: lo comparte cualquiera que
trabaje en ese repo. Describe el repositorio, nunca a una persona.

```json
{
  "baseBranch": "main",
  "branchPattern": "{type}/{number}-{slug}",
  "unmilestoned": "last",
  "assignee": "me-or-unassigned",
  "labels": {
    "ready": "agent-ready",
    "needsSpec": "needs-spec",
    "blocking": "blocking",
    "security": "security"
  },
  "priorityLabels": { "urgent": "priority: urgent", "high": "priority: high", "medium": "priority: medium", "low": "priority: low" },
  "estimateLabels": { "1": "size: XS", "2": "size: S", "3": "size: M", "5": "size: L", "8": "size: XL" },
  "verify": [
    { "paths": ["services/*/**"], "run": "cd services/{service} && ./mvnw clean verify" },
    { "paths": ["apps/web/**"], "run": "cd apps/web && pnpm lint && pnpm typecheck && pnpm test" }
  ],
  "requiredChecks": ["ci"],
  "language": { "commits": "en", "pullRequests": "es" },
  "sdd": { "artifactStore": "hybrid", "deliveryStrategy": "single-pr", "reviewBudgetLines": 800 }
}
```

| Campo | Qué es | Si falta |
|---|---|---|
| `baseBranch` | Rama base de las ramas nuevas y de los PRs. Si no es la rama por defecto del repo, las issues se cierran a mano después del merge (ver *Cierre de la issue* en `SKILL.md`). | La rama por defecto del repositorio (`gh repo view --json defaultBranchRef`). |
| `branchPattern` | Nombre de las ramas nuevas. Variables: `{type}` (`fix`, `feat`, `chore` o `docs`), `{number}` (número de la issue) y `{slug}` (título en minúsculas, ASCII, con guiones, de hasta unos 50 caracteres). | `"{type}/{number}-{slug}"`. |
| `unmilestoned` | Dónde van las issues abiertas sin milestone en el alcance "Todas en orden": `"last"`, `"first"` o `"skip"` (no entran; se pueden elegir igual con el alcance "Sin milestone" o por argumento). | `"last"`. |
| `assignee` | Qué issues se pueden tomar según su asignación: `"me-or-unassigned"` (asignadas a ti o sin asignar; las sin asignar se te asignan al reclamarlas) o `"me"` (solo asignadas a ti). | `"me-or-unassigned"`. |
| `labels` | Nombres de los labels que cambian el comportamiento: `ready` (lista para un agente), `needsSpec` (falta información), `blocking` (trabajo humano) y `security` (revisión humana obligatoria). Se puede declarar solo una parte; el resto toma su valor por defecto. Si el repo no tiene un label con el nombre de `ready`, ese requisito queda apagado para el repo. | Los valores del ejemplo. |
| `priorityLabels` | Labels de prioridad para issues derivadas, por nivel (`urgent`, `high`, `medium`, `low`). | Se buscan labels `priority:*` o `priority/*` en el repo; si no hay, la prioridad va en una línea de la descripción. |
| `estimateLabels` | Labels de estimado para issues derivadas, por puntos (`1`, `2`, `3`, `5`, `8`, `13`). | Se buscan labels `size:*` o `size/*` en el repo; si no hay, el estimado va en una línea de la descripción. |
| `verify` | Qué correr localmente antes de abrir el PR, según los archivos tocados. `paths` son globs relativos a la raíz; `{service}` se reemplaza por el primer segmento que coincide con `*`. Se corren **todas** las entradas cuyos `paths` toquen el cambio. | Se toma de `CLAUDE.md`/`AGENTS.md`. Si tampoco está ahí, se pregunta una vez. |
| `requiredChecks` | Nombres de workflows o checks de GitHub que tienen que estar en verde en el PR antes de mergear. | Todos los checks que GitHub reporte en el PR. |
| `sdd` | Valores del preflight de sesión del SDD de gentle-ai, para que no pregunte en cada issue: `artifactStore` (`openspec`, `engram` o `hybrid`), `deliveryStrategy` (`ask-on-risk`, `single-pr` o `auto-chain`) y `reviewBudgetLines` (número). El ritmo siempre es `auto` dentro de `github-goal`. | Se pregunta una vez por corrida, la primera vez que una issue va por SDD. |
| `language` | Idioma de commits (`commits`) y de descripciones de PR (`pullRequests`), como código ISO (`es`, `en`). | Se imita el idioma de los últimos commits y PRs del repo. |

**Si el archivo no existe**, ofrece crearlo al terminar el chequeo del
repositorio (Paso 1.2), con lo que ya se sabe: la rama base, los labels que
existen en el repo y los comandos de `verify` que se pueden inferir del repo
(`mvnw`, scripts de `package.json`, `Makefile`, lo que diga `CLAUDE.md`).
Muéstralo antes de escribirlo. Una vez escrito, dile al usuario que lo commitee
para no tener que responder lo mismo la próxima vez.

## Por persona: `~/.config/drawl99/github-goal.json`

Vive en el home de cada persona y no se versiona. Se busca primero en
`~/.config/drawl99/github-goal.json` y, si no existe, en
`~/.claude/github-goal.json`. Si existen los dos, gana el primero y el chequeo
de requisitos lo avisa. Describe cómo quiere trabajar esa persona, en cualquier
repo.

```json
{
  "defaultMode": "ask",
  "stopAt": "pr",
  "maxIssues": null,
  "confirmEachIssue": false,
  "defaultRoute": "ask",
  "takeBlockingIssues": "ask",
  "githubAccounts": { "mi-org": "mi-cuenta-de-trabajo" },
  "workspaceDirs": ["~/Desktop", "~/code", "~/projects", "~/dev"]
}
```

| Campo | Valores | Por defecto | Efecto |
|---|---|---|---|
| `defaultMode` | `"ask"` \| `"single"` \| `"goal"` | `"ask"` | Con `"ask"`, pregunta al arrancar si resolver una issue elegida o ir en automático. Con `"single"` o `"goal"`, usa ese modo sin preguntar. Pasar una issue como argumento siempre es modo una issue. |
| `stopAt` | `"pr"` \| `"merge"` | `"pr"` | Con `"pr"`, el flujo termina cada issue al abrir el PR con CI en verde, y sigue con la siguiente solo si sus bloqueantes no dependen de ese PR. Con `"merge"`, mergea cuando el CI está verde (nunca una issue `security`) y cierra la issue si la base no es la rama por defecto. |
| `maxIssues` | número o `null` | `null` | Solo en modo automático: cuántas issues trabajar en una corrida. `null` significa hasta agotar las disponibles. |
| `confirmEachIssue` | `true` \| `false` | `false` | Solo en modo automático: con `true`, antes de reclamar cada issue pregunta si tomarla o saltarla. |
| `defaultRoute` | `"ask"` \| `"direct"` \| `"sdd"` | `"ask"` | Con `"ask"`, muestra la recomendación y pregunta. Con `"direct"` o `"sdd"`, usa esa ruta sin preguntar, salvo que la recomendación sea la otra con señales fuertes: en ese caso pregunta igual. Si SDD no está instalado, `"sdd"` se trata como `"ask"`. |
| `takeBlockingIssues` | `"ask"` \| `"never"` | `"ask"` | Cuando estás bloqueado por una issue asignada a otra persona que nadie empezó, con `"ask"` te ofrece tomarla (siempre preguntando, nunca sola). Con `"never"`, solo reporta el bloqueo. Ver *Desbloqueo* en `SKILL.md`. |
| `githubAccounts` | objeto `{ "<owner>" o "<owner>/<repo>": "<cuenta de gh>" }` | vacío | Para quien tiene varias cuentas de GitHub en `gh`: qué cuenta usar en cada organización o repo. La clave más específica gana (`owner/repo` antes que `owner`). Se usa para listar repos al elegir y para todas las llamadas sobre el repo elegido, con `GH_TOKEN=$(gh auth token -u <cuenta>)`; la cuenta activa global no se toca. La cuenta tiene que estar logueada (`gh auth status`). |
| `workspaceDirs` | lista de directorios | `["~/Desktop", "~/code", "~/projects", "~/dev"]` | Dónde buscar un clon local del repo elegido (comparando `git remote get-url origin`). Si no hay ninguno, se ofrece clonarlo en la primera entrada o en una ruta que escriba el usuario. |

Un valor inválido no se adivina: se informa en el chequeo de requisitos y se
usa el valor por defecto.

## Precedencia

Para cada dato: lo que diga el usuario en la conversación, después el archivo
por persona (solo preferencias), después el archivo del repo (solo datos del
repo), después `CLAUDE.md`/`AGENTS.md`, después preguntar o el valor por
defecto.
