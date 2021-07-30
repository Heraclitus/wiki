#!/usr/bin/env bash

if aws sts get-caller-identity; then
  echo "Starting"
else
  echo "Check token"
  exit
fi

REPORT_PATH="/var/tmp/reports/vendor"
mkdir -p $REPORT_PATH
FULL_REPORT_FILE="$REPORT_PATH/full-report.csv"
if [ -f $FULL_REPORT_FILE ]
then
  DATED_REPORT_PATH="$REPORT_PATH-$(date +"%s")"
  mkdir "$DATED_REPORT_PATH"
  mv $REPORT_PATH/*.* "$DATED_REPORT_PATH"
fi

EAST="us-east-1"
WEST="us-west-2"

#43200 is 12 hours
#36000 is 10 hours
EPOCH_CHUNK="6000"
#EPOCH_CHUNK="3200"
#                         "YYYY-MM-DD 00:00:00"
HUMAN_BEGIN_DATE_AND_TIME="2021-02-12 22:57:00"
AWS_DEFAULT_REGION="$EAST"
export AWS_DEFAULT_REGION

function isRunning ( ) {
  jbid=$1
   R=$(aws logs describe-queries --status Running | grep -c "$jbid")
   echo $R
}

function startJob () {
   JOB_ID=$(aws logs start-query --start-time $BEGIN_EPOCH --end-time $END_EPOCH --log-group-name /prd/apps/nginx/access.log --query-string 'fields @timestamp, @message | parse @message "* - - [*] \"* * *\" * * \"*\" \"*\" \"*\" * * * * * [*] *" as ip, time, method, uri, protocol, status, length, agent, referer, xff_ips, host, elb, request_time, response_time, pipe, request_header, request_body | parse request_header "x-amzn-trace-id: Root=*;" as trace_id | display response_time, trace_id, @timestamp, status, method, agent, uri'| jq -r '.queryId' )
   echo "$JOB_ID"
}

function collectResults () {
   JOB_ID=$1
   echo "aws logs get-query-results --query-id $JOB_ID"
   ##                                                                                                                response_time, trace_id, @timestamp, status, method, agent, uri
   OUT=$(aws logs get-query-results --query-id "$JOB_ID" | jq -r '.results[]| map( {(.field) : (.value) } ) | add |[.response_time, .trace_id, ."@timestamp", .status, .method, .agent, .uri]|@csv')
   echo "$OUT" > "/var/tmp/reports/vendor/$JOB_ID.csv"
}

function waitAndCollect () {
  JOB_ID=$(startJob)
  echo "jobid = $JOB_ID"
  R=$(isRunning $JOB_ID)
  while [ $R -gt 0 ]
  do
    sleep 10
    echo "Checking job $JOB_ID"
    R=$(isRunning $JOB_ID)
    echo "Job count $R $JOB_ID"
  done

  echo "USING CMD: aws logs get-query-results --query-id $JOB_ID"
  ret=$(collectResults "$JOB_ID")
}

R=$(isRunning $JOB_ID)
if [[ $R -gt "1" ]]
then
  echo "Already running! USE: aws logs describe-queries --status Running"
fi

BEGIN_EPOCH=$(date -d "$HUMAN_BEGIN_DATE_AND_TIME" +"%s")
echo "chunk epoch $EPOCH_CHUNK"
echo "begin epoch $BEGIN_EPOCH"
((END_EPOCH=BEGIN_EPOCH+EPOCH_CHUNK))
echo "  end epoch $END_EPOCH"

waitAndCollect &

for job in `jobs -p`
do
echo "Waiting on PID:$job"
    wait $job || let "FAIL+=1"
done
