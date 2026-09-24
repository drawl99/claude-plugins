---
max_turns: 6
allowed_tools: [Skill]
---

Voy a arrancar esta issue. ¿La trabajo con SDD completo (propuesta, specs, diseño y tareas antes de tocar código) o con flujo directo? Dame una recomendación y por qué. Solo tengo el texto de la issue.

**#216 — Generar la secuencia entera por tenant para el WS de la Caja**

`fx_guarda_data` (web service de la Caja de compensación, externo) exige que nosotros proveamos `MaestroFactura` y `DetalleFactura` como enteros únicos, y valida unicidad contra su base Informix. Nuestro sistema usa UUIDv7 en todas partes. Ojo: `PrefijoFactura` y `NumeroFactura` son el número legal de la factura y los asigna `fiscal`; no se inventan. Confundir las dos numeraciones produce duplicados en la Caja.

Definición de terminado:
- [ ] Secuencia entera persistida y monotónica por tenant para `MaestroFactura` y `DetalleFactura`.
- [ ] `PrefijoFactura` y `NumeroFactura` se toman de `Invoice`, nunca de la secuencia local.
- [ ] Mapeo uno a uno y estable entre venta y `MaestroFactura`, y entre línea y `DetalleFactura`.
- [ ] Un reintento del mismo envío reutiliza el mismo entero.
- [ ] Prueba de concurrencia: cien ventas simultáneas producen cien enteros distintos y contiguos.
