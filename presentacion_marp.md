---
marp: true
theme: default
paginate: true
backgroundColor: "#ffffff"
---

<!-- _class: lead -->

# Implementación de una ALU en ASIC

### Diseño físico de una ALU de 32 bits

Trabajo Final de Ingeniería Electrónica – FI · UNMdP  
Autora: **Victoria Otegui Alexenicer**  
Director: **Dr. Jorge Castiñeira** · Co-director: **Dr. Alejandro Uriz**  
Enero 2023 - Diciembre 2025

<table style="margin-left: auto; margin-right: 0; border: none;">
  <tr>
    <td align="center">
      <img src="unmdp_negro.png" width="320">
    </td>
    <td align="center">
      <img src="logo_fi_negro.png" width="150">
    </td>
  </tr>
</table>

---

## Motivaciones

- Popularizar el flujo industrial de diseño físico en la comunidad académica local.
- Generar bibliografía aplicada para estudiantes interesados en microelectrónica VLSI.
- Documentar experiencia profesional y completar la carrera de Ingeniería Electrónica.

---

## Objetivos y alcance

- Implementar todo el flujo de **Place & Route** (Colocación y Enrutamiento) de la ALU paralela de 32 bits.
- **Se dará por exitoso el proyecto si se logra un diseño implementable.**
- Tomar un bloque digital relativamente simple y recorrer las etapas principales que lo llevan desde una descripción de alto nivel en código hasta un layout físico que podría fabricarse en silicio.
- Trabajar con el **PDK educativo SAED14 nm FinFET (1P9M)** y librerías de celdas estándar.
- Entregar documentación reutilizable: scripts TCL, reportes y análisis QoR.

---

## ¿Qué es un ASIC?

<small>
<table width="100%">
  <tr>
    <td width="55%" valign="top">
      <ul>
        <li>Circuito integrado diseñado para una <strong>aplicación específica</strong>.</li>
        <li>Se optimiza para área, consumo y rendimiento siguiendo un PDK definido.</li>
        <li>Depende de un flujo EDA completo y librerías caracterizadas.</li>
        <li>Los dispositivos electrónicos actuales incluyen ASIC para las tareas más críticas de procesamiento.</li>
        <li>A diferencia de un diseño en FPGA, no es reconfigurable: exige un ciclo más largo y costos iniciales altos, pero entrega mejor desempeño, menor área y menor potencia.</li>
      </ul>
    </td>
    <td width="45%" align="center">
      <img src="wafer.png" width="270" />
      <img src="ASIC_chip.png" width="300" />
    </td>
  </tr>
</table>
</small>

---

## Transistor utilizado: FinFET

<table style="width:100%; border:none;">
  <tr>
    <td style="width:55%; vertical-align: top; font-size: 0.95em;">
      <ul>
        <li>El MOSFET plano pierde control electrostático y aumenta la fuga.</li>
        <li>SAED14 nm usa <strong>FinFET</strong> con compuerta envolvente (tres lados) para mejorar el control del canal.</li>
        <li>FinFET mejora el control electrostático y reduce la corriente que se escapa cuando el transistor debería estar apagado.</li>
        <li>Lógica digital más densa, mejor relación ON/OFF, menores fugas que las tecnologías planas anteriores.</li>
      </ul>
    </td>
    <td width="45%" align="center">
      <img src="FinFET_1.png" width="480" />
      <div style="font-size: 0.8em; color: #444; margin-top: 6px;">a. MOSFET plano · b. FinFET</div>
    </td>
  </tr>
</table>

---

## ALU de referencia

- Unidad aritmético-lógica (ALU) de 32 bits: ejecuta operaciones **XOR, AND, OR y suma** sobre dos operandos.
- Selector de reloj con divisores programables `f`, `f/2`, `f/4`, `f/8` y salidas registradas (`o_valid`, `o_data`).
- Frecuencia objetivo **100 MHz**, buses paralelos sincronizados y testbench dedicado para validar funcionalidad y divisores de reloj.
- Aunque es un bloque pequeño, incluye elementos típicos de un diseño real: lógica combinacional, registros y circuitería de reloj.

---

## Diagrama en bloques (RTL)

![width:65%](ALU_rtl_block.svg)

---

## ¿Qué es el diseño físico?

- Consiste en trasladar la "foto lógica" del diseño (RTL) a un plano físico implementable.
- Flujo **RTL → GDSII** cuyo resultado son bases de datos y archivos GDS exportables a las fundidoras, previamente verificados en reglas físicas, de temporización y de potencia.
- Se realiza utilizando y guiando herramientas EDA; depende de un nodo de tecnología y varias librerías y archivos de restricciones que caracterizan el diseño.
- Consiste en las etapas de Place and Route y Verificación Signoff.

---

## ¿Qué es el diseño físico? (visual)

<div style="text-align: center;">
  <img src="VLSI_flujo.png" style="width:85%; max-width:900px; display:inline-block;">
</div>

---

## Inputs del Flujo Place and Route

- **RTL / Netlist lógico**
  - Descripción en Verilog/VHDL (RTL) o netlist de celdas estándar.
  - Define funcionalidad y conectividad entre módulos y celdas.
- **Librerias y archivos de tecnologia**
  - `.lib` / `.db`: modelos de timing y potencia para distintos PVT corners.
  - `.lef`: vistas físicas (tamaño, pines, restricciones de colocación).
  - Archivos de tecnología: reglas de diseño, capas de metal, restricciones de ruteo.
  - Garantizan que el diseño sea realizable y verificable en la tecnología objetivo.

---

## Condiciones de operación y corners PVT

<div style="font-size:0.82em; line-height:1.1;">
<table width="100%" style="border-collapse:collapse;">
  <tr>
    <td width="60%" valign="top" style="padding-right:6px;">
      <ul style="margin-top:0;">
        <li>Estos corners permiten verificar que el diseño funcione correctamente no sólo en la condición ideal, sino también en situaciones ‘lentas’ y ‘rápidas’ del silicio, del voltaje y de la temperatura.</li>
        <li>Escenario = corner PVT + modo (funcional/scan) para cubrir MCMM.</li>
        <li>Esquinas definidas en <code>mcmm_setup.tcl</code>: setup_ss0p72v125c (SS, 0.72 V, 125 °C, C<sub>max</sub>) y hold_ff0p88v125c (FF, 0.88 V, 125 °C, C<sub>min</sub>).</li>
      </ul>
    </td>
    <td width="40%" align="center" valign="top" style="padding-left:6px;">
      <img src="pvt_corners.png" style="width:70%; max-width:360px; display:block; margin:0 auto;">
      <img src="gauss_pvt.svg" style="width:65%; max-width:340px; display:block; margin:8px auto 0;">
    </td>
  </tr>
</table>
</div>

---

## Floorplanning

<table width="100%">
  <tr>
    <td width="45%" valign="top" style="font-size: 0.75em; line-height: 1.2;">
      <ul>
        <li>Define el tamaño y la forma del core.</li>
        <li>Crea las filas de celdas estándar y las regiones.</li>
        <li>Reserva espacio para la red de alimentación.</li>
        <li>Fija la posición de los pines/puertos lógicos.</li>
        <li>Inserta las celdas físicas (well-taps, corner cells).</li>
        <li>Se diseña e implementa la red de alimentación.</li>
      </ul>
    </td>
    <td width="55%" valign="top" align="center">
      <img src="floorplan_1.png" style="width:105%; max-width:700px; display:block; margin:0 auto;">
    </td>
  </tr>
</table>

---

## Floorplan y malla de potencia

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.85em; line-height: 1.2;">
      <ul>
        <li><strong>Die:</strong> 50.024 × 49.800 µm; <em>core offset</em> 1.184 µm (H) / 1.200 µm (V).</li>
        <li><strong>Utilización inicial:</strong> 1.90 % con 106 pines periféricos.</li>
        <li><strong>Malla PG:</strong> 15 <em>straps</em> VDD/VSS en M9 y 80 <em>rails</em> locales en M1.</li>
        <li><strong>Celdas físicas:</strong> 81 <em>tap cells</em> y 450 <em>boundary cells</em> insertadas automáticamente.</li>
        <li>Intencionalmente holgado: utilización de área lógica baja. Espacio para ver ruteo, red de alimentación y celdas físicas, sin congestión.</li>
      </ul>
    </td>
    <td width="40%" valign="top" align="center">
      <div style="display:block; margin:0 auto; width:290px;">
        <img src="floorplan_impl_1.png" width="290" style="display:block; margin:0 auto;">
      </div>
      <div style="display:block; margin:12px auto 0; width:290px;">
        <img src="VDD_VSS_1.png" width="290" style="display:block; margin:0 auto;">
      </div>
    </td>
  </tr>
</table>

---

## Colocación (Placement)

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.75em; line-height: 1.15;">
      <ul>
        <li><strong>Objetivo:</strong> ubicar celdas minimizando cables y respetando timing.</li>
        <li>La herramienta realiza primero una colocación global aproximada y luego la va ajustando hasta legalizar todas las posiciones, respetando filas y evitando solapamientos.</li>
        <li><strong>Guías:</strong> regiones rígidas/blandas, exclusivas/no exclusivas.</li>
        <li><strong>Optimización:</strong> buffers/inversores en críticos.</li>
      </ul>
    </td>
    <td width="40%" valign="top" align="center">
      <img src="db_compile_placement.png" style="width:80%; max-width:340px; display:block; margin:0 auto;">
    </td>
  </tr>
</table>

---

## Colocación (QoR práctico)

- ~377 celdas estándar legalizadas (339 comb., 38 secuenciales).
- WNS/TNS ≈ 0 antes de CTS; clocks aún ideales y listos para propagarse.
- Utilización baja evita congestión; buffering/inversores insertados para caminos críticos.
- Checkpoints y reportes por paso permiten depurar congestión y timing tempranos.
- Diseño sale de placement listo para CTS con redes de reloj limpias y rutas viables.

---

## Síntesis de Árbol de Reloj

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.85em; line-height: 1.25;">
      <ul>
        <li><strong>Objetivo:</strong> llevar el reloj de forma pareja a distintas partes del diseño, sin problemas de sincronización.</li>
        <li><strong>Balanceo:</strong> controlar latencia del reloj y minimizar <em>skew</em> entre registros.</li>
        <li><strong>Optimización:</strong> en los árboles de distribución se pueden agregar buffers o inversores.</li>
        <li><strong>Reglas físicas:</strong> NDR (metal ancho/espaciado) y vías reforzadas para bajar RC/ruido.</li>
        <li>La red de reloj deja de ser ideal.</li>
      </ul>
    </td>
    <td width="35%" valign="top" align="center">
      <img src="clk_net.png" style="width:80%; max-width:340px; display:block; margin:0 auto;">
    </td>
  </tr>
</table>

---

## CTS (QoR práctico)

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.9em; line-height: 1.25;">
      <ul>
        <li><strong>Relojes propagados:</strong> CLOCK_MAIN más divisores /2, /4 y /8 sobre red con reglas NDR.</li>
        <li><strong>Recursos:</strong> ~19 buffers/inversores dedicados; longitud de red ≈ 207 µm en el reloj maestro.</li>
        <li><strong>Métricas:</strong> skew global < 70 ps e inserción < 0.18 ns en escenarios críticos.</li>
        <li>Diferencias de latencia entre los relojes derivados pequeñas y coherentes con el tamaño del bloque. Permite avanzar al ruteo con una base de reloj sólida.</li>
      </ul>
    </td>
    <td width="40%" valign="top" align="center">
      <img src="clock_routing.png" style="width:80%; max-width:360px; display:block; margin:0 auto;">
    </td>
  </tr>
</table>

---

## Enrutamiento

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.85em; line-height: 1.2;">
      <ul>
        <li><strong>Objetivo:</strong> trazar físicamente las conexiones de señal.</li>
        <li><strong>Enrutamiento global:</strong> dividir el bloque en celdas de ruteo. Planificar conexiones por zonas. Estimar congestión.</li>
        <li><strong>Enrutamiento detallado:</strong> asigna pistas y capas de metal específicas para cada señal respetando reglas de tecnología.</li>
      </ul>
    </td>
    <td width="40%" valign="top" align="center">
      <img src="global_routing_cell.png" style="width:85%; max-width:380px; display:block; margin:0 auto;">
    </td>
  </tr>
</table>

---

## Análisis de Temporización Estática (STA)

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.9em; line-height: 1.25;">
      <ul>
        <li><strong>WNS</strong> (worst negative slack): mide el peor incumplimiento de tiempo en cualquier camino.</li>
        <li><strong>TNS:</strong> total negative slack: suma todos los incumplimientos.</li>
        <li>Si WNS y TNS son cero: el diseño cumple la frecuencia objetivo en todos los caminos analizados, para corners de setup y hold.</li>
      </ul>
    </td>
    <td width="40%" valign="top" align="center">
      <div style="display:block; margin:0 auto; width:290px;">
        <img src="setup_time.png" width="290" style="width:290px !important; display:block; margin:0 auto;">
      </div>
      <div style="display:block; margin:14px auto 0; width:290px;">
        <img src="hold_time.png" width="290" style="width:290px !important; display:block; margin:0 auto;">
      </div>
    </td>
  </tr>
</table>

---

## Potencia

- Potencia dinámica o de conmutación, que aparece cuando las señales cambian de valor y depende de la actividad y de la frecuencia de reloj.
- Potencia de fuga, que existe aun cuando el circuito no está conmutando, y está muy ligada a la tecnología del transistor y a la temperatura.
- Se analizan distintos corners de funcionamiento. Algunos muestran mayor potencia de fuga, por ejemplo cuando la temperatura o el voltaje son altos, y otros muestran mayor potencia dinámica, vinculada a señales conmutando con más frecuencia.

---

## Enrutamiento (QoR práctico)

<table width="100%">
  <tr>
    <td width="60%" valign="top" style="font-size: 0.9em; line-height: 1.25;">
      <ul>
        <li><strong>DRC/DRV:</strong> sin violaciones reportadas; transiciones y capacitancias máximas quedaron en cero.</li>
        <li><strong>Timing:</strong> WNS = 0 y TNS = 0 en los corners <em>setup_ss0p72v125c</em> y <em>hold_ff0p88v125c</em> tras extracción parasítica.</li>
        <li><strong>Inventario post-route:</strong> ~377 celdas estándar, 121 buffers/inversores y 38 <em>flip-flops</em>; dominan celdas NVT.</li>
        <li>Poca congestión. No quedan violaciones de reglas físicas post reparación. Tamaño y distribución elegidas fueron adecuadas.</li>
      </ul>
    </td>
    <td width="35%" valign="top" align="center">
      <div style="display:block; margin:0 auto; width:280px;">
        <img src="ruteo_senal_clock.png" width="280" style="width:280px !important; display:block; margin:0 auto;">
      </div>
      <div style="display:block; margin:14px auto 0; width:280px;">
        <img src="dcap_fill_std_cells.png" width="280" style="width:280px !important; display:block; margin:0 auto;">
      </div>
    </td>
  </tr>
</table>

---

## Conclusiones y próximos pasos

<table width="100%">
  <tr>
    <td width="55%" valign="top">
      <ul>
        <li>Se implementó un <strong>flujo reproducible</strong> de diseño físico para una ALU de complejidad media.</li>
        <li>El proyecto entrega <strong>scripts, reportes y figuras</strong> listos para ser reutilizados por la FI-UNMdP.</li>
        <li>Permite incorporar prácticas de la industria (<strong>Synopsys FC</strong>, <strong>SAED14</strong>) a la formación académica.</li>
        <li>Futuros trabajos: ampliar escenarios <strong>MCMM</strong>, integrar bloques adicionales y estudiar <em>sign-off</em> <strong>SI/IR</strong>.</li>
      </ul>
    </td>
    <td width="45%" valign="top" align="center">
      <!-- Espacio para imagen de conclusiones si se desea -->
    </td>
  </tr>
</table>
