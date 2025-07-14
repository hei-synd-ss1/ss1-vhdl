onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /serialporttransmitter_tb/clock
add wave -noupdate /serialporttransmitter_tb/reset
add wave -noupdate -divider Controls
add wave -noupdate -radix hexadecimal -radixshowbase 0 /serialporttransmitter_tb/dataIn
add wave -noupdate /serialporttransmitter_tb/send
add wave -noupdate -divider Internals
add wave -noupdate /serialporttransmitter_tb/I_DUT/dividerCounterReset
add wave -noupdate /serialporttransmitter_tb/I_DUT/txSendingByte
add wave -noupdate /serialporttransmitter_tb/I_DUT/txSendingByteAndStop
add wave -noupdate -divider {Serial out}
add wave -noupdate /serialporttransmitter_tb/busy
add wave -noupdate /serialporttransmitter_tb/TxD
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {33909547739 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 142
configure wave -valuecolwidth 40
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
WaveRestoreZoom {0 ps} {315 us}
