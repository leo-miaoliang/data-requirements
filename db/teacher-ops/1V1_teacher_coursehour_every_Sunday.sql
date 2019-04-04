begin

-- select GET_WEEKDAY(current_date) into @a;

-- if (@a=0) THEN
--     set @begin_time := current_date + interval 1 DAY;
-- else 
--     set @begin_time := current_date + interval 8-@a Day;
-- end if;
--  set @end_time := @begin_time + interval 7 DAY;
 set @begin_time := current_date;
 set @end_time := @begin_time + interval 1 DAY;




-- teacher

DROP TABLE IF EXISTS tmp_teacher;

CREATE TEMPORARY TABLE tmp_teacher (
	SELECT id, english_name
	FROM newuuabc.teacher_user_new AS tun
	WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1 and tun.is_old=1 and tun.bind_one=1
);


-- class schedule

DROP TABLE IF EXISTS tmp_teacher_day;

CREATE TEMPORARY TABLE tmp_teacher_day (
	SELECT tt.id, dr.date1 as d
	FROM tmp_teacher AS tt
		CROSS JOIN (
			SELECT date1 FROM bi.dim_date
			WHERE  date1>=@begin_time and date1<@end_time
      #  date1 >= :begin_time
			#	AND date1 < :end_time
		) AS dr
	ORDER BY tt.id, dr.date1
);


-- 1v1 bind stduent
DROP TABLE IF EXISTS tmp_1v1_student;

CREATE TEMPORARY TABLE tmp_1v1_student
(SELECT teacher_user_id
      ,student_user_id 
FROM newuuabc.open_course_time 
WHERE subject_id in (1,2) 
    AND teacher_user_id 
               in (SELECT id
	                 FROM  tmp_teacher)
    AND  is_end=1
GROUP BY teacher_user_id
        ,student_user_id);

-- 1V1 bind student course count
drop table if exists tmp_bind_course_cnt;
create temporary table tmp_bind_course_cnt
as (
SELECT ac.teacher_user_id
      ,count(1) as bind_student_course_cnt
FROM newuuabc.appoint_course ac
INNER JOIN  tmp_1v1_student tt 
    ON ac.teacher_user_id=tt.teacher_user_id 
    AND ac.student_user_id=tt.student_user_id AND 
    FROM_UNIXTIME(ac.start_time)>=@begin_time AND FROM_UNIXTIME(ac.start_time)<@end_time
WHERE ac.class_appoint_course_id = 0
		AND ac.disabled = 0 
GROUP BY  ac.teacher_user_id);


-- 1V1已约课数
drop table if exists tmp_1v1_havingcourse;
create temporary table tmp_1v1_havingcourse
as (

SELECT teacher_user_id
       ,count(1) as having_cnt
FROM (
  SELECT ac.teacher_user_id,
      class_appoint_course_id as classid
  FROM newuuabc.appoint_course ac
  WHERE  FROM_UNIXTIME(ac.start_time)>=@begin_time
    AND FROM_UNIXTIME(ac.start_time)<@end_time
		AND ac.disabled = 0  
    AND ac.class_appoint_course_id = 0
  UNION ALL
  SELECT ac.teacher_user_id,
       ac.class_appoint_course_id as classid
  FROM newuuabc.appoint_course ac
  WHERE  FROM_UNIXTIME(ac.start_time)>=@begin_time
    AND FROM_UNIXTIME(ac.start_time)<@end_time
		AND ac.disabled = 0  
    AND ac.class_appoint_course_id <> 0
  GROUP BY  ac.teacher_user_id,ac.class_appoint_course_id
) a
where a.teacher_user_id in (select id from tmp_teacher)
group by teacher_user_id
);


truncate table bi.today_sunday_teacher;
insert into bi.today_sunday_teacher
(teacher_id,english_name,contract_enddate,bind_student_cnt,nextweek_total,bind_student_course,having_cnt,free_cnt,courserate
)
SELECT teacher_id AS `外教ID`
	, english_name AS `姓名` 
	, DATE_FORMAT(max(effective_time),'%Y-%m-%d') AS `合约到期日`
  , ifnull(c.bind_cnt,0) AS `下周绑定学生数`
	, COUNT(*) AS `下周签约课数`
  , ifnull(b.bind_student_course_cnt,0) AS `下周绑定学生课数`

	 -- , COUNT(IF(is_leave = 1, 1, NULL)) AS `请假课时数`
  , ifnull(d.having_cnt,0) AS `已约课时数` 
  , COUNT(*)-COUNT(IF(is_leave = 1, 1, NULL))-ifnull(d.having_cnt,0) as `下周空余课数`
  ,round(ifnull(b.bind_student_course_cnt,0)/COUNT(*),2) as `rate`
  
FROM (
	SELECT ttd.id AS teacher_id
	, tun.english_name
	, d AS class_date
	, FROM_UNIXTIME(ts.effective_end_time) AS effective_time
	, FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.start_time * 60) AS start_time
	, FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.end_time * 60) AS end_time
	, (cs.end_time - cs.start_time) AS duration
	, IF (tl.id IS NOT NULL, 1, 0) AS is_leave
FROM tmp_teacher_day AS ttd
		INNER JOIN newuuabc.signed_time AS st
			ON ttd.id = st.teacher_user_id
				AND UNIX_TIMESTAMP(ttd.d) >= st.effective_start_time
				AND UNIX_TIMESTAMP(ttd.d) <= st.effective_end_time
				AND bi.GET_WEEKDAY(ttd.d) = st.weekday
		INNER JOIN newuuabc.teacher_signed AS ts
			ON st.signed_id = ts.id
		INNER JOIN newuuabc.carport_slot AS cs
			ON st.start_time <= cs.start_time
				AND st.end_time >= cs.end_time
		INNER JOIN newuuabc.teacher_user_new AS tun
			ON ttd.id = tun.id
		LEFT JOIN newuuabc.teacher_leave AS tl
			ON ttd.id = tl.teacher_user_id
				AND UNIX_TIMESTAMP(CONVERT_TZ(FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.start_time * 60), '+08:00','+00:00')) >= tl.start_time
				AND UNIX_TIMESTAMP(CONVERT_TZ(FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.end_time * 60), '+08:00','+00:00')) <= tl.end_time
				AND tl.status <> 3
    
	WHERE ts.enable = 1 AND ts.status = 1
) AS a
LEFT JOIN tmp_bind_course_cnt b on a.teacher_id=b.teacher_user_id
LEFT JOIN  (select teacher_user_id,count(1) as bind_cnt
            from tmp_1v1_student
            group by teacher_user_id)  c 
   on a.teacher_id=c.teacher_user_id
LEFT JOIN tmp_1v1_havingcourse d on d.teacher_user_id=a.teacher_id
GROUP BY teacher_id;






end
