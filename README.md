# G1_CY401_MN_TallerPractico1
Este repositorio es para el taller práctico del grupo 1 para el curso CY401.

## Descripción de la Práctica

Esta práctica implementa un **Sistema de Monitoreo y Automatización del Sistema** mediante un script de bash que recolecta métricas de rendimiento (CPU, memoria, disco), genera alertas automáticas y mantiene registros detallados en archivos de log. El script está diseñado como un trabajo colaborativo entre 6 estudiantes, cada uno contribuyendo módulos específicos según sus responsabilidades.

---

## Cómo Ejecutar el Script

### Requisitos Previos
- Sistema operativo Linux o Unix
- Acceso a `bash` (versión 4.0 o superior recomendada)
- Comandos disponibles: `top`, `free`, `df`, `awk`
- Permisos para crear directorios en el directorio de trabajo

### Pasos de Ejecución

#### 1. **Preparación Inicial**
```bash
# Navegar al directorio del proyecto
cd /ruta/al/proyecto/G1_CY401_MN_TallerPractico1

# Hacer ejecutable el script
chmod +x monitoreo.sh

# (Opcional) Crear directorio de logs manualmente
mkdir -p logs
```

#### 2. **Ejecución Básica**
```bash
# Ejecutar el script con configuración por defecto
bash monitoreo.sh
```

Esto abrirá un **menú interactivo** donde puede seleccionar:
- **Opción 1**: Ver información de CPU
- **Opción 2**: Ver top 10 de procesos por uso de CPU
- **Opción 3**: Salir del menú e iniciar el monitoreo del sistema

#### 3. **Ejecución con Variables Personalizadas**
```bash
# Ejemplo: Ejecutar con umbral de memoria diferente (85% en lugar de 70%)
THRESHOLD_MEM=85 bash monitoreo.sh

# Ejemplo: Ejecutar con directorio de logs personalizado
LOG_DIR=/var/log/miapp bash monitoreo.sh

# Ejemplo: Combinar múltiples variables
LOG_DIR=/home/usuario/logs THRESHOLD_MEM=80 bash monitoreo.sh
```

#### 4. **Consultar los Logs Generados**
```bash
# Ver los últimos 100 líneas del log
tail -n 100 logs/monitoreo_$(date +%Y-%m-%d).log

# Ver log en tiempo real (si el script está en ejecución)
tail -f logs/monitoreo_$(date +%Y-%m-%d).log

# Buscar alertas de memoria en los logs
grep "ALERTA" logs/monitoreo_*.log
```

#### 5. **Programar en Cron (Ejecución Automática)**
```bash
# Abrir editor de crontab
crontab -e

# Agregar línea para ejecutar cada hora (a las :00 minutos)
0 * * * * /ruta/completa/al/script/monitoreo.sh >> /dev/null 2>&1

# Para ejecutar cada 30 minutos:
*/30 * * * * /ruta/completa/al/script/monitoreo.sh >> /dev/null 2>&1

# Para ejecutar diariamente a las 08:00:
0 8 * * * /ruta/completa/al/script/monitoreo.sh >> /dev/null 2>&1
```

---

## Explicación del Funcionamiento

### Arquitectura General del Script

El script está estructurado en tres fases principales:

```
┌─────────────────────────────────────────┐
│   FASE 1: INICIALIZACIÓN                │
│   - Crear directorio de logs            │
│   - Configurar archivo de log           │
│   - Mostrar menú interactivo            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│   FASE 2: MONITOREO (5 iteraciones)     │
│   - Recolectar métricas cada 60s        │
│   - Verificar alertas de memoria        │
│   - Registrar todo en logs              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│   FASE 3: FINALIZACIÓN                  │
│   - Registrar hora de término           │
│   - Cerrar archivos de log              │
│   - Salida exitosa (exit 0)             │
└─────────────────────────────────────────┘
```

### Componentes Principales

#### **1. Variables Globales**
Define la configuración del sistema:
- `LOG_DIR`: Directorio donde se almacenan los logs (`./logs`)
- `LOG_FILE`: Archivo de log con fecha (`monitoreo_YYYY-MM-DD.log`)
- `THRESHOLD_MEM`: Umbral de memoria para alertas (70% por defecto)
- `ITERATIONS`: Número de ciclos de monitoreo (5 iteraciones)
- `SLEEP_INTERVAL`: Tiempo entre iteraciones (60 segundos)

#### **2. Funciones Auxiliares**

**a) `manejar_interrupcion()` - Captura de Señales (Estudiante 1: Aaron)**
- Captura Ctrl+C (SIGINT) del usuario
- Registra la interrupción en el log con marca de tiempo
- Permite salida ordenada del script sin perder información

**b) `recolectar_metricas()` - Recolección de Datos (Estudiante 2: Nicole)**
- Ejecuta comandos `top`, `free` y `df`
- Captura snapshots de CPU, memoria y disco
- Registra todo con marca de tiempo en el archivo de log
- Permite historial completo de comportamiento del sistema

**c) `porcentaje_memoria_usada()` - Cálculo de Memoria (Estudiante 2: Nicole)**
- Lee `/proc/meminfo` para obtener datos precisos de memoria
- Calcula porcentaje de uso: `(Total - Disponible) / Total * 100`
- Fallback a comando `free` si `/proc/meminfo` no está disponible
- Resultado se usa para validar umbral de alertas

**d) `comprobar_alerta_memoria()` - Validación de Alertas (Estudiante 2: Nicole)**
- Verifica si el uso de memoria supera `THRESHOLD_MEM`
- Si supera el umbral, registra "[ALERTA]" en el log
- Retorna código de salida (0=OK, 1=Alerta)

**e) `mostrar_menu()` - Interfaz Interactiva (Estudiante 3: Celestita)**
- Menú en bucle continuo que reaparece tras cada opción
- Opción 1: Muestra CPU actual
- Opción 2: Muestra top 10 de procesos
- Opción 3: Sale del menú e inicia monitoreo
- Valida opciones incorrectas con mensaje de error

#### **3. Flujo de Ejecución Principal**

```bash
# 1. Inicializar sistema
crear_directorio_logs              # Crea ./logs si no existe
mostrar_menu                       # Muestra menú interactivo
LOG_FILE=...                       # Configura ruta del archivo de log

# 2. Registrar inicio
echo "Inicio de Monitoreo..."     # Marca temporal en log

# 3. Iterar monitoreo (5 veces)
for i in 1..5:
    recolectar_metricas()         # Captura datos (top, free, df)
    comprobar_alerta_memoria()    # Verifica umbrales
    sleep 60                       # Espera 60 segundos (excepto última iteración)

# 4. Finalizar
echo "Fin de Monitoreo..."        # Marca temporal en log
exit 0                             # Salida exitosa
```

### Manejo de Errores

- **Directorio de logs inexistente**: Se crea automáticamente
- **Archivo de log no accesible**: El script continúa pero registra en stderr
- **Memoria no calculable**: Asume 0% y continúa
- **Opción inválida en menú**: Muestra error y repite el menú
- **Ctrl+C durante ejecución**: Trap captura y registra gracefully

### Salida de Logs

Cada archivo de log contiene:
```
============================================================
Inicio de Monitoreo - 2024-01-15 10:30:45
Usuario: nombredeusuario
Log Guard: nombredeusuario_tailer1
============================================================

--- Iteración 1 de 5 ---

===== Registro: 2024-01-15 10:30:45 =====
--- top (resumen de CPU/mem) ---
Cpu(s):  12.5%us,  2.1%sy,  0.0%ni,  85.3%id,...
...
```

---

## Contribuciones por Estudiante

### Estudiante 1: Arquitectura, Entorno y Captura de Interrupciones - Aaron (Líder Técnico)
- Parte 1: Preparación del entorno (Taller1, monitoreo.sh, permisos).
- Parte 3 (Punto 1 y 2): Estructura inicial del script (Shebang #!/bin/bash, comentarios del curso/integrantes).
- Parte 3 (Punto 9): Implementación de la captura de interrupciones con trap para registrar eventos en el log si el script se corta inesperadamente.
- Integración: Recibir los módulos de los compañeros y ensamblarlos en el script final.

### Estudiante 2: Monitoreo Base y Alertas de Sistema - Nicole
- Parte 3 (Punto 3): Implementar la recolección de datos usando top, free y df con sus respectivas marcas de tiempo (revisar el uso de awk según el enlace provisto).
- Parte 3 (Punto 4): Crear el condicional de alerta si el uso de la memoria RAM supera el 70%.
- Variables: Definir las rutas y variables necesarias para el funcionamiento de sus comandos.

### Estudiante 3: Menú Interactivo (case) y Automatización en Bucle - Celestita
- Parte 3 (Punto 12): Desarrollar la interfaz del menú utilizando la estructura condicional case (Opciones: 1. Ver CPU, 2. Procesos activos, 3. Salir).
- Parte 3 (Punto 12.1): Manejo de errores/opciones incorrectas en el menú.
- Parte 3 (Punto 6): Implementar el bucle for o while para que el monitoreo se repita cada 60 segundos durante 5 iteraciones.

### Estudiante 4: Diagnóstico de Procesos y Gestión de Respaldos - Elian
- Parte 3 (Punto 5): Programar la función verificar_proceso() que reciba un argumento (nombre de proceso) y valide si está activo en el sistema.
- Parte 3 (Punto 10 y 11): Crear la lógica que verifica si los logs anteriores superan los 10 MB y, de ser así, realizar el respaldo comprimido con tar -czf.

### Estudiante 5: Redirección Avanzada, Logs y Automatización Cron - Monse
- Parte 2: Configuración correcta de todas las Variables Globales (LOG_DIR, LOG_FILE, etc.).
- Parte 3 (Punto 7): Configurar la redirección de la salida estándar (stdout) y de error (stderr) a archivos separados. Crear el descriptor adicional (exec 3> debug.log) para depuración.
- Parte 3 (Punto 6.2): Generar el archivo final resumen.txt.
- Parte 3 (Punto 8): Configurar la tarea programada en cron para que el script se ejecute automáticamente cada hora.

### Estudiante 6: Control de Calidad, Evidencias y Documentación - Camilo
- QA (Quality Assurance): Probar el script final en su entorno para asegurar que no tenga bugs y que cumpla con los criterios de "Optimización" de la rúbrica.
- Evidencias: Tomar las capturas de pantalla requeridas (ejecución del script, logs generados, tarea en cron).
- Informe Final (PDF): Redactar y dar formato profesional al documento con la portada, objetivos, descripción, conclusiones, aprendizajes y el código limpio y comentado de todo el grupo.

---

## Referencia de Comandos Útiles

```bash
# Hacer ejecutable el script
chmod +x monitoreo.sh

# Ejecutar el script
bash monitoreo.sh

# Ejecutar con variables personalizadas
LOG_DIR=/ruta/logs THRESHOLD_MEM=80 bash monitoreo.sh

# Ver últimos logs
tail -n 100 logs/monitoreo_$(date +%Y-%m-%d).log

# Ver log en tiempo real
tail -f logs/monitoreo_$(date +%Y-%m-%d).log

# Programar en cron (cada hora)
0 * * * * /ruta/completa/al/script/monitoreo.sh >> /dev/null 2>&1
```
