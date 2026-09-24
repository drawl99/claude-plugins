---
max_turns: 6
allowed_tools: [Skill]
---

Voy a arrancar esta issue. ¿La trabajo con SDD completo (propuesta, specs, diseño y tareas antes de tocar código) o con flujo directo? Dame una recomendación y por qué. Solo tengo el texto de la issue.

**Agregar `customer_document` al evento `SALE_CONFIRMED`**

`fiscal` y `operations` consumen `SALE_CONFIRMED` desde Service Bus. `fiscal` necesita el documento del cliente para facturar sin llamar a `customers`. Hay que agregar el campo al payload del evento. Todavía no está decidido si se sube la versión del evento (v3 → v4) o se agrega como campo opcional en v3, ni qué hace `operations` con eventos viejos que no lo traen.

Definición de terminado:
- [ ] `SALE_CONFIRMED` incluye `customer_document`.
- [ ] `fiscal` lo usa al facturar.
- [ ] Los consumidores siguen funcionando con eventos anteriores al cambio.
