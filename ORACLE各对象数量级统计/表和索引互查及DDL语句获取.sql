--表、索引互查
select INDEX_NAME,TABLE_NAME from dba_indexes where table_name ='BD_CORP';
--dba_indexes：所有用户的对象,user_indexes:当前用户对象

--DDL语句获取
--INDEX
SELECT INDEX_NAME,TABLE_NAME,TABLE_OWNER,DBMS_METADATA.get_ddl('INDEX',INDEX_NAME,'NCV502') INDEX_DDL
   FROM user_indexes --当前用户下的索引
 WHERE table_name = 'BD_CORP';
--Table 
SELECT owner,table_name,tablespace_name,DBMS_METADATA.GET_DDL('TABLE', table_name, 'NCV502') TABLE_DDL
  from dba_tables
 WHERE table_name = 'BD_CORP';
--tablespace
SELECT tablespace_name,DBMS_METADATA.GET_DDL('TABLESPACE', tablespace_name)
  FROM DBA_TABLESPACES;
--User
SELECT username,DBMS_METADATA.GET_DDL('USER',username) 
 FROM DBA_USERS;
--得到一个用户下的所有表，索引，存储过程的ddl
SELECT DBMS_METADATA.GET_DDL(U.OBJECT_TYPE, u.object_name)
FROM USER_OBJECTS u
where U.OBJECT_TYPE IN ('TABLE','INDEX','PROCEDURE');

--【表空间】执行查询结果导出一个库中所有表空间的创建语句
select 'select dbms_metadata.get_ddl(' || '''TABLESPACE''' || ',' || '''' ||
       tablespace_name || '''' || ') from dual ;'
  from dba_data_files
 group by tablespace_name