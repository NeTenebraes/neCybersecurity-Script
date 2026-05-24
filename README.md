# 🧠 Script de Ciberseguridad | EXPERIMENTAL

El archivo **`Cybersecurity.sh`** complementa [mi entorno de trabajo](https://github.com/NeTenebraes/neBSPWM-dotfiles) preparando Arch Linux para un flujo orientado a **ciberseguridad, bug bounty y análisis de vulnerabilidades**. Su enfoque no es estético, sino funcional: **automatiza tareas técnicas que normalmente requerirían decenas de pasos manuales**.

## 🔍 ¿Qué diablos hace?

- **Integra herramientas de seguridad** dentro del entorno gráfico, respetando la estética del sistema *(íconos, menús en Rofi y accesos integrados en `~/.local/share/applications`)*.  
- **Instala y configura herramientas esenciales de hacking y análisis:**
  - **Burp Suite Community** → Proxy y escáner HTTP/S, con wrapper optimizado para Wayland/X11.
  - **Caido** → Proxy moderno y liviano, descargado dinámicamente desde GitHub e integrado directamente al menú de aplicaciones.
  - **Firejail** → Crea **navegadores aislados** con perfiles diferenciados:
    - *Navegador Personal*: aislamiento estándar, pensada para uso diario.  
    - *Navegador Bug Bounty*: entorno sandbox con red privada, DNS dedicados y caché independiente, ideal para investigación y pruebas sin contaminar tus perfiles personales.
- **Virtualización configurada automáticamente:**
  - Detecta el kernel actual *(Hardened, LTS o Zen)* e instala sus *headers* correspondientes.
  - Configura **VirtualBox** y **VMware Workstation** con módulos, red *Host-Only* funcional y soporte para entornos de laboratorio listos para pentesting.
- **Red y protección general automatizada:**
  - Activa **UFW** con reglas predefinidas *(Deny IN / Allow OUT)*.
  - Ofrece habilitar **SSH** de forma opcional.
  - Aplica resolutores **DNS seguros** (Cloudflare, Quad9 o Google) para toda la red del sistema.
- **Flujo de pentesting completamente automatizado:**  
  Al finalizar, todas las herramientas quedan:
  - Integradas visualmente en **Rofi**.  
  - Añadidas al **PATH del usuario**.  
  - Ejecutables sin `sudo` ni elevación de privilegios innecesaria.  

En resumen: Un script que convierte tu instalación limpia de Arch en un **laboratorio de ciberseguridad funcional, seguro y visualmente coherente** en menos de 2min.

## ROADMAP
Este script hace parte de un proyecto experimental de hardening y automatizacion de herramientas relacionadas a Ciberseguridad. Por el momento se tiene en mente las siguientes implementaciones:
1. Modificar el script para hacerlo modular. 
2. Desactivar el login por contraseña de SSH. 
3. Desactivar el uso del usuario root.
4. Instalar/configurar fail2ban.
5. Activar el uso de secureboot.
