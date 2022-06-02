#!/bin/bash

#set -x

#Check required tools are installed or not
needed="curl wget unzip docker"
not_installed=""
for each in $needed;
do
	#echo "checking version"
	#$each --version >> /dev/null 2>&1
	find / -name $each | grep -i "$each"
	if [[ $? -ne 0 ]]; then
		#echo $each is not installed
		not_installed+=" $each"
	fi
	#echo testing $not_installed
done

if [[ -n $not_installed ]];
then
	echo "You need to install these $not_installed"

fi


get_distribution() {
	lsb_dist=""
	# Every system has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	
	echo "$lsb_dist"
}

get_distribution
echo $lsb_dist

case "$lsb_dist" in 
	ubuntu|debian|raspbian)
		echo "You need to use apt for installing"
		;;
	centos|fedora|rhel)
		echo "You need to use YUM for installing"
		;;
	alpine)
		echo "You need to use apk for installing"
		#apk add curl wget unzip
		;;
esac
