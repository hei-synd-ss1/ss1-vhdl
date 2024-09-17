onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Gray60 -label Clock /steppermotorcontroller_tb/clock
add wave -noupdate -color Gray60 -label nReset /steppermotorcontroller_tb/reset
add wave -noupdate -color Turquoise -label Info /steppermotorcontroller_tb/I_tester/testInfo
add wave -noupdate -divider Kart
add wave -noupdate -color Gold -label testMode /steppermotorcontroller_tb/testMode
add wave -noupdate -color Gold -label stepperEnd /steppermotorcontroller_tb/stepperEnd
add wave -noupdate -color Gold -label {hwControl - Clockwise} /steppermotorcontroller_tb/I_tester/hwOrientation(1)
add wave -noupdate -color Gold -label {hwcontrol - Sensor left} /steppermotorcontroller_tb/I_tester/hwOrientation(2)
add wave -noupdate -color Gold -label {hwControl - Restart} /steppermotorcontroller_tb/hwOrientation(4)
add wave -noupdate -divider Coils
add wave -noupdate -color {Blue Violet} -label Coil1 /steppermotorcontroller_tb/coil1
add wave -noupdate -color {Blue Violet} -label Coil2 /steppermotorcontroller_tb/coil2
add wave -noupdate -color {Blue Violet} -label Coil3 /steppermotorcontroller_tb/coil3
add wave -noupdate -color {Blue Violet} -label Coil4 /steppermotorcontroller_tb/coil4
add wave -noupdate -color {Dark Orchid} -radix unsigned /steppermotorcontroller_tb/I_stepper/magnetizing_power
add wave -noupdate -divider Insides
add wave -noupdate -radix unsigned /steppermotorcontroller_tb/I_stepper/targetAngle
add wave -noupdate -radix unsigned /steppermotorcontroller_tb/I_stepper/actual
add wave -noupdate /steppermotorcontroller_tb/I_stepper/reached
add wave -noupdate /steppermotorcontroller_tb/I_stepper/stepperEndOr
add wave -noupdate /steppermotorcontroller_tb/I_stepper/stepEn
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 5} {32080601000 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {21837290558 ps} {35777617340 ps}
