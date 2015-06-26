#!/bin/bash

show_help() {
	echo -e "Usage: $0 [OPTION] [username [password] [timeout]]\n"
	echo "Available options:"
	echo -e "  [no option] \t\t adds a new username. Password is required.\n\t\t\t optional timeout determines expiration of this account.\n\t\t\t\tFORMAT: {integer} minutes/hours/days"
	echo -e "  -r, --remove \t\t removes the given username."
	echo -e "  -l, --list \t\t lists the active usernames."
	echo -e "  -i, --install \t installs the necessary utilities using apt-get.\n"
	exit $1
}

get_users() {
	sudo cat /etc/ppp/chap-secrets | grep "^[^#;]" 
}

get_user() {
	get_users | grep "$1"
}

get_user_job(){
	get_user $1 | sed 's/.*#--\(.*\)--#.*/\1/'
}

get_user_names() {
	get_users | awk '{print $1}'
}



if [[ $1 == "-h" || $1 == "--help" ]]
then
	show_help 0
fi

if [[ $1 == "-l" || $1 == "--list" ]]
then
	get_user_names
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
		
		if [[ get_user $name ]]
		then
			job=$(get_user_job $name)
			if [[ $job ]]
			then
				at -r $job
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
			echo "username $name does not exist."
			exit 1
		fi

	else
		name=$1
		pass=$2
		timeout=$3" "$4

		if [[ ! $name || ! $pass ]]
		then
			show_help 1
		fi

		if [[ get_user $name ]]
		then
			$0 -r $name
		fi
		
		if [[ ${#timeout} -gt 1 ]]
		then
			if [[ ! $4 ]]
			then
				timeout=$timeout"minutes"
			fi

			job=$(echo $0 -r $name | at now +$timeout 2>&1 >/dev/null | tail -n 1 | sed 's/job \(.*\) at.*/\1/')
		fi

		sudo sh -c "echo \"$name\t*\t$pass\t*\t#--$job--#\" >>  /etc/ppp/chap-secrets"
		
fi
