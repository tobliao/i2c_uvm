`ifndef I2C_TYPES_SV
`define I2C_TYPES_SV

// Protocol Direction
typedef enum bit {
  I2C_WRITE = 0,
  I2C_READ  = 1
} i2c_direction_e;

// Bus Speed Modes
typedef enum bit [1:0] {
  I2C_STANDARD_MODE  = 0, // 100 kbit/s
  I2C_FAST_MODE      = 1, // 400 kbit/s
  I2C_FAST_MODE_PLUS = 2  // 1 Mbit/s
} i2c_speed_e;

// Addressing Mode
typedef enum bit {
  I2C_ADDR_7BIT  = 0,
  I2C_ADDR_10BIT = 1
} i2c_addr_mode_e;

// Transaction Status
typedef enum bit [2:0] {
  I2C_STATUS_OK        = 0,
  I2C_STATUS_ADDR_NACK = 1,
  I2C_STATUS_DATA_NACK = 2,
  I2C_STATUS_TIMEOUT   = 3,
  I2C_STATUS_ARB_LOST  = 4, // Placeholder for future
  I2C_STATUS_ERROR     = 5
} i2c_status_e;

`endif // I2C_TYPES_SV

