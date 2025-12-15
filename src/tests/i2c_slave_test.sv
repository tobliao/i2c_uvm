// In i2c_test_lib.sv - Adding Slave Test

class i2c_slave_test extends i2c_test_base;
  `uvm_component_utils(i2c_slave_test)

  function new(string name = "i2c_slave_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Overwrite Config to be Slave
    cfg.is_master = 0; 
  endfunction

  task run_phase(uvm_phase phase);
    i2c_base_sequence seq; // Placeholder for slave sequence (response sequence)
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting Slave Mode Test", UVM_LOW)
    
    // In Slave mode, the "Sequence" is reactive.
    // Ideally we start a reactive slave sequence that runs forever or until N transactions.
    // For now, let's just wait to let the RTL Master drive traffic.
    
    #100us; // Wait for Master traffic
    
    phase.drop_objection(this);
  endtask

endclass

