                                          Bank Credit Analysis



create table CUSTOMER_INFO (CIF number ,
                            NAME varchar2(20),
                            SURNAME varchar2(20),
                            GENDER varchar2(5),
                            AGE NUMBER,
                            JOB varchar2(20),
                            MARITAL varchar2(20),
                            EDUCATION varchar2(20));
                            
SELECT * FROM  CREDIT_INFO FOR UPDATE;                         
                            
create table CREDIT_INFO ( CIF number,
                           BALANCE number,
                           HOUSING varchar2(5),
                           LOAN varchar2(3),
                           DAY number,
                           MONTH varchar2(10),
                           DURATION number,
                           CAMPAIGN number,
                           PDAYS number,
                           PREVIOUS number,
                           DEPOSIT varchar2(10));



CREATE TABLE table_x(cif NUMBER,
                     statement_year NUMBER,
                     STATEMENT_MONTHS NUMBER,
                     net_sale NUMBER);
                     
                     
alter table table_x modify CIF references CUSTOMER_INFO(CIF);

INSERT INTO table_x VALUES (2365987, 2018, 3, 1000);
INSERT INTO table_x VALUES (2365987, 2018, 6, 500);
INSERT INTO table_x VALUES (2365987, 2018, 9, 900);
INSERT INTO table_x VALUES (2365987, 2019, 3, 1000);
INSERT INTO table_x VALUES (2365987, 2019, 5, 1200);
INSERT INTO table_x VALUES (2365987, 2020, 3, 1000);
INSERT INTO table_x VALUES (2365987, 2021, 4, 2300);

INSERT INTO table_x VALUES (1155981, 2018, 3, 1000);
INSERT INTO table_x VALUES (1155981, 2018, 6, 500);
INSERT INTO table_x VALUES (1155981, 2018, 9, 900);
INSERT INTO table_x VALUES (1155981, 2018, 11, 1000);
INSERT INTO table_x VALUES (1155981, 2021, 5, 1200);
INSERT INTO table_x VALUES (1155981, 2021, 7, 1000);
INSERT INTO table_x VALUES (1155981, 2021, 11, 2300);



--1-Yuxarıdakı hər 3 table aralarında düzgün bir əlaqə ilə yaradılır

delete FROM credit_info WHERE cif NOT IN (SELECT cif FROM customer_info);
alter table CUSTOMER_INFO modify CIF primary key;
alter table CREDIT_INFO modify CIF references CUSTOMER_INFO(CIF);




--2-Hər Joba görə ən böyük 3 cü summani tapmaq


--the first method

SELECT bu.balance, bu.job
  FROM (SELECT row_number() OVER(PARTITION BY job ORDER BY balance DESC) nt,
               cr.balance,
               cr.cif,
               cu.job
          FROM CUSTOMER_INFO cu
          JOIN CREDIT_INFO cr
            ON cu.cif = cr.cif) bu
 WHERE bu.nt = 3;


--the second method

WITH RankedBalance as
 (select B.BALANCE,
         A.JOB,
         ROW_NUMBER() OVER(PARTITION BY A.JOB ORDER BY B.BALANCE DESC) row_num
    FROM CUSTOMER_INFO A
    JOIN CREDIT_INFO B
      ON A.CIF = B.CIF)
select job, balance from RankedBalance where row_num = 3;



--2.1-Ən uzun müddətli kreditin verildiyi müştəri neçənçi ildə anadan olub? 

SELECT * FROM CUSTOMER_INFO;
SELECT * FROM CREDIT_INFO cr ORDER BY cr.duration DESC ;
SELECT * FROM table_x;


--the first method

 
WITH MaxDuration AS
 (SELECT A.NAME,
         AGE,
         B.DURATION,
         rank() OVER(ORDER BY B.DURATION DESC) rank_num
    FROM CUSTOMER_INFO A
    JOIN CREDIT_INFO B
      ON A.CIF = B.CIF)
SELECT NAME, DURATION, (EXTRACT(YEAR FROM CURRENT_DATE) - c.age), c.age
  from MaxDuration c
 where rank_num = 1;
 
 
--the second method

SELECT EXTRACT(YEAR FROM SYSDATE) - cu.age
  FROM CUSTOMER_INFO cu  -- bu select eyni max duration malik birden cox customer ucun isleye bilir 
 WHERE cu.cif IN
       (SELECT cr.cif
          FROM CREDIT_INFO cr
         WHERE cr.duration = (SELECT MAX(duration) FROM CREDIT_INFO));
         
         

--2.2 job title-lar üzrə müxtəlif statistikalar aparmaq: ən çox MUDDETE kredit
-- verilən top 10 job title hansıdır. (Fetchsiz yazmaq) 



SELECT DISTINCT(a.job) FROM
(SELECT RANK() OVER (ORDER BY cr.duration) nt ,  cr.balance,
               cr.cif,
              RANK() OVER (ORDER BY cu.job DESC) r,cu.job,
               cr.duration
          FROM CUSTOMER_INFO cu
          JOIN CREDIT_INFO cr
            ON cu.cif = cr.cif) a WHERE a.nt=1 AND a.r<=10 ;
   


WITH Max_Duration_job as
 (select A.JOB,
         B.DURATION,
         RANK() OVER(ORDER BY A.JOB DESC ) row_num,
         RANK() OVER (ORDER BY B.DURATION DESC) r
    FROM CUSTOMER_INFO A
    JOIN CREDIT_INFO B
      ON A.CIF = B.CIF)
SELECT  DISTINCT job FROM  Max_Duration_job WHERE row_num <= 10 AND r=1;




/*3.  Yuxaridakı məlumatlardan istifadə edərək bank daxilində hər müştəri uzrə "Change In Revenue"
 anomaliyasi üzrə CiF və anomaliya məbləğini ekrana çıxartmaq lazımdır. */


SELECT * FROM CUSTOMER_INFO;
SELECT * FROM CREDIT_INFO cr ORDER BY cr.duration DESC ;
SELECT * FROM table_x;

SELECT FROM table_x x 

SELECT a.*,  -- first query
       row_number() OVER (PARTITION BY a.cif, a.statement_year ORDER BY a.cif ASC) AS prev_level_n
FROM table_x a
ORDER BY a.cif ASC, a.statement_year, a.STATEMENT_MONTHS ASC;





SELECT b.*,  --middle query 
       LAG(b.net_sale, b.prev_level_n, 0) OVER (PARTITION BY b.cif ORDER BY b.cif DESC) AS anomaliya
FROM 
(SELECT a.*, ROW_NUMBER() OVER (PARTITION BY a.cif, a.statement_year ORDER BY a.cif ASC) AS prev_level_n 
FROM table_x a) b ;


SELECT c.cif,  --outer query
       c.statement_year,
       c.STATEMENT_MONTHS,
       c.net_sale,
       NVL(c.anomaliya, 0) AS prev_net_sale,
       NVL(c.net_sale / c.anomaliya, 0) AS theshold
FROM 
(SELECT b.*, 
             LAG(b.net_sale, b.prev_level_n, NULL) OVER (PARTITION BY b.cif ORDER BY b.cif DESC) AS anomaliya
FROM (SELECT a.*, ROW_NUMBER() OVER (PARTITION BY a.cif, a.statement_year ORDER BY a.cif ASC)
AS prev_level_n FROM table_x a) b) c;



--3.1Müştəriyə görə(bu müştərilər nəzərdə tutulur  : 
--CIF (2365987,1155981) maksimal treshholdu tapan funksiya yazmaq

CREATE OR REPLACE FUNCTION get_max_treshold(cif NUMBER) RETURN NUMBER IS
  max_threshold NUMBER := 0;
BEGIN
  SELECT MAX(NVL(c.net_sale / c.anomaliya, 0))
    INTO max_threshold
    FROM (SELECT b.*,
                 LAG(b.net_sale, b.prev_level_n, NULL) OVER(PARTITION BY b.cif ORDER BY b.cif DESC) AS anomaliya
            FROM (SELECT a.*,
                         ROW_NUMBER() OVER(PARTITION BY a.cif, a.statement_year ORDER BY a.cif ASC) AS prev_level_n
                    FROM table_x a) b) c
   WHERE c.cif = cif;

  RETURN max_threshold;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN max_threshold;
END;

BEGIN  -- yoxlanis
  dbms_output.put_line(get_max_treshold(cif => 2365987));
END;

----------------------------------------------------
/*3.2  Müştəriyə görə(bu müştərilər nəzərdə tutulur  :
 CIF (2365987,1155981)  treshold məbləği 0 olan bütün müştəriləri yeni bir tb_zero_tresholds adlı tableye
 (iki sütundan ibarət cif, min_treshold) insert edən procedure yazmaq. */
 
 
CREATE TABLE tb_zero_tresholds (cif NUMBER,min_treshold NUMBER);
SELECT * FROM tb_zero_tresholds;
 
 
CREATE OR REPLACE PROCEDURE Insert_Zero_Tresholds IS
BEGIN
  INSERT INTO tb_zero_tresholds
    (cif, min_treshold)
SELECT c.cif, MIN(nvl(c.net_sale / c.theshold, 0)) AS min_theshold
      FROM (SELECT b.*,
lag(b.net_sale, b.prev_level_n, NULL) over(PARTITION BY b.cif ORDER BY b.cif DESC) theshold
              FROM (SELECT a.*,
row_number() over(PARTITION BY a.cif, a.statement_year ORDER BY a.cif ASC) prev_level_n
              FROM table_x a
      ORDER BY a.cif, a.statement_year, a.STATEMENT_MONTHS ASC) b) c
     GROUP BY c.cif;
  COMMIT;
END;

BEGIN
  Insert_Zero_Tresholds; -- yoxlanis
END;             
                

/*3.3  Bütün müştərilər və umumi treshold məbləğlarini 
qaytaran querynin nəticəsini info_treshold adlı iki sütundan ibarət
( cif-pk deyil, treshold adll sütunlara daxil etmək-(insert All tətbiqi)
(qeyd edək ki, tək insert all querysi olaraq ayriliqda 
yazılmalıdır yəni hər hansı prosedura ehtiyac yoxdur) */

CREATE TABLE info_treshold (
  cif NUMBER,
  treshold NUMBER
);

SELECT * FROM info_treshold

INSERT  ALL
INTO info_treshold (cif,treshold) VALUES (cif,treshold)
SELECT * FROM(
SELECT c.cif , SUM(NVL(c.net_sale/ c.thesho, 0)) AS treshold FROM  (SELECT b.cif,b.net_sale,b.gender,b.marital,
lag(b.net_sale, b.prev_level_n, NULL) over(PARTITION BY b.cif ORDER BY b.cif DESC)  AS thesho FROM 
(SELECT a.net_sale,ci.cif,ci.gender,ci.marital, row_number() over(PARTITION BY a.cif, a.statement_year ORDER BY a.cif ASC) prev_level_n
                  FROM table_x a FULL OUTER JOIN customer_info ci ON ci.cif=a.cif
                 ORDER BY a.cif ASC, a.statement_year, a.STATEMENT_MONTHS ASC) b) c GROUP BY c.cif ) ;


                        

