#!/bin/bash
#
# Script to make a proxy (ie HAProxy) capable of monitoring Replication Heartbeats from pt-heartbeat
#

# if [[ $1 == '-h' || $1 == '--help' ]];then
#     echo "Usage: $0 <user> <pass> <available_when_donor=0|1> <log_file> <available_when_readonly=0|1> <defaults_extra_file>"
#     exit
# fi

function parseHeartbeat {
    export CURRENT_HEARTBEAT=$1;
    export ONE_MINUTE_HEARTBEAT=$2;
    export FIVE_MINUTE_HEARTBEAT=$3;
    export FIFTEEN_MINUTE_HEARTBEAT=$4;
}

# if the disabled file is present, return 503. This allows
# admins to manually remove a node from a cluster easily.
if [ -e "/var/tmp/heartbeat.disabled" ]; then
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 51\r\n"
    echo -en "\r\n"
    echo -en "Heartbeat is manually disabled.\r\n"
    sleep 0.1
    exit 1
fi

set -e

ERR_FILE="${ERR_FILE:-/dev/null}"

if [ ! -f /home/repl-monitor/heartbeat ]; then
    # Heartbeat file not found
    # => return HTTP 503
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 54\r\n"
    echo -en "\r\n"
    echo -en "Heartbeat file not found - is heartbeat job running?\r\n"
    sleep 0.1
    exit 1
fi;

parseHeartbeat `cat /home/repl-monitor/heartbeat | sed 's/[][s, ]/ /g'`;

# echo $CURRENT_HEARTBEAT;
# echo $ONE_MINUTE_HEARTBEAT;
# echo $FIVE_MINUTE_HEARTBEAT;
# echo $FIFTEEN_MINUTE_HEARTBEAT;

if (( `echo "$CURRENT_HEARTBEAT > 10" | bc -l` )); then
    # Current heartbeat exceeds 10s
    # => return HTTP 503
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 31\r\n"
    echo -en "\r\n"
    echo -en "Current heartbeat exceeds 10s\r\n"
    sleep 0.1
    exit 1;
fi;


if (( `echo "$ONE_MINUTE_HEARTBEAT > 8" | bc -l` )); then
    # One-minute average heartbeat exceeds 8s
    # => return HTTP 503
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 42\r\n"
    echo -en "\r\n"
    echo -en "One-minute average heartbeat exceeds 20s\r\n"
    sleep 0.1
    exit 1;
fi;


if (( `echo "$FIVE_MINUTE_HEARTBEAT > 6" | bc -l` )); then
    # Five-minute average heartbeat exceeds 6s
    # => return HTTP 503
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 42\r\n"
    echo -en "\r\n"
    echo -en "Five-minute average heartbeat exceeds 60s\r\n"
    sleep 0.1
    exit 1;
fi;


if (( `echo "$FIFTEEN_MINUTE_HEARTBEAT > 4" | bc -l` )); then
    # Fifteen-minute average heartbeat exceeds 4s
    # => return HTTP 503
    # Shell return-code is 1
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 45\r\n"
    echo -en "\r\n"
    echo -en "Fifteen-minute average heartbeat exceeds 4s\r\n"
    sleep 0.1
    exit 1;
fi;

# Percona XtraDB Cluster node local state is 'Synced' => return HTTP 200
# Shell return-code is 0
echo -en "HTTP/1.1 200 OK\r\n"
echo -en "Content-Type: text/plain\r\n"
echo -en "Connection: close\r\n"
echo -en "Content-Length: 31\r\n"
echo -en "\r\n"
echo -en "Heartbeat is within tolerance\r\n"
sleep 0.1
exit 0
