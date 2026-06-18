---
version: "1.2"
actualizado: "2026-05-20"
publico: true
---

# HERMES — Historial de Sesiones

> Registro mínimo de arranques del harness y sesiones clave.
> Cada entrada corresponde a una ejecución de init.sh u otros eventos importantes.

## 2026-05-20 11:59:00 — dashboard LaunchAgent desactivado

- resultado: LaunchAgent del dashboard desactivado temporalmente
- motivo: `com.rene.hermes-dashboard` continúa saliendo con `EX_CONFIG (78)` bajo launchd
- estado_dashboard: funcional en arranque manual
- comando_operativo: `hermes-dashboard-on`
- nota: se prioriza operación estable y sin fricción; la depuración de launchd queda pendiente para una sesión futura

## 2026-05-20 11:38:00 — normalización documental

- resultado: documentación alineada con operación real
- resumen_diario: operativo=true
- scheduler: cron interno de Hermes
- resumen_skill: resumen_texto
- telegram_gateway: canal activo principal
- whatsapp_gateway: fuera de alcance en la fase actual
- nota: se actualizan SOUL.md, agents.md, features.json y README.md para reflejar el flujo vigente y la corrección del ruido/monólogo previo en la salida

## 2026-05-19 14:05:56 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1779221155}, {"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1779221155}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1779221155}]}]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-05-19 16:24:59 — init.sh

- resultado: 10 OK, 1 WARN, 0 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1779229497}, {"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1779229497}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1779229497}]}]
- hermes_agent: installed=true
- telegram_gateway: up=false

## 2026-05-20 12:12:00 — H-002 cerrado

- resultado: H-002 marcado como cerrado en `features.json`
- motivo: el resumen diario ya está operativo en uso real
- estado_resumen_diario: funcional
- entrega: Telegram
- scheduler: cron interno de Hermes
- nota: se cierra la tarea por cumplimiento operativo, aunque el dashboard quede con arranque manual mediante `hermes-dashboard-on`

## 2026-05-22 13:00:14 — init.sh

- resultado: 10 OK, 0 WARN, 1 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1779476411}, {"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1779476411}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1779476411}]}]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-05-22 13:28:09 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1779478089}, {"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1779478089}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1779478089}]}]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-05-22 13:43:14 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1779478994}, {"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1779478994}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1779478994}]}]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-05-22 15:14:00 — dashboard-off fix

- bug: hermes-dashboard-off no liberaba :8421 correctamente
- fix: matar el proceso con mejor manejo de PID y liberación del socket
- estado: resuelto
- impacto: dashboard manual y launchd ya no entran en conflicto

## 2026-05-26 12:25:48 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-05-27 08:00:26 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-05-28 08:00:07 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-05-29 08:00:17 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-05-30 08:00:37 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-05-31 08:00:35 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-01 08:00:50 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-02 08:00:35 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-03 08:00:37 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-04 08:00:19 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-05 08:00:15 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-05 12:21:49 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1780683709}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1780683709}, {"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1780683709}]}]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-05 15:43:00 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[{"object": "list", "data": [{"id": "mlx-community/Qwen3-8B-4bit", "object": "model", "created": 1780695779}, {"id": "mlx-community/Qwen3-4B-4bit", "object": "model", "created": 1780695779}, {"id": "mlx-community/Qwen3-VL-4B-Instruct-4bit", "object": "model", "created": 1780695779}]}]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-05 16:04:39 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-8B-4bit, mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-05 16:08:25 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-8B-4bit, mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-05 16:09:28 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-8B-4bit, mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-06 08:00:37 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-07 08:00:16 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-11 08:00:46 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-13 08:00:47 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-14 08:00:36 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente

## 2026-06-16 12:06:32 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-8B-4bit, mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-16 16:22:38 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-VL-4B-Instruct-4bit, mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-8B-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-17 11:28:36 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-8B-4bit, mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-17 15:21:28 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3-4B-4bit, mlx-community/Qwen3.5-4B-OptiQ-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit, mlx-community/Qwen3-8B-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-17 15:36:03 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3.5-4B-OptiQ-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit, mlx-community/Qwen3-4B-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-17 15:43:05 — init.sh

- resultado: 11 OK, 0 WARN, 0 FAIL
- mlx: up=true, modelos=[mlx-community/Qwen3.5-4B-OptiQ-4bit, mlx-community/Qwen3-VL-4B-Instruct-4bit, mlx-community/Qwen3-4B-4bit]
- hermes_agent: installed=true
- telegram_gateway: up=true

## 2026-06-18 08:00:13 — resumen-diario

- resultado: ok
- canal: telegram
- origen: cron
- nota: resumen diario generado y entregado correctamente
