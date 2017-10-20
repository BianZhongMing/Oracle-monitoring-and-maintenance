--数据表行数排行：
select table_name,num_rows from dba_tables where num_rows>1000000 order by num_rows desc;

--表数据（不含索引）情况汇总
--【注】表总共占用空间=表数据所占空间+索引数据所占空间
select a.table_name 表名,
       a.num_rows   行数,sum(b.bytes) / 1024 / 1024 MB
  from dba_tables a, user_segments b
  where a.table_name=b.segment_name
  group by a.table_name,a.num_rows
 order by a.table_name;

--===表数据（含索引）情况统计分析
select /*+ Parallel(6) */
table_name,sum(MB) MB from (
--明细
select b.table_name,a.segment_name, sum(a.bytes)/1024/1024 MB
  from dba_segments a,(select table_name from user_tables) b
 where a.segment_name in (select INDEX_NAME from user_indexes where table_name =b.table_name)--由表名匹配索引名
 or segment_name = b.table_name --表名
 group by a.segment_name,b.table_name
--====
)group by table_name
order by  MB desc
