---
name: workflow-decision
description: Recomienda si una issue o tarea de desarrollo se trabaja con SDD completo (propuesta, specs, diseño y tareas antes del código) o con flujo directo, explicando por qué con señales de la issue. Úsala cuando alguien pregunte si una issue necesita SDD, planificación formal o diseño previo, o antes de empezar a implementar una issue.
---

# workflow-decision: SDD completo o directo

Se decide por issue, después de leer la issue completa (descripción, criterios
de aceptación, comentarios, issues relacionadas) y, si estás en el repositorio,
el código que toca. Si solo tienes el texto de la issue, decide con eso y dilo. La
pregunta de fondo es una sola:

> ¿Escribir propuesta, specs, diseño y tareas **reduce una ambigüedad real**
> antes de tocar código?

Si la respuesta es sí, SDD completo. Si no, directo.

## Señales a favor de SDD completo

- La issue deja una **decisión de diseño abierta**: "la decisión es parte de
  esta issue", "decidir", "definir", varias alternativas sin elegir.
- **Cambia un contrato** entre servicios, equipos o con un cliente externo
  (API, evento, esquema compartido), o hay que congelarlo para que otra persona
  trabaje en paralelo.
- **Modelo de dominio nuevo** (agregado, entidad o servicio nuevo), o cambia el
  significado de datos que ya existen.
- **Migración de datos con backfill** o sin vuelta atrás fácil.
- **Semántica de seguridad o de aislamiento** (permisos, tenancy, dinero), donde
  un error de criterio es caro y conviene que quede escrito qué se decidió y por
  qué.
- Los criterios de aceptación **no son verificables tal como están** y hay que
  convertirlos en escenarios concretos.
- Coordinación entre varios servicios en la que el orden de los cambios importa.

## Señales a favor de flujo directo

- Criterios de aceptación **concretos y verificables** tal como están escritos.
- Se sabe **dónde** está el cambio, y sigue un patrón que ya existe en el código.
- Bug con reproducción clara.
- Cambios de configuración, CI, documentación o dependencias.
- Un solo servicio y ninguna decisión que otra persona tenga que revisar antes.

## Lo que NO decide

- **El tamaño o la cantidad de archivos, por sí solos, nunca eligen SDD.** Un
  cambio grande pero mecánico va directo; uno chico con una decisión de
  contrato merece SDD.
- El label de la issue, por sí solo. `security` suma una señal, pero un fix de
  seguridad con reproducción y solución conocida puede ir directo.

## Si SDD no está disponible

El SDD de referencia es el de **gentle-ai** (`gentle-ai` en el PATH, con sus
skills y agentes `sdd-*`). Si no está instalado, la recomendación es **directo** y se
dice por qué ("SDD no está instalado en este entorno"). Si la issue tenía
señales fuertes a favor de SDD, menciónalo: puede convenir instalar SDD antes o
dejar el diseño escrito en la descripción del PR.

## Cómo presentarlo

La respuesta siempre incluye, **en el mensaje final**, este bloque:

```
Issue <identificador> — <título>
Recomendación: SDD completo | Directo
Por qué: <2 o 3 señales, citando la issue o el código>
Qué implica: <artefactos que se escriben (SDD) o plan breve (directo)>
```

Después, según quién te invocó:

- **Pedida directamente** ("¿esta issue va con SDD?"): la respuesta es el bloque.
  No preguntes cuál ruta prefiere: te pidieron una recomendación, dala. Puedes
  cerrar con una línea sobre lo que cambiaría la recomendación, si aplica.
- **Desde `github-goal`** (antes de implementar una issue): después del bloque,
  una sola pregunta con la herramienta de preguntas del host (`AskUserQuestion`
  en Claude Code, `question` en OpenCode, `ask_user_question` en Pi), con la opción recomendada primero y
  "(Recomendado)" al final de su etiqueta, y la otra ruta con su costo en una
  línea. Respeta la respuesta aunque contradiga la recomendación, y deja la ruta
  elegida y el motivo en la descripción del PR.
