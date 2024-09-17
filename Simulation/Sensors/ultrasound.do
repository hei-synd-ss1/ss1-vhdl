onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Kart
add wave -noupdate -color Gray60 -label reset /ultrasound_tb/reset
add wave -noupdate -color Gray60 -label clock /ultrasound_tb/clock
add wave -noupdate -color Gray60 -label testInfo /ultrasound_tb/I_tester/testInfo
add wave -noupdate -color Gray60 -label testMode /ultrasound_tb/I_tester/testMode
add wave -noupdate -divider Ultrasound
add wave -noupdate -label startNextCount /ultrasound_tb/startNextCount
add wave -noupdate -color {Dark Orchid} -label distancePulse /ultrasound_tb/distancePulse
add wave -noupdate -color Gold -label distance -radix unsigned /ultrasound_tb/distance
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {749122407 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {0 ps} {2730672 ns}
