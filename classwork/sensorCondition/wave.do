onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /sensorCondition_tb/dut/cadence
add wave -noupdate -format Analog-Step -height 74 -max 1022.0 /sensorCondition_tb/dut/avg_curr
add wave -noupdate -format Analog-Step -height 74 -max 383.0 /sensorCondition_tb/dut/avg_torque
add wave -noupdate /sensorCondition_tb/torque
add wave -noupdate /sensorCondition_tb/curr
add wave -noupdate /sensorCondition_tb/cadence_raw
add wave -noupdate /sensorCondition_tb/dut/cadence_filt
add wave -noupdate /sensorCondition_tb/dut/cadence_rise
add wave -noupdate -radix hexadecimal /sensorCondition_tb/dut/cadence_per
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1692963 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 289
configure wave -valuecolwidth 207
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
WaveRestoreZoom {0 ps} {25837226 ps}
