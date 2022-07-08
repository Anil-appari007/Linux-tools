#!/bin/bash
date=$(date)
query_file="/home/anil/purging/query.sql"
log_location="/home/anil/purging/testlog.txt"
attachment_to_be_sent="/home/anil/purging/temp_daily.txt"
email_data_file="/home/anil/purging/email_data.json"

#container_name="test_db_postgres"

container_name="demo_db_postgres"

need_to_check_before="$query_file"
for each in $need_to_check_before;
do
    if [[ ! -e $each ]] ;
    then
        echo "There is no file at this path $each."
        # exit 1
    fi
done

echo "-----------------------------------------------" >> $log_location
echo "started at $date . Below line is Purge Output " >> $log_location

#curl $url >> $log_location

curl_output="$(cat $query_file | sudo docker exec -i $container_name psql -U postgres | tr -d '"' | cut --complement -d "." -f 1)"


echo $curl_output  >> $log_location

count_before_purging=$(echo $curl_output |  awk {'print $3'})
count_after_purging=$(echo $curl_output | awk {'print $10'})
deleted_count=$(echo $curl_output | awk {'print $7'})

echo -e "Records before purging:   \t $count_before_purging" >> $log_location

echo -e "Records after purging:    \t $count_after_purging" >> $log_location

echo -e "No.of Records deleted:    \t $deleted_count" >> $log_location


echo "completed at  $(date) " >> $log_location

cat $log_location | grep -A20 -B1 -i "$date" > $attachment_to_be_sent



SENDGRID_API_KEY=""

encoded_testdata="$(base64 $attachment_to_be_sent)"

no_space="$(echo $encoded_testdata | tr -d ' ')"


###     Log to single user

#log_attach="{\"personalizations\": [{\"to\": [{\"email\": \"88888888.com\"}]}],\"from\": {\"email\": \"cron***.com\"},\"subject\": \"CRON_JOB NOTIFICATION $(date +%d/%m/%y)\",\"content\": [{\"type\": \"text/plain\", \"value\": \" Cron-Job for DATA-Purge is executed successfully\"}], \"attachments\": [{\"content\": \"${no_space}\", \"type\": \"text/plain\", \"filename\": \"attachment.txt\"}]}"

###     Log for Multi-User
log_attach="{\"personalizations\": [{\"to\": [{\"email\": \"*********.com\"},{\"email\": \"*****.com\"},{\"email\": \"****.com\"},{\"email\": \"******.com\"}]}],\"from\": {\"email\": \"cron**.com\"},\"subject\": \"CRON_JOB DATA PURGING NOTIFICATION $(date +%d/%m/%y)\",\"content\": [{\"type\": \"text/plain\", \"value\": \" Cron-Job for DATA-Purge is executed.\"}], \"attachments\": [{\"content\": \"${no_space}\", \"type\": \"text/plain\", \"filename\": \"attachment.txt\"}]}"



echo $log_attach >  $email_data_file

#       Mail to multiple recipients with attachment.
curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer $SENDGRID_API_KEY" \
  --header 'Content-Type: application/json' \
  --data-binary "@$email_data_file"