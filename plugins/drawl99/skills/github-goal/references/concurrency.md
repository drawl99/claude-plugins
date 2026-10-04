# Concurrencia: varias sesiones sobre el mismo repo

Varias sesiones pueden correr `github-goal` a la vez sobre el mismo
repositorio: de la misma persona (dos terminales) o de colaboradores
distintos. Estas reglas evitan que dos sesiones tomen la misma issue, que una
mueva la rama de otra en el clon compartido, y que una sesión acumule issues a
medio entregar.

## Identidad de la sesión

Al arrancar la corrida, genera un id de sesión de 8 caracteres hexadecimales
aleatorios (`openssl rand -hex 4`). Nunca uses nombres de máquina, rutas ni
usuarios (salvo el login de GitHub, que ya es público en el comentario).
Muéstralo en el plan (Paso 2) para que sobreviva a una compactación del
contexto; si Engram está disponible, guárdalo también en la nota de la sesión.

## Marca de reclamo

El comentario de reclamo lleva una marca oculta (un comentario HTML, no un
label):

```
Tomando esta issue para trabajar en ella ahora.
<!-- github-goal:claim session=<id> heartbeat=<ISO8601 UTC> -->
```

- **Publicarlo y guardar su id:**
  `gh api repos/<owner>/<repo>/issues/<n>/comments -f body="<cuerpo>" -q .id`.
  La hora, con `date -u +%Y-%m-%dT%H:%M:%SZ`.
- **Leer los reclamos:**
  `gh api "repos/<owner>/<repo>/issues/<n>/comments?per_page=100" --paginate --jq '.[] | {id, user: .user.login, created_at, body}'`,
  y en cada cuerpo busca `github-goal:claim` y `github-goal:release`.
- **Latido (heartbeat):** la sesión actualiza `heartbeat=` de **su propio**
  comentario en cada cambio de fase del *Flujo por issue* (rama, entrega a
  gentle-ai, vuelta de gentle-ai, PR, CI) y, mientras espera el merge, al menos
  cada `claims.ttlMinutes/4`:
  `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<comment_id> -f body="<cuerpo con el heartbeat nuevo>"`.
  Conserva el resto del cuerpo tal cual.
- **Activo o vencido:** un reclamo está **activo** si su `heartbeat` tiene
  menos de `claims.ttlMinutes` (config del repo, por defecto 120) y no fue
  liberado; si no, está **vencido**. Un comentario de reclamo sin marca
  (anterior a 2.1.0) cuenta como activo si se creó hace menos de
  `claims.ttlMinutes`, y como vencido si no. Si una fase puede durar más que el
  ttl (por ejemplo, un SDD largo), refresca el latido antes de entregarle la
  issue a gentle-ai y al recibirla de vuelta.
- **Liberar:** edita tu propio comentario y agrega al final una línea visible
  `Liberada: <motivo>.` y la marca
  `<!-- github-goal:release session=<id> -->`. Un reclamo liberado cuenta
  como vencido. Se libera al perder una carrera, al entregar la issue (motivo:
  `entregada en #<pr>`) y al terminar la corrida con la issue sin entregar
  (espera de merge vencida, fin en modo una issue con el PR abierto, PR cerrado
  sin merge, bloqueo): así otra sesión tuya la puede adoptar.
- **Nunca borres comentarios**, ni edites los de otra sesión o persona.

## Reclamar con verificación

El reclamo es un bloqueo optimista: se reclama y después se verifica quién
ganó. Reemplaza el paso *Reclamo* del *Flujo por issue*:

1. **Chequeo previo:** el de *Selección* (asignados, rama enlazada, PR abierto,
   comentarios de reclamo), y además que no haya un reclamo **activo** de otra
   sesión, incluidas las otras sesiones de tu propio login.
2. **Reclamo:** si la issue está sin asignar, asígnatela
   (`gh issue edit <n> -R <owner/repo> --add-assignee @me`) y recuerda que la
   asignación la pusiste tú. Publica el comentario de reclamo y guarda su id.
3. **Verificación:** vuelve a leer asignados y comentarios. **Perdiste** si hay
   otro reclamo activo con `created_at` anterior al tuyo (a igual hora, el de id
   de comentario menor), o si mientras tanto quedó asignada otra persona. Al
   perder: libera tu reclamo (motivo: `la tomó otra sesión`), quita tu
   asignación solo si la pusiste tú y quien ganó es otra persona, y vuelve a
   *Selección* con la siguiente issue (en modo una issue: repórtalo y termina).
   Nunca reintentes la misma issue.
4. **Rama libre:** antes de crear la rama,
   `git -C <ruta> ls-remote --heads origin <rama>`. Si ya existe (o
   `gh issue develop` falla porque existe), no es tuya de este reclamo:
   también perdiste.

Adoptar un reclamo vencido (ver [resume.md](resume.md)) sigue el paso 3: si
mientras tanto el dueño refrescó su latido u otra sesión adoptó antes,
perdiste. El paso 4 no aplica al adoptar: la rama que ya existe es el trabajo
que vienes a retomar. Úsala si es la rama enlazada de la issue y el reclamo
vencido es de tu login; si no, no la adoptes y avisa.

## Worktree por issue

**El clon principal (`<ruta>`) nunca se mueve:** solo se usa para `fetch` y
comandos de `worktree`. Nunca corras en él `checkout`, `switch`, `pull` ni
`stash`, y menos si tiene cambios sin commitear o una rama ajena activa. Cada
issue se trabaja en su propio worktree:

```
git -C <ruta> fetch origin <base> -q
gh issue develop <n> -R <owner/repo> --base <base> --name <rama>
git -C <ruta> fetch origin <rama> -q
git -C <ruta> worktree add <worktree> -b <rama> --track origin/<rama>
```

- `gh issue develop` sin `--checkout` crea la rama remota desde la base y la
  enlaza a la issue.
- `<worktree>` es `<padre de ruta>/<nombre del repo>-worktrees/<número>-<slug>`.
- Si la rama local ya existe (al retomar), `git -C <ruta> worktree add <worktree> <rama>`.
- Antes de crear uno, busca si la rama ya tiene worktree:
  `git -C <ruta> worktree list --porcelain`. Si lo tiene, ese es el de la
  issue: no crees otro. Si la rama está activa en el propio clon principal
  (trabajo de una versión anterior a 2.1.0), ese es su worktree.
- **Todo** lo que sigue (gentle-ai, `verify`, commits, push, RDD) corre en el
  worktree: `git -C <worktree> ...`, `cd <worktree> && ...`, y gentle-ai y sus
  sub-agentes reciben la ruta del worktree. Las llamadas a `gh` siguen con
  `-R <owner/repo>`.
- **Al confirmar el merge:** `git -C <ruta> worktree remove <worktree>` solo si
  está limpio (nunca `--force`); si no lo está, déjalo y dilo en el reporte. La
  rama nunca se borra.

## Una issue en curso por sesión (WIP = 1)

Una sesión tiene como máximo **una** issue reclamada sin entregar. Entregada
significa PR mergeado y la issue cerrada (ver *Cierre de la issue* en
`SKILL.md`). Las issues con reclamo activo de otras sesiones tuyas no cuentan
para el WIP de esta.

- **Huérfanas primero:** si tienes issues propias sin entregar cuyo reclamo
  está vencido (de una sesión que murió), adopta una antes de tomar cualquier
  issue nueva. En automático, sola, la más avanzada primero. En modo una issue
  con otra issue como argumento, dilo y pregunta: "Retomar #X (recomendado)" o
  "Tomar #Y igual".
- **Espera de merge:** en automático con `stopAt: "pr"`, y en toda issue con
  `labels.security` (el merge siempre es humano), con el CI en verde la issue
  pasa a *Esperando merge*. Con `stopAt: "merge"` (salvo `security`) se mergea
  como siempre. En modo una issue con `stopAt: "pr"`, la issue termina con el
  PR en verde, sin esperar.

### Esperando merge

Cada `mergeWait.pollMinutes` (preferencia personal, por defecto 5) consulta
`gh pr view <pr> -R <owner/repo> --json state,mergedAt,reviewDecision,mergeable`
y refresca el latido. Espera con lo que el host permita (en Claude Code, un
bucle en segundo plano o una herramienta de monitoreo), sin bloquear la sesión
más allá del timeout de un comando.

| Lo que pasa | Qué hacer |
|---|---|
| Piden cambios (`CHANGES_REQUESTED`) o hay comentarios de revisión nuevos en el PR | Entrégaselos a gentle-ai en la misma rama y worktree, verifica, pushea, responde en el PR qué cambió (en el idioma de `language.pullRequests`) y sigue esperando. Una pregunta de negocio: detente y avisa. |
| El CI se pone en rojo | Como en *CI y merge*: si es por tu cambio, corrección con gentle-ai; si es ajeno, detente y avisa. |
| Conflictos (`mergeable` da `CONFLICTING`) | `git -C <worktree> fetch origin <base>` y rebasea sobre `origin/<base>`; pushea con `--force-with-lease` solo si todos los commits de la rama son tuyos y el repo permite reescribirla. Si no, mergea la base en la rama y pushea normal. Nunca reescribas commits ajenos. Después, sigue esperando. |
| PR cerrado sin merge | Libera el reclamo, detén la corrida y repórtalo. No tomes otra issue. |
| Se cumple `mergeWait.timeoutMinutes` (por defecto 480; `null` = sin límite) | Libera el reclamo (motivo: `esperando merge de #<pr>`) y termina la corrida reportando "esperando merge". La próxima corrida retoma esta issue primero y no toma otra hasta que se mergee. |
| Mergeado | *Cierre de la issue*, archivo SDD si corresponde, libera el reclamo (`entregada en #<pr>`), quita el worktree y vuelve a *Selección*. |

## Lo que nunca se hace

- Tomar o adoptar una issue con reclamo activo de otra sesión, tuya o ajena.
- Tocar el worktree de otra sesión mientras su reclamo esté activo, y menos si
  tiene cambios sin commitear.
- Mover el clon principal (`checkout`, `switch`, `pull`, `stash`).
- Borrar comentarios, ramas o worktrees con cambios; `worktree remove --force`;
  `push --force` sin `--with-lease`.
- Reintentar una issue después de perder la carrera por ella.
