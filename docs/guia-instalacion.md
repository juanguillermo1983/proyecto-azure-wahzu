# Guía paso a paso — Instalación Wazuh y pruebas (Fases 2-4)

Cada paso indica el comando, qué hace, qué deberías ver, y si corresponde una captura (nombre exacto según `docs/evidencias/README.md`).
Fase 1 (conectividad) ya está resuelta: `01-conectividad-linux-a-windows.png` y `02-conectividad-windows-a-linux.jpeg`.

IPs del laboratorio: Linux 10.0.1.5 (pública `<IP_PUBLICA_LINUX>`) — Windows 10.0.1.4 (pública `<IP_PUBLICA_WINDOWS>`). Obtén las tuyas con `scripts/status.sh` después de desplegar (columna IPPublica); son estáticas mientras no destruyas el recurso.

## Antes de empezar: cómo buscar en el Dashboard (Threat Hunting) sin perder tiempo

Estos errores se repitieron varias veces durante las pruebas — revísalos primero para no volver a caer:

- **Barra de búsqueda (DQL, arriba) vs. chip de filtro (abajo) son cosas distintas.** Escribir una consulta en la barra "Search" no modifica un filtro que ya está aplicado como chip (ej. `rule.id: 60122`). Para cambiar un filtro existente, haz clic directamente sobre el chip → se abre "Edit filter".
- **Para combinar varios `rule.id` en un mismo filtro**, usa el operador **"is one of"** (no "is") y agrega los valores en el campo Value — es más confiable que escribir `rule.id: 60122 or rule.id: 60106` a mano en la barra DQL.
- **Los nombres de campo son sensibles a mayúsculas/minúsculas.** Ej.: el campo correcto es `data.win.eventdata.commandLine` (c minúscula, L mayúscula) — `CommandLine` no existe y da "No results" sin avisar del error.
- **Revisa el número completo antes de asumir que algo no existe.** Un dígito de menos o de más en un `rule.id` o `eventID` (ej. escribir `468` en vez de `4688`) también da "No results" silenciosamente.
- **Si no sabes bajo qué `rule.id` quedó clasificado un evento**, busca primero por el campo crudo de Windows sin filtrar por regla, ej. `data.win.system.eventID: 4624`, y mira en los resultados qué `rule.id` le tocó — Wazuh a veces usa una regla de correlación más específica en vez de la genérica que esperarías (ver 4.1).
- **Verifica el rango de fecha** (arriba a la derecha, "Last 24 hours") cubra el momento en que generaste el evento.

---

## Fase 2 — Wazuh All-in-One en la VM Linux

Conéctate primero:
```bash
ssh -i infra/.secrets/id_ed25519 socadmin@<IP_PUBLICA_LINUX>
```
Todo lo de esta fase se ejecuta **dentro de esa sesión SSH** (en la VM Linux), salvo que se indique lo contrario.

### 2.1 Actualizar el sistema
```bash
sudo apt update && sudo apt -y upgrade
```
Actualiza los paquetes del sistema antes de instalar Wazuh, como pide el enunciado ("Actualizar el sistema base"). Puede tardar unos minutos; si pide reiniciar servicios, aceptar por defecto.

### 2.2 Descargar e instalar Wazuh (Indexer + Server + Dashboard)
```bash
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
sudo bash wazuh-install.sh -a
```
Nota: la ruta `4.x` (genérica) no funciona — devuelve un XML de error, no el script. Hay que usar la versión exacta (`4.14`, la última estable verificada). Si en el futuro Wazuh publica una versión mayor, confirmar la ruta vigente en https://documentation.wazuh.com/current/quickstart.html antes de ejecutar.
`-a` = instalación "All-in-One": los tres componentes en un solo nodo. Descarga, instala y arranca Wazuh Indexer, Wazuh Server (manager) y Wazuh Dashboard. Tarda entre 10 y 20 minutos. Al final imprime la contraseña del usuario `admin` del Dashboard — **cópiala**, la necesitas para entrar. También queda guardada en el propio servidor:
```bash
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```

### 2.3 Verificar que los tres servicios están activos
```bash
sudo systemctl status wazuh-indexer wazuh-manager wazuh-dashboard --no-pager
```
Los tres deben decir `active (running)` en verde. Si alguno falla, no continuar a la fase 3 sin resolverlo.

### 2.4 Entrar al Dashboard
Desde el navegador de tu Mac (no dentro del SSH): `https://<IP_PUBLICA_LINUX>/`
El certificado es autofirmado, el navegador va a advertir — acepta el riesgo y continúa. Usuario `admin`, contraseña la del paso 2.2. Confirma que carga el panel principal de Wazuh.

*(No se pide captura aquí todavía; la captura del Dashboard va en el paso 3.3, ya con el agente Windows activo.)*

---

## Fase 3 — Agente Wazuh en la VM Windows

Conéctate por RDP a `<IP_PUBLICA_WINDOWS>` (usuario `socadmin`, contraseña en `infra/.secrets/windows_password.txt`). Todo lo de esta fase se hace **dentro de esa sesión RDP**.

### 3.1 Generar el comando de instalación desde el Dashboard
En el Dashboard (desde tu Mac o desde el navegador de la VM Windows): menú ☰ → **Agents management** → **Summary** → botón **Deploy new agent**.
- Server address: `10.0.1.5` (IP privada del servidor Linux).
- Operating system: **Windows**.
- Agent name: `vm-soc-windows` (o dejar el sugerido).
El asistente arma automáticamente el comando PowerShell correcto para la versión de Wazuh instalada (evita usar una URL de MSI vencida a mano).

### 3.2 Instalar y registrar el agente
En la VM Windows, abrir **PowerShell como Administrador** y pegar el comando que generó el asistente (descarga el MSI e instala con `WAZUH_MANAGER` y `WAZUH_REGISTRATION_SERVER` apuntando a `10.0.1.5`). Luego iniciar el servicio:
```powershell
NET START WazuhSvc
```
Verificar que quedó en ejecución:
```powershell
Get-Service WazuhSvc
```
Debe decir `Running`.

### 3.3 Verificar el agente en el Dashboard — Captura obligatoria
En el Dashboard (☰ → **Agents management**), buscar `vm-soc-windows`: debe figurar en estado **Active**, con su IP y versión visibles.

📸 **Captura `03-dashboard-agente-windows-active.png`** — pantalla del Dashboard mostrando el agente Active, con fecha/hora del sistema visible (o el reloj de Windows en la esquina si la captura es de la sesión RDP completa).

---

## Fase 4 — Pruebas de verificación (todo dentro de la VM Windows, salvo donde se indique)

### 4.1 Autenticación (UEBA) — Event ID 4624/4625 — Captura obligatoria

**Cómo generar los dos eventos sin cerrar tu sesión RDP activa** (si bloqueas/cierras la sesión desde la que estás conectado, corres el riesgo de quedar sin forma de reabrirla si algo falla). Alternativa más segura, dentro de la misma sesión RDP, en PowerShell (no necesita ser Administrador):
```powershell
runas /user:socadmin cmd
```
1. La primera vez, escribe una **contraseña incorrecta** a propósito y presiona Enter → falla el `runas` → genera Event ID **4625** (fallo de logon).
2. Repite el mismo comando (`runas /user:socadmin cmd`) y esta vez escribe la contraseña **correcta** (la de `infra/.secrets/windows_password.txt`) → se abre una consola nueva → genera Event ID **4624** (logon exitoso). Puedes cerrar esa consola nueva de inmediato.
   (Alternativa equivalente si prefieres probar el flujo real de RDP: bloquear con `Win+L` y volver a iniciar sesión, una vez con clave incorrecta y otra con la correcta.)

3. En el Dashboard: ☰ → **Threat Hunting** (o **Security events**) → filtrar por `vm-soc-windows`. El fallo aparece como `rule.id: 60122` ("Logon Failure"). El éxito, en un entorno con RDP, normalmente **no** aparece como el genérico `rule.id: 60106` sino como una regla de correlación más específica — en nuestras pruebas fue `rule.id: 92652` ("Successful Remote Logon Detected... NTLM authentication, possible pass-the-hash"), porque Wazuh prioriza la regla más específica que matchea el mismo evento 4624. Si no sabes cuál te va a tocar, busca primero por `data.win.system.eventID: 4624` sin filtro de regla y lee el `rule.id` real en los resultados (ver notas al inicio de esta guía). Filtro final recomendado: chip `rule.id` con operador **"is one of"** y valores `60122, 92652` (ajustar el segundo número según lo que arroje tu propia búsqueda).

📸 **Captura `04-eventos-autenticacion-4624-4625.png`** — panel de eventos del Dashboard mostrando ambos Event IDs (2 hits), con fecha y hostname visibles.

### 4.2 Integridad de archivos (FIM) — Captura obligatoria
En la VM Windows, abrir el archivo de configuración del agente. **Ojo:** ese archivo está en `Program Files` y requiere permisos de Administrador para guardarse — si lo abres con doble clic o desde un Bloc de notas normal, vas a poder editarlo pero no guardarlo (falla silenciosamente o pide "Guardar como"). Ábrelo desde una consola **con privilegios elevados**:
```powershell
notepad "C:\Program Files (x86)\ossec-agent\ossec.conf"
```
(ejecuta esto desde un PowerShell o CMD abierto como "Ejecutar como administrador" — clic derecho sobre el ícono → esa opción). Así el Bloc de notas hereda el privilegio y sí puede guardar.

Dentro del bloque `<syscheck>...</syscheck>`, agregar:
```xml
<directories check_all="yes" realtime="yes" report_changes="yes">C:\PII_Data</directories>
```
Guardar y reiniciar el servicio para que tome la nueva configuración:
```powershell
Restart-Service WazuhSvc
```
Crear la carpeta y el archivo simulado (en PowerShell):
```powershell
New-Item -ItemType Directory -Path C:\PII_Data
"rut,nombre`n11111111-1,Cliente Prueba" | Out-File C:\PII_Data\clientes_rut.csv
```
Esperar unos segundos (el monitoreo es en tiempo real) y luego **modificar** el archivo para disparar la alerta:
```powershell
Add-Content C:\PII_Data\clientes_rut.csv "22222222-2,Cliente Dos"
```
En el Dashboard: ☰ → **Integrity monitoring** (o buscar `rule.id: 550` o `554` en Threat Hunting), filtrar por `vm-soc-windows`.

📸 **Captura `05-alerta-fim.png`** — alerta FIM del Dashboard mostrando el archivo `C:\PII_Data\clientes_rut.csv` modificado, con fecha y hostname visibles.

### 4.3 Ejecución administrativa (Living off the Land / MITRE T1059)
En PowerShell (como Administrador) de la VM Windows, **en este orden**:

**Paso 1 — Habilitar auditoría de línea de comandos (una sola vez):**
```powershell
auditpol /set /subcategory:"Process Creation" /success:enable
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f
```
Le dice a Windows que, al crear un proceso (Event ID 4688), registre también el comando completo con el que se lanzó. Si se ejecuta después de los comandos del paso 2, Wazuh solo verá que se abrió `certutil.exe`, sin sus argumentos — la captura pierde el detalle que se busca mostrar.

**Paso 2 — Recién ahora, ejecutar los comandos "sospechosos":**
```powershell
Get-Process
certutil.exe -hashfile C:\Windows\System32\drivers\etc\hosts MD5
```
`Get-Process` es reconocimiento inofensivo. `certutil.exe` es el comando relevante para MITRE T1059/T1105: un binario legítimo de Windows (LOLBin) reutilizado para una tarea ajena a su propósito (aquí, calcular un hash; en un ataque real, también para descargar/decodificar payloads).

**Paso 3 — Verificar en el Dashboard:** Threat Hunting → filtrar por `vm-soc-windows` y `data.win.system.eventID: 4688` (aparecerá como `rule.id: 67027`, "A process was created" — es normal, hay uno por cada proceso creado en el sistema). Para aislar el de `certutil`, agrega: `data.win.eventdata.commandLine: *certutil*` (ojo: el campo es `commandLine`, con "c" minúscula y "L" mayúscula — `CommandLine` con mayúscula inicial no existe y no da resultados). Expande el documento (ícono 🔍) y confirma que `data.win.eventdata.commandLine` muestra el comando completo con sus argumentos, no solo el nombre del ejecutable.
No es una de las 4 capturas obligatorias del enunciado, pero conviene guardar una captura adicional como evidencia de soporte (opcional): `08-ejecucion-powershell-certutil.png`.

---

## Checklist final de evidencias (`docs/evidencias/`)
- [x] `01-conectividad-linux-a-windows.png`
- [x] `02-conectividad-windows-a-linux.jpeg`
- [x] `03-dashboard-agente-windows-active.png`
- [x] `04-eventos-autenticacion-4624-4625.png`
- [x] `05-alerta-fim.png`
- [x] (opcional) `06.1-vnet-topologia.png`, `06.2-vnet-subredes.png` — arquitectura de red, portal Azure
- [x] (opcional) `07-nsg-reglas.png` — reglas del NSG, portal Azure
- [x] (opcional) `08-ejecucion-powershell-certutil.png` — soporte T1059
