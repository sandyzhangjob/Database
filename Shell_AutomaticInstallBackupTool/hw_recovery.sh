#!/bin/bash
#template
#history 2012-09-24
# version 1.0 2013-06-06

source /etc/profile &> /dev/null
export PATH=$PATH:/usr/local/mysql/bin
DATE=`date +%F`
DT=`date +%Y-%m-%d-%M`
mkdir -p /home/databak_rec
BASEDIR=/home/databak_rec
mkdir -p /home/databak_rec/log/
LOGFILE1=/home/databak_rec/log/apply_log_$DATE.log
LOGFILE2=/home/databak_rec/log/copy_log_$DATE.log

### {{{ xtrabackup_all_recovery
xtrabackup_all_recovery()
{
read -p "请输入xtrabackup全备的路径 " ALL_DIR;


def_file=/etc/my.cnf
if [ -z $CONF_DIR/defaults_file.txt ] ; then
        def_file=`grep $PORT $CONF_DIR/defaults_file.txt`
fi
        innobackupex --apply-log --defaults-file ${def_file}   $ALL_DIR 2> $LOGFILE1

if [ $? -eq 0 ]; then
        grep 'innobackupex: completed OK!' $LOGFILE1
else 
        echo "innobackupex recovery failed"
        exit 
fi
#停掉mysql 重启
if [ -s  /etc/init.d/mysql ]; then
        /etc/init.d/mysql stop
else
        /usr/bin/mysqld_multi stop
fi

# 备份原来的数据文件
DATADIR=`grep -v "^#" ${def_file} |grep datadir | awk '{print $NF}'`
TARGET=$DATADIR$DT
mv $DATADIR $TARGET

mkdir -p $DATADIR
if [ $? -eq 0 ] ; then 
        innobackupex  --copy-back --defaults-file ${def_file}  $ALL_DIR 2> $LOGFILE2
        grep "innobackupex: completed OK" $LOGFILE2
else 
        echo "恢复失败";
        exit
fi
chown -R mysql:mysql $DATADIR
if [ -s  /etc/init.d/mysql ]; then
        /etc/init.d/mysql start
else
        /usr/bin/mysqld_multi start
fi
}
###}}} 

### {{{ xtrabackup_inc_recovery
xtrabackup_inc_recovery()
{
read -p "请输入xtrabackup全备的路径 " ALL_DIR;
read -p "请输入xtrabackup增备的路径 " INC_DIR;

def_file=/etc/my.cnf
if [ -z $CONF_DIR/defaults_file.txt ] ; then
        def_file=`grep $PORT $CONF_DIR/defaults_file.txt`
fi
        innobackupex --apply-log --defaults-file ${def_file}   $ALL_DIR 2> $LOGFILE1
        innobackupex --apply-log --defaults-file ${def_file}   $ALL_DIR --incremental-dir=$INC_DIR 2>> $LOGFILE1
if [ $? -eq 0 ]; then
        grep 'innobackupex: completed OK!' $LOGFILE1
else
        echo "innobackupex recovery failed"
        exit
fi
#停掉mysql 重启
if [ -s  /etc/init.d/mysql ]; then
        /etc/init.d/mysql stop
else
        /usr/bin/mysqld_multi stop
fi

# 备份原来的数据文件
DATADIR=`grep -v "^#" ${def_file} |grep datadir | awk '{print $NF}'`
TARGET=$DATADIR$DT
mv $DATADIR $TARGET

mkdir -p $DATADIR
if [ $? -eq 0 ] ; then
        innobackupex  --copy-back --defaults-file ${def_file}  $ALL_DIR 2> $LOGFILE2
        grep "innobackupex: completed OK" $LOGFILE2
else
        echo "恢复失败";
        exit
fi
chown -R mysql:mysql $DATADIR

if [ -s  /etc/init.d/mysql ]; then
        /etc/init.d/mysql start
else
        /usr/bin/mysqld_multi start
fi
}
###}}}

### {{{ help 
helps()
{
echo "xtrabackup_all_recovery---------------全备恢复"
echo "xtrabackup_inc_recovery---------------增备恢复"

}
###}}}   

### {{{  case   
case $1 in
'')
        helps
        ;;
'xtrabackup_all_recovery')
        xtrabackup_all_recovery
        ;;
'xtrabackup_inc_recovery')
        xtrabackup_inc_recovery
        ;;
esac
### }}}
