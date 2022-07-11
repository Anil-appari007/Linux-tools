#!/bin/bash


location="/home/anil/dumps/dbbackup"
pg_dbname="testdb"
container_name="postgres-db"
pg_filename="pg_backup_$(date +%Y_%B_%d_%Hhr_%Mmin).7z"     ##pg_backup_2022_July_11_10hr_19min.7z


######  azure creds

secret=""
application_id=""
tenant_id=""
storage_account_name=""
data_storage=""

######

status_check(){
    if [[ $? -eq 0 ]];
    then
        echo "Execution is failed at $stage"
        exit
}

###########################

echo "--------------------------------------------"
echo backup created at $(date)
cd $location

stage="backup-generation"
sudo docker exec $container_name pg_dump -U postgres -d $pg_dbname > $pg_dbname.sql
status_check

stage="compression"
7za a $pg_filename $pg_dbname.sql
status_check
rm -rf *.sql

#####################   Upload to Azure storage

stage="Azcopy"

export AZCOPY_SPA_CLIENT_SECRET=$secret
azcopy login \
    --service-principal \
    --application-id "$application_id" \
    --tenant-id "$tenant_id"

azcopy copy "$pg_filename" "https://$storage_account_name.blob.core.windows.net/$data_storage"
status_check
echo backup completed at at $(date)
echo "--------------------------------------------"

## Crontab expression 0 13,21 * * *  /home/anil/dumps/cron_for_pg_backup.sh >> /home/anil/dumps/logfile.txt

########Output
# anil@vm:~/dumps$ bash cron_for_pg_db_backup.sh
# --------------------------------------------
# backup created at Mon Jul 11 10:55:13 IST 2022

# Scanning the drive:
# 1 file, 1237822001 bytes (1181 MiB)

# Creating archive: pg_backup_2022_July_11_10hr_55min.7z

# Items to compress: 1


# Files read from disk: 1
# Archive size: 206612471 bytes (198 MiB)
# Everything is Ok
# INFO: If you set an environment variable by using the command line, that variable will be readable in your command line history. Consider clearing variables that contain credentials from your command line history.  To keep variables from appearing in your history, you can use a script to prompt the user for their credentials, and to set the environment variable.
# INFO: SPN Auth via secret succeeded.
# INFO: Scanning...
# INFO: Authenticating to destination using Azure AD
# INFO: Any empty folders will not be processed, because source and/or destination doesn't have full folder support

# Job *****-eef1-*****-62d3-***** has started
# Log file is located at: /home/anil/.azcopy/*****-eef1-*****-62d3-*****.log

# 100.0 %, 1 Done, 0 Failed, 0 Pending, 0 Skipped, 1 Total, 2-sec Throughput (Mb/s): 826.298


# Job *****-eef1-*****-62d3-***** summary
# Elapsed Time (Minutes): 0.0333
# Number of File Transfers: 1
# Number of Folder Property Transfers: 0
# Total Number of Transfers: 1
# Number of Transfers Completed: 1
# Number of Transfers Failed: 0
# Number of Transfers Skipped: 0
# TotalBytesTransferred: 206612471
# Final Job Status: Completed

# backup completed at at Mon Jul 11 10:59:09 IST 2022
