# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Sat Oct 10 16:58:29 IST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design alu

create_clock -name "clk" -period 10.0 -waveform {0.0 5.0} [get_ports clk]
set_clock_transition 0.1 [get_clocks clk]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports rst_n]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {A[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {B[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Sel[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Sel[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Sel[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports {ALU_Out[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 1.0 [get_ports CarryOut]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.01 [get_ports clk]
set_clock_uncertainty -hold 0.01 [get_ports clk]
