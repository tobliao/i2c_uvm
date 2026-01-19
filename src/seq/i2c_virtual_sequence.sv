`ifndef I2C_VIRTUAL_SEQUENCE_SV
`define I2C_VIRTUAL_SEQUENCE_SV

//==============================================================================
// I2C Virtual Sequence Base
//
// Base class for complex sequences that coordinate multiple agents.
// Demonstrates use of:
// - uvm_event for synchronization
// - uvm_barrier for phase coordination
// - uvm_objection for test completion
//==============================================================================

class i2c_virtual_sequence_base extends uvm_sequence;
  `uvm_object_utils(i2c_virtual_sequence_base)
  `uvm_declare_p_sequencer(i2c_virtual_sequencer)
  
  // Configuration
  i2c_config cfg;
  
  function new(string name = "i2c_virtual_sequence_base");
    super.new(name);
  endfunction
  
  //----------------------------------------------------------------------------
  // Pre-body: Setup
  //----------------------------------------------------------------------------
  virtual task pre_body();
    if (starting_phase != null)
      starting_phase.raise_objection(this, "Virtual sequence starting");
    
    // Get configuration
    if (!uvm_config_db#(i2c_config)::get(null, "", "cfg", cfg)) begin
      cfg = i2c_config::type_id::create("cfg");
      `uvm_warning("VSEQ", "No config found, using defaults")
    end
  endtask
  
  //----------------------------------------------------------------------------
  // Post-body: Cleanup
  //----------------------------------------------------------------------------
  virtual task post_body();
    if (starting_phase != null)
      starting_phase.drop_objection(this, "Virtual sequence complete");
  endtask
  
  //----------------------------------------------------------------------------
  // Utility: Wait for Event with Logging
  //----------------------------------------------------------------------------
  task wait_event(string name);
    uvm_event ev = i2c_event_pool::get_event(name);
    `uvm_info("VSEQ", $sformatf("Waiting for event: %s", name), UVM_HIGH)
    ev.wait_trigger();
    `uvm_info("VSEQ", $sformatf("Event received: %s", name), UVM_HIGH)
  endtask
  
  //----------------------------------------------------------------------------
  // Utility: Trigger Event with Logging
  //----------------------------------------------------------------------------
  function void trigger_event(string name);
    i2c_event_pool::trigger_event(name);
    `uvm_info("VSEQ", $sformatf("Event triggered: %s", name), UVM_HIGH)
  endfunction
  
endclass

//==============================================================================
// Coordinated Write-Read Sequence
//
// Demonstrates event-driven sequencing:
// 1. Write data to slave
// 2. Wait for completion event
// 3. Read back and verify
//==============================================================================

class i2c_coordinated_wr_rd_sequence extends i2c_virtual_sequence_base;
  `uvm_object_utils(i2c_coordinated_wr_rd_sequence)
  
  // Parameters
  bit [6:0] target_addr = 7'h55;
  int num_bytes = 4;
  
  function new(string name = "i2c_coordinated_wr_rd_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    i2c_write_sequence wr_seq;
    i2c_read_sequence  rd_seq;
    bit [7:0] write_data[$];
    
    `uvm_info("VSEQ", "Starting coordinated write-read sequence", UVM_LOW)
    
    // Generate random data
    repeat(num_bytes) write_data.push_back($urandom_range(0, 255));
    
    //----------------------------------
    // Phase 1: Write Data
    //----------------------------------
    `uvm_info("VSEQ", "Phase 1: Writing data to slave", UVM_LOW)
    
    wr_seq = i2c_write_sequence::type_id::create("wr_seq");
    wr_seq.target_addr = target_addr;
    wr_seq.data = write_data;
    
    // Start on master sequencer
    wr_seq.start(p_sequencer.master_sqr);
    
    // Trigger completion event
    trigger_event(i2c_event_pool::TRANS_COMPLETE);
    
    //----------------------------------
    // Phase 2: Wait for Bus Idle
    //----------------------------------
    `uvm_info("VSEQ", "Phase 2: Waiting for bus idle", UVM_LOW)
    #1us; // Allow bus to settle
    trigger_event(i2c_event_pool::BUS_IDLE);
    
    //----------------------------------
    // Phase 3: Read Back
    //----------------------------------
    `uvm_info("VSEQ", "Phase 3: Reading back data", UVM_LOW)
    
    rd_seq = i2c_read_sequence::type_id::create("rd_seq");
    rd_seq.target_addr = target_addr;
    rd_seq.num_bytes = num_bytes;
    
    rd_seq.start(p_sequencer.master_sqr);
    
    //----------------------------------
    // Phase 4: Verify (via events)
    //----------------------------------
    trigger_event(i2c_event_pool::DATA_PHASE_DONE);
    
    `uvm_info("VSEQ", "Coordinated sequence complete", UVM_LOW)
  endtask
  
endclass

//==============================================================================
// Stress Test Sequence with Barriers
//
// Demonstrates uvm_barrier for synchronized parallel operations.
//==============================================================================

class i2c_stress_sequence extends i2c_virtual_sequence_base;
  `uvm_object_utils(i2c_stress_sequence)
  
  // Parameters
  int num_iterations = 10;
  int num_parallel_seq = 2;
  
  function new(string name = "i2c_stress_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    uvm_barrier sync_barrier;
    
    `uvm_info("VSEQ", $sformatf("Starting stress test: %0d iterations", num_iterations), UVM_LOW)
    
    // Get/create synchronization barrier
    sync_barrier = p_sequencer.get_barrier("stress_sync");
    sync_barrier.set_threshold(num_parallel_seq);
    
    fork
      // Thread 1: Continuous writes
      begin
        i2c_write_sequence wr_seq;
        repeat(num_iterations) begin
          wr_seq = i2c_write_sequence::type_id::create("wr_seq");
          wr_seq.target_addr = cfg.slave_addr;
          wr_seq.start(p_sequencer.master_sqr);
          
          // Wait at barrier for sync
          sync_barrier.wait_for();
          `uvm_info("VSEQ", "Write thread: passed barrier", UVM_HIGH)
        end
      end
      
      // Thread 2: Continuous reads
      begin
        i2c_read_sequence rd_seq;
        repeat(num_iterations) begin
          rd_seq = i2c_read_sequence::type_id::create("rd_seq");
          rd_seq.target_addr = cfg.slave_addr;
          rd_seq.num_bytes = 1;
          rd_seq.start(p_sequencer.master_sqr);
          
          // Wait at barrier for sync
          sync_barrier.wait_for();
          `uvm_info("VSEQ", "Read thread: passed barrier", UVM_HIGH)
        end
      end
    join
    
    `uvm_info("VSEQ", "Stress test complete", UVM_LOW)
  endtask
  
endclass

//==============================================================================
// Protocol Violation Detection Sequence
//
// Uses events to detect and report protocol violations.
//==============================================================================

class i2c_protocol_check_sequence extends i2c_virtual_sequence_base;
  `uvm_object_utils(i2c_protocol_check_sequence)
  
  // Error counts
  int arb_lost_count = 0;
  int nack_count = 0;
  int timeout_count = 0;
  
  function new(string name = "i2c_protocol_check_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    fork
      // Main test thread
      run_test_traffic();
      
      // Error monitoring thread
      monitor_errors();
    join_any
    disable fork;
    
    // Report results
    report_errors();
  endtask
  
  task run_test_traffic();
    i2c_mixed_sequence mixed_seq;
    
    mixed_seq = i2c_mixed_sequence::type_id::create("mixed_seq");
    mixed_seq.num_transactions = 20;
    mixed_seq.target_addr = cfg.slave_addr;
    mixed_seq.start(p_sequencer.master_sqr);
  endtask
  
  task monitor_errors();
    forever begin
      fork
        begin
          wait_event(i2c_event_pool::ARB_LOST);
          arb_lost_count++;
          `uvm_warning("VSEQ", $sformatf("Arbitration lost detected (count=%0d)", arb_lost_count))
        end
        begin
          wait_event(i2c_event_pool::NACK_RECEIVED);
          nack_count++;
          `uvm_info("VSEQ", $sformatf("NACK received (count=%0d)", nack_count), UVM_MEDIUM)
        end
        begin
          wait_event(i2c_event_pool::ERROR_DETECTED);
          `uvm_error("VSEQ", "Protocol error detected!")
        end
      join_any
    end
  endtask
  
  function void report_errors();
    `uvm_info("VSEQ", "========================================", UVM_LOW)
    `uvm_info("VSEQ", "   PROTOCOL CHECK SUMMARY", UVM_LOW)
    `uvm_info("VSEQ", "========================================", UVM_LOW)
    `uvm_info("VSEQ", $sformatf("Arbitration Lost: %0d", arb_lost_count), UVM_LOW)
    `uvm_info("VSEQ", $sformatf("NACKs Received:   %0d", nack_count), UVM_LOW)
    `uvm_info("VSEQ", "========================================", UVM_LOW)
  endfunction
  
endclass

`endif // I2C_VIRTUAL_SEQUENCE_SV
