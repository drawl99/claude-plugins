---
max_turns: 6
allowed_tools: [Skill]
---

Voy a arrancar esta issue. ¿La trabajo con SDD completo (propuesta, specs, diseño y tareas antes de tocar código) o con flujo directo? Dame una recomendación y por qué. Solo tengo el texto de la issue.

**#321 — Sale se lee sin lock en el flujo de captura síncrono**

Detectado en code review de #209. El fix de esa issue agrega una lectura con lock sobre `Sale` en los caminos async (webhook y expiración), pero la captura síncrona (`PaymentService.capturePayment`) sigue leyendo `Sale` con `findByIdAndTenantId`, sin lock. Bajo READ_COMMITTED una captura síncrona y una expiración async casi simultáneas pueden actuar sobre una foto vieja de la venta.

Definición de terminado:
- [ ] `capturePayment` lee la venta con `SaleRepository.findByIdAndTenantIdForUpdate` (ya existe desde #209).
- [ ] No se introduce un deadlock nuevo entre `Sale` y `Payment`.
- [ ] Test unitario que falla antes del cambio.
- [ ] Test de integración de concurrencia: captura síncrona y expiración async simultáneas dejan la venta consistente.
- [ ] `PaymentCaptureIT` sigue en verde.
