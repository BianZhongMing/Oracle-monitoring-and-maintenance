--统计信息查看
select * from dba_tables a where a.owner='NCV502' and a.last_analyzed is null  ;
select * from dba_indexes i where i.owner='NCV502' and i.last_analyzed is null;
select table_name from dba_tab_columns b where b.owner='NCV502' and b.LAST_ANALYZED is null group by table_name;
