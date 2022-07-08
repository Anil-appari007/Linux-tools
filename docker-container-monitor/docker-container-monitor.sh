#!/bin/bash
##  docker run -itd --restart=always --name alp alpine sleep 5
# container_names="alp"



# source /etc/containermonitoring/config.txt
source config.txt


send_smtp_email(){
    for each_reciever in $recipient_mail_id;
    do
        curl -s --url smtp://$smtp_server_name:$smtp_server_port --ssl-reqd \
            --mail-from $smtp_username --mail-rcpt $each_reciever \
            --upload-file email.txt \
            --user $smtp_username:$smtp_pwd --insecure
    done
}

send_teams_notification(){
    curl -s -H 'Content-Type: application/json' -d "{\"text\": \"$each_container is not running\"}" $webhook > /dev/null
}

send_alert(){
        # case "$send_alerts" in
        #     TRUE)
        #         case "$send_alerts_in_teams" in
        #             TRUE)
        #                 send_teams_notification
        #                 ;;
        #         esac
        #         case "$send_alerts_in_mail" in
        #             TRUE)
        #                 send_smtp_email
        #                 ;;
        #         esac
        #         ;;
        # esac
    send_teams_notification
    send_smtp_email
}


check_and_alert(){
    case "$container_status" in
        running)
            # echo "Container $each_container is running"
            echo -e "\e[1;32m Container $each_container is running \e[0m"
            ;;
        *)
            # echo "Container $container_name is not running"
            echo -e "\e[1;31m Container $each_container is not running \e[0m"
            send_alert
            ;;
    esac
    # if [[ "$container_status" != "running" ]];
    # then
    #     echo "Container is not running"
    #     send_alert
    #     exit
    # fi
}

run_app(){
        echo "Containers to check " $container_names
        echo "Time Frequency is " $check_frequency seconds


        while :
        do
                echo "Check at $(date +%Y_%b_%d_%Hhr_%Mmin_%Ssec)"
                for each_container in $container_names;
                do
                        container_status=`docker inspect $each_container -f {{.State.Status}} 2> /dev/null`
                        check_and_alert     
                done
                sleep $check_frequency

        done
}

run_app | tee -a $output_log

####### Create a service
####### it should have a config file to provide container names, time-frequency, notification config like teams webhook or maiil

#### Guides
####    https://www.baeldung.com/ops/docker-container-states
####    https://linuxize.com/post/bash-source-command/
####    https://everything.curl.dev/usingcurl/smtp
####    https://phoenixnap.com/kb/bash-case-statement

#########################################

#sudo vim /etc/systemd/system/containermonitoring.service
# [Unit]
# Description=Docker Container Monitoring Service
# After=network.target

# [Service]
# Type=simple
# ExecStart=sudo /usr/bin/bash /etc/containermonitoring/containermonitoring.sh

# [Install]
# WantedBy=multi-user.target

#######################################
# demouser@docker-server:/etc/containermonitoring$ sudo service containermonitoring status
# ● containermonitoring.service - Docker Container Monitoring Service
#      Loaded: loaded (/etc/systemd/system/containermonitoring.service; disabled; vendor preset: enabled)
#      Active: active (running) since Fri 2022-06-17 15:37:21 IST; 3min 57s ago
#    Main PID: 4069364 (sudo)
#       Tasks: 5 (limit: 9508)
#      Memory: 3.9M
#      CGroup: /system.slice/containermonitoring.service
#              ├─4069364 /usr/bin/sudo /usr/bin/bash /etc/containermonitoring/containermonitoring.sh
#              ├─4069384 /usr/bin/bash /etc/containermonitoring/containermonitoring.sh
#              ├─4069385 /usr/bin/bash /etc/containermonitoring/containermonitoring.sh
#              ├─4069386 tee -a /var/log/containermonitoring.log
#              └─4070886 sleep 30

# Jun 17 15:39:22 docker-server sudo[4069386]:  Container db is not running
# Jun 17 15:39:52 docker-server sudo[4069386]: Check at 2022_Jun_17_15hr_39min_52sec
# Jun 17 15:39:52 docker-server sudo[4069386]:  Container alp is not running
# Jun 17 15:39:52 docker-server sudo[4069386]:  Container db is not running