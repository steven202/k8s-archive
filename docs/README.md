# HPC-Resources
This repository contains resources for using the HPC cluster at William & Mary. It includes example YAML files for Kubernetes and Slurm job submissions, as well as common commands for managing jobs and checking cluster status.

## Creating an Account
Following the instructions here: https://www.wm.edu/offices/it/services/researchcomputing/acctreq/

## Accessing the Cluster
To access the cluster, you can use SSH to connect to the login node. Use the following
command, replacing `<username>` with your actual username:

* K8s cluster
```bash
ssh <username>@cm.geo.sciclone.wm.edu
```

* Slurm cluster
```bash
ssh <username>@bora.sciclone.wm.edu
```

* Accessing outside of the campus
Set up a bastion host to access the cluster from outside of the campus. Follow the instructions here:
https://code.wm.edu/IT/bastion-host-instructions

```bash
$ ssh -J user@bastion.wm.edu user@somewhere.else
```


### K8s common commands:
For **jobs** it can be submitted under your own namespace, so you can omit the `-n` flag. For pods submission you need to specify the namespace with `-n` flag with `wmd3i` as the group namespace.

Similarly, you can only check the pods and jobs under your own namespace. If you want to check running job under `wmd3i`, you need to specify the namespace with `-n` flag.

- kubectl get pods -n `namespace`
- kubectl get jobs -n `namespace`
- kubectl logs `pod-name` -n `namespace`
- kubectl describe pod `pod-name` -n `namespace`
- kubectl delete pod `pod-name` -n `namespace`
- kubectl delete job `job-name` -n `namespace`
- kubectl apply -f `yaml-file` -n `namespace`
- kubectl delete -f `yaml-file` -n `namespace`
- getnodestats : Check all nodes and their resource usage.
- getgpuusage : Check all running jobs using GPU on the cluster.

### Slurm common commands:
- squeue -u `username`
- scontrol show job `job-id`
- scancel `job-id`
- sbatch `script-file`
- srun `script-file`
- salloc `script-file`
- sinfo

### Cluster Status
https://hpc.wm.edu/grids/ 

### Feel free to ask any questions about the cluster!  -- Yang