--【注】表名、索引名、对象名（INDEX/TABLE）都一定要大写

--某个对象
select segment_name, sum(bytes) / 1024 / 1024 "MB" from dba_segments
 where segment_name = 'BD_CORP'  --表名或者索引名
    -- 表空间 and tablespace_name='NNC_INDEX03'
 group by segment_name
 --order by sum(bytes) desc;

--某类对象
select segment_name, sum(bytes) / 1024 / 1024 "MB"
  from dba_segments
where SEGMENT_TYPE = 'TABLE' -- 所有表，所有索引：'INDEX'
 group by segment_name
 --order by sum(bytes) desc;
 
--分区表占用空间大小计算
Select S.SEGMENT_NAME ,DECODE(SUM(BYTES), NULL, 0, SUM(BYTES) / 1024 / 1024) Mbytes
  From DBA_SEGMENTS S
 Where S.SEGMENT_TYPE = 'TABLE PARTITION'
 Group By S.SEGMENT_NAME

--ALL
select owner,segment_name,segment_type,tablespace_name,sum(bytes) / 1024 / 1024 "MB"
  from dba_segments
 group by owner,segment_name,segment_type,tablespace_name
 order by sum(bytes) desc;
 
