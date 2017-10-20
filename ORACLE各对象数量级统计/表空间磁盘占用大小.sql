--表空间磁盘占用大小
select dbf.tablespace_name "表空间名",
       dbf.totalspace "占磁盘空间总量(GB)",
       --dbf.totalblocks 总块数,
       --dfs.freespace "剩余总量(GB)",
       --dfs.freeblocks "剩余块数",
       dfs.freespace "剩余量(GB)",
       dbf.totalspace-dfs.freespace "使用量(GB)",
       round((dfs.freespace / dbf.totalspace) * 100,2) "空闲(%)"
  from (select t.tablespace_name,
               sum(t.bytes) / 1024 / 1024 / 1024  totalspace  --,sum(t.blocks) totalblocks
          from dba_data_files t
         group by t.tablespace_name) dbf,
       (select tt.tablespace_name,
               sum(tt.bytes) / 1024 / 1024 / 1024  freespace  --,sum(tt.blocks) freeblocks
          from dba_free_space tt
         group by tt.tablespace_name) dfs
 where trim(dbf.tablespace_name) = trim(dfs.tablespace_name)
--and dbf.tablespace_name like 'NNC%'  --只查看NC表空间
order by dbf.tablespace_name
