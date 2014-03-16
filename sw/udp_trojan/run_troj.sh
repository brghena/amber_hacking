#!/bin/bash

NUMARGS=3
ARGC=$#

PACKET_SENDER="udp_packet_sender"

if [[ $ARGC -lt $NUMARGS ]] ; then
	echo "Please provide an input test case!"
	exit
fi

AMBER_TEST_NAME=$1
IP_ADDR=$2
PORT_NUM=$3

if [ ! -f ../../hw/tests/${AMBER_TEST_NAME}.S ]; then
	echo "Test does not exist!"
	exit
else
	echo "Compiling ../../hw/tests/${AMBER_TEST_NAME}.S"
    	pushd ../../hw/tests > /dev/null
    	make --quiet TEST=${AMBER_TEST_NAME}
    	MAKE_STATUS=$?
        
    	popd > /dev/null
    	BOOT_MEM_FILE="../../hw/tests/${AMBER_TEST_NAME}.mem"
fi

echo "Compiling ${PACKET_SENDER}.c"
gcc -Wall -o activate_trojan ${PACKET_SENDER}.c

echo "Running packet sending program"
./activate_trojan "$BOOT_MEM_FILE" "$IP_ADDR" "$PORT_NUM"


