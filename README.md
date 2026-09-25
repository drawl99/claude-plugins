# claude-plugins

Plugins personales de Claude Code de drawl99. El principal, `github-goal`, es
la versión GitHub Issues del flujo linear-goal, para proyectos personales: la
fuente de verdad son las issues de GitHub, a través de `gh`, sin Linear ni
ningún MCP.

## Instalar

Funciona en **Claude Code**, **OpenCode** y **Pi**. Las skills son las mismas; cambia cómo se instalan y cómo se invocan.

| Host | Instalar | Invocar |
|---|---|---|
| Claude Code | `/plugin marketplace add drawl99/claude-plugins` y `/plugin install drawl99@drawl99` | `/drawl99:github-goal`, `/drawl99:workflow-decision` |
| OpenCode | `gh repo clone drawl99/claude-plugins /tmp/drawl99 && /tmp/drawl99/scripts/install-opencode.sh` (clona en `~/.local/share/drawl99/claude-plugins` y enlaza skills y comandos en `~/.config/opencode/`) | `/github-goal`, `/workflow-decision` |
| Pi | `pi install git:git@github.com:drawl99/claude-plugins` (SSH; ver nota) | `/skill:github-goal`, `/skill:workflow-decision` |

Reinicia el host después de instalar.

**Credenciales:** en Pi, instala por SSH (como en la tabla): por HTTPS, Pi
clona con tu credencial por defecto y, si el repo es privado y esa cuenta no lo
ve, falla con "Repository not found". Si usas un alias de SSH para otra cuenta,
ponlo en lugar de `github.com`, por ejemplo
`git:git@github-personal:drawl99/claude-plugins`. En OpenCode, el script clona
con `gh`: tu cuenta activa de `gh` tiene que ver el repo (o exporta
`GH_TOKEN=$(gh auth token -u <cuenta>)` antes de correrlo).

**Actualizar:**

- Claude Code: `/plugin marketplace update drawl99` y `/plugin update drawl99@drawl99`.
- OpenCode: vuelve a correr `~/.local/share/drawl99/claude-plugins/scripts/install-opencode.sh` (hace `git pull`).
- Pi: `pi update git:git@github.com:drawl99/claude-plugins` (con la misma fuente con la que lo instalaste; `pi update` a secas actualiza Pi, no este paquete).

**Qué necesita cada host** para `github-goal`: `gh` autenticado, gentle-ai
3.7.0 o más, una herramienta de preguntas y una de sub-agentes (en Pi, las del
paquete `gentle-pi`, que desde gentle-ai 3.6.1 trae su propio
`ask_user_question`; `gentle-ai sync` quita `@juicesharp/rpiv-ask-user-question`). El detalle, en
[`hosts.md`](plugins/drawl99/skills/github-goal/references/hosts.md).

## Qué incluye

### `/drawl99:github-goal`

Trabaja issues de GitHub de un repositorio en dos modos:

- **Una issue:** eliges una de la lista de disponibles, o la pasas directo:
  `/drawl99:github-goal #123` (repo del directorio actual) o
  `/drawl99:github-goal owner/repo#123`. La resuelve y termina.
- **Automático (goal):** toma una tras otra en orden de milestones (por fecha
  de entrega) y de dependencias, hasta agotarlas.
  Puede limitarse a un milestone:
  `/drawl99:github-goal automático milestone "v1.0"`.

- **Pregunta en qué repositorio trabajar**, entre los tuyos y los de las
  organizaciones a las que perteneces (con cada cuenta de `gh` si tienes
  varias); el del directorio actual aparece primero, pero nunca lo asume. Si no
  estás parado en ese repo, busca un clon local en `workspaceDirs` o te ofrece
  clonarlo, y corre todo ahí.
- Después pregunta el **alcance**: un milestone, "Todas en orden" o "Sin
  milestone", y el modo. La rama base es `baseBranch` o la rama por defecto.
- **Dependencias nativas de GitHub** (`blocked_by`): una issue está disponible
  solo si todas sus bloqueantes están cerradas. Trata como bloqueantes también
  las escritas en la descripción ("Depende de #12", "Blocked by #12") y ofrece
  enlazarlas. Con **sub-issues**, toma las sub-issues antes que el padre.
- **Retoma lo interrumpido:** si una sesión se cortó a mitad de una issue, la
  siguiente encuentra la rama, los cambios sin commitear o en un stash, el PR y
  sus checks, y ofrece seguir desde ahí. Nunca borra ramas ni stashes.
- Por cada issue, después de reclamarla y crear la rama, **se la entrega a
  gentle-ai**, que decide la ruta con su protocolo por defecto (ODD: directo,
  chico o sustancial con `odd/tasks/<feature>.md`) y la implementa con commits
  de unidad de trabajo. Si gentle-ai propone **SDD**, se acepta sola y corre la
  cadena `/gentle-sdd-*`. La skill deja en la issue y en el PR qué ruta tomó
  gentle-ai y por qué, y nunca la vuelve a decidir.
- **Revisión:** con la revisión nativa de gentle-ai (RDD) encendida, revisa
  RDD; si está apagada, `/code-review`. En automático, con
  `"reviewConsent": "granted"` en tus preferencias, acepta sola el
  consentimiento de revisión y lo deja registrado; si no, te lo pregunta.
- **Automático sin paradas:** antes de la primera issue hace una vez el
  preflight de SDD de gentle-ai, con las respuestas recomendadas por la config.
  Con `"sizeException": "accept"`, un PR que supera el presupuesto de revisión
  sigue como uno solo, con el label `size:exception` y el porqué.
- Solo toma issues abiertas, asignadas a ti o sin asignar (las sin asignar se
  te asignan al tomarlas), con `agent-ready` si el repo tiene ese label, y sin
  `needs-spec` ni `blocking`. Los nombres de los labels se configuran.
- Crea la rama con `gh issue develop`, así queda enlazada a la issue.
- **Desbloqueo:** en repos con colaboradores, si te quedaste sin issues propias
  porque una de otra persona te frena y nadie la empezó, te ofrece tomarla.
  Siempre pregunta, vuelve a verificar que siga sin empezar, te la reasigna y
  le avisa a la otra persona con un comentario que la menciona. Se desactiva
  con `"takeBlockingIssues": "never"`.
- Las issues que salen del trabajo se crean completas: asignadas a ti, con el
  milestone de la de origen, labels y una línea "Relacionada con #<origen>".
  Prioridad y estimado van como labels si el repo los tiene, o en el cuerpo.
  Antes de crearlas busca si ya existe una igual.
- No mergea nada con label `security` sin revisión humana.
- Con SDD, archiva el cambio después del merge: push directo si la rama base no
  está protegida, o un PR chico de archivo si lo está.
- No da por bueno un PR sin checks: si el CI no arrancó (por ejemplo, por
  conflictos), lo detecta y lo resuelve antes de seguir.
- Nunca inventa labels de estado: GitHub solo tiene abierta y cerrada, y "en
  curso" se deduce del comentario de reclamo, la rama enlazada y el PR.

**Cómo cierra las issues:** GitHub solo cierra una issue con `Fixes #123`
cuando el PR se mergea en la **rama por defecto** del repo. Si la rama base es
otra (una rama de integración), el PR lleva `Fixes #123` igual, pero la issue
queda abierta después del merge: con `stopAt: "merge"`, la skill verifica que
el PR se mergeó y la cierra con
`gh issue close 123 --comment "Resuelta en #<PR>, mergeado en <base>."`; con
`stopAt: "pr"` (por defecto) te lo avisa, y la próxima corrida detecta el PR
mergeado con la issue abierta y ofrece cerrarla.

**Cómo trabaja:** la sesión principal orquesta GitHub (issues, ramas, PRs, CI,
merge, preguntas) y **gentle-ai** decide la ruta, implementa y, con RDD
encendido, revisa, delegando en sus propios sub-agentes. Así una corrida
automática encadena issues sin llenar el contexto.

**Requisitos:** `gh` autenticado con una cuenta que vea el repositorio, y
gentle-ai 3.7.0 o más. Si tienes varias cuentas en `gh`, indica cuál usar por
organización con `githubAccounts` en tus preferencias; el comando nunca cambia
tu cuenta activa. Engram es opcional.

Antes de empezar verifica los requisitos (`gh`, cuentas, gentle-ai y el modo
de RDD, herramientas del host, Engram) y, con el repo elegido, los del repo (issues habilitadas, árbol
limpio, config, label de lista, herramientas de prueba), y muestra qué falta.

#### Configuración

Dos archivos opcionales en JSON. El formato completo está en
[`config.md`](plugins/drawl99/skills/github-goal/references/config.md).

- **Por repositorio**, `.claude/github-goal.json` (se versiona): rama base
  (`baseBranch`), patrón de nombre de rama (`branchPattern`, por defecto
  `{type}/{number}-{slug}`), dónde van las issues sin milestone
  (`unmilestoned`: `last`, `first` o `skip`), qué issues se toman según su
  asignación (`assignee`: `me-or-unassigned` o `me`), nombres de los labels
  (`labels`), labels de prioridad y estimado, qué correr para verificar según
  los archivos tocados, qué checks de CI son obligatorios, en qué idioma van
  commits y PRs, y el almacén de artefactos recomendado para el SDD. Si no existe, el comando ofrece crearlo
  la primera vez.
- **Por persona**, `~/.config/drawl99/github-goal.json` (o `~/.claude/github-goal.json`; no se versiona): el modo por
  defecto (`defaultMode`: `ask`, `single` o `goal`), hasta dónde llega (`stopAt`: `pr` o `merge`), cuántas issues por corrida (`maxIssues`),
  si confirma cada issue (`confirmEachIssue`), si ofrece tomar issues
  ajenas que te bloquean (`takeBlockingIssues`: `ask` o `never`), si acepta
  solo el consentimiento de revisión en automático (`reviewConsent`:
  `granted`), si acepta por adelantado `size:exception` en automático
  (`sizeException`: `accept`), qué cuenta de
  `gh` usar por organización (`githubAccounts`) y dónde buscar clones locales
  (`workspaceDirs`).

Por defecto se detiene al abrir el PR, no mergea. Para mergear solo:

```json
{ "stopAt": "merge" }
```

### `/drawl99:workflow-decision`

Skill asesora independiente: recomienda si una issue se trabaja con **SDD
completo** o **flujo directo**, con los motivos sacados de la issue, cuando se
la pides: "¿esta issue va con SDD?". No necesita GitHub. `github-goal` no la
usa desde 2.0.0: allí la ruta la decide gentle-ai.

## Sugerirlo en un repo

Para que Claude Code se lo ofrezca a quien abra un repo, versiona
`.claude/settings.json` con:

```json
{
  "extraKnownMarketplaces": {
    "drawl99": { "source": { "source": "github", "repo": "drawl99/claude-plugins" } }
  },
  "enabledPlugins": { "drawl99@drawl99": true }
}
```

Si el repo ignora `.claude/`, agrega la excepción `!.claude/settings.json` al
`.gitignore`.

## Agregar un plugin o una skill

- Una skill nueva va en `plugins/drawl99/skills/<nombre>/SKILL.md`.
- Sube `version` en `plugins/drawl99/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json` y `package.json` (tienen que coincidir).
- Valida antes de subir: `claude plugin validate .`
- Anota el cambio en [`CHANGELOG.md`](CHANGELOG.md).
- Corre los evals si tocaste criterios de decisión:
  `claude plugin eval plugins/drawl99 --runs 3 --trust-plugin`.
- Después del push, crea el tag de la versión:
  `claude plugin tag plugins/drawl99 --push`.
