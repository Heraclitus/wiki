# AWS CLI hacks
https://rizvir.com/articles/AWS-cli-tips/

```
sts=($(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT:role/$ROLE_NAME --role-session-name $SESSION_NAME --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text))
export AWS_ACCESS_KEY_ID=${sts[0]}
export AWS_SECRET_ACCESS_KEY=${sts[1]}
export AWS_SESSION_TOKEN=${sts[2]}

```
Nice!
