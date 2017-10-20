--表文件磁盘占用
select a.file_name "文件全名",
       a.tablespace_name "对应表空间",
       a.bytes / 1024 / 1024 "占磁盘空间总量(MB)",
       --  b.sb /1024/1024 FREE,
       (a.bytes - b.sb) / 1024 / 1024 "使用空间总量(MB)",
       100 * (a.bytes - b.sb) / a.bytes "使用率%"
  from dba_data_files a,
       (select file_id, sum(BYTES) sb from dba_free_space group by file_id) b
 where a.file_id = b.file_id
 --  and a.tablespace_name in ('NNC_INDEX01' /*,'NNC_INDEX02'*/)
 order by a.file_name;
 
/*
--数据收缩
ALTER DATABASE DATAFILE 'C:\ORADATA\NNC_INDEX03_6.DBF.ORAORA ' RESIZE 100M;

--增加数据文件
alter tablespace NNC_DATA01 add datafile 'E:\oracle\oradata\orcl\nnc_data01_11.dbf' size 100M;

--undo表空间：扩展到10GB
select 'ALTER DATABASE DATAFILE '||''''||file_name||''''||' RESIZE 5000M;' ,tablespace_name "对应表空间" from dba_data_files  where tablespace_name like 'UNDOTBS%'

--所有表空间自动扩展设置
select 'ALTER DATABASE DATAFILE ' || '''' || file_name || '''' || ' AUTOEXTEND ON NEXT 100M MAXSIZE 32000M;' from dba_data_files;
*/