# 1. Point directly to the found library folder
set_db lib_search_path { /home/install/FOUNDRY/digital/90nm/dig/lib }
set_db library slow.lib
set_db hdl_search_path { ./ }

# 2. Read Verilog RTL and Elaborate
read_hdl approx_alu.v
elaborate

# 3. Read Timing Constraints
read_sdc alu.sdc

# 4. Map Logic to Standard Cells
syn_gen
syn_map
syn_opt

# 5. Export Gate-Level Netlist and Constraints for Innovus
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge > delays.sdf
write_hdl > approx_alu_netlist.v
write_sdc > approx_alu_sdc.sdc

# 6. Generate Reports
report_timing > approx_alu_timing.rep
report_power  > approx_alu_power.rep
report_area   > approx_alu_cell.rep
report_messages > approx_alu_message.rep

# 7. Bring up the Schematic Viewer GUI
gui_show
