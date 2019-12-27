SELECT *
  FROM SYS.DBA_OBJECTS
 WHERE OWNER IN ('USER명')
   AND OBJECT_TYPE = 'TABLE'
   AND LAST_DDL_TIME >= TO_DATE('20190101', 'yyyymmdd')
 ORDER BY LAST_DDL_TIME DESC;

/*
OBJECT_TYPE

1 INDEX
2 TABLE SUBPARTITION
3 TYPE BODY
4 JAVA CLASS
5 PROCEDURE
6 INDEX SUBPARTITION
7 JAVA RESOURCE
8 TABLE PARTITION
9 JAVA SOURCE
10  TABLE
11  VIEW
12  TYPE
13  FUNCTION
14  TRIGGER
15  MATERIALIZED VIEW
16  DATABASE LINK
17  PACKAGE BODY
18  SYNONYM
19  RULE SET
20  QUEUE
21  EVALUATION CONTEXT
22  PACKAGE
23  SEQUENCE
24  LOB
25  LOB SUBPARTITION
26  LOB PARTITION
27  INDEX PARTITION
28  JOB
*/