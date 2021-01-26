# AWS - System wide TCP Connection Behavior

# Problem Statement
Over time we observed tremendous spikes in TCP connections that would often cripple the system. Recovery form these spikes would often require throttling the API-GW down to sub-200 RPS settings and easing back up to un-throttled position. An example of the spikes looks like <img src="https://github.com/Heraclitus/wiki/blob/master/aws/ConnectionSpikeExample.jpg" height="200"/>

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

## Customer Trends
Peaks can be as high as 4,000 RPS (Requests Per Second) and trough around 1,300 RPS. 

# Troubleshooting process
Typically you would start by thinking of the two ends; CloudFront & RDS.  Did we get a huge rush of customer traffic? Did we get a DB related slow down? Time and time again the answer was no. We'd look at CloudFront request metrics for the spike period and see nothing that would account for that large of spike. ![NotFrontEnd](./NoSpikeInFrontEnd.jpg)

# Mistaken Understanding
The following sequence diagram shows the basic architecture that was tested. 

__FALSE ASSUMPTION:__ 1 client TCP connection will only ever result in 1 TCP conneciton at all levels of the pipeline

This assumption leads us to believe that the following happens...

![Mistaken Connection Behavior](./mistaken.png)


## Actual Behavior

API Gateway doesn't garantee that it's internal operation will consistently link the long-lived client connection with the same long-lived backend connection to the NLB. As a result you can see several NLB "flow" counts for a single repeating client using long-lived HTTP connections.

__NOTE__ the diagram suggests that each request results in a distinct connection on it's "backend" that is a simplification for diagraming and explaining. In actual fact you may or may not get a pre-existing connection. 
![Actual Connection Behavior](./actual.png)

![Video Of Connection Behavior](./connection-behavior.mp4)



# Raw Diagrams

## Mistaken
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

## Actual
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
