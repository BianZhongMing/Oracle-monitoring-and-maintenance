---------------lock--------------------
SELECT l.session_id      sid,
       s.serial#,
       l.locked_mode     锁模式,
       l.oracle_username 登录用户,
       s.username,
       l.os_user_name    登录机器用户名,
       s.machine         机器名,
       s.terminal        终端用户名,
       o.object_name     被锁对象名,
       --l.PROCESS,      --v$process的addr字段，通过这个可以查询到进程对应的session
       s.logon_time      登录数据库时间,
       a.SQL_TEXT,
        'alter system kill session '''||l.Session_ID||','||s.SERIAL#||''';' killSQL
  FROM v$locked_object l, all_objects o, v$session s, v$sql A
 WHERE l.object_id = o.object_id
   AND l.session_id = s.sid
   and S.SQL_HASH_VALUE= A.HASH_VALUE(+)
 ORDER BY sid, s.serial#;

-------------Runing SQL-------
----按照查询所得sid,serial#，由PLSQL session查看SQL TEXT，也可直接结束session；
----NC：由NMC用户名/工号 确定SQL和应用服务器节点或者IP（确定计算机名），由PLSQL session查看SQL TEXT确定sid,serial#。
--SID-->SQL
select a.username, a.sid, b.SQL_TEXT, b.SQL_FULLTEXT
  from v$session a, v$sqlarea b
 where a.sql_address = b.address
   and sid = '485'
--【注意】session的sql内容为空：存在并行事务
 

--------------Kill-------------
/*sid 在同一个instance的当前session中是一个unique key, 而sid ,serial#则是在整个instance生命期内的所有session中是unique key
所以当我们执行了kill session操作之后，能够准确无误的kill的某个session，不会误杀*/
---查看用户的所有Session（kill后才能删除用户）
select sid,serial# from v$session where username='NCV502';   --注意用户名字母都用大写
--select 'alter system kill session '''||sid||','||serial#||''';' from v$session where username='NCV502';--结束用户进程

--sys 登陆(RAC登陆两台机子)，kill
--alter system kill session '609,5447';

--SID ,SPID 互查(通过OS PID=ora SPID排查出效率问题SQL)
select a.SID, a.USERNAME, a.status, a.process, b.SPID from v$session a, v$process b where a.PADDR = b.ADDR
and a.sid = '938'
--and b.SPID='20755';
--OS  KILL -9 SPID

--------------手工触发PMON执行,清理killed进程，释放资源-------------
/*Oracle中kill session之后，oracle只是简单的把相关的session的paddr指向一个虚拟地址，
此时的v$session和v$process失去联系，进程就此中断，然后oracle就等待pmon进程去清除这些被标记为killed的session，
所以通常等待一个被标记为killed的session资源被释放，需要等待很长时间。
如果此时被kill的进程，尝试重新执行操作，那么会马上收到进程中断的提示，process会主动退出，
此时Oracle会立即启动PMON进程来清除该session所使用的资源，这个过程被称作一次异常中断处理。*/
--1.确认PMON进程PID
select pid,spid from v$process p,v$bgprocess b where b.paddr=p.addr and name='PMON';
--2.WAKEUP PMON     
SQL> conn / as sysdba
SQL> oradebug wakeup <orapid(oracle进程的PID)>

--------另：
/*查看并修改_pkt_pmon_interval（PMON启动周期参数）这个隐形参数，加快清除标记为Killed的Session
查询隐形参数命令如下：
--conn / as sysdba
select a.ksppinm name,b.ksppstvl value,a.ksppdesc description
from x$ksppi a,x$ksppcv b
where a.inst_id = USERENV ('Instance') --不用修改为实例名
and b.inst_id = USERENV ('Instance')
and a.indx = b.indx
and  a.ksppinm = '_pkt_pmon_interval';
--查询结果：
_pkt_pmon_interval             50         PMON process clean-up interval (cs)   --cs表示百分之一秒
--修改命令：
ALTER SYSTEM SET "_pkt_pmon_interval"=5;  --即时生效
_pkt_pmon_interval    5          PMON process clean-up interval (cs)
*/
