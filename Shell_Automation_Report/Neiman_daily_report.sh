#!/bin/bash
#####################################################################
#   This Script is used for automatically generating Nei            #
#   Daily Report and will also check the balance between Dashboard  #
#   and Daily report.                                               #
#   If everything is good, then sending this report to the Email    #
#   List. Otherwise, it will sending the error message to Email     #
#   List.                                                           #
#                                                                   #
#   Version 1, 2019/3/20, by Sandy Zhang, sandy@example.com         #
#####################################################################
export LANG=en_US.UTF-8

############ Define Base Dir        ###################
BASE_DIR="/home/ubuntu/Nei_man"

############ Define Email List      ###################
MAIL_LIST='sandy@example.com 

# Useful directory
CURRENT_DATE=`date +%Y-%m-%d`
REPORT_DIR="${BASE_DIR}/NM_DAILY_REPORT/${CURRENT_DATE}"
MYSQL_TMP_DIR="/tmp"
LOG_DIR=${BASE_DIR}/NM_LOG

# Make directory
mkdir -p ${BASE_DIR}
mkdir -p ${BASE_DIR}/NM_DAILY_REPORT/${CURRENT_DATE}
mkdir -p ${BASE_DIR}/NM_LOG
mkdir -p ${BASE_DIR}/NM_DASHBOARD

# Useful files name
# Daily report file name
report_filename="NM_`date '+%Y-%m-%d_%H%M%S'`.csv";
# Dashboard Daily report file name
dashboard_filename="Dashboard_NM_Daily_Result_`date '+%Y-%m-%d_%H%M%S'`.csv";
# Log file name
log_filename="${CURRENT_DATE}.txt"
# Record all dashboard data with email's date
dashboard_history_file="${BASE_DIR}/NM_DASHBOARD/Dashboard_NM_Daily_Result_history.csv"
# error flag 0 - ok
flag=0
# clear the log file
cp /dev/null ${LOG_DIR}/${log_filename}

# Depend on the day of week to decide which report(date range) to use.
day_of_week=`date -d "${date}" +%w` ;
case ${day_of_week} in
        3|4|5)
                        echo "Run Wed, Thur, Fri's Report!" > ${LOG_DIR}/${log_filename}
                        start_date=2;
                        end_date=2;
                        range_date="^\\\"`date -d '-2 day' +%Y-%m-%d`"
                ;;
        1)
                        echo "Run Monday's Report!" > ${LOG_DIR}/${log_filename}
                        start_date=4;
                        end_date=4;
                        range_date="^\\\"`date -d '-4 day' +%Y-%m-%d`"
        ;;
        2)
                        echo "Run Tuesday's Report!" > ${LOG_DIR}/${log_filename}
                        start_date=4;
                        end_date=2;
                        range_date="^\\\"`date -d '-4 day' +%Y-%m-%d`|^\\\"`date -d '-3 day' +%Y-%m-%d`|^\\\"`date -d '-2 day' +%Y-%m-%d`"
        ;;
esac

# 1, Get amount from NM Dashboard. Sql comes from merchant portal (reporting_beijing.php line 28).
mysql -h $RDS_SERVER_READ -u $RDS_USER --password=$RDS_PASSWORD -e "
SELECT
        DATE( CONVERT_TZ( method_pay_time, 'America/New_York', 'Asia/Shanghai' ) ) AS date,
        count( total ) AS num_tran,
        ROUND(SUM( total )/100, 2) AS gross,
        ROUND(SUM( merchant_discount +  merchant_fixed )/100, 2) AS discount,
        ROUND(SUM( CASE WHEN vendor IN ( 'WXP', 'wechatpay' ) THEN total - merchant_discount - merchant_fixed ELSE 0 END )/100, 2) AS wechat,
        ROUND(SUM( CASE WHEN vendor IN ( 'ALP', 'alipay' ) THEN total - merchant_discount - merchant_fixed ELSE 0 END )/100, 2) AS alipay,
        ROUND(SUM(total - merchant_discount - merchant_fixed)/100, 2) as 'Net (dbname2 Amount)'
FROM
        dbname2.ptransactions pt
        JOIN dbname2.merchant_info m ON pt.merchant_id = m.merchant_id
WHERE
        m.merchant_name like ( '%Nei%' )
        AND date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) between date_format( now( ) - INTERVAL ${start_date} DAY, '%Y-%m-%d' ) and  date_format( now( ) - INTERVAL ${end_date} DAY, '%Y-%m-%d' )
GROUP BY
        DATE( CONVERT_TZ( pt.method_pay_time, 'America/New_York', 'Asia/Shanghai' ) )  " |sed 's/\t/","/g;s/^/"/;s/$/"/g' > ${MYSQL_TMP_DIR}/${dashboard_filename}

dashboard_wxp=`sudo cat ${MYSQL_TMP_DIR}/${dashboard_filename}| grep -E "${range_date}" | awk  -F'","'  '{sum += $5} END {print sum}'`;
dashboard_alp=`sudo cat ${MYSQL_TMP_DIR}/${dashboard_filename}| grep -E "${range_date}" | awk  -F'","'  '{sum += $6} END {print sum}'`;

[ ! ${dashboard_wxp} ] && dashboard_wxp=0;
[ ! ${dashboard_alp} ] && dashboard_alp=0;

# 2, Get NM Daily Report. This report will send to Email List.
mysql -h $RDS_SERVER_READ -u $RDS_USER --password=$RDS_PASSWORD -e "
        select
        Beijing_Transaction_Date as 'Beijing Transaction Date',
        CST_Transaction_Time     as 'CST Transaction Time',
        date_add(CST_Transaction_Time, interval offset hour) as 'Store Transaction Time',
        merchant_id              as 'Merchant id',
        Store_id                 as 'Store #',
        Till_id                  as 'Till #',
        store_transaction_id     as 'Store Transaction ID #',
        Transaction_Type         as 'Transaction Type',
        Dr_Or_Cr                 as 'Dr Or Cr',
        Amount,
        dbname2_Date          as 'dbname2 Date',
        RP_ID              as 'RP ID#',
        Alipay_or_Wechat         as 'Alipay or Wechat'
from (
                SELECT
                n.*,
                s.offset
                FROM
                        (SELECT
                                date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) AS 'Beijing_Transaction_Date',
                                date_format(  CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'America/Chicago' ) , '%Y-%m-%d %T' ) AS 'CST_Transaction_Time',
                                pt.merchant_id,
                        CASE

                                        WHEN b.DATA LIKE '%\"Store\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"Store\":\"', b.DATA ) + length( '\"Store\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"Store\":\"', b.DATA ) + length( '\"Store\":\"' ) ) - LOCATE( '\"Store\":\"', b.DATA ) - length( '\"Store\":\"' )
                                        ) ELSE ''
                                END AS 'Store_id',
                        CASE

                                        WHEN b.DATA LIKE '%\"Till\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"Till\":\"', b.DATA ) + length( '\"Till\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"Till\":\"', b.DATA ) + length( '\"Till\":\"' ) ) - LOCATE( '\"Till\":\"', b.DATA ) - length( '\"Till\":\"' )
                                        ) ELSE ''
                                END AS 'Till_id',
                        CASE

                                        WHEN b.DATA LIKE '%\"store_transaction_id\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"store_transaction_id\":\"', b.DATA ) + length( '\"store_transaction_id\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"store_transaction_id\":\"', b.DATA ) + length( '\"store_transaction_id\":\"' ) ) - LOCATE( '\"store_transaction_id\":\"', b.DATA ) - length( '\"store_transaction_id\":\"' )
                                        ) ELSE ''
                                END AS 'store_transaction_id',
                                ( CASE pt.transaction_type WHEN 'pos_payment' THEN 'Sale' WHEN 'pos_refund' THEN 'Return' END ) AS 'Transaction_Type',
                                ( CASE pt.transaction_type WHEN 'pos_payment' THEN 'DR' WHEN 'pos_refund' THEN 'CR' END ) AS 'DR_or_CR',
                                ABS( ROUND( pt.total / 100, 2 ) ) AS 'Amount',
                        CASE
                                        WHEN DAYOFWEEK( pt.time_settled ) = 6 AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 3 DAY, '%Y-%m-%d' )
                                        WHEN DAYOFWEEK( pt.time_settled ) = 7 AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 2 DAY, '%Y-%m-%d' )
                                        WHEN DAYOFWEEK( pt.time_settled) in (2,3,4,5) AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 1 DAY, '%Y-%m-%d' )
                                        ELSE date_format( pt.time_settled, '%Y-%m-%d' )
                                END AS 'dbname2_date',
                                pt.transaction_id AS 'RP_ID',
                                pt.vendor AS 'Alipay_or_Wechat'
                        FROM
                                dbname2.ptransactions pt
                                left join dbname1.transaction_additional_info b on pt.transaction_id = b.transaction_id
                                join dbname2.merchant_info m on pt.merchant_id = m.merchant_id
                        WHERE
                                m.merchant_name LIKE '%Nei%'
                                AND date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) between date_format( now( ) - INTERVAL ${start_date}  DAY, '%Y-%m-%d' ) and  date_format( now( ) - INTERVAL  ${end_date} DAY, '%Y-%m-%d' )
                        HAVING
                                dbname2_date <= now()
                        UNION ALL
                        SELECT
                                date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) AS 'Beijing_Transaction_Date',
                                date_format(  CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'America/Chicago' ) , '%Y-%m-%d %T' ) AS 'CST_Transaction_Time',
                                pt.merchant_id,
                        CASE

                                        WHEN b.DATA LIKE '%\"Store\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"Store\":\"', b.DATA ) + length( '\"Store\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"Store\":\"', b.DATA ) + length( '\"Store\":\"' ) ) - LOCATE( '\"Store\":\"', b.DATA ) - length( '\"Store\":\"' )
                                        ) ELSE ''
                                END AS 'Store_id',
                        CASE

                                        WHEN b.DATA LIKE '%\"Till\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"Till\":\"', b.DATA ) + length( '\"Till\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"Till\":\"', b.DATA ) + length( '\"Till\":\"' ) ) - LOCATE( '\"Till\":\"', b.DATA ) - length( '\"Till\":\"' )
                                        ) ELSE ''
                                END AS 'Till_id',
                        CASE

                                        WHEN b.DATA LIKE '%\"store_transaction_id\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"store_transaction_id\":\"', b.DATA ) + length( '\"store_transaction_id\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"store_transaction_id\":\"', b.DATA ) + length( '\"store_transaction_id\":\"' ) ) - LOCATE( '\"store_transaction_id\":\"', b.DATA ) - length( '\"store_transaction_id\":\"' )
                                        ) ELSE ''
                                END AS 'store_transaction_id',
                                'Fees',
                                ( CASE pt.transaction_type WHEN 'pos_payment' THEN 'DR' WHEN 'pos_refund' THEN 'CR' END ) AS 'DR_or_CR',
                                ABS( ROUND( ( pt.merchant_discount + pt.merchant_fixed ) / 100, 2 ) ) AS 'Fees',
                        CASE
                                        WHEN DAYOFWEEK( pt.time_settled ) = 6 AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 3 DAY, '%Y-%m-%d' )
                                        WHEN DAYOFWEEK( pt.time_settled ) = 7 AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 2 DAY, '%Y-%m-%d' )
                                        WHEN DAYOFWEEK( pt.time_settled) in (2,3,4,5) AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 1 DAY, '%Y-%m-%d' )
                                        ELSE date_format( pt.time_settled, '%Y-%m-%d' )
                                END AS 'dbname2_date',
                                pt.transaction_id AS 'RP_ID',
                                pt.vendor AS 'Alipay_or_Wechat'
                        FROM
                                dbname2.ptransactions pt
                                left join dbname1.transaction_additional_info b on pt.transaction_id = b.transaction_id
                                join dbname2.merchant_info m on pt.merchant_id = m.merchant_id
                        WHERE
                                m.merchant_name LIKE '%Nei%'
                                AND date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) between date_format( now( ) - INTERVAL ${start_date}  DAY, '%Y-%m-%d' ) and  date_format( now( ) - INTERVAL  ${end_date} DAY, '%Y-%m-%d' )
                        HAVING
                                dbname2_date <= now()
                        UNION ALL
                        SELECT
                                date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) AS 'Beijing_Transaction_Date',
                                date_format(  CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'America/Chicago' ) , '%Y-%m-%d %T' ) AS 'CST_Transaction_Time',
                                pt.merchant_id,
                        CASE

                                        WHEN b.DATA LIKE '%\"Store\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"Store\":\"', b.DATA ) + length( '\"Store\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"Store\":\"', b.DATA ) + length( '\"Store\":\"' ) ) - LOCATE( '\"Store\":\"', b.DATA ) - length( '\"Store\":\"' )
                                        ) ELSE ''
                                END AS 'Store_id',
                        CASE

                                        WHEN b.DATA LIKE '%\"Till\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"Till\":\"', b.DATA ) + length( '\"Till\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"Till\":\"', b.DATA ) + length( '\"Till\":\"' ) ) - LOCATE( '\"Till\":\"', b.DATA ) - length( '\"Till\":\"' )
                                        ) ELSE ''
                                END AS 'Till_id',
                        CASE

                                        WHEN b.DATA LIKE '%\"store_transaction_id\":\"%' THEN
                                        SUBSTRING(
                                                b.DATA,
                                                LOCATE( '\"store_transaction_id\":\"', b.DATA ) + length( '\"store_transaction_id\":\"' ),
                                                LOCATE( '\"', b.DATA, LOCATE( '\"store_transaction_id\":\"', b.DATA ) + length( '\"store_transaction_id\":\"' ) ) - LOCATE( '\"store_transaction_id\":\"', b.DATA ) - length( '\"store_transaction_id\":\"' )
                                        ) ELSE ''
                                END AS 'store_transaction_id',
                                'dbname2',
                                ( CASE pt.transaction_type WHEN 'pos_payment' THEN 'DR' WHEN 'pos_refund' THEN 'CR' END ) AS 'DR_or_CR',
                                ABS( ROUND( ( pt.total - pt.merchant_discount - pt.merchant_fixed ) / 100, 2 ) ) AS 'Amount',
                        CASE
                                        WHEN DAYOFWEEK( pt.time_settled ) = 6 AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 3 DAY, '%Y-%m-%d' )
                                        WHEN DAYOFWEEK( pt.time_settled ) = 7 AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 2 DAY, '%Y-%m-%d' )
                                        WHEN DAYOFWEEK( pt.time_settled) in (2,3,4,5) AND pt.vendor = 'ALP' THEN
                                        date_format( pt.time_settled + INTERVAL 1 DAY, '%Y-%m-%d' )
                                        ELSE date_format( pt.time_settled, '%Y-%m-%d' )
                                END AS 'dbname2_date',
                                pt.transaction_id AS 'RP_ID',
                                pt.vendor AS 'Alipay_or_Wechat'
                        FROM
                                dbname2.ptransactions pt
                                left join dbname1.transaction_additional_info b on pt.transaction_id = b.transaction_id
                                join dbname2.merchant_info m on pt.merchant_id = m.merchant_id
                        WHERE
                                m.merchant_name LIKE '%Nei%'
                                AND date_format( DATE( CONVERT_TZ( ( pt.method_pay_time ), 'America/New_York', 'Asia/Shanghai' ) ), '%Y-%m-%d' ) between date_format( now( ) - INTERVAL ${start_date}  DAY, '%Y-%m-%d' ) and  date_format( now( ) - INTERVAL  ${end_date} DAY, '%Y-%m-%d' )
                        HAVING
                                dbname2_date <= now()
                        ORDER BY
                                11 ASC) n
                        LEFT JOIN (
                                select 1 as Store_id, 0 as offset
                                union all select 2 as Store_id, 0 as offset
                                union all select 3 as Store_id, 0 as offset
                                union all select 4 as Store_id, 0 as offset
                                union all select 5 as Store_id, 1 as offset
                        ) s USING ( Store_id )
                ) b " |sed 's/\t/","/g;s/^/"/;s/$/"/g' > ${MYSQL_TMP_DIR}/${report_filename}

# Get amount from reports. SQL comes from Meta database ("http://www2.examples.com/question/79")
nm_wxp_dr=`sudo cat ${MYSQL_TMP_DIR}/${report_filename} | grep -E "${range_date}" | grep -E "dbname2" | grep "DR" | grep 'WXP' | awk  -F',"'  '{sum += $10} END {print sum}'`;
nm_wxp_cr=`sudo cat ${MYSQL_TMP_DIR}/${report_filename} | grep -E "${range_date}" | grep -E "dbname2" | grep "CR" | grep 'WXP' | awk  -F',"'  '{sum += $10} END {print sum}'`;
nm_alp_dr=`sudo cat ${MYSQL_TMP_DIR}/${report_filename} | grep -E "${range_date}" | grep -E "dbname2" | grep "DR" | grep 'ALP' | awk  -F',"'  '{sum += $10} END {print sum}'`;
nm_alp_cr=`sudo cat ${MYSQL_TMP_DIR}/${report_filename} | grep -E "${range_date}" | grep -E "dbname2" | grep "CR" | grep 'ALP' | awk  -F',"'  '{sum += $10} END {print sum}'`;

[ ! ${nm_wxp_dr} ] && nm_wxp_dr=0;
[ ! ${nm_wxp_cr} ] && nm_wxp_cr=0;
[ ! ${nm_alp_dr} ] && nm_alp_dr=0;
[ ! ${nm_alp_cr} ] && nm_alp_cr=0;

nm_sum_wxp=`echo ${nm_wxp_dr} ${nm_wxp_cr} |awk '{print $1-$2}'`
nm_sum_alp=`echo ${nm_alp_dr} ${nm_alp_cr} |awk '{print $1-$2}'`


# check the balance
echo "Report Date Range: `echo ${range_date} | sed  's/\^\\\\"//g' | sed 's/|/,/g'`" >> ${LOG_DIR}/${log_filename}

# If balance are equal between Dashboard and Daily report, then write details in logfile. Otherwise, write error msg in logfile.
if [ "${dashboard_wxp}x" == "${nm_sum_wxp}x" ];then
        echo "WXP Amount:${nm_sum_wxp}   ...........................................[ok]"  >> ${LOG_DIR}/${log_filename}
else
        echo "WXP Amount:                ...........................................[error]"  >> ${LOG_DIR}/${log_filename}
        echo "  Wechat doesn't match between Dashboard and Daily Report, please re-run the `date +%A`'s report munually!"  >> ${LOG_DIR}/${log_filename}
        echo "  Dashboard Net Amount: ${dashboard_wxp}, Report Net Amount: ${nm_sum_wxp}" >> ${LOG_DIR}/${log_filename}
        flag=1
fi


if [ "${dashboard_alp}x" == "${nm_sum_alp}x" ];then
        echo "ALP Amount:${nm_sum_alp}   ...........................................[ok]"  >> ${LOG_DIR}/${log_filename}
else
        echo "ALP Amount:                ...........................................[error]"  >> ${LOG_DIR}/${log_filename}
        echo "  Alipay doesn't match between Dashboard and Daily Report, please re-run the `date +%A`'s report munually!"  >> ${LOG_DIR}/${log_filename}
        echo "  Dashboard Net Amount: ${dashboard_alp}, Report Net Amount: ${nm_sum_alp}" >> ${LOG_DIR}/${log_filename}
        flag=1
fi


# copy two report to the home_dir
sudo find ${REPORT_DIR} -name "*.csv*" -exec rm -rf {} \;
sudo cp ${MYSQL_TMP_DIR}/${report_filename}      ${REPORT_DIR}  2>> ${LOG_DIR}/${log_filename}
sudo cp ${MYSQL_TMP_DIR}/${dashboard_filename}   ${REPORT_DIR}  2>> ${LOG_DIR}/${log_filename}

emaildate=`echo ${range_date} | sed 's/\^\\\\//g' | sed 's/|/"\\\\|/g' | sed 's/$/"/'`

#  If the number matchs, then will send Email.
if [ "${flag}x" == "0x" ];then
        if [ "${dashboard_wxp}x" == "0x" -a "${dashboard_alp}x" == "0x" ];then
                echo "No transactions during report date range!"  >>  ${LOG_DIR}/${log_filename}
                sudo mutt -s "Email Subject : NM Daily Report ${CURRENT_DATE}" ${MAIL_LIST} < ${LOG_DIR}/${log_filename}
        else
                sudo sed -i "/${emaildate}/  s/$/,,,${CURRENT_DATE}/"  ${REPORT_DIR}/${dashboard_filename}
                sudo cat ${REPORT_DIR}/${dashboard_filename} | grep -E "${CURRENT_DATE}$" >> ${dashboard_history_file}
                # mail ( need test on production server )
                sudo mutt -s "Email Subject : NM Daily Report ${CURRENT_DATE}" ${MAIL_LIST} -a ${REPORT_DIR}/${report_filename} -a ${REPORT_DIR}/${dashboard_filename} < ${LOG_DIR}/${log_filename}
        fi
else
        sudo mutt -s "[ERROR] Email Subject : NM Daily Report ${CURRENT_DATE}" ${MAIL_LIST} < ${LOG_DIR}/${log_filename}
fi

# remove file in mysql file directory
sudo find ${MYSQL_TMP_DIR} -mtime +1 -name "*NM*.csv" -exec rm -rf {} \;