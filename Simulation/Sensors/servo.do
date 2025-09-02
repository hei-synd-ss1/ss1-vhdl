onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Kart
add wave -noupdate -color Gray60 -label clock /servo_tb/clock
add wave -noupdate -color Gray60 -label reset /servo_tb/reset
add wave -noupdate -color Gray60 -label testInfo /servo_tb/I_tester/testInfo
add wave -noupdate -divider Servo
add wave -noupdate -color {Violet Red} -label pulse_20ms /servo_tb/pulse_20ms
add wave -noupdate -color {Violet Red} -label count_target -radix unsigned /servo_tb/count_target
add wave -noupdate -color Gold -label servo /servo_tb/servo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {43001040000 ps} 0} {{Cursor 2} {41001040000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 282
configure wave -valuecolwidth 100
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
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ps} {64575462 ns}
run -all
