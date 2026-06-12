#!/bin/bash

# ============================================================================
# CURSO: CY401 - Taller Práctico 1 - Sistemas Operativos Avanzados
# GRUPO: 1
# PROYECTO: Sistema de Monitoreo y Automatización del Sistema
# ============================================================================
#
# DESCRIPCIÓN:
# Script de monitoreo del sistema que recolecta métricas (CPU, memoria, disco)
# con marcas de tiempo, genera alertas si se superan umbrales, captura
# interrupciones (SIGINT) y mantiene un registro en archivos de log.
#
# ESTUDIANTES Y SUS CONTRIBUCIONES:
# - Estudiante 1 (Aaron): Arquitectura, entorno, captura de interrupciones
# - Estudiante 2 (Nicole): Monitoreo base y alertas de sistema
# - Estudiante 3 (Celestita): Menú interactivo y automatización en bucle
# - Estudiante 4 (Elian): Funcion  'verificar_proceso()' y respaldo de Logs, se modifica el menu para agregar la opcion de monitoreo
# ============================================================================




# ---------------------- Variables globales (configurables) ----------------------
# Variables para configuración del usuario y ubicación de logs (Estudiante 2 - Nicole)
usuario_guar="$(whoami)"
log_guar="${usuario_guar}_tailer1"

# Configuración base de logs con timestamp en el nombre del archivo
LOG_DIR="./logs"
BACKUP_DIR="./backups"
MAX_LOG_SIZE=$((10 * 1024 * 1024)) # 10 MB en bytes
# El nombre del archivo se configura dinámicamente con la fecha actual
LOG_FILE_PREFIX="monitoreo"
TIMESTAMP_FMT="%Y-%m-%d %H:%M:%S"

ERROR_LOG=""
ALERT_LOG=""
SYSTEM_LOG=""

# Umbral de memoria para generar alertas (Estudiante 2 - Nicole)
THRESHOLD_MEM=70  # Umbral en porcentaje (por defecto 70%)

# Variables para el bucle de iteraciones (Estudiante 3 - Celestita)
ITERATIONS=5                # Número de iteraciones de monitoreo
SLEEP_INTERVAL=60          # 60 segundos entre iteraciones

# ---------------------- Funciones auxiliares ----------------------

# Manejador de interrupciones (SIGINT) - Estudiante 1 (Aaron)
# Captura interrupciones del usuario (Ctrl+C) y registra el evento en el log
manejar_interrupcion() {
  local ts
  ts="$(timestamp)"
  {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Script interrumpido por el usuario"
    echo "Usuario: ${usuario_guar}"
    echo "Razón: Señal SIGINT recibida"
    echo ""
  } >> "$LOG_FILE" 2>&1
  exit 130
}

# Configurar trap para capturar SIGINT (Estudiante 1 - Aaron)
trap 'manejar_interrupcion' SIGINT

# Crear directorio de logs si no existe
crear_directorio_logs() {
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
  fi

  if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
  fi
}

# Obtener marca de tiempo en formato configurable
timestamp() {
  date "+${TIMESTAMP_FMT}"
}

# Recolectar métricas del sistema (Estudiante 2 - Nicole)
# Captura datos de CPU, memoria y disco con marca de tiempo
recolectar_metricas() {
  local ts
  ts="$(timestamp)"
  {
    echo "===== Registro: ${ts} ====="
    echo "--- top (resumen de CPU/mem) ---"
    top -b -n 1 | head -n 20
    echo "--- free (memoria) ---"
    free -h
    echo "--- df (uso de disco) ---"
    df -h
    echo "\n"
  } >> "$LOG_FILE" 2>&1
}

# Calcular porcentaje de memoria usada (Estudiante 2 - Nicole)
# Utiliza /proc/meminfo para cálculos más precisos en Linux
porcentaje_memoria_usada() {
  if [ -r /proc/meminfo ]; then
    local mem_total mem_available used_percent
    mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    if [ -z "$mem_total" ] || [ -z "$mem_available" ]; then
      echo "0"
      return
    fi
    used_percent=$(( ( (mem_total - mem_available) * 100 ) / mem_total ))
    echo "$used_percent"
  else
    local used total
    read used total <<< $(free -m | awk '/Mem:/ {print $3" "$2}')
    if [ -z "$used" ] || [ -z "$total" ] || [ "$total" -eq 0 ]; then
      echo "0"
      return
    fi
    echo $(( (used * 100) / total ))
  fi
}

# Verificar y generar alerta si la memoria excede el umbral (Estudiante 2 - Nicole)
# Retorna 0 si está dentro del umbral, 1 si se dispara la alerta
comprobar_alerta_memoria() {
  local used
  used=$(porcentaje_memoria_usada)
  if [ "$used" -ge "$THRESHOLD_MEM" ]; then
    local ts
    ts="$(timestamp)"
    registrar_alerta "Memoria usada: ${used}% (umbral: ${THRESHOLD_MEM}%)"

echo "[ALERTA] ${ts} - Memoria usada: ${used}% (umbral: ${THRESHOLD_MEM}%)" >> "$LOG_FILE"
    return 1
  fi
  return 0
}

# Verificar si un proceso está activo (Estudiante 4 - Elian)
# Recibe como parámetro el nombre de un proceso y comprueba si está en ejecución
verificar_proceso() {
  local proceso="$1"
  local ts
  ts="$(timestamp)"

  if [ -z "$proceso" ]; then
    echo "[ERROR] ${ts} - No se indicó ningún proceso para verificar." >> "$LOG_FILE"
    return 1
  fi

  if pgrep -x "$proceso" > /dev/null 2>&1; then
    echo "[OK] ${ts} - El proceso '${proceso}' está activo." >> "$LOG_FILE"
    echo "El proceso '${proceso}' está activo."
    return 0
  else
    echo "[INFO] ${ts} - El proceso '${proceso}' NO está activo." >> "$LOG_FILE"
    echo "El proceso '${proceso}' NO está activo."
    return 1
  fi
}

# Verificar logs anteriores y respaldarlos si superan los 10 MB (Estudiante 4 - Elian)
verificar_tamano_logs() {
  local ts
  ts="$(timestamp)"

  echo "[INFO] ${ts} - Verificando tamaño de logs anteriores." >> "$LOG_FILE"

  for archivo in "$LOG_DIR"/*.log; do
    [ -e "$archivo" ] || continue

    # Evita comprimir el log actual
    if [ "$archivo" != "$LOG_FILE" ]; then
      local tamano
      tamano=$(stat -c%s "$archivo")

      if [ "$tamano" -gt "$MAX_LOG_SIZE" ]; then
        local nombre_archivo
        local respaldo

        nombre_archivo=$(basename "$archivo")
        respaldo="$BACKUP_DIR/respaldo_${nombre_archivo}_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"

        tar -czf "$respaldo" -C "$LOG_DIR" "$nombre_archivo"

        if [ $? -eq 0 ]; then
          echo "[OK] $(timestamp) - Respaldo creado correctamente: $respaldo" >> "$LOG_FILE"
          rm "$archivo"
          echo "[OK] $(timestamp) - Log anterior eliminado después del respaldo: $archivo" >> "$LOG_FILE"
        else
          echo "[ERROR] $(timestamp) - No se pudo crear respaldo para: $archivo" >> "$LOG_FILE"
        fi
      else
        echo "[INFO] $(timestamp) - El log $archivo no supera los 10 MB." >> "$LOG_FILE"
      fi
    fi
  done
}

prueba_redireccion() {

    registrar_log "INFO" "Iniciando prueba de redirección avanzada"

    # Salida estándar a SYSTEM_LOG
    echo "Prueba de salida estándar" >> "$SYSTEM_LOG"

    # Error estándar a ERROR_LOG
    ls /ruta_inexistente 2>> "$ERROR_LOG"

    # Salida y errores separados
    df -h >> "$SYSTEM_LOG" 2>> "$ERROR_LOG"

    # Salida y errores juntos
    top -bn1 &>> "$SYSTEM_LOG"

    registrar_log "INFO" "Prueba de redirección avanzada finalizada"

}

# ---------------------- Flujo principal ----------------------
# Crear directorio de logs primero
crear_directorio_logs

# Configurar el nombre del archivo de log con la fecha actual (ANTES del menú)
LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}_$(date +%Y-%m-%d).log"

ERROR_LOG="${LOG_DIR}/errores_$(date +%Y-%m-%d).log"
ALERT_LOG="${LOG_DIR}/alertas_$(date +%Y-%m-%d).log"
SYSTEM_LOG="${LOG_DIR}/sistema_$(date +%Y-%m-%d).log"

# Verificar tamaño de logs anteriores antes de iniciar el monitoreo
verificar_tamano_logs

# Crear descriptor de archivo para debug log (Estudiante 5 - Monse)
DEBUG_LOG="${LOG_DIR}/debug_$(date +%Y-%m-%d).log"
exec 3> "$DEBUG_LOG"

# Función para generar resumen de ejecución (Estudiante 5 - Monse)
generar_resumen() {
    local RESUMEN="${LOG_DIR}/resumen.txt"
    local ALERTAS=0
    local ERRORES=0

    [ -f "$ALERT_LOG" ] && ALERTAS=$(grep -c "\[ALERTA\]" "$ALERT_LOG" 2>/dev/null || echo 0)
    [ -f "$ERROR_LOG" ] && ERRORES=$(grep -c "\[ERROR\]" "$ERROR_LOG" 2>/dev/null || echo 0)

    {
        echo "================================================="
        echo "RESUMEN DE EJECUCIÓN DEL MONITOREO"
        echo "================================================="
        echo ""
        echo "Fecha de generación: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Usuario: $(whoami)"
        echo "Directorio de logs: $LOG_DIR"
        echo ""
        echo "Iteraciones configuradas: $ITERATIONS"
        echo "Intervalo entre iteraciones: $SLEEP_INTERVAL segundos"
        echo "Umbral de memoria para alertas: ${THRESHOLD_MEM}%"
        echo ""
        echo "Cantidad de alertas generadas: $ALERTAS"
        echo "Cantidad de errores registrados: $ERRORES"
        echo ""
        echo "Archivos generados:"
        echo "  - $LOG_FILE"
        echo "  - $ERROR_LOG"
        echo "  - $ALERT_LOG"
        echo "  - $SYSTEM_LOG"
        echo "================================================="
    } > "$RESUMEN"

    echo "Resumen generado: $RESUMEN"
}

# Bucle principal: mostrar menú, ejecutar monitoreo, y volver al menú
while true; do

#Administracion de logs 

registrar_log() {
    local nivel="$1"
    local mensaje="$2"

    echo "[$nivel] $(timestamp) - $mensaje" >> "$SYSTEM_LOG"
}

registrar_error() {
    local mensaje="$1"

    echo "[ERROR] $(timestamp) - $mensaje" >> "$ERROR_LOG"
    echo "[ERROR] $(timestamp) - $mensaje" >> "$SYSTEM_LOG"
}

registrar_alerta() {
    local mensaje="$1"

    echo "[ALERTA] $(timestamp) - $mensaje" >> "$ALERT_LOG"
    echo "[ALERTA] $(timestamp) - $mensaje" >> "$SYSTEM_LOG"
}

prueba_redireccion() {

    registrar_log "INFO" "Iniciando prueba de redirección"

    # Salida estándar
    ls "$HOME" >> "$SYSTEM_LOG"

    # Error estándar
    ls /ruta_inexistente 2>> "$ERROR_LOG"

    # Salida y errores separados
    df -h >> "$SYSTEM_LOG" 2>> "$ERROR_LOG"

    # Salida y errores juntos
    top -bn1 &>> "$SYSTEM_LOG"

    registrar_log "INFO" "Prueba de redirección finalizada"
}

mostrar_configuracion_cron() {

    echo ""
    echo "========= CONFIGURACIÓN CRON ========="
    echo ""
    echo "1. Abrir cron:"
    echo "   crontab -e"
    echo ""
    echo "2. Ejecutar cada 5 minutos:"
    echo "   */5 * * * * $(pwd)/monitoreo.sh"
    echo ""
    echo "3. Ver tareas programadas:"
    echo "   crontab -l"
    echo ""
}

generar_reporte() {

    local REPORTE
    local ALERTAS=0
    local ERRORES=0

    REPORTE="${LOG_DIR}/reporte_final_$(date +%Y-%m-%d_%H-%M-%S).txt"

    [ -f "$ALERT_LOG" ] && ALERTAS=$(grep -c "\[ALERTA\]" "$ALERT_LOG")
    [ -f "$ERROR_LOG" ] && ERRORES=$(grep -c "\[ERROR\]" "$ERROR_LOG")

    {
        echo "================================================="
        echo " REPORTE FINAL DEL SISTEMA"
        echo "================================================="
        echo ""
        echo "Fecha: $(date)"
        echo "Usuario: $(whoami)"
        echo ""

        echo "-------------------------------------------------"
        echo " ESTADÍSTICAS DE EJECUCIÓN"
        echo "-------------------------------------------------"
        echo "Iteraciones ejecutadas: $ITERATIONS"
        echo "Intervalo: $SLEEP_INTERVAL segundos"
        echo ""

        echo "-------------------------------------------------"
        echo " CPU"
        echo "-------------------------------------------------"
        top -bn1 | head -10
        echo ""

        echo "-------------------------------------------------"
        echo " MEMORIA"
        echo "-------------------------------------------------"
        free -h
        echo ""

        echo "-------------------------------------------------"
        echo " DISCO"
        echo "-------------------------------------------------"
        df -h
        echo ""

        echo "-------------------------------------------------"
        echo " ALERTAS"
        echo "-------------------------------------------------"

        if [ -f "$ALERT_LOG" ]; then
            cat "$ALERT_LOG"
        else
            echo "No se registraron alertas."
        fi

        echo ""

        echo "-------------------------------------------------"
        echo " ERRORES"
        echo "-------------------------------------------------"

        if [ -f "$ERROR_LOG" ]; then
            cat "$ERROR_LOG"
        else
            echo "No se registraron errores."
        fi

        echo ""

        echo "-------------------------------------------------"
        echo " RESUMEN"
        echo "-------------------------------------------------"
        echo "Cantidad de alertas: $ALERTAS"
        echo "Cantidad de errores: $ERRORES"
        echo ""

        echo "================================================="
        echo " FIN DEL REPORTE"
        echo "================================================="

    } > "$REPORTE"

    registrar_log "INFO" "Reporte final generado: $REPORTE"

    echo ""
    echo "Reporte generado correctamente:"
    echo "$REPORTE"
    echo ""
}

# ---------------------- Menú interactivo ----------------------
mostrar_menu() {
  while true; do
    echo ""
    echo "========== MENÚ =========="
    echo "1. Ver CPU"
    echo "2. Ver procesos activos"
    echo "3. Iniciar monitoreo"
    echo "4. Ver configuración Cron"
    echo "5. Salir"
    echo "=========================="
    echo ""

    read -p "Seleccione una opción: " opcion

    case $opcion in
      1)
        echo ""
        echo "[*] Información de CPU:"
        echo "---"
        top -bn1 | grep "Cpu(s)"
        echo ""
        ;;
      2)
        echo ""
        echo "[*] Top 10 procesos por uso de CPU:"
        echo "---"
        ps aux --sort=-%cpu | head -11
        echo ""
        read -p "Digite el nombre del proceso que desea verificar: " proceso_buscar
        verificar_proceso "$proceso_buscar"
        echo ""
        ;;
      3)
        echo ""
        echo "[*] Iniciando monitoreo del sistema..."
        echo ""
        break
        ;;
        4)
    mostrar_configuracion_cron
    ;;
    5)
      echo ""
      generar_reporte
      generar_resumen
      echo "[*] Saliendo del script..."
      echo ""
      exit 0
      ;;
    *)
      echo "[ERROR] Opción inválida. Por favor, seleccione 1, 2, 3, 4 o 5."
      echo ""
      ;;
    esac
  done
}

# Mostrar menú inicial
mostrar_menu

# Mensaje inicial del monitoreo
{
  echo "============================================================"
  echo "Inicio de Monitoreo - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Usuario: ${usuario_guar}"
  echo "Log Guard: ${log_guar}"
  echo "============================================================"
  echo ""
} >> "$LOG_FILE" 2>&1

# Loop de iteraciones para monitoreo (Estudiante 3 - Celestita)
# Ejecuta el monitoreo durante 5 iteraciones con intervalo de 60 segundos
for ((i=1; i<=ITERATIONS; i++)); do
  {
    echo "--- Iteración $i de $ITERATIONS ---"
    echo ""
  } >> "$LOG_FILE" 2>&1
  
  # Recolectar métricas del sistema
  recolectar_metricas
  
  # Verificar alertas de memoria
  if ! comprobar_alerta_memoria; then
    # Se generó una alerta, pero continuamos con el monitoreo
    :
  fi
  
  # No dormir en la última iteración
  if [ $i -lt $ITERATIONS ]; then
    sleep "$SLEEP_INTERVAL"
  fi
done

# Mensaje final del monitoreo
{
  echo ""
  echo "============================================================"
  echo "Fin de Monitoreo - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "============================================================"
} >> "$LOG_FILE" 2>&1

# Cerrar el bucle principal (regresa al menú después de cada monitoreo)
done

# ---------------------- Instrucciones de uso (documentadas) ----------------------
# Comandos útiles:
#  - Crear directorio de logs (si es necesario): mkdir -p "$LOG_DIR"
#  - Hacer ejecutable el script: chmod +x monitoreo.sh
#  - Ejecutar el script: bash monitoreo.sh
#  - Ejecutar con variables personalizadas: LOG_DIR=/ruta/logs THRESHOLD_MEM=80 bash monitoreo.sh
#  - Ver últimos logs: tail -n 100 "$LOG_FILE"
#  - Ejemplo de cron para ejecutar cada hora:
#      0 * * * * /ruta/al/script/monitoreo.sh >> /dev/null 2>&1
#----------------------------------------------------------------------------------
