onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Gray70 /kartcontroller_tb/clock
add wave -noupdate -color Gray70 /kartcontroller_tb/reset
add wave -noupdate /kartcontroller_tb/I_tester/I_transReader/target
add wave -noupdate /kartcontroller_tb/I_tester/I_transReader/info
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider Modules
add wave -noupdate -expand -group DC /kartcontroller_tb/I_Kart/I_dcMotorController/prescaler
add wave -noupdate -expand -group DC /kartcontroller_tb/I_Kart/I_dcMotorController/speed
add wave -noupdate -expand -group DC -color {Medium Orchid} /kartcontroller_tb/I_Kart/pwm
add wave -noupdate -expand -group DC -color {Medium Orchid} /kartcontroller_tb/I_Kart/forwards
add wave -noupdate -expand -group Stepper /kartcontroller_tb/I_Kart/I_stepperController/clockDivider
add wave -noupdate -expand -group Stepper /kartcontroller_tb/I_Kart/I_stepperController/stepEn
add wave -noupdate -expand -group Stepper -color Gold /kartcontroller_tb/I_tester/I_stepper/testMode
add wave -noupdate -expand -group Stepper -radix decimal /kartcontroller_tb/I_Kart/I_stepperController/targetAngle
add wave -noupdate -expand -group Stepper -radix decimal /kartcontroller_tb/I_Kart/I_stepperController/actual
add wave -noupdate -expand -group Stepper /kartcontroller_tb/I_Kart/I_stepperController/reached
add wave -noupdate -expand -group Stepper -color Gold /kartcontroller_tb/I_Kart/stepperEnd
add wave -noupdate -expand -group Stepper /kartcontroller_tb/I_Kart/I_stepperController/I_angleControl/I_phases/enCoils
add wave -noupdate -expand -group Stepper -color {Medium Orchid} /kartcontroller_tb/I_Kart/coil1
add wave -noupdate -expand -group Stepper -color {Medium Orchid} /kartcontroller_tb/I_Kart/coil2
add wave -noupdate -expand -group Stepper -color {Medium Orchid} /kartcontroller_tb/I_Kart/coil3
add wave -noupdate -expand -group Stepper -color {Medium Orchid} /kartcontroller_tb/I_Kart/coil4
add wave -noupdate -expand -group Sensors -color Gold /kartcontroller_tb/testMode
add wave -noupdate -expand -group Sensors -color Gold /kartcontroller_tb/I_Kart/endSwitches
add wave -noupdate -expand -group Sensors -color {Medium Orchid} /kartcontroller_tb/I_Kart/leds
add wave -noupdate -expand -group Sensors -group Hall /kartcontroller_tb/I_Kart/I_sensorsController/I_regs/U_2/sendHall
add wave -noupdate -expand -group Sensors -group Hall -color Gold /kartcontroller_tb/I_Kart/hallPulses
add wave -noupdate -expand -group Sensors -group Hall /kartcontroller_tb/I_Kart/I_sensorsController/zeroPos
add wave -noupdate -expand -group Sensors -group Hall /kartcontroller_tb/I_Kart/I_sensorsController/hallCount
add wave -noupdate -expand -group Sensors -expand -group Ranger -color Gold /kartcontroller_tb/I_Kart/distancePulse
add wave -noupdate -expand -group Sensors -expand -group Ranger /kartcontroller_tb/I_Kart/I_sensorsController/rangerDistance
add wave -noupdate -expand -group Sensors -group Battery /kartcontroller_tb/I_tester/batterySClOut
add wave -noupdate -expand -group Sensors -group Battery -color Gold /kartcontroller_tb/I_tester/batterySDaIn
add wave -noupdate -expand -group Sensors -group Battery /kartcontroller_tb/I_Kart/I_sensorsController/battery250uv
add wave -noupdate -expand -group Sensors -group Battery /kartcontroller_tb/I_Kart/I_sensorsController/current250uA
add wave -noupdate -expand -group CReg /kartcontroller_tb/I_Kart/hwOrientation
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {45854748695 ps} 0} {{Cursor 3} {163917582899 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 527
configure wave -valuecolwidth 120
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
WaveRestoreZoom {0 ps} {204262062368 ps}
run 500ms
