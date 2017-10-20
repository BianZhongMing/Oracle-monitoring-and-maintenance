--SQL监控常用脚本
--锁等待
select w.holding_session sid, w.* from (select * from dba_waiters) w;
--会话锁信息
select sid,
       type,
       id1,
       id2,
       decode(lmode,
              0,
              'None',
              1,
              'Null',
              2,
              'Row share',
              3,
              'Row Exclusive',
              4,
              'Share',
              5,
              'Share Row Exclusive',
              6,
              'Exclusive') lock_type,
       request,
       ctime,
       block
  from v$lock
 where TYPE IN ('TX', 'TM');
 
--长时SQL 9i
 select /*+ RULE */
  s.sid,
  w.seq#,
  s.serial#,
  q.sql_text,
  s.last_call_et,
  s.event,
  q.address,
  S1.SQL_ID,
  s.sql_hash_value,
  child_number
   from v$sqltext q, v$session s, V$SQL S1, v$session_wait w
  where q.address = s.sql_address
    AND S.SQL_ADDRESS = S1.ADDRESS
    and s.sid = w.sid
    and username = upper('ncv502')
    and s.status = 'ACTIVE'
  order by sid, piece


--长时SQL 10g
select s.client_identifier,
       s.sid,
       s.serial#,
       sql.sql_fulltext,
       s.last_call_et,
       s.event,
       sql.SQL_ID,
       child_number,
       s.sql_hash_value
  from v$session s, v$sql sql
 where s.sql_address = sql.ADDRESS
   and s.username = upper('ncv502')
   and s.status = 'ACTIVE'
   and s.last_call_et > 0
 order by sid

--等待事件汇总
select event, count(*) "等待数量" from v$session_wait group by event

--回滚段争用
select name, waits, gets, waits/gets "Ratio"  from v$rollstat a, v$rollname b where a.usn = b.usn 
--表空间IO分布
select df.tablespace_name name,df.file_name "file",f.phyrds pyr,f.phyblkrd pbr,f.phywrts pyw, f.phyblkwrt pbw from v$filestat f, dba_data_files df where f.file# = df.file_id order by df.tablespace_name 
--文件系统IO分布
select substr(a.file#,1,2) "#", substr(a.name,1,30) "Name",a.status, a.bytes, b.phyrds, b.phywrts from v$datafile a, v$filestat b where a.file# = b.file# 
--当天日志切换频率
select b.recid,to_char(b.first_time,'dd-mon-yy hh24:mi:ss') start_time,a.recid,to_char(a.first_time,'dd-mon-yy hh24:mi:ss') end_time, round(((a.first_time-b.first_time)*24)*60,2) minutes from v$log_history a,v$log_history b where a.recid=b.recid+1 and b.first_time>=trunc(sysdate)  order by a.first_time 
select * from dba_jobs --任务
select * from user_tables  --表统计信息
select * from user_indexes  --索引统计信息
--参数
select name, value,    decode(issys_modifiable,'FALSE','静态参数','IMMEDIATE','动态参数','重新登陆后生效') issys_modifiable  from v$parameter where value is not null 
--当前使用的参数文件
select decode(count(*), 1, 'spfile', 'pfile' ) from v$spparameter where rownum=1 and isspecified='TRUE'
--Buffer cache 命中率
SELECT a.VALUE + b.VALUE logical_reads,c.VALUE phys_reads,round(100*(1-c.value/(a.value+b.value)),4) hit_ratio FROM v$sysstat a,v$sysstat b,v$sysstat c WHERE a.NAME='db block gets' AND b.NAME='consistent gets'  AND c.NAME='physical reads'   
--librarycache 命中率
SELECT SUM(pins) total_pins,SUM(reloads) total_reloads,SUM(reloads)/SUM(pins)*100 libcache_reload_ratio FROM v$librarycache  
--操作系统进程查询sql及session
select a.SQL_TEXT,
       b.EVENT,
       b.LAST_CALL_ET,
       b.SID,
       b.SERIAL#,
       b.USERNAME,
       b.MACHINE
  from v$sqltext a, v$session b, v$process c
 where c.spid ='1345' --INPUT
   and b.paddr = c.addr
   and a.hash_value = b.sql_hash_value
 order by piece

