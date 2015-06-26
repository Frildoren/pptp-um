#!/bin/bash

show_help() {
	echo "Usage: $0 -i --> Installs the necessary utilities to use the script"

	echo "Usage: $0 username password [timeout]"
	echo "Usage: $0 -r username"
	exit $1
}

get_users() {
	sudo cat /etc/ppp/chap-secrets | grep "^[^#;]" | awk '{print $1}'
}


if [[ $1 == "-h" || $1 == "--help" ]]
then
	show_help 0
fi

if [[ $1 == "-l" || $1 == "--list" ]]
then
	get_users
	exit 0
fi

if [[ $1 == "-i" || $1 == "--install" ]]
then
	if [[ $(ls /usr/bin | grep -c atq) -gt 0 ]]
	then
		echo "Utility already installed!"
		show_help 1
	else
		sudo apt-get install at
	fi
fi

if [[ $1 == "-r" || $1 == "--remove" ]]
	then
		name=$2;

		if [[ ! $name ]]
		then
			show_help 1
		fi

		sudo sed -i "/$name/d" /etc/ppp/chap-secrets

		out=$(last -w | grep "still logged in" | grep $name)
		while read -r line;
		do
			rip=$(echo $line | awk '{print $3}')
			pid=$(ps aux | grep $rip | grep root | awk '{print $2;exit;}')
			sudo kill $pid
		done <<< "$out"

	else
		name=$1
		pass=$2
		timeout=$3" "$4

		if [[ ! $name || ! $pass ]]
		then
			show_help 1
		fi

		if [[ $(sudo cat /etc/ppp/chap-secrets | grep -c $name) -gt 0 ]]
		then
			echo -e "User $name already exists.\n"
			show_help 1
		else
			if [[ ${#timeout} -gt 1 ]]
			then
				if [[ ! $4 ]]
				then
					timeout=$timeout"minutes"
				fi

				job=$(echo $0 -r $name | at now +$timeout 2>&1 >/dev/null | tail -n 1 | sed 's/job \(.*\) at.*/\1/')
			fi

			sudo sh -c "echo \"$name\t*\t$pass\t* # $job\" >>  /etc/ppp/chap-secrets"
		fi
fi
