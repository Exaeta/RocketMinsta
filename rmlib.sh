#!/bin/bash

if [ -z $INCLUDE ]; then
    echo "This is not a script." >&2
    exit 1
fi

function error
{
    echo -e "\n$*" >&2
    exit 1
}

function getqcc
{
    local i=0
    local qcc=""

    echo "Looking for a QuakeC compiller" >&2

    while true; do
        qcc="${QCC[$i]}"

        [ x"$qcc" = x ] && error "Failed to find a QuakeC compiller"

        echo -n " -- Trying $qcc... " >&2
        which "$qcc" &>/dev/null && break

        echo -e "\e[31;1mmissing\e[0m" >&2
        let i++
    done

    echo -e "\e[32;1mfound\e[0m" >&2
    echo "$qcc"
}

function buildqc
{
    qcdir="$QCSOURCE/$1"

    echo " -- Building $qcdir" >&2
    pushd "$qcdir" &>/dev/null || error "Build target does not exist? huh"
    $USEQCC $QCCFLAGS || error "Failed to build $qcdir"
    popd &>/dev/null
}

function rconopen
{
    RCON_ADDRESS="$1"
    RCON_PORT="$2"
    RCON_PASSWORD="$3"
}

function rconsend
{
    echo " --:> $1"
    printf "\377\377\377\377rcon %s %s" $RCON_PASSWORD "$1" > /dev/udp/$RCON_ADDRESS/$RCON_PORT
}

function rconsendto
{
    echo " --:> $1"
    printf "\377\377\377\377rcon %s %s" "$3" "$4" > /dev/udp/"$1"/"$2"
}
