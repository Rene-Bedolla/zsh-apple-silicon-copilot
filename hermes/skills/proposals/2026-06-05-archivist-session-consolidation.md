# Skill Proposal Template

## Nombre tentativo
archivist-session-consolidation

## Problema que resuelve
Existe una necesidad recurrente de convertir sesiones largas de diseño, configuración y planeación en resúmenes limpios, decisiones explícitas, backlog accionable y evaluación de automatización futura.

## Evidencia de repetición
- Caso observado 1: la sesión de bootstrap de Hermes produjo múltiples decisiones estructurales y necesitó consolidarse en memoria operativa
- Caso observado 2: apareció la necesidad explícita de no depender de edición manual archivo por archivo
- Caso observado 3: se estableció un patrón claro de bloques EOF únicos y de salida estructurada reutilizable

## Tipo de solución recomendada
- Aún no formalizar

## Por qué sí conviene
- Reduce pérdida de contexto tras sesiones largas
- Facilita convertir conversación en backlog real
- Permite detectar mejor cuándo una tarea ya merece script, skill o cron

## Por qué no conviene todavía
- Riesgo: solo existe una sesión formalmente consolidada con este nuevo contrato
- Complejidad: implementar demasiado pronto puede fijar un formato que todavía no ha madurado
- Dependencias: falta observar al menos una o dos sesiones más para validar consistencia
- Señales faltantes: no hay todavía suficiente evidencia de repetición transversal

## Entradas esperadas
- Transcripción o resumen de sesión
- Contexto del proyecto actual
- Plantilla de resumen operativo

## Salidas esperadas
- Archivo Markdown de resumen
- Backlog accionable
- Evaluación de automatización futura
- Propuesta de skill, script o cron cuando aplique

## Dependencias
- Archivo: `~/Documents/dotfiles/hermes/agents/archivist/templates/session-summary.md`
- Archivo: `~/Documents/dotfiles/hermes/agents/archivist/templates/skill-proposal.md`
- Servicio: Hermes Agent
- Tool: flujo Archivist
- Variable o credencial: ninguna específica por ahora

## Frecuencia esperada
- Bajo demanda

## Riesgos
- Riesgo 1: sobrediseñar una capacidad todavía inmadura
- Riesgo 2: duplicar contenido entre memoria, backlog y resúmenes

## Recomendación final
Mantener esta propuesta en `skills/proposals/` y revisarla después de al menos una o dos sesiones adicionales archivadas con el mismo formato. Si el patrón se repite con utilidad clara, el siguiente paso debería ser un script local de apoyo, no un cron.
