# G1_CY401_MN_TallerPractico1
Este repositorio es para el taller práctico del grupo 1 para el curso CY401.

## Estudiante 1: Arquitectura, Entorno y Captura de Interrupciones (Líder Técnico): Aaron
- Parte 1: Preparación del entorno (Taller1, monitoreo.sh, permisos).
- Parte 3 (Punto 1 y 2): Estructura inicial del script (Shebang #!/bin/bash, comentarios del curso/integrantes).
- Parte 3 (Punto 9): Implementación de la captura de interrupciones con trap para registrar eventos en el log si el script se corta inesperadamente.
- Integración: Recibir los módulos de los compañeros y ensamblarlos en el script final.

## Estudiante 2: Monitoreo Base y Alertas de Sistema: Nicole
- Parte 3 (Punto 3): Implementar la recolección de datos usando top, free y df con sus respectivas marcas de tiempo (revisar el uso de awk según el enlace provisto).
- Parte 3 (Punto 4): Crear el condicional de alerta si el uso de la memoria RAM supera el 70%.
- Variables: Definir las rutas y variables necesarias para el funcionamiento de sus comandos.

## Estudiante 3: Menú Interactivo (case) y Automatización en Bucle: Celestita
- Parte 3 (Punto 12): Desarrollar la interfaz del menú utilizando la estructura condicional case (Opciones: 1. Ver CPU, 2. Procesos activos, 3. Salir).
- Parte 3 (Punto 12.1): Manejo de errores/opciones incorrectas en el menú.
- Parte 3 (Punto 6): Implementar el bucle for o while para que el monitoreo se repita cada 60 segundos durante 5 iteraciones.

## Estudiante 4: Diagnóstico de Procesos y Gestión de Respaldos (Tar): Elian
- Parte 3 (Punto 5): Programar la función verificar_proceso() que reciba un argumento (nombre de proceso) y valide si está activo en el sistema.
- Parte 3 (Punto 10 y 11): Crear la lógica que verifica si los logs anteriores superan los 10 MB y, de ser así, realizar el respaldo comprimido con tar -czf.

## Estudiante 5: Redirección Avanzada, Logs y Automatización Cron: Monse
- Parte 2: Configuración correcta de todas las Variables Globales (LOG_DIR, LOG_FILE, etc.).
- Parte 3 (Punto 7): Configurar la redirección de la salida estándar (stdout) y de error (stderr) a archivos separados. Crear el descriptor adicional (exec 3> debug.log) para depuración.
- Parte 3 (Punto 6.2): Generar el archivo final resumen.txt.
- Parte 3 (Punto 8): Configurar la tarea programada en cron para que el script se ejecute automáticamente cada hora.

## Estudiante 6: Control de Calidad, Evidencias y Documentación Profesional: Camilo
- QA (Quality Assurance): Probar el script final en su entorno para asegurar que no tenga bugs y que cumpla con los criterios de "Optimización" de la rúbrica.
- Evidencias: Tomar las capturas de pantalla requeridas (ejecución del script, logs generados, tarea en cron).
- Informe Final (PDF): Redactar y dar formato profesional al documento con la portada, objetivos, descripción, conclusiones, aprendizajes y el código limpio y comentado de todo el grupo.

# Instrucciones
Incluir comandos de ejecución.