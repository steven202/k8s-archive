**From:** Kennedy, Matt <[jmkennedy@wm.edu](mailto:jmkennedy@wm.edu)>
**Sent:** Monday, October 28, 2024 11:42 AM
**To:** Walter, Eric <[ejwalt@wm.edu](mailto:ejwalt@wm.edu)>
**Subject:** WMHPC kubernetes rule change

 

All,

To increase the security and interoperability of the WMHPC Kubernetes system we are rolling out a rule that specificizes each user set a security context whereby every pod you run is owned by your HPC user. If you attempt to run a pod without this security context set properly the pod will fail and you will receive and error message reminding you to set the security context. This change will make file system permissions cleaner for each user as well as safer for the community as a whole. 

Attached is a sample bit of yaml that might help you understand what you will need to add to your existing code. Some users may be impacted by this change if the pods that they are running attempt to change the user that owns the pods root process. I and the HPC team are happy to address these issues.

To find your user id and primary group id you can use the commands `id -ru` and `id -rg` respectively on any WMHPC system. Please let us know if you have any questions, concerns or issues regarding this change. 

This change will take place today between 1pm and 2pm.

Thank you,

Matt Kennedy

Research Computing

---

Greetings, 

Main-campus /sciclone/data10 was just reverted to read-write globally over the filesystem.

IMPORTANT:

1. data10 is only backed up on the weekends and, unfortunately, many backup jobs were in progress or hadn't started yet at 11am on Saturday, May 7th (which is when the filesystem died).  Therefore, most smaller and some larger users could only be restored back to the previous 5/31 backup. 

1. Everyone's top level folder (i.e. /sciclone/data10/<user>) has had its permissions reverted back to rwx for the owner only.  If you have trouble accessing another /sciclone/data10 folder besides your own, please send email to [hpc-help@wm.edu](mailto:hpc-help@wm.edu)

1. I STRONGLY URGE USERS THAT HAVE BEEN USING /sciclone/data10  as a scratch filesystem to please reconsider storing job outputs/temporary files in /sciclone/scr10 or /sciclone/scr20, not on /sciclone/data10.  Note the RC/HPC web page guidance on this (https://www.wm.edu/offices/it/services/researchcomputing/using/filesandfilesystems/)

    

2. 1. Input data files that are needed on an ongoing basis for active projects on the cluster and cannot be easily re-created or re-uploaded. **Please do not have jobs write a substantial amount to data filesystems.** Please use the scratch filesystems (below) for job output unless already given permission from HPC staff. 

       This means that regular job outputs should be written to a scratch filesystem and within the 3-month window for purging on scratch and then eventually moved to data10.  Please do not write to data10           for regular job outputs or large amounts of I/O during a job.

    4. Since we were restoring many files to /sciclone/scr10, we stopped purging it. We will turn purging back on this Friday.  Remember, scr10/scr20 files are purged after 90 days of inactivity.

Please send email to [hpc-help@wm.edu](mailto:hpc-help@wm.edu) if you have any questions.

Regards, 

Eric

\-- 

Eric J. Walter

Executive Director, Research Computing  

Information Technology

William & Mary   

Office: 757-221-1886

---

Greetings, 

The changes to the k8s cluster have been implemented.  As a reminder here is what has changed:

1. All single user namespaces will need to submit jobs instead of pods to the k8s system (see our example of pod vs. job yaml below):

1. Two automatic limits will be added to ALL jobs if not specified:

    **ActiveDeadlineSeconds** - "walltime" for job, all pods managed by this job will be killed after this amount of time

    Default: 86,400 seconds (1 day)

    Maximum: 432,000 seconds (5 days)

    **TtlSecondsAfterFinished** - this controls how long the logs and describe information is available for each pod run with this job.

    Default: 3,600 seconds (1 hour)

    Maximum: 604,800 (1 week)

   3. Project namespaces will still be able to run pods without any time limits.  Project namespaces can run jobs with a time limit, but it is not required.

​    \4. For more information using jobs to run pods see the information below and/or see: [https://kubernetes.io/docs/concepts/workloads/controllers/jo](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fkubernetes.io%2Fdocs%2Fconcepts%2Fworkloads%2Fcontrollers%2Fjo&data=05|02|cwang33%40wm.edu|7910ff75b2f14171f1e208ddf6041144|b93cbc3e661d40588693a897b924b8d7|0|0|638937219563784478|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=%2BgyFxzxJ5c5HrZAXKSA4OqwAdrT0neTJZG2KRVbur%2BA%3D&reserved=0)


   5. If you launch a job, to kill the job you must delete the job:
 
    kubectl get job
    kubectl delete job my-job-name


    instead of 

    kubectl get pod

    kubectl delete pod my-pod-name

If you just delete the pod, the job will start another if you are under the ActiveDeadlineSeconds limit.

**Examples**

**Old way: pod.yml**

\# Creates a python pod that runs for 5 minutes

apiVersion: v1  # Pod uses the "v1" API

kind: Pod

metadata:

 name: python-pod

 namespace: ewalter

spec:

 restartPolicy: OnFailure

 securityContext:

  runAsUser: {{USER_ID}}

  runAsGroup: {{GROUP_ID}}

 containers:

 \- name: python

  image: laudio/pyodbc

  command: ["/bin/sh", "-ec", "sleep 300"]  # Run for 300s (5 min)

  resources:

   requests:   # Minimum resources requested

​    memory: "8Gi"

​    cpu: "2"

   limits:    # Maximum resources allowed

​    memory: "16Gi"

​    cpu: "4"

**New way: job.yml**

\# Creates a Job that runs a python pod for 5 minutes

apiVersion: batch/v1  # Job uses the "batch/v1" API

kind: Job

metadata:

 name: python-job

 namespace: ewalter

spec:

 activeDeadlineSeconds: 60   # Walltime for all pods in this Job 

​                \# Default = 1 day (86400), max = 5 days (432000)  

 ttlSecondsAfterFinished: 30  # Job deleted 30s after completion (default is 3600s)  

 template:           # Pod definition goes here, just like before  

  spec:

   restartPolicy: OnFailure

   securityContext:

​    runAsUser: {{USER_ID}}

​    runAsGroup: {{GROUP_ID}}

   containers:

   \- name: python

​    image: laudio/pyodbc

​    command: ["/bin/sh", "-ec", "sleep 300"]

​    resources:

​     requests:

​      memory: "8Gi"

​      cpu: "2"

​     limits:

​      memory: "16Gi"

​      cpu: "4"

============================================================

**Key differences**

API version: Pods use v1, Jobs use batch/v1

Kind: Pods are kind: Pod, Jobs are kind: Job

Jobs let you set activeDeadlineSeconds for walltime (default 1 day, max 5 days)

Jobs can automatically delete themselves after finishing with ttlSecondsAfterFinished (default 1 hour)

============================================================

**Final** **notes**

Switching from Pods to Jobs is mostly a matter of wrapping your poddefinition inside a Job.

We’ll continue adjusting scheduling as needed, so please report any issues.

And as always, we are here to help if you need a hand.

Please send any questions or comments to [hpc-help@wm.edu](mailto:hpc-help@wm.edu)

\-- 

Eric J. Walter

Executive Director, Research Computing  

Information Technology

William & Mary   

Office: 757-221-1886

Stay connected with W&M IT: 

[Instagram](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fbit.ly%2F3GYAnOO&data=05|02|cwang33%40wm.edu|7910ff75b2f14171f1e208ddf6041144|b93cbc3e661d40588693a897b924b8d7|0|0|638937219563806525|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=GLZI6axSvPuoCVd2FsKCrVJuuaWj7LkN0p8PnyXirbM%3D&reserved=0) | [LinkedIn](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fbit.ly%2F3GYAnOO&data=05|02|cwang33%40wm.edu|7910ff75b2f14171f1e208ddf6041144|b93cbc3e661d40588693a897b924b8d7|0|0|638937219563821800|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=a7ZHHzvCn7xeECkZzeKaoxGp3p5tJvVUxrONNFnnn8g%3D&reserved=0) | [Facebook](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fbit.ly%2F452pNzu&data=05|02|cwang33%40wm.edu|7910ff75b2f14171f1e208ddf6041144|b93cbc3e661d40588693a897b924b8d7|0|0|638937219563836539|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=KdCAUFBqbtPhADTPvhSntxtWUI3paoFMNG1aO6G%2FAoM%3D&reserved=0) | [X](https://nam11.safelinks.protection.outlook.com/?url=https%3A%2F%2Fbit.ly%2F3IXSMM3&data=05|02|cwang33%40wm.edu|7910ff75b2f14171f1e208ddf6041144|b93cbc3e661d40588693a897b924b8d7|0|0|638937219563850898|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=TTP2O7emDHaPTsq4%2F6zH6Y5CyyFyfXrPFEuduMwuJSE%3D&reserved=0) 

------

**From:** Walter, Eric <[ejwalt@wm.edu](mailto:ejwalt@wm.edu)>
**Sent:** Thursday, September 11, 2025 11:43 AM
**To:** k8s-users <[k8s-users@lists.wm.edu](mailto:k8s-users@lists.wm.edu)>
**Subject:** Upcoming Change: User namespace Pods Must Run as Jobs on the Kubernetes Cluster starting on Wed, Sept 17th at noon.

 

Greetings, 

To ensure fair use of resources on the Kubernetes cluster, we are changing the way pods are run.

Starting  on Wed, Sept 17th at noon, pods in user namespaces will only be allowed to run as part of a Job.

============================================================

**Why this change?**

Long-running pods sometimes tie up resources and block others.

Jobs allow us to set a walltime (maximum runtime) so pods don’t run forever.

Jobs are a built-in Kubernetes feature designed for this.

============================================================

**What this means for you**

You’ll need to update your .yaml files to use Jobs instead of standalone Pods.

The changes are simple, and HPC staff are available to help.

This applies only to user namespaces (your personal namespace matching your W&M user ID).

**Lab/project namespaces will not be affected, only individual user namespaces.**

============================================================

**Defaults and limits**

***activeDeadlineSeconds\***

Default: 86,400 seconds (1 day)

Maximum: 432,000 seconds (5 days)

***ttlSecondsAfterFinished\***

Default: 3,600 seconds (1 hour), unless you specify otherwise

============================================================

**Need more time?**

If you have a legitimate use case that requires longer runtimes, you can request an exception (same as in slurm).

============================================================

**Examples**

***Old way: pod.yml\***

\# Creates a python pod that runs for 5 minutes

apiVersion: v1  # Pod uses the "v1" API

kind: Pod

metadata:

 name: python-pod

 namespace: ewalter

spec:

 restartPolicy: OnFailure

 securityContext:

  runAsUser: {{USER_ID}}

  runAsGroup: {{GROUP_ID}}

 containers:

 \- name: python

  image: laudio/pyodbc

  command: ["/bin/sh", "-ec", "sleep 300"]  # Run for 300s (5 min)

  resources:

   requests:   # Minimum resources requested

​    memory: "8Gi"

​    cpu: "2"

   limits:    # Maximum resources allowed

​    memory: "16Gi"

​    cpu: "4"

***New way: job.yml\***

\# Creates a Job that runs a python pod for 5 minutes

apiVersion: batch/v1  # Job uses the "batch/v1" API

kind: Job

metadata:

 name: python-job

 namespace: ewalter

spec:

 activeDeadlineSeconds: 60   # Walltime for all pods in this Job 

​                \# Default = 1 day (86400), max = 5 days (432000)  

 ttlSecondsAfterFinished: 30  # Job deleted 30s after completion (default is 3600s)  

 template:           # Pod definition goes here, just like before  

  spec:

   restartPolicy: OnFailure

   securityContext:

​    runAsUser: {{USER_ID}}

​    runAsGroup: {{GROUP_ID}}

   containers:

   \- name: python

​    image: laudio/pyodbc

​    command: ["/bin/sh", "-ec", "sleep 300"]

​    resources:

​     requests:

​      memory: "8Gi"

​      cpu: "2"

​     limits:

​      memory: "16Gi"

​      cpu: "4"

============================================================

**Key differences**

- API version: Pods use v1, Jobs use batch/v1

- Kind: Pods are kind: Pod, Jobs are kind: Job

- Jobs let you set activeDeadlineSeconds for walltime (default 1 day, max 5 days)

- Jobs can automatically delete themselves after finishing with ttlSecondsAfterFinished (default 1 hour)

============================================================

**Final notes**

Switching from Pods to Jobs is mostly a matter of wrapping your poddefinition inside a Job.

We’ll continue adjusting scheduling as needed, so please report any issues.

And as always, we are here to help if you need a hand.

Please send any questions or comments to [hpc-help@wm.edu](mailto:hpc-help@wm.edu)

Regards,

Eric

\-- 

Eric J. Walter

Executive Director, Research Computing  

Information Technology

William & Mary   

Office: 757-221-1886

---

> **From:** "Walter, Eric" <[ejwalt@wm.edu](mailto:ejwalt@wm.edu)>
>
> **Subject:** **dsci-chen-01 ready for pods/jobs**
>
> **Date:** February 10, 2026 at 12:22:56 PM EST
>
> **To:** "Chen, Haipeng" <[hchen23@wm.edu](mailto:hchen23@wm.edu)>
>
> **Cc:** "Slaughter, Malcolm" <[mslaughter@wm.edu](mailto:mslaughter@wm.edu)>, "Kennedy, Matt" <[jmkennedy@wm.edu](mailto:jmkennedy@wm.edu)>
>
> Hi Haipeng,
>
> Your node is now ready for pods/jobs on the k8s system.    To run a pod or a job on your node specifically, you will need to add the toleration to your job/pod yaml.  We have attached an example job, but could be run as a pod.  Please see https://www.wm.edu/offices/it/services/researchcomputing/k8s/ for another example of pods/jobs.
>
> Also let us know if you want to sit down and go over some things.
>
> apiVersion: batch/v1 #<-
>
> kind: Job
>
> metadata:
>
>  name: msl-testpod-chen
>
>  namespace: wmd3i
>
> spec:
>
>  activeDeadlineSeconds: 3600   #<-- required. Acts as a walltime for all pods in the job template and will kill all pods after expiration.
>
>  ttlSecondsAfterFinished: 300 #<-- Will delete job x seconds after completion.
>
>  template:  #A template of the pod that will be created, basically just the pod definition without the metadata.
>
>   spec:
>
> ​    restartPolicy: OnFailure
>
> ​    securityContext: # <-- pod user will have these id settings
>
> ​     runAsUser: {{USER_ID}}
>
> ​     runAsGroup: {{GROUP_ID}}
>
> ​    containers:
>
> ​    \- name: python
>
> ​     image: pytorch/pytorch:1.7.1-cuda11.0-cudnn8-devel
>
> ​     workingDir: /sciclone/home/mslaughter/
>
> ​     command: ["/bin/bash", "-c"]
>
> ​     args:
>
> ​      \- cd jobexample;
>
> ​       echo "from pod $NODE_NAME" >> a.txt;
>
> ​       sleep 600
>
> ​     env:
>
> ​      \- name: NODE_NAME
>
> ​       valueFrom:
>
> ​        fieldRef:
>
> ​         fieldPath: spec.nodeName
>
> ​     resources:
>
> ​      requests:
>
> ​       memory: "100Gi"
>
> ​       cpu: "30"
>
> ​       [nvidia.com/gpu:](https://nam11.safelinks.protection.outlook.com/?url=http%3A%2F%2Fnvidia.com%2Fgpu%3A&data=05|02|cwang33%40wm.edu|c4864a33e46f4f74fe8a08de68d008d5|b93cbc3e661d40588693a897b924b8d7|0|0|639063439867299027|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=ycPQ0j5nju2fkbCEPY8gC4Em3AQA8E0E1rcpctKsBGQ%3D&reserved=0) 2
>
> ​      limits:
>
> ​       memory: "100Gi"
>
> ​       cpu: "30"
>
> ​       [nvidia.com/gpu:](https://nam11.safelinks.protection.outlook.com/?url=http%3A%2F%2Fnvidia.com%2Fgpu%3A&data=05|02|cwang33%40wm.edu|c4864a33e46f4f74fe8a08de68d008d5|b93cbc3e661d40588693a897b924b8d7|0|0|639063439867317954|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=QJqE4mYFJyz81dgNY%2BCPSmABPqA7y%2BEGpXacjaigQTk%3D&reserved=0) 2
>
> ​     volumeMounts:
>
> ​      \- name: mypath
>
> ​       mountPath: /sciclone/home/mslaughter/
>
> ​    nodeSelector:
>
> ​       [kubernetes.io/hostname:](https://nam11.safelinks.protection.outlook.com/?url=http%3A%2F%2Fkubernetes.io%2Fhostname%3A&data=05|02|cwang33%40wm.edu|c4864a33e46f4f74fe8a08de68d008d5|b93cbc3e661d40588693a897b924b8d7|0|0|639063439867335244|Unknown|TWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D|0|||&sdata=71Abu18Zk6G4iYdMRcxkZ3lPL4UVvaTBh%2Fr86xrCxOI%3D&reserved=0) [dsci-chen-01.sciclone.wm.edu](http://dsci-chen-01.sciclone.wm.edu/)
>
> ​    tolerations:
>
> ​     \- key: "node"
>
> ​      operator: "Equal"
>
> ​      value: "dsci-chen-01"
>
> ​      effect: "NoSchedule"
>
> ​    volumes:
>
> ​     \- name: mypath
>
> ​      nfs:
>
> ​       server: 128.239.56.166
>
> ​       path: /sciclone/home/mslaughter/nodetest/
>
> ​    restartPolicy: Never
>
> Regards, 
>
> Eric
>
> \-- 
>
> Eric J. Walter
>
> Executive Director, Research Computing  
>
> Information Technology
>
> William & Mary   
>
> Office: 757-221-1886

---

Greetings, 

Quotas will now be enforced on /sciclone/home by the end of the day.  Please see:

https://www.wm.edu/offices/it/services/researchcomputing/using/filesandfilesystems/quotas/

For more information on how to determine your quota on /sciclone/home

As stated in our previous email, the default quota will be set to 50GB.  Anyone with more than 50GB will have their quota set to the nearest 50GB above their current usage, so no one should be out of space immediately. 

Please send questions and comments to [hpc-help@wm.edu](mailto:hpc-help@wm.edu)

Regards, 

Eric

\-- 

Eric J. Walter

Executive Director, Research Computing  

Information Technology

William & Mary   

Office: 757-221-1886