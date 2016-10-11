It's very command task to add/decommission/replace nodes in cassandra. Frequently asked question in operation is how  
bootstrap/unbootstrap progess is going, what the ETA is, etc. 

Cassandra has a built-in nodetool netstats to show where the data came from or sent to in files level, but its output
is way to long for big cluster. 

Here is a simple shell/AWK script to parse/format nodetool netstats output to make it more readable, most importantly
calculate progress.


#!/bin/bash
# Jinwen Zou 08/10/2016 started the initial version
cd /tmp; /opt/dse/bin/nodetool netstats > raw.txt
(
cat raw.txt|awk '
BEGIN{
    gtotal=0
    gso_far=0
    format="%55-s %15-s %15-s %12s %12s %12s %12s %10s %15s\n"
    printf (format, "Operation", "Direction", "IP", "Total (MB)", "Transferred", "Left", "Pct", "Files", "F_transferred")
    format="%55-s %15-s %15-s %12.1f %12.1f %12.1f %12.2f %10d %15d\n"
}

/^Repair/ || /^Unbootstrap/ || /^\w/ {
    if (total > 0 && ip ~ /^10./){
        printf (format, command, direction, ip, total/1024/1024, so_far/1024/1024,  (total-so_far)/1024/1024, so_far/total*100, total_files, files)
        gtotal=gtotal+total
        gso_far=gso_far + so_far
        gtotal_files=gtotal_files + total_files
        gfiles=gfiles + files
    }
    command = $0
    #print command
    total=$4
    so_far=0
    direction=$4
    files=0
    ip=""
}
/ Receiving / || / Sending /{
    if (total > 0 && ip ~ /^10./){
        printf (format, command, direction, ip, total/1024/1024, so_far/1024/1024,  (total-so_far)/1024/1024, so_far/total*100, total_files, files)
        gtotal=gtotal+total
        gso_far=gso_far + so_far
        gtotal_files=gtotal_files + total_files
        gfiles=gfiles + files
    }
    total=$4
    so_far=0
    total_files=$2
    files=0
    ip=""
}
/received from/ || / sent to /{
    split($2,a, "/")
    so_far=so_far + a[1]
    direction=$4 "_" $5
    files=files + 1
    ip=$6;
    sub("/", "", ip)
}
END{
    if (total > 0 && ip ~ /^10./){
        printf (format, command, direction, ip, total/1024/1024, so_far/1024/1024,  (total-so_far)/1024/1024, so_far/total*100, total_files, files)
        gtotal=gtotal+total
        gso_far=gso_far + so_far
        gtotal_files=gtotal_files + total_files
        gfiles=gfiles + files
    }
    if (gtotal > 0) printf (format,"========","======","total",  gtotal/1024/1024, gso_far/1024/1024,  (gtotal - gso_far)/1024/1024, gso_far/gtotal*100, gtotal_files, gfiles)
}
'
) | tee formatted.txt
