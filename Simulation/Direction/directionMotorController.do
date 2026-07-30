onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Gray60 -label Clock /directionmotorcontroller_tb/clock
add wave -noupdate -color Gray60 -label nReset /directionmotorcontroller_tb/reset
add wave -noupdate -color Turquoise -label Info /directionmotorcontroller_tb/I_tester/testInfo
add wave -noupdate -divider Insides
add wave -noupdate -color Gold -radix unsigned /directionmotorcontroller_tb/I_stepper/I_registers/targetCommand
add wave -noupdate -divider Kart
add wave -noupdate -radix unsigned /directionmotorcontroller_tb/I_stepper/targetAngle
add wave -noupdate /directionmotorcontroller_tb/I_stepper/customReg1
add wave -noupdate /directionmotorcontroller_tb/I_stepper/customReg2
add wave -noupdate /directionmotorcontroller_tb/I_stepper/customReg3
add wave -noupdate -divider Servo
add wave -noupdate /directionmotorcontroller_tb/I_stepper/dirServoRaw
add wave -noupdate -color {Violet Red} /directionmotorcontroller_tb/I_stepper/directionServo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 5} {20000490000 ps} 0} {{Cursor 2} {21000590000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 215
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ps} {64191517825 ps}
run -all
