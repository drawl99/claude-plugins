---
max_turns: 6
allowed_tools: [Skill]
---

Voy a arrancar esta issue. ¿La trabajo con SDD completo (propuesta, specs, diseño y tareas antes de tocar código) o con flujo directo? Dame una recomendación y por qué. Solo tengo el texto de la issue.

**#312 — CI: build-push falla en todos los servicios Java**

El job `build-push` falla porque `working-directory` apunta al path del servicio antes del `actions/checkout`, así que el directorio todavía no existe. Hay que darle al paso previo su propio `working-directory` después del checkout.

Definición de terminado:
- [ ] El job `build-push` corre en verde para los servicios Java.
- [ ] El paso de preflight tiene su propio `working-directory` válido.
