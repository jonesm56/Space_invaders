# Project-wide compilation settings
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSEMA5F31C6
set_global_assignment -name TOP_LEVEL_ENTITY space_invaders

# RAM inference and optimization settings
set_global_assignment -name AUTO_RAM_RECOGNITION ON
set_global_assignment -name AUTO_RAM_BLOCKING ON
set_global_assignment -name ALLOW_ANY_RAM_SIZE_FOR_RECOGNITION ON

# Memory initialization files
set_global_assignment -name MIF_FILE screens.mif
set_global_assignment -name MIF_FILE elements.mif

# Clock domain constraints
create_clock -period 20.000 -name pixel_clk [get_ports pixel_clk]
create_clock -period 10.000 -name game_clk [get_ports game_clk]
create_clock -period 10.000 -name mem_clk [get_ports mem_clk]

# Clock domain crossing constraints
set_clock_groups -asynchronous -group {pixel_clk} -group {game_clk}
set_clock_groups -asynchronous -group {mem_clk} -group {pixel_clk game_clk}

# RAM timing optimization
set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
set_global_assignment -name ALLOW_SHIFT_REGISTER_MERGING_ACROSS_HIERARCHIES ALWAYS
set_global_assignment -name ALLOW_REGISTER_MERGING ON
set_global_assignment -name ALLOW_REGISTER_DUPLICATION ON

# Cyclone V specific settings
set_global_assignment -name ENABLE_ADVANCED_IO_TIMING ON
set_global_assignment -name USE_HIGH_SPEED_TERMINATION_PARALLEL_STRUCTURES ON
set_global_assignment -name STRATIXV_CONFIGURATION_SCHEME "ACTIVE SERIAL X4"
set_global_assignment -name ACTIVE_SERIAL_CLOCK FREQ_100MHZ

# Power optimization settings for Cyclone V
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"

# Add specific timing constraints for VGA
create_generated_clock -name vga_clk -source [get_pins {pll_main_inst|outclk_0}] -divide_by 2 [get_registers {vga_controller:vga_ctrl|*}]

# Add multicycle paths for VGA signals
set_multicycle_path -setup 2 -from [get_clocks game_clk] -to [get_clocks vga_clk]
set_multicycle_path -hold 1 -from [get_clocks game_clk] -to [get_clocks vga_clk]

# Add false paths for asynchronous resets
set_false_path -from [get_ports {KEY*}] -to *
set_false_path -from [get_ports {SW*}] -to *

# Add specific RAM timing constraints
set_false_path -from [get_registers {blk_mem_gen:mem_interface|mem_init_done}] -to [get_registers {space_invaders:*|mem_ready}]

# Add timing constraints for RAM interfaces
set_false_path -from [get_registers {*|mem_init_done}] -to [get_registers {*|mem_ready}]

# Optimize RAM inference
set_global_assignment -name ALLOW_ANY_RAM_SIZE_FOR_RECOGNITION ON
set_global_assignment -name AUTO_RAM_RECOGNITION ON

# Add specific constraints for dual-port RAM
set_false_path -from [get_registers {elements_ram_ip:*|altsyncram:*|*}] -to [get_registers {screens_ram_ip:*|altsyncram:*|*}]
