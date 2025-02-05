#!/bin/bash
dir="$(dirname "$BASH_SOURCE")"
# Enable all CPU cores
online="$(cat $dir/online.txt)"
for c in $online; do
	echo 1 > "$c"
done

echo "About to unpause processes"
stopped=`cat $dir/stopped.txt`

for p in $stopped; do
	echo "Unpausing $p" 
    kill -CONT $p
done

prev_p=`cat $dir/prev_p.txt`
prev_c=`cat $dir/prev_c.txt`
c=0
for p in $prev_c; do
	echo $p > /sys/devices/system/cpu/cpufreq/policy$c/scaling_governor
	c=$((c+1))
done

c=0
for p in $prev_p; do
	echo $p > /sys/devices/system/cpu/cpufreq/policy$c/energy_performance_preference
	c=$((c+1))
done