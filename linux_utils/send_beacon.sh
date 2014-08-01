#!/bin/sh
#
# Modified from
# https://github.com/floe/BTLE/blob/master/bluez_adv.sh

ascii2hex() {
  # Outputs the data of a string in a format that
  # hcitool can read. Limits it to 8 characters
  # for the "name" location of a BTLE advertisement
  echo -n $1 | awk 'BEGIN{for(n=0;n<256;n++)ord[sprintf("%c",n)]=n}{split($0, chars, ""); for (i=1; i <= 8; i++) { printf( "%x ", ord[chars[i]]) } }'
}

NAME=`ascii2hex $1`

# Turn rfkill off to make this work from boot
rfkill unblock all

# bring up the host controller if not already
sudo hciconfig hci0 up

# enable non-connectable undirected advertisements (only works with recent hciconfig)
#sudo hciconfig hci0 leadv 3

# set random device address
sudo hcitool -i hci0 cmd 0x08 0x0005 12 34 56 78 9A BC

# custom hci commands take two parameters:

# 0x08       opcode group (LE)
# 0x0008     opcode command (set LE adv data)

# set advertising parameters
# A0 00 A0 00  min/max adv. interval (125ms)
# 03           non-connectable undirected advertising
# 01           own address is random (see previous command)
# 00           target address is public (not used for undirected advertising)
# 00 00 00 ... target address (not used for undirected advertising)
# 07           adv. channel map (enable all)
# 00           filter policy (allow any)
sudo hcitool -i hci0 cmd 0x08 0x0006  A0 00  A0 00  03  01  00  00 00 00 00 00 00  07 00

# enable advertising
sudo hcitool -i hci0 cmd 0x08 0x000A  01

# set advertisement data (_after_ advertising is enabled)
# 0e         adv data length (should be at most 0x15 for compatibility with NRF24L01+)
# 02 01 05   flags (LE-only device, non-connectable) 
# 07 09 ...  name
# 02 ff fe   custom data (02 length, ff type, fe data)
# 00 00 ...  padding (to 32 bytes including length)

#                                      1  [   3  ]  [          8          ]  [  3   ]  [                      17                        ]
sudo hcitool -i hci0 cmd 0x08 0x0008  0e  02 01 05  $NAME                    00 00 00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
#sudo hcitool -i hci0 cmd 0x08 0x0008  0e  02 01 05  07 09 66 6f 6f 62 61 72  00 00 00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
#sudo hcitool -i hci0 cmd 0x08 0x0008  0e  02 01 05  07 09 66 6f 6f 62 61 72  02 ff fe  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

sleep 8s

# disable advertising
#sudo hcitool -i hci0 cmd 0x08 0x000A  00
