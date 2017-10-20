--（1）sqlplus下
SQL> set autotrace on; --实际执行后生成执行计划
SQL> select * from dual;--SQL
　　--执行完语句后，会显示explain plan 与 统计信息。
SQL> set autotrace traceonly;--只列出执行计划，而不会真正的执行语句（执行计划可能不准）
SQL>SET AUTOTRACE OFF 　　　　　　　--不生成AUTOTRACE报告，这是缺省模式 
SQL>SET AUTOTRACE ON EXPLAIN 　　 --这样设置包含执行计划、脚本数据输出，没有统计信息 
SQL>SET AUTOTRACE TRACEONLY STAT --这样设置只包含有统计信息 

--（2）ALL
explain plan for
select * from dual;--SQL
select * from table(dbms_xplan.display);



--Look
执行顺序 
执行顺序的原则是：由上至下，从右向左 
由上至下：在执行计划中一般含有多个节点，相同级别(或并列)的节点，靠上的优先执行，靠下的后执行 
从右向左：在某个节点下还存在多个子节点，先从最靠右的子节点开始执行。 