# Hosts: Claude Code, OpenCode y Pi

Las skills están escritas con los nombres de herramientas de Claude Code. En
OpenCode y en Pi, usa el equivalente de esta tabla. Si una herramienta no existe
en el host, usa la alternativa indicada; nunca te saltes el paso que la
necesitaba.

| Qué se necesita | Claude Code | OpenCode | Pi |
|---|---|---|---|
| Invocar `github-goal` | `/drawl99:github-goal [#123 \| owner/repo#123]` | `/github-goal [#123 \| owner/repo#123]` | `/skill:github-goal [#123 \| owner/repo#123]` |
| Invocar `workflow-decision` (skill aparte, asesora; `github-goal` no la usa) | `/drawl99:workflow-decision` o pedirlo | `/workflow-decision` o pedirlo | `/skill:workflow-decision` o pedirlo |
| Preguntar al usuario con opciones (elegir repo, alcance, modo…) | `AskUserQuestion` | `question` | `ask_user_question` (propia del paquete `gentle-pi` desde gentle-ai 3.6.1; `gentle-ai sync` quita `@juicesharp/rpiv-ask-user-question`, que choca con ella). Para un sobre cerrado de una sola opción, como el consentimiento de revisión, `ask_user_choice`, también de `gentle-pi`. Sin ellas, pregunta en texto plano con las opciones numeradas y **detente** hasta la respuesta. |
| Sub-agente (los usa gentle-ai) | `Agent` | `task` (sub-agente `general` o el que el usuario tenga configurado) | herramientas `subagent_*` del paquete `gentle-pi` (reemplazan a `pi-subagents`). Sin ellas, ver *Sin sub-agentes*, abajo. |
| Revisión de código | con RDD encendido, la nativa de gentle-ai; si no, `/code-review` | con RDD encendido, la nativa de gentle-ai; si no, un sub-agente de revisión de solo lectura | con RDD encendido, la nativa de gentle-ai (`gentle_review`); si no, un sub-agente de revisión de solo lectura |
| GitHub | `gh` CLI | `gh` CLI | `gh` CLI |
| Orquestador de gentle-ai (ODD) | instrucciones de gentle-ai en `~/.claude/CLAUDE.md` | agente `gentle-orchestrator` | paquete `gentle-pi` |
| SDD de gentle-ai | comandos `/gentle-sdd-*` (desde 3.7.0; antes `/sdd-*`) y agentes `sdd-*`; flujo en `~/.claude/skills/_shared/sdd-orchestrator-workflow.md` | comandos `/sdd-*` y agente `gentle-orchestrator`; skills en `~/.config/opencode/skills/sdd-*` | paquete `gentle-pi`: comandos `/gentle-sdd-*` y su flujo SDD |
| Memoria (opcional) | Engram (`mem_*`) | Engram si está configurado | `gentle-engram` |

## Sin sub-agentes

Si el host no tiene una herramienta de sub-agentes, gentle-ai trabaja la issue
en la sesión principal, con más disciplina de contexto: lee solo lo que el
cambio necesita, corre las pruebas filtrando la salida al resumen (conteos y
fallas, no el log completo) y no pegues diffs enteros. Dilo en el chequeo de requisitos
(⚠️) para que el usuario sepa que la sesión se va a llenar más rápido.

## Invocación explícita

En Claude Code y en Pi, `github-goal` solo arranca cuando el usuario la invoca:
el frontmatter `disable-model-invocation` lo garantiza. **OpenCode ignora ese
campo**, así que la regla vive también en el texto de la skill: si llegaste a
`github-goal` porque la inferiste de la conversación, y no porque el usuario la
invocó con el comando o la nombró, no arranques; pregunta si quiere correrla.
