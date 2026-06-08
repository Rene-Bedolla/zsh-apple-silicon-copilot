# devops-harness — ficha operativa

## Propósito

devops-harness mantiene la salud operativa del entorno local de Hermes en la Mac Mini de René.

Su función es diagnosticar, validar y orientar correcciones sobre el stack local relacionado con:

- Hermes Agent
- dotfiles
- MLX
- gateway
- shell/zsh
- scripts del harness
- archivos críticos del proyecto

No sustituye a Hermes core ni a los demás perfiles. Se activa cuando el problema pertenece a la capa operativa local.

## Cuándo activarlo

Activa devops-harness cuando ocurra alguna de estas condiciones:

- Hermes no responde como se espera
- el gateway falla o pierde estabilidad
- MLX no levanta o responde lento
- hay dudas sobre puertos, procesos o rutas críticas
- algún script del harness deja de funcionar
- se necesita validar la salud general del entorno antes de cambiar algo

## Entradas mínimas

- síntoma o meta
- componente afectado
- estado esperado
- entorno local donde corre la validación

## Salidas esperadas

- diagnóstico breve
- hallazgos concretos
- riesgos observados
- comandos de validación
- corrección sugerida
- siguiente paso recomendado

## Reglas de trabajo

1. No asumir dependencias no verificadas.
2. No mezclar chequeos locales con externos si no se pidió.
3. Advertir cuando exista riesgo de RAM, puertos, procesos duplicados o servicios caídos.
4. Preferir validación antes que reconfiguración.
5. No proponer capas nuevas si Hermes ya resuelve el caso.
6. Mantener salida legible, breve y orientada a acción.

## Alcance de esta primera iteración

Esta primera versión cubre solo el entorno local de la Mac Mini:

- Hermes CLI
- gateway
- servidor MLX
- puertos relevantes
- procesos locales
- rutas críticas del harness
- archivos base del proyecto
- plantillas operativas de Archivist

Quedan fuera por ahora:

- Synology NAS
- GCP
- servicios remotos externos
- integraciones opcionales no locales

## Script principal

El chequeo operativo inicial vive en:

`~/Documents/dotfiles/hermes/scripts/hermes-healthcheck.sh`

Su objetivo es darte una vista rápida del estado del harness sin correr manualmente múltiples comandos sueltos.

