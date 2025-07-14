onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2cfifo_tb/reset
add wave -noupdate /i2cfifo_tb/clock
add wave -noupdate -divider Controls
add wave -noupdate -radix hexadecimal /i2cfifo_tb/txdata
add wave -noupdate -radix hexadecimal /i2cfifo_tb/txdata
add wave -noupdate /i2cfifo_tb/txwr
add wave -noupdate /i2cfifo_tb/txfull
add wave -noupdate -radix hexadecimal /i2cfifo_tb/rxdata
add wave -noupdate /i2cfifo_tb/rxempty
add wave -noupdate /i2cfifo_tb/rxrd
add wave -noupdate -divider Transmitter
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_dut/txword
add wave -noupdate /i2cfifo_tb/i_dut/txsend
add wave -noupdate /i2cfifo_tb/i_dut/txbusy
add wave -noupdate -divider Receiver
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_dut/rxword
add wave -noupdate /i2cfifo_tb/i_dut/rxwordvalid
add wave -noupdate -divider EEPROM
add wave -noupdate /i2cfifo_tb/i_mem/currentstate
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_mem/memoryaddress
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_mem/i2cdata
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_mem/memorycontent(1360)
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_mem/memorycontent(1361)
add wave -noupdate -radix hexadecimal /i2cfifo_tb/i_mem/currentword
add wave -noupdate -divider {Serial interface}
add wave -noupdate /i2cfifo_tb/sclin
add wave -noupdate /i2cfifo_tb/sdaout
add wave -noupdate /i2cfifo_tb/sdain
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {0 ps} 0}
configure wave -namecolwidth 241
configure wave -valuecolwidth 80
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
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ps} {5250 us}
