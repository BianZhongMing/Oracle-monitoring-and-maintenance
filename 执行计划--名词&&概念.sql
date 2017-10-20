--执行计划--名词&&概念

--名词
-------------------------------
1）Rowid：系统自动生成的伪列，广泛（每个表都有），只读，伴随行的整个生命周期。指出了该行所在的数据文件、数据块以及行在该块中的位置。
Recursive SQL（递归SQL）：
  触发Recursive Call的情况： 
       （1）动态的分配空间：insert没有足够的空间来保存row记录时发生。
       （2）修改数据字典信息：执行DDL语句时，ORACLE总是隐含的发出一些recursive SQL语句时发生。
       （3）没有足够空间存储系统数据字典信息：Shared Pool过小，data dictionary cache 也相应的过小，将数据字典信息从硬盘读入内存中时发生。
            在这种情况下，可以将recursive calls理解为从磁盘读取数据字典的次数。
       （4）存储过程、触发器内有SQL调用时，也会产生recursive SQL。 
2）Row Source（行源）：查询中，上一操作返回的符合条件的行的集合（可以使全表，部分表和表连接之后的结果集）。
3）Predicate（谓词）：查询中的WHERE限制条件
4）Driving Table（驱动表）/驱动行源（driving row source）：该表又称为外层表（OUTER TABLE）。
    一般说来，是应用查询的限制条件后，小row source表作为驱动表，行源数量较多会影响后续操作效率。
    执行计划中，应该为靠上的那个row source，一般将该表称为连接操作的row source 1。
5）Probed Table（被探查表）：该表又称为内层表（INNER TABLE）。
    从驱动表中得到具体一行的数据后，在该表中寻找符合连接条件的行。为大row source且建立相应索引的表是效率高。
    一般将该表称为连接操作的row source 2.
6）concatenated index（组合索引）：由多个列构成的索引，如create index idx_emp on emp（col1， col2， col3， ……）
    在组合索引中有一个重要的概念：引导列（leading column），在上面的例子中，col1列为引导列。当我们进行查询时可以使用“where col1 = ？ ”，
    也可以使用“where col1 = ？ and col2 = ？”，这样的限制条件都会使用索引，但是“where col2 = ？ ”查询就不会使用该索引。
    所以限制条件中包含先导列时，该限制条件才会使用该组合索引。
7）selectivity（可选择性）：比较一下列中唯一键的数量和表中的行数，就可以判断该列的可选择性。
   如果该列的“唯一键的数量/表中的行数”的比值越接近1，则该列的可选择性越高，该列就越适合创建索引，同样索引的可选择性也越高。
   在可选择性高的列上进行查询时，返回的数据就较少，比较适合使用索引查询。

--oracle访问数据的存取方法
--------------------------------
1） 全表扫描（Full Table Scans， FTS）：读取表中所有的行，并检查每一行是否满足语句的WHERE限制条件。
优化：增加每次读取块数，减少I/O次数（db_file_multiblock_read_count参数设定）--不是经常大表走FTS不作调整，调整可能影响cbo不走索引
使用条件：在较大的表上不建议使用全表扫描，除非取出数据的比较多，超过总量的5%-10%，或使用并行查询功能。
select * from dual;
---------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)|
---------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     1 |     2 |     2   (0)|
|   1 |  TABLE ACCESS FULL| DUAL |     1 |     2 |     2   (0)|
---------------------------------------------------------------

2）通过ROWID的表存取（Table Access by ROWID或rowid lookup）:直接访问一个数据块，Oracle存取单行数据的最快方法。
select * from tt where rowid='AAHSaUAALAAOaSAAAA';
------------------------------------------------------------------------
| Id  | Operation                  | Name | Rows  | Bytes | Cost (%CPU)|
------------------------------------------------------------------------
|   0 | SELECT STATEMENT           |      |     1 |     5 |     1   (0)|
|   1 |  TABLE ACCESS BY USER ROWID| TT   |     1 |     5 |     1   (0)|
------------------------------------------------------------------------

3）索引扫描（Index Scan或index lookup）:index获取->rowid值（对于非唯一索引可能返回多个rowid值）->表数据
索引内容：索引值+此值行对应的ROWID值
常识：index常用，内存中，逻辑I/O，访问快；
      大表，放在磁盘中，物理I/O，访问慢；
      索引中的数据已经预排序。
案例分析：
    大表，取出数据的较多，超过总量的5%-10%->index获取rowid->物理I/O访问，慢；
    查询的数据能全部在索引中找到，数据量无论多少，无论需不需要排序，都很快（不需要访问表数据，直接从索引取值）
分类：
（1） 索引唯一扫描（index unique scan）
　　通过唯一索引查找一个数值经常返回单个ROWID.如果存在UNIQUE 或PRIMARY KEY 约束（它保证了语句只存取单行）的话，Oracle经常实现唯一性扫描。
select * from bd_corp where unitcode='J001';
--create unique index I_BD_CORP_1 on BD_CORP (UNITCODE);
 --------------------------------------------------------------------------------
| Id  | Operation                   | Name        | Rows  | Bytes | Cost (%CPU)|
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |             |     1 |   293 |     1   (0)|
|   1 |  TABLE ACCESS BY INDEX ROWID| BD_CORP     |     1 |   293 |     1   (0)|
|   2 |   INDEX UNIQUE SCAN         | I_BD_CORP_1 |     1 |       |     1   (0)|
--------------------------------------------------------------------------------
（2） 索引范围扫描（index range scan）
　　使用一个索引存取多行数据，使用index rang scan的3种情况：
　　  （a） 在唯一索引列上使用了range操作符（> < <> >= <= between）
　　  （b） 在组合索引上，只使用部分列进行查询，导致查询出多行
　　  （c） 对非唯一索引列上进行的任何查询（在非唯一索引上，谓词可能返回多行数据，所以在非唯一索引上都使用索引范围扫描）。
select * from bd_corp where begindate>'2016-01-01';
---------------------------------------------------------------------------------
| Id  | Operation                   | Name         | Rows  | Bytes | Cost (%CPU)|
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |              |    22 |  6446 |     9   (0)|
|   1 |  TABLE ACCESS BY INDEX ROWID| BD_CORP      |    22 |  6446 |     9   (0)|
|   2 |   INDEX RANGE SCAN          | I_BD_CORP_CT |    22 |       |     1   (0)|
---------------------------------------------------------------------------------
（3）索引全扫描（index full scan）
　　与全表扫描对应，也有相应的全索引扫描。而且此时查询出的数据必须全部从索引中可以直接得到。
　　全索引扫描的例子：
select unitcode from bd_corp order by unitcode;
---------------------------------------------------------------------
| Id  | Operation        | Name        | Rows  | Bytes | Cost (%CPU)|
---------------------------------------------------------------------
|   0 | SELECT STATEMENT |             |   791 |  3955 |     1   (0)|
|   1 |  INDEX FULL SCAN | I_BD_CORP_1 |   791 |  3955 |     1   (0)|
---------------------------------------------------------------------
（4）索引快速扫描（index fast full scan）
　　扫描索引中的所有的数据块，与index full scan很类似，区别是它不对查询出的数据进行排序。可以使用多块读功能增加吞吐量，也可以并行读入。
　　select unitname,unitcode from bd_corp order by unitname;
---------------------------------------------------------------------------------
| Id  | Operation               | Name             | Rows  | Bytes | Cost (%CPU)|
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT        |                  |   791 | 22939 |     6  (17)|
|   1 |  SORT ORDER BY          |                  |   791 | 22939 |     6  (17)|
|   2 |   VIEW                  | index$_join$_001 |   791 | 22939 |     5   (0)|
|   3 |    HASH JOIN            |                  |       |       |            |
|   4 |     INDEX FAST FULL SCAN| I_BD_CORP_1      |   791 | 22939 |     2   (0)|
|   5 |     INDEX FAST FULL SCAN| I_BD_CORP_2      |   791 | 22939 |     3   (0)|
---------------------------------------------------------------------------------

--表之间的连接/关联(JOIN)
-------------------------------
*可并行访问join的两个row source的数据，但数据读入内存形成row source后join的其它步骤一般是串行的。
1）按连接操作符分类（原理基本一样）：
  等值连接（如WHERE A.COL3 = B.COL4）、非等值连接（WHERE A.COL3 > B.COL4）、外连接（WHERE A.COL3 = B.COL4（+））。
  
2）连接类型：
（1）排序-合并连接（Sort Merge Join， SMJ）:先排序，后连接
    内部连接过程：<1>生成row source1，按照连接操作关联列排序
                 <2>生成row source2，按照连接操作关联列排序
                 <3>按条件连接两个行源
                 *<1>,<2>可并行，<3>串行
　　优势：若2个row source都已经预先排序，则效率较高。（预先排序包含：已被索引的列/row source在前面的步骤中已经排序）
         对于非等值连接，这种连接方式的效率是比较高的。
         对于将2个较大的row source做连接，该连接方法比NL连接要好一些。
    劣势：sort费时、费资源，特别对于大row source。
（2）嵌套循环（Nested Loops， NL）:驱动表的每一行逐一到被探查表去匹配（2层嵌套循环）。
　　内部连接过程（有驱动表（外部表）的概念）：
　　    Row source1的Row 1 —— Probe ->Row source 2
　　    Row source1的Row 2 —— Probe ->Row source 2
　　    Row source1的Row 3 —— Probe ->Row source 2
　　    ……
　　    Row source1的Row n —— Probe ->Row source 2
    优势：逐一匹配，先返回已经连接的行,响应快
          驱动表较小，且被探查表上有唯一索引或高选择性非唯一索引时，则效率较高。
          并行查询（硬件支持）：常选择大表作为驱动表，因为大表可以充分利用并行功能。
    劣势：内外表颠倒效率差。
（3）哈希连接（Hash Join）
    参数： HASH_JOIN_ENABLED=TRUE，缺省情况下该参数为TRUE
           hash_area_size --因为哈希连接会在该参数指定大小的内存中运行，过小的参数会减小性能。
               alter session set workarea_size_policy=MANUAL;--先设置workarea_size_policy才能生效
               alter session set hash_arear_size=200m;
　　优势：设置好参数，效率优于SMJ和NL（2个较大的row source之间连接时会取得相对较好的效率，在一个row source较小时则能取得更好的效率。）
    劣势：只能用于等值连接中  只能用在CBO优化器中  需要设置合适的参数才能取得较好的性能。
（4）笛卡儿乘积（Cartesian Product）:无关联关系的row source连接
　　通常由编写代码疏漏造成（即程序员忘了写关联条件）。笛卡尔乘积是一个表的每一行依次与另一个表中的所有行匹配。
select a.ta,b.ta from tt a ,tt1 b ;
------------------------------------------------------------------
| Id  | Operation            | Name | Rows  | Bytes | Cost (%CPU)|
------------------------------------------------------------------
|   0 | SELECT STATEMENT     |      |    16 |    64 |    34   (0)|
|   1 |  MERGE JOIN CARTESIAN|      |    16 |    64 |    34   (0)|
|   2 |   TABLE ACCESS FULL  | TT1  |     4 |     8 |     8   (0)|
|   3 |   BUFFER SORT        |      |     4 |     8 |    26   (0)|
|   4 |    TABLE ACCESS FULL | TT   |     4 |     8 |     7   (0)|
------------------------------------------------------------------
--CARTESIAN关键字指出了在2个表之间做笛卡尔乘积
在特殊情况下我们可以使用笛卡儿乘积，如在星形连接中，除此之外，我们要尽量不使用笛卡儿乘积。


--autotrace statistics 名词解释
-------------------------------
recursive calls:递归调用
db block gets:通过update/delete/select for update读的次数。在当前读模式下所读的块数，比较少和特殊，例如数据字典数据获取。
              在DML中，更改或删除数据是要用到当前读模式。
consistent gets:在一致读模式下所读的快数，包括从回滚段读的快数。 即通过不带for update的select 读的次数。
physical reads:物理读(从磁盘上读取数据块的数量)。
               其产生的主要原因是：1.在数据库高速缓存中不存在这些块; 2.全表扫描;  3.磁盘排序。 
redo size:DML生成的redo的大小。
sorts (memory):在内存执行的排序量。 
sorts (disk):在磁盘执行的排序量。
2091 bytes sent via SQL*Net to client 　　　　从SQL*Net向客户端发送了2091字节的数据 
416 bytes received via SQL*Net from client　　客户端向SQL*Net发送了416字节的数据。

LOGIC IO(逻辑读次数）= db block gets + consistent gets

example:
 1188  recursive calls--递归调用
	  0  db block gets
	282  consistent gets
	 10  physical reads
	  0  redo size
 3222  bytes sent via SQL*Net to client
	514  bytes received via SQL*Net from client
	  4  SQL*Net roundtrips to/from client
	 23  sorts (memory)
	  0  sorts (disk)
	 33  rows processed











