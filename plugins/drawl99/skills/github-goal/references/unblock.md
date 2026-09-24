# Desbloqueo: tomar una issue que no es tuya

Sirve para cuando el trabajo de otra persona te frena: por ejemplo, en un repo
con colaboradores necesitas una issue de otra persona para cerrar el milestone
y todavía no la empezó.

**Solo aplica si estás bloqueado**: no queda ninguna issue tuya disponible en
el grupo actual (milestone o sin milestone), y al menos una de tus issues
pendientes de ese grupo está frenada por un bloqueante abierto. Si tienes
trabajo propio disponible, esta excepción no existe.

Una issue ajena es candidata solo si cumple **todo**:

- Es ajena: asignada a otra persona (o sin asignar, con `assignee: "me"`; con
  `"me-or-unassigned"` una issue sin asignar ya se puede tomar por *Selección*).
- Bloquea, directa o transitivamente, a una de tus issues pendientes del mismo
  alcance (por dependencia nativa `blocked_by` o escrita en la descripción).
- Nadie la empezó: sin rama enlazada (`gh issue develop --list <n> -R <owner/repo>`),
  sin PR abierto que la referencie
  (`gh pr list -R <owner/repo> --search "#<n>" --state open`), sin comentario de
  reclamo.
- Cumple el resto de *Selección* (en `SKILL.md`): sus propios bloqueantes
  cerrados, el label de lista (si el repo lo tiene), sin `needs-spec` ni
  `blocking`, sin sub-issues abiertas.

Si hay varias, ordénalas por cuántas de tus issues destrabarían (más primero)
y después por orden de trabajo.

**Siempre se pregunta**, aunque las preferencias digan lo contrario: tomar el
trabajo de otra persona es decisión del usuario, nunca del agente. Muestra la
issue, a quién está asignada y qué issues tuyas destraba, y ofrece "Tomarla"
o "Seguir sin tomarla". Con `takeBlockingIssues: "never"` en las
preferencias personales no se ofrece: solo se reporta el bloqueo.

Si el usuario acepta:

1. **Vuelve a leer la issue justo antes**
   (`gh issue view <n> -R <owner/repo> --json state,assignees,comments`, su rama
   enlazada y los PRs que la referencian): si mientras tanto la empezaron (se
   cerró, cambió el asignado, apareció una rama, un PR o un reclamo),
   suéltala y dilo.
2. **Reasígnala** al usuario actual:
   `gh issue edit <n> -R <owner/repo> --remove-assignee <persona> --add-assignee @me`.
   Es el único cambio de campo permitido; no agregues labels de estado.
3. **Comenta en la issue** mencionando a quien la tenía asignada, para que
   GitHub le avise: "@<persona> tomo esta issue porque bloquea #<X>, que es
   mía, y todavía no estaba empezada. Si ya la estabas por arrancar, avísame y
   la suelto." Sin asignado previo, el mismo comentario sin mención.
4. Sigue el *Flujo por issue* normal de `SKILL.md`. El PR dice en la descripción que se
   tomó para desbloquear y cuál issue destraba.

En modo **una issue**, las candidatas de desbloqueo aparecen en la lista solo
si no tienes ninguna issue propia disponible, marcadas con su asignado y la
issue que destraban.
