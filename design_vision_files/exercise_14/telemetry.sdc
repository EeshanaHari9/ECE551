###################################################################

# Created by write_sdc on Fri Apr 18 14:01:53 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_wire_load_model -name 16000 -library saed32lvt_tt0p85v25c
set_max_transition 0.15 [current_design]
set_load -pin_load 0.15 [get_ports TX]
set_load -pin_load 0.15 [get_ports tx_done]
create_clock [get_ports clk]  -period 2.5  -waveform {0 1.25}
set_input_delay -clock clk  0.5  [get_ports rst_n]
set_input_delay -clock clk  0.5  [get_ports {batt_v[11]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[10]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[9]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[8]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[7]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[6]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[5]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[4]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[3]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[2]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[1]}]
set_input_delay -clock clk  0.5  [get_ports {batt_v[0]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[11]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[10]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[9]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[8]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[7]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[6]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[5]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[4]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[3]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[2]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[1]}]
set_input_delay -clock clk  0.5  [get_ports {avg_curr[0]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[11]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[10]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[9]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[8]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[7]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[6]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[5]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[4]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[3]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[2]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[1]}]
set_input_delay -clock clk  0.5  [get_ports {avg_torque[0]}]
set_output_delay -clock clk  0.75  [get_ports TX]
set_output_delay -clock clk  0.75  [get_ports tx_done]
set_drive 0.0001  [get_ports rst_n]
