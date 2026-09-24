### Scenario

You are working as a DevOps Engineer on a cloud-based infrastructure where a virtual machine (VM), running Ubuntu 24.04, with 64GB of storage is under your management. Recently, your monitoring tools have reported that the VM is consistently running at 99% storage usage. This VM is responsible for only running one service - a NGINX load balancer as a traffic router for upstream services.

### Task
1. Firstly, I review monitoring tools and identify when this high storage usage started, how long it has been occurring, and any patterns or trends in the storage usage over time. I also check for any recent changes or deployments that may have contributed to the increased storage usage.

2. Next, I do a backup of the current state of the VM, including its configuration and any important data, to ensure that I can restore it if necessary.

3. I then investigate the storage usage on the VM by checking the disk space usage
    - Login to the VM by SSH or using a remote console.
    - Run the command `df -h` to check the disk space usage of all mounted filesystems. This will show the total size, used space, available space, and the percentage of space used for each filesystem.
    - Run the command `du -sh /*` to check the disk usage of each directory in the root filesystem. This will help identify which directories are consuming the most space.
    - Run the command `du -sh /var/log/*` to check the disk usage of log files in the `/var/log` directory. This is important because log files can grow rapidly and consume a significant amount of disk space.
    - Check current status VM with `top` or `htop` command to see if there are any processes consuming excessive resources.
    - Check the NGINX configuration files and logs to see if there are any misconfigurations or issues that may be causing excessive logging or other problems that could lead to high storage usage.

4. After identifying the root cause of the high storage usage, I take appropriate actions to resolve the issue. This may include:
    - Cleaning up unnecessary files or directories that are consuming disk space: if there are any temporary files, old backups, or other unnecessary files that can be safely deleted, I remove them to free up space. 
    - Rotating or archiving log files to free up space: if log files are consuming a significant amount of disk space, I rotate or archive them to free up space. This can be done using log rotation tools such as `logrotate`.
    - Adjusting NGINX configuration: change log levels or log file locations to reduce disk space usage. For example, I can change the log level from `debug` to `info` or `error`, or move log files to a different location with more available space. Normally, log level on production environment should be set to `error` or `warn` to reduce the amount of log data generated.
    - Increasing the storage capacity of the VM: incase after investigation, the VM is normally comsuming storage space (NGINX logs is growing rapidly due to high traffic), I can increase the storage capacity of the VM by adding more disk space or resizing the existing disk. This can be done through the cloud provider's management console or using command-line tools.

5. Finally, I monitor the storage usage on the VM after taking corrective actions to ensure that the issue has been resolved and that the storage usage remains within acceptable limits. I also implement monitoring and alerting to proactively detect (predict run out storage by consumption speed) and reduce alert threshhold to 80% to prevent future storage issues that not have enough time to react.