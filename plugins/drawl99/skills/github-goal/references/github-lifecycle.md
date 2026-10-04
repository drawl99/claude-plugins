# Ciclo de vida en GitHub: CI, cierre y estados

## Que los checks existan

Si a los pocos minutos de abrir el PR no
arrancó ningún check, no es verde: averigua por qué antes de seguir. Lo
más común es que el PR tenga conflictos (`gh pr view --json mergeable`
da `CONFLICTING`), y GitHub no corre workflows de `pull_request` en ese
caso. Rebasea sobre la rama base y pushea. Si hubo que cambiarle la base
al PR, el cambio de base no dispara los workflows: pushea de nuevo (por
ejemplo, tras rebasear) para que corran.
   - Nunca des por aprobado un PR sin checks, ni lo mergees así.

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
- Con `stopAt: "pr"` la skill nunca mergea. En automático espera el merge
  humano (ver *Esperando merge* en [concurrency.md](concurrency.md)) y, cuando
  ocurre, cierra la issue como arriba. En modo una issue el merge no ocurre en
  la corrida: repórtalo, y la próxima corrida detecta "PR mergeado en una base
  que no es la por defecto, issue abierta" y ofrece cerrarla (ver
  [resume.md](resume.md)). Lo mismo si la espera de merge venció.


## Estados en GitHub

Una issue en GitHub solo está abierta o cerrada: no hay In Progress ni In
Review. **Nunca inventes labels para estados.** Que una issue está en curso se
deduce del comentario de reclamo (y de su marca de sesión, un comentario HTML
oculto, no un label), de la rama enlazada y del PR abierto que la referencia.
Lo único que cambias en una issue es:

- asignártela al reclamarla, si estaba sin asignar (y quitártela si perdiste
  la carrera, ver [concurrency.md](concurrency.md));
- comentar, y editar **tu propio** comentario de reclamo para refrescar su
  latido o liberarlo (nunca borrarlo, ni editar comentarios ajenos);
- en *Desbloqueo*, y con permiso del usuario, reasignarla;
- cerrarla después de verificar el merge (ver *Cierre de la issue*, arriba), o cuando
  el usuario lo acepta al retomar;
- con permiso del usuario: enlazar dependencias nativas, agregar el label de
  lista, crear labels.
