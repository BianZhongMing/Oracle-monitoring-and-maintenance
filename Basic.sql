--建立索引
create index i_ia_bill_b_30 on ia_bill_b(cinventoryid,dauditdate) parallel nologging;
alter index i_ia_bill_b_30  noparallel;

CREATE INDEX  "I_SC_MATERIALLEDGER" ON "NCV502"."SC_MATERIALLEDGER" ("CVENDORID", "VBATCH", "NPRICE")  parallel nologging ;
alter index I_SC_MATERIALLEDGER noparallel;

--重建索引   
alter index  CRM_BD_HOUSE rebuild online nologging parallel 2;
select 'alter index '|| a.index_name ||' rebuild nologging;' from user_indexes a where a.table_name='MM_PO_B';

--收集统计信息，作为cbo优化器的依据。
Analyze table  CRM_BD_HOUSE compute statistics;
--缺省的表统计信息收集
exec dbms_stats.gather_table_stats(user,'CRM_BD_HOUSE');

--禁用索引
alter index I_IC_GENERAL_H_JSZC01 unusable;
--重新启用（需重建）
alter index  I_IC_GENERAL_B_11 rebuild online nologging parallel 2;

--命令行统计执行耗时
SQL> set time on
11:34:20 SQL> set timing on
11:34:25 SQL> insert into t_parallel select level,level from dual connect by lev
el<=5e5;
500000 rows created.
Elapsed: 00:00:00.69


