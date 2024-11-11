nodes add/decommission/replace is every common in cassandra. An FAQ is how  
bootstrap/unbootstrap progess is going, what's ETA, etc. 

Cassandra has a built-in nodetool netstats to show where the data came from or sent to in files level, but its output
is way to long for big cluster. 

Here is a simple script to parse and format nodetool netstats output to make it more readable, calculate progress.

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


The output like this:

[slcdbx1447.slc.ebay.com] out: sudo password:
[slcdbx1447.slc.ebay.com] out: Operation                                               Direction       IP                Total (MB)  Transferred         Left          Pct      Files   F_transferred
[slcdbx1447.slc.ebay.com] out: Bootstrap f3bdf7b0-961d-11e6-892b-055c0ea6b20d          received_from   10.89.137.110        49683.3      45370.6       4312.7        91.32        569             484
[slcdbx1447.slc.ebay.com] out: Bootstrap f3bdf7b0-961d-11e6-892b-055c0ea6b20d          received_from   10.89.144.42         54887.3      45266.3       9621.0        82.47        588             437
[slcdbx1447.slc.ebay.com] out: Bootstrap f3bdf7b0-961d-11e6-892b-055c0ea6b20d          received_from   10.89.137.198        48608.7      46504.9       2103.7        95.67        546             502
[slcdbx1447.slc.ebay.com] out: Bootstrap f3bdf7b0-961d-11e6-892b-055c0ea6b20d          received_from   10.89.144.44         48748.9      46100.1       2648.9        94.57        516             468
[slcdbx1447.slc.ebay.com] out: Bootstrap f3bdf7b0-961d-11e6-892b-055c0ea6b20d          received_from   10.89.137.206        58795.2      46777.2      12018.0        79.56        605             438
[slcdbx1447.slc.ebay.com] out: ========                                                ======          total               260723.4     230019.1      30704.3        88.22       2824            2329
[slcdbx1447.slc.ebay.com] out:
