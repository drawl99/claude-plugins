# Dependencias y sub-issues

Detalle de *Orden de trabajo* en `SKILL.md`.

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
