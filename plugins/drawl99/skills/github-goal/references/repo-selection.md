# Elegir el repositorio y su checkout

Detalle del Paso 1.1 de `SKILL.md`.

## Repositorio

Si el argumento ya fija el repositorio (ver *Argumentos*), úsalo y salta al checkout.
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

## Checkout local

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

