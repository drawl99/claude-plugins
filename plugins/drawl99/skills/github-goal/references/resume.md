# Retomar trabajo pendiente

Una sesión puede cortarse a mitad de una issue: se cierra la terminal, se acaba
el contexto, se interrumpe un agente. Lo que quedó hecho vive en git y en
GitHub; este paso lo encuentra y sigue desde ahí en vez de empezar de cero.

GitHub no tiene estado In Progress: que una issue está en curso se deduce del
comentario de reclamo, de la rama enlazada y del PR que la referencia. Nunca
inventes labels de estado.

## Qué buscar

En el repositorio elegido (en el checkout del Paso 1.1), sin importar el
alcance, entre las issues abiertas asignadas al usuario actual
(`gh issue list -R <owner/repo> --assignee @me --state open --json number,title`;
tu login, con `gh api user -q .login`):

1. **Issues reclamadas y abiertas:** las que tienen al menos una de estas
   señales:
   - un comentario tuyo "Tomando esta issue para trabajar en ella ahora", con
     o sin marca de sesión (cómo leerlos: *Marca de reclamo* en
     [concurrency.md](concurrency.md));
   - una rama enlazada (`gh issue develop --list <n> -R <owner/repo>`);
   - un PR abierto que la referencia
     (`gh pr list -R <owner/repo> --search "#<n>" --state open`).
2. **Clasifícalas por su reclamo** (el último comentario de reclamo tuyo,
   por su marca):
   - **De esta sesión** (mismo id): sigue desde donde quedó.
   - **Activo de otra sesión**, tuya o de cualquiera: **no se retoma**.
     Lístala como "en curso en otra sesión" y saltéala.
   - **Vencido** (o liberado, o sin marca y viejo): **adoptable**. Al adoptarla,
     publica un comentario de reclamo nuevo con tu id de sesión que diga que
     adopta el reclamo vencido `<id viejo>`, verifícalo como en *Reclamar con
     verificación* ([concurrency.md](concurrency.md)) y sigue desde la tabla
     de abajo. Las issues sin entregar con reclamo vencido se adoptan antes de
     tomar cualquier issue nueva (WIP = 1).
3. Para cada una que no esté en curso en otra sesión, su evidencia en el repo,
   usando la rama enlazada (o, si no hay, el nombre que da `branchPattern`):
   - rama local (`git -C <ruta> branch --list <rama>`) y remota
     (`git -C <ruta> ls-remote --heads origin <rama>`);
   - su worktree, si tiene (`git -C <ruta> worktree list --porcelain`, buscando
     la rama), o el clon principal si la rama está activa ahí (trabajo de una
     versión anterior a 2.1.0);
   - cambios sin commitear en ese worktree;
   - stashes que la mencionen (`git -C <ruta> stash list`, buscando la rama o
     `#<n>`);
   - PR (`gh pr list -R <owner/repo> --head <rama> --state all --json number,state,mergeable,baseRefName`)
     y, si está abierto, sus checks;
   - si gentle-ai la trabajó como sustancial: su documento `odd/tasks/<feature>.md`
     en la rama y su espejo `odd/<feature>/tasks` en Engram (tareas hechas y
     pendientes);
   - si usó SDD: su carpeta en `openspec/changes/` o su `apply-progress` en Engram.
4. **PRs mergeados con la issue abierta:** tus PRs mergeados en una rama base
   que no es la rama por defecto
   (`gh pr list -R <owner/repo> --author @me --state merged --base <base> --json number,body,baseRefName`),
   cuya issue de `Fixes #<n>` sigue abierta. Las palabras clave no la cerraron
   porque la base no es la rama por defecto (ver *Cierre de la issue* en
   `SKILL.md`).
5. **Archivos SDD pendientes:** cambios cuyo PR ya se mergeó pero no se
   archivaron (ver [archive.md](archive.md), *Archivos pendientes*).

No busques en otros repos: el trabajo pendiente se busca en el repo elegido.

## Qué hacer según lo que encuentres

| Estado encontrado | Desde dónde sigue |
|---|---|
| Reclamada, sin rama ni PR | Reclamo viejo. Sigue desde *Rama y worktree* y entrégasela a gentle-ai como una issue nueva. |
| Rama sin worktree | Créale el worktree (`git -C <ruta> worktree add <worktree> <rama>`, o con `--track origin/<rama>` si solo existe en el remoto; ver *Worktree por issue* en [concurrency.md](concurrency.md)) y sigue según el estado de la rama. |
| Rama con un documento de ODD o un cambio SDD a medias | Entrégasela a gentle-ai para que retome la feature o el cambio desde la siguiente tarea pendiente (ODD reconcilia el documento con su espejo en Engram); no la vuelvas a empezar. |
| Rama con cambios sin commitear o en un stash | Trabaja en el worktree de la rama; recupera el stash ahí (`git -C <worktree> stash apply`, nunca `pop` ni `drop`) y trata los cambios como **no verificados**: sigue desde la *Verificación local*. |
| Rama con commits, sin PR | Sigue desde la *Verificación local*: no abras PR sobre trabajo que nadie verificó en esta sesión. |
| PR abierto, checks en rojo | Sigue desde *CI y merge*: corrige si es tu cambio. |
| PR abierto, sin checks | Aplica la regla de *Que los checks existan*. |
| PR abierto, checks en verde | Con `stopAt: "pr"`: en automático (o si es `security`), sigue desde *Esperando merge* ([concurrency.md](concurrency.md)); en modo una issue, repórtalo como esperando revisión. Con `"merge"`, mergea (nunca una `security`) y sigue con *Cierre de la issue*. |
| PR cerrado sin merge, issue abierta | No la retomes sola: muéstrala y pregunta si retomarla (nuevo PR desde la misma rama) o soltarla (quitar tu asignación, con permiso). En automático, no tomes una issue nueva hasta que se decida. |
| PR mergeado en la rama por defecto, issue abierta | `Fixes #<n>` debería haberla cerrado. Verifica el merge y ofrece cerrarla con el comentario de *Cierre de la issue*. |
| PR mergeado en otra rama base, issue abierta | Verifica que el PR está mergeado (`gh pr view <pr> --json state` da `MERGED`) y ofrece cerrarla: `gh issue close <n> -R <owner/repo> --comment "Resuelta en #<pr>, mergeado en <base>."`. Si usó SDD, después queda el archivo pendiente. |
| PR mergeado, issue cerrada | No hay nada que retomar. Si usó SDD, queda el archivo pendiente. Si su worktree sigue y está limpio, quítalo (`git -C <ruta> worktree remove <worktree>`, nunca `--force`). |

## Cómo preguntarlo

Si encuentras algo, antes de elegir issues nuevas muéstralo en una lista corta
(issue, estado encontrado, desde dónde seguiría; las que están en curso en otra
sesión, aparte y sin opción de retomar) y pregunta una sola vez con
`AskUserQuestion`: retomar (una opción por issue, la más avanzada primero),
cerrar las issues de PRs ya mergeados, o seguir sin retomar.

- En modo **automático**, retomar va antes que cualquier issue nueva, sin
  preguntar: adopta la más avanzada de las que tienen el reclamo vencido.
- Si se invocó con una issue como argumento y es una de las pendientes,
  retómala sin preguntar. Si es otra y tienes issues sin entregar con el
  reclamo vencido, dilo y pregunta: "Retomar #X (recomendado)" o "Tomar #Y
  igual". Si no, menciona las pendientes y sigue con la del argumento.

Al retomar, comenta en la issue qué estado encontraste y desde dónde sigues, para
que quede registro.

## Lo que nunca se hace al retomar

- Borrar ramas o stashes, ni hacer `push --force`.
- Dar por verificado trabajo que no se verificó en esta sesión.
- Seguir si la rama local y la remota divergieron: detente y pregunta.
- Retomar una issue asignada a otra persona.
- Adoptar un reclamo activo, de otra sesión tuya o ajena.
- Tocar el worktree de otra sesión con cambios sin commitear mientras su
  reclamo esté activo.
- Mover el clon principal (`checkout`, `switch`, `pull`, `stash`) para retomar:
  se trabaja en el worktree de la issue.
- Cerrar una issue sin haber verificado que su PR está mergeado, ni sin que el
  usuario lo acepte.
