onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Reset and clock} /uvmrs232_tb/reset
add wave -noupdate -group {Reset and clock} /uvmrs232_tb/clock
add wave -noupdate -expand -group {UART signals} /uvmrs232_tb/RxD
add wave -noupdate -expand -group {UART signals} /uvmrs232_tb/TxD
add wave -noupdate -expand -group {UART Tx} /uvmrs232_tb/I_tester/rs232TxString
add wave -noupdate -expand -group {UART Tx} /uvmrs232_tb/I_tester/rs232SendString
add wave -noupdate -expand -group {UART Tx} /uvmrs232_tb/dataIn
add wave -noupdate -expand -group {UART Tx} /uvmrs232_tb/send
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/U_DUT/I_driv/outString
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/U_DUT/I_driv/sendString
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/U_DUT/I_driv/outChar
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/U_DUT/I_driv/sendChar
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/dataOut
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/dataValid
add wave -noupdate -expand -group {UART Rx} /uvmrs232_tb/I_tester/rs232RxChar
add wave -noupdate -expand -group Transactions /uvmrs232_tb/U_DUT/driverTransaction
add wave -noupdate -expand -group Transactions /uvmrs232_tb/U_DUT/monitorTransaction
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 247
configure wave -valuecolwidth 40
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
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {2100 us}
