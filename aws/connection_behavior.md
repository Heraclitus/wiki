# System wide TCP Connection Behavior

## Mistaken Understanding
The following sequence diagram shows the basic architecture that was tested. 

__FALSE ASSUMPTION:__ 1 client TCP connection will only ever result in 1 TCP conneciton at all levels of the pipeline

This assumption leads us to believe that the following happens...

![Mistaken Connection Behavior](./mistaken.png)


## Actual Behavior

API Gateway doesn't garantee that it's internal operation will consistently link the long-lived client connection with the same long-lived backend connection to the NLB. As a result you can see several NLB "flow" counts for a single repeating client using long-lived HTTP connections.

__NOTE__ the diagram suggests that each request results in a distinct connection on it's "backend" that is a simplification for diagraming and explaining. In actual fact you may or may not get a pre-existing connection. 
![Actual Connection Behavior](./actual)



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
