# I2C UVM Verification Project

This project contains a comprehensive UVM Verification IP (VIP) for the I2C protocol and a reference behavioral RTL design. It is configured for Synopsys VCS.

## Directory Structure
```
i2c_uvm/
├── docs/                 # Testplan and Specifications
├── rtl/                  # Behavioral RTL Models (Master & Slave)
├── sim/                  # Simulation scripts (Makefile)
├── src/                  # UVM Source Code
│   ├── common/           # Shared types and enums
│   ├── agent/            # I2C Agent (Driver, Monitor, Sequencer)
│   ├── env/              # UVM Environment and Scoreboard
│   ├── seq/              # Sequence Library
│   ├── tests/            # Test Library (Flat structure)
│   ├── i2c_pkg.sv        # Main Package
│   └── i2c_if.sv         # Interface
```

## Prerequisites
*   Synopsys VCS (with UVM 1.2 support)
*   Verdi (for waveform viewing, optional)

## How to Run

1.  **Navigate to the simulation directory:**
    ```bash
    cd sim
    ```

2.  **Run the Comprehensive Sanity Test (Recommended):**
    ```bash
    make run
    ```
    *   **Test Name:** `i2c_sanity_test`
    *   **Description:** This single test validates both operational modes of the VIP in sequence:
        1.  **Phase 1 (Master Mode):** VIP acts as Master, writing data to the RTL Slave.
        2.  **Phase 2 (Slave Mode):** VIP switches to Slave mode. The RTL Master (triggered at 2ms) drives traffic to the VIP.
    *   **Log:** `sim/run.log`

3.  **Run Dedicated Slave Test:**
    ```bash
    make run_slave
    ```
    *   **Test Name:** `i2c_slave_test`
    *   **Description:** Configures VIP strictly as a Slave to verify reception from an external Master.
    *   **Log:** `sim/run_slave.log`

4.  **View Waveforms:**
    ```bash
    verdi -ssf waves.fsdb
    ```

## Implemented Features
*   **Protocol Support:** I2C Standard Mode (100kHz), Fast Mode (400kHz).
*   **Dual-Role VIP:**
    *   **Master Mode:** Generates Start/Stop, Drives Address/Data, Handles ACK/NACK.
    *   **Slave Mode:** Detects Start, reacts to external Master requests.
*   **Verification Infrastructure:**
    *   **Driver:** Bit-banging implementation for precise timing control.
    *   **Monitor:** Protocol observation.
    *   **Coverage:** Functional coverage for protocol states and configuration.
    *   **Scoreboard:** Data integrity checks.
*   **RTL Models:**
    *   `i2c_slave.sv`: Behavioral Slave with memory.
    *   `i2c_master.sv`: Behavioral Master for test stimulus.

## Future Work (High Availability)
*   **Multi-Master Arbitration:** Logic for arbitration loss and back-off.
*   **10-bit Addressing:** Full support for extended addressing.
*   **High-Speed Mode:** Support for 3.4 MHz signaling.

## Submission Guidelines

When submitting this project, please ensure only the necessary source files and documentation are included. All generated files, logs, and simulation artifacts should be excluded.

**Required Files:**
*   `rtl/`: All RTL source files.
*   `src/`: All UVM source code (agent, env, sequences, tests).
*   `sim/`: `Makefile` only (no logs or binaries).
*   `docs/`: Testplan and documentation.
*   `README.md`: This file.

**Excluded Files (automatically handled by .gitignore):**
*   Compilation directories (`csrc`, `simv.daidir`)
*   Simulation executables (`simv`)
*   Log files (`*.log`)
*   Waveform dumps (`*.fsdb`)
*   Coverage databases (`coverage.vdb`)
*   Verdi configuration files
