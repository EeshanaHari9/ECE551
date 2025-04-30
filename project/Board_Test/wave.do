onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ebike_tb/clk
add wave -noupdate /ebike_tb/RST_n
add wave -noupdate /ebike_tb/A2D_SS_n
add wave -noupdate /ebike_tb/A2D_MOSI
add wave -noupdate /ebike_tb/A2D_SCLK
add wave -noupdate /ebike_tb/A2D_MISO
add wave -noupdate /ebike_tb/hallGrn
add wave -noupdate /ebike_tb/hallYlw
add wave -noupdate /ebike_tb/hallBlu
add wave -noupdate /ebike_tb/highGrn
add wave -noupdate /ebike_tb/lowGrn
add wave -noupdate /ebike_tb/highYlw
add wave -noupdate /ebike_tb/lowYlw
add wave -noupdate /ebike_tb/highBlu
add wave -noupdate /ebike_tb/lowBlu
add wave -noupdate /ebike_tb/inertSS_n
add wave -noupdate /ebike_tb/inertSCLK
add wave -noupdate /ebike_tb/inertMISO
add wave -noupdate /ebike_tb/inertINT
add wave -noupdate /ebike_tb/cadence
add wave -noupdate /ebike_tb/tgglMd
add wave -noupdate /ebike_tb/TX_RX
add wave -noupdate /ebike_tb/LED
add wave -noupdate /ebike_tb/TORQUE
add wave -noupdate /ebike_tb/BRAKE
add wave -noupdate -format Analog-Step -height 74 -max 422.0 -radix decimal /ebike_tb/CURR
add wave -noupdate /ebike_tb/BATT
add wave -noupdate /ebike_tb/YAW_RT
add wave -noupdate /ebike_tb/rst_n
add wave -noupdate /ebike_tb/vld_TX
add wave -noupdate /ebike_tb/rx_data
add wave -noupdate -format Analog-Step -height 74 -max 982.99999999999989 -min -188.0 -radix decimal /ebike_tb/u_phys/omega
add wave -noupdate -format Analog-Step -height 74 -max 374.0 -radix decimal /ebike_tb/u_phys/avg_curr
add wave -noupdate -format Analog-Step -height 74 -max 2043.0000000000005 -min -2044.0 -radix decimal /ebike_tb/DUT/error
add wave -noupdate -format Analog-Step -height 74 -max 3287.0 -radix unsigned /ebike_tb/DUT/u_sensorCondition/target_curr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1687050000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 276
configure wave -valuecolwidth 140
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {6529648553 ps}
