`ifndef I2C_TRANSACTION_SV
`define I2C_TRANSACTION_SV

class i2c_transaction extends uvm_sequence_item;

  // Randomizable Protocol Fields
  rand i2c_direction_e direction;
  rand bit [9:0]       addr;      // Supports up to 10-bit address
  rand i2c_addr_mode_e addr_mode;
  rand bit [7:0]       data[];    // Payload
  rand bit             repeated_start; // If true, generate Sr after this transaction instead of Stop

  // Response / Status Fields
  i2c_status_e         status;
  bit                  nack_received;

  // UVM Automation Macros
  `uvm_object_utils_begin(i2c_transaction)
    `uvm_field_enum(i2c_direction_e, direction, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_enum(i2c_addr_mode_e, addr_mode, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_int(repeated_start, UVM_ALL_ON)
    `uvm_field_enum(i2c_status_e, status, UVM_ALL_ON)
    `uvm_field_int(nack_received, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constraints
  
  // Reasonable burst size default
  constraint c_data_size_default {
    data.size() inside {[1:128]};
  }

  // Address range validity
  constraint c_addr_7bit {
    if (addr_mode == I2C_ADDR_7BIT) {
      addr inside {[0:127]};
      // Reserved addresses (like general call) could be constrained out here if needed
    }
  }

  function new(string name = "i2c_transaction");
    super.new(name);
  endfunction

  // Custom convert2string for readable sprint logs
  virtual function string convert2string();
    string s;
    s = "\n--------------------------------------------------\n";
    s = {s, $sformatf(" I2C TRANSACTION\n")};
    s = {s, $sformatf(" Address      : 0x%0x (%s)\n", addr, (addr_mode==I2C_ADDR_7BIT) ? "7-bit" : "10-bit")};
    s = {s, $sformatf(" Direction    : %s\n", direction.name())};
    s = {s, $sformatf(" Payload Size : %0d bytes\n", data.size())};
    if (data.size() > 0) begin
      s = {s, " Data Content :\n"};
      foreach (data[i]) begin
        if (i % 16 == 0) s = {s, $sformatf("    [%04x] ", i)};
        s = {s, $sformatf("%02x ", data[i])};
        if ((i+1) % 16 == 0) s = {s, "\n"};
      end
      if (data.size() % 16 != 0) s = {s, "\n"};
    end
    s = {s, $sformatf(" Status       : %s\n", status.name())};
    s = {s, "--------------------------------------------------"};
    return s;
  endfunction

endclass

`endif // I2C_TRANSACTION_SV
