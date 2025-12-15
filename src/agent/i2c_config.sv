`ifndef I2C_CONFIG_SV
`define I2C_CONFIG_SV

class i2c_config extends uvm_object;
  
  // Active means driving the bus (Master or Slave driver enabled)
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  // Role configuration
  bit is_master = 1; // 1 = Master, 0 = Slave
  
  // Speed configuration
  i2c_speed_e speed = I2C_STANDARD_MODE;

  // Timing Parameters (in timescale units, e.g., ns)
  // These should be set based on the speed mode
  int t_low_ns;
  int t_high_ns;
  int t_buf_ns; // Bus free time between Stop and Start
  
  `uvm_object_utils_begin(i2c_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_int(is_master, UVM_ALL_ON)
    `uvm_field_enum(i2c_speed_e, speed, UVM_ALL_ON)
    `uvm_field_int(t_low_ns, UVM_ALL_ON)
    `uvm_field_int(t_high_ns, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "i2c_config");
    super.new(name);
  endfunction

  // Helper to set default timings based on speed
  function void set_default_timings();
    case (speed)
      I2C_STANDARD_MODE: begin // 100 kHz
        t_low_ns  = 4700; // 4.7 us
        t_high_ns = 4000; // 4.0 us
        t_buf_ns  = 4700;
      end
      I2C_FAST_MODE: begin // 400 kHz
        t_low_ns  = 1300; // 1.3 us
        t_high_ns = 600;  // 0.6 us
        t_buf_ns  = 1300;
      end
      I2C_FAST_MODE_PLUS: begin // 1 MHz
        t_low_ns  = 500; // 0.5 us
        t_high_ns = 260; // 0.26 us
        t_buf_ns  = 500;
      end
    endcase
  endfunction

endclass

`endif // I2C_CONFIG_SV

