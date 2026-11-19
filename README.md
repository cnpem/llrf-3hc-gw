# 3rd Harmonic Cavity (3HC) Low-Level Radio Frequency (LLRF) Gateware

Gateware for the Sirius' 3rd Harmonic Cavity (3HC) Low-Level Radio Frequency
(LLRF).

## Directory Structure

```
*
|
|-- hdl:
|    |   HDL (Verilog/VHDL) modules related to the Sirius' 3HC LLRF.
|    |
|    |-- ip_cores:
|    |        Third-party reusable modules.
|    |
|    |-- modules:
|    |        Application-specific modules.
|    |
|    |-- platform:
|    |     |   Platform-specific HDL and framework integration files.
|    |     |   Each supported platform should have its own subdirectory.
|    |     |
|    |     |-- sis8300ku:
|    |               SIS8300KU-specific ESSFFW configuration packages.
|    |
|    |-- sim:
|    |        Generic simulation files (e.g. reusable Bus Functional
|    |        Modules (BFMs), constants definitions)
|    |
|    |-- syn:
|    |        Synthesis-specific files (user constraints files and top design
|    |          specification).
|    |
|    |-- testbench:
|    |        Testbenches for modules and top level designs. May use modules
|    |          defined within the "sim" directory.
|    |
|    |-- top:
|             Synthesizable top-level design modules and framework wrappers.
```
