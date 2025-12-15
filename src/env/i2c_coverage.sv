`ifndef I2C_COVERAGE_SV
`define I2C_COVERAGE_SV

class i2c_coverage extends uvm_subscriber #(i2c_transaction);
  `uvm_component_utils(i2c_coverage)

  i2c_config cfg;

  // ---------------------------------------------------------------------------
  // Covergroup: Protocol Transactions
  // ---------------------------------------------------------------------------
  covergroup i2c_protocol_cg;
    option.per_instance = 1;

    // Address Coverage
    cp_addr_mode: coverpoint i2c_addr_mode_e'(0) { // Placeholder, need transaction field
      // We need to capture the mode from the transaction or config
      // Ideally, the transaction should carry the mode used.
      // Assuming tr.addr_mode exists based on previous file reads.
      option.weight = 0; // Derived from addr
    }
    
    cp_addr_7bit: coverpoint req.addr {
       bins zero        = {0};
       bins gen_call    = {0}; // General Call
       bins low_range   = {[1:15]};
       bins mid_range   = {[16:111]};
       bins high_range  = {[112:126]};
       bins max_val     = {127};
       // specialized 10-bit prefix reserved logic could be added here
    }

    // Direction Coverage
    cp_direction: coverpoint req.direction {
       bins write = {I2C_WRITE};
       bins read  = {I2C_READ};
    }

    // Transaction Status (ACK/NACK)
    cp_status: coverpoint req.status {
       bins ok        = {I2C_STATUS_OK};
       bins addr_nack = {I2C_STATUS_ADDR_NACK};
       bins data_nack = {I2C_STATUS_DATA_NACK};
    }

    // Data Payload Size
    cp_data_size: coverpoint req.data.size() {
       bins single_byte = {1};
       bins small_burst = {[2:8]};
       bins large_burst = {[9:128]};
    }

    // Repeated Start
    cp_repeated_start: coverpoint req.repeated_start {
       bins stop_end = {0};
       bins rep_start = {1};
    }

    // Cross Coverage
    cross_dir_status: cross cp_direction, cp_status;
    cross_dir_size:   cross cp_direction, cp_data_size;
    cross_rep_start:  cross cp_direction, cp_repeated_start;

  endgroup

  // ---------------------------------------------------------------------------
  // Covergroup: Configuration / Speed
  // ---------------------------------------------------------------------------
  covergroup i2c_config_cg;
     option.per_instance = 1;
     
     cp_speed: coverpoint cfg.speed {
        bins standard = {I2C_STANDARD_MODE};
        bins fast     = {I2C_FAST_MODE};
        bins fast_plus = {I2C_FAST_MODE_PLUS};
     }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    i2c_protocol_cg = new();
    i2c_config_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(i2c_config)::get(this, "", "cfg", cfg)) begin
       `uvm_info("COV", "Config not found, creating default", UVM_LOW)
       cfg = i2c_config::type_id::create("cfg");
    end
  endfunction

  // Sample function called via Analysis Port
  function void write(i2c_transaction t);
    // Needed to access protected member 'req' in coverpoints, 
    // or just use 't' if we rename the arg or assign to a class member.
    // UVM subscriber uses 't' as argument, but our covergroup uses 'req'.
    // Let's copy t to a class member 'req' for the CG to see it.
    this.req = t; 
    
    i2c_protocol_cg.sample();
    i2c_config_cg.sample();
  endfunction

  // Member to hold current transaction for covergroup visibility
  protected i2c_transaction req;

endclass

`endif // I2C_COVERAGE_SV

