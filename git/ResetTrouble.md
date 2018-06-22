```
user@ubuntu:/depot/DFH/git$ git pull
Updating 353821c..ed6cd0f
error: Your local changes to the following files would be overwritten by merge:
    lab-main-t-aor-fhc-tfh1/Deployment.yaml
    lab-main-t-aor-fhc-tfh2/Deployment.yaml
Please, commit your changes or stash them before you can merge.
Aborting
user@ubuntu:/depot/DFH/git$ git revert lab-main-t-aor-fhc-tfh1/Deployment.yaml
fatal: bad revision 'lab-main-t-aor-fhc-tfh1/Deployment.yaml'

user@ubuntu:/depot/DFH/git$ git pull
Updating 353821c..ed6cd0f
error: Your local changes to the following files would be overwritten by merge:
    lab-main-t-aor-fhc-tfh1/Deployment.yaml
    lab-main-t-aor-fhc-tfh2/Deployment.yaml
Please, commit your changes or stash them before you can merge.
Aborting
user@ubuntu:/depot/DFH/git$ git reset lab-main-t-aor-fhc-tfh1/Deployment.yaml
Unstaged changes after reset:
M   lab-main-t-aor-fhc-tfh1/Deployment.yaml
M   lab-main-t-aor-fhc-tfh2/Deployment.yaml
user@ubuntu:/depot/DFH/git$ git reset --hard lab-main-t-aor-fhc-tfh1/Deployment.yaml
fatal: Cannot do hard reset with paths.
user@ubuntu:/depot/DFH/git$ git reset --hard
HEAD is now at 353821c alive check consistency in both lab2 and mounting
user@ubuntu:/depot/DFH/git$ git pull
Updating 353821c..ed6cd0f
Fast-forward
 lab-main-t-aor-fhc-tfh1/ConfigMap.yaml             |   1 +
 lab-main-t-aor-fhc-tfh1/Deployment.yaml            |  11 +++--
 lab-main-t-aor-fhc-tfh2/ConfigMap.yaml             |   1 +
 lab-main-t-aor-fhc-tfh2/Deployment.yaml            |  11 +++--
 prod-us-a-aor-fhc-pfh1/ConfigMap.yaml              | 112 ++++++++++++++++++++++++++++++++++++++++++++
 prod-us-a-aor-fhc-pfh1/Deployment.yaml             |  68 +++++++++++++++++++++++++++
 prod-us-a-aor-fhc-pfh1/Service.yaml                |  25 ++++++++++
 prod-us-a-aor-fhc-pfh1/ffmpeg-service-account.yaml |   4 ++
 8 files changed, 227 insertions(+), 6 deletions(-)
 create mode 100644 prod-us-a-aor-fhc-pfh1/ConfigMap.yaml
 create mode 100644 prod-us-a-aor-fhc-pfh1/Deployment.yaml
 create mode 100644 prod-us-a-aor-fhc-pfh1/Service.yaml
 create mode 100644 prod-us-a-aor-fhc-pfh1/ffmpeg-service-account.yaml
 ```
