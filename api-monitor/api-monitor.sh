#!/bin/sh

####
api_list="api1 api2 ap13"

word="crash"
crash_list=""

webhook=""

curl_log="/opt/api-monitor/curl_log.txt"

sed -i "s/Last check at =.*/Last check at = $(date)/" $curl_log

echo "---------------------------------
Last check at $(date)"

for each in $api_list;
do
    ## Search logfile for word crash in last line
    ## e.g.: [nodemon] app crashed - waiting for file changes before starting...

    cat /home/anil/.pm2/logs/$each-out.log | tail -1 | grep -i "$word"

        #cat $each.txt | grep -i "$word"

    ##  if crash word is found, grep exit status would be 0
    status=$(echo $?)


        if [ $status = 0 ]; then
                # echo "$word is here"
                echo "$each crashed"
                crash_list+=" $each"

        ### if crash word is not in log line,
        elif [ $status != 0 ]; then
                echo "$each         Running fine"
                                #echo "notsent" > curl_log.txt
                #sed -i 's/$each =.*/$each =dontsend/' curl_log.txt
                sed -i "s/$each =.*/$each = noneed/" $curl_log
        fi
done

#echo This is-- crash list $crash_list


mail_send_list=""
for each in $crash_list;
do
### Checking if any mail has been sent in last status check.
    if [ $(cat $curl_log | grep $each | awk {'print $3'} ) != "sent" ]; then
        mail_send_list+="$each "
        echo " mail will go for $each status"
    elif [ $(cat $curl_log | grep $each | awk {'print $3'} ) = "sent" ]; then
        echo "Mail already sent for $each status"
    fi
done

 #echo "This is mail sending list $mail_send_list"


if [[ -n $mail_send_list  ]]; then


    echo "This is mail sending list $mail_send_list"

     curl -H 'Content-Type: application/json' -d "{\"text\": \"Production api $mail_send_list crashed\"}" $webhook
    curl_status=$(echo $?)
    # #echo $curl_status
        if [ $curl_status = 0 ]; then
        #     ### if mail sent successfully, value of api will be sent
        #       #echo "sent" > curl_log.txt
        #     #echo $each
        #     #echo "Mail sent"
              for each in $mail_send_list;
              do
              #     ### sed -i 's/sit-admin = sent/sit-admin = notsent/' curl_log.txt
                     sed -i "s/$each =.*/$each = sent/" $curl_log
              #     #echo $?
              done
        fi
fi

if [[ -n $crash_list ]]; then
        echo "Need to restart $crash_list"
        pm2 restart $crash_list
fi