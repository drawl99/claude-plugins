# Hosts: Claude Code, OpenCode y Pi

Las skills están escritas con los nombres de herramientas de Claude Code. En
OpenCode y en Pi, usa el equivalente de esta tabla. Si una herramienta no existe
en el host, usa la alternativa indicada; nunca te saltes el paso que la
necesitaba.

| Qué se necesita | Claude Code | OpenCode | Pi |
|---|---|---|---|
| Invocar `github-goal` | `/drawl99:github-goal [#123 \| owner/repo#123]` | `/github-goal [#123 \| owner/repo#123]` | `/skill:github-goal [#123 \| owner/repo#123]` |
| Invocar `workflow-decision` | `/drawl99:workflow-decision` o pedirlo | `/workflow-decision` o pedirlo | `/skill:workflow-decision` o pedirlo |
| Preguntar al usuario con opciones (elegir repo, alcance, modo, ruta…) | `AskUserQuestion` | `question` | `ask_user_question` (paquete `@juicesharp/rpiv-ask-user-question`). Sin él, pregunta en texto plano con las opciones numeradas y **detente** hasta la respuesta. |
| Sub-agente | `Agent` (tipo `general-purpose`) | `task` (sub-agente `general` o el que el usuario tenga configurado) | `subagent_run` y `subagent_result` (paquete `pi-subagents`). Sin él, ver *Sin sub-agentes*, abajo. |
| Modelo del sub-agente (ruta directa) | parámetro `model` de `Agent` (`opus`, `sonnet`, `haiku`) | si `task` no acepta modelo por llamada, el del sub-agente configurado en `opencode.json` (⚠️ en el chequeo) | si `subagent_run` no acepta modelo por llamada, el configurado en `pi-subagents` (⚠️ en el chequeo) |
| Revisión de código | `/code-review` | un sub-agente de revisión de solo lectura | un sub-agente de revisión de solo lectura |
| GitHub | `gh` CLI | `gh` CLI | `gh` CLI |
| SDD de gentle-ai | skills y agentes `sdd-*`; flujo en `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` | comandos `/sdd-*` y agente `gentle-orchestrator`; skills en `~/.config/opencode/skills/sdd-*` | paquete `gentle-pi` (skills `gentle-ai-*` y sus prompts) |
| Memoria (opcional) | Engram (`mem_*`) | Engram si está configurado | `gentle-engram` |

## Sin sub-agentes

Si el host no tiene una herramienta de sub-agentes, la ruta directa se hace en
la sesión principal, con más disciplina de contexto: lee solo lo que el cambio
necesita, corre las pruebas filtrando la salida al resumen (conteos y fallas, no
el log completo) y no pegues diffs enteros. Dilo en el chequeo de requisitos
(⚠️) para que el usuario sepa que la sesión se va a llenar más rápido.

## Invocación explícita

En Claude Code y en Pi, `github-goal` solo arranca cuando el usuario la invoca:
el frontmatter `disable-model-invocation` lo garantiza. **OpenCode ignora ese
campo**, así que la regla vive también en el texto de la skill: si llegaste a
`github-goal` porque la inferiste de la conversación, y no porque el usuario la
invocó con el comando o la nombró, no arranques; pregunta si quiere correrla.
