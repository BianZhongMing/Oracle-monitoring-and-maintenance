--µ÷ÕûSGA
create pfile='$ORACLE_HOME/rdbms/pfile20150507' from spfile;
alter system set sga_target=30g scope=spfile;
alter system set sga_max_size=30g scope=spfile;
SQL>shutdown immediate;
SQL>startup;