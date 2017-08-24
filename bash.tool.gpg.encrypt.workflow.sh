#!/bin/sh
# created: 08-22-2017
# updated: 08-24-2017
# name: ssh_helper.sh
# about: encryption backup workflow 

function _applescript_get_local_folder() {

read -r -d '' local_folder_path <<'EOF'
   set folder_path to POSIX path of (choose folder with prompt "Choose Folder To Sync")
   return POSIX path of folder_path
EOF

local local_folder_path=$(osascript -e "$local_folder_path");

echo ${local_folder_path}

}

function _applescript_get_gpg_password() {

read -r -d '' local_gpg_password <<'EOF'
   set gpg_password to the text returned of (display dialog "Enter GPG Password" default answer "")
   return gpg_password
EOF

local local_gpg_password=$(osascript -e "$local_gpg_password");

echo ${local_gpg_password}

}

function current_timestamp (){
	echo $(date "+%Y.%m.%d.%H%M%S")
}

function random() {
	local _length=${1};
	python -c "from random import choice; print ''.join([choice('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') for i in range(10000)])" | \
	head -c ${_length} ;
}


function create_temp_file () {
	
	local _temp_file=`mktemp /tmp/bash.script.temp.gpg.workflow.XXXXXXXXXX` || exit 1
	local _temp_folder=$(dirname "${_temp_file}")
	echo "${_temp_file}";
}


function _gpg_workflow () {
	
	# set working directory
	local work_directory=$( _applescript_get_local_folder );
	cd "${work_directory}";
	pwd;
	
	# prompt for password | will be applied to all files
	local _password=$( _applescript_get_gpg_password )
	

	
	# create csvfile and headers
	local _csvfile=$( create_temp_file );
	local _timestamp=$( current_timestamp );
	local _csv_filename="file.list.${_timestamp}.csv";
	    
	
	echo "file,id" >> ${_csvfile};
		
	
	# create tar and gpg output folder
	
	for i in *; do
		#printf  ${i} '\n';
		local _original_file=${i};
		local _id=$( random 30 );
		local _current_file=${i};
		local _tar_file="archive.${_id}.tar"
		
		#echo "${_tar_file}";

		echo "${_original_file},${_id}" >> ${_csvfile};
		
		echo ${_tar_file};
		
		tar -cf "${_tar_file}" "${_original_file}"
		echo "${_password}" | \
		gpg --passphrase-fd 0 \
		-c "${_tar_file}"
				
	done
	
	mkdir output;
	local _output="$(pwd)/output/";
	
	
	rm -rf *.tar
	mv *.gpg "${_output}"
	
	
	mv ${_csvfile} "$(pwd)/${_csv_filename}"
	rm -rf "${_csvfile}";
	
}

echo $( _gpg_workflow );

