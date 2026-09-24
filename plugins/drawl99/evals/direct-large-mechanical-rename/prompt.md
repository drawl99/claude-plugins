---
max_turns: 6
allowed_tools: [Skill]
---

Voy a arrancar esta issue. ¿La trabajo con SDD completo (propuesta, specs, diseño y tareas antes de tocar código) o con flujo directo? Dame una recomendación y por qué. Solo tengo el texto de la issue.

**Renombrar el paquete `com.acme.commerce.common` a `com.acme.commerce.shared`**

El nombre `common` choca con la convención del resto de servicios. Hay que mover el paquete y actualizar los imports: son unos 60 archivos entre `src/main` y `src/test` de commerce. No cambia ningún comportamiento ni ninguna API pública; el IDE hace el movimiento.

Definición de terminado:
- [ ] El paquete se llama `shared` y no queda ninguna referencia a `commerce.common`.
- [ ] `./mvnw clean verify` de commerce en verde, con el mismo número de tests.
