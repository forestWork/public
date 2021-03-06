SELECT NAME
      ,TYPE
      ,LINE
      ,CASE WHEN LINE = 1 THEN 'CREATE OR REPLACE ' || TEXT ELSE TEXT END AS TEXT FROM USER_SOURCE
 WHERE TYPE IN ('PACKAGE', 'PACKAGE BODY')
   AND UPPER(NAME) LIKE '%페키지명%'
 ORDER BY 1,2,3;

/*
TYPE

1    TYPE BODY
2    PROCEDURE
3    TYPE
4    FUNCTION
5    TRIGGER
6    JAVA SOURCE
7    PACKAGE BODY
8    PACKAGE
*/

