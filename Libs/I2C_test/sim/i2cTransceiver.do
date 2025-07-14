onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2ctransceiver_tb/reset
add wave -noupdate /i2ctransceiver_tb/clock
add wave -noupdate -divider Transmitter
add wave -noupdate -radix hexadecimal /i2ctransceiver_tb/i_ctrl/txword
add wave -noupdate /i2ctransceiver_tb/i_ctrl/txsend
add wave -noupdate -divider {Serial interface}
add wave -noupdate /i2ctransceiver_tb/scl
add wave -noupdate /i2ctransceiver_tb/sda
add wave -noupdate -divider {Transceiver internals}
add wave -noupdate /i2ctransceiver_tb/i_dut/startcondition
add wave -noupdate -radix unsigned /i2ctransceiver_tb/i_dut/stopcondition
add wave -noupdate -format Analog-Step -height 20 -max 14.117599999999999 -radix unsigned /i2ctransceiver_tb/i_dut/bitcounter
add wave -noupdate /i2ctransceiver_tb/i_dut/endofword
add wave -noupdate /i2ctransceiver_tb/i_dut/rxstate
add wave -noupdate /i2ctransceiver_tb/i_dut/i2cbytevalid
add wave -noupdate -radix hexadecimal /i2ctransceiver_tb/i_dut/i2cbyte
add wave -noupdate /i2ctransceiver_tb/i_dut/ackmoment
add wave -noupdate /i2ctransceiver_tb/i_dut/sendack
add wave -noupdate /i2ctransceiver_tb/i_dut/loadoutshiftreg
add wave -noupdate /i2ctransceiver_tb/i_dut/ensdaout
add wave -noupdate -radix hexadecimal /i2ctransceiver_tb/i_dut/outputshiftreg
add wave -noupdate -divider {Transceiver interface}
add wave -noupdate -radix hexadecimal -subitemconfig {/i2ctransceiver_tb/chipaddr(6) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/chipaddr(5) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/chipaddr(4) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/chipaddr(3) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/chipaddr(2) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/chipaddr(1) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/chipaddr(0) {-height 15 -radix hexadecimal}} /i2ctransceiver_tb/chipaddr
add wave -noupdate /i2ctransceiver_tb/isselected
add wave -noupdate -radix hexadecimal -subitemconfig {/i2ctransceiver_tb/registeraddr(7) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(6) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(5) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(4) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(3) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(2) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(1) {-radix hexadecimal} /i2ctransceiver_tb/registeraddr(0) {-radix hexadecimal}} /i2ctransceiver_tb/registeraddr
add wave -noupdate -radix hexadecimal -subitemconfig {/i2ctransceiver_tb/datain(7) {-radix hexadecimal} /i2ctransceiver_tb/datain(6) {-radix hexadecimal} /i2ctransceiver_tb/datain(5) {-radix hexadecimal} /i2ctransceiver_tb/datain(4) {-radix hexadecimal} /i2ctransceiver_tb/datain(3) {-radix hexadecimal} /i2ctransceiver_tb/datain(2) {-radix hexadecimal} /i2ctransceiver_tb/datain(1) {-radix hexadecimal} /i2ctransceiver_tb/datain(0) {-radix hexadecimal}} /i2ctransceiver_tb/datain
add wave -noupdate /i2ctransceiver_tb/writedata
add wave -noupdate /i2ctransceiver_tb/datavalid
add wave -noupdate -radix hexadecimal /i2ctransceiver_tb/dataout
add wave -noupdate -divider {Register bank}
add wave -noupdate -radix hexadecimal -subitemconfig {/i2ctransceiver_tb/i_tb/registerbank(7) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(6) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(5) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(4) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(3) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(2) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(1) {-height 15 -radix hexadecimal} /i2ctransceiver_tb/i_tb/registerbank(0) {-height 15 -radix hexadecimal}} /i2ctransceiver_tb/i_tb/registerbank
add wave -noupdate -divider Receiver
add wave -noupdate /i2ctransceiver_tb/rxempty
add wave -noupdate /i2ctransceiver_tb/rxrd
add wave -noupdate -radix hexadecimal /i2ctransceiver_tb/rxdata
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
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {210 us}
