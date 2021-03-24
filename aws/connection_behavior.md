# The puzzling and herculean troubleshooting of a complex system
This is the opening chapter in a saga on a multi-month problem that I was involved in for a large customer using our AWS cloud hosted services. See the second chapter to see how we turned a corner. 

# System Story
Our system is serving millions of clients on the public internet on a mixture of platforms including IPhone, Android and embedded devices. These clients call into our AWS backend architecture for serving of REST API calls. Our client trend peaks can be as high as 4,000 RPS (Requests Per Second) and trough around 1,300 RPS. Noon is high water mark and midnight is our low. 

## Problem Landscape
We started experienceing massive failure rates (HTTP 5xx status codes). Days would go by without witnessing any significant failures and other days we'd see two or three failure events. Our typical response during an outage was to throttle traffic (causing 429 errors) until our internal request pipeline cleared out it's backlogs and then we would ease back off the throttling until we reached a steady state. These recovery actions would take 20-50 mins. Sometimes we'd have to dial the throttling back down because the system would get backed up again. We observed tremendous spikes in TCP connections and system latency would increase. Recovery throttling on the API-GW was down to as low as 50 RPS throttling. 

# High Level Architecture

```
|---------------------| |-----------| |------|  |---|  |---------------|  |---------|
|Customer-REST-Client => CloudFront => API-GW => NLB => EC2-TargetGroup => RDS-MYSQL
|---------------------| |-----------| |------|  |---|  |---------------|  |---------|
```
Each EC2 instance had the following ...
```
 |-------------------------|  |----------------------------|  |---------------|  |----------|  |--------|
 Port 80 (Traffic Port)     => L4 Connection queue (Golang) => NGINX(port8080) => NODEJS-APP => RDS-MYSQL
 |--------------------------| |----------------------------|  |---------------|  |----------|  |--------|
 |--------------------------| |-----------------------------------------------|  |----------|
 Port 8080 (Alive-Check)    => NGINX ......................................... => NODEJS-APP
 |--------------------------| |-----------------------------------------------|  |----------|
```
## Configuration
The L4 connection queue had a limit of 15 active TCP connections it allowed to send/rcv packets on. Any additional TCP connection request would be accepted but placed on a queue and no read/write was done on those queued connections. 

our NGINX configuration has a default 75 second http keepalive setting and default keepalive_requests of 100

An example of the spikes as viewed from the NLB looks like <img src="https://github.com/Heraclitus/wiki/blob/master/aws/ConnectionSpikeExample.jpg" height="400"/>

# Troubleshooting process
Typically you would start by thinking of the two ends; CloudFront & RDS.  Did we get a huge rush of customer traffic? Did we get a DB related slow down? What about third-party APIs?

in 29 days we counted 
1. **33 events** w/associated RDS MySQL spikes & NLB spikes
1. **8 events** w/out RDS MySQL spikes & NLB spikes
1. **0 events** w/increased CloudFrount request count

Below you can see that request count measured at CloudFront is relatively stable the two primary CloudFront distributions that clients use (Mobile + Embedded). It actually dips down during the spike and recovers higher afterwards. <img src="https://github.com/Heraclitus/wiki/blob/master/aws/NoSpikeInFrontEnd.jpg" height="400"/>

So a spike due to incomming traffic was **NOT** the cause.

An example of the DB spikes can be seen here.  
<img src="https://github.com/Heraclitus/wiki/blob/master/aws/DBGraph.jpg" height="400"/>

**How about third party calls?**
Nope, statistical analysis of our thirdparty calls didn't explain the latencies and were not abnormally high.

# Why so challenging?
1. The smallest granularity of many AWS metrics is 1 minute and that makes identifying leading indicators very difficult.
2. Complex system that allowed for lots of competing theories amongst collueges with strong opinions. We tried hard to blame the NLB :) 
3. Slow pace of expiramentation. We lacked a proper performance testing environment that could simulate our expiraments.
4. Our customers were very sensitive to change.
5. RDS monitoring is minimal compared to what we eventually added (PMM - https://www.percona.com/software/database-tools/percona-monitoring-and-management)


# Resolution?
Not in this chapter. We did gane some important insights.

Two key learnings. One was fixing our understanding of how long lived connections were working between API-GW and our connection throttling software. The other was realizing a flaw in our approach to connection throttling upstream of the API-GW. Below I dig into each.

## Mistaken Understanding
The following sequence diagram shows the basic architecture that was tested. 

__FALSE ASSUMPTION:__ 1 client TCP connection will only ever result in 1 TCP conneciton at all levels of the pipeline

This assumption leads us to believe that the following happens...
<img src="https://github.com/Heraclitus/wiki/blob/master/aws/mistaken.png" height="400"/>


### Actual Behavior

API Gateway doesn't garantee that it's internal operation will consistently link the long-lived client connection with the same long-lived backend connection to the NLB. As a result you can see several NLB "flow" counts for a single repeating client using long-lived HTTP connections.

__NOTE__ the diagram suggests that each request results in a distinct connection on it's "backend" that is a simplification for diagraming and explaining. In actual fact you may or may not get a pre-existing connection. 
<img src="https://github.com/Heraclitus/wiki/blob/master/aws/actual.png" height="400"/>

![Video Of Connection Behavior](./connection-behavior.mp4)


## Raw Diagrams

### Mistaken
```
@startuml
participant JMETER
participant APIGW
participant NLB
box "You think the same TCP conn gets used"
participant EC2
participant ConnCtrl
participant NGINX
end box

== 1st request ==
JMETER -> APIGW : 1 TCP conn.
APIGW -> NLB : 1 TCP conn.
NLB -> EC2 : 1 TCP connection
EC2 -> ConnCtrl : 1 TCP conn.
ConnCtrl -> NGINX : 1 TCP conn.
ConnCtrl <- NGINX
EC2 <- ConnCtrl
NLB <- EC2
APIGW <- NLB
JMETER <- APIGW
== 2nd request ==
JMETER -> APIGW : 1 TCP conn.
APIGW -> NLB : 1 TCP conn.
NLB -> EC2 : 1 TCP connection
EC2 -> ConnCtrl : 1 TCP conn.
ConnCtrl -> NGINX : 1 TCP conn.
ConnCtrl <- NGINX
EC2 <- ConnCtrl
NLB <- EC2
APIGW <- NLB
JMETER <- APIGW
== 3rd request ==
JMETER -> APIGW : 1 TCP conn.
APIGW -> NLB : 1 TCP conn.
NLB -> EC2 : 1 TCP connection
EC2 -> ConnCtrl : 1 TCP conn.
ConnCtrl -> NGINX : 1 TCP conn.
ConnCtrl <- NGINX
EC2 <- ConnCtrl
NLB <- EC2
APIGW <- NLB
JMETER <- APIGW
@enduml
```

### Actual
```
@startuml
participant JMETER
participant APIGW
participant NLB
participant EC2
participant ConnCtrl
participant NGINX

== 1st request ==
JMETER -> APIGW : 1 TCP conn.
APIGW -> NLB : 1 TCP conn.
NLB -> EC2 : 1 TCP connection
EC2 -> ConnCtrl : 1 TCP conn.
ConnCtrl -> NGINX : 1 TCP conn.
ConnCtrl <- NGINX
EC2 <- ConnCtrl
NLB <- EC2
APIGW <- NLB
JMETER <- APIGW
== 2nd request ==
JMETER -> APIGW : 1 TCP conn.
APIGW -> NLB : **2 TCP conn.**
NLB -> EC2 : 2 TCP connection
EC2 -> ConnCtrl : 2 TCP conn.
ConnCtrl -> NGINX : 2 TCP conn.
ConnCtrl <- NGINX
EC2 <- ConnCtrl
NLB <- EC2
APIGW <- NLB
JMETER <- APIGW
== 3rd request ==
JMETER -> APIGW : 3 TCP conn.
APIGW -> NLB : **3 TCP conn.**
NLB -> EC2 : 3 TCP connection
EC2 -> ConnCtrl : 3 TCP conn.
ConnCtrl -> NGINX : 3 TCP conn.
ConnCtrl <- NGINX
EC2 <- ConnCtrl
NLB <- EC2
APIGW <- NLB
JMETER <- APIGW
@enduml
```

## Flaw in Connection throttling
At root the flaw is asymetrical knowledge. On one side you have API-GW holding many TCP connections and believing they are all equally valid and useful. On the other side you have these connection throttling instances on EC2 nodes designating certain connections as **golden** connections which have priority while other connections are queued.  One side knows something the other does not. API-GW can't effectively optimize which connections it sends requests on. 

It's important to point out that the NLB really is quite simple in it's basic construction and should be removed from our thinking about the problem.

NLB is basically a hashed-ledger table to descide how to route packets

**properties:**
1. CLIENT-INITIATED: TCP connection negotiation w/NLB is required before entry is created
2. SERVER-ACCEPTED: an entry can't exist without an EC2 instance and negotiation of a TCP socket
3. DURABLE: all subsequent packets with matching src/dst characteristics are passed along to the DST EC2 ip/port
4. NON-TRANSFERABLE: C's packet traffic to 2.3.2.2 :84 never goes to 2.2.2.2:89 or 2.3.4.3:1000 under any circumstances.

<table class="wrapped relative-table confluenceTable" data-resize-percent="77.20651242502143"><colgroup><col style="width: 8.66667%;" data-resize-pixel="78" data-resize-percent="8.666666666666668" data-offset-left="40" data-offset-right="118" /><col style="width: 12.5556%;" data-resize-pixel="113" data-resize-percent="12.555555555555555" data-offset-left="118" data-offset-right="231" /><col style="width: 15.8889%;" data-resize-pixel="143" data-resize-percent="15.88888888888889" data-offset-left="231" data-offset-right="374" /><col style="width: 19.5556%;" data-resize-pixel="176" data-resize-percent="19.555555555555557" data-offset-left="374" data-offset-right="550" /><col style="width: 12.4444%;" data-resize-pixel="112" data-resize-percent="12.444444444444445" data-offset-left="550" data-offset-right="662" /><col style="width: 14.3333%;" data-resize-pixel="129" data-resize-percent="14.333333333333334" data-offset-left="662" data-offset-right="791" /><col style="width: 16.5556%;" data-resize-pixel="149" data-resize-percent="16.555555555555557" data-offset-left="791" data-offset-right="940" /></colgroup><tbody><tr><th class="confluenceTh" colspan="1">NLB HashKey</th><th class="confluenceTh">SRC IP: Port</th><th class="confluenceTh" colspan="1">NLB CLIENT SIDE IP:PORT</th><th class="confluenceTh">EC2 DST IP :Port</th><th class="confluenceTh" colspan="1">NOT IN TABLE-&gt;</th><th class="confluenceTh" colspan="1">Connection Throttle</th><th class="confluenceTh" colspan="1">CHANGE</th></tr><tr><td class="confluenceTd" colspan="1">A</td><td class="highlight-#57d9a3 confluenceTd" title="Background colour : Medium green 65%" data-highlight-colour="#57d9a3">1.1.1.1 :80</td><td class="highlight-#57d9a3 confluenceTd" title="Background colour : Medium green 65%" colspan="1" data-highlight-colour="#57d9a3">4.3.3.3 :222</td><td class="confluenceTd">2.2.2.2 :89</td><th class="confluenceTh" colspan="1"><br /></th><td class="confluenceTd" colspan="1">HAS RUN SLOT</td><td class="confluenceTd" colspan="1">WAS 80% of traffic</td></tr><tr><td class="confluenceTd" colspan="1">B</td><td class="highlight-#57d9a3 confluenceTd" title="Background colour : Medium green 65%" data-highlight-colour="#57d9a3">1.2.1.1 :1000</td><td class="highlight-#57d9a3 confluenceTd" title="Background colour : Medium green 65%" colspan="1" data-highlight-colour="#57d9a3">4.3.3.5 :322</td><td class="confluenceTd">2.3.4.3 :1000</td><th class="confluenceTh" colspan="1"><br /></th><td class="confluenceTd" colspan="1">HAS RUN SLOT</td><td class="confluenceTd" colspan="1">WAS 20% of traffic</td></tr><tr><td class="confluenceTd" colspan="1">C</td><td class="highlight-#57d9a3 confluenceTd" title="Background colour : Medium green 65%" colspan="1" data-highlight-colour="#57d9a3">1.1.1.1 :87</td><td class="highlight-#57d9a3 confluenceTd" title="Background colour : Medium green 65%" colspan="1" data-highlight-colour="#57d9a3">4.3.3.2 :622</td><td class="confluenceTd" colspan="1">2.3.2.2 :84</td><th class="confluenceTh" colspan="1"><br /></th><td class="confluenceTd" colspan="1">HAS NO RUN SLOT</td><td class="confluenceTd" colspan="1">NOW 80% of traffic, but no run slot.</td></tr></tbody></table>

# How does chapter one end?
1. We removed the conneciton throttling software from the request pipeline. This did not solve the outages but reduced the complexity of the system
2. We worked to get our performance environment setup
3. We stopped making random guesses about production

Read on to see how things progressed. 

# Links
1. API-GW LongLivedConnections - https://forums.aws.amazon.com/thread.jspa?threadID=240690
2. NLB Behavior - https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html
3. More NLB Behavior - https://www.1strategy.com/blog/2017/11/28/exploring-the-new-network-load-balancer-nlb/
4. And More NLB stuff - https://stackoverflow.com/a/55798133/10808574, https://medium.com/tenable-techblog/lessons-from-aws-nlb-timeouts-5028a8f65dda, https://aws.amazon.com/premiumsupport/knowledge-center/elb-fix-unequal-traffic-routing/
