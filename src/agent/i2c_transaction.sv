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
