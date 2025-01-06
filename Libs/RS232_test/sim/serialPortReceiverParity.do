onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock & reset}
add wave -noupdate /serialportreceiverparity_tb/clock
add wave -noupdate /serialportreceiverparity_tb/reset
add wave -noupdate /serialportreceiverparity_tb/U_1/dbg_info
add wave -noupdate -divider Input
add wave -noupdate /serialportreceiverparity_tb/RxD
add wave -noupdate -divider Output
add wave -noupdate /serialportreceiverparity_tb/byte
add wave -noupdate /serialportreceiverparity_tb/byteError
add wave -noupdate /serialportreceiverparity_tb/byteReceived
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7054567 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 228
configure wave -valuecolwidth 65
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {28849131 ps}
