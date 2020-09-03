#!/bin/bash

# control SNAP chassis power. Can only turn on/off entire chassis which
# holds 10 SNAP boards.

# A Raspberry Pi host. login using: ssh pi@powersnap.ant.pvt
RELAY_HOST="powersnap.ant.pvt"
RELAY_HOST_PORT=9696
NUM_CHASSIS=4
TOGGLE_TIME_SEC=5
# 8 boards can be stacked on each other allowing 64 total relays. Must
# have a powersupply able to source needed current for all relays engaged.
# Note: this software needs to be expanded to add a map for multiple boards.
BRD=0

function usage() {
    echo "Usage: powersnap [chassis No] [on|off|toggle]"
    echo "To turn power off on chassis 1:"
    echo "powersnap 1 off"
    echo "To turn toggle power on all chassis:"
    echo "powersnap 0 toggle"
    exit 1
}

function off() {
    brd=$1
    relay=$2
    echo "`date`: Turning Brd $brd relay $relay OFF"
    curl -d "{\"brd\": $brd, \"relays\": [{\"id\": $relay, \"state\": false}]}" http://$RELAY_HOST:$RELAY_HOST_PORT/jcmd
}

function on() {
    brd=$1
    relay=$2
    echo "`date`: Turning Brd $brd relay $relay ON"
    curl -d "{\"brd\": $brd, \"relays\": [{\"id\": $relay, \"state\": true}]}" http://$RELAY_HOST:$RELAY_HOST_PORT/jcmd
}

function toggle() {
    brd=$1
    relay=$2
    time=$3

    off $brd $relay
    sleep $time
    on $brd $relay
}

function allOff() {
    brd=$1
    for i in {1..$NUM_CHASSIS}; do
        off $brd $i
    done
}

function run() {
    chassis=$1
    cmd=$2
    if [[ "$chassis" == "0" ]]; then
        for ii in `seq 1 $NUM_CHASSIS`; do
	    $cmd $BRD $ii $TOGGLE_TIME_SEC
        done
    else
        $cmd $BRD $chassis $TOGGLE_TIME_SEC
    fi
}

#======== main ============

if [[ $# -ne 2 ]]; then
    echo "Wrong number of arguments" >&2
    usage
fi

# Usage: powersnap [chassis No] [on|off|toggle]"
chassis=$1
cmd=$2

if [[ $chassis -lt 0 || $chassis -gt NUM_CHASSIS ]]; then
    echo "Chassis number must be 0-$NUM_CHASSIS inclusive" >&2
    exit 1
fi

if [[ "$cmd" != "on" && "$cmd" != "off" && "$cmd" != "toggle" ]]; then
    echo "Unknown command" >&2
    usage
fi

run $chassis $cmd

