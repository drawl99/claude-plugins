# Issues que salen de una issue

Cualquier issue nueva que nazca del trabajo de otra (hallazgos fuera de
alcance, deuda técnica, bugs descubiertos, seguimientos que el diseño deja
afuera):

1. **Busca antes de crear.**
   `gh issue list -R <owner/repo> --state open --search "<términos clave>"`,
   más las issues relacionadas con la de origen. Si ya existe una que cubre lo
   mismo, comenta lo nuevo en ella en vez de crear otra.
2. **Créala con todos estos campos en el mismo `gh issue create`**, nunca para
   completarlos después:
   - `--assignee @me` (quien la crea).
   - `--milestone "<título>"`: el milestone de la issue de origen. Si la de
     origen no tiene milestone, omítelo.
   - `--label` con los labels que correspondan y que **ya existan** en el repo
     (`gh label list -R <owner/repo> --limit 200 --json name`). Si el repo usa
     `tech-debt`, exige una issue padre o un ADR que la justifique. Nunca crees
     labels sin preguntar.
   - **Prioridad** (Urgent, High, Medium, Low): `security` o un bug de
     aislamiento o de corrección, al menos High; deuda técnica, Medium;
     limpieza menor, Low.
   - **Estimado** en puntos (1, 2, 3, 5, 8, 13): 1 cambio trivial; 2 fix chico;
     3 fix o feature con tests en un servicio; 5 varios servicios o con diseño;
     8 o más si es grande.
   - En el cuerpo, la línea "Relacionada con #<origen>".

   GitHub no tiene campos nativos de prioridad ni de estimado. Si la config del
   repo declara `priorityLabels` / `estimateLabels`, o el repo tiene labels
   `priority:*` / `priority/*` y `size:*` / `size/*`, aplica el que
   corresponda. Si no, escríbelos en una línea del cuerpo
   ("Prioridad: Alta · Estimado: 3 pts") y dilo en el reporte.
3. **No escribas hechos de código sin verificarlos.** Métodos, clases, órdenes de
   locks, líneas o comportamientos que la issue afirme tienen que estar leídos en
   el código, no deducidos. Si algo es una hipótesis, escríbelo como hipótesis.
4. **Label de lista:** si la issue ya cumple la definición de lista (criterios
   de aceptación concretos en forma de checklist, sin preguntas de negocio
   abiertas), ofrece agregarle `labels.ready` para que una corrida futura pueda
   tomarla. Si no la cumple, no la marques y di qué le falta. Si el repo no
   tiene ese label, no lo crees sin preguntar.
5. En el reporte al usuario, di qué prioridad, estimado y milestone elegiste, y
   si fueron como labels o en el cuerpo, para que pueda corregirlos.
