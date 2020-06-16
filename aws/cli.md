# AWS CLI hacks
https://rizvir.com/articles/AWS-cli-tips/

```
sts=($(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT:role/$ROLE_NAME --role-session-name $SESSION_NAME --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text))
AWS_ACCESS_KEY_ID=${sts[0]}
AWS_SECRET_ACCESS_KEY=${sts[1]}
AWS_SESSION_TOKEN=${sts[2]} ${@:2}

```
Nice!
