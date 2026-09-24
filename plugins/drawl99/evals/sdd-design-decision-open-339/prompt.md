---
max_turns: 6
allowed_tools: [Skill]
---

Voy a arrancar esta issue. ¿La trabajo con SDD completo (propuesta, specs, diseño y tareas antes de tocar código) o con flujo directo? Dame una recomendación y por qué. Solo tengo el texto de la issue.

**#339 — El filtro de tenant de Hibernate es inerte en los seis servicios**

El `@Filter(tenantFilter)` se habilita desde un filtro de servlet, fuera de toda transacción, con `open-in-view: false`: se habilita sobre una sesión que se descarta, y los métodos `@Transactional` abren una sesión sin filtro. Afecta a customers, fiscal, catalog, commerce, validator e identity. Hoy solo protegen los predicados explícitos de `tenant_id`.

Definición de terminado:
- [ ] El filtro se habilita dentro de la transacción que lo va a usar (un aspecto alrededor de `@Transactional`, un interceptor de sesión de Hibernate, o el mecanismo que se decida) — la decisión de diseño es parte de esta issue.
- [ ] Un test de integración por servicio que pruebe el caso real.
- [ ] Revisar si algún repositorio ya depende del filtro y omite el predicado explícito — esas son fugas activas.
- [ ] Corregir la documentación de la "defensa de 3 capas".
