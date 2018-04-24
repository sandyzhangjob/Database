#!/bin/bash

####################################
#   use for vn tlbb gamedb update  #
#   created by penghy 20121016     #
###################################

# init variables
BASE_DIR="/home/databackup"
serverlist="${BASE_DIR}/ip.txt"
remote_dir="/tmp/${date}"

#date=20140126 DT1=140126 TIME=20131203-1603
date=`date +%Y%m%d`
DT1=`date +%y%m%d`
TIME=`date +%Y%m%d-%H%M`
# please fill out your script filename here, order by your execute order
order_scriptname=(
deploy_backup_2.0_20140212.tar.gz
)
md5file=""
logfile="./hw_bakcup_deploy_${date}.log"

iplist=`egrep -v '^#|^$' ${serverlist} | awk '{print $1}'`

while getopts "c:i:d:" OPT; do
        case $OPT in
                "c") 
                command=$OPTARG
                ;;
                "i") 
                script_id=$OPTARG
                ;;
                "d") 
                db_name=$OPTARG
                ;;
        esac
done

upload(){
	mkdir -p $BASE_DIR/db_config
	 
	if [ -f $serverlist ];then
	        if [ -f $BASE_DIR/db_config/all_db_config.txt ]; then
			sed "/^$/d;/^#/d" $BASE_DIR/db_config/all_db_config.txt
	                read -p "Is all DB informations in $BASE_DIR/db_config/all_db_config.txt[y/n]?" a
			if [ ${a}x == 'yx' ]; then
		            	echo ""
			else 
				echo "Please add DB informaiton at $BASE_DIR/db_config/all_db_config.txt"
				exit
			fi
	        else
	                echo  -e "\e[1;33mPlease modify all_db_config.txt and excute again! You can do this: \n1)cp -rp $BASE_DIR/scripts/example_all_db_config.txt $BASE_DIR/db_config/all_db_config.txt \n2)Simple modify all_db_config.txt!\n(This file define mysqldump parameters.)\e[0m"
	        exit
	        fi
	else
	        echo -e "\e[1;33mPlease modify $BASE_DIR/ip.txt and excute again! \n (ip.txt records IP that you want to add DB dump function)\n E.g: 10.10.81.1\n 10.10.81.2\e[0m"     
	        exit
	fi
	
        for ip in ${iplist}
        do
	        echo -e "\e[1;32;40m###################  upload ${ip}\t #######################\e[0m" 
		if [ `cat $BASE_DIR/db_config/all_db_config.txt | grep -v "^#" | grep ${ip} | wc -l` -ge 1 ]; then
        	        ssh ${ip} "mkdir -p ${remote_dir}" 
                	ssh ${ip} "mkdir -p ${BASE_DIR}/db_config" 
                	for script in ${order_scriptname[@]}
                	do
                       		scp ${script} ${ip}:${remote_dir}
				scp $BASE_DIR/db_config/all_db_config.txt ${ip}:$BASE_DIR/db_config
				ssh ${ip} "cd ${remote_dir} && tar zxf ${order_scriptname[${script_id}]} -C ${BASE_DIR}"
                	done
		else
			echo -e "\e[1;31mNo this IP information in all_db_config.txt.\nIt will cause mysqldump failed.\nPlease check all_db_config.txt and execute upload again!\e[0m"
			exit
		fi
        done
}

verify_script(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  verify ${ip} #######################\e[0m" 
                for script in ${order_scriptname[@]}
                do
                        ssh ${ip} "cd ${remote_dir} && md5sum ${script}"
                done
                echo -e "-----------------Original md5----------------------------------"
		md5sum ${order_scriptname}
        done
}

check_connection(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  conn ${ip} #######################\e[0m" 
		ssh ${ip} "mysqladmin pr"
        done

}

install_backup(){
	for ip in ${iplist}
	do
		echo -e "\e[1;32;40m###################  install bakcup ${ip} #######################\e[0m"
		ssh ${ip} "mkdir -p ${BASE_DIR}"
		ssh ${ip} "sh ${BASE_DIR}/scripts/hw_backup_all.sh install_xtrabackup"
		if [ $? == 0 ];then
			ssh ${ip} "sh ${BASE_DIR}/scripts/hw_backup_all.sh add_crontab_jobs"
		else
			echo -e "\e[1;32;40m [error $ip] install failed!\n Please check this mechine\e[0m"
		fi
	done
}

mysqldump_db(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  backup ${ip} #######################\e[0m" 
                ssh ${ip} "/bin/bash ${BASE_DIR}/scripts/hw_backup_all.sh mysqldump_backup"
        done
}

xtrabackup_full_db(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  backup ${ip} #######################\e[0m" 
                ssh ${ip} "/bin/bash ${BASE_DIR}/scripts/hw_backup_all.sh xtrabackup_all" 
        done
}

xtrabackup_inc_db(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  backup ${ip} #######################\e[0m" 
                ssh ${ip} "/bin/bash ${BASE_DIR}/scripts/hw_backup_all.sh xtrabackup_inc" 
        done
}

check_mysqldump(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  check ${ip} #######################\e[0m" 
                dump_ps_count=`ssh ${ip} "ps aux | grep 'dump' | grep -v grep | grep -v ssh | wc -l"`
                echo -e "mysqldump processing count: ${dump_ps_count}"
                if [[ ${dump_ps_count} -eq 0 ]]; then
                        ssh ${ip} "ls -lthr ${BASE_DIR}/backup_mysqldump/ | tail -6"
                fi
        done
}

check_xtrabackup_full(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  backup ${ip} #######################\e[0m"
		ssh ${ip} "cat  ${BASE_DIR}/log/xtr_backup_full_*.log | grep  '${DT1}' | grep OK | tail -3" 
		ssh ${ip} "ls -lthr ${BASE_DIR}/back_zip/ | grep xtr | grep full | tail -6"
        done
}

check_xtrabackup_increment(){
        for ip in ${iplist}
        do
                echo -e "\e[1;32;40m###################  backup ${ip} #######################\e[0m"
		ssh ${ip} "cat  ${BASE_DIR}/log/xtr_backup_inc_*.log | grep  '${DT1}' | grep OK | tail -3"
		ssh ${ip} "ls -lthr ${BASE_DIR}/back_zip/ | grep xtr | grep inc | tail -6"
        done
}

get_help(){
        echo -e "\tusing DB IP list:       \e[1;32;40m${serverlist}\e[0m"
        echo -e "\tDeploy backup package name:\t\t\e[1;32;40m"
        for i in `seq ${#order_scriptname[@]}`
        do
                id=$(($i - 1))
                echo -e "\t\t\t\t${order_scriptname[$id]}"
        done
	echo -e "\e[0m\tMysqldump config file:  \e[1;32;40m$BASE_DIR/db_config/all_db_config.txt\e[0m"
        echo -e "\e[0m\t\e[1;31;40mPlease check all your variables has set coorectly!!\n\n\e[0m"


        echo -e "\tDeploy backup step :\e[1;33;40m"
        echo -e "\t\t-c <upload>                       Upload deploy_backup_2.0_20140212.tar.gz to remote DB (ip.txt contains)."
        echo -e "\t\t-c <verify_script>                Compare package MD5 between present zc and remote DB."
        echo -e "\t\t-c <check_connection>             Check mysqladmin pr (optional)"
        echo -e "\t\t-c <install_backup>               Install xtrabackup rpm and adding backup crontab"
        echo -e "\t\t-c <mysqldump_db>                 Excute one time mysqldump backup"
        echo -e "\t\t-c <xtrabackup_full_db>           Excute one time xtrabackup full backup"
        echo -e "\t\t-c <xtrabackup_inc_db>            Excute one time xtrabackup increment backup"
        echo -e "\t\t-c <check_mysqldump>              Check mysqldump result"
        echo -e "\t\t-c <check_xtrabackup_full>        Check xtrabackup full backup result"
        echo -e "\t\t-c <check_xtrabackup_increment>   Check xtrabackup increment backup result\e[0m"
}


case "${command}" in

        'upload')
        upload
        ;;

        'verify_script')
        verify_script
        ;;

        'check_connection')
        check_connection
        ;;

        'install_backup')
        install_backup
        ;;

        'mysqldump_db')
        mysqldump_db
        ;;

        'xtrabackup_full_db')
        xtrabackup_full_db
        ;;

        'xtrabackup_inc_db')
        xtrabackup_inc_db
        ;;

        'check_mysqldump')
        check_mysqldump
        ;;

        'check_xtrabackup_full')
        check_xtrabackup_full
        ;;

        'check_xtrabackup_increment')
        check_xtrabackup_increment
        ;;

        *)
        get_help
        ;;
esac
