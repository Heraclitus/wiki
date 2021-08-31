# Chapter 2: The puzzling and herculean troubleshooting of a complex system
In [ch.1](./connection_behavior.md) of this saga you got the basic setup of the system and the issues experienced. Now we will explore how we started to turn a corner for the better. We left part 1 with sometimes daily HTTP 5xx errors that we could only stop by throttling (HTTP 429) down to very low levels and then slowly building back up to normal levels.

# The old database
A common feature of these outages was a crippled DB <img src="https://github.com/Heraclitus/wiki/blob/master/aws/crippled-db.jpg" height="200"/>

We lived with these events, sometimes multiple times a day. This system had an old version of MySQL (5.6). For various reasons the team was not able to prioritize upgrading. We never could prove that the DB was the leading cause of the outages but we knew that a DB at over 75% utilization wasn't a good thing and we knew that MySQL 8.0 was going at the very least behave better under these conditions then 5.6

## Our first corner turned. 
After upgrading to 8.0 we never had to throttle down and back up. **Did we solve the problem?** Well in a sense it solved the major issue for the client. We no longer failed our SLA's for error rate. But the story doesn't end here.

# New problems, Old problems ...
1. Fequent DB connection spikes **(NEW)**
2. Attempt to fix the first problem, lead to maxing out our DB's maximum prepared statement count **(NEW)**
3. A bug with prepared statement is found! **(NEW)**
4. Very lumpy request distribution **(OLD)**
5. To many DB calls **(OLD)**


## Frequent DB Connection Spikes
<img src="https://github.com/Heraclitus/wiki/blob/master/aws/frequent-db-connection-spikes.jpg" height="200"/>
Our application server is written in NodeJS and using Sequelize ORM library. Sequelize uses a connection pooling library called Sequelize-pool. For reasons that are still a mystery the connections counts flucuate drammaticly. The Sequelize-pool library is fairly straight forward pool implementation with 5 configurations. Min/Max/Idle-Timeout/ReapInterval/AcquireTimeout. From reading the ~500 lines of code it's not clear why the dramatic fluctuations would be happening.  

One theory was our "Lumpy request distribution" which resolving didn't end up fixing the issue.

## Maximum Prepared Statement Count
In an attempt to reduce spikes in the DB connections we tried lifting the Sequelize-pool min connection to nearly match its max value. We caused an outage because of our DB's max prepared connection count being breached.  **Why?**
It turns out that Sequelize depends on mysql2 library. That library constructs an LRU cache per connection with 16K max prepared statments. Since each NodeJS instance was allowed 20 connections max, 17 min our connections were kept open longer and prepared statements are kept open for the lifetime of those connections. So the breaching on the DB side was inevitable.  

During investigation we discovered some queries that had broken parameterization and created a cardinality explosion of prepared statements. This also contributed to reaching the DB maximum constraint. 

## Very lumpy request distribution
<img src="https://github.com/Heraclitus/wiki/blob/master/aws/lumpy-nlb.jpg" height="200"/>
AWS is very clear that you should expect uneven distributions if you are using longlived connections https://aws.amazon.com/premiumsupport/knowledge-center/elb-fix-unequal-traffic-routing/
<img src="https://github.com/Heraclitus/wiki/blob/master/aws/aws-lb-lumpy.png" height="100"/>
We swapped out the NLB for an ALB and had a drammatic improvement in distribution of requests per node. This had the benifit of reducing latency avg by about 10%. Our connection spikes did not change. 

# So now what???
At this point in the story we have...
1. A happier customer, no more 5xx.
2. High AWS costs $$$ due to our attempts to out-scale the problems
4. Better DB behavior
5. New problems that were probably contributing to the outages prior to the DB upgrade.

The story isn't over. We still need to 
1. Fix our broken prepared statements
2. Figure out how to size the connection/prepared-statement/db-max-prepared-statement limits without causing outages
3. Reduce the fleet costs without causing 5xx
4. Reduce the App's reliance on the DB with caching strategies using Redis cache
5. Avoid overwhelming the Redis cache and causing 5xx


