#!/bin/bash
# disable touchpad wakeup
echo disabled > "/sys/devices/platform/AMDI0010:00/i2c-0/i2c-SYNA30DC:00/power/wakeup"

children() { for f in /proc/$1/task/*/children;do l=""; [ -r $f ] &&read l<$f;for p in $l;do echo $p; children $p; done; done; }
pid_to_name() {
    ps -p $1 -o comm=
}
dir="$(dirname "$BASH_SOURCE")"
ignore=`cat $dir/ignore.txt`
do_list="$(cat $dir/do.txt)"
to_stop=""
for parent in $do_list; do
	parent_pid=`pidof $parent`
	if [ ! -z "$parent_pid" ] && [ "$parent_pid" != "$$" ]; then
		to_stop_add=`children $parent_pid`
		to_stop="$to_stop $to_stop_add $parent_pid"
	fi
done
high_cpu=`ps -o %cpu,pid | awk '$1 >= 10 {print $2}'`
to_stop="$to_stop $high_cpu"

stopped=""
echo "About to pause processes"
for p in $to_stop; do
    name=`pid_to_name $p`
    is_ignored=false
    for i in $ignore; do
        if [[ ${name} == *"$i"* ]]; then
            is_ignored=true
        fi
    done
    if [ "$is_ignored" = true ]; then
        continue
    fi
    echo "Pausing $name"
    kill -STOP $p
    stopped="$stopped $p"
done



echo "$stopped" > $dir/stopped.txt
prev=""
prev_p=""
for c in /sys/devices/system/cpu/cpufreq/policy*; do
	c_prev=`cat $c/scaling_governor`
    if [[ $? -eq 0 ]]; then
        prev="$prev $c_prev"
        echo powersave > $c/scaling_governor
        
        p_prev=`cat $c/energy_performance_preference`
        prev_p="$prev_p $p_prev"
        echo power > $c/energy_performance_preference
    fi
done

echo "$prev" > $dir/prev_c.txt
echo "$prev_p" > $dir/prev_p.txt

online=""
# Disable all CPU cores except for 0
for c in /sys/devices/system/cpu/cpu*/online; do
    if [ `cat $c` == "1" ]; then
        online="$online $c"
    fi
    if [ "$c" != "/sys/devices/system/cpu/cpu0/online" ]; then
        echo 0 > "$c"
    fi
done
echo "$online" > $dir/online.txt