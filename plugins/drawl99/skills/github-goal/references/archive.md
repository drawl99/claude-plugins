# Archivo de un cambio SDD

Aplica solo a issues trabajadas con SDD completo. El archivo se hace **después
del merge**, nunca antes: registra un cambio ya integrado.

- **Dónde va el commit de archivo:** en la rama base, con el mensaje
  `docs(sdd): archive <change> change (#<n>)`. Averigua si la rama base está
  protegida con `gh api repos/<owner>/<repo>/branches/<base> -q .protected`
  (`true`/`false`; funciona con nombres que llevan `/` y no requiere ser admin,
  a diferencia del endpoint `/protection`). El commit se hace en un worktree
  nuevo desde `origin/<base>`, nunca en el clon principal (ver *Worktree por
  issue* en [concurrency.md](concurrency.md)), y ese worktree se quita al
  terminar si está limpio.
  - **Sin protección:** commitea y pushea directo a la rama base
    (`git -C <worktree> push origin HEAD:<base>`).
  - **Protegida** (o si el push es rechazado): crea una rama `<rama>-archive`
    (la rama de la issue más `-archive`) desde la base actualizada, commitea ahí
    y abre un PR chico contra la base, con `Refs #<n>` en la descripción (no
    `Fixes`: la issue ya se cerró, o se cierra por *Cierre de la issue*). Ese PR
    sigue las mismas reglas de CI; con `stopAt: "merge"` se mergea en verde,
    con `"pr"` queda abierto.
- **Con `stopAt: "pr"`** en automático, el archivo se hace cuando la espera
  de merge confirma el merge. En modo una issue (o si la espera venció) el
  merge no ocurre en la corrida, así que el archivo queda pendiente: dilo en el reporte final, con el nombre del cambio.
  Lo recoge la próxima corrida (ver *Archivos pendientes*, abajo) o el comando
  de archivo de gentle-ai (`/gentle-sdd-archive` en Claude Code y Pi,
  `/sdd-archive` en OpenCode; ver [hosts.md](hosts.md)).

## Archivos pendientes

Si SDD está disponible, antes de elegir issues busca cambios SDD sin archivar
cuyo PR ya se mergeó: carpetas en `openspec/changes/` (fuera de `archive/`), o
los topics `sdd/<change>/*` sin `archive-report` en Engram, cuya issue esté
cerrada. Ofrece archivarlos primero, en una sola pregunta, siguiendo las reglas
de arriba. Si el PR está mergeado pero la issue sigue abierta porque la base no
es la rama por defecto, primero ofrece cerrarla (ver [resume.md](resume.md)).
No toques cambios cuyo PR no esté mergeado.
