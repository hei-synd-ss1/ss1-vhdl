onerror {resume}
quietly virtual signal -install /sensors_tb/I_sensors {/sensors_tb/I_sensors/hallCount  } hallCount_0001
quietly virtual signal -install /sensors_tb/I_sensors { /sensors_tb/I_sensors/hallCount(15 downto 0)} hallcount_1
quietly virtual signal -install /sensors_tb/I_sensors { /sensors_tb/I_sensors/hallCount(31 downto 16)} hallCount2
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Gray60 -label Clock /sensors_tb/clock
add wave -noupdate -color Gray60 -label Reset /sensors_tb/reset
add wave -noupdate -color {Cornflower Blue} -label {Test Info} /sensors_tb/I_tester/testInfo
add wave -noupdate -divider Hall
add wave -noupdate -expand -group {Sensor 1} -color Gold -label {hallPulse - 1} /sensors_tb/hallPulses(1)
add wave -noupdate -expand -group {Sensor 1} -color Gold -label {zeroPos - 1} /sensors_tb/I_sensors/zeroPos(0)
add wave -noupdate -expand -group {Sensor 1} -color {Dark Orchid} -label {hallCount - 1} -radix unsigned /sensors_tb/I_sensors/hallcount_1
add wave -noupdate -expand -group {Sensor 2} -color Gold -label {hallPulse - 2} /sensors_tb/hallPulses(2)
add wave -noupdate -expand -group {Sensor 2} -color Gold -label {zeroPos - 2} /sensors_tb/I_sensors/zeroPos(1)
add wave -noupdate -expand -group {Sensor 2} -color {Dark Orchid} -label {hallCount - 2} -radix unsigned -childformat {{/sensors_tb/I_sensors/hallCount2(31) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(30) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(29) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(28) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(27) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(26) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(25) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(24) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(23) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(22) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(21) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(20) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(19) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(18) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(17) -radix unsigned} {/sensors_tb/I_sensors/hallCount2(16) -radix unsigned}} -subitemconfig {/sensors_tb/I_sensors/hallCount(31) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(30) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(29) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(28) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(27) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(26) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(25) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(24) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(23) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(22) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(21) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(20) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(19) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(18) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(17) {-color {Dark Orchid} -radix unsigned} /sensors_tb/I_sensors/hallCount(16) {-color {Dark Orchid} -radix unsigned}} /sensors_tb/I_sensors/hallCount2
add wave -noupdate -divider Ultrasound
add wave -noupdate -color Gold -label distancePulse /sensors_tb/distancePulse
add wave -noupdate -color {Dark Orchid} -label rangerDistance -radix unsigned /sensors_tb/I_sensors/rangerDistance
add wave -noupdate -radix decimal /sensors_tb/I_tester/tbRangerDistanceTarget
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {2295433870 ps} 0}
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
WaveRestoreZoom {1566733324 ps} {6310161405 ps}
run 100ms
