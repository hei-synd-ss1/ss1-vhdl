onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Gray60 -label Clock /dcmotorcontroller_tb/I_tester/clock
add wave -noupdate -color Gray60 -label Reset /dcmotorcontroller_tb/I_tester/reset
add wave -noupdate -color {Cornflower Blue} -label {Test Info} /dcmotorcontroller_tb/I_tester/testInfo
add wave -noupdate -divider Kart
add wave -noupdate -color Gold -label Prescaler /dcmotorcontroller_tb/I_DC/I_regs/prescaler
add wave -noupdate -color Gold -label pwmEn /dcmotorcontroller_tb/I_DC/I_div/pwmEn
add wave -noupdate -color Gold -label Speed /dcmotorcontroller_tb/I_DC/I_regs/speed
add wave -noupdate -color Gold -label {hwOrientation - Normal direction} /dcmotorcontroller_tb/I_tester/hwOrientation(0)
add wave -noupdate -color Gold -label {hwOrientation - Restart} /dcmotorcontroller_tb/I_tester/hwOrientation(4)
add wave -noupdate -color Gold -label {hwOrientation - BT Connected} /dcmotorcontroller_tb/I_tester/hwOrientation(5)
add wave -noupdate -divider {DC motor}
add wave -noupdate -color {Dark Orchid} -label Forwards /dcmotorcontroller_tb/I_tester/forwards
add wave -noupdate -color {Dark Orchid} -label PWM /dcmotorcontroller_tb/I_tester/pwm
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 251
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
WaveRestoreZoom {0 ps} {19679678074 ps}
run 500 ms
