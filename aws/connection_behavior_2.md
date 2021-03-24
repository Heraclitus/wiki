# Chapter 2: The puzzling and herculean troubleshooting of a complex system
In [ch.1](./connection_behavior.md) of this saga you got the basic setup of the system and the issues experienced. Now we will explore how we started to turn a corner for the better. We left part 1 with sometimes daily HTTP 5xx errors that we could only stop by throttling (HTTP 429) down to very low levels and then slowly building back up to normal levels.

# The old database
A common feature of these outages was a crippled DB <img src="https://github.com/Heraclitus/wiki/blob/master/aws/crippled-db.jpg" height="400"/>
This system had an old version of MySQL (5.6). For various reasons the team was not able to prioritize upgrading. 
