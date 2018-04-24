#!/bin/bash
# all backup scripts
# character utf8
# create by zhangwen 2013-03-22
# modify by zhangshan 2014-01
# version 1.1 2013-06-06
# version 1.2 2013-06-06 init_env
# version 1.4 2013-06-18 init_env
# version 1.6 2013-06-18 file_name
# version 1.7 2013-06-18 file_name
# version 1.8 2013-07-18 file_name
# version 2.1 2013-01-05 by zhangshan. Rewrite xtrabackup_all and xtrabackup_increment. Support tar full dump file to backup xtrabakcup increment.
# version 2.2 2014-01-15 by zhangshan. Rewrite mysqldump backup. Simplify all_config.txt.
# version 2.3 2014-01-24 by zhangshan. Add some variables, truncate some config rows. 
# version 2.4 2014-02-25 by zhangshan. Fix some bugs and make script more readable.

SSH="ssh -oConnectionAttempts=2 -oConnectTimeout=5 -oStrictHostKeyChecking=no"
SCP="scp -oConnectionAttempts=2 -oConnectTimeout=5 -oStrictHostKeyChecking=no"

ACTION=$1

### You can define this variables when you modify it.###
### 1, this script name
SCRIPT_NAME=hw_backup_all.sh
### 2, mail list when backup failed
MAIL_LIST='zhangshan@cyou-inc.com liangxiaoliang@cyou-inc.com jiangyanguo@cyou-inc.com'
### 3, mysqldump_expire_time e.g 13 means retain 14days.(+mtime ${EXPIRE_TIME}-1)
EXPIRE_TIME='13'
### 4, xtrabackup_expire_time
XTR_EXPIRE_TIME='2'

### {{{ Define variables, Make dir
# export env
export PATH=${PATH}:/sbin/

#TIME=20131203-1603 DATE=20131203 Ltime=20131203-1603
TIME=`date +%Y%m%d-%H%M`
DATE=`date +%Y%m%d`
LTIME=`date -d "-1 hour" +'%Y%m%d%H'`


#######create databack DIR#######################
mkdir -p /home/databackup
BASE_DIR=/home/databackup
mkdir -p ${BASE_DIR}/scripts
mkdir -p ${BASE_DIR}/db_config
mkdir -p ${BASE_DIR}/log
mkdir -p ${BASE_DIR}/backup_mysqldump
mkdir -p ${BASE_DIR}/back_zip
mkdir -p ${BASE_DIR}/backup_xtrabackup

############ define scripts dir##################
SH_DIR=${BASE_DIR}/scripts

############ define DIR variables ###################
#BASE_DIR=/home/databackup
SH_DIR=${BASE_DIR}/scripts
CONF_DIR=${BASE_DIR}/db_config
LOG_DIR=${BASE_DIR}/log
BACK_ZIP=${BASE_DIR}/back_zip
DUMP_DIR=${BASE_DIR}/backup_mysqldump
XTR_DUMP_DIR=${BASE_DIR}/backup_xtrabackup

############ define LOG variables ###################
MYSQLDUMP_LOG=${LOG_DIR}/mysqldump_backup_${TIME}.log
XTR_full_LOG=${LOG_DIR}/xtr_backup_full_${TIME}.log
XTR_inc_LOG=${LOG_DIR}/xtr_backup_inc_${TIME}.log
ERROR_LOG=${LOG_DIR}/error_$DATE.log

## oracle sqlser
#mkdir -p ${BASE_DIR}/oracle
#ORA_DIR=${BASE_DIR}/oracle
#mkdir -p ${BASE_DIR}/sqlserver
#MS_DIR=${BASE_DIR}/sqlserver
function print_green()
{
        echo -e "\e[1;32;40m$1\e[0m"
}

function print_red()
{
        echo -e "\e[1;31;40m$1\e[0m"
}

function print_yellow()
{
        echo -e "\e[1;33;40m$1\e[0m"
}
###}}}  

###{{{ Initiate db_config.txt. Install xtrabackup, Add crontab jobs
### 安装部署 xtrabackup 
function install_xtrabackup()
{
#判断系统版本
if [ -s  /etc/redhat-release ] ;then 
        egrep -q "release 4" /etc/redhat-release && OS=4
        egrep -q "release 5" /etc/redhat-release && OS=5
        egrep -q "release 6" /etc/redhat-release && OS=6
else        
        egrep -q "release 4" /etc/issue && OS=4
        egrep -q "release 5" /etc/issue && OS=5
        egrep -q "release 6" /etc/issue && OS=6
fi  

echo -e "\e[1;33m###1, Begin install xtrbackup\e[0m"
if [ `rpm -qa | grep "xtrabackup-1" | wc -l` -eq 0 ]; then
        if [ $OS == 5 ] ; then
                rpm -ivh $BASE_DIR/scripts/xtrabackup-1.6.5-328.rhel5.x86_64.rpm --nodeps
		#if [ `rpm -qa | grep xtrabackup-debuginfo |wc -l` -gt 0  ] ; then
        	rpm -ivh $BASE_DIR/scripts/xtrabackup-debuginfo-1.6.5-328.rhel5.x86_64.rpm
		#fi
	elif [ $OS -ge 6 ]; then
		rpm -ivh $BASE_DIR/scripts/percona-xtrabackup-2.1.6-702.rhel6.x86_64.rpm --nodeps
                rpm -ivh $BASE_DIR/scripts/percona-xtrabackup-debuginfo-2.1.6-702.rhel6.x86_64.rpm
		rpm -ivh $BASE_DIR/scripts/perl-DBD-MySQL-4.013-3.el6.x86_64.rpm 
        elif [ $OS -ge 4 ]; then
                rpm -ivh $BASE_DIR/scripts/xtrabackup-1.5-7.rhel4.x86_64.rpm --nodeps
                ln -s /usr/bin/innobackupex-1.5.1 /usr/bin/innobackupex
        fi
fi
echo -e "\e[1;33m--->install_xtrbackup SUCCESS!<---\e[0m"
}

function add_crontab_jobs()
{
   #echo -e "Existed backup crontab:\n"
   sed -i "/${SCRIPT_NAME}/d" /var/spool/cron/root; sed -i "/#### ${SCRIPT_NAME}/d" /var/spool/cron/root
   echo -e "\e[1;33m###2, Adding backup crontab ......\e[0m"
   echo -e "####  ${SCRIPT_NAME} backup  #############" >> /var/spool/cron/root
   echo -e "00 4 * * * (/bin/bash ${SH_DIR}/${SCRIPT_NAME} mysqldump_backup)" >> /var/spool/cron/root
   echo -e "00 5 * * * (/bin/bash ${SH_DIR}/${SCRIPT_NAME} xtrabackup_all)" >> /var/spool/cron/root
   echo -e "30 * * * * (/bin/bash ${SH_DIR}/${SCRIPT_NAME} xtrabackup_inc)" >> /var/spool/cron/root
   if [ `crontab -l | grep ${SCRIPT_NAME}| wc -l` > 0 ];then
        echo -e '\e[1;33m--->add backup crontab SUCCESS!<---\e[0m'
	crontab -l | grep ${SCRIPT_NAME}
	echo -e '\e[1;32mPlease check other existed backup job in crontab!!! Please delete it in manual!!!\n\e[0m'
   fi
}
### }}}

### {{{ mysql: mysqldump_backup 
function mysqldump_backup()
{
  ###########create dbbackup list: db_config.txt from config/all_db_config.txt; automatic check ###############
  inet_ip=`/sbin/ifconfig |grep "inet addr:"| cut -d':' -f2 | awk '{ print $1}'|egrep '^192.|^172.|^10.'`
  if [ -f ${CONF_DIR}/all_db_config.txt ];then
  	if [ `grep $inet_ip ${CONF_DIR}/all_db_config.txt 2>/dev/null | wc -l` == 0 ]; then
		echo -e "\e[1;31m[error ${inet_ip}] No record in ${CONF_DIR}/all_db_config.txt. \nThis may cause dump failed! \nPlease check this DB information in ${CONF_DIR}/all_db_config.txt\e[0m" | tee -a ${ERROR_LOG}
		mail -s "Mysqldump backup Failed! Please check!!!" ${MAIL_LIST} < ${ERROR_LOG}
		echo "" > ${CONF_DIR}/db_config.txt
	else
		grep $inet_ip ${CONF_DIR}/all_db_config.txt > ${CONF_DIR}/db_config.txt
		echo -e "\e[1;32m(note:Backup file ${CONF_DIR}/db_config.txt has been created from ${CONF_DIR}/all_db_config.txt)\e[0m"
	fi
  else
	echo -e "\e[1;33mplease check whether ${CONF_DIR}/all_db_config.txt is exist! \nNothing to do. Exit!\e[0m"
	exit
  fi

  egrep -v '^#|^$' ${BASE_DIR}/db_config/db_config.txt| grep '^dump'| while read line
  do
  REGION=`echo ${line}|awk '{print $2}'`
  PRODUCT=`echo ${line}|awk '{print $3}'`
  IP=`echo ${line}|awk '{print $5}'| awk -F. '{print $3"."$4}'` 
  CARACHTER=`echo ${line}|awk '{print $7}'`
  PORT=`echo ${line}|awk '{print $8}'`
  PRODUCT_STATUS=`echo ${line}|awk '{print $10}'`
  ZONE=`echo ${line}|awk '{print $11}'`
  DBNAME=`echo ${line}|awk '{print $12}'`
  FILENAME=${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_dump_${PRODUCT_STATUS}_${DBNAME}_${TIME}_full.sql.gz
  FILENAME1=${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_dump_${PRODUCT_STATUS}_${DBNAME}_${TIME}_full.sql.gz*

	cd $DUMP_DIR
	###Begin mysqldump
        mysqldump -h127.0.0.1 -uroot -P $PORT --default-character-set=${CARACHTER} \
        --single-transaction -q -R --triggers -B ${DBNAME} 2>$DUMP_DIR/tmp_dump.log |gzip > ${FILENAME}

	###check result. If success, then add md5. If failed, mail me. 
	###Reserve 1st per month backup file
	###Delete over 15days files.
        if [ `cat $DUMP_DIR/tmp_dump.log | grep error | wc -l` == 0 ];then
		#add success log
		echo "${IP} mysqldump success."| tee -a ${MYSQLDUMP_LOG}
                #get md5sum and file size
                filesize=`ls -l ${DUMP_DIR}/${FILENAME} | awk '{print $5}'`
                filemd5=`md5sum ${DUMP_DIR}/${FILENAME} | awk '{print $1}'`
                echo "$filemd5 $filesize" > ${DUMP_DIR}/${FILENAME}.md5

		### cp ${DUMP_DIR} to back_zip. Summary gz to one file. Delete older than 1days file in this file.
		cp -rp ${DUMP_DIR}/${FILENAME}* ${BACK_ZIP}
		find ${DUMP_DIR}/ -mtime +0 -type f -name "*_dump_*.sql*" | xargs rm -fr "{}" \;
                ### chattr +i for permanent backup files
                chattr +i ${BACK_ZIP}/${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_dump_${PRODUCT_STATUS}_${DBNAME}_201*01-*_full.sql.gz* 2>/dev/null
                ### delete *-dump-*.gz ${EXPIRE_TIME} days ago.
		### If home disk storage is larger than 85%, then delete 7 days ago ###
		DISK=`df -h | grep home | awk '{print $5}' | awk -F'%' '{print $1}'`
		if [ $DISK -gt 85 ]; then
			find ${BACK_ZIP}/ -mtime +6 -type f -name "*_dump_*.sql*" | xargs rm -fr "{}" \;
		else
	                find ${BACK_ZIP}/ -mtime +${EXPIRE_TIME} -type f -name "*_dump_*.sql*" | xargs rm -fr "{}" \;
		fi
        else
                echo "[error ${TIME} ${IP}] mysqldump backup failed. Please test mysqldump manually to find reason" | tee -a ${ERROR_LOG}
		mail -s "Mysqldump backup Failed! Please check!!!" ${MAIL_LIST} <  ${ERROR_LOG}
		rm -rf $DUMP_DIR/tmp_dump.log
        fi  
done
}
### }}}  

##  {{{ #mysql: xtrabackup_all
function xtrabackup_all()
{
  egrep -v '^#|^$' ${BASE_DIR}/db_config/db_config.txt | head -1 | while read line
  do
    REGION=`echo ${line}|awk '{print $2}'`
    PRODUCT=`echo ${line}|awk '{print $3}'`
    IP=`echo ${line}|awk '{print $5}'| awk -F. '{print $3"."$4}'`
    PRODUCT_STATUS=`echo ${line}|awk '{print $10}'`
    ZONE=`echo ${line}|awk '{print $11}'`

    for SOCK in `ls /home/mysql*/mysql.sock`  
    do
            DATADIR=`echo $SOCK | awk -F '/' '{print $3}'`
            PORT=`echo $DATADIR | awk -F '_' '{print $2}'`
            mkdir -p ${XTR_DUMP_DIR}/full/${DATADIR}
            FULLDIR=${XTR_DUMP_DIR}/full/${DATADIR}
            MYCNF=${FULLDIR}/${PORT}.cnf
    	    FILENAME=${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_xtr_${PRODUCT_STATUS}_${TIME}_full.tar.gz
    	    FILENAME1=${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_xtr_${PRODUCT_STATUS}_*_full.*
            
            if [ `date +%d` -eq '01' ]
            then
                  echo > ${XTR_full_LOG}
            fi
            
            if [ `ls /home/mysql/mysql.sock 2>/dev/null | wc -l` -eq 1 ]
            then
              innobackupex --socket=/home/${DATADIR}/mysql.sock  ${FULLDIR}/${TIME} --no-timestamp --throttle=100  1>> ${XTR_full_LOG} 2>&1  
            else
                  egrep "mysqld${PORT}|datadir|innodb_data_file_path|innodb_log_file_size|innodb_log_files_in_group" /etc/my.cnf | grep -A4 "mysqld${PORT}" | sed "s/mysqld${PORT}/mysqld/g" > ${MYCNF}
                  innobackupex --socket=/home/${DATADIR}/mysql.sock --defaults-file=${MYCNF} ${FULLDIR}/${TIME}  --no-timestamp --throttle=100  1>> ${XTR_full_LOG} 2>&1
            fi
            
            if [ $? -eq 0 ]
            then
                 rm -f ${FULLDIR}/xtrabackup_checkpoints && cp ${FULLDIR}/${TIME}/xtrabackup_checkpoints ${FULLDIR} 1>> ${XTR_full_LOG} 2>&1
  		 cd ${FULLDIR} && tar -czf ${FILENAME} ${TIME} && rm -rf ${TIME} 1>> ${XTR_full_LOG} 2>&1
                 #get md5sum and file size
                 filesize=`ls -l ${FULLDIR}/${FILENAME} | awk '{print $5}'`
                 filemd5=`md5sum ${FULLDIR}/${FILENAME} | awk '{print $1}'`
                 echo "$filemd5 $filesize" > ${FULLDIR}/${FILENAME}.md5

		 ### cp ${DUMP_DIR} to back_zip. Summary gz to one file. Delete older than 1days file in this file.
		 cp -rp ${FULLDIR}/${FILENAME}* ${BACK_ZIP}
		 find ${FULLDIR}/ -mtime +0 -type f -name "*_xtr_*_full.tar.gz*" | xargs rm -fr "{}" \;

		 ### delete back_zip dir xtrabackup full backup before 7days ago ###
		 find ${BACK_ZIP}/ -mtime +${XTR_EXPIRE_TIME} -type f -name "*_xtr_*_full.tar.gz*" | xargs rm -fr "{}" \;
            else
                  echo "[error ${TIME} ${IP}] innobackex full backup failed. Please check ${XTR_full_LOG}" | tee -a ${ERROR_LOG}
 		  mail -s "Xtrabackup backup Failed! Please check!!!" ${MAIL_LIST} <  ${ERROR_LOG}
            fi
    done
done
}

 ## }}} 

## {{{  #mysql: xtrabackup_increment

function xtrabackup_inc()
{
  egrep -v '^#|^$' ${BASE_DIR}/db_config/db_config.txt | head -1 | while read line
  do
    REGION=`echo ${line}|awk '{print $2}'`
    PRODUCT=`echo ${line}|awk '{print $3}'`
    IP=`echo ${line}|awk '{print $5}'| awk -F. '{print $3"."$4}'`
    PRODUCT_STATUS=`echo ${line}|awk '{print $10}'`
    ZONE=`echo ${line}|awk '{print $11}'`

    for SOCK in `ls /home/mysql*/mysql.sock`
    do
            DATADIR=`echo $SOCK | awk -F '/' '{print $3}'`
            PORT=`echo $DATADIR | awk -F '_' '{print $2}'`
            mkdir -p ${XTR_DUMP_DIR}/incre/${DATADIR}
            INCDIR=${XTR_DUMP_DIR}/incre/${DATADIR}
            FULLDIR=${XTR_DUMP_DIR}/full/${DATADIR}
            MYCNF=${FULLDIR}/${PORT}.cnf
    	    FILENAME=${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_xtr_${PRODUCT_STATUS}_${TIME}_inc.tar.gz
    	    FILENAME1=${REGION}_${PRODUCT}_${ZONE}_${IP}_mysql_${PORT}_xtr_${PRODUCT_STATUS}_${TIME}_inc.tar.gz.*
            
            if [ `date +%d` -eq '01' ]
            then
               echo > ${XTR_inc_LOG}
            fi
            
            if [ `ls /home/mysql/mysql.sock 2>/dev/null | wc -l` -eq 1 ]
            then
                  innobackupex --socket=/home/${DATADIR}/mysql.sock ${INCDIR}/${TIME} --incremental --incremental-basedir=${FULLDIR} --no-timestamp --throttle=100  1>> ${XTR_inc_LOG} 2>&1
            else
                  innobackupex --socket=/home/${DATADIR}/mysql.sock --defaults-file=${MYCNF} ${INCDIR}/${TIME} --incremental --incremental-basedir=${FULLDIR} --no-timestamp --throttle=100  1>> ${XTR_inc_LOG} 2>&1
            fi
            
            if [ $? -eq 0 ]
            then
                  cd ${INCDIR} && tar -czf ${FILENAME} ${TIME} && rm -rf ${TIME} 1>> ${XTR_inc_LOG} 2>&1
                  #get md5sum and file size
                  filesize=`ls -l ${INCDIR}/${FILENAME} | awk '{print $5}'`
                  filemd5=`md5sum ${INCDIR}/${FILENAME} | awk '{print $1}'`
                  echo "$filemd5 $filesize" > ${INCDIR}/${FILENAME}.md5

                  ### cp ${DUMP_DIR} to back_zip. Summary gz to one file. Delete older than 1days file in this file.
                  cp -rp ${INCDIR}/${FILENAME}* ${BACK_ZIP}
                  find ${INCDIR}/ -mtime +0 -type f -name "*_xtr_*_inc.tar.gz*" | xargs rm -fr "{}" \;
 
                  ### delete back_zip dir xtrabackup increment backup before 7days ago ###
                  find ${BACK_ZIP}/ -mtime +${XTR_EXPIRE_TIME} -type f -name "*_xtr_*_inc.tar.gz*" | xargs rm -fr "{}" \;
            else
                  echo "[error ${TIME}] Xtrabakcup increment backup failed. Please check ${XTR_inc_LOG}" | tee -a ${ERROR_LOG}
  		  mail -s "Xtrabackup increment backup Failed! Please check!!!" ${MAIL_LIST} <  ${ERROR_LOG}
            fi
    done
done
}
### }}}    

### {{{ [Temporary useless] oracle exp
oracle_exp_backup()
{
  egrep -v '^#|^$' ${BASE_DIR}/db_config/db_config.txt| grep '^oracle'|while read line
  do
  D_TYPE=`echo ${line}|awk '{print $1}'`
  REGION=`echo ${line}|awk '{print $2}'`
  PRODUCT=`echo ${line}|awk '{print $3}'`
  TYPE=`echo ${line}|awk '{print $4}'`
  IP=`echo ${line}|awk '{print $5}'`
  BAK_TYPE=`echo ${line}|awk '{print $6}'`
  CARACHTER=`echo ${line}|awk '{print $7}'`
  PORT=`echo ${line}|awk '{print $8}'`
  RESERVE_DAYS=`echo ${line}|awk '{print $9}'`
  PRODUCT_STATUS=`echo ${line}|awk '{print $10}'`
  ZONE=`echo ${line}|awk '{print $11}'`
  DBNAME=`echo ${line}|awk '{print $12}'`
  FILENAME=${REGION}_${PRODUCT}_${ZONE}_${IP}_${TYPE}_${PORT}_${D_TYPE}_${PRODUCT_STATUS}_${DBNAME}_${TIME}_full.sql.gz
  FILENAME1=${REGION}_${PRODUCT}_${ZONE}_${IP}_${TYPE}_${PORT}_${D_TYPE}_${PRODUCT_STATUS}_${DBNAME}_*_full.sql.gz*

  ORA_TIME=`date +%Y%m%d`
  expdir='/home/oracle/backup_stage/exp'

  #执行逻辑备份脚本
  su - oracle -c "/bin/bash /home/oracle/scripts/expdpfull.sh"
  #执行rman备份脚本
  #su - oracle -c "/bin/bash $HOME/scripts/expdpfull.sh"

  # 拷贝副本 压缩处理
  cd $expdir
  zip -r $FILENAME *_$ORA_TIME*
  #get md5sum and file size
  filesize=`ls -l ${expdir}/${FILENAME} | awk '{print $5}'`
  filemd5=`md5sum ${expdir}/${FILENAME} | awk '{print $1}'`
  echo "$filemd5 $filesize" > ${expdir}/${FILENAME}.md5
  mv ${FILENAME}* ${BACK_ZIP}
  done
}
### }}} 

### {{{  [Temporary useless] oracle RMAN
oracle_rman_backup()
{
  egrep -v '^#|^$' ${BASE_DIR}/db_config/db_config.txt| grep '^oracle'|while read line
  do
  D_TYPE=`echo ${line}|awk '{print $1}'`
  REGION=`echo ${line}|awk '{print $2}'`
  PRODUCT=`echo ${line}|awk '{print $3}'`
  TYPE=`echo ${line}|awk '{print $4}'`
  IP=`echo ${line}|awk '{print $5}'`
  BAK_TYPE=`echo ${line}|awk '{print $6}'`
  CARACHTER=`echo ${line}|awk '{print $7}'`
  PORT=`echo ${line}|awk '{print $8}'`
  RESERVE_DAYS=`echo ${line}|awk '{print $9}'`
  PRODUCT_STATUS=`echo ${line}|awk '{print $10}'`
  ZONE=`echo ${line}|awk '{print $11}'`
  DBNAME=`echo ${line}|awk '{print $12}'`
  FILENAME=${REGION}_${PRODUCT}_${ZONE}_${IP}_${TYPE}_${PORT}_${D_TYPE}_${PRODUCT_STATUS}_${DBNAME}_${TIME}_full.sql.gz
  FILENAME1=${REGION}_${PRODUCT}_${ZONE}_${IP}_${TYPE}_${PORT}_${D_TYPE}_${PRODUCT_STATUS}_${DBNAME}_*_full.sql.gz*

  HOT_TIME=`date +%y%m%d`
  hotdir='/home/oracle/backup_stage/hotbak'
  backup_sh='/home/oracle/scripts/rmanbak.sh'
  #执行rman备份脚本
  su - oracle -c "/bin/bash ${backup_sh}"
  #拷贝副本 压缩处理
  cd $hotdir
  zip -r $FILENAME $HOT_TIME*
  #get md5sum and file size
  filesize=`ls -l ${hotdir}/${FILENAME} | awk '{print $5}'`
  filemd5=`md5sum ${hotdir}/${FILENAME} | awk '{print $1}'`
  echo "$filemd5 $filesize" > ${hotdir}/${FILENAME}.md5
  mv ${FILENAME}* ${BACK_ZIP}
  done
}
### }}} 

#exec 3>&1 4>&2 1>>$LOGFILE 2>&1

### {{{ CASE
case ${ACTION} in
  'install_xtrabackup')
   install_xtrabackup
  ;;

  'add_crontab_jobs')
   add_crontab_jobs
  ;;

  'mysqldump_backup')
   mysqldump_backup
  ;;

  'xtrabackup_all')
   xtrabackup_all
  ;;

  'xtrabackup_inc')
   xtrabackup_inc
  ;;
  *)
  print_yellow "\tPlease input below commends"
  print_yellow "\tCommend:\t\tDescription:"
  print_green "\tinstall_xtrabackup\t#Install xtrabackup rpm packages"
  print_green "\tadd_crontab_jobs\t#Add backup crontab jobs"
  print_green "\tmysqldump_backup\t#Type:mysqldump full backup"
  print_green "\txtrabackup_all\t\t#Type:innobackupex full back and tar"
  print_green "\txtrabackup_inc\t\t#Type:innobackupex increment back and tar"

  echo 
  ;;
esac
### }}}
