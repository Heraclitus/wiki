# Chapter 2: The puzzling and herculean troubleshooting of a complex system
In [ch.1](./connection_behavior.md) of this saga you got the basic setup of the system and the issues experienced. Now we will explore how we started to turn a corner for the better. We left part 1 with sometimes daily HTTP 5xx errors that we could only stop by throttling (HTTP 429) down to very low levels and then slowly building back up to normal levels.

# The old database
A common feature of these outages was a crippled DB <img src="https://github.com/Heraclitus/wiki/blob/master/aws/crippled-db.jpg" height="400"/>

We lived with these events, sometimes multiple times a day. This system had an old version of MySQL (5.6). For various reasons the team was not able to prioritize upgrading. We never could prove that the DB was the leading cause of the outages but we knew that a DB at over %75 utilization wasn't a good thing and we knew that MySQL 8.0 was going at the very least behave better under these conditions then 5.6

## Our first corner turned. 
After upgrading to 8.0 we never had to throttle down and back up. **Did we solve the problem?** Well in a sense it solved the major issue for the client. We no longer failed our SLA's for error rate. But the story doesn't end here.

# New problems, Old problems ...
1. Fequent DB connection spikes (NEW) <img src="https://github.com/Heraclitus/wiki/blob/master/aws/frequent-db-connection-spikes.jpg" height="400"/>
3. Very lumpy request distribution (OLD) <img src="https://github.com/Heraclitus/wiki/blob/master/aws/lumpy-nlb.jpg" height="400"/>




