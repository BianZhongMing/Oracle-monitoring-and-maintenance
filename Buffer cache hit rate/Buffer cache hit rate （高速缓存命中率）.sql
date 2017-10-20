--Buffer Cache Hit rate
select 1 - ((physical.value - direct.value - lobs.value) / logical.value) "Buffer Cache Hit Ratio"
  from v$sysstat physical,
       v$sysstat direct,
       v$sysstat lobs,
       v$sysstat logical
 where physical.name = 'physical reads'
   and direct.name = 'physical reads direct'
   and lobs.name = 'physical reads direct (lob)'
   and logical.name = 'session logical reads';
/*session logical reads为读的总量.
physical reads 为从数据文件读.
physical reads direct 为从缓冲区读(不含LOBS).
physical reads direct (LOBS)为从缓冲区读(含LOBS)*/

--增大PGA，SGA
