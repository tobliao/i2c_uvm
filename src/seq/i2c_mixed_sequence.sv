`ifndef I2C_MIXED_SEQUENCE_SV
`define I2C_MIXED_SEQUENCE_SV

class i2c_mixed_sequence extends i2c_base_sequence;
  `uvm_object_utils(i2c_mixed_sequence)
  
  rand int num_transactions;

  constraint c_num_trans {
    num_transactions inside {[10:50]};
  }

  function new(string name = "i2c_mixed_sequence");
    super.new(name);
  endfunction

  task body();
    i2c_direction_e last_dir;
    
    `uvm_info("SEQ", $sformatf("Starting Mixed Sequence with %0d transactions to addr 0x%0h", num_transactions, target_addr), UVM_LOW)
    
    repeat(num_transactions) begin
      req = i2c_transaction::type_id::create("req");
      
      start_item(req);
      if (!req.randomize() with {
         addr_mode == I2C_ADDR_7BIT;
         addr == local::target_addr;
         data.size() inside {[1:32]};
         
         // Weight distribution for interesting scenarios
         direction dist {I2C_WRITE := 50, I2C_READ := 50};
         repeated_start dist {0 := 70, 1 := 30};
      }) begin
        `uvm_fatal("SEQ", "Randomization failed")
      end
      finish_item(req);
      
      last_dir = req.direction;
    end
    
    `uvm_info("SEQ", "Finished Mixed Sequence", UVM_LOW)
  endtask
endclass

`endif // I2C_MIXED_SEQUENCE_SV
