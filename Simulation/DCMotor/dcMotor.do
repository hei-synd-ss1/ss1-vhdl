onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Kart
add wave -noupdate -color Gray60 -label reset /dcmotor_tb/I_tester/reset
add wave -noupdate -color Gray60 -label clock /dcmotor_tb/I_tester/clock
add wave -noupdate -color Gray60 -label {test info} /dcmotor_tb/I_tester/testInfo
add wave -noupdate -divider Prescaler
add wave -noupdate -color {Dark Orchid} -label prescaler -radix unsigned /dcmotor_tb/prescaler
add wave -noupdate -label pwmEn /dcmotor_tb/pwmEn
add wave -noupdate -divider {DC motor}
add wave -noupdate -color {Dark Orchid} -label normalDirection /dcmotor_tb/normalDirection
add wave -noupdate -color {Dark Orchid} -label restart /dcmotor_tb/restart
add wave -noupdate -color {Dark Orchid} -label btConnected /dcmotor_tb/btConnected
add wave -noupdate -color {Dark Orchid} -label speed -radix sfixed /dcmotor_tb/speed
add wave -noupdate -color Gold -label forwards /dcmotor_tb/forwards
add wave -noupdate -color Gold -label pwmOut /dcmotor_tb/pwmOut
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {269099357 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {0 ps} {2730567 ns}
run -all
