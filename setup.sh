#!/bin/bash

mproto="mrouted"
mproto="pimd"

stem="net"
fanout=2

function buildns {
	local base=$1
	local depth=$2
	local level=$3
	local cnt=$4
	
	$STEP ip netns del ${stem}${base}${cnt} &> /dev/null
	$STEP ip netns add ${stem}${base}${cnt}

	$STEP ip netns exec ${stem}${base}${cnt} ip link set lo up
	$STEP ip link add down-${base}${cnt} link edown type vlan id ${base}${cnt}
	$STEP ip link set down-${base}${cnt} netns ${stem}${base} up

	$STEP ip link add up-${base}${cnt} link eup type vlan id ${base}${cnt}
	$STEP ip link set up-${base}${cnt} netns ${stem}${base}${cnt} up
	$STEP ip netns exec ${stem}${base}${cnt} ip addr add 192.168.${base}${cnt}.2/30 dev up-${base}${cnt}
	$STEP ip netns exec ${stem}${base} ip addr add 192.168.${base}${cnt}.1/30 dev down-${base}${cnt}
	$STEP ip netns exec ${stem}${base}${cnt} ip route add default via 192.168.${base}${cnt}.1 dev up-${base}${cnt}


	$STEP echo -e "hostname $stem$base$cnt\npassword zebra\nlog stdout\nrouter rip\n" >/tmp/ripd-${base}${cnt}
	$STEP echo -e " network up-${base}${cnt}\n" >>/tmp/ripd-${base}${cnt}
	$STEP echo -e " network down-${base}${cnt}\n" >>/tmp/ripd-${base}
	$STEP cp zebra.conf /tmp/zebra-${base}${cnt}
	$STEP cp pimd.conf /tmp/pimd-${base}${cnt}
	$STEP cp mrouted.conf /tmp/mrouted-${base}${cnt}
	$STEP sed -e "/host-name/s/net/$stem$base$cnt/" avahi-daemon.conf > /tmp/avahi-${base}${cnt}

}

function routers { 
	local base=$1
	local depth=$2
	local level=$3
	local cnt=$4
	
	$STEP ip netns exec ${stem}${base}${cnt} zebra -d -f /tmp/zebra-${base}${cnt} -i /tmp/zebra-pid-${base}${cnt}
	$STEP ip netns exec ${stem}${base}${cnt} ripd -d -f /tmp/ripd-${base}${cnt} -i /tmp/ripd-pid-${base}${cnt}
	$STEP ip netns exec ${stem}${base}${cnt} ./p${mproto} ${base}${cnt} 
}
function hosts { 
	local base=$1
	local depth=$2
	local level=$3
	local cnt=$4

	if [ $depth -ne $level ]; then return ; fi	
	$STEP ip netns exec ${stem}${base}${cnt} ./pavahi ${base}${cnt} 
}

function recurse {
	local cmd=$1
	local depth=$2
	local base=$3
	local level=$4
	local cnt=0
	
	if [ $level -gt $depth ] ; then return ; fi

	for cnt in $(seq $fanout); do
		"$cmd" "$base" "$depth" "$level" "$cnt"	
		echo "BASE CALL $cmd $depth $base $cnt $level"
               recurse "$cmd" "$depth" "${base}${cnt}" "$(($level+1))"
		echo "BASE RETN $cmd $depth $base $cnt $level"
	done
}

function stop_sim {
	$STEP rm -f /tmp/rip*d-*
	$STEP rm -f /tmp/zebra*d-*
	$STEP rm -f /tmp/pim*d-*
	$STEP rm -f /tmp/avahi-*
	$STEP killall avahi-daemon
	$STEP killall ripd
	$STEP killall zebra 
	$STEP killall pimd 
	$STEP killall mrouted 
	$STEP killall mcast.py 
	$STEP iptables -t nat -D POSTROUTING -s 192.168.77.1/30 -j MASQUERADE
	$STEP ip link del eup &> /dev/null
	$STEP ip link del edown &> /dev/null
	for net in $(cat nets); do
		$STEP ip netns del $net
	done
}




if [ $# -eq 0 ]; then
	stop_sim
	exit
else
	case "$1" in
		p*) mproto=pimd ;;
		m*) mproto=mrouted ;;
		*)  STEP=echo;;
	esac
fi



$STEP ip link add eup type veth peer name edown
$STEP ip link set eup up
$STEP ip link set edown up
$STEP ip netns del $stem
$STEP ip netns add $stem
$STEP ip link add $stem-up link eup type vlan id 777
$STEP ip link add $stem-down link edown type vlan id 777

$STEP ip link set $stem-up netns  $stem multicast off  up
$STEP ip link set $stem-down up
$STEP ip addr add 192.168.77.1/30 dev $stem-down

$STEP iptables -t nat -A POSTROUTING -s 192.168.77.1/30 -j MASQUERADE
$STEP ip netns exec $stem ip addr add 192.168.77.2/30 dev $stem-up
$STEP ip netns exec $stem ip route add default via  192.168.77.1 dev $stem-up
$STEP ip netns exec $stem iptables -t nat -A POSTROUTING -o $stem-up -j MASQUERADE

$STEP cp zebra.conf /tmp/zebra-
$STEP echo -e "hostname $stem$base$cnt\npassword zebra\nlog stdout\nrouter rip\n" >/tmp/ripd-

recurse buildns 2 ""  0 
#recurse routers 1 ""  0 

$STEP ip netns exec $stem ip route add 224.0.0.0/4 dev down-1 metric 1
$STEP ip netns exec $stem ip route add 224.0.0.0/4 dev down-2 metric 2
$STEP ip netns exec ${stem} zebra -d -f /tmp/zebra- -i /tmp/zebra-pid-
$STEP ip netns exec ${stem} ripd -d -f /tmp/ripd- -i /tmp/ripd-pid-
$STEP ip netns exec ${stem} ./p${mproto}

recurse routers 1 ""  0 
recurse hosts 2 ""  0 


