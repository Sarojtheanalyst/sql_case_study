use stu12;

select * from correct_answer; 
-- question_paper_code,question_number, correct_option                              
							
select * from student_list;
-- 	roll_number , student_name,class, section, school_name			
		
select * from student_response; 
-- roll_number, question_paper_code , question_number ,opetion_marked

select * from question_paper_code;  -- paper_code , class,subject

-- PROBLEM Solve 
WITH temp1 AS
(  SELECT
        sr.roll_number,
        sr.question_paper_code,
        sr.question_number,
        sr.option_marked,
        ca.correct_option
    FROM student_response AS sr
    JOIN correct_answer AS ca
        ON sr.question_paper_code = ca.question_paper_code
       AND sr.question_number = ca.question_number
),

temp2 AS
(  SELECT*,
        CASE
            WHEN option_marked = "e" THEN "yet_to_learn"
            WHEN correct_option != option_marked THEN "Incorrect"
            ELSE "correct"
        END AS "ans_status"
    FROM temp1
),

temp3 AS
(
    SELECT
        roll_number,
        question_paper_code,
        ans_status,
        COUNT(ans_status) AS 'ans_st'
    FROM temp2
    GROUP BY roll_number, question_paper_code, ans_status
),

temp4 AS
(
    SELECT
        *
    FROM temp3 AS t3
    JOIN question_paper_code AS qc
        ON t3.question_paper_code = qc.paper_code
),

temp5 AS
(
    SELECT
        *,
        CONCAT(subject, '_', ans_status) AS status
    FROM temp4
),

temp6 AS
(
    SELECT
        roll_number,
        MAX(CASE WHEN status = "Math_Incorrect" THEN ans_st ELSE 0 END) AS 'Math_Incorrect',
        MAX(CASE WHEN status = "Math_correct" THEN ans_st ELSE 0 END) AS 'Math_correct',
        MAX(CASE WHEN status = "Math_yet_to_learn" THEN ans_st ELSE 0 END) AS 'Math_yet_to_learn',
        MAX(CASE WHEN status = "Science_correct" THEN ans_st ELSE 0 END) AS 'science_correct',
        MAX(CASE WHEN status = "Science_Incorrect" THEN ans_st ELSE 0 END) AS 'Science_Incorrect',
        MAX(CASE WHEN status = "Science_yet_to_learn" THEN ans_st ELSE 0 END) AS 'Science_yet_to_learn'

    FROM temp5
    GROUP BY roll_number
) , 
temp7 as (

SELECT *,Math_correct as "math_score",
science_correct as "science_score",
round((Math_correct/(Math_correct+Math_Incorrect+Math_yet_to_learn))*100,2) AS 'math_%',
round((science_correct/(science_correct+Science_Incorrect+Science_yet_to_learn))*100,2) AS 'sci_%'
FROM temp6)

SELECT  * FROM student_list AS sl JOIN  temp7 AS t7
ON sl.roll_number=t7.roll_number ;


-- Creating a View 
CREATE VIEW result AS
WITH temp1 AS
(
    SELECT
        sr.roll_number,
        sr.question_paper_code,
        sr.question_number,
        sr.option_marked,
        ca.correct_option
    FROM student_response AS sr
    JOIN correct_answer AS ca
        ON sr.question_paper_code = ca.question_paper_code
       AND sr.question_number = ca.question_number
),

temp2 AS
(
    SELECT
        *,
        CASE
            WHEN option_marked = "e" THEN "yet_to_learn"
            WHEN correct_option != option_marked THEN "Incorrect"
            ELSE "correct"
        END AS "ans_status"
    FROM temp1
),

temp3 AS
(
    SELECT
        roll_number,
        question_paper_code,
        ans_status,
        COUNT(ans_status) AS 'ans_st'
    FROM temp2
    GROUP BY roll_number, question_paper_code, ans_status
),

temp4 AS
(
    SELECT * FROM temp3 AS t3
    JOIN question_paper_code AS qc
        ON t3.question_paper_code = qc.paper_code
),
temp5 AS
(
    SELECT *,CONCAT(subject, '_', ans_status) AS status FROM temp4
),
temp6 AS
(
    SELECT
        roll_number,
        MAX(CASE WHEN status = "Math_Incorrect" THEN ans_st ELSE 0 END) AS 'Math_Incorrect',
        MAX(CASE WHEN status = "Math_correct" THEN ans_st ELSE 0 END) AS 'Math_correct',
        MAX(CASE WHEN status = "Math_yet_to_learn" THEN ans_st ELSE 0 END) AS 'Math_yet_to_learn',
        MAX(CASE WHEN status = "Science_correct" THEN ans_st ELSE 0 END) AS 'science_correct',
        MAX(CASE WHEN status = "Science_Incorrect" THEN ans_st ELSE 0 END) AS 'Science_Incorrect',
        MAX(CASE WHEN status = "Science_yet_to_learn" THEN ans_st ELSE 0 END) AS 'Science_yet_to_learn'

    FROM temp5
    GROUP BY roll_number
) , temp7 as (

select *,Math_correct as "math_score",
science_correct as "science_score",
round((Math_correct/(Math_correct+Math_Incorrect+Math_yet_to_learn))*100,2) as 'math_per',
round((science_correct/(science_correct+Science_Incorrect+Science_yet_to_learn))*100,2) as 'sci_per'
from temp6)

select sl.roll_number,sl.student_name,sl.class,
sl.section,sl.school_name,t7.Math_Incorrect,t7.Math_correct,
t7.Math_yet_to_learn,t7.math_score,t7.math_per,
t7.Science_Incorrect,t7.science_correct, t7.Science_yet_to_learn,t7.sci_per,
t7.science_score
from student_list as sl join temp7 as t7
on sl.roll_number=t7.roll_number ;

-- fins the TOP 3 topper studxents from every class 
with final as (
with ranks as (
select *,(Math_correct+science_correct) as 'total_marks' from result)

select *,
rank() over(partition by class order  by total_marks desc ) as 'ranks'
 from ranks)
 
 select * from final where ranks<=3  order by class asc,total_marks desc

