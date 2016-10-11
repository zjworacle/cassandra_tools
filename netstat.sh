It's very command task to add/decommission/replace nodes in cassandra. Frequently asked question in operation is how  
bootstrap/unbootstrap progess is going, what the ETA is, etc. 

Cassandra has a built-in nodetool netstats to show where the data came from or sent to in files level, but its output is way to long
for big cluster. 

Here is a simple to format the nodetool netstats output to make it more readable, mostly help output the progress so far.

