onerror {resume}
quietly virtual signal -install /hall_tb/I_DUT { /hall_tb/I_DUT/position(31 downto 16)} Position2
quietly virtual signal -install /hall_tb/I_DUT { /hall_tb/I_DUT/position(15 downto 0)} Position1
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Kart
add wave -noupdate -color Gray60 -label reset /hall_tb/reset
add wave -noupdate -color Gray60 -label clock /hall_tb/clock
add wave -noupdate -color Gray60 -label testInfo /hall_tb/I_tester/testInfo
add wave -noupdate -divider Hall
add wave -noupdate -expand -group {Sensor 1} -color {Dark Orchid} -label {hallPulses 1} /hall_tb/I_DUT/hallPulses(1)
add wave -noupdate -expand -group {Sensor 1} -color {Dark Orchid} -label {zeroPos 1} /hall_tb/I_DUT/zeroPos(1)
add wave -noupdate -expand -group {Sensor 1} -color Gold -label {Position 1} /hall_tb/I_DUT/Position1
add wave -noupdate -expand -group {Sensor 2} -color {Dark Orchid} -label {hallPulses 2} /hall_tb/I_DUT/hallPulses(2)
add wave -noupdate -expand -group {Sensor 2} -color {Dark Orchid} -label {zeroPos 2} /hall_tb/I_DUT/zeroPos(2)
add wave -noupdate -expand -group {Sensor 2} -color Gold -label {Position 2} /hall_tb/I_DUT/Position2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {4180648394 ps} 0}
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
WaveRestoreZoom {0 ps} {2730567 ns}
run -all
