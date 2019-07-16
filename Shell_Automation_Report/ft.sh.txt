#!/bin/bash
#####################################################################
#   This Script is used for automatically generating FT             #
#   Daily Report and will also check the balance between Dashboard  # 
#   and Daily report using Beijing timezone.                        #
#   If everything is good, then sending this report to the Email    #
#   List and also send it to ftp automatically. Otherwise, it will  #
#   sending the error message to Email List.                        #
#                                                                   #
#   Version 1, 2019-06-25, by Sandy Zhang, sandy@xxx.com            #          
#####################################################################

export LANG=en_US.UTF-8

############ Define Base Dir        ################### 
# BASE_DIR="/home/sandy/ubuntu/ft_travel"
BASE_DIR="/home/ubuntu/ft_travel"
# format: 2019-06-19
TRANSACTION_DATE=`date -d "1 day ago" +%Y-%m-%d`

############ Define Email List      ###################
MAIL_LIST='sandy@xxx.com nathan@xxx.com'
# MAIL_LIST='sandy@xxx.com'

# Make directory  
mkdir -p ${BASE_DIR}
mkdir -p ${BASE_DIR}/FT_DAILY_REPORT/${TRANSACTION_DATE}
mkdir -p ${BASE_DIR}/FT_LOG
mkdir -p ${BASE_DIR}/FT_DASHBOARD

# Useful directory 
REPORT_DIR="${BASE_DIR}/FT_DAILY_REPORT/${TRANSACTION_DATE}"
LOG_DIR=${BASE_DIR}/FT_LOG
DASHBOARD_DIR=${BASE_DIR}/FT_DASHBOARD

# Useful files name
# Daily report file name
report_filename="${TRANSACTION_DATE}.csv";
# report_filename="TEST_${TRANSACTION_DATE}_`date '+%H%M%S'`.csv"

# Dashboard Daily report file name
dashboard_filename="Dashboard_FT_Daily_Result_${TRANSACTION_DATE}.csv";
# Log file name
log_filename="FT_${TRANSACTION_DATE}.txt"
# Ftp log file name
ftp_log_filename="FTP_FT_${TRANSACTION_DATE}.txt"
# flag status
# 0 - everything is ok,amount is positive, success send file to ftp, 
# 1 - Amount not equal between Dashboard and Report
# 2 - No data on that day
# 3 - FTP transfer fail
flag=0
# clear the log file
cp /dev/null ${LOG_DIR}/${log_filename}


# 1, Get amount from FT Dashboard. Sql comes from merchant portal (reporting.php line 28).
mysql -h $RDS_SERVER_READ -u $RDS_USER --password=$RDS_PASSWORD -e " 
SELECT
	DATE( CONVERT_TZ( method_pay_time, 'America/New_York', 'Asia/Shanghai' ) ) AS date,
	count( total ) AS num_tran,
	ROUND(SUM( total )/100, 2) AS gross,
	ROUND(SUM( merchant_discount +  merchant_fixed )/100, 2) AS discount,
	ROUND(SUM( CASE WHEN vendor IN ( 'WXP', 'wechatpay' ) THEN total - merchant_discount - merchant_fixed ELSE 0 END )/100, 2) AS wechat,
	ROUND(SUM( CASE WHEN vendor IN ( 'ALP', 'alipay' ) THEN total - merchant_discount - merchant_fixed ELSE 0 END )/100, 2) AS alipay,
	ROUND(SUM(total - merchant_discount - merchant_fixed)/100, 2) as 'Net (Settlement Amount)'
FROM
	settlement.processed_transactions pt
	JOIN settlement.merchant_info m ON pt.merchant_id = m.merchant_id 
WHERE
	m.merchant_name like ( '%ft%' ) 
	AND date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) = date_format( now( ) - INTERVAL 1 DAY, '%Y-%m-%d' )
GROUP BY
	DATE( CONVERT_TZ( pt.method_pay_time, 'America/New_York', 'Asia/Shanghai' ) )  " |sed 's/\t/","/g;s/^/"/;s/$/"/' > ${DASHBOARD_DIR}/${dashboard_filename}

dashboard_gross=`sudo cat ${DASHBOARD_DIR}/${dashboard_filename}  | awk  -F'","'  '{sum += $3} END {print sum}'`; 

[ ! ${dashboard_gross} ] && dashboard_gross=0


# 2, Get FT Daily Report. This report will send to ftp and Email List. 
mysql -h $RDS_SERVER_READ -u $RDS_USER --password=$RDS_PASSWORD -e "
	SELECT 
	substring_index(note,'_', 1) as 'Channel ID', 
    transaction_id as 'Transaction ID', 
    CONVERT_TZ(notify_time,'America/New_York', 'Asia/Shanghai' ) as 'Date/Time',
    substring_index(substring_index(note,'_', -2), '_', 1) as 'Name', 
	substring_index(note,'_', -1) as 'Email', 
    total as 'Amount'
FROM alipay.transactions t join alipay.partners p on t.partner_id = p.partner_id
WHERE
partner_name LIKE 'ft%'
AND notify_result='success'
AND date_format( DATE( CONVERT_TZ( ( notify_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) = date_format( now( ) - INTERVAL 1 DAY, '%Y-%m-%d' )
ORDER BY 3 DESC
" |sed 's/\t/","/g;s/^/"/;s/$/"/' > ${REPORT_DIR}/${report_filename}
			
# Get amount from reports. SQL comes from Meta database  
report_gross_amount=`sudo cat ${REPORT_DIR}/${report_filename} | awk  -F',"'  '{sum += $6} END {print sum}'`;

[ ! ${report_gross_amount} ] && report_gross_amount=0;
 

# check the balance
echo "Transaction Date: `echo ${TRANSACTION_DATE}`" >> ${LOG_DIR}/${log_filename}

# If balance are equal between Dashboard and Daily report, then write details in logfile. Otherwise, write error msg in logfile.
if [ "${dashboard_gross}x" == "${report_gross_amount}x" ];then
	echo "Gross Amount:${report_gross_amount}   .................................[ok]"  >> ${LOG_DIR}/${log_filename}
else
	echo "Gross Amount:           .................................[error]"  >> ${LOG_DIR}/${log_filename}
	echo "Dashboard Gross Amount: ${dashboard_gross} " >> ${LOG_DIR}/${log_filename}
	echo "Report Gross Amount      : ${report_gross_amount} " >> ${LOG_DIR}/${log_filename}
	flag=1
fi

# if no data during that day, then write log
if [ "${dashboard_gross}x" == "0x" -a "${report_gross_amount}x" == "0x" ];then
		echo "Transaction Date: `echo ${TRANSACTION_DATE}`" >   ${LOG_DIR}/${log_filename}
		echo "No transactions! No need to transfer to FTP." >>  ${LOG_DIR}/${log_filename}
		flag=2
fi

# transfer file to ftp
if [ "${flag}x" == "0x" -a "${flag}x" != "2x" ];then
	# ftp
	PUTFILE_DIRECTORY=${REPORT_DIR}
	PUTFILE=${report_filename}
	
	exec 6>&1 1>${LOG_DIR}/${ftp_log_filename}
	
	ftp -v -n example.ca<<EOF
	user log@example.ca afntnrfw@#$
	binary
	cd /
	lcd ${PUTFILE_DIRECTORY}
	prompt
	passive
	put $PUTFILE
	bye
	#here document
EOF
	exec 1>&6    
	exec 6>&-     
	if grep -q 'File successfully transferred' ${LOG_DIR}/${ftp_log_filename}; then  
		echo "Transfer to FTP:  .................................[ok]" >> ${LOG_DIR}/${log_filename}
	else 
		flag=3; 
		echo "" >> ${LOG_DIR}/${log_filename}
		echo "Failue to transfer file to FTP:   .................................[error]" >> ${LOG_DIR}/${log_filename}
	fi
fi

#  If the number matchs, then will send Email. 
# echo ${flag}x
# echo 0x
echo "" >> ${LOG_DIR}/${log_filename}
if [ "${flag}x" == "0x" ];then
	echo "Nothing need to do. " >> ${LOG_DIR}/${log_filename}
	sudo mutt -s "SUCCESS -- Email Subject: ft Daily Report ${TRANSACTION_DATE}" ${MAIL_LIST} -a ${REPORT_DIR}/${report_filename} < ${LOG_DIR}/${log_filename}
elif [ "${flag}x" == "1x" ];then
	echo "Failue to transfer file to FTP:   .................................[error]" >> ${LOG_DIR}/${log_filename}
	echo "Please re-run the report munually! And transfer to FTP manually!"  >> ${LOG_DIR}/${log_filename}
	sudo mutt -s "ERROR -- Email Subject: ft Daily Report ${TRANSACTION_DATE}" ${MAIL_LIST} < ${LOG_DIR}/${log_filename}
elif [ "${flag}x" == "2x" ];then
	echo "Nothing need to do. " >> ${LOG_DIR}/${log_filename}
	sudo mutt -s "NO DATA -- Email Subject: ft Daily Report ${TRANSACTION_DATE}" ${MAIL_LIST} < ${LOG_DIR}/${log_filename}
elif [ "${flag}x" == "3x" ];then
	echo "Please transfer the attached to FTP manually!"  >> ${LOG_DIR}/${log_filename}
	sudo mutt -s "ERROR -- Email Subject: ft Daily Report ${TRANSACTION_DATE}" ${MAIL_LIST} -a ${REPORT_DIR}/${report_filename} < ${LOG_DIR}/${log_filename}
fi

# remove file in mysql file directory
# sudo find ${MYSQL_TMP_DIR} -mtime +1 -name "*NM*.csv" -exec rm -rf {} \;

<<'COMMENT'
COMMENT