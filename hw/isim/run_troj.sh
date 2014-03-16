#!/bin/bash

NUMARGS=1
ARGC=$#

if [[ $ARGC -lt $NUMARGS ]] ; then
	echo "Please provide an input test case!"
	exit
fi

AMBER_TEST_NAME=$1

if [ ! -f ../tests/${AMBER_TEST_NAME}.S ]; then
	echo "Test does not exist!"
	exit
else
	echo "Compile ../tests/${AMBER_TEST_NAME}.S"
    	pushd ../tests > /dev/null
    	make --quiet TEST=${AMBER_TEST_NAME}
    	MAKE_STATUS=$?
        
    	popd > /dev/null
    	BOOT_MEM_FILE="../tests/${AMBER_TEST_NAME}.mem"
fi

./activate_trojan "$BOOT_MEM_FILE"


